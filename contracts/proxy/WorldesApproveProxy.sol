/*
 
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

import {IWorldesApprove} from "../interfaces/IWorldesApprove.sol";
import {InitializableOwnable} from "../libraries/InitializableOwnable.sol";

interface IWorldesApproveProxy {
    function isAllowedProxy(address _proxy) external view returns (bool);
    function claimTokens(address token,address who,address dest,uint256 amount) external;
}

/**
 * @title WorldesApproveProxy
  *
 * @notice Allow different version worldesproxy to claim from WorldesApprove
 */
contract WorldesApproveProxy is InitializableOwnable {
    
    // ============ Storage ============
    uint256 private constant _TIMELOCK_DURATION_ = 3 days;
    mapping (address => bool) public _IS_ALLOWED_PROXY_;
    uint256 public _TIMELOCK_;
    address public _PENDING_ADD_WORLDES_PROXY_;
    address public immutable _WORLDES_APPROVE_;

    // ============ Modifiers ============
    modifier notLocked() {
        require(
            _TIMELOCK_ <= block.timestamp,
            "SetProxy is timelocked"
        );
        _;
    }

    constructor(address worldesApprove) public {
        _WORLDES_APPROVE_ = worldesApprove;
    }

    function init(address owner, address[] memory proxies) external {
        initOwner(owner);
        for(uint i = 0; i < proxies.length; i++) 
            _IS_ALLOWED_PROXY_[proxies[i]] = true;
    }

    function unlockAddProxy(address newSwapProxy) public onlyOwner {
        _TIMELOCK_ = block.timestamp + _TIMELOCK_DURATION_;
        _PENDING_ADD_WORLDES_PROXY_ = newSwapProxy;
    }

    function lockAddProxy() public onlyOwner {
       _PENDING_ADD_WORLDES_PROXY_ = address(0);
       _TIMELOCK_ = 0;
    }


    function addWorldesProxy() external onlyOwner notLocked() {
        _IS_ALLOWED_PROXY_[_PENDING_ADD_WORLDES_PROXY_] = true;
        lockAddProxy();
    }

    function removeWorldesProxy (address oldSwapProxy) public onlyOwner {
        _IS_ALLOWED_PROXY_[oldSwapProxy] = false;
    }

    function setTimeLockEmergency (uint256 timeLock) public onlyOwner {
        _TIMELOCK_ = timeLock;
    }
    
    function claimTokens(
        address token,
        address who,
        address dest,
        uint256 amount
    ) external {
        require(_IS_ALLOWED_PROXY_[msg.sender], "WorldesApproveProxy:Access restricted");
        IWorldesApprove(_WORLDES_APPROVE_).claimTokens(
            token,
            who,
            dest,
            amount
        );
    }

    function isAllowedProxy(address _proxy) external view returns (bool) {
        return _IS_ALLOWED_PROXY_[_proxy];
    }
}
