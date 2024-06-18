/*

    SPDX-License-Identifier: Apache-2.0

*/
pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

import {SafeERC20} from "../libraries/SafeERC20.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {SafeMath} from "../libraries/SafeMath.sol";
import {DecimalMath} from "../libraries/DecimalMath.sol";
import {InitializableOwnable} from "../libraries/InitializableOwnable.sol";
import {IRewardVault, RewardVault} from "./RewardVault.sol";

contract BaseMine is InitializableOwnable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // ============ Storage ============

    struct RewardTokenInfo {
        address rewardToken;
        uint256 startTime;
        uint256 endTime;
        address rewardVault;
        uint256 rewardPerSecond;
        uint256 accRewardPerShare;
        uint256 lastRewardTime;
        uint256 workThroughReward;
        uint256 lastFlagTime;
        mapping(address => uint256) userRewardPerSharePaid;
        mapping(address => uint256) userRewards;
    }

    RewardTokenInfo[] public rewardTokenInfos;

    uint256 internal _totalSupply;
    mapping(address => uint256) internal _balances;

    // ============ Event =============

    event Claim(uint256 indexed i, address indexed user, uint256 reward);
    event UpdateReward(uint256 indexed i, uint256 rewardPerSecond);
    event UpdateEndTime(uint256 indexed i, uint256 endTime);
    event NewRewardToken(uint256 indexed i, address rewardToken);
    event RemoveRewardToken(address rewardToken);
    event WithdrawLeftOver(address owner, uint256 i);

    // ============ View  ============

    function getPendingReward(address user, uint256 i) public view returns (uint256) {
        require(i<rewardTokenInfos.length, "WorldesMine: REWARD_ID_NOT_FOUND");
        RewardTokenInfo storage rt = rewardTokenInfos[i];
        uint256 accRewardPerShare = rt.accRewardPerShare;
        if (rt.lastRewardTime != block.timestamp) {
            accRewardPerShare = _getAccRewardPerShare(i);
        }
        return
            DecimalMath.mulFloor(
                balanceOf(user), 
                accRewardPerShare.sub(rt.userRewardPerSharePaid[user])
            ).add(rt.userRewards[user]);
    }

    function getPendingRewardByToken(address user, address rewardToken) external view returns (uint256) {
        return getPendingReward(user, getIdByRewardToken(rewardToken));
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address user) public view returns (uint256) {
        return _balances[user];
    }

    function getRewardTokenById(uint256 i) external view returns (address) {
        require(i<rewardTokenInfos.length, "WorldesMine: REWARD_ID_NOT_FOUND");
        RewardTokenInfo memory rt = rewardTokenInfos[i];
        return rt.rewardToken;
    }

    function getIdByRewardToken(address rewardToken) public view returns(uint256) {
        uint256 len = rewardTokenInfos.length;
        for (uint256 i = 0; i < len; i++) {
            if (rewardToken == rewardTokenInfos[i].rewardToken) {
                return i;
            }
        }
        require(false, "WorldesMine: TOKEN_NOT_FOUND");
    }

    function getRewardNum() external view returns(uint256) {
        return rewardTokenInfos.length;
    }

    function getVaultByRewardToken(address rewardToken) public view returns(address) {
        uint256 len = rewardTokenInfos.length;
        for (uint256 i = 0; i < len; i++) {
            if (rewardToken == rewardTokenInfos[i].rewardToken) {
                return rewardTokenInfos[i].rewardVault;
            }
        }
        require(false, "WorldesMine: TOKEN_NOT_FOUND");
    }

    function getVaultDebtByRewardToken(address rewardToken) public view returns(uint256) {
        uint256 len = rewardTokenInfos.length;
        for (uint256 i = 0; i < len; i++) {
            if (rewardToken == rewardTokenInfos[i].rewardToken) {
                uint256 totalDepositReward = IRewardVault(rewardTokenInfos[i].rewardVault)._TOTAL_REWARD_();
                uint256 gap = rewardTokenInfos[i].endTime.sub(rewardTokenInfos[i].lastFlagTime);
                uint256 totalReward = rewardTokenInfos[i].workThroughReward.add(gap.mul(rewardTokenInfos[i].rewardPerSecond));
                if(totalDepositReward >= totalReward) {
                    return 0;
                }else {
                    return totalReward.sub(totalDepositReward);
                }
            }
        }
        require(false, "WorldesMine: TOKEN_NOT_FOUND");
    }

    // ============ Claim ============

    function claimReward(uint256 i) public {
        require(i<rewardTokenInfos.length, "WorldesMine: REWARD_ID_NOT_FOUND");
        _updateReward(msg.sender, i);
        RewardTokenInfo storage rt = rewardTokenInfos[i];
        uint256 reward = rt.userRewards[msg.sender];
        if (reward > 0) {
            rt.userRewards[msg.sender] = 0;
            IRewardVault(rt.rewardVault).reward(msg.sender, reward);
            emit Claim(i, msg.sender, reward);
        }
    }

    function claimAllRewards() external {
        uint256 len = rewardTokenInfos.length;
        for (uint256 i = 0; i < len; i++) {
            claimReward(i);
        }
    }

    // =============== Ownable  ================

    function addRewardToken(
        address rewardToken,
        uint256 rewardPerSecond,
        uint256 startTime,
        uint256 endTime
    ) external onlyOwner {
        require(rewardToken != address(0), "WorldesMine: TOKEN_INVALID");
        require(startTime > block.timestamp, "WorldesMine: START_BLOCK_INVALID");
        require(endTime > startTime, "WorldesMine: DURATION_INVALID");

        uint256 len = rewardTokenInfos.length;
        for (uint256 i = 0; i < len; i++) {
            require(
                rewardToken != rewardTokenInfos[i].rewardToken,
                "WorldesMine: TOKEN_ALREADY_ADDED"
            );
        }

        RewardTokenInfo storage rt = rewardTokenInfos.push();
        rt.rewardToken = rewardToken;
        rt.startTime = startTime;
        rt.lastFlagTime = startTime;
        rt.endTime = endTime;
        rt.rewardPerSecond = rewardPerSecond;
        rt.rewardVault = address(new RewardVault(rewardToken));

        uint256 rewardAmount = rewardPerSecond.mul(endTime.sub(startTime));
        IERC20(rewardToken).safeTransfer(rt.rewardVault, rewardAmount);
        RewardVault(rt.rewardVault).syncValue();

        emit NewRewardToken(len, rewardToken);
    }

    function setEndTime(uint256 i, uint256 newEndTime)
        external
        onlyOwner
    {
        require(i < rewardTokenInfos.length, "WorldesMine: REWARD_ID_NOT_FOUND");
        _updateReward(address(0), i);
        RewardTokenInfo storage rt = rewardTokenInfos[i];


        uint256 totalDepositReward = RewardVault(rt.rewardVault)._TOTAL_REWARD_();
        uint256 gap = newEndTime.sub(rt.lastFlagTime);
        uint256 totalReward = rt.workThroughReward.add(gap.mul(rt.rewardPerSecond));
        require(totalDepositReward >= totalReward, "WorldesMine: REWARD_NOT_ENOUGH");

        require(block.timestamp < newEndTime, "WorldesMine: END_BLOCK_INVALID");
        require(block.timestamp > rt.startTime, "WorldesMine: NOT_START");
        require(block.timestamp < rt.endTime, "WorldesMine: ALREADY_CLOSE");

        rt.endTime = newEndTime;
        emit UpdateEndTime(i, newEndTime);
    }

    function setReward(uint256 i, uint256 newRewardPerSecond)
        external
        onlyOwner
    {
        require(i < rewardTokenInfos.length, "WorldesMine: REWARD_ID_NOT_FOUND");
        _updateReward(address(0), i);
        RewardTokenInfo storage rt = rewardTokenInfos[i];
        
        require(block.timestamp < rt.endTime, "WorldesMine: ALREADY_CLOSE");
        
        rt.workThroughReward = rt.workThroughReward.add((block.timestamp.sub(rt.lastFlagTime)).mul(rt.rewardPerSecond));
        rt.rewardPerSecond = newRewardPerSecond;
        rt.lastFlagTime = block.timestamp;

        uint256 totalDepositReward = RewardVault(rt.rewardVault)._TOTAL_REWARD_();
        uint256 gap = rt.endTime.sub(block.timestamp);
        uint256 totalReward = rt.workThroughReward.add(gap.mul(newRewardPerSecond));
        require(totalDepositReward >= totalReward, "WorldesMine: REWARD_NOT_ENOUGH");

        emit UpdateReward(i, newRewardPerSecond);
    }

    function withdrawLeftOver(uint256 i, uint256 amount) external onlyOwner {
        require(i < rewardTokenInfos.length, "WorldesMine: REWARD_ID_NOT_FOUND");
        
        RewardTokenInfo storage rt = rewardTokenInfos[i];
        require(block.timestamp > rt.endTime, "WorldesMine: MINING_NOT_FINISHED");
        
        uint256 gap = rt.endTime.sub(rt.lastFlagTime);
        uint256 totalReward = rt.workThroughReward.add(gap.mul(rt.rewardPerSecond));
        uint256 totalDepositReward = IRewardVault(rt.rewardVault)._TOTAL_REWARD_();
        require(amount <= totalDepositReward.sub(totalReward), "WorldesMine: NOT_ENOUGH");

        IRewardVault(rt.rewardVault).withdrawLeftOver(msg.sender,amount);

        emit WithdrawLeftOver(msg.sender, i);
    }


    function directTransferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "WorldesMine: ZERO_ADDRESS");
        emit OwnershipTransferred(_OWNER_, newOwner);
        _OWNER_ = newOwner;
    }

    // ============ Internal  ============

    function _updateReward(address user, uint256 i) internal {
        RewardTokenInfo storage rt = rewardTokenInfos[i];
        if (rt.lastRewardTime != block.timestamp){
            rt.accRewardPerShare = _getAccRewardPerShare(i);
            rt.lastRewardTime = block.timestamp;
        }
        if (user != address(0)) {
            rt.userRewards[user] = getPendingReward(user, i);
            rt.userRewardPerSharePaid[user] = rt.accRewardPerShare;
        }
    }

    function _updateAllReward(address user) internal {
        uint256 len = rewardTokenInfos.length;
        for (uint256 i = 0; i < len; i++) {
            _updateReward(user, i);
        }
    }

    function _getUnrewardTimeNum(uint256 i) internal view returns (uint256) {
        RewardTokenInfo memory rt = rewardTokenInfos[i];
        if (block.timestamp < rt.startTime || rt.lastRewardTime > rt.endTime) {
            return 0;
        }
        uint256 start = rt.lastRewardTime < rt.startTime ? rt.startTime : rt.lastRewardTime;
        uint256 end = rt.endTime < block.timestamp ? rt.endTime : block.timestamp;
        return end.sub(start);
    }

    function _getAccRewardPerShare(uint256 i) internal view returns (uint256) {
        RewardTokenInfo memory rt = rewardTokenInfos[i];
        if (totalSupply() == 0) {
            return rt.accRewardPerShare;
        }
        return
            rt.accRewardPerShare.add(
                DecimalMath.divFloor(_getUnrewardTimeNum(i).mul(rt.rewardPerSecond), totalSupply())
            );
    }

}
