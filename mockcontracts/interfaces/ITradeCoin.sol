// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITradeCoin {
    enum State {
        NonExistent,
        Created,
        PendingProcess,
        Processing,
        PendingTransport,
        Transporting,
        PendingStorage,
        Stored,
        EndOfLife
    }

    // Definition of Events
    event MintCommodity(
        uint256 indexed tokenId,
        address indexed tokenizer,
        uint256 tokenIdTCT,
        string commodityName,
        uint256 amount,
        string unit
    );

    event CommodityTransformation(
        uint256 indexed tokenId,
        address indexed transformer,
        string transformation
    );

    event CommodityTransformation(
        uint256 indexed tokenId,
        address indexed transformer,
        string transformation,
        uint256 amountDecrease
    );

    event SplitCommodity(
        uint256 indexed tokenId,
        address indexed splitter,
        uint256[] newTokenIds
    );

    event BatchCommodities(
        uint256 indexed batchedToken,
        address indexed batcher,
        uint256[] tokenIds
    );

    event InitializeSale(
        uint256 indexed tokenIdTCT,
        address indexed seller,
        address indexed buyer,
        uint256 priceInWei,
        bool payInFiat
    );

    event PaymentOfToken(
        uint256 indexed tokenIdTCT,
        address indexed payer,
        uint256 priceInWei
    );

    event CompleteSale(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed functionCaller
    );

    event BurnCommodity(uint256 indexed tokenId, address indexed burner);

    event ChangeStateAndHandler(
        uint256 indexed tokenId,
        address indexed functionCaller,
        address newCurrentHandler,
        State newState
    );

    event QualityCheckCommodity(
        uint256 indexed tokenId,
        address indexed checker,
        string data
    );

    event LocationOfCommodity(
        uint256 indexed tokenId,
        address indexed locationSignaler,
        uint256 latitude,
        uint256 longitude,
        uint256 radius
    );

    event AddInformation(
        uint256 indexed tokenId,
        address indexed functionCaller,
        string data
    );

    event CommodityOutOfChain(
        uint256 indexed tokenId,
        address indexed funCaller
    );

    function initializeSale(
        address owner,
        address handler,
        uint256 tokenIdOfTokenizer,
        uint256 priceInWei
    ) external;

    function paymentOfToken(uint256 tokenIdOfTokenizer) external payable;

    function mintCommodity(uint256 tokenIdOfTokenizer) external;

    function addTransformation(uint256 _tokenId, string memory transformation)
        external;

    function addTransformation(
        uint256 _tokenId,
        string memory transformation,
        uint256 amountDecrease
    ) external;

    function changeCurrentHandlerAndState(
        uint256 _tokenId,
        address newHandler,
        State newCommodityState
    ) external;

    function addInformationToCommodity(uint256 _tokenId, string memory data)
        external;

    function checkQualityOfCommodity(uint256 _tokenId, string memory data)
        external;

    function confirmCommodityLocation(
        uint256 _tokenId,
        uint256 latitude,
        uint256 longitude,
        uint256 radius
    ) external;

    function burnCommodity(uint256 _tokenId) external;

    function batchCommodities(uint256[] memory _tokenIds) external;

    function splitCommodity(uint256 _tokenId, uint256[] memory partitions)
        external;
}
