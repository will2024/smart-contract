/*
 
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;

import {IWorldesApproveProxy} from "./WorldesApproveProxy.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import {SafeMath} from "../libraries/SafeMath.sol";
import {SafeERC20} from "../libraries/SafeERC20.sol";
import {DecimalMath} from "../libraries/DecimalMath.sol";
import {ReentrancyGuard} from "../libraries/ReentrancyGuard.sol";
import {IDSP} from "../stablePool/interfaces/IDSP.sol";
import {IDSPFactory} from "../factory/DSPFactory.sol";

/**
 * @title WorldesDspProxy
 *
 * @notice Entrance of Worldes Stable Pair in Worldes platform
 */
contract WorldesDspProxy is ReentrancyGuard {
    using SafeMath for uint256;

    // ============ Storage ============

    address constant _ETH_ADDRESS_ = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public immutable _WETH_;
    address public immutable _WORLDES_APPROVE_PROXY_;
    address public immutable _DSP_FACTORY_;

    // ============ Modifiers ============

    modifier judgeExpired(uint256 deadLine) {
        require(deadLine >= block.timestamp, "WorldesDspProxy: EXPIRED");
        _;
    }

    fallback() external payable {}

    receive() external payable {}

    constructor(
        address dspFactory,
        address payable weth,
        address worldesApproveProxy
    ) public {
        _DSP_FACTORY_ = dspFactory;
        _WETH_ = weth;
        _WORLDES_APPROVE_PROXY_ = worldesApproveProxy;
    }

    // ============ DSP Functions (create & add liquidity) ============

    function createStablePair(
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
        payable
        preventReentrant
        judgeExpired(deadLine)
        returns (address newStablePair, uint256 shares)
    {
        {
            address _baseToken = baseToken == _ETH_ADDRESS_ ? _WETH_ : baseToken;
            address _quoteToken = quoteToken == _ETH_ADDRESS_ ? _WETH_ : quoteToken;
            newStablePair = IDSPFactory(_DSP_FACTORY_).createStablePool(
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
                newStablePair,
                _baseToken,
                baseInAmount,
                _baseToken == _ETH_ADDRESS_
            );
            _deposit(
                msg.sender,
                newStablePair,
                _quoteToken,
                quoteInAmount,
                _quoteToken == _ETH_ADDRESS_
            );
        }

        (shares, , ) = IDSP(newStablePair).buyShares(msg.sender);
    }

    function addDSPLiquidity(
        address dspAddress,
        uint256 baseInAmount,
        uint256 quoteInAmount,
        uint256 baseMinAmount,
        uint256 quoteMinAmount,
        uint8 flag, // 0 - ERC20, 1 - baseInETH, 2 - quoteInETH
        uint256 deadLine
    )
        external
        payable
        preventReentrant
        judgeExpired(deadLine)
        returns (
            uint256 shares,
            uint256 baseAdjustedInAmount,
            uint256 quoteAdjustedInAmount
        )
    {
        address _dsp = dspAddress;
        (baseAdjustedInAmount, quoteAdjustedInAmount) = _addDSPLiquidity(
            _dsp,
            baseInAmount,
            quoteInAmount
        );
        require(
            baseAdjustedInAmount >= baseMinAmount && quoteAdjustedInAmount >= quoteMinAmount,
            "WorldesDspProxy: deposit amount is not enough"
        );

        _deposit(msg.sender, _dsp, IDSP(_dsp)._BASE_TOKEN_(), baseAdjustedInAmount, flag == 1);
        _deposit(msg.sender, _dsp, IDSP(_dsp)._QUOTE_TOKEN_(), quoteAdjustedInAmount, flag == 2);
        
        (shares, , ) = IDSP(_dsp).buyShares(msg.sender);

        // refund dust eth
        if (flag == 1 && msg.value > baseAdjustedInAmount) msg.sender.transfer(msg.value - baseAdjustedInAmount);
        if (flag == 2 && msg.value > quoteAdjustedInAmount) msg.sender.transfer(msg.value - quoteAdjustedInAmount);
    }


    // =================== internal functions =====================

    function _addDSPLiquidity(
        address dspAddress,
        uint256 baseInAmount,
        uint256 quoteInAmount
    ) internal view returns (uint256 baseAdjustedInAmount, uint256 quoteAdjustedInAmount) {
        (uint256 baseReserve, uint256 quoteReserve) = IDSP(dspAddress).getVaultReserve();
        if (quoteReserve == 0 && baseReserve == 0) {
            uint256 i = IDSP(dspAddress)._I_();
            uint256 shares = quoteInAmount < DecimalMath.mulFloor(baseInAmount, i)
                ? DecimalMath.divFloor(quoteInAmount, i)
                : baseInAmount;
            baseAdjustedInAmount = shares;
            quoteAdjustedInAmount = DecimalMath.mulFloor(shares, i);
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

    function _deposit(
        address from,
        address to,
        address token,
        uint256 amount,
        bool isETH
    ) internal {
        if (isETH) {
            if (amount > 0) {
                IWETH(_WETH_).deposit{value: amount}();
                if (to != address(this)) SafeERC20.safeTransfer(IERC20(_WETH_), to, amount);
            }
        } else {
            IWorldesApproveProxy(_WORLDES_APPROVE_PROXY_).claimTokens(token, from, to, amount);
        }
    }
}
