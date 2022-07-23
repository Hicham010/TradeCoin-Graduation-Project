//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./interfaces/ITradeCoinTokenizer.sol";

contract TradeCoinTokenizerV2 is ERC721, ITradeCoinTokenizer {
    struct TradeCoinToken {
        string commodity;
        uint256 amount;
        string unit;
    }

    uint256 public tokenCounter;

    mapping(uint256 => TradeCoinToken) public tradeCoinToken;

    constructor() ERC721("TradeCoinTokenizerV2", "TCT") {}

    function mintToken(
        string memory commodity,
        uint256 amount,
        string memory unit
    ) external override {
        tradeCoinToken[tokenCounter] = TradeCoinToken(commodity, amount, unit);
        _mint(msg.sender, tokenCounter);

        emit MintToken(tokenCounter, msg.sender, commodity, amount, unit);

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
    }

    function decreaseAmount(uint256 tokenId, uint256 amountDecrease)
        external
        override
    {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        unchecked {
            tradeCoinToken[tokenId].amount -= amountDecrease;
        }
    }

    function burnToken(uint256 tokenId) external override {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
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
