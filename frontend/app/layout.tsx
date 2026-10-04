import { Activity, ArrowUpRight, Gauge, Waves } from 'lucide-react'
import { NavLink, Outlet } from 'react-router-dom'
import { LoginButton } from '../components/LoginButton'
import { ZeroDevProvider, useZeroDevAccount } from '../hooks/useZeroDevAccount'

function Frame() {
  const { address } = useZeroDevAccount()

  return (
    <div className="app-frame">
      <aside className="sidebar">
        <NavLink to="/" className="brand" aria-label="Valve home">
          <span className="brand-mark"><Waves size={19} strokeWidth={2.6} /></span>
          <span>valve<span className="brand-period">.</span></span>
        </NavLink>
        <div className="workspace-label">YOUR ACCOUNT</div>
        <nav className="main-nav" aria-label="Main navigation">
          <NavLink to="/dashboard" className={({ isActive }) => `nav-item${isActive ? ' active' : ''}`}>
            <Gauge size={17} /> <span>Subscriptions</span>
          </NavLink>
          <NavLink to="/provider" className={({ isActive }) => `nav-item${isActive ? ' active' : ''}`}>
            <Activity size={17} /> <span>Provider view</span>
          </NavLink>
        </nav>
        <div className="sidebar-bottom">
          <div className="network-indicator"><span className="network-dot" /> Arbitrum Sepolia</div>
          <p>Streams settle in USDC.<br />No upfront subscription charge.</p>
          <a className="sidebar-link" href="https://sepolia.arbiscan.io" target="_blank" rel="noreferrer">
            Explorer <ArrowUpRight size={13} />
          </a>
        </div>
      </aside>
      <div className="main-column">
        <header className="topbar">
          <div className="mobile-brand"><span className="brand-mark"><Waves size={17} /></span> valve<span className="brand-period">.</span></div>
          <div className="topbar-note"><span className="live-dot" /> Arbitrum Sepolia · USDC</div>
          <LoginButton compact connectedAddress={address} />
        </header>
        <main className="page-content"><Outlet /></main>
        <footer className="site-footer"><span>VALVE PROTOCOL</span><span>Stream only what you use.</span></footer>
      </div>
    </div>
  )
}

export function Layout() {
  return <ZeroDevProvider><Frame /></ZeroDevProvider>
}