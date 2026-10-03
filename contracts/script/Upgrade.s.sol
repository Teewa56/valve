// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

interface IUUPSUpgrade {
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable;
}

contract Upgrade is Script {
    error WrongNetwork(uint256 actualChainId);

    function run() external {
        if (block.chainid != 421614) revert WrongNetwork(block.chainid);

        address registryProxy = vm.envAddress("VALVE_REGISTRY_PROXY");
        address vaultProxy = vm.envAddress("VALVE_VAULT_PROXY");
        address registryImplementation = vm.envAddress("VALVE_REGISTRY_IMPLEMENTATION");
        address vaultImplementation = vm.envAddress("VALVE_VAULT_IMPLEMENTATION");
        uint256 ownerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(ownerKey);
        IUUPSUpgrade(registryProxy).upgradeToAndCall(registryImplementation, "");
        IUUPSUpgrade(vaultProxy).upgradeToAndCall(vaultImplementation, "");
        vm.stopBroadcast();

        console2.log("Upgraded ValveRegistry proxy:", registryProxy);
        console2.log("Upgraded ValveVault proxy:", vaultProxy);
    }
}
