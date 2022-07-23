// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "./TradeCoinV4.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TradeCoinEscrow is ReentrancyGuard {
    struct SaleQueue {
        address seller;
        address newOwner;
        uint256 priceInWei;
        bool isPayed;
    }

    TradeCoinV4 public tradeCoinV4;
    uint256 public tradeCoinTokenBalance;
    uint256 public weiBalance;

    event InitializeSale(
        uint256 tradeCoinTokenID,
        address seller,
        address newOwner,
        uint256 priceInWei,
        bool isPayed
    );

    event PayForToken(uint256 tradeCoinTokenID, address financer);

    event CompleteSale(uint256 tradeCoinTokenID, address lastSigner);

    event ReverseSale(uint256 tradeCoinTokenID, address aborter);

    constructor(address _tradeCoinV4) {
        tradeCoinV4 = TradeCoinV4(_tradeCoinV4);
    }

    mapping(uint256 => SaleQueue) public pendingSales;

    function initializeSale(
        uint256 tradeCoinTokenID,
        address _newOwner,
        uint256 priceInWei
    ) external {
        tradeCoinV4.transferFrom(msg.sender, address(this), tradeCoinTokenID);
        pendingSales[tradeCoinTokenID] = SaleQueue(
            msg.sender,
            _newOwner,
            priceInWei,
            priceInWei == 0
        );
        tradeCoinTokenBalance += 1;

        emit InitializeSale(
            tradeCoinTokenID,
            msg.sender,
            _newOwner,
            priceInWei,
            priceInWei == 0
        );
    }

    function payForToken(uint256 tradeCoinTokenID) external payable {
        require(
            pendingSales[tradeCoinTokenID].priceInWei == msg.value,
            "Not the right price"
        );
        pendingSales[tradeCoinTokenID].isPayed = true;
        weiBalance += msg.value;

        emit PayForToken(tradeCoinTokenID, msg.sender);
    }

    function completeSale(uint256 tradeCoinTokenID) external nonReentrant {
        require(pendingSales[tradeCoinTokenID].isPayed, "Not the right price");
        weiBalance -= pendingSales[tradeCoinTokenID].priceInWei;
        tradeCoinTokenBalance -= 1;
        tradeCoinV4.transferFrom(
            address(this),
            pendingSales[tradeCoinTokenID].newOwner,
            tradeCoinTokenID
        );
        payable(pendingSales[tradeCoinTokenID].seller).transfer(
            pendingSales[tradeCoinTokenID].priceInWei
        );

        delete pendingSales[tradeCoinTokenID];

        emit CompleteSale(tradeCoinTokenID, msg.sender);
    }

    function reverseSale(uint256 tradeCoinTokenID) external nonReentrant {
        require(
            pendingSales[tradeCoinTokenID].seller == msg.sender ||
                pendingSales[tradeCoinTokenID].newOwner == msg.sender,
            "Not the seller or new owner"
        );
        tradeCoinTokenBalance -= 1;

        tradeCoinV4.transferFrom(
            address(this),
            pendingSales[tradeCoinTokenID].seller,
            tradeCoinTokenID
        );
        if (
            pendingSales[tradeCoinTokenID].isPayed &&
            pendingSales[tradeCoinTokenID].priceInWei != 0
        ) {
            weiBalance -= pendingSales[tradeCoinTokenID].priceInWei;

            payable(pendingSales[tradeCoinTokenID].seller).transfer(
                pendingSales[tradeCoinTokenID].priceInWei
            );
        }
        delete pendingSales[tradeCoinTokenID];

        emit ReverseSale(tradeCoinTokenID, msg.sender);
    }
}
