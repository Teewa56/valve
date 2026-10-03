// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IValveRegistry} from "../src/interfaces/IValveRegistry.sol";
import {IValveVault} from "../src/interfaces/IValveVault.sol";
import {ValveRegistry} from "../src/ValveRegistry.sol";
import {ValveVault} from "../src/ValveVault.sol";
import {MockUSDC} from "./mocks/MockUSDC.sol";

contract ValveRegistryTest is Test {
    uint256 internal constant RATE_SCALE = 1e18;
    address internal constant PAYER = address(0xA11CE);
    address internal constant PROVIDER = address(0xB0B);

    MockUSDC internal usdc;
    ValveVault internal vault;
    ValveRegistry internal registry;

    function setUp() public {
        usdc = new MockUSDC();

        ValveVault vaultImplementation = new ValveVault();
        vault = ValveVault(
            address(
                new ERC1967Proxy(
                    address(vaultImplementation),
                    abi.encodeCall(ValveVault.initialize, (address(this), IERC20(address(usdc))))
                )
            )
        );

        ValveRegistry registryImplementation = new ValveRegistry();
        registry = ValveRegistry(
            address(
                new ERC1967Proxy(
                    address(registryImplementation),
                    abi.encodeCall(
                        ValveRegistry.initialize, (address(this), IERC20(address(usdc)), IValveVault(address(vault)))
                    )
                )
            )
        );
        vault.setRegistry(address(registry));
    }

    function test_createStreamRegistersCapWithoutUpfrontTransfer() public {
        uint256 streamId = _createStream(1_000, RATE_SCALE);

        IValveRegistry.Stream memory stream = registry.getStream(streamId);
        assertEq(stream.payer, PAYER);
        assertEq(stream.provider, PROVIDER);
        assertEq(stream.maxAmount, 1_000);
        assertEq(usdc.balanceOf(address(vault)), 0);
        assertEq(usdc.balanceOf(PAYER), 10_001_000);
        assertTrue(stream.active);
    }

    function test_claimPaysOnlyVestedUSDC() public {
        uint256 streamId = _createStream(1_000, RATE_SCALE);
        vm.warp(block.timestamp + 5);

        vm.prank(PROVIDER);
        uint256 claimed = registry.claim(streamId);

        assertEq(claimed, 5);
        assertEq(usdc.balanceOf(PROVIDER), 5);
        assertEq(usdc.balanceOf(PAYER), 10_000_995);
        assertEq(usdc.balanceOf(address(vault)), 0);
    }

    function test_cumulativeVestingPreservesFractionsAcrossClaims() public {
        uint256 streamId = _createStream(100, RATE_SCALE / 2);

        vm.warp(block.timestamp + 1);
        assertEq(registry.accruedAmount(streamId), 0);

        vm.warp(block.timestamp + 1);
        vm.prank(PROVIDER);
        assertEq(registry.claim(streamId), 1);
    }

    function test_cancelSettlesEarnedAndStopsAccrual() public {
        uint256 streamId = _createStream(100, 2 * RATE_SCALE);
        vm.warp(block.timestamp + 10);

        vm.prank(PAYER);
        uint256 settled = registry.cancelStream(streamId);

        assertEq(usdc.balanceOf(PROVIDER), 20);
        assertEq(settled, 20);
        assertEq(usdc.balanceOf(PAYER), 10_000_080);
        assertEq(usdc.balanceOf(address(vault)), 0);
        assertFalse(registry.isActive(streamId));
    }

    function test_claimCapsAtMaximumAndDeactivates() public {
        uint256 streamId = _createStream(100, 2 * RATE_SCALE);
        vm.warp(block.timestamp + 1_000);

        vm.prank(PROVIDER);
        assertEq(registry.claim(streamId), 100);

        assertEq(usdc.balanceOf(PROVIDER), 100);
        assertFalse(registry.isActive(streamId));
        vm.expectRevert(ValveRegistry.StreamInactive.selector);
        vm.prank(PROVIDER);
        registry.claim(streamId);
    }

    function test_nonProviderCannotClaim() public {
        uint256 streamId = _createStream(100, RATE_SCALE);
        vm.warp(block.timestamp + 1);

        vm.expectRevert(ValveRegistry.NotProvider.selector);
        vm.prank(PAYER);
        registry.claim(streamId);
    }

    function test_nonPayerCannotCancel() public {
        uint256 streamId = _createStream(100, RATE_SCALE);

        vm.expectRevert(ValveRegistry.NotPayer.selector);
        vm.prank(PROVIDER);
        registry.cancelStream(streamId);
    }

    function test_createStreamRequiresVaultAllowance() public {
        usdc.mint(PAYER, 100);
        vm.expectRevert(abi.encodeWithSelector(ValveRegistry.InsufficientAllowance.selector, 0, 100));
        vm.prank(PAYER);
        registry.createStream(PROVIDER, RATE_SCALE, 100);
    }

    function test_monthlyUSDC_rateAccruesAboutTwoDollarsInFortyEightHours() public {
        uint256 monthlyDeposit = 30_000_000;
        uint256 monthlyRate = (monthlyDeposit * RATE_SCALE) / 30 days;
        uint256 streamId = _createStream(monthlyDeposit, monthlyRate);

        vm.warp(block.timestamp + 48 hours);
        assertApproxEqAbs(registry.accruedAmount(streamId), 2_000_000, 1);
    }

    function test_UUPSUpgradePreservesStreamState() public {
        uint256 streamId = _createStream(1_000, RATE_SCALE);
        ValveRegistry nextImplementation = new ValveRegistry();

        registry.upgradeToAndCall(address(nextImplementation), "");

        IValveRegistry.Stream memory stream = registry.getStream(streamId);
        assertEq(stream.payer, PAYER);
        assertEq(stream.provider, PROVIDER);
        assertEq(stream.maxAmount, 1_000);
        assertTrue(registry.isActive(streamId));
    }

    function test_cancelFreezesAccrualWhenAllowanceWasRevoked() public {
        uint256 streamId = _createStream(100, 2 * RATE_SCALE);
        vm.warp(block.timestamp + 10);

        vm.prank(PAYER);
        usdc.approve(address(vault), 0);
        vm.prank(PAYER);
        assertEq(registry.cancelStream(streamId), 0);

        vm.warp(block.timestamp + 100);
        assertFalse(registry.isActive(streamId));
        assertEq(registry.accruedAmount(streamId), 20);

        vm.prank(PAYER);
        usdc.approve(address(vault), 20);
        vm.prank(PROVIDER);
        assertEq(registry.claim(streamId), 20);
    }

    function _createStream(uint256 depositAmount, uint256 ratePerSecondX18) private returns (uint256 streamId) {
        usdc.mint(PAYER, depositAmount + 10_000_000);
        vm.startPrank(PAYER);
        usdc.approve(address(vault), type(uint256).max);
        streamId = registry.createStream(PROVIDER, ratePerSecondX18, depositAmount);
        vm.stopPrank();
    }
}
