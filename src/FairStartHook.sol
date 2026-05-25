// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {BaseHook} from "@openzeppelin/uniswap-hooks/src/base/BaseHook.sol";

import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {LPFeeLibrary} from "@uniswap/v4-core/src/libraries/LPFeeLibrary.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
import {ModifyLiquidityParams, SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";

/// @notice Launch-phase protection for Uniswap v4 pools on X Layer.
/// @dev Fees are expressed in hundredths of a bip: 1e6 = 100%, 3000 = 0.30%.
contract FairStartHook is BaseHook {
    using LPFeeLibrary for uint24;
    using PoolIdLibrary for PoolKey;

    uint24 public constant DEFAULT_BASE_FEE = 500; // 0.05%
    uint24 public constant DEFAULT_LAUNCH_FEE = 3_000; // 0.30%
    uint24 public constant DEFAULT_COOLDOWN_FEE = 6_000; // 0.60%
    uint24 public constant DEFAULT_LARGE_SWAP_FEE = 10_000; // 1.00%
    uint24 public constant DEFAULT_MAX_FEE = 10_000; // 1.00%

    uint32 public constant DEFAULT_LAUNCH_DURATION = 30 minutes;
    uint32 public constant DEFAULT_LIQUIDITY_LOCK_DURATION = 30 minutes;
    uint32 public constant DEFAULT_COOLDOWN_SECONDS = 30 seconds;
    uint256 public constant DEFAULT_LARGE_SWAP_THRESHOLD = 10 ether;

    enum FeeReason {
        BASE,
        LAUNCH_WINDOW,
        COOLDOWN,
        LARGE_SWAP
    }

    struct PoolConfig {
        uint24 baseFee;
        uint24 launchFee;
        uint24 cooldownFee;
        uint24 largeSwapFee;
        uint24 maxFee;
        uint32 launchDuration;
        uint32 liquidityLockDuration;
        uint32 cooldownSeconds;
        uint256 largeSwapThreshold;
    }

    struct PoolState {
        uint64 launchTimestamp;
        uint64 swapCount;
        bool rulesLocked;
    }

    error NotDynamicFee();
    error InvalidConfig();
    error LaunchRulesAlreadyLocked(PoolId poolId);
    error LiquidityLocked(PoolId poolId, uint256 unlockTimestamp);

    mapping(PoolId poolId => PoolConfig config) public poolConfig;
    mapping(PoolId poolId => PoolState state) public poolState;
    mapping(PoolId poolId => mapping(address sender => uint256 timestamp)) public lastSwapAt;

    event PoolConfigured(PoolId indexed poolId, PoolConfig config);
    event LaunchStarted(PoolId indexed poolId, uint256 launchTimestamp, uint256 launchEndsAt, uint256 liquidityUnlocksAt);
    event LaunchRulesLocked(PoolId indexed poolId);
    event FairStartFeeApplied(PoolId indexed poolId, address indexed sender, uint24 fee, FeeReason reason);
    event LiquidityRemovalBlocked(PoolId indexed poolId, address indexed sender, uint256 unlockTimestamp);

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: true,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: true,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    /// @notice Optional pre-initialization config. Call this before pool initialization.
    function configurePool(PoolKey calldata key, PoolConfig calldata config) external {
        PoolId poolId = key.toId();
        if (poolState[poolId].rulesLocked) revert LaunchRulesAlreadyLocked(poolId);

        _validateConfig(config);
        poolConfig[poolId] = config;

        emit PoolConfigured(poolId, config);
    }

    function getDefaultConfig() public pure returns (PoolConfig memory) {
        return PoolConfig({
            baseFee: DEFAULT_BASE_FEE,
            launchFee: DEFAULT_LAUNCH_FEE,
            cooldownFee: DEFAULT_COOLDOWN_FEE,
            largeSwapFee: DEFAULT_LARGE_SWAP_FEE,
            maxFee: DEFAULT_MAX_FEE,
            launchDuration: DEFAULT_LAUNCH_DURATION,
            liquidityLockDuration: DEFAULT_LIQUIDITY_LOCK_DURATION,
            cooldownSeconds: DEFAULT_COOLDOWN_SECONDS,
            largeSwapThreshold: DEFAULT_LARGE_SWAP_THRESHOLD
        });
    }

    function launchEndsAt(PoolId poolId) public view returns (uint256) {
        PoolState memory state = poolState[poolId];
        PoolConfig memory config = _configFor(poolId);
        return uint256(state.launchTimestamp) + config.launchDuration;
    }

    function liquidityUnlocksAt(PoolId poolId) public view returns (uint256) {
        PoolState memory state = poolState[poolId];
        PoolConfig memory config = _configFor(poolId);
        return uint256(state.launchTimestamp) + config.liquidityLockDuration;
    }

    function quoteFee(address sender, PoolKey calldata key, SwapParams calldata params)
        external
        view
        returns (uint24 fee, FeeReason reason)
    {
        return _feeFor(sender, key.toId(), params);
    }

    function _afterInitialize(address, PoolKey calldata key, uint160, int24) internal override returns (bytes4) {
        if (!key.fee.isDynamicFee()) revert NotDynamicFee();

        PoolId poolId = key.toId();
        PoolState storage state = poolState[poolId];
        PoolConfig memory config = _configFor(poolId);

        state.launchTimestamp = uint64(block.timestamp);
        state.rulesLocked = true;
        poolConfig[poolId] = config;

        emit LaunchStarted(
            poolId,
            block.timestamp,
            block.timestamp + config.launchDuration,
            block.timestamp + config.liquidityLockDuration
        );
        emit LaunchRulesLocked(poolId);

        return BaseHook.afterInitialize.selector;
    }

    function _beforeSwap(address sender, PoolKey calldata key, SwapParams calldata params, bytes calldata hookData)
        internal
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        PoolId poolId = key.toId();
        address actor = _actor(sender, hookData);
        (uint24 fee, FeeReason reason) = _feeFor(actor, poolId, params);

        emit FairStartFeeApplied(poolId, actor, fee, reason);

        return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, fee | LPFeeLibrary.OVERRIDE_FEE_FLAG);
    }

    function _afterSwap(address sender, PoolKey calldata key, SwapParams calldata, BalanceDelta, bytes calldata hookData)
        internal
        override
        returns (bytes4, int128)
    {
        PoolId poolId = key.toId();
        address actor = _actor(sender, hookData);

        poolState[poolId].swapCount++;
        lastSwapAt[poolId][actor] = block.timestamp;

        return (BaseHook.afterSwap.selector, 0);
    }

    function _beforeRemoveLiquidity(address sender, PoolKey calldata key, ModifyLiquidityParams calldata, bytes calldata)
        internal
        override
        returns (bytes4)
    {
        PoolId poolId = key.toId();
        uint256 unlockTimestamp = liquidityUnlocksAt(poolId);

        if (block.timestamp < unlockTimestamp) {
            emit LiquidityRemovalBlocked(poolId, sender, unlockTimestamp);
            revert LiquidityLocked(poolId, unlockTimestamp);
        }

        return BaseHook.beforeRemoveLiquidity.selector;
    }

    function _feeFor(address sender, PoolId poolId, SwapParams calldata params)
        internal
        view
        returns (uint24 fee, FeeReason reason)
    {
        PoolConfig memory config = _configFor(poolId);

        fee = config.baseFee;
        reason = FeeReason.BASE;

        uint256 absoluteAmount = _absoluteAmount(params.amountSpecified);

        if (absoluteAmount >= config.largeSwapThreshold) {
            fee = config.largeSwapFee;
            reason = FeeReason.LARGE_SWAP;
        } else if (
            lastSwapAt[poolId][sender] != 0 && block.timestamp < lastSwapAt[poolId][sender] + config.cooldownSeconds
        ) {
            fee = config.cooldownFee;
            reason = FeeReason.COOLDOWN;
        } else if (block.timestamp < launchEndsAt(poolId)) {
            fee = config.launchFee;
            reason = FeeReason.LAUNCH_WINDOW;
        }

        if (fee > config.maxFee) {
            fee = config.maxFee;
        }
    }

    function _configFor(PoolId poolId) internal view returns (PoolConfig memory config) {
        config = poolConfig[poolId];

        if (config.maxFee == 0) {
            config = getDefaultConfig();
        }
    }

    function _validateConfig(PoolConfig calldata config) internal pure {
        bool invalid = config.maxFee == 0 || config.baseFee > config.maxFee || config.launchFee > config.maxFee
            || config.cooldownFee > config.maxFee || config.largeSwapFee > config.maxFee
            || config.maxFee > LPFeeLibrary.MAX_LP_FEE || config.largeSwapThreshold == 0;

        if (invalid) revert InvalidConfig();
    }

    function _absoluteAmount(int256 amountSpecified) internal pure returns (uint256) {
        return amountSpecified < 0 ? uint256(-amountSpecified) : uint256(amountSpecified);
    }

    function _actor(address sender, bytes calldata hookData) internal pure returns (address) {
        if (hookData.length == 32) {
            return abi.decode(hookData, (address));
        }

        return sender;
    }
}
