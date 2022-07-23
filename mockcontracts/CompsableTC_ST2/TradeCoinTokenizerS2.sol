//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@rari-capital/solmate/src/utils/SSTORE2.sol";
import "./interfaces/ITradeCoinTokenizer.sol";

contract TradeCoinTokenizerS2 is ERC721, ITradeCoinTokenizer {
    struct TradeCoinToken {
        string commodity;
        uint256 amount;
        string unit;
    }

    uint256 public tokenCounter;

    mapping(uint256 => address) private tradeCoinToken;

    constructor() ERC721("TradeCoinTokenizerV2", "TCTV2") {}

    function mintToken(
        string memory commodity,
        uint256 amount,
        string memory unit
    ) external override {
        tradeCoinToken[tokenCounter] = SSTORE2.write(
            abi.encode(TradeCoinToken(commodity, amount, unit))
        );
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
        TradeCoinToken memory _tradeCoin = abi.decode(
            SSTORE2.read(tradeCoinToken[tokenId]),
            (TradeCoinToken)
        );
        unchecked {
            _tradeCoin.amount += amountIncrease;
        }

        tradeCoinToken[tokenCounter] = SSTORE2.write(abi.encode(_tradeCoin));
    }

    function decreaseAmount(uint256 tokenId, uint256 amountDecrease)
        external
        override
    {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        TradeCoinToken memory _tradeCoin = abi.decode(
            SSTORE2.read(tradeCoinToken[tokenId]),
            (TradeCoinToken)
        );
        unchecked {
            _tradeCoin.amount -= amountDecrease;
        }

        tradeCoinToken[tokenCounter] = SSTORE2.write(abi.encode(_tradeCoin));
    }

    function burnToken(uint256 tokenId) external override {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        _burn(tokenId);
    }

    function readTradeCoinData(uint256 tokenId)
        external
        view
        returns (TradeCoinToken memory)
    {
        return
            abi.decode(SSTORE2.read(tradeCoinToken[tokenId]), (TradeCoinToken));
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
