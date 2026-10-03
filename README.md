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

| | Web2 (Legacy) | Valve |
|---|---|---|
| Upfront cost | $30.00 | $0.00 |
| Cancellation | Remember to cancel, navigate churn surveys | One toggle |
| Final cost | $30.00 | **$2.00** (48 hrs of streaming) |
| Funds left in wallet | $0.00 | **$28.00**, untouched |

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
  │     Next.js Dashboard + ZeroDev Passkey Account        │
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

| Layer | Technology | Purpose |
|---|---|---|
| Blockchain | [Arbitrum One](https://arbitrum.io/) | Layer-2 with ultra-low fees that make per-second micro-billing viable |
| Smart Contracts | Solidity + [OpenZeppelin](https://docs.openzeppelin.com/) | Secure ERC20 and access-control primitives |
| Node Infrastructure | [Alchemy](https://docs.alchemy.com) | Reliable RPC access and transaction bundling |
| Account Abstraction & Auth | [ZeroDev](https://docs.zerodev.app/) | Social logins, WebAuthn passkeys and gasless session keys |
| Analytics | [Dune Analytics](https://dune.com) | Dashboards for subscription metrics and cash flows |
| Frontend | Next.js | On/off toggle dashboard |
| Testing | Foundry | Unit and fuzz tests |

---

## Folder Structure

```
valve-protocol/
├── apps/
│   └── frontend/              # Next.js web application dashboard
│       ├── components/        # On/Off UI toggle components
│       └── hooks/             # ZeroDev account abstraction hooks
├── contracts/
│   ├── src/                   # Solidity smart contracts
│   │   ├── ValveRegistry.sol  # Core stream registry
│   │   └── ValveVault.sol     # Escrow management
│   ├── lib/                   # OpenZeppelin dependencies
│   └── test/                  # Foundry unit and fuzz tests
├── dashboards/
│   └── dune/                  # SQL queries for Dune dashboards
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
git clone https://github.com/<your-username>/valve-protocol.git
cd valve-protocol/contracts
forge install OpenZeppelin/openzeppelin-contracts
```

### Running Tests

Run unit and linear-time fuzz tests:

```bash
forge test -vvv
```

---

## Config

Create a `.env` file in both `contracts/` and `apps/frontend/`:

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

Contributions are welcome! Fork the repository, create a descriptive feature branch (e.g. `feature/stream-settlement-fuzz-tests`), and open a Pull Request against `main` for review during the Arbitrum Open House hackathon timeline.