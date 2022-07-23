// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./RoleControl.sol";
// import "hardhat/console.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TradeCoinERC721 is
    ERC721,
    ERC721Enumerable,
    RoleControl,
    ReentrancyGuard
{
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
        bytes32 docHash,
        string docType,
        bytes32 rootHash
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
        bytes32 dochash,
        string docType,
        bytes32 rootHash
    );

    event BurnEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        bytes32 indexed docHash,
        string docType,
        bytes32 rootHash
    );

    event AddInformationEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        bytes32 indexed docHash,
        string docType,
        bytes32 rootHash
    );

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

    // Maybe needed for future uses
    ///////////////////////////////////////////////////////////////////
    // modifier isLegalOwnerOrApproved(address sender, uint tokenId){
    //     require(_isApprovedOrOwner(sender, tokenId), "Given address is not the Owner nor approved.");
    //     _;
    // }

    // modifier onlyApprovedTransporterState(uint _tokenId) {
    //     require(
    //         tradeCoin[_tokenId].state == State.Transporting ||
    //             tradeCoin[_tokenId].state == State.PendingTransport,
    //         "Is not set to transporting or pending"
    //     );
    //     _;
    // }

    // modifier onlyApprovedProcessorState(uint _tokenId) {
    //     require(
    //         tradeCoin[_tokenId].state == State.Processing ||
    //             tradeCoin[_tokenId].state == State.PendingProcess,
    //         "Is not set to processing or pending"
    //     );
    //     _;
    // }

    // modifier onlyApprovedWarehouseState(uint _tokenId) {
    //     require(
    //         tradeCoin[_tokenId].state == State.Stored ||
    //             tradeCoin[_tokenId].state == State.PendingStorage,
    //         "Is not set to stored or pending"
    //     );
    //     _;
    // }
    ///////////////////////////////////////////////////////////////////

    // Mapping for the metadata of the tradecoin
    mapping(uint256 => TradeCoin) public tradeCoin;
    mapping(uint256 => address) public addressOfNewOwner;
    mapping(uint256 => uint256) public priceForOwnership;
    mapping(uint256 => bool) public paymentInFiat;

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
        RoleControl(msg.sender)
    {}

    // We have a seperate tokenization function for the first time minting, we mint this value to the Farmer address
    function initialTokenization(
        string calldata commodity,
        uint256 weight // weight in gram
    ) external onlyTokenizerOrAdmin {
        require(weight > 0, "Weight can't be 0 or less");

        // Set default transformations to raw
        string[] memory tempArray = new string[](1);
        tempArray[0] = "Raw";

        // Get new tokenId by incrementing
        _tokenIdCounter.increment();
        uint256 id = _tokenIdCounter.current();

        // Mint new token
        _safeMint(msg.sender, id);
        // Store data on-chain
        tradeCoin[id] = TradeCoin(
            commodity,
            weight,
            State.PendingCreation,
            msg.sender,
            tempArray,
            ""
        );

        // Fire off the event
        emit InitialTokenizationEvent(id, msg.sender);
    }

    // Set up sale of token to approve the actual creation of the product
    function initiateCommercialTx(
        uint256 _tokenId,
        uint256 _priceInWei,
        address _newOwner,
        bytes32 _docHash,
        string calldata _docType,
        bytes32 _rootHash,
        bool _payInFiat
    ) external onlyLegalOwner(msg.sender, _tokenId) {
        require(msg.sender != _newOwner, "You can't sell to yourself");
        if (_payInFiat) {
            require(_priceInWei == 0, "You promised to pay in Fiat.");
        }
        priceForOwnership[_tokenId] = _priceInWei;
        addressOfNewOwner[_tokenId] = _newOwner;
        paymentInFiat[_tokenId] = _payInFiat;
        tradeCoin[_tokenId].rootHash = _rootHash;

        emit InitiateCommercialTxEvent(
            _tokenId,
            msg.sender,
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
        bytes32 _docHash,
        string calldata _docType,
        bytes32 _rootHash
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
        // TODO: DISCUSS: Should we also reset the currentHandler to a new address?

        // Change state and delete memory
        delete priceForOwnership[_tokenId];
        delete addressOfNewOwner[_tokenId];
        tradeCoin[_tokenId].state = State.Created;

        emit ApproveTokenizationEvent(
            _tokenId,
            _legalOwner,
            msg.sender,
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
        external
        isLegalOwnerOrCurrentHandler(msg.sender, _tokenId)
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
            msg.sender,
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
        external
        onlyLegalOwner(msg.sender, _tokenId)
        notAtState(State.PendingCreation, _tokenId)
    {
        tradeCoin[_tokenId].currentHandler = _newCurrentHandler;
        tradeCoin[_tokenId].state = _newState;
        tradeCoin[_tokenId].rootHash = _rootHash;

        emit ChangeStateAndHandlerEvent(
            _tokenId,
            msg.sender,
            _docHash,
            _docType,
            _rootHash,
            _newState,
            _newCurrentHandler
        );
    }

    function splitProduct(
        uint256 _tokenId,
        uint256[] memory partitions,
        bytes32 _docHash,
        string memory _docType,
        bytes32 _rootHash
    )
        external
        onlyLegalOwner(msg.sender, _tokenId)
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

        emit SplitProductEvent(_tokenId, msg.sender, tempArray);
        delete temporaryStruct;
    }

    function batchProduct(
        uint256[] memory _tokenIds,
        bytes32 _docHash,
        string calldata _docType,
        bytes32 _rootHash
    ) external {
        require(
            _tokenIds.length > 1 && _tokenIds.length <= 3,
            "Maximum batch: 3, minimum: 2"
        );

        bytes32 emptyHash;
        uint256 cummulativeWeight;
        TradeCoin memory short = TradeCoin({
            commodity: tradeCoin[_tokenIds[0]].commodity,
            state: tradeCoin[_tokenIds[0]].state,
            currentHandler: tradeCoin[_tokenIds[0]].currentHandler,
            transformations: tradeCoin[_tokenIds[0]].transformations,
            weight: 0,
            rootHash: emptyHash
        });

        bytes32 hashed = keccak256(abi.encode(short));

        uint256[] memory tempArray = new uint256[](_tokenIds.length + 1);

        for (uint256 tokenId; tokenId < _tokenIds.length; tokenId++) {
            require(
                ownerOf(_tokenIds[tokenId]) == msg.sender,
                "Unauthorized: The tokens do not have the same owner."
            );
            require(
                tradeCoin[_tokenIds[tokenId]].state != State.PendingCreation,
                "Unauthorized: The tokens are not in the right state."
            );
            TradeCoin memory short2 = TradeCoin({
                commodity: tradeCoin[_tokenIds[tokenId]].commodity,
                state: tradeCoin[_tokenIds[tokenId]].state,
                currentHandler: tradeCoin[_tokenIds[tokenId]].currentHandler,
                transformations: tradeCoin[_tokenIds[tokenId]].transformations,
                weight: 0,
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

        emit BatchProductEvent(msg.sender, tempArray);
    }

    // Function must be overridden as ERC721 and ERC721Enumerable are conflicting

    function finishCommercialTx(
        uint256 _tokenId,
        bytes32 _docHash,
        string calldata _docType,
        bytes32 _rootHash
    )
        external
        payable
        notAtState(State.PendingCreation, _tokenId)
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
        _transfer(legalOwner, msg.sender, _tokenId);
        // TODO: DISCUSS: Should we also reset the currentHandler t

        // Change state and delete memory
        delete priceForOwnership[_tokenId];
        delete addressOfNewOwner[_tokenId];

        emit FinishCommercialTxEvent(
            _tokenId,
            legalOwner,
            msg.sender,
            _docHash,
            _docType,
            _rootHash
        );
    }

    function addInformation(
        uint256 _tokenId,
        bytes32 _docHash,
        string calldata _docType,
        bytes32 _rootHash
    )
        external
        onlyInformationHandlerOrAdmin
        notAtState(State.PendingCreation, _tokenId)
    {
        tradeCoin[_tokenId].rootHash = _rootHash;

        emit AddInformationEvent(
            _tokenId,
            msg.sender,
            _docHash,
            _docType,
            _rootHash
        );
    }

    function burn(
        uint256 _tokenId,
        bytes32 _docHash,
        string memory _docType,
        bytes32 _rootHash
    ) public virtual onlyLegalOwner(msg.sender, _tokenId) {
        _burn(_tokenId);
        // Remove lingering data to refund gas costs
        delete tradeCoin[_tokenId];
        emit BurnEvent(_tokenId, msg.sender, _docHash, _docType, _rootHash);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
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

    function getOwnedTokens(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 totalTokens = balanceOf(_owner);
        uint256[] memory allOwnedTokens = new uint256[](totalTokens);

        for (uint256 token; token < totalTokens; token++) {
            allOwnedTokens[token] = tokenOfOwnerByIndex(_owner, token);
        }
        return allOwnedTokens;
    }

    // This function will mint a token to
    function mintAfterSplitOrBatch(
        string memory _commodity,
        uint256 _weight,
        State _state,
        address currentHandler,
        string[] memory transformations
    ) internal {
        require(_weight != 0, "Weight can't be 0");

        // Get new tokenId by incrementing
        _tokenIdCounter.increment();
        uint256 id = _tokenIdCounter.current();

        // Mint new token
        _safeMint(msg.sender, id);
        // Store data on-chain
        tradeCoin[id] = TradeCoin(
            _commodity,
            _weight,
            _state,
            currentHandler,
            transformations,
            ""
        );

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

    // Function must be overridden as ERC721 and ERC721Enumerable are conflicting
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
