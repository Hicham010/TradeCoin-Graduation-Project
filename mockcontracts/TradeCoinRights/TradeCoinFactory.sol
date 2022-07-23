// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./TradeCoinTokenizer.sol";
import "./TradeCoinRights.sol";
import "./TradeCoinData.sol";

contract TradeCoinFactory is IERC721Receiver {
    TradeCoinTokenizer public tradeCoinTokenizer;
    TradeCoinRights public tradeCoinRights;
    TradeCoinData public tradeCoinData;

    uint256 public tokenCounter;

    address private admin;

    constructor() {
        admin = msg.sender;
    }

    struct TradeCoinDR {
        uint256 price;
        address farmer;
        address warehouse;
        address financer;
        bool fiat;
    }

    mapping(uint256 => TradeCoinDR) public tradecoindr;
    mapping(uint256 => bool) public payedEth;

    mapping(uint256 => bool) public blockTokenId;

    mapping(address => uint256[]) public compositionQueue;

    event SaleInitialized(
        uint256 indexed _id,
        address indexed warehouse,
        address indexed financer,
        address farmer,
        bool fiat,
        uint256 price
    );

    event SaleCompleted(uint256 indexed _id);
    event SaleReversed(uint256 indexed _id);

    function onERC721Received(
        address tokenizer,
        address,
        uint256 id,
        bytes calldata _data
    ) public virtual override returns (bytes4) {
        // require(
        //     address(tradeCoinTokenizer) == msg.sender ||
        //         address(tradeCoinRights) == msg.sender ||
        //         address(tradeCoinData) == msg.sender,
        //     "This is not the address of the TradeCoin Tokenizer, Rights or Data"
        // );

        if (address(tradeCoinTokenizer) == msg.sender) {
            initializeProductSale(tokenizer, id, _data);
        } else if (address(tradeCoinRights) == msg.sender) {} else if (
            address(tradeCoinData) == msg.sender
        ) {} else {
            revert(
                "This is not the address of the TradeCoin Tokenizer, Rights or Data"
            );
        }

        return this.onERC721Received.selector;
    }

    function initializeProductSale(
        address tokenizer,
        uint256 id,
        bytes calldata _data
    ) internal {
        (
            uint256 _price,
            address _warehouse,
            address _financer,
            bool _fiat
        ) = abi.decode(_data, (uint256, address, address, bool));
        TradeCoinDR memory _tradecoindr = TradeCoinDR(
            _price,
            tokenizer,
            _warehouse,
            _financer,
            _fiat
        );
        tradecoindr[id] = _tradecoindr;
        emit SaleInitialized(
            id,
            _warehouse,
            _financer,
            _financer,
            _fiat,
            _price
        );
    }

    // function startComposition()

    // function receiveRights(address tokenizer, uint256[] memory _ids) internal {}

    function setTradeCoinAddresses(
        address _tradeCoinTokenizerAddr,
        address _tradeCoinRightsAddr,
        address _tradeCoinDataAddr
    ) public {
        require(admin == msg.sender, "You are not the admin");

        tradeCoinTokenizer = TradeCoinTokenizer(_tradeCoinTokenizerAddr);
        tradeCoinRights = TradeCoinRights(_tradeCoinRightsAddr);
        tradeCoinData = TradeCoinData(_tradeCoinDataAddr);
    }

    function getTokenCounter() external returns (uint256 _tokenCounter) {
        _tokenCounter = tokenCounter;
        tokenCounter += 1;
    }

    function payForToken(uint256 _id) public payable {
        uint256 _price = tradecoindr[_id].price;
        require(msg.value == _price, "Payment does not match price");
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
        emit SaleCompleted(_id);
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
        emit SaleReversed(_id);
    }

    function initializeComposition(uint256[] memory _ids) external {
        for (uint256 i; i < _ids.length; i++) {
            require(
                tradeCoinRights.ownerOf(_ids[i]) == msg.sender,
                "You don't own these tokens"
            );
            tradeCoinRights.safeTransferFrom(
                msg.sender,
                address(this),
                _ids[i]
            );
        }
        // emit CompositionInitialized();
    }

    function addTransformation(
        uint256 _tokenId,
        uint256 weightLoss,
        string memory _transformationCode,
        bytes32 _docHash,
        string memory _docType,
        bytes32 _rootHash
    ) public isTradeCoinData {
        tradeCoinTokenizer.addTransformation(
            _tokenId,
            weightLoss,
            _transformationCode,
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
    ) public isTradeCoinData {
        tradeCoinTokenizer.addInformation(
            _tokenId,
            _docHash,
            _docType,
            _rootHash
        );
    }

    function changeStateAndHandler(
        uint256 _tokenId,
        address _newCurrentHandler,
        uint8 _newState,
        bytes32 _docHash,
        string memory _docType,
        bytes32 _rootHash
    ) public isTradeCoinData {
        tradeCoinTokenizer.changeStateAndHandler(
            _tokenId,
            _newCurrentHandler,
            tokenizerStateAdapter(_newState),
            _docHash,
            _docType,
            _rootHash
        );
    }

    function tokenizerStateAdapter(uint8 indexState)
        internal
        pure
        returns (TradeCoinTokenizer.State)
    {
        if (indexState == uint8(0))
            return TradeCoinTokenizer.State.PendingCreation;
        else if (indexState == 1) return TradeCoinTokenizer.State.Created;
        else if (indexState == 2)
            return TradeCoinTokenizer.State.PendingProcess;
        else if (indexState == 3) return TradeCoinTokenizer.State.Processing;
        else if (indexState == 4)
            return TradeCoinTokenizer.State.PendingTransport;
        else if (indexState == 5) return TradeCoinTokenizer.State.Transporting;
        else if (indexState == 6)
            return TradeCoinTokenizer.State.PendingStorage;
        else if (indexState == 7) return TradeCoinTokenizer.State.Stored;
        else if (indexState == 8) return TradeCoinTokenizer.State.Burned;
        else if (indexState == 9) return TradeCoinTokenizer.State.EOL;
        revert("Index not found in enum");
    }

    function blockIdOfToken(uint256 _id, bool _block) external {
        require(
            address(tradeCoinRights) == msg.sender,
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

    modifier isTradeCoinData() {
        require(
            msg.sender == address(tradeCoinData),
            "Is not the data address"
        );
        _;
    }
}
