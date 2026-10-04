#!/usr/bin/env bash
set -euo pipefail

# Some Linux distributions install an unrelated `forge` executable in /usr/bin.
# Prefer Foundry's standard per-user installation when it is available.
if [[ -x "$HOME/.foundry/bin/forge" ]]; then
    export PATH="$HOME/.foundry/bin:$PATH"
fi

# Run from the contracts directory after Deploy.s.sol has been broadcast.
# Reads implementation and proxy constructor data from Foundry's latest broadcast record.
chain_id=421614
broadcast_file="broadcast/Deploy.s.sol/${chain_id}/run-latest.json"

if [[ ! -f "$broadcast_file" ]]; then
    echo "Missing $broadcast_file. Run the deployment script with --broadcast first." >&2
    exit 1
fi
if [[ -z "${ARBISCAN_API_KEY:-}" ]]; then
    echo "Set ARBISCAN_API_KEY to your Arbiscan API key before verifying." >&2
    exit 1
fi
command -v jq >/dev/null || { echo "jq is required to read the broadcast record." >&2; exit 1; }

transactions="$(jq -c '.transactions[] | select(.transactionType == "CREATE")' "$broadcast_file")"
vault_impl="$(jq -r 'select(.contractName == "ValveVault") | .contractAddress' <<<"$transactions")"
registry_impl="$(jq -r 'select(.contractName == "ValveRegistry") | .contractAddress' <<<"$transactions")"
mapfile -t proxies < <(jq -c 'select(.contractName == "ERC1967Proxy")' <<<"$transactions")
if [[ "${#proxies[@]}" -ne 2 ]]; then
    echo "Expected two ERC1967Proxy deployments in $broadcast_file." >&2
    exit 1
fi
vault_proxy="$(jq -r '.contractAddress' <<<"${proxies[0]}")"
registry_proxy="$(jq -r '.contractAddress' <<<"${proxies[1]}")"

verify() {
    local contract="$1" address="$2" constructor_args="${3:-}"
    local args=("$contract" --chain-id "$chain_id" --verifier etherscan --etherscan-api-key "$ARBISCAN_API_KEY" --watch)
    if [[ -n "$constructor_args" ]]; then args+=(--constructor-args "$constructor_args"); fi
    forge verify-contract "$address" "${args[@]}"
}

# Implementations have no constructor arguments.
verify src/ValveVault.sol:ValveVault "$vault_impl"
verify src/ValveRegistry.sol:ValveRegistry "$registry_impl"

# Proxy constructor arguments are (implementation, initializer calldata), recorded by Forge.
vault_args="$(cast abi-encode 'constructor(address,bytes)' "$(jq -r '.arguments[0]' <<<"${proxies[0]}")" "$(jq -r '.arguments[1]' <<<"${proxies[0]}")")"
registry_args="$(cast abi-encode 'constructor(address,bytes)' "$(jq -r '.arguments[0]' <<<"${proxies[1]}")" "$(jq -r '.arguments[1]' <<<"${proxies[1]}")")"

verify lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy "$vault_proxy" "$vault_args"
verify lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy "$registry_proxy" "$registry_args"
