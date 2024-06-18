/*

    SPDX-License-Identifier: Apache-2.0

*/
pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

import {SafeERC20} from "../libraries/SafeERC20.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {SafeMath} from "../libraries/SafeMath.sol";
import {ReentrancyGuard} from "../libraries/ReentrancyGuard.sol";
import {BaseMine} from "./BaseMine.sol";

contract ERC20Mine is ReentrancyGuard, BaseMine {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // ============ Storage ============

    address public _TOKEN_;
    uint256 public _LOCK_DURATION_;
    uint256 public stakerInfoLength = 0;
    mapping(uint256 => StakeInfo) public stakerIds;
    mapping(uint256 => bool) public stakerWithdrawn;
    mapping(address => StakeInfo[]) public userStakeInfos;

    // ============ Constructor ============
    struct StakeInfo {
        address staker;
        uint256 stakeTime;
        uint256 stakeAmount;
    }

    function init(address owner, address token, uint256 lockDuration) external {
        super.initOwner(owner);
        _TOKEN_ = token;
        _LOCK_DURATION_ = lockDuration;
    }

    // ============ Event  ============

    event Deposit(address indexed user, uint256 stakeId, uint256 amount);
    event Withdraw(address indexed user, uint256 stakeId, uint256 amount);

    // ============ Deposit && Withdraw && Exit ============

    function deposit(uint256 amount) external preventReentrant {
        require(amount > 0, "WorldesMine: CANNOT_DEPOSIT_ZERO");

        _updateAllReward(msg.sender);

        uint256 erc20OriginBalance = IERC20(_TOKEN_).balanceOf(address(this));
        IERC20(_TOKEN_).safeTransferFrom(msg.sender, address(this), amount);
        uint256 actualStakeAmount = IERC20(_TOKEN_).balanceOf(address(this)).sub(erc20OriginBalance);
        
        _totalSupply = _totalSupply.add(actualStakeAmount);
        _balances[msg.sender] = _balances[msg.sender].add(actualStakeAmount);

        StakeInfo memory stakeInfo = StakeInfo({
            staker: msg.sender,
            stakeTime: block.timestamp,
            stakeAmount: actualStakeAmount
        });

        StakeInfo[] storage infos = userStakeInfos[msg.sender];
        infos.push(stakeInfo);
        userStakeInfos[msg.sender] = infos;

        stakerInfoLength = stakerInfoLength.add(1);

        stakerWithdrawn[stakerInfoLength] = false;
        stakerIds[stakerInfoLength] = stakeInfo;

        emit Deposit(msg.sender, stakerInfoLength, actualStakeAmount);
    }

    function withdraw(uint256 stakeId) external preventReentrant {
        StakeInfo memory stakeInfo = stakerIds[stakeId];
        require(stakeInfo.staker == msg.sender, "WorldesMine: NO_STAKER");
        require(stakeInfo.stakeTime + _LOCK_DURATION_ < block.timestamp, "WorldesMine: LOCK_TIME_NOT_PASSED");
        require(!stakerWithdrawn[stakeId], "WorldesMine: ALREADY_WITHDRAWN");

        _updateAllReward(msg.sender);
        _totalSupply = _totalSupply.sub(stakeInfo.stakeAmount);
        _balances[msg.sender] = _balances[msg.sender].sub(stakeInfo.stakeAmount);
        IERC20(_TOKEN_).safeTransfer(msg.sender, stakeInfo.stakeAmount);

        stakerWithdrawn[stakeId] = true;

        emit Withdraw(msg.sender, stakeId, stakeInfo.stakeAmount);
    }
}
