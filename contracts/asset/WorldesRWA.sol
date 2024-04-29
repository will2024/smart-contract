// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.10;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract WorldesRWA is 
    Ownable,
    ERC721Enumerable, 
    ERC721URIStorage
{
    enum RwaStatus {
        Tradable,
        Untradable,
        Voided
    }

    uint256 private _nextTokenId = 1;
    RwaStatus public _RWA_STATUS_ = RwaStatus.Tradable;
    mapping(uint256 => RwaStatus) public _RWA_STATUS_BY_TOKEN_;

    address public _NOTRAY_ADMIN_;
    address public _MINTER_ADMIN_;

    error ErrZeroAddress();
    error ErrCallerIsNotNotaryAdmin(address caller, address notaryAdmin);
    error ErrCallerIsNotMinterAdmin(address caller, address minterAdmin);
    error ErrCallerIsNotNftOwner(address caller, address owner);
    error ErrStatusIsTheSame(uint256 tokenId, RwaStatus status);
    error ErrStatusIsVoided(uint256 tokenId);
    error ErrTokenIsUntradable(uint256 tokenId, RwaStatus status);

    constructor(
        address owner,
        address notaryAdmin,
        address minterAdmin
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

    function setRwaStatus(uint256 tokenId, RwaStatus status) external onlyNotray {
        if (status == _RWA_STATUS_BY_TOKEN_[tokenId]) {
            revert ErrStatusIsTheSame(tokenId, status);
        }
        if (_RWA_STATUS_BY_TOKEN_[tokenId] == RwaStatus.Voided) {
            revert ErrStatusIsVoided(tokenId);
        }
        _RWA_STATUS_BY_TOKEN_[tokenId] = status;
    }

    function setTokenURI(uint256 tokenId, string memory uri) external onlyTokenOwner(tokenId) {
        _setTokenURI(tokenId, uri);
    }

    function safeMint(address to, string memory uri) external onlyMinter{
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
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

        if (_RWA_STATUS_BY_TOKEN_[firstTokenId] != RwaStatus.Tradable) {
            revert ErrTokenIsUntradable(firstTokenId, _RWA_STATUS_BY_TOKEN_[firstTokenId]);
        }
    }
}
