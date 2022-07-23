// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./TradeCoinTokenizerV2.sol";
import "./RoleControl.sol";
import "./interfaces/ITradeCoin.sol";

contract TradeCoinV4 is ERC721, RoleControl, ITradeCoin {
    uint256 public tokenCounter;
    TradeCoinTokenizerV2 public tradeCoinTokenizer;

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

    mapping(uint256 => TradeCoinCommodity) public tradeCoinCommodity;
    mapping(uint256 => CommoditySale) public commoditySaleQueue;

    modifier isCurrentHandler(uint256 tokenId) {
        require(
            tradeCoinCommodity[tokenId].currentHandler == msg.sender,
            "Caller is not the current handler"
        );
        _;
    }

    constructor(address _tradeCoinTokenizer)
        ERC721("TradeCoinV4", "TCT4")
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
        tradeCoinTokenizer.transferFrom(
            msg.sender,
            address(this),
            tokenIdOfTokenizer
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
        CommoditySale memory _sale = commoditySaleQueue[tokenIdOfTokenizer];
        require(_sale.isPaid, "Not payed for yet");
        require(_sale.handler == msg.sender, "Not a handler");

        if (!(_sale.priceInWei == 0)) {
            payable(_sale.seller).transfer(_sale.priceInWei);
        }
        _mint(_sale.owner, tokenCounter);

        (bytes4 hashOfProperties, uint256 amount) = emitTokenData(
            tokenIdOfTokenizer
        );

        tradeCoinCommodity[tokenCounter] = TradeCoinCommodity(
            amount,
            State.Created,
            hashOfProperties,
            msg.sender
        );

        tradeCoinTokenizer.burnToken(tokenIdOfTokenizer);

        emit CompleteSale(tokenCounter, _sale.seller, msg.sender);

        // delete commoditySaleQueue[tokenIdOfTokenizer];
        unchecked {
            tokenCounter += 1;
        }
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

    function addTransformation(uint256 _tokenId, string calldata transformation)
        external
        override
        onlyTransformationHandler
        isCurrentHandler(_tokenId)
    {
        tradeCoinCommodity[_tokenId].hashOfProperties =
            tradeCoinCommodity[_tokenId].hashOfProperties ^
            bytes4(keccak256(abi.encodePacked(transformation)));

        emit CommodityTransformation(_tokenId, msg.sender, transformation);
    }

    function addTransformationDecrease(
        uint256 _tokenId,
        string calldata transformation,
        uint256 amountDecrease
    ) external override onlyTransformationHandler isCurrentHandler(_tokenId) {
        tradeCoinCommodity[_tokenId].amount -= amountDecrease;

        tradeCoinCommodity[_tokenId].hashOfProperties =
            tradeCoinCommodity[_tokenId].hashOfProperties ^
            bytes4(keccak256(abi.encodePacked(transformation)));

        emit CommodityTransformationDecrease(
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

    function addInformationToCommodity(uint256 _tokenId, string calldata data)
        external
        override
        onlyInformationHandler
        isCurrentHandler(_tokenId)
    {
        emit AddInformation(_tokenId, msg.sender, data);
    }

    function checkQualityOfCommodity(uint256 _tokenId, string calldata data)
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

    function batchCommodities(uint256[] calldata _tokenIds) external override {
        uint256 tokenId0 = _tokenIds[0];
        require(ownerOf(tokenId0) == msg.sender, "Not the owner");
        require(_tokenIds.length > 1, "Length of array must be greater than 1");
        bytes32 hashOfCommodity = keccak256(
            abi.encodePacked(
                tradeCoinCommodity[tokenId0].state,
                tradeCoinCommodity[tokenId0].hashOfProperties
            )
        );

        uint256 cumulativeAmount = tradeCoinCommodity[tokenId0].amount;

        uint256 tokenIdsLength = _tokenIds.length;
        for (uint256 i = 1; i < tokenIdsLength; ) {
            uint256 tokenIdI = _tokenIds[i];
            require(ownerOf(tokenIdI) == msg.sender, "Not the owner");
            bytes32 hashOfiProduct = keccak256(
                abi.encodePacked(
                    tradeCoinCommodity[tokenIdI].state,
                    tradeCoinCommodity[tokenIdI].hashOfProperties
                )
            );
            require(
                hashOfiProduct == hashOfCommodity,
                "Properties don't match"
            );
            _burn(tokenIdI);
            // delete tradeCoinCommodity[_tokenIds[i]];
            unchecked {
                cumulativeAmount += tradeCoinCommodity[tokenIdI].amount;
                ++i;
            }
        }

        _mint(msg.sender, tokenCounter);
        tradeCoinCommodity[tokenCounter] = TradeCoinCommodity(
            cumulativeAmount,
            State.Created,
            tradeCoinCommodity[tokenId0].hashOfProperties,
            tradeCoinCommodity[tokenId0].currentHandler
        );

        _burn(tokenId0);
        // delete tradeCoinCommodity[_tokenIds[0]];

        emit BatchCommodities(tokenCounter, msg.sender, _tokenIds);

        tokenCounter += 1;
    }

    function splitCommodity(uint256 _tokenId, uint256[] calldata partitions)
        external
        override
    {
        uint256 partitionsLength = partitions.length;
        uint256 cumulativeAmountPartitions;

        require(ownerOf(_tokenId) == msg.sender, "Not the owner");
        require(partitionsLength > 1, "Length of array must be bigger than 1");

        for (uint256 i; i < partitionsLength; ) {
            uint256 partition = partitions[i];
            require(partition != 0, "Partition can't be 0");
            cumulativeAmountPartitions += partition;
            unchecked {
                ++i;
            }
        }
        require(
            tradeCoinCommodity[_tokenId].amount == cumulativeAmountPartitions,
            "The amounts don't add up"
        );

        _burn(_tokenId);

        uint256[] memory newTokens = new uint256[](partitionsLength);
        bytes4 _hashOfProperties = tradeCoinCommodity[_tokenId]
            .hashOfProperties;
        address _currentHandler = tradeCoinCommodity[_tokenId].currentHandler;
        uint256 _tokenCounter = tokenCounter;

        for (uint256 i; i < partitionsLength; ) {
            uint256 partition = partitions[i];
            _mint(msg.sender, _tokenCounter);
            tradeCoinCommodity[_tokenCounter] = TradeCoinCommodity(
                partition,
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
        // delete tradeCoinCommodity[_tokenId];

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
