// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.10;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IWorldesPropertyRights {
    
    function beforeDeployRWAToken(uint256 tokenId, address from) external;

    function afterDeployRWAToken(uint256 tokenId, address token) external;
}

interface ICloneFactory {
    function clone(address prototype) external returns (address proxy);
}

interface IWorldesRWAToken {

    function initialize(
        address propertyRights,
        address owner,
        address listAdmin,
        address to,
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        uint8 intitialDecimals
    ) external;
}

contract WorldesRWATokenFactory is Ownable {
    event TokenDeployed(
        address propertyRights,
        uint256 indexed rwaId, 
        address indexed tokenAddress,
        address indexed to,
        address sender,
        string name, 
        string symbol, 
        uint256 intialSupply,
        uint8 decimals
    );

    address public immutable _CLONE_FACTORY_;
    address public _RWA_TOKEN_TEMPLATE_;
    
    constructor(
        address owner,
        address cloneFactory,
        address rwaTokenTemplate
    ) {
        _CLONE_FACTORY_ = cloneFactory;
        _RWA_TOKEN_TEMPLATE_ = rwaTokenTemplate;
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

        // WorldesRWAToken token = new WorldesRWAToken(propertyRights, owner, listAdmin, to, name, symbol, intialSupply, decimals);
        address token = ICloneFactory(_CLONE_FACTORY_).clone(_RWA_TOKEN_TEMPLATE_);
        {
            IWorldesRWAToken(token).initialize(propertyRights, owner, listAdmin, to, name, symbol, intialSupply, decimals);
        }

        IWorldesPropertyRights(propertyRights).afterDeployRWAToken(nftId, token);
        
        emit TokenDeployed(
            propertyRights, 
            nftId, 
            address(token), 
            to, 
            msg.sender, 
            name, 
            symbol, 
            intialSupply, 
            decimals
        );
    }
}
