// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.10;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

interface IWorldesRWAToken {
    function setMaxSupply(uint256 increaseSupply) external;
}

contract WorldesPropertyRights is 
    Ownable,
    ERC721Enumerable, 
    ERC721URIStorage
{
    enum AssetStatus {
        Tradable,
        Untradable,
        Voided
    }

    uint256 private _nextTokenId = 1;
    mapping(uint256 => AssetStatus) public _ASSET_STATUS_BY_TOKEN_ID_;
    //asset_tokenId => rwa_erc20_Address
    mapping(uint256 => address) public _TOKEN_ID_TO_RWA_ADDRESS_;
    //rwa_erc20_Address => asset_tokenId
    mapping(address => uint256) public _RWA_ADDRESS_TO_TOKEN_ID_;
    mapping (address => bool) public _MINTER_AMIN_LIST_;
    mapping (uint256 => address) public _NOTARY_AMDIN_MAPPING_;

    address public _WORLDES_RWA_TOKEN_FACTORY_;

    // ============ Events ============

    event AddMinter(address indexed sender, address indexed newAddr);
    event RemoveMinter(address indexed sender, address indexed newAddr);
    event SetRwaStatus(address indexed sender, uint256 indexed tokenId, AssetStatus status);
    event ClearRwaRelation(address indexed sender, uint256 indexed tokenId, address rwaToken);
    event IncreaseMaxSupply(uint256 indexed tokenId, uint256 increaseSupply);
    event SafeMint(address indexed sender, address indexed to, uint256 indexed tokenId, address notary, string uri);

    constructor(
        address owner,
        address worldesRwaTokenFactory
    ) 
      ERC721("Worldes Property Rights", "WPR")
    {
        _transferOwnership(owner);
        _WORLDES_RWA_TOKEN_FACTORY_ = worldesRwaTokenFactory;
    }

    modifier onlyNotary(uint256 tokenId) {
        require(_NOTARY_AMDIN_MAPPING_[tokenId] == _msgSender(), "WPR: sender is not notary admin");
        _;
    }

    modifier onlyMinter() {
        require(_MINTER_AMIN_LIST_[_msgSender()], "WPR: sender is not minter admin");
        _;
    }

    // modifier onlyTokenOwner(uint256 tokenId) {
    //     require(_msgSender() == ownerOf(tokenId), "WPR: caller is not token owner");
    //     _;
    // }

    modifier onlyTokenFactory() {
        require(_msgSender() == _WORLDES_RWA_TOKEN_FACTORY_, "WPR: caller is not token factory");
        _;
    }

    function addMinter (address newAddr) public onlyOwner {
        _MINTER_AMIN_LIST_[newAddr] = true;

        emit AddMinter(_msgSender(), newAddr);
    }

    function removeMinter (address newAddr) public onlyOwner {
        _MINTER_AMIN_LIST_[newAddr] = false;

        emit RemoveMinter(_msgSender(), newAddr);
    }

    function setRwaStatus(uint256 tokenId, AssetStatus status) external onlyNotary(tokenId) {
        require(status != _ASSET_STATUS_BY_TOKEN_ID_[tokenId], "WPR: status is been setted.");
        require(_ASSET_STATUS_BY_TOKEN_ID_[tokenId] != AssetStatus.Voided, "WPR: asset status is voided.");
        _ASSET_STATUS_BY_TOKEN_ID_[tokenId] = status;

        emit SetRwaStatus(_msgSender(), tokenId, status);
    }

    function clearRwaRelation(uint256 tokenId) external onlyNotary(tokenId) {
        address rwaToken = _TOKEN_ID_TO_RWA_ADDRESS_[tokenId];
        _TOKEN_ID_TO_RWA_ADDRESS_[tokenId] == address(0);

        emit ClearRwaRelation(_msgSender(), tokenId, rwaToken);
    }

    function increaseMaxSupply(uint256 tokenId, uint256 increaseSupply) external onlyNotary(tokenId) {
        IWorldesRWAToken(_TOKEN_ID_TO_RWA_ADDRESS_[tokenId]).setMaxSupply(increaseSupply);

        emit IncreaseMaxSupply(tokenId, increaseSupply);
    }

    function beforeDeployRWAToken(uint256 tokenId, address from) external onlyTokenFactory{
        require(from == ownerOf(tokenId), "WPR: from is not the owner of this token.");
        require(_TOKEN_ID_TO_RWA_ADDRESS_[tokenId] == address(0), "WPR: RWA is deployed.");
    }

    function afterDeployRWAToken(uint256 tokenId, address rwaToken) external onlyTokenFactory {
        _TOKEN_ID_TO_RWA_ADDRESS_[tokenId] = address(rwaToken);
        _RWA_ADDRESS_TO_TOKEN_ID_[address(rwaToken)] = tokenId;
        _ASSET_STATUS_BY_TOKEN_ID_[tokenId] = AssetStatus.Untradable;
    }

    function setTokenURI(uint256 tokenId, string memory uri) external onlyMinter {
        require(_ASSET_STATUS_BY_TOKEN_ID_[tokenId] != AssetStatus.Voided, "WPR: token is voided.");
        _setTokenURI(tokenId, uri);
    }

    function safeMint(address to, address notary, string memory uri) external onlyMinter {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        _ASSET_STATUS_BY_TOKEN_ID_[tokenId] = AssetStatus.Tradable;
        _NOTARY_AMDIN_MAPPING_[tokenId] = notary;

        emit SafeMint(_msgSender(), to, tokenId, notary, uri);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) 
        internal 
        override(ERC721, ERC721URIStorage) 
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        require(_ASSET_STATUS_BY_TOKEN_ID_[firstTokenId] == AssetStatus.Tradable, "WPR: this token is untradable.");
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }
}
