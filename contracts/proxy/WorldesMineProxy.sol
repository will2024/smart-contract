/*

    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

import {InitializableOwnable} from "../libraries/InitializableOwnable.sol";
import {IWorldesApproveProxy} from "./WorldesApproveProxy.sol";
import {IRewardVault} from "../mining/RewardVault.sol";
import {IWorldesMineRegistry} from "../mining/WorldesMineRegistry.sol";
import {ICloneFactory} from "../libraries/CloneFactory.sol";
import {SafeMath} from "../libraries/SafeMath.sol";

interface IMine {
    function init(address owner, address token) external;

    function addRewardToken(
        address rewardToken,
        uint256 rewardPerBlock,
        uint256 startBlock,
        uint256 endBlock
    ) external;

    function directTransferOwnership(address newOwner) external;

    function getVaultByRewardToken(address rewardToken) external view returns(address);
}

/**
 * @title WorldesMine Proxy
 *
 * @notice Create And Register WorldesMine Contracts 
 */
contract WorldesMineProxy is InitializableOwnable {
    using SafeMath for uint256;
    // ============ Templates ============

    address public immutable _CLONE_FACTORY_;
    address public immutable _WORLDES_APPROVE_PROXY_;
    address public immutable _WORLDES_MINE_REGISTRY_;
    address public _MINE_TEMPLATE_;


    // ============ Events ============
    event DepositRewardToVault(address mine, address rewardToken, uint256 amount);
    event DepositRewardToMine(address mine, address rewardToken, uint256 amount);
    event CreateMine(address account, address mine, uint256 platform);
    event ChangeMineTemplate(address mine);

    constructor(
        address cloneFactory,
        address mineTemplate,
        address worldesApproveProxy,
        address worldesMineRegistry
    ) public {
        _CLONE_FACTORY_ = cloneFactory;
        _MINE_TEMPLATE_ = mineTemplate;
        _WORLDES_APPROVE_PROXY_ = worldesApproveProxy;
        _WORLDES_MINE_REGISTRY_ = worldesMineRegistry;
    }

    // ============ Functions ============

    function createWorldesMine(
        address stakeToken,
        bool isLpToken,
        uint256 platform,
        address[] memory rewardTokens,
        uint256[] memory rewardPerBlock,
        uint256[] memory startBlock,
        uint256[] memory endBlock
    ) external returns (address newMine) {
        // require(rewardTokens.length > 0, "REWARD_EMPTY");
        require(rewardTokens.length == rewardPerBlock.length, "REWARD_PARAM_NOT_MATCH");
        require(startBlock.length == rewardPerBlock.length, "REWARD_PARAM_NOT_MATCH");
        require(endBlock.length == rewardPerBlock.length, "REWARD_PARAM_NOT_MATCH");

        newMine = ICloneFactory(_CLONE_FACTORY_).clone(_MINE_TEMPLATE_);

        IMine(newMine).init(address(this), stakeToken);

        for(uint i = 0; i<rewardTokens.length; i++) {
            uint256 rewardAmount = rewardPerBlock[i].mul(endBlock[i].sub(startBlock[i]));
            IWorldesApproveProxy(_WORLDES_APPROVE_PROXY_).claimTokens(rewardTokens[i], msg.sender, newMine, rewardAmount);
            IMine(newMine).addRewardToken(
                rewardTokens[i],
                rewardPerBlock[i],
                startBlock[i],
                endBlock[i]
            );
        }

        IMine(newMine).directTransferOwnership(msg.sender);

        IWorldesMineRegistry(_WORLDES_MINE_REGISTRY_).addMine(newMine, isLpToken, stakeToken);

        emit CreateMine(msg.sender, newMine, platform);
    }

    function depositRewardToVault(
        address mine,
        address rewardToken,
        uint256 amount
    ) external {    
        address rewardVault = IMine(mine).getVaultByRewardToken(rewardToken);
        IWorldesApproveProxy(_WORLDES_APPROVE_PROXY_).claimTokens(rewardToken, msg.sender, rewardVault, amount);
        IRewardVault(rewardVault).syncValue();

        emit DepositRewardToVault(mine,rewardToken,amount);
    }

    function depositRewardToMine(
        address mine,
        address rewardToken,
        uint256 amount
    ) external {
        require(mine != address(0), "MINE_EMPTY");
        IWorldesApproveProxy(_WORLDES_APPROVE_PROXY_).claimTokens(rewardToken, msg.sender, mine, amount);

        emit DepositRewardToMine(mine,rewardToken,amount);
    }

    // ============ Admin Operation Functions ============
    
    function updateMineTemplate(address _newMineTemplate) external onlyOwner {
        _MINE_TEMPLATE_ = _newMineTemplate;
        emit ChangeMineTemplate(_newMineTemplate);
    }

    function version() virtual external pure returns (string memory) {
        return "MineProxy 0.0.1";
    }
}
