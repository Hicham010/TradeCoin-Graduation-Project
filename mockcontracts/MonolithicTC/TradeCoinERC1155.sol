// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "hardhat/console.sol";

contract TradeCoinCommodity is ERC1155, AccessControl, Pausable {
    struct Commodity {
        CommodityState state;
        string commodityType;
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

    uint256 tokenId = 0;

    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant FARMER_ROLE = keccak256("FARMER_ROLE");
    bytes32 public constant TRANSPORTER_ROLE = keccak256("TRANSPORTER_ROLE");
    bytes32 public constant PROCCESOR_ROLE = keccak256("PROCCESOR_ROLE");
    bytes32 public constant WAREHOUSE_ROLE = keccak256("WAREHOUSE_ROLE");
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");

    event Raw(address indexed creator, uint256 indexed tokenId);
    event Created(
        address indexed seller,
        address indexed receiver,
        uint256 indexed tokenId
    );
    event Pickedup(
        address indexed transporter,
        address indexed location,
        uint256 indexed tokenId
    );
    event Delivered(address indexed receiver, uint256 indexed tokenId);
    event Processed(
        address indexed processor,
        address indexed receiver,
        uint256 indexed tokenId
    );
    event Stored(
        address indexed warehouse,
        address indexed receiver,
        uint256 indexed tokenId
    );
    event Burned(address indexed nutConsumer, uint256 indexed tokenId);
    event HashedDocument(
        address indexed documentHasher,
        bytes signer,
        uint256 indexed tokenId
    );
    event TransferOwnership(
        address indexed oldOwner,
        address indexed newOwner,
        uint256 indexed tokenId
    );

    mapping(uint256 => bytes) private commodityData;

    mapping(uint256 => address) private owners;
    mapping(address => uint256) private ownersBalance;

    mapping(uint256 => address) public addressOfNewOwner;
    mapping(uint256 => uint256) public priceForOwnership;
    mapping(uint256 => bool) public payInFiat;

    constructor() ERC1155("https://tradecoin.io/") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(OWNER_ROLE, msg.sender);
        _grantRole(FARMER_ROLE, msg.sender);
        _grantRole(TRANSPORTER_ROLE, msg.sender);
        _grantRole(PROCCESOR_ROLE, msg.sender);
        _grantRole(WAREHOUSE_ROLE, msg.sender);
        _grantRole(VERIFIER_ROLE, msg.sender);
    }

    function mintCommodity(
        uint256 weightInGram,
        string memory commodityType,
        address warehouse
    ) public onlyRole(FARMER_ROLE) whenNotPaused {
        require(
            hasRole(WAREHOUSE_ROLE, warehouse),
            "Address is not an approved warehouse"
        );
        string[] memory emptyList;
        uint256 id = tokenId;

        Commodity memory _commodity = Commodity(
            CommodityState.PendingConfirmation,
            commodityType,
            emptyList,
            address(0),
            address(0)
        );
        owners[id] = msg.sender;
        setApprovalForAll(warehouse, true);

        ownersBalance[msg.sender] += 1;

        commodityData[id] = abi.encode(_commodity);
        _mint(msg.sender, id, weightInGram, "");
        tokenId++;
    }

    function confirmCommodity(uint256 id, address owner)
        external
        onlyRole(WAREHOUSE_ROLE)
    {
        require(hasRole(OWNER_ROLE, owner), "Address is not an approved owner");
        require(
            dataOf(id).state == CommodityState.PendingConfirmation,
            "The token is not pending for confirmation"
        );
        Commodity memory _commodity = dataOf(id);

        address farmerOfToken = owners[id];

        _commodity.state = CommodityState.Confirmed;
        _commodity.pickupAddress = farmerOfToken;
        _commodity.destinationAddress = msg.sender;

        safeTransferFrom(
            farmerOfToken,
            msg.sender,
            id,
            balanceOf(farmerOfToken, id),
            ""
        );

        commodityData[id] = abi.encode(_commodity);

        ownersBalance[ownerOf(id)] -= 1;
        ownersBalance[owner] += 1;
        owners[id] = owner;

        //emit event stored and created
    }

    // function mintBatch(
    //     address to,
    //     uint256[] memory ids,
    //     uint256[] memory amounts,
    //     bytes memory data
    // ) public onlyRole(MINTER_ROLE) whenNotPaused {
    //     _mintBatch(to, ids, amounts, data);
    // }

    // Create delivery

    function createDelivery(
        uint256 id,
        address receiver,
        address transporter
    ) public {
        Commodity memory _commodity = dataOf(id);
        require(
            _commodity.destinationAddress == msg.sender,
            "Error: this commodity is not near you"
        );

        _commodity.state = CommodityState.PendingTransport;
        _commodity.pickupAddress = msg.sender;
        _commodity.destinationAddress = receiver;

        commodityData[id] = abi.encode(_commodity);
        setApprovalForAll(transporter, true);
    }

    // Ownership
    function setPriceForOwnership(
        uint256 id,
        uint256 priceInWei,
        address newOwner,
        bool isFiat
    ) external onlyRole(OWNER_ROLE) {
        Commodity memory _commodity = dataOf(id);
        address ownerOfId = owners[id];

        require(msg.sender == ownerOfId, "You are not the owner");
        require(
            _commodity.state != CommodityState.PendingConfirmation,
            "The commodity is still pending for confirmation"
        );
        priceForOwnership[id] = priceInWei;
        addressOfNewOwner[id] = newOwner;
        payInFiat[id] = isFiat;
    }

    function payForOwnership(uint256 id) external payable onlyRole(OWNER_ROLE) {
        bool _payFiat = payInFiat[id];
        address prevOwnerId = owners[id];

        require(
            addressOfNewOwner[id] == msg.sender,
            "You don't have the right to pay"
        );
        require(
            priceForOwnership[id] != 0 || _payFiat,
            "The NFT has no set price"
        );
        require(priceForOwnership[id] <= msg.value, "You did not pay enough");

        address addrOwner = ownerOf(id);

        if (!_payFiat) {
            payable(addrOwner).transfer(msg.value);
        }

        owners[id] = msg.sender;
        ownersBalance[msg.sender] += 1;
        ownersBalance[prevOwnerId] -= 1;
        priceForOwnership[id] = 0;

        // emit sale
    }

    // Transporter

    function pickupCommodity(uint256 id) public onlyRole(TRANSPORTER_ROLE) {
        Commodity memory _commodity = dataOf(id);
        require(
            _commodity.state == CommodityState.PendingTransport,
            "TradeCoinERC1155: this commodity is not set to pending for transport"
        );

        _commodity.state = CommodityState.Transporting;
        commodityData[id] = abi.encode(_commodity);

        safeTransferFrom(
            _commodity.pickupAddress,
            msg.sender,
            id,
            balanceOf(_commodity.pickupAddress, id),
            ""
        );

        emit Pickedup(msg.sender, _commodity.pickupAddress, id);
    }

    function deliveredCommodity(uint256 id) public onlyRole(TRANSPORTER_ROLE) {
        Commodity memory _commodity = dataOf(id);
        // require(
        //     _commodity.destinationAddress == msg.sender,
        //     "You are not the destination address"
        // );
        bool hasRoleProcessor = hasRole(
            PROCCESOR_ROLE,
            _commodity.destinationAddress
        );
        // console.log("bool of hasRoleProcessor:", hasRoleProcessor);
        bool hasRoleWarehouse = hasRole(
            WAREHOUSE_ROLE,
            _commodity.destinationAddress
        );
        // console.log("bool of hasRoleWarehouse:", hasRoleWarehouse);

        require(
            _commodity.state == CommodityState.Transporting,
            "TradeCoinERC1155: this commodity is not set to transport"
        );

        setApprovalForAll(_commodity.destinationAddress, true);

        if (hasRoleProcessor) {
            _commodity.state = CommodityState.PendingProcess;
        } else if (hasRoleWarehouse) {
            _commodity.state = CommodityState.PendingStorage;
        }
        // } else {
        //     //TODO: check if needed
        //     revert("Address not part of supply chain");
        // }

        commodityData[id] = abi.encode(_commodity);
    }

    function confirmDelivery(uint256 id, address transporter) public {
        Commodity memory _commodity = dataOf(id);
        require(
            _commodity.destinationAddress == msg.sender,
            "Error: this commodity is not at your address"
        );

        //TODO: maybe add extra check for safety?
        if (_commodity.state == CommodityState.PendingProcess) {
            _commodity.state = CommodityState.Processing;
        } else if (_commodity.state == CommodityState.PendingStorage) {
            _commodity.state = CommodityState.Stored;
        } else {
            revert("The commodity has not yet been delivered");
        }

        commodityData[id] = abi.encode(_commodity);
        safeTransferFrom(
            transporter,
            msg.sender,
            id,
            balanceOf(transporter, id),
            ""
        );
        emit Delivered(msg.sender, id);
    }

    function addProcesses(uint256 id, string[] memory _processes)
        public
        onlyRole(PROCCESOR_ROLE)
    {
        Commodity memory _commodity = dataOf(id);
        require(
            _commodity.destinationAddress == msg.sender,
            "TradeCoinERC1155: this commodity is not at your address"
        );
        require(
            _commodity.state == CommodityState.Processing,
            "TradeCoinERC1155: is not set to processing"
        );

        uint256 _lengthOriginal = _commodity.isoList.length;
        uint256 _lengthProcesses = _processes.length;
        uint256 _lengthPlus = _lengthOriginal + _lengthProcesses;
        string[] memory addedProcessesList = new string[](_lengthPlus);

        for (uint256 i = 0; i < _lengthPlus; i++) {
            if (i < _lengthOriginal) {
                addedProcessesList[i] = _commodity.isoList[i];
            } else {
                addedProcessesList[i] = _processes[i - _lengthOriginal];
            }
            // i < _lengthOriginal
            //     ? addedProcessesList[i] = _commodity.isoList[i]
            //     : addedProcessesList[i] = _processes[i - _lengthOriginal];
        }

        _commodity.isoList = addedProcessesList;

        commodityData[id] = abi.encode(_commodity);
        // emit event stored
    }

    function changeFullProcessesList(uint256 id, string[] memory _processes)
        public
        onlyRole(PROCCESOR_ROLE)
    {
        Commodity memory _commodity = dataOf(id);
        require(
            _commodity.destinationAddress == msg.sender,
            "TradeCoinERC1155: this commodity is not at your address"
        );
        require(
            _commodity.state == CommodityState.Processing,
            "TradeCoinERC1155: is not set to processing"
        );

        _commodity.isoList = _processes;

        commodityData[id] = abi.encode(_commodity);
        // emit event stored
    }

    function decreaseWeight(uint256 id, uint256 amountInGram)
        public
        onlyRole(PROCCESOR_ROLE)
    {
        _burn(msg.sender, id, amountInGram);
    }

    function batchTokens(uint256[] memory _Ids)
        public
        onlyRole(WAREHOUSE_ROLE)
    {
        require(_Ids.length > 1, "Can't batch 1 token");
        Commodity memory _commodityAll = dataOf(_Ids[0]);
        Commodity memory _commodity0 = Commodity(
            _commodityAll.state,
            _commodityAll.commodityType,
            _commodityAll.isoList,
            address(0),
            _commodityAll.destinationAddress
        );
        require(
            _commodity0.state == CommodityState.Stored ||
                _commodity0.state == CommodityState.Processing ||
                _commodity0.state == CommodityState.Confirmed,
            "This token is not stored or processing"
        );
        require(
            _commodity0.destinationAddress == msg.sender,
            "This token is not in your possession"
        );
        bytes memory commodity0Encode = abi.encode(_commodity0);

        uint256 totalWeight = 0;
        address ownerOfIds = ownerOf(_Ids[0]);

        totalWeight += balanceOf(msg.sender, _Ids[0]);
        _burn(msg.sender, _Ids[0], totalWeight);
        ownersBalance[ownerOfIds] -= 1;

        for (uint256 i = 1; i < _Ids.length; i++) {
            Commodity memory _commodityIAll = dataOf(_Ids[i]);
            Commodity memory _commodityI = Commodity(
                _commodityIAll.state,
                _commodityIAll.commodityType,
                _commodityIAll.isoList,
                address(0),
                _commodityIAll.destinationAddress
            );
            bytes memory _commodityIEncode = abi.encode(_commodityI);
            require(
                keccak256(commodity0Encode) == keccak256(_commodityIEncode)
            );
            require(
                ownerOfIds == ownerOf(_Ids[i]),
                "Not allowed to batch tokens of different owners"
            );
            uint256 balanceOfI = balanceOf(msg.sender, _Ids[i]);
            totalWeight += balanceOfI;
            _burn(msg.sender, _Ids[i], balanceOfI);
            ownersBalance[ownerOfIds] -= 1;
            delete commodityData[i];
            delete owners[_Ids[i]];
        }

        Commodity memory _commodityBatch = Commodity(
            _commodity0.state,
            _commodity0.commodityType,
            _commodity0.isoList,
            address(0),
            msg.sender
        );

        uint256 tokenIdPlus = tokenId + 1;
        commodityData[tokenIdPlus] = abi.encode(_commodityBatch);
        owners[tokenIdPlus] = ownerOf(_Ids[0]);

        _mint(msg.sender, tokenIdPlus, totalWeight, "");
        tokenId++;
        ownersBalance[ownerOfIds] += 1;

        delete commodityData[_Ids[0]];
        delete owners[_Ids[0]];

        //emit Batched;
    }

    function splitCommodity(uint256 id, uint256 amountOfSplits)
        public
        onlyRole(WAREHOUSE_ROLE)
    {
        Commodity memory _commodity = dataOf(id);
        uint256 _tokenId = tokenId;
        require(
            _commodity.state == CommodityState.Stored ||
                _commodity.state == CommodityState.Confirmed,
            "TradeCoinERC1155: Commodity is not in the right state for splitting"
        );
        require(
            _commodity.destinationAddress == msg.sender,
            "TradeCoinERC1155: Commodity is not near you for"
        );

        uint256 _balance = balanceOf(msg.sender, id);
        require(
            _balance % amountOfSplits == 0,
            "TradeCoinERC1155: Can not split evenly"
        );
        address ownerOfId = owners[id];

        for (uint256 i = 0; i < amountOfSplits + 1; i++) {
            Commodity memory _commodityI = Commodity(
                _commodity.state,
                _commodity.commodityType,
                _commodity.isoList,
                _commodity.pickupAddress,
                msg.sender
            );

            owners[_tokenId + i] = ownerOfId;
            ownersBalance[ownerOfId] += 1;

            commodityData[_tokenId + i] = abi.encode(_commodityI);
            _mint(msg.sender, (_tokenId + i), (_balance / amountOfSplits), "");
            // console.log(
            //     "data of: ",
            //     msg.sender,
            //     _tokenId + i,
            //     _balance / amountOfSplits
            // );
        }

        tokenId = _tokenId + amountOfSplits;
        _burn(msg.sender, id, _balance);
        ownersBalance[ownerOfId] -= 1;
        delete commodityData[id];
        delete owners[id];
    }

    function splitCommodityByList(uint256 id, uint256[] memory splitIntoAmounts)
        public
        onlyRole(WAREHOUSE_ROLE)
    {
        Commodity memory _commodity = dataOf(id);
        uint256 _tokenId = tokenId;
        require(
            _commodity.state == CommodityState.Stored ||
                _commodity.state == CommodityState.Confirmed,
            "TradeCoinERC1155: Commodity is not in the right state for splitting"
        );
        require(
            _commodity.destinationAddress == msg.sender,
            "TradeCoinERC1155: Commodity is not near you"
        );

        uint256 _balance = balanceOf(msg.sender, id);

        uint256 totalWeight;
        for (uint256 i; i < splitIntoAmounts.length; i++) {
            totalWeight += splitIntoAmounts[i];
        }

        require(
            _balance == totalWeight,
            "TradeCoinERC1155: total weight does not equal total weight of list"
        );
        address ownerOfId = owners[id];

        for (uint256 i = 0; i < splitIntoAmounts.length; i++) {
            Commodity memory _commodityI = Commodity(
                _commodity.state,
                _commodity.commodityType,
                _commodity.isoList,
                _commodity.pickupAddress,
                msg.sender
            );

            owners[_tokenId + i] = ownerOfId;
            ownersBalance[ownerOfId] += 1;

            commodityData[_tokenId + i] = abi.encode(_commodityI);
            _mint(msg.sender, (_tokenId + i), splitIntoAmounts[i], "");
        }

        tokenId = _tokenId + splitIntoAmounts.length;
        _burn(msg.sender, id, _balance);

        ownersBalance[ownerOfId] -= 1;
        delete commodityData[id];
        delete owners[id];
    }

    // Commodity Data

    function dataOf(uint256 id) public view returns (Commodity memory) {
        require(
            owners[id] != address(0),
            "TradeCoinERC1155: data query for zero address"
        );

        return abi.decode(commodityData[id], (Commodity));
    }

    function typeCommodityOf(uint256 id) public view returns (string memory) {
        return dataOf(id).commodityType;
    }

    function stateCommodityOf(uint256 id) public view returns (CommodityState) {
        return dataOf(id).state;
    }

    function pickupCommodityOf(uint256 id) public view returns (address) {
        return dataOf(id).pickupAddress;
    }

    function destinationCommodityOf(uint256 id) public view returns (address) {
        return dataOf(id).destinationAddress;
    }

    function isoListLengthOf(uint256 id) public view returns (uint256) {
        return dataOf(id).isoList.length;
    }

    function isobyIndexOf(uint256 id, uint256 index)
        public
        view
        returns (string memory)
    {
        return dataOf(id).isoList[index];
    }

    function ownerOf(uint256 id) public view returns (address) {
        return owners[id];
    }

    function balanceOfOwners(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC1155: balance query for zero address");
        return ownersBalance[owner];
    }

    // function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
    //     _setURI(newuri);
    // }

    // Grant roles

    function grantFarmerRole(address farmer) external onlyRole(OWNER_ROLE) {
        _grantRole(FARMER_ROLE, farmer);
    }

    function grantTransporterRole(address transporter)
        external
        onlyRole(OWNER_ROLE)
    {
        _grantRole(TRANSPORTER_ROLE, transporter);
    }

    function grantProcessorRole(address processor)
        external
        onlyRole(OWNER_ROLE)
    {
        _grantRole(PROCCESOR_ROLE, processor);
    }

    function grantWarehouseRole(address warehouse)
        external
        onlyRole(OWNER_ROLE)
    {
        _grantRole(WAREHOUSE_ROLE, warehouse);
    }

    function grantVerifierRole(address verifier) external onlyRole(OWNER_ROLE) {
        _grantRole(VERIFIER_ROLE, verifier);
    }

    function grantAllRolesForOwner(address owner)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _grantRole(OWNER_ROLE, owner);
        _grantRole(FARMER_ROLE, owner);
        _grantRole(TRANSPORTER_ROLE, owner);
        _grantRole(PROCCESOR_ROLE, owner);
        _grantRole(WAREHOUSE_ROLE, owner);
        _grantRole(VERIFIER_ROLE, owner);
    }

    // Pause

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155) whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    function batchTokens(uint256[] memory _Ids)
        public
        onlyRole(WAREHOUSE_ROLE)
    {
        require(_Ids.length > 1, "Can't batch 1 token");
        Commodity memory _commodity0 = dataOf(_Ids[0]);
        require(
            _commodity0.state == CommodityState.Stored ||
                _commodity0.state == CommodityState.Processing ||
                _commodity0.state == CommodityState.Confirmed,
            "This token is not stored or processing"
        );
        require(
            _commodity0.destinationAddress == msg.sender,
            "This token is not in your possession"
        );

        uint256 totalWeight = 0;
        address ownerOfIds = ownerOf(_Ids[0]);

        totalWeight += balanceOf(msg.sender, _Ids[0]);
        _burn(msg.sender, _Ids[0], totalWeight);

        for (uint256 i = 1; i < _Ids.length; i++) {
            // console.log("Inside of for loop", i);
            // console.log("Length of array", _Ids.length);
            Commodity memory _commodityI = dataOf(_Ids[i]);
            require(
                _commodityI.destinationAddress == msg.sender,
                "This token is not in your possession"
            );
            require(
                ownerOfIds == ownerOf(_Ids[i]),
                "Not allowed to batch tokens of different owners"
            );
            require(
                _commodity0.state == _commodityI.state,
                "Commodity states don't match"
            );
            require(
                keccak256(abi.encode(_commodity0.isoList)) ==
                    keccak256(abi.encode(_commodityI.isoList)),
                "Commodities don't the same processes"
            );
            require(
                keccak256(abi.encode(_commodity0.commodityType)) ==
                    keccak256(abi.encode(_commodityI.commodityType)),
                "Commodities aren't of the same type"
            );
            // console.log("After all require");
            uint256 balanceOfI = balanceOf(msg.sender, _Ids[i]);
            totalWeight += balanceOfI;
            _burn(msg.sender, _Ids[i], balanceOfI);
            delete commodityData[i];
        }

        Commodity memory _commodityBatch = Commodity(
            _commodity0.state,
            _commodity0.commodityType,
            _commodity0.isoList,
            address(0),
            msg.sender
        );

        uint256 tokenIdPlus = tokenId + 1;
        commodityData[tokenIdPlus] = abi.encode(_commodityBatch);

        _mint(msg.sender, tokenIdPlus, totalWeight, "");
        tokenId++;
        delete commodityData[_Ids[0]];

        //emit Batched;
}
