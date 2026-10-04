import { useState, type FormEvent } from 'react'
import { ArrowDown, ArrowUpRight, CircleHelp, Plus, RefreshCw } from 'lucide-react'
import { LoginButton } from '../../components/LoginButton'
import { StreamToggle } from '../../components/StreamToggle'
import { SubscriptionCard } from '../../components/SubscriptionCard'
import { useStreams } from '../../hooks/useStreams'
import { useToggleStream } from '../../hooks/useToggleStream'
import { useZeroDevAccount } from '../../hooks/useZeroDevAccount'
import { formatUsdc, shortenAddress } from '../../lib/contracts'

export function DashboardPage() {
  const { address, isConfigured } = useZeroDevAccount()
  const { streams, isLoading, error, refresh } = useStreams('payer')
  const { createStream, cancelStream, isPending, txHash, error: actionError } = useToggleStream()
  const [showForm, setShowForm] = useState(false)
  const [provider, setProvider] = useState('')
  const [monthlyRate, setMonthlyRate] = useState('30')
  const [cap, setCap] = useState('30')

  const accrued = streams.reduce((total, stream) => total + stream.accrued, 0n)
  const activeCount = streams.filter((stream) => stream.active).length

  async function submitStream(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    const hash = await createStream({ provider: provider as `0x${string}`, monthlyUsdc: monthlyRate, maxUsdc: cap })
    if (hash) {
      await refresh()
      setShowForm(false)
      setProvider('')
    }
  }

  return (
    <div className="dashboard-page">
      <div className="page-heading-row">
        <div><div className="eyebrow">YOUR CONTROL PANEL</div><h1>Subscriptions</h1><p className="page-lede">Your services, your spend, your switch.</p></div>
        <button className="button button-primary" onClick={() => setShowForm((visible) => !visible)} disabled={!address || isPending}><Plus size={17} /> New stream</button>
      </div>
      <section className="summary-strip" aria-label="Subscription summary">
        <div className="summary-cell"><span>ACTIVE STREAMS</span><strong>{address ? activeCount.toString().padStart(2, '0') : '—'}</strong><small>currently running</small></div>
        <div className="summary-cell"><span>ACCRUED SO FAR</span><strong>{address ? formatUsdc(accrued) : '—'}</strong><small>earned by providers</small></div>
        <div className="summary-cell summary-cell-status"><span>NETWORK</span><strong><i className="network-dot" /> Arbitrum Sepolia</strong><small>USDC · 6 decimals</small></div>
        <button className="refresh-button" onClick={() => void refresh()} aria-label="Refresh streams" title="Refresh streams"><RefreshCw size={16} /></button>
      </section>
      {!address && <section className="empty-state connect-state"><div className="empty-symbol"><CircleHelp size={21} /></div><div><h2>Connect your passkey account</h2><p>Sign in with a device passkey to view or manage streams for that smart account.</p></div><LoginButton /></section>}
      {address && showForm && <form className="stream-form" onSubmit={(event) => void submitStream(event)}>
        <div className="form-heading"><div><span className="eyebrow">START A SUBSCRIPTION</span><h2>Open a new stream</h2></div><button type="button" className="icon-button close-form" aria-label="Close form" onClick={() => setShowForm(false)}>×</button></div>
        <label>Provider wallet address<input required pattern="^0x[a-fA-F0-9]{40}$" placeholder="0x…" value={provider} onChange={(event) => setProvider(event.target.value)} /></label>
        <div className="form-pair"><label>Monthly rate <span>USDC / month</span><input required min="0.01" step="0.01" type="number" value={monthlyRate} onChange={(event) => setMonthlyRate(event.target.value)} /></label><label>Maximum spend <span>USDC total cap</span><input required min="0.01" step="0.01" type="number" value={cap} onChange={(event) => setCap(event.target.value)} /></label></div>
        <p className="form-note">Only earned USDC is transferred. Approve the maximum cap; settlement never exceeds that limit.</p>
        <button className="button button-primary" disabled={isPending || !isConfigured}>{isPending ? 'Confirming…' : 'Approve cap & start stream'} <ArrowUpRight size={16} /></button>
      </form>}
      <div className="list-toolbar"><div><h2>My streams</h2><span>{address ? shortenAddress(address) : 'Wallet not connected'}</span></div><div className="list-controls"><span className="sort-label"><ArrowDown size={13} /> RECENT FIRST</span></div></div>
      {error && <div className="inline-error" role="alert">{error}</div>}
      {actionError && <div className="inline-error" role="alert">{actionError}</div>}
      {txHash && <a className="transaction-link" href={`https://sepolia.arbiscan.io/tx/${txHash}`} target="_blank" rel="noreferrer">View latest transaction on Arbiscan <ArrowUpRight size={14} /></a>}
      {isLoading && <div className="loading-line"><span className="loading-pulse" /> Reading the Registry…</div>}
      {address && !isLoading && streams.length === 0 && <section className="empty-state"><div className="empty-symbol"><Plus size={21} /></div><div><h2>No streams yet</h2><p>Create one with a provider address, monthly rate, and total spend cap.</p></div><button className="button button-outline" onClick={() => setShowForm(true)}><Plus size={16} /> New stream</button></section>}
      <div className="stream-list">{streams.map((stream) => <SubscriptionCard key={stream.id.toString()} stream={stream} action={<StreamToggle active={stream.active} disabled={isPending} onToggle={() => void cancelStream(stream.id).then((hash) => hash && refresh())} />} />)}</div>
      {streams.length >= 250 && <p className="list-limit">Showing the latest 250 streams. Older history is available on Arbiscan.</p>}
      <div className="privacy-note"><span className="note-rule" />Switching off freezes this stream immediately. The shared Vault allowance remains available to your other active streams.</div>
    </div>
  )
}