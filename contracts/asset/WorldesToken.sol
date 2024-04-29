// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.10;

import {Ownable} from  "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from  "@openzeppelin/contracts/security/Pausable.sol";
import {ERC20} from  "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from  "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract WorldesToken is 
    Ownable, 
    Pausable,
    ERC20Permit
{
    uint8 private _decimals = 18;
    address public _LIST_ADMIN_;
    bool public _WHITE_LISTED_ENABLE_ = false;
    mapping (address => bool) public isWhiteListed;
    mapping (address => bool) public isBlackListed;

    error ErrZeroAddress();
    error ErrCallerIsNotListAdmin(address caller, address listAdmin);
    error ErrTransferWhilePaused(address from, address to, uint256 amount);
    error ErrTransferNotWhiteListed(address from, address to, uint256 amount);
    error ErrTransferBlackListed(address from, address to, uint256 amount);

    modifier onlyListAdmin() {
        if (_msgSender() != _LIST_ADMIN_) {
            revert ErrCallerIsNotListAdmin(_msgSender(), _LIST_ADMIN_);
        }
        _;
    }

    constructor(
        address owner,
        address listAdmin,
        address to,
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        uint8 intitialDecimals
    )
        ERC20(name, symbol)
        ERC20Permit("WESToken")
    {
        if (owner == address(0) || listAdmin == address(0) || to == address(0)) {
            revert ErrZeroAddress();
        }
        _transferOwnership(owner);
        _decimals = intitialDecimals;
        _LIST_ADMIN_ = listAdmin;
        _mint(to, initialSupply * 10 ** intitialDecimals);
    }

    function addWhiteList (address newAddr) public onlyListAdmin {
        isWhiteListed[newAddr] = true;
    }

    function removeWhiteList (address newAddr) public onlyListAdmin {
        isWhiteListed[newAddr] = false;
    }

    function addBlackList (address newAddr) public onlyListAdmin {
        isBlackListed[newAddr] = true;
    }

    function removeBlackList (address newAddr) public onlyListAdmin {
        isBlackListed[newAddr] = false;
    }

    function setListAdmin(address listAdmin) external onlyOwner {
        if (listAdmin == address(0)) {
            revert ErrZeroAddress();
        }
        _LIST_ADMIN_ = listAdmin;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) external onlyOwner {
        if (to == address(0)) {
            revert ErrZeroAddress();
        }
        _mint(to, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20) {

        if (paused()) {
            revert ErrTransferWhilePaused(from, to, amount);
        }

        if (_WHITE_LISTED_ENABLE_) {
            if (!isWhiteListed[from] || !isWhiteListed[to]) {
                revert ErrTransferNotWhiteListed(from, to, amount);
            }
        } else {
            if (isBlackListed[from] || isBlackListed[to]) {
                revert ErrTransferBlackListed(from, to, amount);
            }
        }

        super._afterTokenTransfer(from, to, amount);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}
