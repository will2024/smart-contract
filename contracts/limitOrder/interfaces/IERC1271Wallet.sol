/*

    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.8;

interface IERC1271Wallet {
    function isValidSignature(bytes32 hash, bytes calldata signature) external view returns (bytes4 magicValue);
}