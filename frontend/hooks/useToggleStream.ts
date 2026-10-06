import { useState } from 'react'
import { createPublicClient, encodeFunctionData, http, parseUnits, type Address, type Hash } from 'viem'
import { chainConfig, frontendConfig, RATE_SCALE, SECONDS_PER_MONTH } from '../lib/chains'
import { ValveRegistryAbi, usdcAbi } from '../lib/contracts'
import { useZeroDevAccount } from './useZeroDevAccount'

type CreateStreamArgs = { provider: Address; monthlyUsdc: string; maxUsdc: string }
type Call = { to: Address; value: bigint; data: `0x${string}` }

function actionErrorMessage(cause: unknown, fallback: string) {
  const message = cause instanceof Error ? cause.message : ''
  if (message.includes('0x969bf728') || message.includes('NothingToClaim')) {
    return 'The claim transferred no USDC. If accrued is above $0, the payer may need USDC in their wallet or more allowance for the Valve Vault. Ask them to check their balance and allowance, then retry.'
  }
  return message || fallback
}

export function useToggleStream() {
  const { address, client } = useZeroDevAccount()
  const [isPending, setIsPending] = useState(false)
  const [txHash, setTxHash] = useState<Hash>()
  const [error, setError] = useState<string>()

  async function submit(calls: Call[]) {
    if (!client) throw new Error('Connect the passkey account before sending transactions.')
    setError(undefined)
    setTxHash(undefined)
    setIsPending(true)
    try {
      const hash = await client.sendTransaction({ calls })
      setTxHash(hash)
      return hash
    } catch (cause) {
      setError(actionErrorMessage(cause, 'The user operation failed.'))
      throw cause
    } finally {
      setIsPending(false)
    }
  }

  async function createStream({ provider, monthlyUsdc, maxUsdc }: CreateStreamArgs) {
    if (!frontendConfig.registryAddress || !frontendConfig.vaultAddress) throw new Error('Configure the Registry and Vault proxy addresses first.')
    try {
      const cap = parseUnits(maxUsdc, 6)
      const monthlyAmount = parseUnits(monthlyUsdc, 6)
      if (cap <= 0n || monthlyAmount <= 0n) throw new Error('Rate and spend cap must be greater than zero.')
      if (!address) throw new Error('Connect the passkey account before creating a stream.')
      if (provider.toLowerCase() === address.toLowerCase()) {
        throw new Error('Provider address must be different from your payer address.')
      }
      const ratePerSecondX18 = monthlyAmount * RATE_SCALE / BigInt(SECONDS_PER_MONTH)
      const publicClient = createPublicClient({ chain: chainConfig, transport: http(frontendConfig.rpcUrl) })
      const currentAllowance = await publicClient.readContract({ address: frontendConfig.usdcAddress, abi: usdcAbi, functionName: 'allowance', args: [address, frontendConfig.vaultAddress] })
      return await submit([
        { to: frontendConfig.usdcAddress, value: 0n, data: encodeFunctionData({ abi: usdcAbi, functionName: 'approve', args: [frontendConfig.vaultAddress, currentAllowance + cap] }) },
        { to: frontendConfig.registryAddress, value: 0n, data: encodeFunctionData({ abi: ValveRegistryAbi, functionName: 'createStream', args: [provider, ratePerSecondX18, cap] }) },
      ])
    } catch (cause) {
      setError(actionErrorMessage(cause, 'Could not create the stream.'))
      return undefined
    }
  }

  async function cancelStream(streamId: bigint) {
    if (!frontendConfig.registryAddress) throw new Error('Registry address is not configured.')
    try {
      return await submit([
        { to: frontendConfig.registryAddress, value: 0n, data: encodeFunctionData({ abi: ValveRegistryAbi, functionName: 'cancelStream', args: [streamId] }) },
      ])
    } catch {
      return undefined
    }
  }

  async function claimStream(streamId: bigint) {
    if (!frontendConfig.registryAddress) throw new Error('Registry address is not configured.')
    try {
      return await submit([{ to: frontendConfig.registryAddress, value: 0n, data: encodeFunctionData({ abi: ValveRegistryAbi, functionName: 'claim', args: [streamId] }) }])
    } catch {
      return undefined
    }
  }

  return { createStream, cancelStream, claimStream, isPending, txHash, error }
}
