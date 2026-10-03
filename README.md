# Valve

**Absolute control over your digital subscriptions.**

## Description

Valve is a consumer-first subscription management protocol built on Arbitrum One.

In the traditional Web2 economy, recurring billing is predatory. Once you hand over your credit card details, companies can *pull* money from your account automatically, often burying the cancel button behind confusing surveys or customer service phone lines.

Valve replaces this with a **push-based** model. Instead of a flat upfront monthly charge, users stream funds linearly, second by second, through smart contract allowances. Funds flow like water through a pipe: open the valve when you need a service, shut it when you don't. The contract calculates the exact elapsed time down to the block timestamp, so you only pay for the time you actually use.

The frontend strips out Web3 friction. Users sign in with social accounts, approve actions with device passkeys, and manage everything from a dashboard of simple on/off toggles. Flipping a toggle to **Off** sends a micro-transaction that slashes the allowance to zero, freezing the stream instantly **without the service provider's permission**. This kind of granular micro-billing is only viable because of Arbitrum's ultra-low gas fees.

---

## How It Works & Case Study

### Core Mechanism

1. **Initiation:** The user picks a service and approves a time-restricted token allowance instead of paying a lump sum upfront.
2. **Streaming:** As time passes, the contract calculates the provider's accrued earnings from elapsed block timestamps.
3. **The Cut-off:** To cancel, the user revokes the allowance. The stream freezes mid-second, and the provider cannot pull a single extra cent.

### Case Study: Everyday Streaming

**Scenario:** Alice subscribes to a premium AI developer tool that costs $30/month. She only needs it for an intensive weekend feature sprint (exactly 48 hours).

|                      | Web2 (Legacy)                              | Valve                                 |
| -------------------- | ------------------------------------------ | ------------------------------------- |
| Upfront cost         | $30.00                                     | $0.00                                 |
| Cancellation         | Remember to cancel, navigate churn surveys | One toggle                            |
| Final cost           | $30.00                                     | **$2.00** (48 hrs of streaming) |
| Funds left in wallet | $0.00                                      | **$28.00**, untouched           |

Alice toggles the stream **ON** Friday night and **OFF** Sunday night. The contract streams exactly 48 hours of linear payment, and she pays $2.00.

### Stream Flow

```
 [ ALICE WALLET ] ──( Streaming Push )──> [ VALVE CORE CONTRACT ] ──> [ SERVICE PROVIDER ]
        │                                          │
        └──( Toggle OFF → allowance = 0 )──────────┴──> [ Stream frozen at 0 USDC/sec ]
```

### Stream Lifecycle

```
  Toggle ON            Time passes              Toggle OFF
     │                      │                        │
     ▼                      ▼                        ▼
 approve(allowance) ──> accrued = rate × Δt ──> approve(0) ──> settle exact amount
```

---

## Architecture

Valve pairs modular smart contracts with a Web2-style login experience.

```
  ┌────────────────────────────────────────────────────────┐
  │                   FRONTEND / CLIENT                    │
  │     React.js Dashboard + ZeroDev Passkey Account       │
  └──────────────────────────┬─────────────────────────────┘
                             │ (Gasless Meta-Transactions)
                             ▼
  ┌────────────────────────────────────────────────────────┐
  │                 ALCHEMY NODE GATEWAY                   │
  │       Tx Bundling, RPC & User Operations               │
  └──────────────────────────┬─────────────────────────────┘
                             │
                             ▼
  ┌────────────────────────────────────────────────────────┐
  │                 ARBITRUM ONE NETWORK                   │
  │ ┌────────────────────────────────────────────────────┐ │
  │ │               VALVE CORE PROTOCOL                  │ │
  │ │   - ValveRegistry: stream creation & accounting    │ │
  │ │   - ValveVault: escrow & settlement                │ │
  │ │   - OpenZeppelin ERC20 & safeguards                │ │
  │ └────────────────────────────────────────────────────┘ │
  └──────────────────────────┬─────────────────────────────┘
                             │
                             ▼
  ┌────────────────────────────────────────────────────────┐
  │                 INDEXING & ANALYTICS                   │
  │          Dune Analytics Dashboards                     │
  └────────────────────────────────────────────────────────┘
```

---

## Stack & Specs

| Layer                      | Technology                                              | Purpose                                                               |
| -------------------------- | ------------------------------------------------------- | --------------------------------------------------------------------- |
| Blockchain                 | [Arbitrum One](https://arbitrum.io/)                     | Layer-2 with ultra-low fees that make per-second micro-billing viable |
| Smart Contracts            | Solidity +[OpenZeppelin](https://docs.openzeppelin.com/) | Secure ERC20 and access-control primitives                            |
| Node Infrastructure        | [Alchemy](https://docs.alchemy.com)                      | Reliable RPC access and transaction bundling                          |
| Account Abstraction & Auth | [ZeroDev](https://docs.zerodev.app/)                     | Social logins, WebAuthn passkeys and gasless session keys             |
| Analytics                  | [Dune Analytics](https://dune.com)                       | Dashboards for subscription metrics and cash flows                    |
| Frontend                   | React.js                                                | On/off toggle dashboard                                               |
| Testing                    | Foundry                                                 | Unit and fuzz tests                                                   |

---

## Folder Structure

```
valve-protocol/
├── apps/
│   └── frontend/                      # React.js dashboard
│       ├── app/
│       │   ├── layout.tsx             # Root layout + providers
│       │   ├── page.tsx               # Landing / login
│       │   ├── dashboard/
│       │   │   └── page.tsx           # Subscription toggle panel
│       │   └── provider/
│       │       └── page.tsx           # Service provider view (earnings, active streams)
│       ├── components/
│       │   ├── StreamToggle.tsx       # On/Off valve switch
│       │   ├── SubscriptionCard.tsx   # Service name, rate, live accrued cost
│       │   ├── LiveCounter.tsx        # Per-second cost ticker
│       │   └── LoginButton.tsx        # Social / passkey login
│       ├── hooks/
│       │   ├── useZeroDevAccount.ts   # Passkey smart account + session keys
│       │   ├── useStreams.ts          # Read active streams from Registry
│       │   └── useToggleStream.ts     # Open / close a stream
│       ├── lib/
│       │   ├── zerodev.ts             # ZeroDev kernel client setup
│       │   ├── chains.ts              # Arbitrum One + Arbitrum Sepolia config
│       │   ├── contracts.ts           # Addresses + typed contract instances
│       │   └── abis/                  # ABIs exported from Foundry builds
│       │       ├── ValveRegistry.json
│       │       └── ValveVault.json
│       ├── public/
│       ├── .env.example
│       ├── vite.config.js
│       ├── package.json
│       └── tsconfig.json
│
├── contracts/
│   ├── src/
│   │   ├── ValveRegistry.sol          # Stream creation, rate math, accrual accounting
│   │   ├── ValveVault.sol             # Escrow + settlement to providers
│   │   ├── interfaces/
│   │   │   ├── IValveRegistry.sol
│   │   │   └── IValveVault.sol
│   │   └── libraries/
│   │       └── StreamMath.sol         # rate × elapsed time helpers
│   ├── script/
│   │   ├── Deploy.s.sol               # Deploy Registry + Vault
│   │   └── Seed.s.sol                 # Demo providers / sample streams for the pitch
│   ├── test/
│   │   ├── ValveRegistry.t.sol        # Unit tests
│   │   ├── ValveVault.t.sol
│   │   ├── fuzz/
│   │   │   └── StreamMath.fuzz.t.sol  # Linear-time fuzz tests
│   │   ├── invariant/
│   │   │   └── Valve.invariant.t.sol  # e.g. provider can never pull more than accrued
│   │   └── mocks/
│   │       └── MockUSDC.sol           # Test token for Sepolia demo
│   ├── lib/                           # OpenZeppelin + forge-std (via forge install)
│   ├── foundry.toml
│   ├── remappings.txt
│   └── .env.example
│
├── dashboards/
│   └── dune/
│       ├── active_streams.sql
│       ├── total_volume.sql
│       └── README.md                  # Link to the live Dune dashboard
│
├── .github/
│   └── workflows/
│       └── test.yml                   # Runs forge test on every PR
│
├── .gitignore
├── LICENSE
└── README.md
```

---

## Development and Testing

Smart contracts are written, compiled and tested with [Foundry](https://book.getfoundry.sh/).

### Prerequisites

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Installation

```bash
git clone https://github.com/teewa56/valve.git
cd valve/contracts
forge install OpenZeppelin/openzeppelin-contracts
```

### Running Tests

Run unit and linear-time fuzz tests:

```bash
forge test -vvv
```

---

## Config

Create a `.env` file in root:

```env
# Network Routing
ARBITRUM_RPC_URL=https://arb-mainnet.g.alchemy.com/v2/<your-alchemy-api-key>
PRIVATE_KEY=0x...

# Account Abstraction
ZERODEV_PROJECT_ID=your-zerodev-project-id
```

> Never commit your `.env` file or private keys. Use a testnet wallet for development.

---

## Contributions

Contributions are welcome! Fork the repository, create a descriptive feature branch (e.g. `feature/stream-settlement-fuzz-tests`), and open a Pull Request against `main` for review.
