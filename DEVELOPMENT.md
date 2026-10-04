# Valve Development Guide

This guide covers local contract and frontend checks, followed by deployment to Arbitrum Sepolia. Live deployment and passkey transactions use testnet infrastructure; local unit tests do not need RPC credentials.

## Requirements

- [Foundry](https://book.getfoundry.sh/getting-started/installation) (`forge`, `cast`)
- Node.js compatible with the Vite version in `frontend/package.json` and npm
- For testnet deployment: an Arbitrum Sepolia RPC URL, a funded testnet deployer, and Circle test USDC
- For passkey transactions: a ZeroDev project and a configured passkey service

Never commit private keys or put them in `frontend/.env`. Frontend variables prefixed with `VITE_` are public and are embedded in the client build.

## Local Contract Checks

From the repository root:

```bash
cd contracts
forge install
forge build
forge test -vvv --invariant-depth 64
forge fmt --check
```

The tests deploy proxies locally and use `test/mocks/MockUSDC.sol`, a six-decimal test token. Its mint function is test-only; production deployment scripts do not deploy or use this token. The invariant suite checks that test USDC remains accounted for through stream creation, claims, and cancellation.

## Local Frontend Checks

In a second terminal, from the repository root:

```bash
cd frontend
npm install
npm run typecheck
npm run build
npm run dev -- --host 0.0.0.0 --port 5173
```

Open `http://localhost:5173`. The landing, subscriber (`/dashboard`), and provider (`/provider`) routes can be reviewed without deployed contracts. Without the required wallet and proxy configuration, passkey transaction controls intentionally remain disabled. The frontend has no separate unit-test script at present; `typecheck` and the production build are its automated checks.

The Vite app is not configured to run the AA/passkey workflow against a local Anvil chain. For end-to-end transaction testing, deploy the contracts to Arbitrum Sepolia and use the testnet configuration below.

## Deploy Contracts to Arbitrum Sepolia

### 1. Prepare a testnet deployer

Create `contracts/.env` from the example:

```bash
cd contracts
cp .env.example .env
```

Set these values in `contracts/.env`:

- `ARBITRUM_SEPOLIA_RPC_URL`: your Arbitrum Sepolia RPC endpoint
- `ARBITRUM_SEPOLIA_USDC`: Circle's Arbitrum Sepolia USDC address, `0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d`
- `PRIVATE_KEY`: the testnet deployer key, stored locally only

The deployer needs Arbitrum Sepolia ETH for gas. The deployment script checks chain ID `421614`, USDC contract code, and six token decimals before deploying.

### 2. Build and test before broadcasting

From `contracts/`:

```bash
forge build
forge test -vvv --invariant-depth 64
```

### 3. Deploy the Registry and Vault proxies

Load the RPC value into the shell and broadcast the deployment:

```bash
set -a
source .env
set +a
forge script script/Deploy.s.sol:Deploy --rpc-url "$ARBITRUM_SEPOLIA_RPC_URL" --broadcast
```

Record the printed `ValveRegistry proxy` and `ValveVault proxy` addresses. The script deploys each implementation and ERC1967 proxy, initializes both with the deployer as owner, configures the USDC token, and links the Vault to the Registry. Confirm the transactions on Arbiscan before proceeding.

### 4. Configure the frontend

Create `frontend/.env` from its example:

```bash
cd ../frontend
cp .env.example .env
```

Set the following values in `frontend/.env`:

- `VITE_ZERODEV_PROJECT_ID`: your ZeroDev project ID for Arbitrum Sepolia
- `VITE_PASSKEY_SERVER_URL`: the passkey service URL configured for that project
- `VITE_VALVE_REGISTRY_ADDRESS`: the Registry proxy address printed by deployment
- `VITE_VALVE_VAULT_ADDRESS`: the Vault proxy address printed by deployment
- `VITE_ARBITRUM_SEPOLIA_RPC_URL`: an RPC URL usable by the browser
- `VITE_USDC_ADDRESS`: Circle's Arbitrum Sepolia USDC address above

Restart the dev server after changing `.env`. To exercise the app against the deployed contracts, use `npm run dev` and connect a passkey account configured for Arbitrum Sepolia. The account needs test USDC for subscriptions and test ETH if gas is not sponsored by the configured paymaster.

### 5. Build and publish the frontend

Vite reads `VITE_` settings at build time. Set the production environment values before building:

```bash
npm run typecheck
npm run build
npm run preview -- --host 0.0.0.0 --port 4173
```

Test the preview at `http://localhost:4173`, then publish the generated `frontend/dist/` directory with your static hosting provider. Set the same `VITE_` variables in the hosting provider's build environment and rebuild after changing contract addresses. Configure SPA fallback to `index.html` so direct navigation to `/dashboard` and `/provider` works.

### 6. Verify the live deployment

Check the configured chain and USDC token:

```bash
cast chain-id --rpc-url "$ARBITRUM_SEPOLIA_RPC_URL"
cast call "$ARBITRUM_SEPOLIA_USDC" 'decimals()(uint8)' --rpc-url "$ARBITRUM_SEPOLIA_RPC_URL"
```

Expected results are chain ID `421614` and decimals `6`. Confirm the Registry proxy's `usdc()` matches the configured USDC, its `vault()` matches the Vault proxy, and the Vault's `registry()` matches the Registry proxy before enabling user traffic.

## Seed a Test Stream

To run the Foundry seed script, set `VALVE_REGISTRY_PROXY`, `VALVE_VAULT_PROXY`, `SEED_PROVIDER`, `SEED_RATE_PER_SECOND_X18`, and `SEED_DEPOSIT_AMOUNT` in `contracts/.env`. `PRIVATE_KEY` must belong to the payer, and that wallet must hold enough test USDC. The script submits USDC approval and stream creation:

```bash
cd contracts
set -a
source .env
set +a
forge script script/Seed.s.sol:Seed --rpc-url "$ARBITRUM_SEPOLIA_RPC_URL" --broadcast
```

Amounts are in USDC base units (1 USDC = 1,000,000 units). The rate is base units per second scaled by `1e18`; for example `1e18` accrues one micro-USDC per second. A payer can also create streams from the frontend, which batches approval and Registry creation in a smart-account operation.

## Upgrade Proxies

Only the current proxy owner can authorize UUPS upgrades. First deploy new implementations from `contracts/` using the owner key:

```bash
set -a
source .env
set +a
forge create src/ValveRegistry.sol:ValveRegistry --rpc-url "$ARBITRUM_SEPOLIA_RPC_URL" --private-key "$PRIVATE_KEY"
forge create src/ValveVault.sol:ValveVault --rpc-url "$ARBITRUM_SEPOLIA_RPC_URL" --private-key "$PRIVATE_KEY"
```

Set the returned addresses as `VALVE_REGISTRY_IMPLEMENTATION` and `VALVE_VAULT_IMPLEMENTATION` in `contracts/.env`, keep the proxy addresses in `VALVE_REGISTRY_PROXY` and `VALVE_VAULT_PROXY`, then run:

```bash
forge script script/Upgrade.s.sol:Upgrade --rpc-url "$ARBITRUM_SEPOLIA_RPC_URL" --broadcast
```

Validate storage-layout compatibility and test the new implementation before upgrading. For production, use a multisig as proxy owner; the current deployment script assigns ownership to the deployer key.

## Contract ABI Updates

After changing contract interfaces, regenerate the Foundry ABI artifacts and copy them into the frontend's documented ABI folder:

```bash
cd contracts
forge build --extra-output-files abi
cp out/ValveRegistry.sol/ValveRegistry.abi.json ../frontend/lib/abis/ValveRegistry.json
cp out/ValveVault.sol/ValveVault.abi.json ../frontend/lib/abis/ValveVault.json
cd ../frontend
npm run typecheck
npm run build
```

## Important Stream Behavior

Creating a stream sets a per-stream maximum and requires the payer to approve the Vault, but it does not transfer the maximum upfront. Claims transfer accrued USDC directly from payer to provider, bounded by accrual, the stream cap, and the payer's shared USDC allowance and balance. Canceling one stream freezes that stream's accrual; it must not zero the Vault allowance because that allowance is shared with the payer's other streams. Any approved amount remains subject to each stream's individual Registry/Vault cap.
