// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IValveVault} from "./interfaces/IValveVault.sol";

contract ValveVault is Initializable, OwnableUpgradeable, ReentrancyGuard, UUPSUpgradeable, IValveVault {
    using SafeERC20 for IERC20;

    error ZeroAddress();
    error InvalidToken();
    error InvalidStream();
    error ZeroAmount();
    error RegistryAlreadySet();
    error OnlyRegistry();

    struct VaultStream {
        address payer;
        address provider;
        uint256 maxAmount;
        uint256 settledAmount;
    }

    IERC20 public override usdc;
    address public override registry;
    mapping(uint256 streamId => VaultStream stream) public streams;

    event RegistrySet(address indexed registry);
    event StreamRegistered(
        uint256 indexed streamId, address indexed payer, address indexed provider, uint256 maxAmount
    );
    event Settled(uint256 indexed streamId, address indexed payer, address indexed provider, uint256 amount);

    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner, IERC20 usdcToken) external initializer {
        if (address(usdcToken) == address(0)) revert ZeroAddress();
        if (address(usdcToken).code.length == 0) revert InvalidToken();

        __Ownable_init(initialOwner);
        usdc = usdcToken;
    }

    function setRegistry(address registryAddress) external override onlyOwner {
        if (registry != address(0)) revert RegistryAlreadySet();
        if (registryAddress == address(0) || registryAddress.code.length == 0) revert ZeroAddress();
        registry = registryAddress;
        emit RegistrySet(registryAddress);
    }

    function registerStream(uint256 streamId, address payer, address provider, uint256 maxAmount)
        external
        override
        nonReentrant
        onlyRegistry
    {
        if (payer == address(0) || provider == address(0)) revert ZeroAddress();
        if (maxAmount == 0) revert ZeroAmount();
        if (streams[streamId].payer != address(0)) revert InvalidStream();

        streams[streamId] = VaultStream({payer: payer, provider: provider, maxAmount: maxAmount, settledAmount: 0});
        emit StreamRegistered(streamId, payer, provider, maxAmount);
    }

    function settle(uint256 streamId, uint256 requestedAmount)
        external
        override
        nonReentrant
        onlyRegistry
        returns (uint256 settledAmount)
    {
        VaultStream storage stream = streams[streamId];
        if (stream.payer == address(0)) revert InvalidStream();

        uint256 remainingCap = stream.maxAmount - stream.settledAmount;
        uint256 availableAllowance = usdc.allowance(stream.payer, address(this));
        uint256 availableBalance = usdc.balanceOf(stream.payer);
        settledAmount = _min(requestedAmount, _min(remainingCap, _min(availableAllowance, availableBalance)));

        if (settledAmount != 0) {
            stream.settledAmount += settledAmount;
            usdc.safeTransferFrom(stream.payer, stream.provider, settledAmount);
            emit Settled(streamId, stream.payer, stream.provider, settledAmount);
        }
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    modifier onlyRegistry() {
        if (msg.sender != registry) revert OnlyRegistry();
        _;
    }

    function _min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}
