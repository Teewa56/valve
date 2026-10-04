import type { Address } from 'viem'
import registryAbiJson from './abis/ValveRegistry.json'
import vaultAbiJson from './abis/ValveVault.json'

export const ValveRegistryAbi = registryAbiJson
export const ValveVaultAbi = vaultAbiJson

export const usdcAbi = [
  { type: 'function', name: 'approve', stateMutability: 'nonpayable', inputs: [{ name: 'spender', type: 'address' }, { name: 'amount', type: 'uint256' }], outputs: [{ name: '', type: 'bool' }] },
  { type: 'function', name: 'allowance', stateMutability: 'view', inputs: [{ name: 'owner', type: 'address' }, { name: 'spender', type: 'address' }], outputs: [{ name: '', type: 'uint256' }] },
] as const

export type StreamView = {
  id: bigint
  payer: Address
  provider: Address
  ratePerSecondX18: bigint
  maxAmount: bigint
  claimed: bigint
  accrued: bigint
  active: boolean
}

export function formatUsdc(amount: bigint, maximumFractionDigits = 4) {
  const whole = amount / 1_000_000n
  const remainder = amount % 1_000_000n
  const fraction = remainder.toString().padStart(6, '0').slice(0, maximumFractionDigits).replace(/0+$/, '')
  return `$${whole.toLocaleString('en-US')}${fraction ? `.${fraction}` : ''}`
}

export function shortenAddress(address: Address) {
  return `${address.slice(0, 6)}…${address.slice(-4)}`
}