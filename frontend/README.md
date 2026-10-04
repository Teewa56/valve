# Valve Frontend

React, TypeScript, and Vite client for the Arbitrum Sepolia Valve contracts.

## Configure

Copy `.env.example` to `.env` and provide a ZeroDev project ID, passkey service URL, and deployed Valve Registry and Vault proxy addresses. The default USDC address is Circle's Arbitrum Sepolia token. `VITE_` values are public client configuration; never put private keys or other secrets here.

Passkey connection requires the configured ZeroDev project and passkey service. Until proxies are deployed and configured, the app intentionally does not create a wallet or submit transactions.

## Run

```bash
npm install
npm run dev
```

## Routes

- `/` passkey registration or reconnection
- `/dashboard` payer streams, accrued usage, new stream creation, and per-stream cancellation
- `/provider` incoming streams and provider claims

Stream creation batches USDC approval with Registry creation. Turning a stream off cancels only that Registry stream. The ERC20 allowance is shared by all streams for a wallet and Vault, so it is intentionally not reset when one stream is canceled; each registered stream still has its own maximum settlement cap. The provider view claims earned USDC through the Registry. Contract ABIs in `lib/abis/` are generated from Foundry output; regenerate them after contract ABI changes.
