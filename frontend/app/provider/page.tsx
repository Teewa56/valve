import { ArrowUpRight, CircleDollarSign, RefreshCw } from 'lucide-react'
import { LoginButton } from '../../components/LoginButton'
import { useStreams } from '../../hooks/useStreams'
import { useToggleStream } from '../../hooks/useToggleStream'
import { useZeroDevAccount } from '../../hooks/useZeroDevAccount'
import { formatUsdc, shortenAddress } from '../../lib/contracts'

export function ProviderPage() {
  const { address } = useZeroDevAccount()
  const { streams, isLoading, error, refresh } = useStreams('provider')
  const { claimStream, isPending, txHash, error: actionError } = useToggleStream()
  const totalAccrued = streams.reduce((total, stream) => total + stream.accrued, 0n)
  const totalClaimed = streams.reduce((total, stream) => total + stream.claimed, 0n)

  return (
    <div className="dashboard-page provider-page">
      <div className="page-heading-row"><div><div className="eyebrow">SERVICE PROVIDER</div><h1>Provider view</h1><p className="page-lede">Accrual follows usage. Claims are yours to initiate.</p></div><button className="icon-button refresh-icon" onClick={() => void refresh()} title="Refresh earnings" aria-label="Refresh earnings"><RefreshCw size={16} /></button></div>
      <section className="summary-strip provider-summary">
        <div className="summary-cell"><span>UNCLAIMED</span><strong>{address ? formatUsdc(totalAccrued) : '—'}</strong><small>available to claim</small></div>
        <div className="summary-cell"><span>CLAIMED</span><strong>{address ? formatUsdc(totalClaimed) : '—'}</strong><small>paid directly to wallet</small></div>
        <div className="summary-cell"><span>ACTIVE PAYERS</span><strong>{address ? streams.filter((stream) => stream.active).length.toString().padStart(2, '0') : '—'}</strong><small>live streams</small></div>
      </section>
      {!address && <section className="empty-state connect-state"><div className="empty-symbol"><CircleDollarSign size={21} /></div><div><h2>Connect your provider account</h2><p>Use the provider wallet tied to your streams to see accruals and claim USDC.</p></div><LoginButton /></section>}
      {error && <div className="inline-error" role="alert">{error}</div>}
      {actionError && <div className="inline-error" role="alert">{actionError}</div>}
      {txHash && <a className="transaction-link" href={`https://sepolia.arbiscan.io/tx/${txHash}`} target="_blank" rel="noreferrer">View latest transaction on Arbiscan <ArrowUpRight size={14} /></a>}
      <div className="list-toolbar"><div><h2>Incoming streams</h2><span onClick={() => address && navigator.clipboard.writeText(address)}>{address ? shortenAddress(address) : 'Wallet not connected'}</span></div></div>
      {isLoading && <div className="loading-line"><span className="loading-pulse" /> Reading provider streams…</div>}
      {address && !isLoading && streams.length === 0 && <section className="empty-state"><div className="empty-symbol"><CircleDollarSign size={21} /></div><div><h2>No incoming streams</h2><p>Streams addressed to this wallet appear here when a payer turns one on.</p></div></section>}
      <div className="provider-stream-list">{streams.map((stream) => <article className="provider-row" key={stream.id.toString()}>
        <div className="provider-service-avatar">V</div>
        <div className="provider-stream-info"><strong>Stream #{stream.id.toString().padStart(4, '0')}</strong><span>From {shortenAddress(stream.payer)} · {stream.active ? 'Running' : 'Stopped'}</span></div>
        <div className="provider-stream-earned"><small>ACCRUED</small><strong>{formatUsdc(stream.accrued)}</strong></div>
        <button className="button button-outline claim-button" disabled={isPending || stream.accrued === 0n} onClick={() => void claimStream(stream.id).then((hash) => hash && refresh())}>{isPending ? 'Claiming…' : 'Claim'} <ArrowUpRight size={14} /></button>
      </article>)}</div>
      <div className="privacy-note"><span className="note-rule" />Claim transactions transfer only the amount already accrued under the payer’s cap.</div>
    </div>
  )
}