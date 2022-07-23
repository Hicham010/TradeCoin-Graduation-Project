// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./RoleControl.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TradeCoinERC721 is
    ERC721,
    RoleControl,
    ReentrancyGuard
{
    // SafeMath and Counters for creating unique ProductNFT identifiers
    // incrementing the tokenID by 1 after each mint
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    using Strings for uint;

    // structure of the metadata
    struct TradeCoin {
        string product;
        uint256 amount; // can be in grams, liters, etc
        bytes32 unit;
        State state;
        address currentHandler;
        string[] transformations;
        bytes32 rootHash;
    }

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

    struct Documents {
        bytes32[] docHash;
        bytes32[] docType;
        bytes32 rootHash;
    }

    // Definition of Events
    event InitialTokenizationEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        string geoLocation
    );

    event MintAfterSplitOrBatchEvent(
        uint256 indexed tokenId,
        address indexed functionCaller
    );

    event ApproveTokenizationEvent(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed functionCaller,
        bytes32[] docHash,
        bytes32[] docType,
        bytes32 rootHash
    );

    event InitiateCommercialTxEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        address indexed buyer,
        bytes32[] docHash,
        bytes32[] docType,
        bytes32 rootHash,
        bool payInFiat
    );

    event AddTransformationEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        bytes32 indexed docHashIndexed,
        bytes32[] docHash, 
        bytes32[] docType,
        bytes32 rootHash,
        uint256 weightLoss,
        string transformationCode
    );

    event ChangeStateAndHandlerEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        bytes32 docHashIndexed,
        bytes32[] docHash,
        bytes32[] docType,
        bytes32 rootHash,
        State newState,
        address newCurrentHandler
    );

    event SplitProductEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        uint256[] notIndexedTokenIds
    );

    event BatchProductEvent(
        address indexed functionCaller,
        uint256[] notIndexedTokenIds
    );

    event FinishCommercialTxEvent(
        uint256 indexed tokenId,
        address indexed seller, 
        address indexed functionCaller, 
        bytes32[] dochash,
        bytes32[] docType,
        bytes32 rootHash
    );

    event ServicePaymentEvent(
        uint256 indexed tokenId,
        address indexed receiver,
        address indexed sender,
        bytes32 indexedDocHash,
        bytes32[] docHash,
        bytes32[] docType,
        bytes32 rootHash,
        uint256 paymentInWei,
        bool payInFiat
    );

    event BurnEvent(
        uint256 indexed tokenId,
        address indexed functionCaller, 
        bytes32 docHashIndexed,
        bytes32[] docHash,
        bytes32[] docType,
        bytes32 rootHash
    );

    event AddInformationEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        bytes32 docHashIndexed,
        bytes32[] docHash,
        bytes32[] docType,
        bytes32 rootHash
    );

    event UnitConversionEvent(
        uint256 indexed tokenId,
        uint256 indexed amount,
        bytes32 previousAmountUnit,
        bytes32 newAmountUnit
    );

    // Self created modifiers/require
    modifier atState(State _state, uint256 _tokenId) {
        require(
            tradeCoin[_tokenId].state == _state,
            "Incorrect State"
        );
        _;
    }

    modifier notAtState(State _state, uint256 _tokenId) {
        require(
            tradeCoin[_tokenId].state != _state,
            "Incorrect State"
        );
        _;
    }

    modifier onlyLegalOwner(address _sender, uint256 _tokenId) {
        require(ownerOf(_tokenId) == _sender, "Not Owner");
        _;
    }

    modifier isLegalOwnerOrCurrentHandler(address _sender, uint256 _tokenId) {
        require(
            tradeCoin[_tokenId].currentHandler == _sender ||
                ownerOf(_tokenId) == _sender,
            "Not the Owner nor current Handler."
        );
        _;
    }

    /// block number in which the contract was deployed.
    uint public deployedOn;

    // Mapping for the metadata of the tradecoin
    mapping(uint256 => TradeCoin) public tradeCoin;
    mapping(uint256 => string) private _tokenURIs;

    mapping(uint256 => address) public addressOfNewOwner;
    mapping(uint256 => uint256) public priceForOwnership;
    mapping(uint256 => bool) public paymentInFiat;

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
        RoleControl(msg.sender)
    {
        deployedOn = block.number;
    }

    // We have a seperate tokenization function for the first time minting, we mint this value to the Farmer address
    function initialTokenization(
        string memory _product,
        uint256 _amount,
        bytes32 _unit,
        string memory _geoLocation
    ) external onlyTokenizerOrAdmin {
        require(_amount > 0, "Weight can't be 0");

        // Set default transformations to raw
        string[] memory tempArray = new string[](1);
        tempArray[0] = "Raw";

        // Get new tokenId by incrementing
        _tokenIdCounter.increment();
        uint256 id = _tokenIdCounter.current();

        // Mint new token
        _mint(msg.sender, id);
        // Store data on-chain
        tradeCoin[id] = TradeCoin(
            _product,
            _amount,
            _unit,
            State.PendingCreation,
            msg.sender,
            tempArray,
            ""
        );

        _setTokenURI(id);

        // Fire off the event
        emit InitialTokenizationEvent(id, msg.sender, _geoLocation);
    }

    function unitConversion(
        uint256 _tokenId,
        uint256 _amount,
        bytes32 _previousAmountUnit,
        bytes32 _newAmountUnit
    ) external onlyLegalOwner(msg.sender, _tokenId) {
        require(_amount > 0, "Can't be 0");
        require(_previousAmountUnit != _newAmountUnit, "Invalid Conversion");
        require(_previousAmountUnit == tradeCoin[_tokenId].unit, "Invalid Match: unit");

        tradeCoin[_tokenId].amount = _amount;
        tradeCoin[_tokenId].unit = _newAmountUnit;

        emit UnitConversionEvent(_tokenId, _amount, _previousAmountUnit, _newAmountUnit);
    }

    // Set up sale of token to approve the actual creation of the product
    function initiateCommercialTx(
        uint256 _tokenId,
        uint256 _paymentInWei,
        address _newOwner,
        Documents memory _documents,
        bool _payInFiat
    ) external onlyLegalOwner(msg.sender, _tokenId) {
        require(msg.sender != _newOwner, "You can't sell to yourself");
        require(
            _documents.docHash.length == _documents.docType.length && 
                (_documents.docHash.length <= 2 || _documents.docType.length <= 2), 
            "Invalid length"
        );
        if(_payInFiat){
            require(_paymentInWei == 0, "Not eth amount");
        } else {
            require(_paymentInWei != 0, "Not Fiat amount");
        }
        priceForOwnership[_tokenId] = _paymentInWei;
        addressOfNewOwner[_tokenId] = _newOwner;
        paymentInFiat[_tokenId] = _payInFiat;
        tradeCoin[_tokenId].rootHash = _documents.rootHash;

        emit InitiateCommercialTxEvent(
            _tokenId,
            msg.sender,
            _newOwner,
            _documents.docHash,
            _documents.docType,
            _documents.rootHash,
            _payInFiat
        );
    }

    // Changing state from pending to created
    function approveTokenization(
        uint256 _tokenId, 
        Documents memory _documents
    ) 
        external 
        payable 
        onlyProductHandlerOrAdmin
        atState(State.PendingCreation, _tokenId)
        nonReentrant
    {
        require(
            addressOfNewOwner[_tokenId] == msg.sender,
            "You don't have the right to pay"
        );

        require(
            priceForOwnership[_tokenId] <= msg.value,
            "You did not pay enough"
        );

        require(
            _documents.docHash.length == _documents.docType.length && 
                (_documents.docHash.length <= 2 || _documents.docType.length <= 2), 
            "Invalid length"
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
        _transfer(_legalOwner, msg.sender, _tokenId);

        // Change state and delete memory
        delete priceForOwnership[_tokenId];
        delete addressOfNewOwner[_tokenId];
        tradeCoin[_tokenId].state = State.Created;

        emit ApproveTokenizationEvent(
            _tokenId,
            _legalOwner,
            msg.sender,
            _documents.docHash,
            _documents.docType,
            _documents.rootHash
        );
    }

    // Can only be called if Owner or approved account
    // In case of being an approved account, this account must be a Minter Role and Burner Role (Admin)
    function addTransformation(
        uint256 _tokenId, 
        uint256 _amountLoss,
        string memory _transformationCode,
        Documents memory _documents
    ) 
        external 
        isLegalOwnerOrCurrentHandler(msg.sender, _tokenId) 
        notAtState(State.PendingCreation, _tokenId)
    {
        require(_amountLoss > 0 && _amountLoss < tradeCoin[_tokenId].amount, 
            "Invalid Weightloss"
        );

        require(
            _documents.docHash.length == _documents.docType.length && 
                (_documents.docHash.length <= 2 || _documents.docType.length <= 2), 
            "Invalid length"
        );

        tradeCoin[_tokenId].transformations.push(_transformationCode);
        uint256 newAmount = tradeCoin[_tokenId].amount - _amountLoss;
        tradeCoin[_tokenId].amount = newAmount;
        tradeCoin[_tokenId].rootHash = _documents.rootHash;
        
        emit AddTransformationEvent(
            _tokenId,
            msg.sender,
            _documents.docHash[0],
            _documents.docHash,
            _documents.docType,
            _documents.rootHash,
            newAmount,
            _transformationCode
        );
    }

    function changeStateAndHandler(
        uint256 _tokenId,
        address _newCurrentHandler,
        State _newState,
        Documents memory _documents
    ) 
        external 
        onlyLegalOwner(msg.sender, _tokenId) 
        notAtState(State.PendingCreation, _tokenId)
    {
        require(
            _documents.docHash.length == _documents.docType.length && 
                (_documents.docHash.length <= 2 || _documents.docType.length <= 2), 
            "Invalid length"
        );

        tradeCoin[_tokenId].currentHandler = _newCurrentHandler;
        tradeCoin[_tokenId].state = _newState;
        tradeCoin[_tokenId].rootHash = _documents.rootHash;

        emit ChangeStateAndHandlerEvent(
            _tokenId,
            msg.sender,
            _documents.docHash[0],
            _documents.docHash,
            _documents.docType,
            _documents.rootHash,
            _newState,
            _newCurrentHandler
        );
    }

    function splitProduct(
        uint256 _tokenId, 
        uint256[] memory partitions,
        Documents memory _documents
    ) 
        external
        onlyLegalOwner(msg.sender, _tokenId)
        notAtState(State.PendingCreation, _tokenId)
    {
        require(
            partitions.length <= 3 && partitions.length > 1,
            "Max 3, Min 2 tokens"
        );
        require(
            _documents.docHash.length == _documents.docType.length && 
                (_documents.docHash.length <= 2 || _documents.docType.length <= 2), 
            "Invalid Length"
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
            tradeCoin[_tokenId].amount == sumPartitions,
            "Incorrect sum of amount"
        );

        burn(_tokenId, _documents);
        for (uint256 i; i < partitions.length; i++){
            mintAfterSplitOrBatch(
                temporaryStruct.product,
                partitions[i],
                temporaryStruct.unit,
                temporaryStruct.state,
                temporaryStruct.currentHandler,
                temporaryStruct.transformations
            );
            tempArray[i + 1] = _tokenIdCounter.current();
        }

        emit SplitProductEvent(_tokenId, msg.sender, tempArray);
        delete temporaryStruct;
    }

    function batchProduct(
        uint256[] memory _tokenIds,
        Documents memory _documents
    ) external {
        require(
            _tokenIds.length > 1 && _tokenIds.length <= 3,
            "Maximum batch: 3, minimum: 2"
        );

        require(
            _documents.docHash.length == _documents.docType.length && 
                (_documents.docHash.length <= 2 || _documents.docType.length <= 2), 
            "Invalid length"
        );

        bytes32 emptyHash;
        uint256 cummulativeAmount;
        TradeCoin memory short = TradeCoin({
            product: tradeCoin[_tokenIds[0]].product,
            state: tradeCoin[_tokenIds[0]].state,
            currentHandler: tradeCoin[_tokenIds[0]].currentHandler,
            transformations: tradeCoin[_tokenIds[0]].transformations,
            amount: 0,
            unit: tradeCoin[_tokenIds[0]].unit,
            rootHash: emptyHash
        });

        bytes32 hashed = keccak256(abi.encode(short));

        uint256[] memory tempArray = new uint256[](_tokenIds.length + 1);

        for (uint256 tokenId; tokenId < _tokenIds.length; tokenId++) {
            require(
                ownerOf(_tokenIds[tokenId]) == msg.sender,
                "Unauthorized"
            );
            require(
                tradeCoin[_tokenIds[tokenId]].state != State.PendingCreation,
                "Invalid State"
            );
            TradeCoin memory short2 = TradeCoin({
                product: tradeCoin[_tokenIds[tokenId]].product,
                state: tradeCoin[_tokenIds[tokenId]].state,
                currentHandler: tradeCoin[_tokenIds[tokenId]].currentHandler,
                transformations: tradeCoin[_tokenIds[tokenId]].transformations,
                amount: 0,
                unit: tradeCoin[_tokenIds[tokenId]].unit,
                rootHash: emptyHash
            });
            require(
                hashed == keccak256(abi.encode(short2)),
                "Invalid PNFT"
            );

            tempArray[tokenId] = _tokenIds[tokenId];
            // create temp struct
            cummulativeAmount += tradeCoin[_tokenIds[tokenId]].amount;
            burn(_tokenIds[tokenId], _documents);
            delete tradeCoin[_tokenIds[tokenId]];
        }
        mintAfterSplitOrBatch(
            short.product,
            cummulativeAmount,
            short.unit,
            short.state,
            short.currentHandler,
            short.transformations
        );
        tempArray[_tokenIds.length] = _tokenIdCounter.current();

        emit BatchProductEvent(msg.sender, tempArray);
    }

    function finishCommercialTx(
        uint256 _tokenId, 
        Documents memory _documents
    )
        external
        payable
        notAtState(State.PendingCreation, _tokenId)
        nonReentrant
    {
        require(
            addressOfNewOwner[_tokenId] == msg.sender,
            "Unauthorized"
        );

        require(
            priceForOwnership[_tokenId] <= msg.value,
            "Insufficient funds"
        );

        require(
            _documents.docHash.length == _documents.docType.length && 
                (_documents.docHash.length <= 2 || _documents.docType.length <= 2), 
            "Invalid length"
        );

        address legalOwner = ownerOf(_tokenId);

        // When not paying in Fiat pay but in Eth
        if (!paymentInFiat[_tokenId]) {
            require(
                priceForOwnership[_tokenId] != 0,
                "Not for sale"
            );
            payable(legalOwner).transfer(msg.value);
        }
        // else transfer
        _transfer(legalOwner, msg.sender, _tokenId);

        // Change state and delete memory
        delete priceForOwnership[_tokenId];
        delete addressOfNewOwner[_tokenId];

        emit FinishCommercialTxEvent(
            _tokenId,
            legalOwner,
            msg.sender,
            _documents.docHash,
            _documents.docType,
            _documents.rootHash
        );
    }

    function servicePayment(
        uint256 _tokenId,
        address _receiver,
        uint256 _paymentInWei,
        bool _payInFiat,
        Documents memory _documents
    ) 
        payable
        external
        nonReentrant
    {
        require(
            _documents.docHash.length == _documents.docType.length && 
                (_documents.docHash.length <= 2 || _documents.docType.length <= 2), 
            "Invalid length"
        );

        // When not paying in Fiat pay but in Eth
        if (!_payInFiat) {
            require(_paymentInWei >= msg.value && _paymentInWei > 0, "Promised to pay in Fiat");
            payable(_receiver).transfer(msg.value);
        }

        emit ServicePaymentEvent(
            _tokenId,
            _receiver,
            msg.sender,
            _documents.docHash[0],
            _documents.docHash,
            _documents.docType,
            _documents.rootHash,
            _paymentInWei,
            _payInFiat
        );
    }

    function addInformation(
        uint256[] memory _tokenIds, 
        Documents memory _documents,
        bytes32[] memory _rootHash
    ) 
        external
        onlyInformationHandlerOrAdmin
    {
        require(_tokenIds.length == _rootHash.length, 
            "Invalid Length"
        );

        require(
            _documents.docHash.length == _documents.docType.length && 
                (_documents.docHash.length <= 2 || _documents.docType.length <= 2), 
            "Invalid length"
        );
        
        for(uint256 _tokenId; _tokenId < _tokenIds.length; _tokenId++){
            tradeCoin[_tokenIds[_tokenId]].rootHash = _rootHash[_tokenId];
            emit AddInformationEvent(_tokenIds[_tokenId], msg.sender, _documents.docHash[0], _documents.docHash, _documents.docType, _rootHash[_tokenId]);
        }
    }

    function massApproval(uint256[] memory _tokenIds, address to) external {
        for (uint256 i; i < _tokenIds.length; i++) {
            require(
                ownerOf(_tokenIds[i]) == msg.sender,
                "You are not the approver"
            );
            approve(to, _tokenIds[i]);
        }
    }

    function burn(
        uint256 _tokenId,
        Documents memory _documents
    ) public virtual onlyLegalOwner(msg.sender, _tokenId) {
        require(
            _documents.docHash.length == _documents.docType.length && 
                (_documents.docHash.length <= 2 || _documents.docType.length <= 2), 
            "Invalid Length"
        );

        _burn(_tokenId);
        // Remove lingering data to refund gas costs
        delete tradeCoin[_tokenId];
        emit BurnEvent(
            _tokenId,
            msg.sender,
            _documents.docHash[0],
            _documents.docHash,
            _documents.docType,
            _documents.rootHash
        );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
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

    // This function will mint a token to
    function mintAfterSplitOrBatch(
        string memory _product,
        uint256 _amount,
        bytes32 _unit,
        State _state,
        address currentHandler,
        string[] memory transformations
    ) internal {
        require(_amount != 0, "Insufficient Amount");

        // Get new tokenId by incrementing
        _tokenIdCounter.increment();
        uint256 id = _tokenIdCounter.current();

        // Mint new token
        _mint(msg.sender, id);
        // Store data on-chain
        tradeCoin[id] = TradeCoin(
            _product,
            _amount,
            _unit,
            _state,
            currentHandler,
            transformations,
            ""
        );

        _setTokenURI(id);

        // Fire off the event
        emit MintAfterSplitOrBatchEvent(id, msg.sender);
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
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = tokenId.toString();
    }

    // Function must be overridden as ERC721 are conflicting
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
