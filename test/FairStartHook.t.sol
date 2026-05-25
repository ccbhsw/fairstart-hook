// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";

import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import {LiquidityAmounts} from "@uniswap/v4-core/test/utils/LiquidityAmounts.sol";
import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";
import {LPFeeLibrary} from "@uniswap/v4-core/src/libraries/LPFeeLibrary.sol";
import {SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {Actions} from "@uniswap/v4-periphery/src/libraries/Actions.sol";

import {EasyPosm} from "./utils/libraries/EasyPosm.sol";

import {FairStartHook} from "../src/FairStartHook.sol";
import {BaseTest} from "./utils/BaseTest.sol";

contract FairStartHookTest is BaseTest {
    using EasyPosm for IPositionManager;
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    using StateLibrary for IPoolManager;

    Currency currency0;
    Currency currency1;

    PoolKey poolKey;

    FairStartHook hook;
    PoolId poolId;

    uint256 tokenId;
    int24 tickLower;
    int24 tickUpper;

    address trader = address(0xBEEF);

    function setUp() public {
        deployArtifactsAndLabel();

        (currency0, currency1) = deployCurrencyPair();

        address flags = address(
            uint160(
                Hooks.AFTER_INITIALIZE_FLAG | Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG
                    | Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG
            ) ^ (0x4444 << 144)
        );
        bytes memory constructorArgs = abi.encode(poolManager);
        deployCodeTo("FairStartHook.sol:FairStartHook", constructorArgs, flags);
        hook = FairStartHook(flags);

        poolKey = PoolKey(currency0, currency1, LPFeeLibrary.DYNAMIC_FEE_FLAG, 60, IHooks(hook));
        poolId = poolKey.toId();
        poolManager.initialize(poolKey, Constants.SQRT_PRICE_1_1);

        tickLower = TickMath.minUsableTick(poolKey.tickSpacing);
        tickUpper = TickMath.maxUsableTick(poolKey.tickSpacing);

        uint128 liquidityAmount = 100e18;

        (uint256 amount0Expected, uint256 amount1Expected) = LiquidityAmounts.getAmountsForLiquidity(
            Constants.SQRT_PRICE_1_1,
            TickMath.getSqrtPriceAtTick(tickLower),
            TickMath.getSqrtPriceAtTick(tickUpper),
            liquidityAmount
        );

        (tokenId,) = positionManager.mint(
            poolKey,
            tickLower,
            tickUpper,
            liquidityAmount,
            amount0Expected + 1,
            amount1Expected + 1,
            address(this),
            block.timestamp,
            Constants.ZERO_BYTES
        );
    }

    function testLaunchRulesLockedAfterInitialize() public view {
        (uint64 launchTimestamp,, bool rulesLocked) = hook.poolState(poolId);
        assertTrue(rulesLocked);
        assertEq(launchTimestamp, block.timestamp);
        assertEq(hook.launchEndsAt(poolId), block.timestamp + hook.DEFAULT_LAUNCH_DURATION());
        assertEq(hook.liquidityUnlocksAt(poolId), block.timestamp + hook.DEFAULT_LIQUIDITY_LOCK_DURATION());
    }

    function testLaunchWindowFee() public view {
        (uint24 fee, FairStartHook.FeeReason reason) =
            hook.quoteFee(trader, poolKey, _swapParams(1 ether, true));

        assertEq(fee, hook.DEFAULT_LAUNCH_FEE());
        assertEq(uint256(reason), uint256(FairStartHook.FeeReason.LAUNCH_WINDOW));
    }

    function testBaseFeeAfterLaunchWindow() public {
        vm.warp(block.timestamp + hook.DEFAULT_LAUNCH_DURATION() + 1);

        (uint24 fee, FairStartHook.FeeReason reason) =
            hook.quoteFee(trader, poolKey, _swapParams(1 ether, true));

        assertEq(fee, hook.DEFAULT_BASE_FEE());
        assertEq(uint256(reason), uint256(FairStartHook.FeeReason.BASE));
    }

    function testLargeSwapFeeTakesPriority() public view {
        (uint24 fee, FairStartHook.FeeReason reason) =
            hook.quoteFee(trader, poolKey, _swapParams(hook.DEFAULT_LARGE_SWAP_THRESHOLD(), true));

        assertEq(fee, hook.DEFAULT_LARGE_SWAP_FEE());
        assertEq(uint256(reason), uint256(FairStartHook.FeeReason.LARGE_SWAP));
    }

    function testCooldownFeeAfterSameActorSwap() public {
        bytes memory hookData = abi.encode(trader);

        swapRouter.swapExactTokensForTokens({
            amountIn: 1 ether,
            amountOutMin: 0,
            zeroForOne: true,
            poolKey: poolKey,
            hookData: hookData,
            receiver: address(this),
            deadline: block.timestamp + 1
        });

        assertEq(hook.lastSwapAt(poolId, trader), block.timestamp);

        (uint24 fee, FairStartHook.FeeReason reason) =
            hook.quoteFee(trader, poolKey, _swapParams(1 ether, true));

        assertEq(fee, hook.DEFAULT_COOLDOWN_FEE());
        assertEq(uint256(reason), uint256(FairStartHook.FeeReason.COOLDOWN));
    }

    function testAfterSwapIncrementsSwapCount() public {
        (, uint64 beforeSwapCount,) = hook.poolState(poolId);

        BalanceDelta swapDelta = swapRouter.swapExactTokensForTokens({
            amountIn: 1 ether,
            amountOutMin: 0,
            zeroForOne: true,
            poolKey: poolKey,
            hookData: abi.encode(trader),
            receiver: address(this),
            deadline: block.timestamp + 1
        });

        assertEq(int256(swapDelta.amount0()), -1 ether);

        (, uint64 afterSwapCount,) = hook.poolState(poolId);
        assertEq(afterSwapCount, beforeSwapCount + 1);
    }

    function testLiquidityRemovalBlockedDuringLaunchLock() public {
        vm.expectRevert();

        _decreaseLiquidity(1e18);
    }

    function testLiquidityRemovalAllowedAfterLaunchLock() public {
        vm.warp(block.timestamp + hook.DEFAULT_LIQUIDITY_LOCK_DURATION() + 1);

        _decreaseLiquidity(1e18);
    }

    function _swapParams(uint256 amountIn, bool zeroForOne) internal pure returns (SwapParams memory) {
        return SwapParams({
            zeroForOne: zeroForOne,
            amountSpecified: -int256(amountIn),
            sqrtPriceLimitX96: zeroForOne ? TickMath.MIN_SQRT_PRICE + 1 : TickMath.MAX_SQRT_PRICE - 1
        });
    }

    function _decreaseLiquidity(uint256 liquidityToRemove) internal {
        bytes[] memory params = new bytes[](2);
        params[0] = abi.encode(tokenId, liquidityToRemove, 0, 0, Constants.ZERO_BYTES);
        params[1] = abi.encode(currency0, currency1, address(this));

        positionManager.modifyLiquidities(
            abi.encode(abi.encodePacked(uint8(Actions.DECREASE_LIQUIDITY), uint8(Actions.TAKE_PAIR)), params),
            block.timestamp
        );
    }
}
