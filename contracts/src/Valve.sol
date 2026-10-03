// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20Like {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Valve {
    error ZeroAddress();
    error ZeroRate();
    error InvalidStream();
    error NotOwner();
    error NotRecipient();
    error StreamInactive();
    error NothingToClaim();
    error TokenTransferFailed();

    struct Stream {
        address owner;
        address recipient;
        address token;
        uint256 ratePerSecond;
        uint256 funded;
        uint256 withdrawn;
        uint256 lastUpdate;
        bool active;
    }

    mapping(uint256 => Stream) public streams;
    uint256 public nextStreamId;

    event StreamCreated(
        uint256 indexed streamId,
        address indexed owner,
        address indexed recipient,
        address token,
        uint256 ratePerSecond,
        uint256 funded,
        uint256 timestamp
    );
    event StreamClaimed(uint256 indexed streamId, address indexed recipient, uint256 amount, uint256 timestamp);
    event StreamCancelled(uint256 indexed streamId, address indexed owner, uint256 amountReturned, uint256 timestamp);
    event StreamFunded(uint256 indexed streamId, address indexed owner, uint256 amount, uint256 timestamp);

    function createStream(address token, address recipient, uint256 ratePerSecond, uint256 depositAmount)
        external
        returns (uint256 streamId)
    {
        if (token == address(0) || recipient == address(0)) revert ZeroAddress();
        if (ratePerSecond == 0) revert ZeroRate();
        if (depositAmount == 0) revert ZeroRate();

        streamId = ++nextStreamId;
        Stream storage stream = streams[streamId];
        stream.owner = msg.sender;
        stream.recipient = recipient;
        stream.token = token;
        stream.ratePerSecond = ratePerSecond;
        stream.funded = depositAmount;
        stream.lastUpdate = block.timestamp;
        stream.active = true;

        if (!IERC20Like(token).transferFrom(msg.sender, address(this), depositAmount)) {
            revert TokenTransferFailed();
        }

        emit StreamCreated(streamId, msg.sender, recipient, token, ratePerSecond, depositAmount, block.timestamp);
    }

    function fundStream(uint256 streamId, uint256 amount) external {
        Stream storage stream = streams[streamId];
        if (stream.owner == address(0)) revert InvalidStream();
        if (msg.sender != stream.owner) revert NotOwner();
        if (amount == 0) revert ZeroRate();

        if (!IERC20Like(stream.token).transferFrom(msg.sender, address(this), amount)) {
            revert TokenTransferFailed();
        }

        stream.funded += amount;
        emit StreamFunded(streamId, msg.sender, amount, block.timestamp);
    }

    function claim(uint256 streamId) external returns (uint256 amount) {
        Stream storage stream = streams[streamId];
        if (stream.owner == address(0)) revert InvalidStream();
        if (msg.sender != stream.recipient) revert NotRecipient();
        if (!stream.active) revert StreamInactive();

        amount = _accruedAmount(stream);
        if (amount == 0) revert NothingToClaim();

        uint256 remaining = stream.funded - stream.withdrawn;
        if (amount > remaining) {
            amount = remaining;
        }

        if (amount == 0) revert NothingToClaim();

        if (!IERC20Like(stream.token).transfer(stream.recipient, amount)) {
            revert TokenTransferFailed();
        }

        stream.withdrawn += amount;
        stream.lastUpdate = block.timestamp;

        if (stream.withdrawn >= stream.funded) {
            stream.active = false;
        }

        emit StreamClaimed(streamId, stream.recipient, amount, block.timestamp);
    }

    function cancelStream(uint256 streamId) external returns (uint256 amountReturned) {
        Stream storage stream = streams[streamId];
        if (stream.owner == address(0)) revert InvalidStream();
        if (msg.sender != stream.owner) revert NotOwner();

        uint256 pending = _accruedAmount(stream);
        if (pending > 0 && stream.active) {
            uint256 remaining = stream.funded - stream.withdrawn;
            if (pending > remaining) {
                pending = remaining;
            }
            if (pending > 0 && !IERC20Like(stream.token).transfer(stream.recipient, pending)) {
                revert TokenTransferFailed();
            }
            stream.withdrawn += pending;
        }

        amountReturned = stream.funded - stream.withdrawn;
        if (amountReturned > 0 && !IERC20Like(stream.token).transfer(msg.sender, amountReturned)) {
            revert TokenTransferFailed();
        }

        stream.lastUpdate = block.timestamp;
        stream.active = false;
        stream.funded = stream.withdrawn;

        emit StreamCancelled(streamId, msg.sender, amountReturned, block.timestamp);
    }

    function isActive(uint256 streamId) external view returns (bool) {
        return streams[streamId].active;
    }

    function accruedAmount(uint256 streamId) external view returns (uint256) {
        Stream storage stream = streams[streamId];
        if (stream.owner == address(0)) revert InvalidStream();
        return _accruedAmount(stream);
    }

    function _accruedAmount(Stream storage stream) internal view returns (uint256) {
        if (!stream.active) {
            return 0;
        }

        uint256 elapsed = block.timestamp - stream.lastUpdate;
        return elapsed * stream.ratePerSecond;
    }
}
