// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./RoleControl.sol";

contract TradeCoinTokenizer is ERC721 {
    using Counters for Counters.Counter;

    struct CommodityStruct {
        CommodityState state;
        string commodityType;
        uint256 weightInGram;
        string[] isoList;
        address pickupAddress;
        address destinationAddress;
    }

    enum CommodityState {
        PendingConfirmation,
        Confirmed,
        PendingProcess,
        Processing,
        PendingTransport,
        Transporting,
        PendingStorage,
        Stored,
        EOL
    }

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("TradeCoinTokenizer", "TCT") {}

    mapping(uint256 => CommodityStruct) public Commodity;

    function safeMint(
        address to,
        uint256 weightInGram,
        string memory commodityType
    ) public {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);

        string[] memory emptyList;
        uint256 id = tokenId;

        CommodityStruct memory _commodity = CommodityStruct(
            CommodityState.PendingConfirmation,
            commodityType,
            weightInGram,
            emptyList,
            address(0),
            address(0)
        );

        Commodity[id] = _commodity;
    }

    function addProcess(uint256 _id, string memory _process) external {
        require(msg.sender == ownerOf(_id), "You are not the owner");
        Commodity[_id].isoList.push(_process);
    }

    function decreaseWeight(uint256 _id, uint256 decreaseAmount) external {
        require(msg.sender == ownerOf(_id), "You are not the owner");
        Commodity[_id].weightInGram -= decreaseAmount;
    }

    function transfer(
        address _to,
        uint256 id,
        uint256 priceInEth,
        address warehouse,
        address financer,
        bool fiat
    ) public {
        bytes memory _data = abi.encode(priceInEth, warehouse, financer, fiat);
        safeTransferFrom(msg.sender, _to, id, _data);
    }

    function dataOf(uint256 _id) public view returns (CommodityStruct memory) {
        CommodityStruct memory _tradeCoinStruct = Commodity[_id];
        require(
            _tradeCoinStruct.pickupAddress != address(0),
            "Token not received"
        );
        return _tradeCoinStruct;
    }

    // modifier onlySetupContract(msg.sender) {
    //     require(msg.sender == SetupAddr)
    // }
}

contract TradeCoinSetup is IERC721Receiver {
    TradeCoinTokenizer tradeCoinTokenizer;
    TradeCoinRights tradeCoinRights;
    TradeCoinData tradeCoinData;

    address public tradeCoinTokenizerAddr;
    address public tradeCoinRightsAddr;
    address public tradeCoinDataAddr;

    constructor() {}

    struct TradeCoindDR {
        uint256 price;
        address farmer;
        address warehouse;
        address financer;
        bool fiat;
    }

    mapping(uint256 => TradeCoindDR) tradecoindr;
    mapping(uint256 => bool) payedEth;

    mapping(uint256 => bool) blockTokenId;

    event saleInitialized(
        uint256 indexed _id,
        address indexed warehouse,
        address indexed financer,
        address farmer,
        bool fiat,
        uint256 price
    );

    event saleCompleted(uint256 indexed _id);
    event saleReversed(uint256 indexed _id);

    function onERC721Received(
        address _farmer,
        address,
        uint256 _idOfTokenizer,
        bytes memory _data
    ) public virtual override returns (bytes4) {
        require(
            tradeCoinTokenizerAddr == msg.sender,
            "This is not the address of the TradeCoin Tokenizer"
        );

        (
            uint256 _price,
            address _warehouse,
            address _financer,
            bool _fiat
        ) = abi.decode(_data, (uint256, address, address, bool));
        TradeCoindDR memory _tradecoindr = TradeCoindDR(
            _price,
            _farmer,
            _warehouse,
            _financer,
            _fiat
        );
        tradecoindr[_idOfTokenizer] = _tradecoindr;
        emit saleInitialized(
            _idOfTokenizer,
            _warehouse,
            _financer,
            _financer,
            _fiat,
            _price
        );

        return this.onERC721Received.selector;
    }

    function setTradeCoinTokenizerAddr(
        address _tradeCoinTokenizerAddr,
        address _tradeCoinRightsAddr,
        address _tradeCoinDataAddr
    ) public {
        tradeCoinTokenizerAddr = _tradeCoinTokenizerAddr;
        tradeCoinRightsAddr = _tradeCoinRightsAddr;
        tradeCoinDataAddr = _tradeCoinDataAddr;
        tradeCoinTokenizer = TradeCoinTokenizer(_tradeCoinTokenizerAddr);
        tradeCoinRights = TradeCoinRights(_tradeCoinRightsAddr);
        tradeCoinData = TradeCoinData(_tradeCoinDataAddr);
    }

    function payForToken(uint256 _id) public payable {
        uint256 _price = tradecoindr[_id].price;
        require(msg.value == _price);
        payedEth[_id] = true;
    }

    function completeSale(uint256 _id) public {
        address _farmer = tradecoindr[_id].farmer;
        address _financer = tradecoindr[_id].financer;
        address _warehouse = tradecoindr[_id].warehouse;

        require(
            msg.sender == _warehouse,
            "You are not part of this transaction"
        );

        bool _fiat = tradecoindr[_id].fiat;
        if (!_fiat) {
            //TODO: discuss
            require(payedEth[_id], "You did not pay yet");
            uint256 _price = tradecoindr[_id].price;
            payable(_farmer).transfer(_price);
        }

        tradeCoinRights.safeMint(_financer);
        tradeCoinData.safeMint(_warehouse);
        emit saleCompleted(_id);
    }

    function reverseSale(uint256 _id) public {
        address _farmer = tradecoindr[_id].farmer;
        address _financer = tradecoindr[_id].financer;
        address _warehouse = tradecoindr[_id].warehouse;

        require(
            msg.sender == _farmer ||
                msg.sender == _financer ||
                msg.sender == _warehouse,
            "You are not part of this transaction"
        );

        tradeCoinTokenizer.safeTransferFrom(address(this), _farmer, _id);

        bool _fiat = tradecoindr[_id].fiat;
        if (!_fiat) {
            //TODO: discuss
            require(payedEth[_id], "You did not pay yet");
            uint256 _price = tradecoindr[_id].price;
            payable(_financer).transfer(_price);
        }

        delete tradecoindr[_id];
        emit saleReversed(_id);
    }

    function addProcess(uint256 _id, string memory _process) external {
        require(
            tradeCoinDataAddr == msg.sender,
            "You are not the owner of this data token"
        );

        tradeCoinTokenizer.addProcess(_id, _process);
    }

    function decreaseWeight(uint256 _id, uint256 decreaseAmount) external {
        require(
            tradeCoinDataAddr == msg.sender,
            "You are not the owner of this data token"
        );

        tradeCoinTokenizer.decreaseWeight(_id, decreaseAmount);
    }

    function blockIdOfToken(uint256 _id, bool _block) external {
        require(
            tradeCoinRightsAddr == msg.sender,
            "You don't own the rights token"
        );
        blockTokenId[_id] = _block;
    }

    modifier isBlocked(uint256 _id) {
        require(
            !blockTokenId[_id],
            "The owner has blocked wrights to this token"
        );
        _;
    }
}

contract TradeCoinRights is ERC721 {
    using Counters for Counters.Counter;

    TradeCoinSetup tradeCoinSetup;
    address public tradeCoinSetupAddr;
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("TradeCoinRights", "TCR") {}

    function safeMint(address to) public {
        require(
            tradeCoinSetupAddr == msg.sender,
            "This is not the address of the TradeCoin Setup"
        );

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function transfer(address _to, uint256 id) public {
        safeTransferFrom(msg.sender, _to, id);
    }

    function setTradeCoinSetupAddr(address _tradeCoinSetupAddr) public {
        tradeCoinSetup = TradeCoinSetup(_tradeCoinSetupAddr);
        tradeCoinSetupAddr = _tradeCoinSetupAddr;
    }
}

contract TradeCoinData is ERC721 {
    using Counters for Counters.Counter;

    TradeCoinSetup tradeCoinSetup;
    address public tradeCoinSetupAddr;
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("TradeCoinData", "TCD") {}

    function safeMint(address to) public {
        require(
            tradeCoinSetupAddr == msg.sender,
            "This is not the address of the TradeCoin Setup"
        );

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function transfer(address _to, uint256 id) public {
        safeTransferFrom(msg.sender, _to, id);
    }

    function setTradeCoinSetupAddr(address _tradeCoinSetupAddr) public {
        tradeCoinSetup = TradeCoinSetup(_tradeCoinSetupAddr);
        tradeCoinSetupAddr = _tradeCoinSetupAddr;
    }

    function addProcess(uint256 _id, string memory _process) external {
        require(
            ownerOf(_id) == msg.sender,
            "You are not the owner of this data token"
        );

        tradeCoinSetup.addProcess(_id, _process);
    }

    function decreaseWeight(uint256 _id, uint256 decreaseAmount) external {
        require(
            ownerOf(_id) == msg.sender,
            "You are not the owner of this data token"
        );

        tradeCoinSetup.decreaseWeight(_id, decreaseAmount);
    }
}

contract TradeCoinERC721 is ERC721 {
    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    using Strings for uint256;
    // SafeMath and Counters for creating unique ProductNFT identifiers
    // incrementing the tokenID by 1 after each mint
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // structure of the metadata
    struct TradeCoin {
        string commodity;
        uint256 weight; // in grams
        State state;
        address currentHandler;
        string[] transformations;
        bytes32 rootHash;
    }

    // Mapping for the metadata of the tradecoin
    mapping(uint256 => TradeCoin) public tradeCoin;
    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    mapping(uint256 => address) public addressOfNewOwner;
    mapping(uint256 => uint256) public priceForOwnership;
    mapping(uint256 => bool) public paymentInFiat;

    // Definition of Events
    event InitialTokenizationEvent(
        uint256 indexed tokenId,
        address indexed functionCaller
    );

    event MintAfterSplitOrBatchEvent(
        uint256 indexed tokenId,
        address indexed functionCaller
    );

    event ApproveTokenizationEvent(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed functionCaller,
        string docHash,
        string docType,
        string rootHash
    );

    event InitiateCommercialTxEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        address indexed buyer,
        bytes32 docHash,
        string docType,
        bytes32 rootHash,
        bool payInFiat
    );

    event AddTransformationEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        bytes32 indexed docHash,
        string docType,
        bytes32 rootHash,
        uint256 weightLoss,
        string transformationCode
    );

    event ChangeStateAndHandlerEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        bytes32 indexed docHash,
        string docType,
        bytes32 rootHash,
        State newState,
        address newCurrentHandler
    );

    event SplitProductEvent(
        uint256 indexed tokenId,
        uint256[] indexed tokenIds,
        address indexed functionCaller,
        uint256[] notIndexedTokenIds
    );

    event BatchProductEvent(
        uint256[] indexed tokenIds,
        address indexed functionCaller,
        uint256[] notIndexedTokenIds
    );

    event FinishCommercialTxEvent(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed functionCaller,
        bytes32 dochash,
        string docType,
        bytes32 rootHash
    );

    event BurnEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        string indexed docHash,
        string docType,
        string rootHash
    );

    event AddInformationEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        bytes32 indexed docHash,
        bytes32 rootHash,
        string docType
    );

    // Enum of state of productNFT
    enum State {
        PendingCreation,
        Created,
        PendingProcess,
        Processing,
        PendingTransport,
        Transporting,
        PendingStorage,
        Stored,
        Burned,
        EOL //end of life
    }

    // Self created modifiers/require
    modifier atState(State _state, uint256 _tokenId) {
        require(
            tradeCoin[_tokenId].state == _state,
            "ProductNFT not in the right state"
        );
        _;
    }

    modifier notAtState(State _state, uint256 _tokenId) {
        require(
            tradeCoin[_tokenId].state != _state,
            "ProductNFT can not be in the current state"
        );
        _;
    }

    modifier onlyLegalOwner(address _sender, uint256 _tokenId) {
        require(ownerOf(_tokenId) == _sender, "Sender is not owner of NFT.");
        _;
    }

    modifier isLegalOwnerOrCurrentHandler(address _sender, uint256 _tokenId) {
        require(
            tradeCoin[_tokenId].currentHandler == _sender ||
                ownerOf(_tokenId) == _sender,
            "Given address is not the Owner nor current Handler."
        );
        _;
    }

    // Function must be overridden as ERC721 and ERC721Enumerable are conflicting
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // Function must be overridden as ERC721 and ERC721Enumerable are conflicting
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Set new baseURI
    // TODO: Set vaultURL as custom variable instead of hardcoded value Only for system admin/Contract owner
    function _baseURI()
        internal
        view
        virtual
        override(ERC721)
        returns (string memory)
    {
        return "http://tradecoin.nl/vault/";
    }

    // Set token URI
    function _setTokenURI(uint256 tokenId) internal virtual {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = tokenId.toString();
    }

    // We have a seperate tokenization function for the first time minting, we mint this value to the Farmer address
    function initialTokenization(
        string memory commodity,
        // weight in gram
        uint256 weight
    ) public {
        require(weight > 0, "Weight can't be 0 or less");
        require(
            keccak256(abi.encodePacked(commodity)) !=
                keccak256(abi.encodePacked("")),
            "Commodity needs to have a value."
        );
        // Set default transformations to raw
        string[] memory tempArray = new string[](1);
        tempArray[0] = "Raw";

        // Get new tokenId by incrementing
        _tokenIdCounter.increment();
        uint256 id = _tokenIdCounter.current();

        // Mint new token
        _safeMint(_msgSender(), id);
        // Store data on-chain
        // TODO: Make state maybe local variable instead of global
        tradeCoin[id] = TradeCoin(
            commodity,
            weight,
            State.PendingCreation,
            _msgSender(),
            tempArray,
            ""
        );

        _setTokenURI(id);
        // Fire off the event
        emit InitialTokenizationEvent(id, _msgSender());
    }

    // Set up sale of token to approve the actual creation of the product
    function initiateCommercialTx(
        uint256 _tokenId,
        uint256 _priceInEth,
        address _newOwner,
        bytes32 _docHash,
        string memory _docType,
        bytes32 _rootHash,
        bool _payInFiat
    ) external onlyLegalOwner(_msgSender(), _tokenId) {
        require(_msgSender() != _newOwner, "You can't sell to yourself");
        if (_payInFiat) {
            require(_priceInEth == 0, "You promised to pay in Fiat.");
        }
        priceForOwnership[_tokenId] = _priceInEth * 1 ether;
        addressOfNewOwner[_tokenId] = _newOwner;
        paymentInFiat[_tokenId] = _payInFiat;
        tradeCoin[_tokenId].rootHash = _rootHash;

        emit InitiateCommercialTxEvent(
            _tokenId,
            _msgSender(),
            _newOwner,
            _docHash,
            _docType,
            _rootHash,
            _payInFiat
        );
    }

    // Changing state from pending to created
    function approveTokenization(
        uint256 _tokenId,
        string memory _docHash,
        string memory _docType,
        string memory _rootHash
    ) external payable atState(State.PendingCreation, _tokenId) {
        require(
            addressOfNewOwner[_tokenId] == _msgSender(),
            "You don't have the right to pay"
        );
        require(
            priceForOwnership[_tokenId] <= msg.value,
            "You did not pay enough"
        );

        address _legalOwner = ownerOf(_tokenId);

        // When not paying in Fiat pay but in Eth
        if (!paymentInFiat[_tokenId]) {
            require(
                priceForOwnership[_tokenId] != 0,
                "This is not listed as an offer"
            );
            payable(_legalOwner).transfer(msg.value);
        }
        // else transfer
        _transfer(_legalOwner, _msgSender(), _tokenId);
        // TODO: DISCUSS: Should we also reset the currentHandler to a new address?

        // Change state and delete memory
        delete priceForOwnership[_tokenId];
        delete addressOfNewOwner[_tokenId];
        tradeCoin[_tokenId].state = State.Created;

        emit ApproveTokenizationEvent(
            _tokenId,
            _legalOwner,
            _msgSender(),
            _docHash,
            _docType,
            _rootHash
        );
    }

    // Can only be called if Owner or approved account
    // In case of being an approved account, this account must be a Minter Role and Burner Role (Admin)
    function addTransformation(
        uint256 _tokenId,
        uint256 weightLoss,
        string memory _transformationCode,
        bytes32 _docHash,
        string memory _docType,
        bytes32 _rootHash
    )
        public
        isLegalOwnerOrCurrentHandler(_msgSender(), _tokenId)
        notAtState(State.PendingCreation, _tokenId)
    {
        require(
            weightLoss > 0 && weightLoss <= tradeCoin[_tokenId].weight,
            "Altered weight can't be 0 nor more than total weight"
        );

        tradeCoin[_tokenId].transformations.push(_transformationCode);
        uint256 newWeight = tradeCoin[_tokenId].weight - weightLoss;
        tradeCoin[_tokenId].weight = newWeight;
        tradeCoin[_tokenId].rootHash = _rootHash;

        emit AddTransformationEvent(
            _tokenId,
            _msgSender(),
            _docHash,
            _docType,
            _rootHash,
            newWeight,
            _transformationCode
        );
    }

    function changeStateAndHandler(
        uint256 _tokenId,
        address _newCurrentHandler,
        State _newState,
        bytes32 _docHash,
        string memory _docType,
        bytes32 _rootHash
    )
        public
        onlyLegalOwner(_msgSender(), _tokenId)
        notAtState(State.PendingCreation, _tokenId)
    {
        tradeCoin[_tokenId].currentHandler = _newCurrentHandler;
        tradeCoin[_tokenId].state = _newState;
        tradeCoin[_tokenId].rootHash = _rootHash;

        emit ChangeStateAndHandlerEvent(
            _tokenId,
            _msgSender(),
            _docHash,
            _docType,
            _rootHash,
            _newState,
            _newCurrentHandler
        );
    }

    function burn(
        uint256 _tokenId,
        string memory _docHash,
        string memory _docType,
        string memory _rootHash
    ) public virtual onlyLegalOwner(_msgSender(), _tokenId) {
        _burn(_tokenId);
        // Remove lingering data to refund gas costs
        delete tradeCoin[_tokenId];
        emit BurnEvent(_tokenId, msg.sender, _docHash, _docType, _rootHash);
    }

    function splitProduct(
        uint256 _tokenId,
        uint256[] memory partitions,
        string memory _docHash,
        string memory _docType,
        string memory _rootHash
    )
        public
        onlyLegalOwner(_msgSender(), _tokenId)
        notAtState(State.PendingCreation, _tokenId)
    {
        require(
            partitions.length <= 3 && partitions.length > 1,
            "Token should be split to 2 or more new tokens, we limit the max to 3."
        );
        // create temp list of tokenIds
        uint256[] memory tempArray = new uint256[](partitions.length + 1);
        tempArray[0] = _tokenId;
        // create temp struct
        TradeCoin memory temporaryStruct = tradeCoin[_tokenId];

        uint256 sumPartitions;
        for (uint256 x; x < partitions.length; x++) {
            require(partitions[x] != 0, "Partitions can't be 0");
            sumPartitions += partitions[x];
        }

        require(
            tradeCoin[_tokenId].weight == sumPartitions,
            "The given amount of partitions do not equal total weight amount."
        );

        burn(_tokenId, _docHash, _docType, _rootHash);
        for (uint256 i; i < partitions.length; i++) {
            mintAfterSplitOrBatch(
                temporaryStruct.commodity,
                partitions[i],
                temporaryStruct.state,
                temporaryStruct.currentHandler,
                temporaryStruct.transformations
            );
            tempArray[i + 1] = _tokenIdCounter.current();
        }

        emit SplitProductEvent(_tokenId, tempArray, _msgSender(), tempArray);
        delete temporaryStruct;
    }

    function batchProduct(
        uint256[] memory _tokenIds,
        string memory _docHash,
        string memory _docType,
        string memory _rootHash
    ) public {
        require(
            _tokenIds.length > 1 && _tokenIds.length <= 3,
            "Maximum batch: 3, minimum: 2"
        );
        bytes32 emptyHash;

        uint256 cummulativeWeight;
        TradeCoin memory short = TradeCoin({
            commodity: tradeCoin[_tokenIds[0]].commodity,
            weight: 0,
            state: tradeCoin[_tokenIds[0]].state,
            currentHandler: tradeCoin[_tokenIds[0]].currentHandler,
            transformations: tradeCoin[_tokenIds[0]].transformations,
            rootHash: emptyHash
        });

        bytes32 hashed = keccak256(abi.encode(short));

        uint256[] memory tempArray = new uint256[](_tokenIds.length + 1);

        for (uint256 tokenId; tokenId < _tokenIds.length; tokenId++) {
            require(
                ownerOf(_tokenIds[tokenId]) == _msgSender(),
                "Unauthorized: The tokens do not have the same owner."
            );
            require(
                tradeCoin[_tokenIds[tokenId]].state != State.PendingCreation,
                "Unauthorized: The tokens are not in the right state."
            );
            TradeCoin memory short2 = TradeCoin({
                commodity: tradeCoin[_tokenIds[tokenId]].commodity,
                weight: 0,
                state: tradeCoin[_tokenIds[tokenId]].state,
                currentHandler: tradeCoin[_tokenIds[tokenId]].currentHandler,
                transformations: tradeCoin[_tokenIds[tokenId]].transformations,
                rootHash: emptyHash
            });
            require(
                hashed == keccak256(abi.encode(short2)),
                "This should be the same hash, one of the fields in the NFT don't match"
            );

            tempArray[tokenId] = _tokenIds[tokenId];
            // create temp struct
            cummulativeWeight += tradeCoin[_tokenIds[tokenId]].weight;
            burn(_tokenIds[tokenId], _docHash, _docType, _rootHash);
            delete tradeCoin[_tokenIds[tokenId]];
        }
        mintAfterSplitOrBatch(
            short.commodity,
            cummulativeWeight,
            short.state,
            short.currentHandler,
            short.transformations
        );
        tempArray[_tokenIds.length] = _tokenIdCounter.current();

        emit BatchProductEvent(tempArray, _msgSender(), tempArray);
    }

    // This function will mint a token to
    function mintAfterSplitOrBatch(
        string memory _commodity,
        uint256 _weight,
        State _state,
        address currentHandler,
        string[] memory transformations
    ) internal {
        // Get new tokenId by incrementing
        _tokenIdCounter.increment();
        uint256 id = _tokenIdCounter.current();

        // Mint new token
        _safeMint(_msgSender(), id);
        // Store data on-chain
        tradeCoin[id] = TradeCoin(
            _commodity,
            _weight,
            _state,
            currentHandler,
            transformations,
            ""
        );

        _setTokenURI(id);

        // Fire off the event
        emit MintAfterSplitOrBatchEvent(id, _msgSender());
    }

    function finishCommercialTx(
        uint256 _tokenId,
        bytes32 _docHash,
        string memory _docType,
        bytes32 _rootHash
    ) public payable notAtState(State.PendingCreation, _tokenId) {
        require(
            addressOfNewOwner[_tokenId] == _msgSender(),
            "You don't have the right to pay"
        );
        require(
            priceForOwnership[_tokenId] <= msg.value,
            "You did not pay enough"
        );
        address legalOwner = ownerOf(_tokenId);

        // When not paying in Fiat pay but in Eth
        if (!paymentInFiat[_tokenId]) {
            require(
                priceForOwnership[_tokenId] != 0,
                "This is not listed as an offer"
            );
            payable(legalOwner).transfer(msg.value);
        }
        // else transfer
        _transfer(legalOwner, _msgSender(), _tokenId);
        // TODO: DISCUSS: Should we also reset the currentHandler t

        // Change state and delete memory
        delete priceForOwnership[_tokenId];
        delete addressOfNewOwner[_tokenId];

        emit FinishCommercialTxEvent(
            _tokenId,
            legalOwner,
            _msgSender(),
            _docHash,
            _docType,
            _rootHash
        );
    }

    function addInformation(
        uint256 _tokenId,
        bytes32 _docHash,
        string memory _docType,
        bytes32 _rootHash
    ) public notAtState(State.PendingCreation, _tokenId) {
        tradeCoin[_tokenId].rootHash = _rootHash;

        emit AddInformationEvent(
            _tokenId,
            _msgSender(),
            _docHash,
            _rootHash,
            _docType
        );
    }

    function getTransformationsbyIndex(
        uint256 _tokenId,
        uint256 _transformationIndex
    ) public view returns (string memory) {
        return tradeCoin[_tokenId].transformations[_transformationIndex];
    }

    function getTransformationsLength(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return tradeCoin[_tokenId].transformations.length;
    }

    function getOwnedTokens(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 totalTokens = balanceOf(_owner);
        uint256[] memory allOwnedTokens = new uint256[](totalTokens);

        // for (uint256 token; token < totalTokens; token++) {
        //     allOwnedTokens[token] = tokenOfOwnerByIndex(_owner, token);
        // }
        return allOwnedTokens;
    }
}

contract TradeCoinSale is IERC721Receiver {
    TradeCoinTokenizer tradeCoinTokenizer;
    address public tradeCoinTokenizerAddr;

    struct TradeCoinSaleData {
        address seller;
        address receiver;
        uint256 priceInWei;
        bool fiat;
        bool isPayed;
    }

    constructor(address _tradeCoinTokenizerAddr) {
        tradeCoinTokenizerAddr = _tradeCoinTokenizerAddr;
        tradeCoinTokenizer = TradeCoinTokenizer(_tradeCoinTokenizerAddr);
    }

    mapping(uint256 => TradeCoinSaleData) private tradeCoinSaleData;
    mapping(uint256 => bool) withdrawnPayment;
    mapping(uint256 => bool) withdrawnToken;

    event SetupSale(
        address indexed seller,
        address indexed receiver,
        uint256 indexed tokenId,
        uint256 priceInWei
    );
    event SetupSale(
        address indexed seller,
        address indexed receiver,
        uint256 indexed tokenId,
        bool fiat
    );
    event DepositPayment(address indexed depositer, uint256 indexed tokenId);
    event WithdrawPayment(address indexed withdrawer, uint256 indexed tokenId);
    event WithdrawToken(address indexed withdrawer, uint256 indexed tokenId);

    function onERC721Received(
        address _seller,
        address,
        uint256 _id,
        bytes memory _data
    ) public virtual override returns (bytes4) {
        require(
            tradeCoinTokenizerAddr == msg.sender,
            "This is not the address of the TradeCoin Tokenizer"
        );

        (uint256 _priceInWei, address _receiver, bool _fiat) = abi.decode(
            _data,
            (uint256, address, bool)
        );
        // bool _isPayed = _fiat ? true : false;
        if (_fiat) {
            emit SetupSale(_seller, _receiver, _id, true);
            tradeCoinSaleData[_id] = TradeCoinSaleData(
                _seller,
                _receiver,
                0,
                true,
                true
            );
            withdrawnPayment[_id] = true;
        } else {
            emit SetupSale(_seller, _receiver, _id, _priceInWei);
            tradeCoinSaleData[_id] = TradeCoinSaleData(
                _seller,
                _receiver,
                _priceInWei,
                false,
                false
            );
            withdrawnPayment[_id] = false;
        }

        withdrawnToken[_id] = false;

        return this.onERC721Received.selector;
    }

    function payForToken(uint256 _id) external payable {
        TradeCoinSaleData memory _tradeCoinSaleData = dataOf(_id);
        require(!_tradeCoinSaleData.isPayed, "This token is already payed for");
        require(
            (_tradeCoinSaleData.priceInWei) == msg.value,
            "This is not the right amount"
        );

        emit DepositPayment(msg.sender, _id);
    }

    function withdrawPayment(uint256 _id) external {
        TradeCoinSaleData memory _tradeCoinSaleData = dataOf(_id);
        require(
            !withdrawnPayment[_id],
            "The payment has already been withdrawn"
        );
        require(!_tradeCoinSaleData.fiat, "This token has been payed in fiat");
        require(_tradeCoinSaleData.isPayed, "This token is not payed for");
        _tradeCoinSaleData.isPayed = false;
        withdrawnPayment[_id] = true;
        payable(_tradeCoinSaleData.seller).transfer(
            _tradeCoinSaleData.priceInWei
        );

        emit WithdrawPayment(msg.sender, _id);
    }

    function withdrawToken(uint256 _id) external {
        TradeCoinSaleData memory _tradeCoinSaleData = dataOf(_id);
        require(!withdrawnToken[_id], "The token has already been withdrawn");
        require(_tradeCoinSaleData.isPayed, "This token is not payed for");
        withdrawnToken[_id] = true;

        tradeCoinTokenizer.safeTransferFrom(
            address(this),
            _tradeCoinSaleData.receiver,
            _id
        );
        emit WithdrawToken(msg.sender, _id);
    }

    function dataOf(uint256 _id)
        public
        view
        returns (TradeCoinSaleData memory)
    {
        TradeCoinSaleData memory _tradeCoinSaleData = tradeCoinSaleData[_id];
        require(_tradeCoinSaleData.seller != address(0), "Token not received");
        return _tradeCoinSaleData;
    }

    // function setTradeCoinSetupAddr(address _tradeCoinTokenizerAddr) public {
    //     tradeCoinTokenizerAddr = _tradeCoinTokenizerAddr;
    //     tradeCoinTokenizer = TradeCoinTokenizer(_tradeCoinTokenizerAddr);
    // }
}
