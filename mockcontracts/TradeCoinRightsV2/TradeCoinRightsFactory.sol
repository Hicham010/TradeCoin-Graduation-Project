//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./LimitedERC721.sol";
import "./TradeCoin.sol";
import "./TradeCoinComposition.sol";

//TODO: ask about splitting of ownership or creating a debt?
contract TradeCoinRightsFactory {
    TradeCoinERC721 public tradeCoin;
    TradeCoinCompositionERC721 public tradeCoinComposition;

    LimitedERC721 public tradeCoinRights;
    LimitedERC721 public tradeCoinDebt;

    uint256 tokenCounter;

    struct Debt {
        address lender;
        address borrower;
        uint256[] tradeCoinCollateralIds;
        uint256[] tradeCoinCompositionCollateralIds;
        uint256 debtInWei;
    }

    mapping(uint256 => Debt) public debt;
    mapping(uint256 => bool) public debtIsNotPaid;

    constructor(address tradeCoinAddress, address tradeCoinCompositionAddress) {
        tradeCoin = TradeCoinERC721(tradeCoinAddress);
        tradeCoinComposition = TradeCoinCompositionERC721(
            tradeCoinCompositionAddress
        );
        tradeCoinRights = new LimitedERC721(msg.sender);
        tradeCoinDebt = new LimitedERC721(msg.sender);
    }

    function initializeDebt(
        address borrower,
        uint256[] memory _tcIds,
        uint256[] memory _tccIds,
        uint256 debtInWei
    ) external {
        for (uint256 i; i < _tcIds.length; i++) {
            tradeCoin.transferFrom(msg.sender, address(this), _tcIds[i]);
        }
        for (uint256 i; i < _tccIds.length; i++) {
            tradeCoinComposition.transferFrom(
                msg.sender,
                address(this),
                _tccIds[i]
            );
        }
        tradeCoinRights.mint(borrower, tokenCounter);
        tradeCoinDebt.mint(msg.sender, tokenCounter);

        debt[tokenCounter] = Debt(
            msg.sender,
            borrower,
            _tcIds,
            _tccIds,
            debtInWei
        );

        tokenCounter += 1;
    }
}
