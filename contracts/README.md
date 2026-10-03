# Valve Contracts

Valve uses two UUPS proxies on Arbitrum Sepolia. `ValveRegistry` owns stream state and vesting math; `ValveVault` is the payer-approved USDC spender and enforces per-stream settlement caps. Creating a stream records an allowance cap but does not transfer the cap amount, so the payer's USDC stays in their wallet until it is earned.

## Setup

Install Foundry and the repository dependencies, then copy `.env.example` to `.env` and set `PRIVATE_KEY`:

```bash
forge install
cp .env.example .env
```

The example uses Circle's USDC contract on Arbitrum Sepolia (`0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d`). Fund the deployer with Arbitrum Sepolia ETH for gas and test USDC before seeding streams.

## Test

```bash
forge test -vvv
```

The unit and invariant suites use `test/mocks/MockUSDC.sol`, a six-decimal ERC20 with a test-only mint function. No test token is deployed by production scripts.

## Deploy

```bash
source .env
forge script script/Deploy.s.sol:Deploy --rpc-url "$ARBITRUM_SEPOLIA_RPC_URL" --broadcast
```

The script refuses to run unless the chain ID is Arbitrum Sepolia (`421614`) and the configured USDC address contains contract code and reports six decimals. It deploys implementations and ERC1967 proxies, then links the Vault to the Registry.

## Upgrade

Deploy new implementations and set their addresses in `.env`, then run:

```bash
forge script script/Upgrade.s.sol:Upgrade --rpc-url "$ARBITRUM_SEPOLIA_RPC_URL" --broadcast
```

Only the proxy owner can authorize an upgrade. Use a multisig owner for deployed environments and validate storage-layout compatibility before upgrading.

## Seed a Stream

Set the deployed proxy addresses, provider, deposit, and rate in `.env`, then run:

```bash
forge script script/Seed.s.sol:Seed --rpc-url "$ARBITRUM_SEPOLIA_RPC_URL" --broadcast
```

Rates are denominated in the smallest token unit per second with 18 extra decimal places. For USDC, one base unit is one micro-USDC, so a rate of `1e18` accrues one micro-USDC per second. Payers approve the Vault before the Registry creates the stream. Claims pull only vested USDC from the payer directly to the provider, bounded by both the stream cap and remaining token allowance.

To turn a stream off, call `cancelStream` and then approve the Vault for zero in the same wallet transaction batch. Cancellation fixes the final accrual timestamp and settles whatever is currently authorized. If the payer already revoked allowance, unpaid vested USDC remains claimable only if the payer later reauthorizes it; no accrual is added after cancellation.
