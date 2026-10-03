## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy to Arbitrum Sepolia

Copy `.env.example` to `.env` and set the real Arbitrum Sepolia RPC URL and the live USDC contract address for the network:

```bash
cp .env.example .env
```

Then deploy:

```shell
$ forge script script/DeployValve.s.sol --rpc-url $ARBITRUM_SEPOLIA_RPC_URL --broadcast
```

The contract accepts a token address at runtime, so the active subscription token can be set to the real USDC contract on Arbitrum Sepolia rather than a mock or local stub.

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
