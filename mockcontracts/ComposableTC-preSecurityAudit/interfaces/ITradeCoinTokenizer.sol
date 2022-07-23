//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

interface ITradeCoinTokenizer {
    event MintToken(
        uint256 indexed tokenId,
        address indexed tokenizer,
        string commodity,
        uint256 amount,
        string unit
    );

    event IncreaseCommodity(uint256 indexed tokenId, uint256 amountIncrease);

    event DecreaseCommodity(uint256 indexed tokenId, uint256 amountDecrease);

    function mintToken(
        string calldata _commodity,
        uint256 _amount,
        string calldata _unit
    ) external;

    function increaseAmount(uint256 tokenId, uint256 amountIncrease) external;

    function decreaseAmount(uint256 tokenId, uint256 amountDecrease) external;

    function burnToken(uint256 tokenId) external;
}
