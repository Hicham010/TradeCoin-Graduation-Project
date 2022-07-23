//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface ITradeCoinTokenizer {
    event InitializeSaleInCrypto(
        uint256 indexed tokenId,
        address indexed tokenizer,
        address indexed owner,
        uint256 priceInWei
    );

    event InitializeSaleInFiat(
        uint256 indexed tokenId,
        address indexed tokenizer,
        address indexed owner
    );

    event IncreaseCommodity(uint256 indexed tokenId, uint256 amountIncrease);

    event DecreaseCommodity(uint256 indexed tokenId, uint256 amountDecrease);

    function mintToken(
        string memory _commodity,
        uint256 _amount,
        string memory _unit
    ) external;

    function increaseAmount(uint256 tokenId, uint256 amountIncrease) external;

    function decreaseAmount(uint256 tokenId, uint256 amountDecrease) external;

    function burnToken(uint256 tokenId) external;
}
