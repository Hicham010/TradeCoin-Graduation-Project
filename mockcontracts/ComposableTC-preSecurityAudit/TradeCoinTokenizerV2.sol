//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./interfaces/ITradeCoinTokenizer.sol";

contract TradeCoinTokenizerV2 is ERC721, ITradeCoinTokenizer {
    uint256 public tokenCounter;

    struct TradeCoinToken {
        string commodity;
        uint256 amount;
        string unit;
    }

    mapping(uint256 => TradeCoinToken) public tradeCoinToken;

    constructor() ERC721("TradeCoinTokenizerV2", "TCTV2") {}

    function mintToken(
        string memory _commodity,
        uint256 _amount,
        string memory _unit
    ) external override {
        tradeCoinToken[tokenCounter] = TradeCoinToken(
            _commodity,
            _amount,
            _unit
        );
        _mint(msg.sender, tokenCounter);

        emit MintToken(tokenCounter, msg.sender, _commodity, _amount, _unit);

        unchecked {
            tokenCounter += 1;
        }
    }

    function increaseAmount(uint256 tokenId, uint256 amountIncrease)
        external
        override
    {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        unchecked {
            tradeCoinToken[tokenId].amount += amountIncrease;
        }
        // emit IncreaseCommodity(tokenId, amountIncrease);
    }

    function decreaseAmount(uint256 tokenId, uint256 amountDecrease)
        external
        override
    {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        unchecked {
            tradeCoinToken[tokenId].amount -= amountDecrease;
        }
        // emit DecreaseCommodity(tokenId, amountDecrease);
    }

    function burnToken(uint256 tokenId) external override {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        // delete tradeCoinToken[tokenId];
        _burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return
            type(ITradeCoinTokenizer).interfaceId == interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
