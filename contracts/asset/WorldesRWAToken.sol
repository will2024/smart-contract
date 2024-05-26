// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.10;

import {Ownable} from  "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from  "@openzeppelin/contracts/security/Pausable.sol";
import {ERC20} from  "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from  "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract WorldesRWAToken is 
    Ownable, 
    Pausable,
    ERC20Permit
{
    uint8 private _decimals = 18;
    address public _LIST_ADMIN_;
    bool public _WHITE_LISTED_ENABLE_ = false;
    mapping (address => bool) public isWhiteListed;
    mapping (address => bool) public isBlackListed;

    modifier onlyListAdmin() {
        require(_msgSender() == _LIST_ADMIN_, "WorldesRWAToken: caller is not list admin");
        _;
    }

    event SetListAdmin(address indexed sender, address indexed newAddr);

    event SetWhiteListEnable(address indexed sender, bool enable);

    event SetWhiteList(address indexed sender, address indexed newAddr, bool enable);

    event SetBlackList(address indexed sender, address indexed newAddr, bool enable);

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
        require(owner != address(0) && listAdmin != address(0) && to != address(0), "WorldesRWAToken: error zero address");
        _transferOwnership(owner);
        _decimals = intitialDecimals;
        _LIST_ADMIN_ = listAdmin;
        _mint(to, initialSupply * 10 ** intitialDecimals);
    }

    function enableWhiteList() public onlyOwner {
        _WHITE_LISTED_ENABLE_ = true;

        emit SetWhiteListEnable(_msgSender(), true);
    }

    function disableWhiteList() public onlyOwner {
        _WHITE_LISTED_ENABLE_ = false;

        emit SetWhiteListEnable(_msgSender(), false);
    }

    function addWhiteList (address newAddr) public onlyListAdmin {
        isWhiteListed[newAddr] = true;

        emit SetWhiteList(_msgSender(), newAddr, true);
    }

    function removeWhiteList (address newAddr) public onlyListAdmin {
        isWhiteListed[newAddr] = false;

        emit SetWhiteList(_msgSender(), newAddr, false);
    }

    function addBlackList (address newAddr) public onlyListAdmin {
        isBlackListed[newAddr] = true;

        emit SetBlackList(_msgSender(), newAddr, true);
    }

    function removeBlackList (address newAddr) public onlyListAdmin {
        isBlackListed[newAddr] = false;

        emit SetBlackList(_msgSender(), newAddr, false);
    }

    function setListAdmin(address listAdmin) external onlyOwner {
        require(listAdmin != address(0), "WorldesRWAToken: error zero address");
        _LIST_ADMIN_ = listAdmin;

        emit SetListAdmin(_msgSender(), listAdmin);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20) whenNotPaused() {
        
        if (_WHITE_LISTED_ENABLE_) {
            require(isWhiteListed[from] && isWhiteListed[to], "WorldesRWAToken: white list condition not met");
        } else {
            require(!isBlackListed[from] && !isBlackListed[to], "WorldesRWAToken: black list condition not met");
        }

        super._afterTokenTransfer(from, to, amount);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}
