/*
 
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;

interface IWorldesApprove {
    function claimTokens(address token,address who,address dest,uint256 amount) external;
    function getWorldesProxy() external view returns (address);
}
