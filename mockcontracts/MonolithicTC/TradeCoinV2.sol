//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "hardhat/console.sol";

contract TradeCoinV2 is ERC721 {
    using Strings for uint256;

    uint256 public tokenCounter = 0;

    enum TradeCoinCommodityState {
        PendingCreation,
        Created,
        PendingProcess,
        Processing,
        PendingTransport,
        Transporting,
        PendingStorage,
        Stored,
        Burned,
        EOL
    }

    struct TradeCoinCommodity {
        string tradeCoinCommodity_type;
        // uint total_bags;
        // uint[] weights;
        uint256 weight_gram;
        string[] ISO_list;
        // bytes32 json_sha3;
        TradeCoinCommodityState tradeCoinCommodity_state;
    }

    mapping(uint256 => TradeCoinCommodity) public tradeCoinCommodity;
    mapping(uint256 => address) public approvedTransporter;
    mapping(uint256 => address) public approvedProcessor;
    mapping(uint256 => address) public approvedWarehouse;
    mapping(uint256 => address) public transportDestination;
    mapping(uint256 => address) public transportPickUp;

    event TradeCoinCommodityPending(
        address indexed creator,
        uint256 indexed _tokenId
    );
    event TradeCoinCommodityCreated(
        address indexed seller,
        address indexed receiver,
        uint256 indexed _tokenId
    );
    event TradeCoinCommodityDelivered(
        address indexed transporter,
        address indexed receiver,
        uint256 indexed _tokenId
    );
    event TradeCoinCommodityProcessed(
        address indexed processor,
        address indexed receiver,
        uint256 indexed _tokenId
    );
    event TradeCoinCommodityStored(
        address indexed warehouse,
        address indexed receiver,
        uint256 indexed _tokenId
    );
    event TradeCoinCommodityBurned(
        address indexed tradeCoinCommodityConsumer,
        uint256 indexed _tokenId
    );

    modifier onlyApprovedProcessor(uint256 _tokenId, address _processor) {
        //Also approve NFT holder?
        require(
            approvedTransporter[_tokenId] == _processor,
            "You don't have the right to "
        );
        // require(tradeCoinCommodity[_tokenId].tradeCoinCommodity_state == TradeCoinCommodityState.Transporting, "Is not set to transporting");
        _;
    }

    modifier onlyApprovedTransporter(uint256 _tokenId, address _transporter) {
        require(
            approvedTransporter[_tokenId] == _transporter,
            "You don't have the right to add processes"
        );
        // require(tradeCoinCommodity[_tokenId].tradeCoinCommodity_state == TradeCoinCommodityState.Processing, "Is not set to transporting");
        _;
    }

    modifier onlyApprovedWarehouse(uint256 _tokenId, address _warehouse) {
        require(
            approvedWarehouse[_tokenId] == _warehouse,
            "You don't have the right to store"
        );
        // require(tradeCoinCommodity[_tokenId].tradeCoinCommodity_state == TradeCoinCommodityState.Stored, "Is not set to stored");
        _;
    }

    constructor() ERC721("tradeCoinCommoditys", "TCC") {}

    function minttradeCoinCommodity(
        uint256 _weight_gram,
        string memory _tradeCoinCommodity_type
    ) external {
        uint256 _tokenId = tokenCounter + 1;
        string[] memory _ISO_list;
        // bytes32 _json_sha3 = keccak256(abi.encode(""));
        TradeCoinCommodity memory _tradeCoinCommodity = TradeCoinCommodity(
            _tradeCoinCommodity_type,
            _weight_gram,
            _ISO_list,
            TradeCoinCommodityState.PendingCreation
        );

        _mint(msg.sender, _tokenId);
        tradeCoinCommodity[_tokenId] = _tradeCoinCommodity;
        tokenCounter = _tokenId;

        emit TradeCoinCommodityPending(msg.sender, _tokenId);
    }

    function approvetradeCoinCommodity(uint256 _tokenId, address _receiver)
        external
    {
        require(
            msg.sender == ERC721.ownerOf(_tokenId),
            "You are not the owner"
        );

        approve(_receiver, _tokenId);
    }

    function createtradeCoinCommodity(uint256 _tokenId, address _buyer)
        external
    {
        transferFrom(_buyer, msg.sender, _tokenId);
        tradeCoinCommodity[_tokenId]
            .tradeCoinCommodity_state = TradeCoinCommodityState.Created;

        emit TradeCoinCommodityCreated(_buyer, msg.sender, _tokenId);
    }

    function transferOwnership(uint256 _tokenId, address _newOwner) external {
        require(
            tradeCoinCommodity[_tokenId].tradeCoinCommodity_state !=
                TradeCoinCommodityState.PendingCreation,
            "This tradeCoinCommodity is pending for confirmation"
        );
        transferFrom(_newOwner, msg.sender, _tokenId);
    }

    function pickuptradeCoinCommodity(uint256 _tokenId, address _sender)
        external
        onlyApprovedTransporter(_tokenId, msg.sender)
    {
        require(
            tradeCoinCommodity[_tokenId].tradeCoinCommodity_state ==
                TradeCoinCommodityState.PendingTransport
        );

        if (
            approvedProcessor[_tokenId] == _sender &&
            transportPickUp[_tokenId] == _sender
        ) {
            emit TradeCoinCommodityProcessed(_sender, msg.sender, _tokenId);
            // approvedProcessor[_tokenId] = address(0);
        } else if (
            approvedWarehouse[_tokenId] == _sender &&
            transportPickUp[_tokenId] == _sender
        ) {
            emit TradeCoinCommodityStored(_sender, msg.sender, _tokenId);
            // approvedWarehouse[_tokenId] = address(0);
        }

        tradeCoinCommodity[_tokenId]
            .tradeCoinCommodity_state = TradeCoinCommodityState.Transporting;
    }

    function deliveredtradeCoinCommodity(uint256 _tokenId, address _receiver)
        external
        onlyApprovedTransporter(_tokenId, msg.sender)
    {
        if (
            approvedProcessor[_tokenId] == _receiver &&
            transportDestination[_tokenId] == _receiver
        ) {
            tradeCoinCommodity[_tokenId]
                .tradeCoinCommodity_state = TradeCoinCommodityState
                .PendingProcess;
        } else if (
            approvedWarehouse[_tokenId] == _receiver &&
            transportDestination[_tokenId] == _receiver
        ) {
            tradeCoinCommodity[_tokenId]
                .tradeCoinCommodity_state = TradeCoinCommodityState
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
        require(
            tradeCoinCommodity[_tokenId].tradeCoinCommodity_state ==
                TradeCoinCommodityState.Processing
        );
        transportPickUp[_tokenId] = msg.sender;
        transportDestination[_tokenId] = _receiver;

        approvedTransporter[_tokenId] = _transporter;
        tradeCoinCommodity[_tokenId]
            .tradeCoinCommodity_state = TradeCoinCommodityState
            .PendingTransport;
    }

    function transportForWarehouse(
        uint256 _tokenId,
        address _transporter,
        address _receiver
    ) external onlyApprovedWarehouse(_tokenId, msg.sender) {
        require(
            tradeCoinCommodity[_tokenId].tradeCoinCommodity_state ==
                TradeCoinCommodityState.Stored
        );
        transportPickUp[_tokenId] = msg.sender;
        transportDestination[_tokenId] = _receiver;

        approvedTransporter[_tokenId] = _transporter;
        tradeCoinCommodity[_tokenId]
            .tradeCoinCommodity_state = TradeCoinCommodityState
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
        tradeCoinCommodity[_tokenId]
            .tradeCoinCommodity_state = TradeCoinCommodityState
            .PendingTransport;
    }

    function processingtradeCoinCommodity(uint256 _tokenId)
        external
        onlyApprovedProcessor(_tokenId, msg.sender)
    {
        require(
            tradeCoinCommodity[_tokenId].tradeCoinCommodity_state ==
                TradeCoinCommodityState.PendingProcess,
            "The tradeCoinCommodity has to be pending for process"
        );
        tradeCoinCommodity[_tokenId]
            .tradeCoinCommodity_state = TradeCoinCommodityState.Processing;

        emit TradeCoinCommodityDelivered(
            approvedTransporter[_tokenId],
            msg.sender,
            _tokenId
        );
        // approvedTransporter[_tokenId] = address(0);
    }

    function storringtradeCoinCommodity(uint256 _tokenId)
        external
        onlyApprovedWarehouse(_tokenId, msg.sender)
    {
        require(
            tradeCoinCommodity[_tokenId].tradeCoinCommodity_state ==
                TradeCoinCommodityState.PendingStorage,
            "The tradeCoinCommodity has to be pending for storage"
        );
        tradeCoinCommodity[_tokenId]
            .tradeCoinCommodity_state = TradeCoinCommodityState.Stored;

        emit TradeCoinCommodityDelivered(
            approvedTransporter[_tokenId],
            msg.sender,
            _tokenId
        );
        // approvedTransporter[_tokenId] = address(0);
    }

    function burningtradeCoinCommodity(uint256 _tokenId)
        external
        onlyApprovedWarehouse(_tokenId, msg.sender)
    {
        require(
            tradeCoinCommodity[_tokenId].tradeCoinCommodity_state ==
                TradeCoinCommodityState.Stored,
            "The tradeCoinCommodity has to be in stored"
        );
        tradeCoinCommodity[_tokenId].tradeCoinCommodity_state ==
            TradeCoinCommodityState.Burned;

        _burn(_tokenId);

        emit TradeCoinCommodityBurned(msg.sender, _tokenId);
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

    function decreaseWeight(uint256 _weight_gram, uint256 _tokenId)
        public
        onlyApprovedProcessor(_tokenId, msg.sender)
        returns (uint256)
    {
        require(
            tradeCoinCommodity[_tokenId].tradeCoinCommodity_state ==
                TradeCoinCommodityState.Processing
        );
        uint256 weight = tradeCoinCommodity[_tokenId].weight_gram;
        require(weight >= _weight_gram, "Weight can't be negative");

        console.log(
            "Decreasing weight of %s with amount of %s",
            weight.toString(),
            _weight_gram.toString()
        );

        tradeCoinCommodity[_tokenId].weight_gram = weight - _weight_gram;

        return tradeCoinCommodity[_tokenId].weight_gram;
    }

    function addISO(string memory _ISO, uint256 _tokenId)
        public
        onlyApprovedProcessor(_tokenId, msg.sender)
    {
        require(
            tradeCoinCommodity[_tokenId].tradeCoinCommodity_state ==
                TradeCoinCommodityState.Processing
        );
        tradeCoinCommodity[_tokenId].ISO_list.push(_ISO);
    }

    function getISObyIndex(uint256 _tokenId, uint256 _ISOIndex)
        public
        view
        returns (string memory)
    {
        return tradeCoinCommodity[_tokenId].ISO_list[_ISOIndex];
    }

    function getISOLength(uint256 _tokenId) public view returns (uint256) {
        return tradeCoinCommodity[_tokenId].ISO_list.length;
    }

    function getTradeCoinCommodityState(uint256 _tokenId)
        public
        view
        returns (TradeCoinCommodityState)
    {
        return tradeCoinCommodity[_tokenId].tradeCoinCommodity_state;
    }

    function gettradeCoinCommodityType(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        return tradeCoinCommodity[_tokenId].tradeCoinCommodity_type;
    }

    function gettradeCoinCommodityWeight(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return tradeCoinCommodity[_tokenId].weight_gram;
    }
}
