/*
    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

import {InitializableOwnable} from "../libraries/InitializableOwnable.sol";

interface IWorldesMineRegistry {
    function addMine(
        address mine,
        bool isLpToken,
        address stakeToken,
        uint256 lockDuration
    ) external;
}

/**
 * @title WorldesMine Registry
 *
 * @notice Register WorldesMine Pools 
 */
contract WorldesMineRegistry is InitializableOwnable, IWorldesMineRegistry {

    mapping (address => bool) public isAdminListed;
    
    // ============ Registry ============
    // minePool -> stakeToken
    mapping(address => PoolInfo) public _MINE_REGISTRY_;
    // lpToken -> minePool
    mapping(address => address[]) public _LP_REGISTRY_;
    // singleToken -> minePool
    mapping(address => address[]) public _SINGLE_REGISTRY_;

    struct PoolInfo {
        address mine;
        address stakeToken;
        uint256 lockTime;
    }

    // ============ Events ============
    event NewMine(address mine, address stakeToken, bool isLpToken, uint256 lockDuration);
    event RemoveMine(address mine, address stakeToken);
    event addAdmin(address admin);
    event removeAdmin(address admin);


    function addMine(
        address mine,
        bool isLpToken,
        address stakeToken,
        uint256 lockDuration
    ) override external {
        require(isAdminListed[msg.sender], "ACCESS_DENIED");
        _MINE_REGISTRY_[mine] = PoolInfo({
            mine: mine,
            stakeToken: stakeToken,
            lockTime: lockDuration
        });

        if(isLpToken) {
            _LP_REGISTRY_[stakeToken].push(mine);
        }else {
            _SINGLE_REGISTRY_[stakeToken].push(mine);
        }

        emit NewMine(mine, stakeToken, isLpToken, lockDuration);
    }

    // ============ Admin Operation Functions ============

    function removeMine(
        address mine,
        bool isLpToken,
        address stakeToken
    ) external onlyOwner {
        _MINE_REGISTRY_[mine] = PoolInfo({
            mine: address(0),
            stakeToken: address(0),
            lockTime: 0
        });
        if(isLpToken) {
            uint256 len = _LP_REGISTRY_[stakeToken].length;
            for (uint256 i = 0; i < len; i++) {
                if (mine == _LP_REGISTRY_[stakeToken][i]) {
                    if(i != len - 1) {
                        _LP_REGISTRY_[stakeToken][i] = _LP_REGISTRY_[stakeToken][len - 1];
                    }
                    _LP_REGISTRY_[stakeToken].pop();
                    break;
                }
            }
        }else {
            uint256 len = _SINGLE_REGISTRY_[stakeToken].length;
            for (uint256 i = 0; i < len; i++) {
                if (mine == _SINGLE_REGISTRY_[stakeToken][i]) {
                    if(i != len - 1) {
                        _SINGLE_REGISTRY_[stakeToken][i] = _SINGLE_REGISTRY_[stakeToken][len - 1];
                    }
                    _SINGLE_REGISTRY_[stakeToken].pop();
                    break;
                }
            }
        }

        emit RemoveMine(mine, stakeToken);
    }

    function addAdminList (address contractAddr) external onlyOwner {
        isAdminListed[contractAddr] = true;
        emit addAdmin(contractAddr);
    }

    function removeAdminList (address contractAddr) external onlyOwner {
        isAdminListed[contractAddr] = false;
        emit removeAdmin(contractAddr);
    }
}