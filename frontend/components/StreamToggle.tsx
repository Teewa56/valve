import { Power } from 'lucide-react'

type StreamToggleProps = { active: boolean; disabled?: boolean; onToggle: () => void }

export function StreamToggle({ active, disabled = false, onToggle }: StreamToggleProps) {
  return <button type="button" className={`stream-switch${active ? ' is-on' : ''}`} role="switch" aria-checked={active}
    aria-label={active ? 'Turn stream off' : 'Stream is stopped'} title={active ? 'Cancel this stream' : 'This stream is stopped'}
    disabled={disabled || !active} onClick={onToggle}><span className="switch-knob"><Power size={13} /></span></button>
}