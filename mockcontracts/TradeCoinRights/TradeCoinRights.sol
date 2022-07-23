// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./TradeCoinFactory.sol";

contract TradeCoinRights is ERC721 {
    constructor() ERC721("TradeCoinRights", "TCR") {
        admin = msg.sender;
    }

    TradeCoinFactory public tradeCoinFactory;

    address private admin;

    function safeMint(address to) public {
        require(
            address(tradeCoinFactory) == msg.sender,
            "This is not the address of the TradeCoin Setup"
        );

        uint256 tokenId = tradeCoinFactory.getTokenCounter();
        _safeMint(to, tokenId);
    }

    function transfer(address _to, uint256 id) public {
        safeTransferFrom(msg.sender, _to, id);
    }

    function transferForComposition(uint256[] calldata ids) external {
        for (uint256 i; i < ids.length; i++) {
            require(
                ownerOf(ids[i]) == msg.sender,
                "You don't own these tokens"
            );
            safeTransferFrom(msg.sender, address(tradeCoinFactory), ids[i]);
        }
    }

    function setTradeCoinSetupAddr(address _tradeCoinFactoryAddr) public {
        require(admin == msg.sender, "You are not the admin");

        tradeCoinFactory = TradeCoinFactory(_tradeCoinFactoryAddr);
    }
}
