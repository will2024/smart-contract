// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.10;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

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

    address public _NOTRAY_ADMIN_;
    address public _MINTER_ADMIN_;
    address public _WORLDES_RWA_TOKEN_FACTORY_;

    error ErrZeroAddress();
    error ErrCallerIsNotNotaryAdmin(address caller, address notaryAdmin);
    error ErrCallerIsNotMinterAdmin(address caller, address minterAdmin);
    error ErrCallerIsNotNftOwner(address caller, address owner);
    error ErrCallerIsNotTokenFactory(address caller, address tokenFactory);
    error ErrStatusIsTheSame(uint256 tokenId, AssetStatus status);
    error ErrStatusIsVoided(uint256 tokenId);
    error ErrTokenIsUntradable(uint256 tokenId, AssetStatus status);
    error ErrRWATokenIsDeployed(uint256 tokenId, address rwaAddress);

    constructor(
        address owner,
        address notaryAdmin,
        address minterAdmin,
        address worldesRwaTokenFactory
    ) 
      ERC721("Worldes Property Rights", "WPR")
    {
        if (
            owner == address(0) || 
            notaryAdmin == address(0) || 
            minterAdmin == address(0)
        ) {
            revert ErrZeroAddress();
        }
        _transferOwnership(owner);
        _NOTRAY_ADMIN_ = notaryAdmin;
        _MINTER_ADMIN_ = minterAdmin;
        _WORLDES_RWA_TOKEN_FACTORY_ = worldesRwaTokenFactory;
    }

    modifier onlyNotray() {
        if (_msgSender() != _NOTRAY_ADMIN_) {
            revert ErrCallerIsNotNotaryAdmin(_msgSender(), _NOTRAY_ADMIN_);
        }
        _;
    }

    modifier onlyMinter() {
        if (_msgSender() != _MINTER_ADMIN_) {
            revert ErrCallerIsNotMinterAdmin(_msgSender(), _MINTER_ADMIN_);
        }
        _;
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        if (_msgSender() != ownerOf(tokenId)) {
            revert ErrCallerIsNotNftOwner(_msgSender(), ownerOf(tokenId));
        }
        _;
    }

    modifier onlyTokenFactory() {
        if (_msgSender() != _WORLDES_RWA_TOKEN_FACTORY_) {
            revert ErrCallerIsNotTokenFactory(_msgSender(), _WORLDES_RWA_TOKEN_FACTORY_);
        }
        _;
    }

    function setNotaryAdmin(address notaryAdmin) external onlyOwner {
        if (notaryAdmin == address(0)) {
            revert ErrZeroAddress();
        }
        _NOTRAY_ADMIN_ = notaryAdmin;
    }

    function setMinterAdmin(address minterAdmin) external onlyOwner {
        if (minterAdmin == address(0)) {
            revert ErrZeroAddress();
        }
        _MINTER_ADMIN_ = minterAdmin;
    }

    function setRwaStatus(uint256 tokenId, AssetStatus status) external onlyNotray {
        if (status == _ASSET_STATUS_BY_TOKEN_ID_[tokenId]) {
            revert ErrStatusIsTheSame(tokenId, status);
        }
        if (_ASSET_STATUS_BY_TOKEN_ID_[tokenId] == AssetStatus.Voided) {
            revert ErrStatusIsVoided(tokenId);
        }
        _ASSET_STATUS_BY_TOKEN_ID_[tokenId] = status;
    }

    function beforeDeployRWAToken(uint256 tokenId, address from) external view {
        if (from != ownerOf(tokenId)) {
            revert ErrCallerIsNotNftOwner(from, ownerOf(tokenId));
        }

        if (_TOKEN_ID_TO_RWA_ADDRESS_[tokenId] != address(0)) {
            revert ErrRWATokenIsDeployed(tokenId, _TOKEN_ID_TO_RWA_ADDRESS_[tokenId]);
        }
    }

    function afterDeployRWAToken(uint256 tokenId, address rwaToken) external onlyTokenFactory {
        _TOKEN_ID_TO_RWA_ADDRESS_[tokenId] = address(rwaToken);
        _RWA_ADDRESS_TO_TOKEN_ID_[address(rwaToken)] = tokenId;
        _ASSET_STATUS_BY_TOKEN_ID_[tokenId] = AssetStatus.Untradable;
    }

    function setTokenURI(uint256 tokenId, string memory uri) external onlyTokenOwner(tokenId) {
        if (_ASSET_STATUS_BY_TOKEN_ID_[tokenId] == AssetStatus.Voided) {
            revert ErrStatusIsVoided(tokenId);
        }
        _setTokenURI(tokenId, uri);
    }

    function safeMint(address to, string memory uri) external onlyMinter{
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        _ASSET_STATUS_BY_TOKEN_ID_[tokenId] = AssetStatus.Tradable;
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
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        if (_ASSET_STATUS_BY_TOKEN_ID_[firstTokenId] != AssetStatus.Tradable) {
            revert ErrTokenIsUntradable(firstTokenId, _ASSET_STATUS_BY_TOKEN_ID_[firstTokenId]);
        }
    }
}
