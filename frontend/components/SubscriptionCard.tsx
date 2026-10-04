import { ArrowUpRight, CircleDollarSign } from 'lucide-react'
import type { ReactNode } from 'react'
import { LiveCounter } from './LiveCounter'
import { formatUsdc, shortenAddress, type StreamView } from '../lib/contracts'

type SubscriptionCardProps = { stream: StreamView; action: ReactNode }

export function SubscriptionCard({ stream, action }: SubscriptionCardProps) {
  const monthlyRate = stream.ratePerSecondX18 * 30n * 24n * 60n * 60n / 10n ** 18n
  return <article className={`subscription-row${stream.active ? '' : ' is-stopped'}`}>
    <div className="subscription-service-icon"><CircleDollarSign size={19} /></div>
    <div className="subscription-main"><div className="subscription-title"><strong>Stream #{stream.id.toString().padStart(4, '0')}</strong><span className={`state-label${stream.active ? ' state-live' : ''}`}><i />{stream.active ? 'LIVE' : 'OFF'}</span></div><a href={`https://sepolia.arbiscan.io/address/${stream.provider}`} target="_blank" rel="noreferrer">{shortenAddress(stream.provider)} <ArrowUpRight size={12} /></a></div>
    <div className="subscription-rate"><small>MONTHLY RATE</small><strong>{formatUsdc(monthlyRate)}</strong></div>
    <div className="subscription-accrued"><small>ACCRUED</small><strong><LiveCounter accrued={stream.accrued} maxAmount={stream.maxAmount - stream.claimed} ratePerSecondX18={stream.ratePerSecondX18} running={stream.active} /></strong><span>of {formatUsdc(stream.maxAmount)} cap</span></div>
    <div className="subscription-action">{action}</div>
  </article>
}