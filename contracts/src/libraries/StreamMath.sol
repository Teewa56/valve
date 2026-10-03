// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

library StreamMath {
    uint256 internal constant RATE_SCALE = 1e18;

    function vestedAmount(uint256 ratePerSecondX18, uint256 elapsed, uint256 depositAmount)
        internal
        pure
        returns (uint256)
    {
        uint256 highProduct;
        assembly ("memory-safe") {
            let mm := mulmod(ratePerSecondX18, elapsed, not(0))
            let lowProduct := mul(ratePerSecondX18, elapsed)
            highProduct := sub(sub(mm, lowProduct), lt(mm, lowProduct))
        }
        if (highProduct >= RATE_SCALE) return depositAmount;

        uint256 amount = Math.mulDiv(ratePerSecondX18, elapsed, RATE_SCALE);
        return amount < depositAmount ? amount : depositAmount;
    }
}
