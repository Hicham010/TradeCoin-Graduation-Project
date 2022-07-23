// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./TradeCoin.sol";
import "./RoleControl.sol";
import "./interfaces/ITradeCoinComposition.sol";
import "./interfaces/ITradeCoin.sol";

contract TradeCoinCompositionV2 is ERC721, RoleControl, ITradeCoinComposition {
    uint256 public tokenCounter;
    TradeCoinV4 public tradeCoinV4;

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
        string memory compositionName,
        uint256[] memory tokenIdsOfTC,
        address newHandler
    ) external override {
        require(
            tokenIdsOfTC.length > 1,
            "You can't make a composition of less then 2 tokens"
        );

        uint256 totalAmount;
        for (uint256 i; i < tokenIdsOfTC.length; i++) {
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
            totalAmount += amountOfTC;

            tradeCoinV4.changeCurrentHandlerAndState(
                tokenIdsOfTC[i],
                address(0),
                ITradeCoin.State.Stored
            );
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

        tokenCounter += 1;
    }

    function appendCommodityToComposition(
        uint256 _tokenIdComposition,
        uint256 _tokenIdTC
    ) external override {
        require(ownerOf(_tokenIdComposition) == msg.sender, "Not the owner");

        tradeCoinV4.transferFrom(msg.sender, address(this), _tokenIdTC);

        tradeCoinComposition[_tokenIdComposition].tokenIdsOfTC.push(_tokenIdTC);

        (uint256 amountOfTC, , , ) = tradeCoinV4.tradeCoinCommodity(_tokenIdTC);
        tradeCoinComposition[_tokenIdComposition]
            .cumulativeAmount += amountOfTC;

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

        require(lengthTokenIds > 2, "Can't remove token from composition");
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
        tradeCoinComposition[_tokenIdComposition]
            .cumulativeAmount -= amountOfTC;

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
        for (uint256 i; i < productIds.length; i++) {
            tradeCoinV4.transferFrom(address(this), msg.sender, productIds[i]);
        }

        delete tradeCoinComposition[_tokenId];
        _burn(_tokenId);

        emit Decomposition(_tokenId, msg.sender, productIds);
    }

    function burnComposition(uint256 _tokenId) public override {
        require(ownerOf(_tokenId) == msg.sender, "Not the owner");
        for (
            uint256 i;
            i < tradeCoinComposition[_tokenId].tokenIdsOfTC.length;
            i++
        ) {
            tradeCoinV4.burnCommodity(
                tradeCoinComposition[_tokenId].tokenIdsOfTC[i]
            );
        }
        emit BurnComposition(
            _tokenId,
            msg.sender,
            tradeCoinComposition[_tokenId].tokenIdsOfTC
        );
        _burn(_tokenId);
        delete tradeCoinComposition[_tokenId];
    }

    function addTransformation(
        uint256 _tokenId,
        string memory _transformationCode
    ) external override onlyTransformationHandler isCurrentHandler(_tokenId) {
        emit CompositionTransformation(
            _tokenId,
            msg.sender,
            _transformationCode
        );
    }

    function addTransformationDecrease(
        uint256 _tokenId,
        string memory _transformationCode,
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

    function addInformationToComposition(uint256 _tokenId, string memory data)
        external
        override
        onlyInformationHandler
        isCurrentHandler(_tokenId)
    {
        emit AddInformation(_tokenId, msg.sender, data);
    }

    function checkQualityOfComposition(uint256 _tokenId, string memory data)
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
        returns (uint256[] memory)
    {
        return tradeCoinComposition[_tokenId].tokenIdsOfTC;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // function splitProduct(uint256 _tokenId, uint256[] memory partitions)
    //     external
    //     override
    // {
    //     require(
    //         partitions.length <= 3 && partitions.length > 1,
    //         "Token should be split to 2 or more new tokens, we limit the max to 3."
    //     );
    //     // create temp list of tokenIds
    //     uint256[] memory tempArray = new uint256[](partitions.length + 1);
    //     tempArray[0] = _tokenId;
    //     // create temp struct
    //     Composition memory temporaryStruct = tradeCoinComposition[_tokenId];

    //     uint256 sumPartitions;
    //     for (uint256 x; x < partitions.length; x++) {
    //         require(partitions[x] != 0, "Partitions can't be 0");
    //         sumPartitions += partitions[x];
    //     }

    //     require(
    //         tradeCoinComposition[_tokenId].cumulativeAmount == sumPartitions,
    //         "The given amount of partitions do not equal total weight amount."
    //     );

    //     burnComposition(_tokenId);
    //     for (uint256 i; i < partitions.length; i++) {
    //         mintAfterSplitOrBatch(
    //             temporaryStruct.tokenIdsOfTC,
    //             // temporaryStruct.compositionName,
    //             partitions[i],
    //             temporaryStruct.state,
    //             temporaryStruct.currentHandler
    //             // temporaryStruct.transformations
    //         );
    //         tempArray[i + 1] = tokenCounter;
    //     }

    //     emit SplitComposition(_tokenId, msg.sender, tempArray);
    //     delete temporaryStruct;
    // }

    // function batchComposition(uint256[] memory _tokenIds) external override {
    //     require(
    //         _tokenIds.length > 1 && _tokenIds.length <= 3,
    //         "Maximum batch: 3, minimum: 2"
    //     );

    //     // bytes32 emptyHash;
    //     uint256 cumulativeWeight;
    //     uint256[] memory tokenIdsEmpty;
    //     Composition memory short = Composition(
    //         tokenIdsEmpty,
    //         0,
    //         State.Created,
    //         "",
    //         tradeCoinComposition[_tokenIds[0]].currentHandler
    //     );

    //     bytes32 hashed = keccak256(abi.encode(short));

    //     uint256[] memory tempArray = new uint256[](_tokenIds.length + 1);

    //     uint256[] memory collectiveProductIds = new uint256[](
    //         tradeCoinComposition[_tokenIds[0]].tokenIdsOfTC.length +
    //             tradeCoinComposition[_tokenIds[1]].tokenIdsOfTC.length
    //     );

    //     collectiveProductIds = concatenateArrays(
    //         tradeCoinComposition[_tokenIds[0]].tokenIdsOfTC,
    //         tradeCoinComposition[_tokenIds[0]].tokenIdsOfTC
    //     );

    //     for (uint256 tokenId; tokenId < _tokenIds.length; tokenId++) {
    //         require(
    //             ownerOf(_tokenIds[tokenId]) == msg.sender,
    //             "Unauthorized: The tokens do not have the same owner."
    //         );
    //         require(
    //             tradeCoinComposition[_tokenIds[tokenId]].state !=
    //                 State.NonExistent,
    //             "Unauthorized: The tokens are not in the right state."
    //         );
    //         Composition memory short2 = Composition(
    //             tokenIdsEmpty,
    //             0,
    //             tradeCoinComposition[_tokenIds[tokenId]].state,
    //             "",
    //             tradeCoinComposition[_tokenIds[tokenId]].currentHandler
    //         );
    //         require(
    //             hashed == keccak256(abi.encode(short2)),
    //             "This should be the same hash, one of the fields in the NFT don't match"
    //         );

    //         tempArray[tokenId] = _tokenIds[tokenId];
    //         // create temp struct
    //         cumulativeWeight += tradeCoinComposition[_tokenIds[tokenId]]
    //             .cumulativeAmount;
    //         burnComposition(_tokenIds[tokenId]);
    //         delete tradeCoinComposition[_tokenIds[tokenId]];
    //     }
    //     mintAfterSplitOrBatch(
    //         collectiveProductIds,
    //         // short.compositionName,
    //         cumulativeWeight,
    //         short.state,
    //         short.currentHandler
    //         // short.transformations
    //     );
    //     tempArray[_tokenIds.length] = tokenCounter;

    //     emit BatchComposition(msg.sender, tempArray);
    // }

    // function mintAfterSplitOrBatch(
    //     uint256[] memory _tokenIdsOfProduct,
    //     uint256 _weight,
    //     State _state,
    //     address currentHandler
    // ) internal {
    //     require(_weight != 0, "Weight can't be 0");

    //     uint256 id = tokenCounter;

    //     _safeMint(msg.sender, id);

    //     tradeCoinComposition[id] = Composition(
    //         _tokenIdsOfProduct,
    //         _weight,
    //         _state,
    //         "",
    //         currentHandler
    //     );

    //     tokenCounter += 1;
    // }

    // function concatenateArrays(
    //     uint256[] memory accounts,
    //     uint256[] memory accounts2
    // ) internal pure returns (uint256[] memory) {
    //     uint256[] memory returnArr = new uint256[](
    //         accounts.length + accounts2.length
    //     );

    //     uint256 i = 0;
    //     for (; i < accounts.length; i++) {
    //         returnArr[i] = accounts[i];
    //     }

    //     uint256 j = 0;
    //     while (j < accounts.length) {
    //         returnArr[i++] = accounts2[j++];
    //     }

    //     return returnArr;
    // }
}
