// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IValveVault} from "../../src/interfaces/IValveVault.sol";
import {ValveRegistry} from "../../src/ValveRegistry.sol";
import {ValveVault} from "../../src/ValveVault.sol";
import {MockUSDC} from "../mocks/MockUSDC.sol";

contract ValveHandler is Test {
    MockUSDC internal immutable usdc;
    ValveVault internal immutable vault;
    ValveRegistry internal immutable registry;
    address internal immutable provider;
    uint256 public totalMinted;
    uint256[] internal _streamIds;

    constructor(MockUSDC usdcToken, ValveVault streamVault, ValveRegistry streamRegistry, address providerAddress) {
        usdc = usdcToken;
        vault = streamVault;
        registry = streamRegistry;
        provider = providerAddress;
        usdc.approve(address(vault), type(uint256).max);
    }

    function createStream(uint96 amountSeed, uint96 rateSeed) external {
        uint256 amount = bound(uint256(amountSeed), 1, 1_000_000);
        uint256 rate = bound(uint256(rateSeed), 1, 10e18);
        usdc.mint(address(this), amount);
        totalMinted += amount;
        _streamIds.push(registry.createStream(provider, rate, amount));
    }

    function warp(uint32 secondsSeed) external {
        vm.warp(block.timestamp + bound(uint256(secondsSeed), 0, 30 days));
    }

    function claim(uint256 indexSeed) external {
        if (_streamIds.length == 0) return;
        uint256 streamId = _streamIds[indexSeed % _streamIds.length];
        vm.prank(provider);
        try registry.claim(streamId) {} catch {}
    }

    function cancel(uint256 indexSeed) external {
        if (_streamIds.length == 0) return;
        uint256 streamId = _streamIds[indexSeed % _streamIds.length];
        try registry.cancelStream(streamId) {} catch {}
    }
}

contract ValveInvariantTest is StdInvariant, Test {
    MockUSDC internal usdc;
    ValveVault internal vault;
    ValveRegistry internal registry;
    ValveHandler internal handler;
    address internal constant PROVIDER = address(0xB0B);

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

        handler = new ValveHandler(usdc, vault, registry, PROVIDER);
        targetContract(address(handler));
    }

    function invariant_everyUSDCunitRemainsAccountedFor() public view {
        assertEq(
            usdc.balanceOf(address(vault)) + usdc.balanceOf(address(handler)) + usdc.balanceOf(PROVIDER),
            handler.totalMinted()
        );
    }
}
