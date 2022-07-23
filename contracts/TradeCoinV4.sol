// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./TradeCoinTokenizerV2.sol";
import "./RoleControl.sol";
import "./interfaces/ITradeCoin.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TradeCoinV4 is ERC721, RoleControl, ITradeCoin, ReentrancyGuard {
    struct TradeCoinCommodity {
        uint256 amount;
        State state;
        bytes4 hashOfProperties;
        address currentHandler;
    }

    struct CommoditySale {
        address seller;
        address owner;
        address handler;
        bool isPaid;
        uint256 priceInWei;
    }

    uint256 public tokenCounter;
    TradeCoinTokenizerV2 public tradeCoinTokenizer;

    mapping(uint256 => TradeCoinCommodity) public tradeCoinCommodity;
    mapping(uint256 => CommoditySale) public commoditySaleQueue;
    mapping(uint256 => bool) public pendingWithdrawal;

    modifier isCurrentHandler(uint256 tokenId) {
        require(
            tradeCoinCommodity[tokenId].currentHandler == msg.sender,
            "Caller is not the current handler"
        );
        _;
    }

    constructor(address _tradeCoinTokenizer)
        ERC721("TradeCoinV4", "TC")
        RoleControl(msg.sender)
    {
        tradeCoinTokenizer = TradeCoinTokenizerV2(_tradeCoinTokenizer);
    }

    function initializeSale(
        address owner,
        address handler,
        uint256 tokenIdOfTokenizer,
        uint256 priceInWei
    ) external override onlyTokenizer {
        require(
            tradeCoinTokenizer.ownerOf(tokenIdOfTokenizer) == msg.sender,
            "Not the owner"
        );

        commoditySaleQueue[tokenIdOfTokenizer] = CommoditySale(
            msg.sender,
            owner,
            handler,
            priceInWei == 0,
            priceInWei
        );

        emit InitializeSale(
            tokenIdOfTokenizer,
            msg.sender,
            owner,
            priceInWei,
            priceInWei == 0
        );

        tradeCoinTokenizer.transferFrom(
            msg.sender,
            address(this),
            tokenIdOfTokenizer
        );
    }

    function paymentOfToken(uint256 tokenIdOfTokenizer)
        external
        payable
        override
    {
        require(
            commoditySaleQueue[tokenIdOfTokenizer].priceInWei == msg.value,
            "Not enough Ether"
        );
        require(
            !commoditySaleQueue[tokenIdOfTokenizer].isPaid,
            "Token is already paid for"
        );
        commoditySaleQueue[tokenIdOfTokenizer].isPaid = true;

        emit PaymentOfToken(tokenIdOfTokenizer, msg.sender, msg.value);
    }

    function mintCommodity(uint256 tokenIdOfTokenizer)
        external
        override
        onlyTransformationHandler
    {
        CommoditySale memory sale = commoditySaleQueue[tokenIdOfTokenizer];
        require(sale.isPaid, "Not payed for yet");
        require(sale.handler == msg.sender, "Not a handler");

        _mint(sale.owner, tokenCounter);

        (bytes4 hashOfProperties, uint256 amount) = emitTokenData(
            tokenIdOfTokenizer
        );

        tradeCoinCommodity[tokenCounter] = TradeCoinCommodity(
            amount,
            State.Created,
            hashOfProperties,
            msg.sender
        );

        pendingWithdrawal[tokenIdOfTokenizer] = true;

        emit CompleteSale(tokenCounter, sale.seller, msg.sender);

        unchecked {
            tokenCounter += 1;
        }

        tradeCoinTokenizer.burnToken(tokenIdOfTokenizer);
    }

    function withdrawPayment(uint256 tokenIdOfTokenizer)
        external
        override
        nonReentrant
    {
        uint256 salePrice = commoditySaleQueue[tokenIdOfTokenizer].priceInWei;
        require(pendingWithdrawal[tokenIdOfTokenizer], "Token not minted yet");
        require(
            commoditySaleQueue[tokenIdOfTokenizer].seller == msg.sender,
            "Caller is not seller"
        );

        commoditySaleQueue[tokenIdOfTokenizer].priceInWei = 0;

        emit WithdrawPayment(tokenIdOfTokenizer, msg.sender, salePrice);

        payable(msg.sender).transfer(salePrice);
    }

    function emitTokenData(uint256 tokenIdOfTokenizer)
        internal
        returns (bytes4, uint256)
    {
        (
            string memory commodity,
            uint256 amount,
            string memory unit
        ) = tradeCoinTokenizer.tradeCoinToken(tokenIdOfTokenizer);

        emit MintCommodity(
            tokenCounter,
            msg.sender,
            tokenIdOfTokenizer,
            commodity,
            amount,
            unit
        );

        emit CommodityTransformation(tokenCounter, msg.sender, "raw");

        return (
            bytes4(keccak256(abi.encodePacked(commodity, unit, "raw"))),
            amount
        );
    }

    function addTransformation(uint256 tokenId, string calldata transformation)
        external
        override
        onlyTransformationHandler
        isCurrentHandler(tokenId)
    {
        tradeCoinCommodity[tokenId].hashOfProperties =
            tradeCoinCommodity[tokenId].hashOfProperties ^
            bytes4(keccak256(abi.encodePacked(transformation)));

        emit CommodityTransformation(tokenId, msg.sender, transformation);
    }

    function addTransformationDecrease(
        uint256 tokenId,
        string calldata transformation,
        uint256 amountDecrease
    ) external override onlyTransformationHandler isCurrentHandler(tokenId) {
        tradeCoinCommodity[tokenId].amount -= amountDecrease;

        tradeCoinCommodity[tokenId].hashOfProperties =
            tradeCoinCommodity[tokenId].hashOfProperties ^
            bytes4(keccak256(abi.encodePacked(transformation)));

        emit CommodityTransformationDecrease(
            tokenId,
            msg.sender,
            transformation,
            amountDecrease
        );
    }

    function changeCurrentHandlerAndState(
        uint256 tokenId,
        address newHandler,
        State newCommodityState
    ) external override {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        tradeCoinCommodity[tokenId].currentHandler = newHandler;
        tradeCoinCommodity[tokenId].state = newCommodityState;

        emit ChangeStateAndHandler(
            tokenId,
            msg.sender,
            newHandler,
            newCommodityState
        );
    }

    function addInformationToCommodity(uint256 tokenId, string calldata data)
        external
        override
        onlyInformationHandler
        isCurrentHandler(tokenId)
    {
        emit AddInformation(tokenId, msg.sender, data);
    }

    function checkQualityOfCommodity(uint256 tokenId, string calldata data)
        external
        override
        onlyInformationHandler
        isCurrentHandler(tokenId)
    {
        emit QualityCheckCommodity(tokenId, msg.sender, data);
    }

    function confirmCommodityLocation(
        uint256 tokenId,
        uint256 latitude,
        uint256 longitude,
        uint256 radius
    ) external override onlyInformationHandler isCurrentHandler(tokenId) {
        emit LocationOfCommodity(
            tokenId,
            msg.sender,
            latitude,
            longitude,
            radius
        );
    }

    function batchCommodities(uint256[] calldata tokenIds) external override {
        require(ownerOf(tokenIds[0]) == msg.sender, "Not the owner");
        require(tokenIds.length > 1, "Length of array must be greater than 1");
        bytes32 hashOfCommodity = keccak256(
            abi.encodePacked(
                tradeCoinCommodity[tokenIds[0]].state,
                tradeCoinCommodity[tokenIds[0]].hashOfProperties
            )
        );

        uint256 cumulativeAmount = tradeCoinCommodity[tokenIds[0]].amount;

        for (uint256 i = 1; i < tokenIds.length; ) {
            require(ownerOf(tokenIds[i]) == msg.sender, "Not the owner");
            bytes32 hashOfiProduct = keccak256(
                abi.encodePacked(
                    tradeCoinCommodity[tokenIds[i]].state,
                    tradeCoinCommodity[tokenIds[i]].hashOfProperties
                )
            );
            require(
                hashOfiProduct == hashOfCommodity,
                "Properties don't match"
            );
            _burn(tokenIds[i]);
            // delete tradeCoinCommodity[tokenIds[i]];
            unchecked {
                cumulativeAmount += tradeCoinCommodity[tokenIds[i]].amount;
                ++i;
            }
        }

        _mint(msg.sender, tokenCounter);
        tradeCoinCommodity[tokenCounter] = TradeCoinCommodity(
            cumulativeAmount,
            State.Created,
            tradeCoinCommodity[tokenIds[0]].hashOfProperties,
            tradeCoinCommodity[tokenIds[0]].currentHandler
        );

        _burn(tokenIds[0]);
        // delete tradeCoinCommodity[tokenIds[0]];

        emit BatchCommodities(tokenCounter, msg.sender, tokenIds);

        tokenCounter += 1;
    }

    function splitCommodity(uint256 tokenId, uint256[] calldata partitions)
        external
        override
    {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        require(partitions.length > 1, "Length of array must be bigger than 1");
        uint256 cumulativeAmountPartitions;
        for (uint256 i = 0; i < partitions.length; ) {
            require(partitions[i] != 0, "Partition can't be 0");
            cumulativeAmountPartitions += partitions[i];
            unchecked {
                ++i;
            }
        }
        require(
            tradeCoinCommodity[tokenId].amount == cumulativeAmountPartitions,
            "The amounts don't add up"
        );

        _burn(tokenId);

        uint256[] memory newTokens = new uint256[](partitions.length);
        bytes4 _hashOfProperties = tradeCoinCommodity[tokenId].hashOfProperties;
        address _currentHandler = tradeCoinCommodity[tokenId].currentHandler;
        uint256 _tokenCounter = tokenCounter;

        for (uint256 i = 0; i < partitions.length; ) {
            _mint(msg.sender, _tokenCounter);
            tradeCoinCommodity[_tokenCounter] = TradeCoinCommodity(
                partitions[i],
                State.Created,
                _hashOfProperties,
                _currentHandler
            );
            newTokens[i] = _tokenCounter;
            unchecked {
                ++i;
                _tokenCounter += 1;
            }
        }
        tokenCounter = _tokenCounter;
        // delete tradeCoinCommodity[tokenId];

        emit SplitCommodity(tokenId, msg.sender, newTokens);
    }

    function burnCommodity(uint256 tokenId) external override {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");

        _burn(tokenId);

        emit CommodityOutOfChain(tokenId, msg.sender);
    }

    // Function must be overridden as ERC721 and AccesControl are conflicting
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return
            type(ITradeCoin).interfaceId == interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
