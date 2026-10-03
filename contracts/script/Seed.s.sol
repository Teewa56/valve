// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IValveRegistry} from "../src/interfaces/IValveRegistry.sol";
import {IValveVault} from "../src/interfaces/IValveVault.sol";

contract Seed is Script {
    error WrongNetwork(uint256 actualChainId);
    error InvalidUSDCConfiguration();

    function run() external {
        if (block.chainid != 421614) revert WrongNetwork(block.chainid);

        uint256 payerKey = vm.envUint("PRIVATE_KEY");
        IERC20 usdc = IERC20(vm.envAddress("ARBITRUM_SEPOLIA_USDC"));
        IValveRegistry registry = IValveRegistry(vm.envAddress("VALVE_REGISTRY_PROXY"));
        IValveVault vault = IValveVault(vm.envAddress("VALVE_VAULT_PROXY"));
        if (
            address(usdc).code.length == 0 || IERC20Metadata(address(usdc)).decimals() != 6
                || address(registry.usdc()) != address(usdc) || address(vault.usdc()) != address(usdc)
        ) revert InvalidUSDCConfiguration();
        address provider = vm.envAddress("SEED_PROVIDER");
        uint256 ratePerSecondX18 = vm.envUint("SEED_RATE_PER_SECOND_X18");
        uint256 depositAmount = vm.envUint("SEED_DEPOSIT_AMOUNT");

        vm.startBroadcast(payerKey);
        usdc.approve(address(vault), depositAmount);
        uint256 streamId = registry.createStream(provider, ratePerSecondX18, depositAmount);
        vm.stopBroadcast();

        console2.log("Seed stream ID:", streamId);
        console2.log("Provider:", provider);
        console2.log("Deposit (USDC base units):", depositAmount);
    }
}
