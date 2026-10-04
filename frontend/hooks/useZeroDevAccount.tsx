import { createContext, useContext, useState, type ReactNode } from 'react'
import { createKernelAccount } from '@zerodev/sdk/accounts'
import { createKernelAccountClient, createZeroDevPaymasterClient } from '@zerodev/sdk/clients'
import { getEntryPoint, KERNEL_V3_3 } from '@zerodev/sdk/constants'
import { PasskeyValidatorContractVersion, toPasskeyValidator, toWebAuthnKey, WebAuthnMode } from '@zerodev/passkey-validator'
import { createPublicClient, http, type Address } from 'viem'
import { arbitrumSepolia } from 'viem/chains'
import { frontendConfig, getZeroDevRpc } from '../lib/chains'

type AccountClient = ReturnType<typeof createKernelAccountClient>
type AccountContextValue = {
  address?: Address
  client?: AccountClient
  isBusy: boolean
  isConfigured: boolean
  error?: string
  connect: () => Promise<void>
  disconnect: () => void
}

const AccountContext = createContext<AccountContextValue | undefined>(undefined)
const ACCOUNT_STORAGE_KEY = 'valve.passkey.account'

export function ZeroDevProvider({ children }: { children: ReactNode }) {
  const [address, setAddress] = useState<Address>()
  const [client, setClient] = useState<AccountClient>()
  const [isBusy, setIsBusy] = useState(false)
  const [error, setError] = useState<string>()
  const isConfigured = frontendConfig.isWalletConfigured

  async function createAccount(mode: WebAuthnMode) {
    const publicClient = createPublicClient({ chain: arbitrumSepolia, transport: http(frontendConfig.rpcUrl) })
    const webAuthnKey = await toWebAuthnKey({ mode, rpID: window.location.hostname, passkeyName: 'Valve account', passkeyServerUrl: frontendConfig.passkeyServerUrl })
    const entryPoint = getEntryPoint('0.7')
    const validator = await toPasskeyValidator(publicClient, {
      webAuthnKey,
      entryPoint,
      kernelVersion: KERNEL_V3_3,
      validatorContractVersion: PasskeyValidatorContractVersion.V0_0_3_PATCHED,
    })
    const account = await createKernelAccount(publicClient, {
      plugins: { sudo: validator },
      entryPoint,
      kernelVersion: KERNEL_V3_3,
    })
    const zerodevRpcUrl = getZeroDevRpc(frontendConfig.projectId, arbitrumSepolia.id)
    const paymaster = createZeroDevPaymasterClient({ chain: arbitrumSepolia, transport: http(zerodevRpcUrl) })
    const accountClient = createKernelAccountClient({
      account,
      chain: arbitrumSepolia,
      client: publicClient,
      bundlerTransport: http(zerodevRpcUrl),
      paymaster: {
        getPaymasterData: (parameters) => paymaster.getPaymasterData(parameters),
        getPaymasterStubData: (parameters) => paymaster.getPaymasterStubData(parameters),
      },
    })
    return { address: account.address, client: accountClient }
  }

  async function connect() {
    if (!isConfigured) {
      setError('Set VITE_ZERODEV_PROJECT_ID, VITE_PASSKEY_SERVER_URL, and the Valve proxy addresses in frontend/.env first.')
      return
    }
    setError(undefined)
    setIsBusy(true)
    try {
      const savedAddress = window.localStorage.getItem(ACCOUNT_STORAGE_KEY)
      const account = await createAccount(savedAddress ? WebAuthnMode.Login : WebAuthnMode.Register)
      if (savedAddress && account.address.toLowerCase() !== savedAddress.toLowerCase()) {
        throw new Error('That passkey resolved to a different account. Disconnect and register a new account to continue.')
      }
      window.localStorage.setItem(ACCOUNT_STORAGE_KEY, account.address)
      setAddress(account.address)
      setClient(account.client)
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'Passkey account setup failed.')
    } finally {
      setIsBusy(false)
    }
  }

  function disconnect() {
    window.localStorage.removeItem(ACCOUNT_STORAGE_KEY)
    setAddress(undefined)
    setClient(undefined)
    setError(undefined)
  }

  return <AccountContext.Provider value={{ address, client, isBusy, isConfigured, error, connect, disconnect }}>{children}</AccountContext.Provider>
}

export function useZeroDevAccount() {
  const context = useContext(AccountContext)
  if (!context) throw new Error('useZeroDevAccount must be used inside ZeroDevProvider')
  return context
}