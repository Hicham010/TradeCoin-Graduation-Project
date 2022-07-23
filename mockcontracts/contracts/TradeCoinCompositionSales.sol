// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
import "./TradeCoinComposition.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
contract TradeCoinCompositionSales is ReentrancyGuard {
    struct SaleQueue {
        address seller;
        address newOwner;
        uint256 priceInWei;
        bool payInFiat;
        bool isPayed;
    }

    struct Documents {
        bytes32[] docHash;
        bytes32[] docType;
        bytes32 rootHash;
    }

    TradeCoinCompositionERC721 public tradeCoinComposition;

    uint256 public tradeCoinTokenBalance;
    uint256 public weiBalance;
    
    event InitialCommercialTxEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        address indexed buyer,
        bool payInFiat,
        uint256 priceInWei,
        bool isPayed,
        bytes32[] docHash,
        bytes32[] docType,
        bytes32 rootHash
    );

    event FinishCommercialTxEvent(
        uint256 indexed tokenId,
        address indexed seller, 
        address indexed functionCaller, 
        bytes32[] dochash,
        bytes32[] docType,
        bytes32 rootHash
    );
    
    event CompleteSaleEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        bytes32[] dochash,
        bytes32[] docType,
        bytes32 rootHash
    );

    event ReverseSaleEvent(
        uint256 indexed tokenId,
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

    constructor(address _tradeCoin) {
        tradeCoinComposition = TradeCoinCompositionERC721(_tradeCoin);
    }

    mapping(uint256 => SaleQueue) public pendingSales;

    function initialCommercialTx(
        uint256 _tradeCoinTokenID,
        address _newOwner,
        uint256 _priceInWei,
        Documents memory _documents,
        bool _payInFiat
    ) external {
        tradeCoinComposition.transferFrom(msg.sender, address(this), _tradeCoinTokenID);
        pendingSales[_tradeCoinTokenID] = SaleQueue(
            msg.sender,
            _newOwner,
            _priceInWei,
            _payInFiat,
            _priceInWei == 0
        );
        tradeCoinTokenBalance += 1;
        emit InitialCommercialTxEvent(
            _tradeCoinTokenID,
            msg.sender,
            _newOwner,
            _payInFiat,
            _priceInWei,
            _priceInWei == 0,
            _documents.docHash,
            _documents.docType,
            _documents.rootHash
        );
    }

    function finishCommercialTx(
        uint256 _tradeCoinTokenID,
        Documents memory _documents
    ) external payable {
        if(!pendingSales[_tradeCoinTokenID].payInFiat){
            require(
                pendingSales[_tradeCoinTokenID].priceInWei == msg.value,
                "Not the right price"
            );
        }
        address legalOwner = pendingSales[_tradeCoinTokenID].seller;
        
        pendingSales[_tradeCoinTokenID].isPayed = true;
        weiBalance += msg.value;
        emit FinishCommercialTxEvent(
            _tradeCoinTokenID,
            legalOwner,
            msg.sender,
            _documents.docHash,
            _documents.docType,
            _documents.rootHash
        );
        completeSale(_tradeCoinTokenID, _documents);
    }

    function completeSale(
        uint256 _tradeCoinTokenID,
        Documents memory _documents
    ) internal nonReentrant {
        require(pendingSales[_tradeCoinTokenID].isPayed, "Not payed");
        weiBalance -= pendingSales[_tradeCoinTokenID].priceInWei;
        tradeCoinTokenBalance -= 1;
        tradeCoinComposition.transferFrom(
            address(this),
            pendingSales[_tradeCoinTokenID].newOwner,
            _tradeCoinTokenID
        );
        payable(pendingSales[_tradeCoinTokenID].seller).transfer(
            pendingSales[_tradeCoinTokenID].priceInWei
        );
        delete pendingSales[_tradeCoinTokenID];
        emit CompleteSaleEvent(
            _tradeCoinTokenID,
            msg.sender,
            _documents.docHash,
            _documents.docType,
            _documents.rootHash
        );
    }

    function reverseSale(uint256 _tradeCoinTokenID, Documents memory _documents) external nonReentrant {
        require(
            pendingSales[_tradeCoinTokenID].seller == msg.sender ||
                pendingSales[_tradeCoinTokenID].newOwner == msg.sender,
            "Not the seller or new owner"
        );
        tradeCoinTokenBalance -= 1;
        tradeCoinComposition.transferFrom(
            address(this),
            pendingSales[_tradeCoinTokenID].seller,
            _tradeCoinTokenID
        );
        if (
            pendingSales[_tradeCoinTokenID].isPayed &&
            pendingSales[_tradeCoinTokenID].priceInWei != 0
        ) {
            weiBalance -= pendingSales[_tradeCoinTokenID].priceInWei;
            payable(pendingSales[_tradeCoinTokenID].seller).transfer(
                pendingSales[_tradeCoinTokenID].priceInWei
            );
        }
        delete pendingSales[_tradeCoinTokenID];
        emit ReverseSaleEvent(
            _tradeCoinTokenID,
            msg.sender,
            _documents.docHash,
            _documents.docType,
            _documents.rootHash
        );
    }

    function servicePayment(
        uint256 _tradeCoinTokenID,
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
            _tradeCoinTokenID,
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
}