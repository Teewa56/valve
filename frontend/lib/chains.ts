import type { Address } from 'viem'
import { arbitrumSepolia } from 'viem/chains'

const env = import.meta.env

export const chainConfig = arbitrumSepolia
export const SECONDS_PER_MONTH = 30 * 24 * 60 * 60
export const RATE_SCALE = 10n ** 18n

function configuredAddress(value: string | undefined): Address | undefined {
  return value && /^0x[a-fA-F0-9]{40}$/.test(value) ? value as Address : undefined
}

export const frontendConfig = {
  rpcUrl: env.VITE_ARBITRUM_SEPOLIA_RPC_URL || 'https://sepolia-rollup.arbitrum.io/rpc',
  projectId: env.VITE_ZERODEV_PROJECT_ID || '',
  passkeyServerUrl: env.VITE_PASSKEY_SERVER_URL || '',
  registryAddress: configuredAddress(env.VITE_VALVE_REGISTRY_ADDRESS),
  vaultAddress: configuredAddress(env.VITE_VALVE_VAULT_ADDRESS),
  usdcAddress: configuredAddress(env.VITE_USDC_ADDRESS) ?? '0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d' as Address,
  get isWalletConfigured() {
    return Boolean(this.projectId && this.passkeyServerUrl && this.registryAddress && this.vaultAddress)
  },
}

export function getZeroDevRpc(projectId: string, chainId: number) {
  return `https://rpc.zerodev.app/api/v3/${projectId}/chain/${chainId}`
}