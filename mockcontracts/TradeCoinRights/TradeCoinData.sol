// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./TradeCoinFactory.sol";
import "./TradeCoinTokenizer.sol";

contract TradeCoinData is ERC721 {
    constructor() ERC721("TradeCoinData", "TCD") {
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

    function setTradeCoinSetupAddr(address _tradeCoinFactoryAddr) public {
        require(admin == msg.sender, "You are not the admin");

        tradeCoinFactory = TradeCoinFactory(_tradeCoinFactoryAddr);
    }

    function addTransformation(
        uint256 _tokenId,
        uint256 weightLoss,
        string memory _transformationCode,
        bytes32 _docHash,
        string memory _docType,
        bytes32 _rootHash
    ) public isOwner(_tokenId) {
        tradeCoinFactory.addTransformation(
            _tokenId,
            weightLoss,
            _transformationCode,
            _docHash,
            _docType,
            _rootHash
        );
    }

    function changeStateAndHandler(
        uint256 _tokenId,
        address _newCurrentHandler,
        uint8 _newState,
        bytes32 _docHash,
        string memory _docType,
        bytes32 _rootHash
    ) public isOwner(_tokenId) {
        tradeCoinFactory.changeStateAndHandler(
            _tokenId,
            _newCurrentHandler,
            _newState,
            _docHash,
            _docType,
            _rootHash
        );
    }

    function addInformation(
        uint256 _tokenId,
        bytes32 _docHash,
        string memory _docType,
        bytes32 _rootHash
    ) public isOwner(_tokenId) {
        tradeCoinFactory.addInformation(
            _tokenId,
            _docHash,
            _docType,
            _rootHash
        );
    }

    modifier isOwner(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner");
        _;
    }
}
