// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Valve} from "../src/Valve.sol";

interface IERC20Like {
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract ValveTest is Test {
    Valve internal valve;
    IERC20Like internal usdc;

    function setUp() public {
        valve = new Valve();

        string memory rpc = vm.envOr("ARBITRUM_SEPOLIA_RPC_URL", string(""));
        if (bytes(rpc).length == 0) return;

        vm.createSelectFork(rpc);

        address usdcAddress = vm.envAddress("ARBITRUM_SEPOLIA_USDC");
        require(usdcAddress != address(0), "ARBITRUM_SEPOLIA_USDC is required");
        usdc = IERC20Like(usdcAddress);
    }

    function test_uses_arbitrum_sepolia_usdc_configuration() public {
        string memory rpc = vm.envOr("ARBITRUM_SEPOLIA_RPC_URL", string(""));
        if (bytes(rpc).length == 0) return;

        assertEq(block.chainid, 421614, "Expected Arbitrum Sepolia chain id");
        assertTrue(address(usdc) != address(0), "USDC contract should be configured");
        assertTrue(address(usdc) != address(valve), "USDC should not be the valve contract address");
    }
}
