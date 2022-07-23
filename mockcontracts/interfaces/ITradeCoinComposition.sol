// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface ITradeCoinComposition {
    enum State {
        NonExistent,
        Created,
        PendingProcess,
        Processing,
        PendingTransport,
        Transporting,
        PendingStorage,
        Stored
    }

    event MintComposition(
        uint256 indexed tokenId,
        address indexed caller,
        uint256[] productIds,
        string compositionName,
        uint256 amount
    );

    event CompositionTransformation(
        uint256 indexed tokenId,
        address indexed caller,
        uint256 weightLoss,
        string transformation
    );

    event CompositionTransformation(
        uint256 indexed tokenId,
        address indexed caller,
        string transformation
    );

    // event SplitComposition(
    //     uint256 indexed tokenId,
    //     address indexed caller,
    //     uint256[] newTokenIds
    // );

    // event BatchComposition(address indexed caller, uint256[] batchedTokenIds);

    event RemoveCommodityFromComposition(
        uint256 indexed tokenId,
        address indexed caller,
        uint256 tokenIdOfProduct
    );

    event AppendCommodityToComposition(
        uint256 indexed tokenId,
        address indexed caller,
        uint256 tokenIdOfProduct
    );

    event Decomposition(
        uint256 indexed tokenId,
        address indexed caller,
        uint256[] productIds
    );

    event ChangeStateAndHandler(
        uint256 indexed tokenId,
        address indexed caller,
        State newState,
        address newCurrentHandler
    );

    event QualityCheckComposition(
        uint256 indexed tokenId,
        address indexed checker,
        string data
    );

    event LocationOfComposition(
        uint256 indexed tokenId,
        address indexed locationSignaler,
        uint256 latitude,
        uint256 longitude,
        uint256 radius
    );

    event AddInformation(
        uint256 indexed tokenId,
        address indexed caller,
        string data
    );

    event BurnComposition(
        uint256 indexed tokenId,
        address indexed caller,
        uint256[] productIds
    );

    function createComposition(
        string memory compositionName,
        uint256[] memory tokenIdsOfTC
    ) external;

    function appendCommodityToComposition(
        uint256 _tokenIdComposition,
        uint256 _tokenIdTC
    ) external;

    function removeCommodityFromComposition(
        uint256 _tokenIdComposition,
        uint256 _indexTokenIdTC
    ) external;

    function decomposition(uint256 _tokenId) external;

    function addTransformation(
        uint256 _tokenId,
        string memory _transformationCode
    ) external;

    function addInformationToComposition(uint256 _tokenId, string memory data)
        external;

    function checkQualityOfComposition(uint256 _tokenId, string memory data)
        external;

    function confirmCompositionLocation(
        uint256 _tokenId,
        uint256 latitude,
        uint256 longitude,
        uint256 radius
    ) external;

    function changeStateAndHandler(
        uint256 _tokenId,
        address _newCurrentHandler,
        State _newState
    ) external;

    // function splitProduct(uint256 _tokenId, uint256[] memory partitions)
    //     external;

    // function batchComposition(uint256[] memory _tokenIds) external;

    function getIdsOfCommodities(uint256 _tokenId)
        external
        view
        returns (uint256[] memory);

    function burnComposition(uint256 _tokenId) external;
}
