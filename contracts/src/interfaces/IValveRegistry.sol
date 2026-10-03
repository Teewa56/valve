// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IValveVault} from "./IValveVault.sol";

interface IValveRegistry {
    struct Stream {
        address payer;
        address provider;
        uint256 ratePerSecondX18;
        uint256 maxAmount;
        uint256 claimedAmount;
        uint256 startTime;
        uint256 endTime;
        bool active;
    }

    function createStream(address provider, uint256 ratePerSecondX18, uint256 maxAmount)
        external
        returns (uint256 streamId);
    function claim(uint256 streamId) external returns (uint256 amount);
    function cancelStream(uint256 streamId) external returns (uint256 settledAmount);
    function getStream(uint256 streamId) external view returns (Stream memory);
    function accruedAmount(uint256 streamId) external view returns (uint256);
    function isActive(uint256 streamId) external view returns (bool);
    function usdc() external view returns (IERC20);
    function vault() external view returns (IValveVault);
    function nextStreamId() external view returns (uint256);
}
