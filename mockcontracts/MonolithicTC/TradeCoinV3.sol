//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "hardhat/console.sol";

contract TradeCoinV3 is ERC721, ReentrancyGuard {
    using Strings for uint256;

    uint256 public tokenCounter = 0;

    enum TradeCoinState {
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

    struct TradeCoinToken {
        bytes tradeCoinTokenType;
        uint256 weightGram;
        string[] isoList;
        // bytes32 json_sha3;
        TradeCoinState tradeCoinState;
    }

    mapping(uint256 => TradeCoinToken) public tradeCoinToken;
    mapping(uint256 => address) public approvedTransporter;
    mapping(uint256 => address) public approvedProcessor;
    mapping(uint256 => address) public approvedWarehouse;
    mapping(uint256 => address) public transportDestination;
    mapping(uint256 => address) public transportPickUp;

    mapping(uint256 => address) public addressOfNewOwner;
    mapping(uint256 => uint256) public priceForOwnership;
    mapping(uint256 => bool) public payInFiat;

    event tradeCoinTokenPending(
        address indexed creator,
        uint256 indexed _tokenId
    );
    event tradeCoinTokenCreated(
        address indexed seller,
        address indexed receiver,
        uint256 indexed _tokenId
    );
    event tradeCoinTokenDelivered(
        address indexed transporter,
        address indexed receiver,
        uint256 indexed _tokenId
    );
    event tradeCoinTokenProcessed(
        address indexed processor,
        address indexed transporter,
        uint256 indexed _tokenId
    );
    event tradeCoinTokenStored(
        address indexed warehouse,
        address indexed transporter,
        uint256 indexed _tokenId
    );
    event tradeCoinTokenBurned(
        address indexed tradeCoinTokenConsumer,
        uint256 indexed _tokenId
    );

    modifier onlyApprovedProcessor(uint256 _tokenId, address _processor) {
        //Also approve NFT holder?
        require(
            approvedProcessor[_tokenId] == _processor,
            "You don't have the right to process"
        );
        require(
            tradeCoinToken[_tokenId].tradeCoinState ==
                TradeCoinState.Processing ||
                tradeCoinToken[_tokenId].tradeCoinState ==
                TradeCoinState.PendingProcess,
            "Is not set to processing or pending"
        );
        _;
    }

    modifier onlyApprovedTransporter(uint256 _tokenId, address _transporter) {
        require(
            approvedTransporter[_tokenId] == _transporter,
            "You don't have the right to transport"
        );
        require(
            tradeCoinToken[_tokenId].tradeCoinState ==
                TradeCoinState.Transporting ||
                tradeCoinToken[_tokenId].tradeCoinState ==
                TradeCoinState.PendingTransport,
            "Is not set to transporting or pending"
        );
        _;
    }

    modifier onlyApprovedWarehouse(uint256 _tokenId, address _warehouse) {
        require(
            approvedWarehouse[_tokenId] == _warehouse,
            "You don't have the right to store"
        );
        require(
            tradeCoinToken[_tokenId].tradeCoinState == TradeCoinState.Stored ||
                tradeCoinToken[_tokenId].tradeCoinState ==
                TradeCoinState.PendingStorage,
            "Is not set to stored or pending"
        );
        _;
    }

    constructor() ERC721("tradeCoinTokens", "tradeCoinToken") {}

    function minttradeCoinToken(
        uint256 _weightGram,
        string memory _tradeCoinTokenType
    ) public {
        uint256 _tokenId = tokenCounter + 1;
        string[] memory _isoList;
        bytes memory _tradeCoinTokenTypeBytes = abi.encodePacked(
            _tradeCoinTokenType
        );
        // bytes32 _json_sha3 = keccak256(abi.encode(""));
        TradeCoinToken memory _tradeCoinToken = TradeCoinToken(
            _tradeCoinTokenTypeBytes,
            _weightGram,
            _isoList,
            TradeCoinState.PendingCreation
        );

        _mint(msg.sender, _tokenId);
        tradeCoinToken[_tokenId] = _tradeCoinToken;
        tokenCounter = _tokenId;

        emit tradeCoinTokenPending(msg.sender, _tokenId);
    }

    function approvetradeCoinToken(uint256 _tokenId, address _receiver)
        external
    {
        require(
            msg.sender == ERC721.ownerOf(_tokenId),
            "You are not the owner"
        );

        approve(_receiver, _tokenId);
    }

    function createtradeCoinToken(uint256 _tokenId, address _farmer) external {
        transferFrom(_farmer, msg.sender, _tokenId);
        tradeCoinToken[_tokenId].tradeCoinState = TradeCoinState.Created;

        emit tradeCoinTokenCreated(_farmer, msg.sender, _tokenId);
    }

    function transferOwnership(uint256 _tokenId, address _newOwner) external {
        require(
            tradeCoinToken[_tokenId].tradeCoinState !=
                TradeCoinState.PendingCreation,
            "This tradeCoinToken is pending for confirmation"
        );
        transferFrom(msg.sender, _newOwner, _tokenId);
    }

    function setPriceForOwnership(
        uint256 _tokenId,
        uint256 priceInWei,
        address _newOwner,
        bool isFiat
    ) external {
        require(
            msg.sender == ERC721.ownerOf(_tokenId),
            "You are not the owner"
        );
        priceForOwnership[_tokenId] = priceInWei;
        addressOfNewOwner[_tokenId] = _newOwner;
        payInFiat[_tokenId] = isFiat;
    }

    function payForOwnership(uint256 _tokenId) external payable nonReentrant {
        bool _payFiat = !payInFiat[_tokenId];
        require(
            addressOfNewOwner[_tokenId] == msg.sender,
            "You don't have the right to pay"
        );
        require(
            priceForOwnership[_tokenId] != 0 || _payFiat,
            "The NFT has no set price"
        );
        require(
            priceForOwnership[_tokenId] <= msg.value,
            "You did not pay enough"
        );

        address addrOwner = ownerOf(_tokenId);

        priceForOwnership[_tokenId] = 0;
        tradeCoinToken[_tokenId].tradeCoinState = TradeCoinState.Created;

        if (_payFiat) {
            payable(addrOwner).transfer(msg.value);
        }

        _transfer(addrOwner, msg.sender, _tokenId);

        emit tradeCoinTokenCreated(addrOwner, msg.sender, _tokenId);
    }

    function pickuptradeCoinToken(uint256 _tokenId, address _sender)
        external
        onlyApprovedTransporter(_tokenId, msg.sender)
    {
        // require(
        //     tradeCoinToken[_tokenId].TradeCoinState == TradeCoinState.PendingTransport,
        //     "This shipment is not pending for transport"
        // );

        if (
            approvedProcessor[_tokenId] == _sender &&
            transportPickUp[_tokenId] == _sender
        ) {
            emit tradeCoinTokenProcessed(_sender, msg.sender, _tokenId);
            // approvedProcessor[_tokenId] = address(0);
        } else if (
            approvedWarehouse[_tokenId] == _sender &&
            transportPickUp[_tokenId] == _sender
        ) {
            emit tradeCoinTokenStored(_sender, msg.sender, _tokenId);
            // approvedWarehouse[_tokenId] = address(0);
        }

        tradeCoinToken[_tokenId].tradeCoinState = TradeCoinState.Transporting;
    }

    function deliveredtradeCoinToken(uint256 _tokenId, address _receiver)
        external
        onlyApprovedTransporter(_tokenId, msg.sender)
    {
        // require(
        //     tradeCoinToken[_tokenId].TradeCoinState == TradeCoinState.Transporting,
        //     "This shipment is not being transported"
        // );
        if (
            approvedProcessor[_tokenId] == _receiver &&
            transportDestination[_tokenId] == _receiver
        ) {
            tradeCoinToken[_tokenId].tradeCoinState = TradeCoinState
                .PendingProcess;
        } else if (
            approvedWarehouse[_tokenId] == _receiver &&
            transportDestination[_tokenId] == _receiver
        ) {
            tradeCoinToken[_tokenId].tradeCoinState = TradeCoinState
                .PendingStorage;
        } else {
            revert("This is not an approved receiver or destination");
        }
    }

    function transportForProcessor(
        uint256 _tokenId,
        address _transporter,
        address _receiver
    ) external onlyApprovedProcessor(_tokenId, msg.sender) {
        // require(tradeCoinToken[_tokenId].TradeCoinState == TradeCoinState.Processing);
        transportPickUp[_tokenId] = msg.sender;
        transportDestination[_tokenId] = _receiver;

        approvedTransporter[_tokenId] = _transporter;
        tradeCoinToken[_tokenId].tradeCoinState = TradeCoinState
            .PendingTransport;
    }

    function transportForWarehouse(
        uint256 _tokenId,
        address _transporter,
        address _receiver
    ) external onlyApprovedWarehouse(_tokenId, msg.sender) {
        // require(tradeCoinToken[_tokenId].TradeCoinState == TradeCoinState.Stored);
        transportPickUp[_tokenId] = msg.sender;
        transportDestination[_tokenId] = _receiver;

        approvedTransporter[_tokenId] = _transporter;
        tradeCoinToken[_tokenId].tradeCoinState = TradeCoinState
            .PendingTransport;
    }

    function transportForOwner(
        uint256 _tokenId,
        address _transporter,
        address _receiver
    ) external {
        require(
            msg.sender == ERC721.ownerOf(_tokenId),
            "You are not the owner"
        );
        transportPickUp[_tokenId] = msg.sender;
        transportDestination[_tokenId] = _receiver;

        approvedTransporter[_tokenId] = _transporter;
        tradeCoinToken[_tokenId].tradeCoinState = TradeCoinState
            .PendingTransport;
    }

    function processingtradeCoinToken(uint256 _tokenId)
        external
        onlyApprovedProcessor(_tokenId, msg.sender)
    {
        // require(
        //     tradeCoinToken[_tokenId].TradeCoinState == TradeCoinState.PendingProcess,
        //     "The tradeCoinToken has to be pending for process"
        // );
        tradeCoinToken[_tokenId].tradeCoinState = TradeCoinState.Processing;

        emit tradeCoinTokenDelivered(
            approvedTransporter[_tokenId],
            msg.sender,
            _tokenId
        );
        // approvedTransporter[_tokenId] = address(0);
    }

    function storringtradeCoinToken(uint256 _tokenId)
        external
        onlyApprovedWarehouse(_tokenId, msg.sender)
    {
        // require(
        //     tradeCoinToken[_tokenId].TradeCoinState == TradeCoinState.PendingStorage,
        //     "The tradeCoinToken has to be pending for storage"
        // );
        tradeCoinToken[_tokenId].tradeCoinState = TradeCoinState.Stored;

        emit tradeCoinTokenDelivered(
            approvedTransporter[_tokenId],
            msg.sender,
            _tokenId
        );
        // approvedTransporter[_tokenId] = address(0);
    }

    function burningtradeCoinToken(uint256 _tokenId)
        external
        onlyApprovedWarehouse(_tokenId, msg.sender)
    {
        // require(
        //     tradeCoinToken[_tokenId].TradeCoinState == TradeCoinState.Stored,
        //     "The tradeCoinToken has to be in stored"
        // );
        tradeCoinToken[_tokenId].tradeCoinState == TradeCoinState.Burned;

        _burn(_tokenId);

        emit tradeCoinTokenBurned(msg.sender, _tokenId);
    }

    function approveTransporter(address _transporter, uint256 _tokenId) public {
        require(
            msg.sender == ERC721.ownerOf(_tokenId),
            "You are not the owner"
        );

        approvedTransporter[_tokenId] = _transporter;
    }

    function approveProcessor(address _processor, uint256 _tokenId) public {
        require(
            msg.sender == ERC721.ownerOf(_tokenId),
            "You are not the owner"
        );

        approvedProcessor[_tokenId] = _processor;
    }

    function approveWarehouse(address _warehouse, uint256 _tokenId) public {
        require(
            msg.sender == ERC721.ownerOf(_tokenId),
            "You are not the owner"
        );

        approvedWarehouse[_tokenId] = _warehouse;
    }

    function batchtradeCoinTokens(uint256 _tokenId1, uint256 _tokenId2) public {
        require(
            msg.sender == ERC721.ownerOf(_tokenId1) &&
                msg.sender == ERC721.ownerOf(_tokenId2),
            "You are not the owner both NFT's"
        );
        require(
            keccak256(
                abi.encode(tradeCoinToken[_tokenId1].tradeCoinTokenType)
            ) ==
                keccak256(
                    abi.encode(tradeCoinToken[_tokenId2].tradeCoinTokenType)
                ),
            "The tradeCoinTokens have to be the same kind"
        );
        // require(
        //     tradeCoinToken[_tokenId1].TradeCoinState == TradeCoinState.Stored &&
        //         tradeCoinToken[_tokenId2].TradeCoinState == TradeCoinState.Stored,
        //     "The NFT's are not stored"
        // );
        // This will break because a list with the same ISO's but ordered different will produce different hashes
        require(
            keccak256(abi.encode(tradeCoinToken[_tokenId1].isoList)) ==
                keccak256(abi.encode(tradeCoinToken[_tokenId1].isoList)),
            "The tradeCoinTokens have to have the same ISO processes"
        );

        uint256 _weight = tradeCoinToken[_tokenId1].weightGram +
            tradeCoinToken[_tokenId2].weightGram;
        string memory _tradeCoinTokenType = string(
            tradeCoinToken[_tokenId1].tradeCoinTokenType
        );

        _burn(_tokenId1);
        _burn(_tokenId2);

        minttradeCoinToken(_weight, _tradeCoinTokenType);
        tradeCoinToken[tokenCounter].isoList = tradeCoinToken[_tokenId1]
            .isoList;
        tradeCoinToken[tokenCounter].tradeCoinState = TradeCoinState.Stored;

        delete tradeCoinToken[_tokenId1];
        delete tradeCoinToken[_tokenId1];
    }

    function decreaseWeight(uint256 _weightGram, uint256 _tokenId)
        public
        onlyApprovedProcessor(_tokenId, msg.sender)
        returns (uint256)
    {
        // require(tradeCoinToken[_tokenId].TradeCoinState == TradeCoinState.Processing);
        uint256 weight = tradeCoinToken[_tokenId].weightGram;
        require(weight >= _weightGram, "Weight can't be negative");

        console.log(
            "Decreasing weight of %s with amount of %s",
            weight.toString(),
            _weightGram.toString()
        );

        tradeCoinToken[_tokenId].weightGram = weight - _weightGram;

        return tradeCoinToken[_tokenId].weightGram;
    }

    function addISO(string memory _iso, uint256 _tokenId)
        public
        onlyApprovedProcessor(_tokenId, msg.sender)
    {
        // require(tradeCoinToken[_tokenId].TradeCoinState == TradeCoinState.Processing);
        tradeCoinToken[_tokenId].isoList.push(_iso);
    }

    function getISObyIndex(uint256 _tokenId, uint256 _isoIndex)
        public
        view
        returns (string memory)
    {
        return tradeCoinToken[_tokenId].isoList[_isoIndex];
    }

    function getISOLength(uint256 _tokenId) public view returns (uint256) {
        return tradeCoinToken[_tokenId].isoList.length;
    }

    function getTradeCoinState(uint256 _tokenId)
        public
        view
        returns (TradeCoinState)
    {
        return tradeCoinToken[_tokenId].tradeCoinState;
    }

    function gettradeCoinTokenType(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        return string(tradeCoinToken[_tokenId].tradeCoinTokenType);
    }

    function gettradeCoinTokenWeight(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return tradeCoinToken[_tokenId].weightGram;
    }
}
