// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./TradeCoinFactory.sol";

contract TradeCoinTokenizer is ERC721 {
    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {
        admin = msg.sender;
    }

    using Strings for uint256;

    TradeCoinFactory public tradeCoinFactory;
    address private admin;

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

    // We have a seperate tokenization function for the first time minting, we mint this value to the Farmer address
    function initialTokenization(
        string memory commodity,
        // weight in gram
        uint256 weight
    ) public {
        // Set default transformations to raw
        string[] memory tempArray = new string[](1);
        tempArray[0] = "Raw";

        uint256 id = tradeCoinFactory.getTokenCounter();

        // Mint new token
        _safeMint(_msgSender(), id);
        // Store data on-chain
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
            // TODO: why do this?
            // tempArray[i + 1] = _tokenIdCounter.current();
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
        // TODO: why do this?
        // tempArray[_tokenIds.length] = _tokenIdCounter.current();

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
        uint256 id = tradeCoinFactory.getTokenCounter();

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

    // function getTokenCounterFromFactory() internal returns (uint256) {
    //     return tradeCoinFactory.getTokenCounter();
    // }

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

    function setTradeCoinFactoryAddr(address _tradeCoinFactoryAddr) public {
        require(admin == msg.sender, "You are not the admin");
        tradeCoinFactory = TradeCoinFactory(_tradeCoinFactoryAddr);
    }

    modifier isTradeCoinFactory() {
        require(
            msg.sender == address(tradeCoinFactory),
            "Not the Factory address"
        );
        _;
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
}
