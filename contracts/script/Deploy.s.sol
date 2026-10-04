// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ValveRegistry} from "../src/ValveRegistry.sol";
import {ValveVault} from "../src/ValveVault.sol";
import {IValveVault} from "../src/interfaces/IValveVault.sol";

contract Deploy is Script {
    error WrongNetwork(uint256 actualChainId);
    error InvalidUSDC();
    error InvalidUSDCDecimals(uint8 decimals);

    function run() external {
        if (block.chainid != 421614) revert WrongNetwork(block.chainid);

        string memory rawPrivateKey = vm.envString("PRIVATE_KEY");
        bytes memory privateKeyBytes = bytes(rawPrivateKey);
        bool hasHexPrefix = privateKeyBytes.length >= 2 && privateKeyBytes[0] == "0" &&
            (privateKeyBytes[1] == "x" || privateKeyBytes[1] == "X");
        uint256 deployerKey = vm.parseUint(hasHexPrefix ? rawPrivateKey : string.concat("0x", rawPrivateKey));
        address owner = vm.addr(deployerKey);
        IERC20Metadata usdcMetadata = IERC20Metadata(vm.envAddress("ARBITRUM_SEPOLIA_USDC"));
        if (address(usdcMetadata).code.length == 0) revert InvalidUSDC();
        uint8 tokenDecimals = usdcMetadata.decimals();
        if (tokenDecimals != 6) revert InvalidUSDCDecimals(tokenDecimals);
        IERC20 usdc = IERC20(address(usdcMetadata));

        vm.startBroadcast(deployerKey);

        ValveVault vaultImplementation = new ValveVault();
        ValveVault vault = ValveVault(
            address(
                new ERC1967Proxy(address(vaultImplementation), abi.encodeCall(ValveVault.initialize, (owner, usdc)))
            )
        );

        ValveRegistry registryImplementation = new ValveRegistry();
        ValveRegistry registry = ValveRegistry(
            address(
                new ERC1967Proxy(
                    address(registryImplementation),
                    abi.encodeCall(ValveRegistry.initialize, (owner, usdc, IValveVault(address(vault))))
                )
            )
        );
        vault.setRegistry(address(registry));

        vm.stopBroadcast();

        console2.log("ValveRegistry proxy:", address(registry));
        console2.log("ValveVault proxy:", address(vault));
        console2.log("USDC:", address(usdc));
    }
}
