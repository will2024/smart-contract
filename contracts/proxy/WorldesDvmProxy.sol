/*
 
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;

import {IWorldesDvmProxy} from "../interfaces/IWorldesDvmProxy.sol";
import {IWorldes} from "../interfaces/IWorldes.sol";
import {IWorldesApproveProxy} from "./WorldesApproveProxy.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import {SafeMath} from "../libraries/SafeMath.sol";
import {UniversalERC20} from "../libraries/UniversalERC20.sol";
import {SafeERC20} from "../libraries/SafeERC20.sol";
import {DecimalMath} from "../libraries/DecimalMath.sol";
import {ReentrancyGuard} from "../libraries/ReentrancyGuard.sol";
import {InitializableOwnable} from "../libraries/InitializableOwnable.sol";

/**
 * @title WorldesDvmProxy
 *
 * @notice Entrance of trading in Worldes platform
 */
contract WorldesDvmProxy is IWorldesDvmProxy, ReentrancyGuard, InitializableOwnable {
    using SafeMath for uint256;
    using UniversalERC20 for IERC20;

    // ============ Storage ============

    address constant _ETH_ADDRESS_ = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public immutable _WETH_;
    address public immutable _WORLDES_APPROVE_PROXY_;
    address public immutable _DVM_FACTORY_;
    mapping (address => bool) public isWhiteListed;

    // ============ Events ============

    event OrderHistory(
        address fromToken,
        address toToken,
        address sender,
        uint256 fromAmount,
        uint256 returnAmount
    );

    // ============ Modifiers ============

    modifier judgeExpired(uint256 deadLine) {
        require(deadLine >= block.timestamp, "WorldesDvmProxy: EXPIRED");
        _;
    }

    fallback() external payable {}

    receive() external payable {}

    constructor(
        address dvmFactory,
        address payable weth,
        address worldesApproveProxy
    ) public {
        _DVM_FACTORY_ = dvmFactory;
        _WETH_ = weth;
        _WORLDES_APPROVE_PROXY_ = worldesApproveProxy;
    }

    function addWhiteList (address contractAddr) public onlyOwner {
        isWhiteListed[contractAddr] = true;
    }

    function removeWhiteList (address contractAddr) public onlyOwner {
        isWhiteListed[contractAddr] = false;
    }

    // ============ DVM Functions (create & add liquidity) ============

    function createVendingMachine(
        address baseToken,
        address quoteToken,
        uint256 baseInAmount,
        uint256 quoteInAmount,
        uint256 lpFeeRate,
        uint256 i,
        uint256 k,
        bool isOpenTWAP,
        uint256 deadLine
    )
        external
        override
        payable
        preventReentrant
        judgeExpired(deadLine)
        returns (address newVendingMachine, uint256 shares)
    {
        {
            address _baseToken = baseToken == _ETH_ADDRESS_ ? _WETH_ : baseToken;
            address _quoteToken = quoteToken == _ETH_ADDRESS_ ? _WETH_ : quoteToken;
            newVendingMachine = IWorldes(_DVM_FACTORY_).createVendingMachine(
                _baseToken,
                _quoteToken,
                lpFeeRate,
                i,
                k,
                isOpenTWAP
            );
        }

        {
            address _baseToken = baseToken;
            address _quoteToken = quoteToken;
            _deposit(
                msg.sender,
                newVendingMachine,
                _baseToken,
                baseInAmount,
                _baseToken == _ETH_ADDRESS_
            );
            _deposit(
                msg.sender,
                newVendingMachine,
                _quoteToken,
                quoteInAmount,
                _quoteToken == _ETH_ADDRESS_
            );
        }

        (shares, , ) = IWorldes(newVendingMachine).buyShares(msg.sender);
    }

    function addDVMLiquidity(
        address dvmAddress,
        uint256 baseInAmount,
        uint256 quoteInAmount,
        uint256 baseMinAmount,
        uint256 quoteMinAmount,
        uint8 flag, // 0 - ERC20, 1 - baseInETH, 2 - quoteInETH
        uint256 deadLine
    )
        external
        override
        payable
        preventReentrant
        judgeExpired(deadLine)
        returns (
            uint256 shares,
            uint256 baseAdjustedInAmount,
            uint256 quoteAdjustedInAmount
        )
    {
        address _dvm = dvmAddress;
        (baseAdjustedInAmount, quoteAdjustedInAmount) = _addDVMLiquidity(
            _dvm,
            baseInAmount,
            quoteInAmount
        );
        require(
            baseAdjustedInAmount >= baseMinAmount && quoteAdjustedInAmount >= quoteMinAmount,
            "WorldesDvmProxy: deposit amount is not enough"
        );

        _deposit(msg.sender, _dvm, IWorldes(_dvm)._BASE_TOKEN_(), baseAdjustedInAmount, flag == 1);
        _deposit(msg.sender, _dvm, IWorldes(_dvm)._QUOTE_TOKEN_(), quoteAdjustedInAmount, flag == 2);
        
        (shares, , ) = IWorldes(_dvm).buyShares(msg.sender);
        // refund dust eth
        if (flag == 1 && msg.value > baseAdjustedInAmount) msg.sender.transfer(msg.value - baseAdjustedInAmount);
        if (flag == 2 && msg.value > quoteAdjustedInAmount) msg.sender.transfer(msg.value - quoteAdjustedInAmount);
    }

    function _addDVMLiquidity(
        address dvmAddress,
        uint256 baseInAmount,
        uint256 quoteInAmount
    ) internal view returns (uint256 baseAdjustedInAmount, uint256 quoteAdjustedInAmount) {
        (uint256 baseReserve, uint256 quoteReserve) = IWorldes(dvmAddress).getVaultReserve();
        if (quoteReserve == 0 && baseReserve == 0) {
            baseAdjustedInAmount = baseInAmount;
            quoteAdjustedInAmount = quoteInAmount;
        }
        if (quoteReserve == 0 && baseReserve > 0) {
            baseAdjustedInAmount = baseInAmount;
            quoteAdjustedInAmount = 0;
        }
        if (quoteReserve > 0 && baseReserve > 0) {
            uint256 baseIncreaseRatio = DecimalMath.divFloor(baseInAmount, baseReserve);
            uint256 quoteIncreaseRatio = DecimalMath.divFloor(quoteInAmount, quoteReserve);
            if (baseIncreaseRatio <= quoteIncreaseRatio) {
                baseAdjustedInAmount = baseInAmount;
                quoteAdjustedInAmount = DecimalMath.mulFloor(quoteReserve, baseIncreaseRatio);
            } else {
                quoteAdjustedInAmount = quoteInAmount;
                baseAdjustedInAmount = DecimalMath.mulFloor(baseReserve, quoteIncreaseRatio);
            }
        }
    }

    // ============ Swap ============

    function worldesSwapETHToToken(
        address toToken,
        uint256 minReturnAmount,
        address[] memory worldesPairs,
        uint256 directions,
        uint256 deadLine
    )
        external
        override
        payable
        judgeExpired(deadLine)
        returns (uint256 returnAmount)
    {
        require(worldesPairs.length > 0, "WorldesDvmProxy: PAIRS_EMPTY");
        require(minReturnAmount > 0, "WorldesDvmProxy: RETURN_AMOUNT_ZERO");
        
        uint256 originToTokenBalance = IERC20(toToken).balanceOf(msg.sender);
        IWETH(_WETH_).deposit{value: msg.value}();
        SafeERC20.safeTransfer(IERC20(_WETH_), worldesPairs[0], msg.value);

        for (uint256 i = 0; i < worldesPairs.length; i++) {
            if (i == worldesPairs.length - 1) {
                if (directions & 1 == 0) {
                    IWorldes(worldesPairs[i]).sellBase(msg.sender);
                } else {
                    IWorldes(worldesPairs[i]).sellQuote(msg.sender);
                }
            } else {
                if (directions & 1 == 0) {
                    IWorldes(worldesPairs[i]).sellBase(worldesPairs[i + 1]);
                } else {
                    IWorldes(worldesPairs[i]).sellQuote(worldesPairs[i + 1]);
                }
            }
            directions = directions >> 1;
        }

        returnAmount = IERC20(toToken).balanceOf(msg.sender).sub(originToTokenBalance);
        require(returnAmount >= minReturnAmount, "WorldesDvmProxy: Return amount is not enough");

        emit OrderHistory(
            _ETH_ADDRESS_,
            toToken,
            msg.sender,
            msg.value,
            returnAmount
        );
    }

    function worldesSwapTokenToETH(
        address fromToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        address[] memory worldesPairs,
        uint256 directions,
        uint256 deadLine
    )
        external
        override
        judgeExpired(deadLine)
        returns (uint256 returnAmount)
    {
        require(worldesPairs.length > 0, "WorldesDvmProxy: PAIRS_EMPTY");
        require(minReturnAmount > 0, "WorldesDvmProxy: RETURN_AMOUNT_ZERO");
        
        IWorldesApproveProxy(_WORLDES_APPROVE_PROXY_).claimTokens(fromToken, msg.sender, worldesPairs[0], fromTokenAmount);

        for (uint256 i = 0; i < worldesPairs.length; i++) {
            if (i == worldesPairs.length - 1) {
                if (directions & 1 == 0) {
                    IWorldes(worldesPairs[i]).sellBase(address(this));
                } else {
                    IWorldes(worldesPairs[i]).sellQuote(address(this));
                }
            } else {
                if (directions & 1 == 0) {
                    IWorldes(worldesPairs[i]).sellBase(worldesPairs[i + 1]);
                } else {
                    IWorldes(worldesPairs[i]).sellQuote(worldesPairs[i + 1]);
                }
            }
            directions = directions >> 1;
        }
        returnAmount = IWETH(_WETH_).balanceOf(address(this));
        require(returnAmount >= minReturnAmount, "WorldesDvmProxy: Return amount is not enough");
        IWETH(_WETH_).withdraw(returnAmount);
        msg.sender.transfer(returnAmount);

        emit OrderHistory(
            fromToken,
            _ETH_ADDRESS_,
            msg.sender,
            fromTokenAmount,
            returnAmount
        );
    }

    function worldesSwapTokenToToken(
        address fromToken,
        address toToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        address[] memory worldesPairs,
        uint256 directions,
        uint256 deadLine
    )
        external
        override
        judgeExpired(deadLine)
        returns (uint256 returnAmount)
    {
        require(worldesPairs.length > 0, "WorldesDvmProxy: PAIRS_EMPTY");
        require(minReturnAmount > 0, "WorldesDvmProxy: RETURN_AMOUNT_ZERO");

        uint256 originToTokenBalance = IERC20(toToken).balanceOf(msg.sender);
        IWorldesApproveProxy(_WORLDES_APPROVE_PROXY_).claimTokens(fromToken, msg.sender, worldesPairs[0], fromTokenAmount);

        for (uint256 i = 0; i < worldesPairs.length; i++) {
            if (i == worldesPairs.length - 1) {
                if (directions & 1 == 0) {
                    IWorldes(worldesPairs[i]).sellBase(msg.sender);
                } else {
                    IWorldes(worldesPairs[i]).sellQuote(msg.sender);
                }
            } else {
                if (directions& 1 == 0) {
                    IWorldes(worldesPairs[i]).sellBase(worldesPairs[i + 1]);
                } else {
                    IWorldes(worldesPairs[i]).sellQuote(worldesPairs[i + 1]);
                }
            }
            directions = directions >> 1;
        }
        returnAmount = IERC20(toToken).balanceOf(msg.sender).sub(originToTokenBalance);
        require(returnAmount >= minReturnAmount, "WorldesDvmProxy: Return amount is not enough");

        emit OrderHistory(
            fromToken,
            toToken,
            msg.sender,
            fromTokenAmount,
            returnAmount
        );
    }

    function externalSwap(
        address fromToken,
        address toToken,
        address approveTarget,
        address swapTarget,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        bytes memory callDataConcat,
        uint256 deadLine
    )
        external
        override
        payable
        judgeExpired(deadLine)
        returns (uint256 returnAmount)
    {
        require(minReturnAmount > 0, "WorldesDvmProxy: RETURN_AMOUNT_ZERO");
        
        uint256 toTokenOriginBalance = IERC20(toToken).universalBalanceOf(msg.sender);
        if (fromToken != _ETH_ADDRESS_) {
            IWorldesApproveProxy(_WORLDES_APPROVE_PROXY_).claimTokens(
                fromToken,
                msg.sender,
                address(this),
                fromTokenAmount
            );
            IERC20(fromToken).universalApproveMax(approveTarget, fromTokenAmount);
        }

        require(isWhiteListed[swapTarget], "WorldesDvmProxy: Not Whitelist Contract");
        (bool success, ) = swapTarget.call{value: fromToken == _ETH_ADDRESS_ ? msg.value : 0}(callDataConcat);

        require(success, "WorldesDvmProxy: External Swap execution Failed");

        IERC20(toToken).universalTransfer(
            msg.sender,
            IERC20(toToken).universalBalanceOf(address(this))
        );

        returnAmount = IERC20(toToken).universalBalanceOf(msg.sender).sub(toTokenOriginBalance);
        require(returnAmount >= minReturnAmount, "WorldesDvmProxy: Return amount is not enough");

        emit OrderHistory(
            fromToken,
            toToken,
            msg.sender,
            fromTokenAmount,
            returnAmount
        );
    }
    

    function _deposit(
        address from,
        address to,
        address token,
        uint256 amount,
        bool isETH
    ) internal {
        if (isETH) {
            if (amount > 0) {
                require(msg.value == amount, "ETH_VALUE_WRONG");
                IWETH(_WETH_).deposit{value: amount}();
                if (to != address(this)) SafeERC20.safeTransfer(IERC20(_WETH_), to, amount);
            }
        } else {
            IWorldesApproveProxy(_WORLDES_APPROVE_PROXY_).claimTokens(token, from, to, amount);
        }
    }

    function _withdraw(
        address payable to,
        address token,
        uint256 amount,
        bool isETH
    ) internal {
        if (isETH) {
            if (amount > 0) {
                IWETH(_WETH_).withdraw(amount);
                to.transfer(amount);
            }
        } else {
            if (amount > 0) {
                SafeERC20.safeTransfer(IERC20(token), to, amount);
            }
        }
    }
}
