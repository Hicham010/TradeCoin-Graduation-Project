//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// Probably not needed for solidity 0.8.x
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "hardhat/console.sol";

contract TradeCoinV1 is ERC721 {
    using SafeMath for uint256;
    using SafeMath for uint8;
    using Strings for uint256;

    uint256 public tokenCounter = 0;

    mapping(uint256 => uint256) public weight_gram;
    mapping(uint256 => string) public Commodity_type;
    mapping(uint256 => string[]) public ISO_list;

    mapping(address => mapping(address => uint256[])) public cargo;

    event Delevered(
        address indexed transporter,
        address indexed receiver,
        uint256[] cargo
    );

    constructor() ERC721("Commoditys", "Commodity") {}

    function mintCommodity(uint256 _weight_gram, string memory _Commodity_type)
        public
    {
        uint256 _tokenId = tokenCounter.add(1);
        _mint(msg.sender, _tokenId);
        weight_gram[_tokenId] = _weight_gram;
        Commodity_type[_tokenId] = _Commodity_type;
        tokenCounter = _tokenId;
    }

    function decreaseWeight(uint256 _weight_gram, uint256 _tokenId)
        public
        returns (uint256)
    {
        require(
            msg.sender == ERC721.ownerOf(_tokenId),
            "You are not the owner"
        );
        uint256 weight = weight_gram[_tokenId];
        require(weight >= _weight_gram, "Weight can't be negative");

        weight_gram[_tokenId] = weight - _weight_gram;

        return weight_gram[_tokenId];
    }

    function addISOList(string[] memory _ISO_list, uint256 _tokenId) public {
        require(
            msg.sender == ERC721.ownerOf(_tokenId),
            "You are not the owner"
        );

        ISO_list[_tokenId] = _ISO_list;
    }

    function addISO(string memory _ISO, uint256 _tokenId) public {
        require(
            msg.sender == ERC721.ownerOf(_tokenId),
            "You are not the owner"
        );

        ISO_list[_tokenId].push(_ISO);
    }

    function getISOLength(uint256 _tokenId) public view returns (uint256) {
        return ISO_list[_tokenId].length;
    }

    function getCargoByIndex(
        address _transporter,
        address _receiver,
        uint256 _indexCargo
    ) public view returns (uint256) {
        return cargo[_transporter][_receiver][_indexCargo];
    }

    function transport(
        address _transporter,
        address _receiver,
        uint256[] memory _tokenIdList
    ) public {
        // Will break because it assumes a receiver can have only 1 delivery per transporter
        for (uint8 i = 0; i < _tokenIdList.length; i++) {
            require(
                msg.sender == ERC721.ownerOf(_tokenIdList[i]),
                "You are not the owner"
            );
            approve(_receiver, _tokenIdList[i]);
        }
        cargo[_transporter][_receiver] = _tokenIdList;
    }

    function delivered(
        address _transporter,
        address _seller,
        uint256[] memory _tokenIdList
    ) public {
        uint256[] memory _cargo_list = cargo[_transporter][msg.sender];
        require(
            keccak256(abi.encodePacked(_cargo_list)) ==
                keccak256(abi.encodePacked(_tokenIdList)),
            "You are not the owner of this cargo"
        );

        for (uint256 i = 0; i < _cargo_list.length; i++) {
            transferFrom(_seller, msg.sender, _cargo_list[i]);
        }

        emit Delevered(_transporter, msg.sender, _cargo_list);
        delete cargo[_transporter][msg.sender];
    }

    function batchCommoditys(uint256 _tokenId1, uint256 _tokenId2) public {
        require(
            msg.sender == ERC721.ownerOf(_tokenId1) &&
                msg.sender == ERC721.ownerOf(_tokenId2),
            "You are not the owner both NFT's"
        );
        require(
            keccak256(abi.encode(Commodity_type[_tokenId1])) ==
                keccak256(abi.encode(Commodity_type[_tokenId2])),
            "The Commoditys have to be the same kind"
        );

        // This will break because a list with the same ISO's but ordered different will produce different hashes
        require(
            keccak256(abi.encode(ISO_list[_tokenId1])) ==
                keccak256(abi.encode(ISO_list[_tokenId2])),
            "The Commoditys have to have the same ISO processes"
        );

        uint256 _weight = weight_gram[_tokenId1].add(weight_gram[_tokenId2]);

        weight_gram[_tokenId1] = 0;
        weight_gram[_tokenId2] = 0;

        _burn(_tokenId1);
        _burn(_tokenId2);

        mintCommodity(_weight, Commodity_type[_tokenId1]);
        ISO_list[tokenCounter] = ISO_list[_tokenId1];
    }
}
