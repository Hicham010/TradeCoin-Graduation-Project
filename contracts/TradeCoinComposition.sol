// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./TradeCoinV4.sol";
import "./RoleControl.sol";
import "./interfaces/ITradeCoinComposition.sol";
import "./interfaces/ITradeCoin.sol";

contract TradeCoinCompositionV2 is ERC721, RoleControl, ITradeCoinComposition {
    struct Composition {
        uint256[] tokenIdsOfTC;
        uint256 cumulativeAmount;
        State state;
        address currentHandler;
    }

    uint256 public tokenCounter;
    TradeCoinV4 public immutable tradeCoinV4;

    mapping(uint256 => Composition) public tradeCoinComposition;

    modifier isCurrentHandler(uint256 tokenId) {
        require(
            tradeCoinComposition[tokenId].currentHandler == msg.sender,
            "Caller is not the current handler"
        );
        _;
    }

    constructor(address _tradeCoinV4)
        ERC721("TradeCoinCompositionV2", "TCc")
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
        for (uint256 i = 0; i < tokenIdsOfTC.length; ) {
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
        uint256 tokenIdComposition,
        uint256 tokenIdTC
    ) external override {
        require(ownerOf(tokenIdComposition) == msg.sender, "Not the owner");

        tradeCoinComposition[tokenIdComposition].tokenIdsOfTC.push(tokenIdTC);

        (uint256 amountOfTC, , , ) = tradeCoinV4.tradeCoinCommodity(tokenIdTC);
        unchecked {
            tradeCoinComposition[tokenIdComposition]
                .cumulativeAmount += amountOfTC;
        }

        emit AppendCommodityToComposition(
            tokenIdComposition,
            msg.sender,
            tokenIdTC
        );

        tradeCoinV4.transferFrom(msg.sender, address(this), tokenIdTC);
    }

    function removeCommodityFromComposition(
        uint256 tokenIdComposition,
        uint256 indexTokenIdTC
    ) external override {
        require(ownerOf(tokenIdComposition) == msg.sender, "Not the owner");

        uint256 lengthTokenIds = tradeCoinComposition[tokenIdComposition]
            .tokenIdsOfTC
            .length;

        require(lengthTokenIds > 2, "Must contain at least 2 tokens");
        require((lengthTokenIds - 1) >= indexTokenIdTC, "Index not in range");

        uint256 tokenIdTC = tradeCoinComposition[tokenIdComposition]
            .tokenIdsOfTC[indexTokenIdTC];
        uint256 lastTokenId = tradeCoinComposition[tokenIdComposition]
            .tokenIdsOfTC[lengthTokenIds - 1];

        tradeCoinComposition[tokenIdComposition].tokenIdsOfTC[
            indexTokenIdTC
        ] = lastTokenId;

        tradeCoinComposition[tokenIdComposition].tokenIdsOfTC.pop();

        emit RemoveCommodityFromComposition(
            tokenIdComposition,
            msg.sender,
            tokenIdTC
        );

        (uint256 amountOfTC, , , ) = tradeCoinV4.tradeCoinCommodity(tokenIdTC);
        unchecked {
            tradeCoinComposition[tokenIdComposition]
                .cumulativeAmount -= amountOfTC;
        }
        tradeCoinV4.transferFrom(address(this), msg.sender, tokenIdTC);
    }

    function decomposition(uint256 tokenId) external override {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");

        uint256[] memory productIds = tradeCoinComposition[tokenId]
            .tokenIdsOfTC;

        _burn(tokenId);

        emit Decomposition(tokenId, msg.sender, productIds);

        for (uint256 i = 0; i < productIds.length; ) {
            tradeCoinV4.transferFrom(address(this), msg.sender, productIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    function burnComposition(uint256 tokenId) external override {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        uint256[] memory commodityIds = tradeCoinComposition[tokenId]
            .tokenIdsOfTC;

        emit BurnComposition(tokenId, msg.sender, commodityIds);

        _burn(tokenId);

        for (uint256 i = 0; i < commodityIds.length; ) {
            tradeCoinV4.burnCommodity(commodityIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    function addTransformation(uint256 tokenId, string calldata transformation)
        external
        override
        onlyTransformationHandler
        isCurrentHandler(tokenId)
    {
        emit CompositionTransformation(tokenId, msg.sender, transformation);
    }

    function addTransformationDecrease(
        uint256 tokenId,
        string calldata transformation,
        uint256 amountLoss
    ) external override onlyTransformationHandler isCurrentHandler(tokenId) {
        tradeCoinComposition[tokenId].cumulativeAmount -= amountLoss;
        emit CompositionTransformationDecrease(
            tokenId,
            msg.sender,
            amountLoss,
            transformation
        );
    }

    function addInformationToComposition(uint256 tokenId, string calldata data)
        external
        override
        onlyInformationHandler
        isCurrentHandler(tokenId)
    {
        emit AddInformation(tokenId, msg.sender, data);
    }

    function checkQualityOfComposition(uint256 tokenId, string calldata data)
        external
        override
        onlyInformationHandler
        isCurrentHandler(tokenId)
    {
        emit QualityCheckComposition(tokenId, msg.sender, data);
    }

    function confirmCompositionLocation(
        uint256 tokenId,
        uint256 latitude,
        uint256 longitude,
        uint256 radius
    ) external override onlyInformationHandler isCurrentHandler(tokenId) {
        emit LocationOfComposition(
            tokenId,
            msg.sender,
            latitude,
            longitude,
            radius
        );
    }

    function changeStateAndHandler(
        uint256 tokenId,
        address newCurrentHandler,
        State newState
    ) external override {
        tradeCoinComposition[tokenId].currentHandler = newCurrentHandler;
        tradeCoinComposition[tokenId].state = newState;

        emit ChangeStateAndHandler(
            tokenId,
            msg.sender,
            newState,
            newCurrentHandler
        );
    }

    function getIdsOfCommodities(uint256 tokenId)
        external
        view
        override
        returns (uint256[] memory tokenIds)
    {
        tokenIds = tradeCoinComposition[tokenId].tokenIdsOfTC;
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
