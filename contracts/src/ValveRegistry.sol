// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IValveRegistry} from "./interfaces/IValveRegistry.sol";
import {IValveVault} from "./interfaces/IValveVault.sol";
import {StreamMath} from "./libraries/StreamMath.sol";

contract ValveRegistry is Initializable, OwnableUpgradeable, ReentrancyGuard, UUPSUpgradeable, IValveRegistry {
    error ZeroAddress();
    error InvalidVault();
    error InvalidProvider();
    error ZeroRate();
    error ZeroDeposit();
    error InsufficientAllowance(uint256 available, uint256 required);
    error InvalidStream();
    error NotProvider();
    error NotPayer();
    error StreamInactive();
    error NothingToClaim();

    IERC20 public override usdc;
    IValveVault public override vault;
    uint256 public override nextStreamId;
    mapping(uint256 streamId => IValveRegistry.Stream stream) private _streams;

    event StreamCreated(
        uint256 indexed streamId,
        address indexed payer,
        address indexed provider,
        uint256 ratePerSecondX18,
        uint256 maxAmount,
        uint256 startTime
    );
    event StreamClaimed(uint256 indexed streamId, address indexed provider, uint256 amount);
    event StreamCancelled(uint256 indexed streamId, address indexed payer, uint256 accrued, uint256 settled);

    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner, IERC20 usdcToken, IValveVault vaultAddress) external initializer {
        if (address(usdcToken) == address(0) || address(vaultAddress) == address(0)) revert ZeroAddress();
        if (address(usdcToken).code.length == 0) revert ZeroAddress();
        if (address(vaultAddress.usdc()) != address(usdcToken)) revert InvalidVault();

        __Ownable_init(initialOwner);
        usdc = usdcToken;
        vault = vaultAddress;
    }

    function createStream(address provider, uint256 ratePerSecondX18, uint256 maxAmount)
        external
        override
        nonReentrant
        returns (uint256 streamId)
    {
        if (provider == address(0) || provider == msg.sender) revert InvalidProvider();
        if (ratePerSecondX18 == 0) revert ZeroRate();
        if (maxAmount == 0) revert ZeroDeposit();
        uint256 availableAllowance = usdc.allowance(msg.sender, address(vault));
        if (availableAllowance < maxAmount) revert InsufficientAllowance(availableAllowance, maxAmount);

        streamId = ++nextStreamId;
        vault.registerStream(streamId, msg.sender, provider, maxAmount);
        _streams[streamId] = IValveRegistry.Stream({
            payer: msg.sender,
            provider: provider,
            ratePerSecondX18: ratePerSecondX18,
            maxAmount: maxAmount,
            claimedAmount: 0,
            startTime: block.timestamp,
            endTime: 0,
            active: true
        });

        emit StreamCreated(streamId, msg.sender, provider, ratePerSecondX18, maxAmount, block.timestamp);
    }

    function claim(uint256 streamId) external override nonReentrant returns (uint256 amount) {
        IValveRegistry.Stream storage stream = _getClaimableStream(streamId);
        if (msg.sender != stream.provider) revert NotProvider();

        amount = _claimable(stream);
        if (amount == 0) revert NothingToClaim();

        amount = vault.settle(streamId, amount);
        if (amount == 0) revert NothingToClaim();

        stream.claimedAmount += amount;
        if (stream.claimedAmount == stream.maxAmount) stream.active = false;

        emit StreamClaimed(streamId, stream.provider, amount);
    }

    function cancelStream(uint256 streamId) external override nonReentrant returns (uint256 settledAmount) {
        IValveRegistry.Stream storage stream = _getActiveStream(streamId);
        if (msg.sender != stream.payer) revert NotPayer();

        stream.active = false;
        stream.endTime = block.timestamp;

        uint256 accrued = _claimable(stream);
        try vault.settle(streamId, accrued) returns (uint256 amount) {
            settledAmount = amount;
        } catch {
            settledAmount = 0;
        }
        stream.claimedAmount += settledAmount;

        emit StreamCancelled(streamId, stream.payer, accrued, settledAmount);
    }

    function getStream(uint256 streamId) external view override returns (IValveRegistry.Stream memory) {
        IValveRegistry.Stream memory stream = _streams[streamId];
        if (stream.payer == address(0)) revert InvalidStream();
        return stream;
    }

    function accruedAmount(uint256 streamId) external view override returns (uint256) {
        IValveRegistry.Stream storage stream = _streams[streamId];
        if (stream.payer == address(0)) revert InvalidStream();
        return _claimable(stream);
    }

    function isActive(uint256 streamId) external view override returns (bool) {
        IValveRegistry.Stream storage stream = _streams[streamId];
        if (stream.payer == address(0)) revert InvalidStream();
        return stream.active;
    }

    function _getActiveStream(uint256 streamId) private view returns (IValveRegistry.Stream storage stream) {
        stream = _streams[streamId];
        if (stream.payer == address(0)) revert InvalidStream();
        if (!stream.active) revert StreamInactive();
    }

    function _getClaimableStream(uint256 streamId) private view returns (IValveRegistry.Stream storage stream) {
        stream = _streams[streamId];
        if (stream.payer == address(0)) revert InvalidStream();
        if (!stream.active && stream.endTime == 0) revert StreamInactive();
    }

    function _claimable(IValveRegistry.Stream storage stream) private view returns (uint256) {
        uint256 timestamp = stream.endTime == 0 ? block.timestamp : stream.endTime;
        uint256 elapsed = timestamp - stream.startTime;
        uint256 vested = StreamMath.vestedAmount(stream.ratePerSecondX18, elapsed, stream.maxAmount);
        return vested - stream.claimedAmount;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
