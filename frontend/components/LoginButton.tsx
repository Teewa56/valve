import { useState } from 'react'
import { Check, Copy, Fingerprint, LoaderCircle, LogOut } from 'lucide-react'
import { useZeroDevAccount } from '../hooks/useZeroDevAccount'

type LoginButtonProps = { compact?: boolean; connectedAddress?: `0x${string}` }

export function LoginButton({ compact = false, connectedAddress }: LoginButtonProps) {
  const account = useZeroDevAccount()
  const address = connectedAddress ?? account.address
  const [copied, setCopied] = useState(false)

  async function copyAddress() {
    if (!address) return
    try {
      await navigator.clipboard.writeText(address)
      setCopied(true)
      window.setTimeout(() => setCopied(false), 1600)
    } catch {
      setCopied(false)
    }
  }

  if (address) return <div className={`wallet-control${compact ? ' compact' : ''}`}>
    <button className="wallet-chip" onClick={() => void copyAddress()} title={copied ? 'Address copied' : 'Copy wallet address'} aria-label={copied ? 'Wallet address copied' : `Copy wallet address ${address}`}>
      <span className="wallet-status" />{`${address.slice(0, 6)}…${address.slice(-4)}`}{copied ? <Check size={14} /> : <Copy size={14} />}
    </button>
    <button className="wallet-disconnect" onClick={account.disconnect} title="Disconnect this passkey account" aria-label="Disconnect this passkey account"><LogOut size={14} /></button>
    <span className="sr-only" aria-live="polite">{copied ? 'Wallet address copied to clipboard' : ''}</span>
  </div>

  return <button className={compact ? 'button button-top-login' : 'button button-primary'} disabled={account.isBusy || !account.isConfigured} onClick={() => void account.connect()}>
    {account.isBusy ? <LoaderCircle className="spin" size={16} /> : <Fingerprint size={17} />}
    {account.isBusy ? account.isRestoring ? 'Restoring account…' : 'Opening passkey…' : compact ? 'Connect' : 'Continue with passkey'}
  </button>
}
