// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ValveVault} from "../src/ValveVault.sol";
import {MockUSDC} from "./mocks/MockUSDC.sol";

contract VaultRegistryCaller {
    function registerStream(ValveVault vault, uint256 streamId, address payer, address provider, uint256 maxAmount)
        external
    {
        vault.registerStream(streamId, payer, provider, maxAmount);
    }

    function settle(ValveVault vault, uint256 streamId, uint256 amount) external returns (uint256) {
        return vault.settle(streamId, amount);
    }
}

contract ValveVaultTest is Test {
    MockUSDC internal usdc;
    ValveVault internal vault;
    address internal registryCaller;
    address internal payer = address(0xA11CE);
    address internal provider = address(0xB0B);

    function setUp() public {
        usdc = new MockUSDC();
        ValveVault implementation = new ValveVault();
        vault = ValveVault(
            address(
                new ERC1967Proxy(
                    address(implementation),
                    abi.encodeCall(ValveVault.initialize, (address(this), IERC20(address(usdc))))
                )
            )
        );
        registryCaller = address(new VaultRegistryCaller());
        vault.setRegistry(registryCaller);
    }

    function test_onlyRegistryCanRegisterAndSettleStreams() public {
        vm.expectRevert(ValveVault.OnlyRegistry.selector);
        vault.registerStream(1, payer, provider, 1);
        vm.expectRevert(ValveVault.OnlyRegistry.selector);
        vault.settle(1, 1);
    }

    function test_registrySettlementTransfersOnlyEarnedUSDC() public {
        usdc.mint(payer, 100);
        vm.prank(payer);
        usdc.approve(address(vault), 100);

        VaultRegistryCaller(registryCaller).registerStream(vault, 1, payer, provider, 100);
        assertEq(VaultRegistryCaller(registryCaller).settle(vault, 1, 40), 40);

        assertEq(usdc.balanceOf(provider), 40);
        assertEq(usdc.balanceOf(payer), 60);
        assertEq(usdc.balanceOf(address(vault)), 0);
    }

    function test_vaultCapsTotalSettlementAtRegisteredMaximum() public {
        usdc.mint(payer, 200);
        vm.prank(payer);
        usdc.approve(address(vault), 200);
        VaultRegistryCaller(registryCaller).registerStream(vault, 7, payer, provider, 100);

        assertEq(VaultRegistryCaller(registryCaller).settle(vault, 7, 200), 100);
        assertEq(VaultRegistryCaller(registryCaller).settle(vault, 7, 1), 0);
        assertEq(usdc.balanceOf(provider), 100);
        assertEq(usdc.balanceOf(payer), 100);
    }
}
