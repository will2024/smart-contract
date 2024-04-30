// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.10;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {WorldesRWAToken} from "./WorldesRWAToken.sol";

interface IWorldesPropertyRights {
    
    function beforeDeployRWAToken(uint256 tokenId, address from) external view;

    function afterDeployRWAToken(uint256 tokenId, WorldesRWAToken token) external;
}

contract WorldesTokenFactory is Ownable {
    event TokenDeployed(
        address indexed propertyRights,
        uint256 indexed rwaId, 
        address indexed tokenAddress, 
        string name, 
        string symbol, 
        uint256 intialSupply,
        uint8 decimals
    );
    
    constructor(
        address owner
    ) {
        _transferOwnership(owner);
    }

    function deployWorldesRWAToken(
        address propertyRights,
        uint256 nftId,
        address owner,
        address listAdmin,
        address to,
        uint256 intialSupply,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external {

        IWorldesPropertyRights(propertyRights).beforeDeployRWAToken(nftId, msg.sender);

        WorldesRWAToken token = new WorldesRWAToken(owner, listAdmin, to, name, symbol, intialSupply, decimals);

        IWorldesPropertyRights(propertyRights).afterDeployRWAToken(nftId, token);
        
        emit TokenDeployed(propertyRights, nftId, address(token), name, symbol, intialSupply, decimals);
    }
}
