// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./TradeCoin.sol";
import "./RoleControl.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TradeCoinCompositionERC721 is ERC721, RoleControl, ReentrancyGuard {
    using Strings for uint256;

    uint256 private _tokenIdCounter;

    TradeCoinERC721 public tradeCoinERC721;

    // structure of the metadata
    struct TradeCoinComposition {
        uint256[] tokenIdsOfTC;
        string compositionName;
        uint256 cumulativeAmount;
        bytes32 unit;
        State state;
        address currentHandler;
        string[] transformations;
        bytes32 rootHash;
    }

    struct Documents {
        bytes32[] docHash;
        bytes32[] docType;
        bytes32 rootHash;
    }

    // Enum of state of productNFT
    enum State {
        NonExistent,
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
    event CreateCompositionEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        uint256[] productIds,
        bytes32[] docHash,
        bytes32[] docType,
        bytes32 rootHash
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
        bytes32 indexed docHashIndexed,
        bytes32[] docHash,
        bytes32[] docType,
        bytes32 rootHash,
        State newState,
        address newCurrentHandler
    );

    event RemoveProductFromComposition(
        uint256 indexed tokenId,
        address indexed functionCaller,
        uint256 tokenIdOfProduct
    );

    event AppendProductToComposition(
        uint256 indexed tokenId,
        address indexed functionCaller,
        uint256 tokenIdOfProduct
    );

    event AddInformationEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        bytes32 indexed docHashIndexed,
        bytes32[] docHash,
        bytes32[] docType,
        bytes32 rootHash
    );

    event DecompositionEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        uint256[] productIds,
        bytes32[] docHash,
        bytes32[] docType,
        bytes32 rootHash
    );

    event BurnEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        bytes32 indexed docHashIndexed,
        bytes32[] docHash,
        bytes32[] docType,
        bytes32 rootHash
    );

    // Self created modifiers/require
    modifier atState(State _state, uint256 _tokenId) {
        require(
            tradeCoinComposition[_tokenId].state == _state,
            "Invalid State"
        );
        _;
    }

    modifier notAtState(State _state, uint256 _tokenId) {
        require(
            tradeCoinComposition[_tokenId].state != _state,
            "Invalid State"
        );
        _;
    }

    modifier onlyLegalOwner(address _sender, uint256 _tokenId) {
        require(ownerOf(_tokenId) == _sender, "Not NFTOwner");
        _;
    }

    modifier isLegalOwnerOrCurrentHandler(address _sender, uint256 _tokenId) {
        require(
            tradeCoinComposition[_tokenId].currentHandler == _sender ||
                ownerOf(_tokenId) == _sender,
            "Not Owner/Handler"
        );
        _;
    }

    // Mapping for the metadata of the tradecoinComposition
    mapping(uint256 => TradeCoinComposition) public tradeCoinComposition;
    mapping(uint256 => string) private _tokenURIs;

    mapping(uint256 => address) public addressOfNewOwner;
    mapping(uint256 => uint256) public priceForOwnership;
    mapping(uint256 => bool) public paymentInFiat;

    /// block number in which the contract was deployed.
    uint256 public deployedOn;

    constructor(
        string memory _name,
        string memory _symbol,
        address _tradeCoinERC721
    ) ERC721(_name, _symbol) RoleControl(msg.sender) {
        tradeCoinERC721 = TradeCoinERC721(_tradeCoinERC721);
        deployedOn = block.number;
    }

    function createComposition(
        string memory _compositionName,
        uint256[] memory _tokenIdsOfTC,
        Documents memory _documents
    ) external onlyTokenizerOrAdmin {
        uint256 length = _tokenIdsOfTC.length;
        require(length > 1, "Invalid Length");
        // Get new tokenId by incrementing
        _tokenIdCounter++;
        uint256 id = _tokenIdCounter;

        string[] memory emptyTransformations = new string[](0);

        uint256 totalAmount;
        bytes32 unitOfTC;
        for (uint256 i; i < length; ) {
            tradeCoinERC721.transferFrom(
                msg.sender,
                address(this),
                _tokenIdsOfTC[i]
            );

            (
                ,
                uint256 amountOfTC,
                bytes32 oldUnitOfTC,
                TradeCoinERC721.State stateOfProduct,
                ,

            ) = tradeCoinERC721.tradeCoin(_tokenIdsOfTC[i]);
            require(
                stateOfProduct != TradeCoinERC721.State.PendingCreation,
                "Product still pending"
            );
            totalAmount += amountOfTC;
            unitOfTC = oldUnitOfTC;
            unchecked {
                ++i;
            }
        }

        // Mint new token
        _safeMint(msg.sender, id);
        // Store data on-chain
        tradeCoinComposition[id] = TradeCoinComposition(
            _tokenIdsOfTC,
            _compositionName,
            totalAmount,
            unitOfTC,
            State.Created,
            msg.sender,
            emptyTransformations,
            ""
        );

        _setTokenURI(id);

        // Fire off the event
        emit CreateCompositionEvent(
            id,
            msg.sender,
            _tokenIdsOfTC,
            _documents.docHash,
            _documents.docType,
            _documents.rootHash
        );
    }

    function appendProductToComposition(
        uint256 _tokenIdComposition,
        uint256 _tokenIdTC
    ) external onlyTokenizerOrAdmin {
        // require(
        //     tradeCoinComposition[_tokenIdComposition].state ==
        //         State.PendingCreation,
        //     "This composition is already done"
        // );
        require(ownerOf(_tokenIdComposition) != address(0));

        tradeCoinERC721.transferFrom(msg.sender, address(this), _tokenIdTC);

        tradeCoinComposition[_tokenIdComposition].tokenIdsOfTC.push(_tokenIdTC);

        (, uint256 amountOfTC, , , , ) = tradeCoinERC721.tradeCoin(_tokenIdTC);
        tradeCoinComposition[_tokenIdComposition]
            .cumulativeAmount += amountOfTC;
    }

    function removeProductFromComposition(
        uint256 _tokenIdComposition,
        uint256 _indexTokenIdTC
    ) external onlyTokenizerOrAdmin {
        uint256 lengthTokenIds = tradeCoinComposition[_tokenIdComposition]
            .tokenIdsOfTC
            .length;
        // require(
        //     tradeCoinComposition[_tokenIdComposition].state ==
        //         State.PendingCreation,
        //     "This composition is already done"
        // );
        require(lengthTokenIds > 2, "Invalid lengths");
        require((lengthTokenIds - 1) >= _indexTokenIdTC, "Index not in range");

        uint256 tokenIdTC = tradeCoinComposition[_tokenIdComposition]
            .tokenIdsOfTC[_indexTokenIdTC];
        uint256 lastTokenId = tradeCoinComposition[_tokenIdComposition]
            .tokenIdsOfTC[lengthTokenIds - 1];

        tradeCoinERC721.transferFrom(address(this), msg.sender, tokenIdTC);

        tradeCoinComposition[_tokenIdComposition].tokenIdsOfTC[
            _indexTokenIdTC
        ] = lastTokenId;

        tradeCoinComposition[_tokenIdComposition].tokenIdsOfTC.pop();

        (, uint256 amountOfTC, , , , ) = tradeCoinERC721.tradeCoin(tokenIdTC);
        tradeCoinComposition[_tokenIdComposition]
            .cumulativeAmount -= amountOfTC;
    }

    function decomposition(uint256 _tokenId, Documents memory _documents)
        external
    {
        require(ownerOf(_tokenId) == msg.sender, "Not Owner");

        uint256[] memory productIds = tradeCoinComposition[_tokenId]
            .tokenIdsOfTC;
        uint256 length = productIds.length;
        for (uint256 i; i < length; ) {
            tradeCoinERC721.transferFrom(
                address(this),
                msg.sender,
                productIds[i]
            );
            unchecked {
                ++i;
            }
        }

        delete tradeCoinComposition[_tokenId];
        _burn(_tokenId);

        emit DecompositionEvent(
            _tokenId,
            msg.sender,
            productIds,
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
        notAtState(State.NonExistent, _tokenId)
    {
        require(
            _amountLoss <= tradeCoinComposition[_tokenId].cumulativeAmount,
            "Invalid amount loss"
        );

        tradeCoinComposition[_tokenId].transformations.push(
            _transformationCode
        );
        uint256 newAmount = tradeCoinComposition[_tokenId].cumulativeAmount -
            _amountLoss;
        tradeCoinComposition[_tokenId].cumulativeAmount = newAmount;
        tradeCoinComposition[_tokenId].rootHash = _documents.rootHash;

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
        notAtState(State.NonExistent, _tokenId)
    {
        tradeCoinComposition[_tokenId].currentHandler = _newCurrentHandler;
        tradeCoinComposition[_tokenId].state = _newState;
        tradeCoinComposition[_tokenId].rootHash = _documents.rootHash;

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

    // Function must be overridden as ERC721 and ERC721Enumerable are conflicting

    function addInformation(
        uint256[] memory _tokenIds,
        Documents memory _documents,
        bytes32[] memory _rootHash
    ) external onlyInformationHandlerOrAdmin {
        uint256 length = _tokenIds.length;
        require(length == _rootHash.length, "Invalid Length");

        require(
            _documents.docHash.length == _documents.docType.length &&
                (_documents.docHash.length <= 2 ||
                    _documents.docType.length <= 2),
            "Invalid length"
        );

        for (uint256 _tokenId; _tokenId < length; ) {
            tradeCoinComposition[_tokenIds[_tokenId]].rootHash = _rootHash[
                _tokenId
            ];
            emit AddInformationEvent(
                _tokenIds[_tokenId],
                msg.sender,
                _documents.docHash[0],
                _documents.docHash,
                _documents.docType,
                _rootHash[_tokenId]
            );
            unchecked {
                ++_tokenId;
            }
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

    function burn(uint256 _tokenId, Documents memory _documents)
        public
        virtual
        onlyLegalOwner(msg.sender, _tokenId)
    {
        _burn(_tokenId);
        // Remove lingering data to refund gas costs
        delete tradeCoinComposition[_tokenId];
        emit BurnEvent(
            _tokenId,
            msg.sender,
            _documents.docHash[0],
            _documents.docHash,
            _documents.docType,
            _documents.rootHash
        );
    }

    function getIdsOfComposite(uint256 _tokenId)
        public
        view
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

    function getTransformationsbyIndex(
        uint256 _tokenId,
        uint256 _transformationIndex
    ) public view returns (string memory) {
        return
            tradeCoinComposition[_tokenId].transformations[
                _transformationIndex
            ];
    }

    function getTransformationsLength(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return tradeCoinComposition[_tokenId].transformations.length;
    }

    function ConcatenateArrays(
        uint256[] memory Accounts,
        uint256[] memory Accounts2
    ) internal pure returns (uint256[] memory) {
        uint256 length = Accounts.length;
        uint256[] memory returnArr = new uint256[](length + Accounts2.length);

        uint256 i = 0;
        for (; i < length; ) {
            returnArr[i] = Accounts[i];
            unchecked {
                ++i;
            }
        }

        uint256 j = 0;
        while (j < length) {
            returnArr[i++] = Accounts2[j++];
        }

        return returnArr;
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
        return "http://tradecoinComposition.nl/vault/";
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
}
