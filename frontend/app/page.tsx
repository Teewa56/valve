import { ArrowDownRight, ArrowRight, Check, ShieldCheck, Waves } from 'lucide-react'
import { Link } from 'react-router-dom'
import { LoginButton } from '../components/LoginButton'
import { useZeroDevAccount } from '../hooks/useZeroDevAccount'

export function LoginPage() {
  const { address, error, isConfigured } = useZeroDevAccount()

  return (
    <section className="welcome-page">
      <div className="welcome-kicker"><span className="kicker-line" /> A better way to subscribe</div>
      <div className="welcome-layout">
        <div className="welcome-copy">
          <h1>Keep the service.<br /><span>Lose the lock-in.</span></h1>
          <p className="welcome-description">Subscriptions that stop when you do. Valve streams USDC by the second, with a spending cap you control.</p>
          <div className="welcome-actions">
            <LoginButton />
            {address && <Link className="text-link" to="/dashboard">Open dashboard <ArrowRight size={15} /></Link>}
          </div>
          {!isConfigured && <div className="config-notice">Passkey setup needs the ZeroDev project, passkey service, and deployed Valve proxy addresses in frontend environment values.</div>}
          {error && <div className="inline-error" role="alert">{error}</div>}
          <div className="trust-line"><ShieldCheck size={16} /><span>Passkey secured</span><span className="trust-separator" /><span>Arbitrum Sepolia</span></div>
        </div>
        <div className="flow-art" aria-label="A payment stream that stops when you switch it off">
          <div className="flow-art-top"><span>PAYMENT FLOW</span><span>48H EXAMPLE</span></div>
          <div className="flow-stage">
            <div className="flow-node wallet-node"><div className="node-icon"><Waves size={18} /></div><div><strong>Your wallet</strong><small>USDC stays yours</small></div></div>
            <div className="flow-track"><div className="track-base" /><div className="track-fill" /><span className="flow-particle particle-one" /><span className="flow-particle particle-two" /><span className="flow-particle particle-three" /></div>
            <div className="flow-node service-node"><div className="service-avatar">S</div><div><strong>Service</strong><small>Earns as you use it</small></div></div>
          </div>
          <div className="flow-cut"><span className="cut-switch"><span /></span><div><strong>OFF means off</strong><small>Cancel this stream in one tap</small></div><ArrowDownRight size={18} /></div>
          <div className="flow-metric"><div><small>AT $30 / MONTH</small><strong>$2.00</strong></div><div className="metric-bar"><span /><span /><span /><span /><span /><span /><span /></div><div className="metric-caption"><Check size={13} /> exactly 48 hours of use</div></div>
          <div className="art-stamp">01<span> / </span>CONTROL</div>
        </div>
      </div>
      <div className="welcome-bottom"><span>EVERY SECOND COUNTS</span><span>YOUR CONTROL PANEL <ArrowDownRight size={14} /></span><Link to="/dashboard">Go to dashboard <ArrowRight size={14} /></Link></div>
    </section>
  )
}