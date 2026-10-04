import { useEffect, useState } from 'react'
import { RATE_SCALE } from '../lib/chains'
import { formatUsdc } from '../lib/contracts'

type LiveCounterProps = { accrued: bigint; maxAmount: bigint; ratePerSecondX18: bigint; running: boolean }

export function LiveCounter({ accrued, ratePerSecondX18, running }: LiveCounterProps) {
  const [elapsedMilliseconds, setElapsedMilliseconds] = useState(0n)

  useEffect(() => {
    if (!running) {
      setElapsedMilliseconds(0n)
      return
    }
    setElapsedMilliseconds(0n)
    const interval = window.setInterval(() => setElapsedMilliseconds((value) => value + 100n), 100)
    return () => window.clearInterval(interval)
  }, [accrued, ratePerSecondX18, running])

  const estimate = accrued + ratePerSecondX18 * elapsedMilliseconds / (1000n * RATE_SCALE)
  const displayed = estimate < maxAmount ? estimate : maxAmount
  return <span className="live-counter" aria-label={`Accrued ${formatUsdc(accrued)} USDC`}>{formatUsdc(displayed)}</span>
}