import type { AppUser } from '../types/uno';

interface MenuScreenProps {
  user: AppUser;
  onSolo: () => void;
  onMultiplayer: () => void;
  onSettings: () => void;
}

const OPTIONS = [
  {
    label: 'Jugar Solo',
    desc: 'Enfréntate a la IA',
    icon: '🃏',
    gradient: 'linear-gradient(135deg, #E63946, #a01c27)',
    glow: 'rgba(230,57,70,0.4)',
    key: 'solo',
  },
  {
    label: 'Multijugador',
    desc: 'Juega con amigos en red',
    icon: '🌐',
    gradient: 'linear-gradient(135deg, #4CC9F0, #1565A3)',
    glow: 'rgba(76,201,240,0.35)',
    key: 'multi',
  },
  {
    label: 'Configuración',
    desc: 'Cuenta y opciones',
    icon: '⚙️',
    gradient: 'linear-gradient(135deg, #2a2a60, #16163a)',
    glow: 'rgba(122,122,170,0.2)',
    key: 'settings',
  },
];

export default function MenuScreen({ user, onSolo, onMultiplayer, onSettings }: MenuScreenProps) {
  const handlers = { solo: onSolo, multi: onMultiplayer, settings: onSettings };

  return (
    <div style={{
      height: '100%',
      background: 'linear-gradient(160deg, #0d0d1a 0%, #12122e 60%, #0d1a2e 100%)',
      display: 'flex',
      flexDirection: 'column',
      overflow: 'hidden',
    }}>
      {/* Header */}
      <div style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        padding: '20px 28px 0',
      }}>
        <div style={{
          display: 'flex',
          alignItems: 'center',
          gap: 12,
          background: 'rgba(230,57,70,0.12)',
          border: '1px solid rgba(230,57,70,0.25)',
          borderRadius: 14,
          padding: '6px 14px 6px 8px',
        }}>
          <div style={{
            width: 36,
            height: 36,
            borderRadius: '50%',
            background: 'linear-gradient(135deg, #E63946, #c41e3a)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontFamily: 'Fredoka One, cursive',
            fontSize: 18,
            color: '#FFD60A',
            boxShadow: '0 2px 8px rgba(230,57,70,0.4)',
          }}>
            {user.initial}
          </div>
          <div>
            <div style={{ color: '#f0f0f0', fontWeight: 700, fontSize: 14, lineHeight: 1 }}>
              {user.name}
            </div>
            <div style={{ color: '#7a7aaa', fontSize: 11, marginTop: 2 }}>
              {user.method === 'google' ? 'Google' : 'Local'}
            </div>
          </div>
        </div>

        {/* UNO logo */}
        <div style={{
          background: 'linear-gradient(135deg, #E63946, #c41e3a)',
          borderRadius: 12,
          padding: '4px 18px',
          boxShadow: '0 4px 16px rgba(230,57,70,0.45)',
        }}>
          <span style={{
            fontFamily: 'Fredoka One, cursive',
            fontSize: 28,
            color: '#FFD60A',
            letterSpacing: 3,
          }}>UNO</span>
        </div>
      </div>

      {/* Decorative line */}
      <div style={{ margin: '20px 28px', height: 1, background: 'rgba(255,255,255,0.06)' }} />

      {/* Title */}
      <div style={{ padding: '0 28px 8px', textAlign: 'center' }}>
        <h1 style={{
          fontFamily: 'Fredoka One, cursive',
          fontSize: 38,
          color: '#f0f0f0',
          margin: 0,
          letterSpacing: 1,
        }}>¿Qué quieres hacer?</h1>
        <p style={{ color: '#7a7aaa', margin: '8px 0 0', fontSize: 15 }}>
          Elige un modo de juego
        </p>
      </div>

      {/* Options */}
      <div style={{
        flex: 1,
        display: 'flex',
        flexDirection: 'column',
        gap: 14,
        padding: '16px 28px 32px',
        overflowY: 'auto',
        justifyContent: 'center',
      }}>
        {OPTIONS.map(opt => (
          <button
            key={opt.key}
            onClick={handlers[opt.key as keyof typeof handlers]}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 20,
              padding: '20px 24px',
              background: opt.gradient,
              border: '1px solid rgba(255,255,255,0.1)',
              borderRadius: 18,
              cursor: 'pointer',
              textAlign: 'left',
              boxShadow: `0 8px 28px ${opt.glow}`,
              transition: 'transform 0.15s ease, box-shadow 0.15s ease',
            }}
            onMouseEnter={e => {
              (e.currentTarget as HTMLButtonElement).style.transform = 'translateY(-3px) scale(1.01)';
              (e.currentTarget as HTMLButtonElement).style.boxShadow = `0 16px 40px ${opt.glow}`;
            }}
            onMouseLeave={e => {
              (e.currentTarget as HTMLButtonElement).style.transform = '';
              (e.currentTarget as HTMLButtonElement).style.boxShadow = `0 8px 28px ${opt.glow}`;
            }}
          >
            <div style={{
              fontSize: 36,
              width: 56,
              height: 56,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              background: 'rgba(255,255,255,0.12)',
              borderRadius: 14,
              flexShrink: 0,
            }}>
              {opt.icon}
            </div>
            <div style={{ flex: 1 }}>
              <div style={{
                fontFamily: 'Fredoka One, cursive',
                fontSize: 24,
                color: '#fff',
                lineHeight: 1,
                marginBottom: 4,
              }}>{opt.label}</div>
              <div style={{ color: 'rgba(255,255,255,0.65)', fontSize: 14, fontWeight: 600 }}>
                {opt.desc}
              </div>
            </div>
            <svg width="20" height="20" fill="none" stroke="rgba(255,255,255,0.5)" strokeWidth="2" viewBox="0 0 24 24">
              <path d="M9 18l6-6-6-6"/>
            </svg>
          </button>
        ))}
      </div>
    </div>
  );
}
