// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./TradeCoinTokenizerV2.sol";
import "./RoleControl.sol";
import "./ITradeCoin.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TradeCoinV4 is ERC721, RoleControl, ReentrancyGuard, ITradeCoin {
    uint256 public tokenCounter;
    uint256 public contractWeiBalance;
    TradeCoinTokenizerV2 public tradeCoinTokenizerV2;

    struct TradeCoinCommodity {
        uint256 amount;
        State state;
        bytes32 hashOfProperties;
        address currentHandler;
    }

    struct CommoditySale {
        address seller;
        address owner;
        address handler;
        uint256 priceInWei;
        bool isPaid;
    }

    mapping(uint256 => TradeCoinCommodity) public tradeCoinCommodity;
    mapping(uint256 => CommoditySale) public commoditySaleQueue;

    modifier isCurrentHandler(uint256 tokenId) {
        require(
            tradeCoinCommodity[tokenId].currentHandler == msg.sender,
            "Caller is not the current handler"
        );
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _tradeCoinTokenizerV2
    ) ERC721(_name, _symbol) RoleControl(msg.sender) {
        tradeCoinTokenizerV2 = TradeCoinTokenizerV2(_tradeCoinTokenizerV2);
    }

    function initializeSale(
        address owner,
        address handler,
        uint256 tokenIdOfTokenizer,
        uint256 priceInWei
    ) external override onlyTokenizer {
        require(
            tradeCoinTokenizerV2.ownerOf(tokenIdOfTokenizer) == msg.sender,
            "Not the owner"
        );
        tradeCoinTokenizerV2.transferFrom(
            msg.sender,
            address(this),
            tokenIdOfTokenizer
        );

        commoditySaleQueue[tokenIdOfTokenizer] = CommoditySale(
            msg.sender,
            owner,
            handler,
            priceInWei,
            priceInWei == 0
        );

        emit InitializeSale(
            tokenIdOfTokenizer,
            msg.sender,
            owner,
            priceInWei,
            priceInWei == 0
        );
    }

    function paymentOfToken(uint256 tokenIdOfTokenizer)
        external
        payable
        override
    {
        require(
            commoditySaleQueue[tokenIdOfTokenizer].isPaid &&
                commoditySaleQueue[tokenIdOfTokenizer].priceInWei == msg.value,
            "Not enough Ether"
        );
        assert(address(this).balance == contractWeiBalance);

        commoditySaleQueue[tokenIdOfTokenizer].isPaid = true;
        contractWeiBalance += msg.value;

        emit PaymentOfToken(
            tokenIdOfTokenizer,
            msg.sender,
            commoditySaleQueue[tokenIdOfTokenizer].priceInWei
        );
    }

    function mintCommodity(uint256 tokenIdOfTokenizer)
        external
        override
        onlyTransformationHandler
    {
        require(
            commoditySaleQueue[tokenIdOfTokenizer].isPaid,
            "Not payed for yet"
        );
        require(
            commoditySaleQueue[tokenIdOfTokenizer].handler == msg.sender,
            "Not a handler"
        );

        if (!(commoditySaleQueue[tokenIdOfTokenizer].priceInWei == 0)) {
            payable(commoditySaleQueue[tokenIdOfTokenizer].seller).transfer(
                commoditySaleQueue[tokenIdOfTokenizer].priceInWei
            );
        }
        _mint(commoditySaleQueue[tokenIdOfTokenizer].owner, tokenCounter);

        (bytes32 hashOfProperties, uint256 amount) = emitTokenData(
            tokenIdOfTokenizer
        );

        tradeCoinCommodity[tokenCounter] = TradeCoinCommodity(
            amount,
            State.Created,
            hashOfProperties,
            msg.sender
        );

        tradeCoinTokenizerV2.burnToken(tokenIdOfTokenizer);

        emit CompleteSale(
            tokenCounter,
            commoditySaleQueue[tokenIdOfTokenizer].seller,
            msg.sender
        );

        delete commoditySaleQueue[tokenIdOfTokenizer];
        tokenCounter += 1;
    }

    function emitTokenData(uint256 tokenIdOfTokenizer)
        internal
        returns (bytes32, uint256)
    {
        (
            string memory commodity,
            uint256 amount,
            string memory unit
        ) = tradeCoinTokenizerV2.tradeCoinToken(tokenIdOfTokenizer);

        emit MintCommodity(
            tokenCounter,
            msg.sender,
            tokenIdOfTokenizer,
            commodity,
            amount,
            unit
        );

        emit CommodityTransformation(tokenCounter, msg.sender, "raw");

        return (keccak256(abi.encodePacked(commodity, unit, "raw")), amount);
    }

    function addTransformation(uint256 _tokenId, string memory transformation)
        external
        override
        onlyInformationHandler
        isCurrentHandler(_tokenId)
    {
        tradeCoinCommodity[_tokenId].hashOfProperties = keccak256(
            abi.encodePacked(
                tradeCoinCommodity[_tokenId].hashOfProperties,
                transformation
            )
        );

        emit CommodityTransformation(_tokenId, msg.sender, transformation);
    }

    function addTransformation(
        uint256 _tokenId,
        string memory transformation,
        uint256 amountDecrease
    ) external override onlyTransformationHandler isCurrentHandler(_tokenId) {
        tradeCoinCommodity[_tokenId].amount -= amountDecrease;

        tradeCoinCommodity[_tokenId].hashOfProperties = keccak256(
            abi.encodePacked(
                tradeCoinCommodity[_tokenId].hashOfProperties,
                transformation
            )
        );

        emit CommodityTransformation(
            _tokenId,
            msg.sender,
            transformation,
            amountDecrease
        );
    }

    function changeCurrentHandlerAndState(
        uint256 _tokenId,
        address newHandler,
        State newCommodityState
    ) external override {
        require(ownerOf(_tokenId) == msg.sender, "Not the owner");
        tradeCoinCommodity[_tokenId].currentHandler = newHandler;
        tradeCoinCommodity[_tokenId].state = newCommodityState;

        emit ChangeStateAndHandler(
            _tokenId,
            msg.sender,
            newHandler,
            newCommodityState
        );
    }

    function addInformationToCommodity(uint256 _tokenId, string memory data)
        external
        override
        onlyInformationHandler
        isCurrentHandler(_tokenId)
    {
        emit AddInformation(_tokenId, msg.sender, data);
    }

    function checkQualityOfCommodity(uint256 _tokenId, string memory data)
        external
        override
        onlyInformationHandler
        isCurrentHandler(_tokenId)
    {
        emit QualityCheckCommodity(_tokenId, msg.sender, data);
    }

    function confirmCommodityLocation(
        uint256 _tokenId,
        uint256 latitude,
        uint256 longitude,
        uint256 radius
    ) external override onlyInformationHandler isCurrentHandler(_tokenId) {
        emit LocationOfCommodity(
            _tokenId,
            msg.sender,
            latitude,
            longitude,
            radius
        );
    }

    function batchCommodities(uint256[] memory _tokenIds) external override {
        require(ownerOf(_tokenIds[0]) == msg.sender, "Not the owner");
        bytes32 hashOfCommodity = keccak256(
            abi.encode(
                TradeCoinCommodity(
                    0,
                    tradeCoinCommodity[_tokenIds[0]].state,
                    tradeCoinCommodity[_tokenIds[0]].hashOfProperties,
                    address(0)
                )
            )
        );

        uint256 cumulativeAmount = tradeCoinCommodity[_tokenIds[0]].amount;

        for (uint256 i = 1; i < _tokenIds.length; i++) {
            require(ownerOf(_tokenIds[i]) == msg.sender, "Not the owner");
            bytes32 hashOfiProduct = keccak256(
                abi.encode(
                    TradeCoinCommodity(
                        0,
                        tradeCoinCommodity[_tokenIds[i]].state,
                        tradeCoinCommodity[_tokenIds[i]].hashOfProperties,
                        address(0)
                    )
                )
            );
            cumulativeAmount += tradeCoinCommodity[_tokenIds[i]].amount;
            require(
                hashOfiProduct == hashOfCommodity,
                "Properties don't match"
            );
            _burn(_tokenIds[i]);
            delete tradeCoinCommodity[_tokenIds[i]];
        }

        _mint(msg.sender, tokenCounter);
        tradeCoinCommodity[tokenCounter] = TradeCoinCommodity(
            cumulativeAmount,
            State.Created,
            tradeCoinCommodity[_tokenIds[0]].hashOfProperties,
            tradeCoinCommodity[_tokenIds[0]].currentHandler
        );

        _burn(_tokenIds[0]);
        delete tradeCoinCommodity[_tokenIds[0]];

        emit BatchCommodities(tokenCounter, msg.sender, _tokenIds);

        tokenCounter += 1;
    }

    function splitCommodity(uint256 _tokenId, uint256[] memory partitions)
        external
        override
    {
        require(ownerOf(_tokenId) == msg.sender, "Not the owner");
        require(partitions.length > 1, "Length of array must be bigger then 1");
        uint256 cumulativeAmountPartitions;
        for (uint256 i; i < partitions.length; i++) {
            require(partitions[i] != 0, "Partitiona amount can't be 0");
            cumulativeAmountPartitions += partitions[i];
        }
        require(
            tradeCoinCommodity[_tokenId].amount == cumulativeAmountPartitions,
            "The amounts to add up"
        );

        _burn(_tokenId);
        uint256[] memory newTokens = new uint256[](partitions.length);

        for (uint256 i; i < partitions.length; i++) {
            _mint(msg.sender, tokenCounter);
            tradeCoinCommodity[tokenCounter] = TradeCoinCommodity(
                partitions[i],
                State.Created,
                tradeCoinCommodity[_tokenId].hashOfProperties,
                msg.sender
            );
            newTokens[i] = tokenCounter;
            tokenCounter += 1;
        }
        delete tradeCoinCommodity[_tokenId];

        emit SplitCommodity(_tokenId, msg.sender, newTokens);
    }

    function burnCommodity(uint256 _tokenId) external override {
        require(ownerOf(_tokenId) == msg.sender, "Not the owner");

        _burn(_tokenId);

        emit CommodityOutOfChain(_tokenId, msg.sender);
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
