// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test} from "forge-std/Test.sol";
import {StreamMath} from "../../src/libraries/StreamMath.sol";

contract StreamMathHarness {
    function vested(uint256 rate, uint256 elapsed, uint256 depositAmount) external pure returns (uint256) {
        return StreamMath.vestedAmount(rate, elapsed, depositAmount);
    }
}

contract StreamMathFuzzTest is Test {
    StreamMathHarness internal mathHarness;

    function setUp() public {
        mathHarness = new StreamMathHarness();
    }

    function testFuzz_vestedAmountNeverExceedsDeposit(uint256 rate, uint256 elapsed, uint256 depositAmount)
        public
        view
    {
        depositAmount = bound(depositAmount, 1, type(uint128).max);
        uint256 vested = mathHarness.vested(rate, elapsed, depositAmount);
        assertLe(vested, depositAmount);
    }

    function testFuzz_vestingIsMonotonic(uint256 rate, uint64 firstElapsed, uint64 extraElapsed, uint128 depositAmount)
        public
        view
    {
        depositAmount = uint128(bound(depositAmount, 1, type(uint128).max));
        uint256 first = mathHarness.vested(rate, firstElapsed, depositAmount);
        uint256 later = mathHarness.vested(rate, uint256(firstElapsed) + extraElapsed, depositAmount);
        assertGe(later, first);
    }
}
