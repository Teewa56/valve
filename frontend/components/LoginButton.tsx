import { Fingerprint, LoaderCircle, LogOut } from 'lucide-react'
import { useZeroDevAccount } from '../hooks/useZeroDevAccount'

type LoginButtonProps = { compact?: boolean; connectedAddress?: `0x${string}` }

export function LoginButton({ compact = false, connectedAddress }: LoginButtonProps) {
  const account = useZeroDevAccount()
  const address = connectedAddress ?? account.address

  if (address) return <button className={compact ? 'wallet-chip' : 'button button-connected'} onClick={account.disconnect} title="Disconnect this passkey account">
    <span className="wallet-status" />{`${address.slice(0, 6)}…${address.slice(-4)}`}<LogOut size={14} />
  </button>

  return <button className={compact ? 'button button-top-login' : 'button button-primary'} disabled={account.isBusy || !account.isConfigured} onClick={() => void account.connect()}>
    {account.isBusy ? <LoaderCircle className="spin" size={16} /> : <Fingerprint size={17} />}
    {account.isBusy ? account.isRestoring ? 'Restoring account…' : 'Opening passkey…' : compact ? 'Connect' : 'Continue with passkey'}
  </button>
}
