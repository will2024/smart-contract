/*
 
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;

import {IERC20} from "../interfaces/IERC20.sol";
import {SafeERC20} from "../libraries/SafeERC20.sol";
import {InitializableOwnable} from "../libraries/InitializableOwnable.sol";


/**
 * @title WorldesApprove
  *
 * @notice Handle authorizations in Worldes platform
 */
contract WorldesApprove is InitializableOwnable {
    using SafeERC20 for IERC20;
    
    // ============ Storage ============
    uint256 private constant _TIMELOCK_DURATION_ = 3 days;
    uint256 private constant _TIMELOCK_EMERGENCY_DURATION_ = 24 hours;
    uint256 public _TIMELOCK_;
    address public _PENDING_WORLDES_PROXY_;
    address public _WORLDES_PROXY_;

    // ============ Events ============

    event SetWorldesProxy(address indexed oldProxy, address indexed newProxy);

    
    // ============ Modifiers ============
    modifier notLocked() {
        require(
            _TIMELOCK_ <= block.timestamp,
            "SetProxy is timelocked"
        );
        _;
    }

    function init(address owner, address initProxyAddress) external {
        initOwner(owner);
        _WORLDES_PROXY_ = initProxyAddress;
    }

    function unlockSetProxy(address newSwapProxy) public onlyOwner {
        if(_WORLDES_PROXY_ == address(0))
            _TIMELOCK_ = block.timestamp + _TIMELOCK_EMERGENCY_DURATION_;
        else
            _TIMELOCK_ = block.timestamp + _TIMELOCK_DURATION_;
        _PENDING_WORLDES_PROXY_ = newSwapProxy;
    }


    function lockSetProxy() public onlyOwner {
       _PENDING_WORLDES_PROXY_ = address(0);
       _TIMELOCK_ = 0;
    }


    function setWorldesProxy() external onlyOwner notLocked() {
        emit SetWorldesProxy(_WORLDES_PROXY_, _PENDING_WORLDES_PROXY_);
        _WORLDES_PROXY_ = _PENDING_WORLDES_PROXY_;
        lockSetProxy();
    }


    function claimTokens(
        address token,
        address who,
        address dest,
        uint256 amount
    ) external {
        require(msg.sender == _WORLDES_PROXY_, "WorldesApprove:Access restricted");
        if (amount > 0) {
            IERC20(token).safeTransferFrom(who, dest, amount);
        }
    }

    function getWorldesProxy() public view returns (address) {
        return _WORLDES_PROXY_;
    }
}
