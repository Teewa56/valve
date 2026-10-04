import { useCallback, useEffect, useState } from 'react'
import { createPublicClient, http } from 'viem'
import { chainConfig, frontendConfig } from '../lib/chains'
import { ValveRegistryAbi, ValveVaultAbi, type StreamView } from '../lib/contracts'
import { useZeroDevAccount } from './useZeroDevAccount'

type StreamRole = 'payer' | 'provider'

export function useStreams(role: StreamRole) {
  const { address } = useZeroDevAccount()
  const [streams, setStreams] = useState<StreamView[]>([])
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string>()

  const refresh = useCallback(async () => {
    if (!frontendConfig.registryAddress || !frontendConfig.vaultAddress || !address) {
      setStreams([])
      return
    }
    setIsLoading(true)
    setError(undefined)
    try {
      const publicClient = createPublicClient({ chain: chainConfig, transport: http(frontendConfig.rpcUrl) })
      const { registryAddress, vaultAddress } = frontendConfig
      const nextId = await publicClient.readContract({ address: registryAddress, abi: ValveRegistryAbi, functionName: 'nextStreamId' })
      const firstId = nextId > 250n ? nextId - 249n : 1n
      const ids = Array.from({ length: Number(nextId - firstId + 1n) }, (_, index) => firstId + BigInt(index))
      const results = await Promise.all(ids.map(async (id) => {
        try {
          const [stream, accrued, vaultStream] = await Promise.all([
            publicClient.readContract({ address: registryAddress, abi: ValveRegistryAbi, functionName: 'getStream', args: [id] }),
            publicClient.readContract({ address: registryAddress, abi: ValveRegistryAbi, functionName: 'accruedAmount', args: [id] }),
            publicClient.readContract({ address: vaultAddress, abi: ValveVaultAbi, functionName: 'streams', args: [id] }),
          ])
          return { id, payer: stream.payer, provider: stream.provider, ratePerSecondX18: stream.ratePerSecondX18, maxAmount: stream.maxAmount, claimed: vaultStream.settledAmount, accrued, active: stream.active } satisfies StreamView
        } catch {
          return undefined
        }
      }))
      const matched = results.filter((stream): stream is StreamView => stream !== undefined && (
        role === 'payer' ? stream.payer.toLowerCase() === address.toLowerCase() : stream.provider.toLowerCase() === address.toLowerCase()
      ))
      setStreams(matched.reverse())
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'Could not read streams from the Registry.')
    } finally {
      setIsLoading(false)
    }
  }, [address, role])

  useEffect(() => {
    void refresh()
    if (!address) return
    const interval = window.setInterval(() => void refresh(), 15_000)
    return () => window.clearInterval(interval)
  }, [address, refresh])

  return { streams, isLoading, error, refresh }
}