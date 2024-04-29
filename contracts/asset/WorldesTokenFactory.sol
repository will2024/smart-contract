// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.10;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {WorldesToken} from "./WorldesToken.sol";

contract WorldesTokenFactory is Ownable {

    address public _WORLDES_RWA_;
    //rwa_rwaId => erc20_Address
    mapping(uint256 => address) public _RWA_TO_TOKEN_ADDRESS_;
    //erc20_Address => rwa_rwaId
    mapping(address => uint256) public _TOKEN_ADDRESS_TO_RWA_;

    error ErrCallerIsNotNftOwner(address caller, address owner);
    error ErrTokenIsDeployed(uint256 rwaId, address tokenAddress);

    event TokenDeployed(
        uint256 rwaId, 
        address tokenAddress, 
        string name, 
        string symbol, 
        uint256 intialSupply,
        uint8 decimals
    );
    
    constructor(
        address owner, 
        address rwaAddress
    ) {
        _transferOwnership(owner);
        _WORLDES_RWA_ = rwaAddress;
    }

    function deployWorldesToken(
        uint256 rwaId,
        address owner,
        address listAdmin,
        address to,
        uint256 intialSupply,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external {
        address ownerOfRwa = IERC721(_WORLDES_RWA_).ownerOf(rwaId);

        if (msg.sender != ownerOfRwa) {
            revert ErrCallerIsNotNftOwner(msg.sender, ownerOfRwa);
        }

        if (_RWA_TO_TOKEN_ADDRESS_[rwaId] != address(0)) {
            revert ErrTokenIsDeployed(rwaId, _RWA_TO_TOKEN_ADDRESS_[rwaId]);
        }

        WorldesToken token = new WorldesToken(owner, listAdmin, to, name, symbol, intialSupply, decimals);

        _RWA_TO_TOKEN_ADDRESS_[rwaId] = address(token);
        _TOKEN_ADDRESS_TO_RWA_[address(token)] = rwaId;
        
        emit TokenDeployed(rwaId, address(token), name, symbol, intialSupply, decimals);
    }
}
