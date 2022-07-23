// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./TradeCoinV4.sol";
import "./RoleControl.sol";
import "./interfaces/ITradeCoinComposition.sol";
import "./interfaces/ITradeCoin.sol";

contract TradeCoinCompositionV2 is ERC721, RoleControl, ITradeCoinComposition {
    uint256 public tokenCounter;
    TradeCoinV4 public immutable tradeCoinV4;

    struct Composition {
        uint256[] tokenIdsOfTC;
        uint256 cumulativeAmount;
        State state;
        address currentHandler;
    }

    mapping(uint256 => Composition) public tradeCoinComposition;

    modifier isCurrentHandler(uint256 tokenId) {
        require(
            tradeCoinComposition[tokenId].currentHandler == msg.sender,
            "Caller is not the current handler"
        );
        _;
    }

    constructor(address _tradeCoinV4)
        ERC721("TradeCoinComposition", "TCC")
        RoleControl(msg.sender)
    {
        tradeCoinV4 = TradeCoinV4(payable(_tradeCoinV4));
    }

    function createComposition(
        string calldata compositionName,
        uint256[] calldata tokenIdsOfTC,
        address newHandler
    ) external override {
        require(
            tokenIdsOfTC.length > 1,
            "Composition must be more than 2 tokens"
        );

        uint256 totalAmount;
        for (uint256 i; i < tokenIdsOfTC.length; ) {
            tradeCoinV4.transferFrom(
                msg.sender,
                address(this),
                tokenIdsOfTC[i]
            );

            (
                uint256 amountOfTC,
                TradeCoinV4.State stateOfProduct,
                ,

            ) = tradeCoinV4.tradeCoinCommodity(tokenIdsOfTC[i]);
            require(uint8(stateOfProduct) == 7, "Commodity must be stored");

            tradeCoinV4.changeCurrentHandlerAndState(
                tokenIdsOfTC[i],
                address(0),
                ITradeCoin.State.Stored
            );
            unchecked {
                ++i;
                totalAmount += amountOfTC;
            }
        }

        _mint(msg.sender, tokenCounter);

        tradeCoinComposition[tokenCounter] = Composition(
            tokenIdsOfTC,
            totalAmount,
            State.Created,
            newHandler
        );

        emit MintComposition(
            tokenCounter,
            msg.sender,
            tokenIdsOfTC,
            compositionName,
            totalAmount
        );
        unchecked {
            tokenCounter += 1;
        }
    }

    function appendCommodityToComposition(
        uint256 _tokenIdComposition,
        uint256 _tokenIdTC
    ) external override {
        require(ownerOf(_tokenIdComposition) == msg.sender, "Not the owner");

        tradeCoinV4.transferFrom(msg.sender, address(this), _tokenIdTC);

        tradeCoinComposition[_tokenIdComposition].tokenIdsOfTC.push(_tokenIdTC);

        (uint256 amountOfTC, , , ) = tradeCoinV4.tradeCoinCommodity(_tokenIdTC);
        unchecked {
            tradeCoinComposition[_tokenIdComposition]
                .cumulativeAmount += amountOfTC;
        }

        emit AppendCommodityToComposition(
            _tokenIdComposition,
            msg.sender,
            _tokenIdTC
        );
    }

    function removeCommodityFromComposition(
        uint256 _tokenIdComposition,
        uint256 _indexTokenIdTC
    ) external override {
        require(ownerOf(_tokenIdComposition) == msg.sender, "Not the owner");

        uint256 lengthTokenIds = tradeCoinComposition[_tokenIdComposition]
            .tokenIdsOfTC
            .length;

        require(lengthTokenIds > 2, "Must contain at least 2 tokens");
        require((lengthTokenIds - 1) >= _indexTokenIdTC, "Index not in range");

        uint256 tokenIdTC = tradeCoinComposition[_tokenIdComposition]
            .tokenIdsOfTC[_indexTokenIdTC];
        uint256 lastTokenId = tradeCoinComposition[_tokenIdComposition]
            .tokenIdsOfTC[lengthTokenIds - 1];

        tradeCoinV4.transferFrom(address(this), msg.sender, tokenIdTC);

        tradeCoinComposition[_tokenIdComposition].tokenIdsOfTC[
            _indexTokenIdTC
        ] = lastTokenId;

        tradeCoinComposition[_tokenIdComposition].tokenIdsOfTC.pop();

        (uint256 amountOfTC, , , ) = tradeCoinV4.tradeCoinCommodity(tokenIdTC);
        unchecked {
            tradeCoinComposition[_tokenIdComposition]
                .cumulativeAmount -= amountOfTC;
        }

        emit RemoveCommodityFromComposition(
            _tokenIdComposition,
            msg.sender,
            tokenIdTC
        );
    }

    function decomposition(uint256 _tokenId) external override {
        require(ownerOf(_tokenId) == msg.sender, "Not the owner");

        uint256[] memory productIds = tradeCoinComposition[_tokenId]
            .tokenIdsOfTC;
        for (uint256 i; i < productIds.length; ) {
            tradeCoinV4.transferFrom(address(this), msg.sender, productIds[i]);
            unchecked {
                ++i;
            }
        }

        // delete tradeCoinComposition[_tokenId];
        _burn(_tokenId);

        emit Decomposition(_tokenId, msg.sender, productIds);
    }

    function burnComposition(uint256 _tokenId) public override {
        require(ownerOf(_tokenId) == msg.sender, "Not the owner");
        uint256[] memory commodityIds = tradeCoinComposition[_tokenId]
            .tokenIdsOfTC;
        for (uint256 i; i < commodityIds.length; ) {
            tradeCoinV4.burnCommodity(commodityIds[i]);
            unchecked {
                ++i;
            }
        }
        emit BurnComposition(_tokenId, msg.sender, commodityIds);

        // delete tradeCoinComposition[_tokenId];
        _burn(_tokenId);
    }

    function addTransformation(
        uint256 _tokenId,
        string calldata _transformationCode
    ) external override onlyTransformationHandler isCurrentHandler(_tokenId) {
        emit CompositionTransformation(
            _tokenId,
            msg.sender,
            _transformationCode
        );
    }

    function addTransformationDecrease(
        uint256 _tokenId,
        string calldata _transformationCode,
        uint256 amountLoss
    ) external override onlyTransformationHandler isCurrentHandler(_tokenId) {
        tradeCoinComposition[_tokenId].cumulativeAmount -= amountLoss;
        emit CompositionTransformationDecrease(
            _tokenId,
            msg.sender,
            amountLoss,
            _transformationCode
        );
    }

    function addInformationToComposition(uint256 _tokenId, string calldata data)
        external
        override
        onlyInformationHandler
        isCurrentHandler(_tokenId)
    {
        emit AddInformation(_tokenId, msg.sender, data);
    }

    function checkQualityOfComposition(uint256 _tokenId, string calldata data)
        external
        override
        onlyInformationHandler
        isCurrentHandler(_tokenId)
    {
        emit QualityCheckComposition(_tokenId, msg.sender, data);
    }

    function confirmCompositionLocation(
        uint256 _tokenId,
        uint256 latitude,
        uint256 longitude,
        uint256 radius
    ) external override onlyInformationHandler isCurrentHandler(_tokenId) {
        emit LocationOfComposition(
            _tokenId,
            msg.sender,
            latitude,
            longitude,
            radius
        );
    }

    function changeStateAndHandler(
        uint256 _tokenId,
        address _newCurrentHandler,
        State _newState
    ) external override {
        tradeCoinComposition[_tokenId].currentHandler = _newCurrentHandler;
        tradeCoinComposition[_tokenId].state = _newState;

        emit ChangeStateAndHandler(
            _tokenId,
            msg.sender,
            _newState,
            _newCurrentHandler
        );
    }

    function getIdsOfCommodities(uint256 _tokenId)
        external
        view
        override
        returns (uint256[] memory tokenIds)
    {
        tokenIds = tradeCoinComposition[_tokenId].tokenIdsOfTC;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return
            type(ITradeCoinComposition).interfaceId == interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
