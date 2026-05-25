// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {HookMiner} from "@uniswap/v4-periphery/src/utils/HookMiner.sol";

import {BaseScript} from "./base/BaseScript.sol";

import {FairStartHook} from "../src/FairStartHook.sol";

/// @notice Mines the address and deploys the FairStart Hook contract.
contract DeployHookScript is BaseScript {
    function run() public {
        uint160 flags = uint160(
            Hooks.AFTER_INITIALIZE_FLAG | Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG
                | Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG
        );

        bytes memory constructorArgs = abi.encode(poolManager);
        (address hookAddress, bytes32 salt) =
            HookMiner.find(CREATE2_FACTORY, flags, type(FairStartHook).creationCode, constructorArgs);

        vm.startBroadcast();
        FairStartHook fairStartHook = new FairStartHook{salt: salt}(poolManager);
        vm.stopBroadcast();

        require(address(fairStartHook) == hookAddress, "DeployHookScript: Hook Address Mismatch");
    }
}
