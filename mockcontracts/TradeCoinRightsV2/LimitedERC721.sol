//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract LimitedERC721 is ERC721 {
    address public tradeCoinFactoryAddress;

    modifier isTCFactory(address _caller) {
        require(
            msg.sender == tradeCoinFactoryAddress,
            "Not the TradeCoin Factory"
        );
        _;
    }

    constructor(address _tradeCoinFactoryAddress) ERC721("", "") {
        tradeCoinFactoryAddress = _tradeCoinFactoryAddress;
    }

    function mint(address to, uint256 tokenId)
        external
        isTCFactory(msg.sender)
    {
        _safeMint(to, tokenId);
    }

    function approve(address to, uint256 tokenId)
        public
        override
        isTCFactory(msg.sender)
    {
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        isTCFactory(msg.sender)
    {
        super.setApprovalForAll(operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override isTCFactory(msg.sender) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override isTCFactory(msg.sender) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override isTCFactory(msg.sender) {
        super.safeTransferFrom(from, to, tokenId, _data);
    }
}
