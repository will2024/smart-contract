// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WorldRealAssetToken is ERC20 {
    constructor() ERC20("World real asset token", "WRA") {
        _mint(msg.sender, 100000000 * 10 ** 18);
    }
}
