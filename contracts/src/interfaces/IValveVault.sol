// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IValveVault {
    function usdc() external view returns (IERC20);
    function registry() external view returns (address);
    function registerStream(uint256 streamId, address payer, address provider, uint256 maxAmount) external;
    function settle(uint256 streamId, uint256 requestedAmount) external returns (uint256 settledAmount);
    function setRegistry(address registryAddress) external;
}
