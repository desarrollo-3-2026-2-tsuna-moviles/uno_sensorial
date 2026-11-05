import type { AppUser } from '../types/uno';

interface SettingsScreenProps {
  user: AppUser;
  onBack: () => void;
  onLogout: () => void;
}

const PLAYER_STATS = [
  { label: 'Partidas jugadas', value: '0' },
  { label: 'Victorias', value: '0' },
  { label: 'UNOs gritados', value: '0' },
];

export default function SettingsScreen({ user, onBack, onLogout }: SettingsScreenProps) {
  return (
    <div style={{
      height: '100%',
      background: 'linear-gradient(160deg, #0d0d1a 0%, #12122e 60%, #0d1a2e 100%)',
      display: 'flex',
      flexDirection: 'column',
      overflow: 'hidden',
    }}>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', padding: '20px 24px', gap: 12 }}>
        <button
          onClick={onBack}
          style={{
            width: 40, height: 40,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            background: 'rgba(255,255,255,0.07)',
            border: '1px solid rgba(255,255,255,0.12)',
            borderRadius: 10, cursor: 'pointer', color: '#f0f0f0',
          }}
        >
          <svg width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
            <path d="M15 18l-6-6 6-6"/>
          </svg>
        </button>
        <h2 style={{ fontFamily: 'Fredoka One, cursive', fontSize: 26, color: '#f0f0f0', margin: 0 }}>
          Configuración
        </h2>
      </div>

      <div style={{ flex: 1, overflowY: 'auto', padding: '0 24px 32px', display: 'flex', flexDirection: 'column', gap: 16 }}>
        {/* Profile card */}
        <div style={{
          background: 'linear-gradient(135deg, rgba(230,57,70,0.15), rgba(26,16,64,0.8))',
          border: '1px solid rgba(230,57,70,0.2)',
          borderRadius: 20,
          padding: '24px',
          display: 'flex',
          alignItems: 'center',
          gap: 18,
        }}>
          <div style={{
            width: 64, height: 64,
            borderRadius: '50%',
            background: 'linear-gradient(135deg, #E63946, #c41e3a)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontFamily: 'Fredoka One, cursive',
            fontSize: 28, color: '#FFD60A',
            boxShadow: '0 4px 16px rgba(230,57,70,0.5)',
            flexShrink: 0,
          }}>
            {user.initial}
          </div>
          <div>
            <div style={{ fontFamily: 'Fredoka One, cursive', fontSize: 24, color: '#f0f0f0', lineHeight: 1 }}>
              {user.name}
            </div>
            <div style={{ color: '#7a7aaa', fontSize: 14, marginTop: 4, display: 'flex', alignItems: 'center', gap: 6 }}>
              {user.method === 'google' ? (
                <><svg width="14" height="14" viewBox="0 0 24 24"><path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/><path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/><path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/><path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/></svg> Cuenta Google</>
              ) : (
                <><svg width="14" height="14" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24"><rect x="2" y="3" width="20" height="14" rx="2"/><path d="M8 21h8M12 17v4"/></svg> Usuario local</>
              )}
            </div>
          </div>
        </div>

        {/* Stats */}
        <div style={{
          background: 'rgba(255,255,255,0.04)',
          border: '1px solid rgba(255,255,255,0.08)',
          borderRadius: 16,
        }}>
          <div style={{ padding: '14px 20px', borderBottom: '1px solid rgba(255,255,255,0.06)' }}>
            <h3 style={{ fontFamily: 'Fredoka One, cursive', fontSize: 18, color: '#f0f0f0', margin: 0 }}>
              Estadísticas
            </h3>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 0 }}>
            {PLAYER_STATS.map((stat, i) => (
              <div
                key={stat.label}
                style={{
                  padding: '18px 14px',
                  textAlign: 'center',
                  borderRight: i < 2 ? '1px solid rgba(255,255,255,0.06)' : 'none',
                }}
              >
                <div style={{ fontFamily: 'Fredoka One, cursive', fontSize: 28, color: '#FFD60A' }}>
                  {stat.value}
                </div>
                <div style={{ color: '#7a7aaa', fontSize: 12, fontWeight: 600, marginTop: 4 }}>
                  {stat.label}
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Settings options */}
        <div style={{
          background: 'rgba(255,255,255,0.04)',
          border: '1px solid rgba(255,255,255,0.08)',
          borderRadius: 16,
          overflow: 'hidden',
        }}>
          <div style={{ padding: '14px 20px', borderBottom: '1px solid rgba(255,255,255,0.06)' }}>
            <h3 style={{ fontFamily: 'Fredoka One, cursive', fontSize: 18, color: '#f0f0f0', margin: 0 }}>
              Opciones
            </h3>
          </div>
          {[
            { icon: '🔔', label: 'Notificaciones', desc: 'Sonidos del juego', value: 'Activado' },
            { icon: '🎨', label: 'Tema', desc: 'Apariencia visual', value: 'Oscuro' },
            { icon: '🌐', label: 'Idioma', desc: 'Language / Idioma', value: 'Español' },
          ].map((opt, i, arr) => (
            <div
              key={opt.label}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 14,
                padding: '14px 20px',
                borderBottom: i < arr.length - 1 ? '1px solid rgba(255,255,255,0.05)' : 'none',
              }}
            >
              <span style={{ fontSize: 22 }}>{opt.icon}</span>
              <div style={{ flex: 1 }}>
                <div style={{ color: '#f0f0f0', fontWeight: 700, fontSize: 15 }}>{opt.label}</div>
                <div style={{ color: '#7a7aaa', fontSize: 12 }}>{opt.desc}</div>
              </div>
              <span style={{
                color: '#7a7aaa',
                fontSize: 13,
                fontWeight: 600,
                background: 'rgba(255,255,255,0.06)',
                borderRadius: 8,
                padding: '4px 10px',
              }}>{opt.value}</span>
            </div>
          ))}
        </div>

        {/* Danger zone */}
        <div style={{
          background: 'rgba(230,57,70,0.06)',
          border: '1px solid rgba(230,57,70,0.2)',
          borderRadius: 16,
          padding: '20px',
          display: 'flex',
          flexDirection: 'column',
          gap: 12,
        }}>
          <h3 style={{ fontFamily: 'Fredoka One, cursive', fontSize: 18, color: '#E63946', margin: 0 }}>
            Cuenta
          </h3>
          <button
            onClick={onLogout}
            style={{
              padding: '13px 20px',
              background: 'rgba(230,57,70,0.12)',
              border: '1.5px solid rgba(230,57,70,0.35)',
              borderRadius: 12,
              color: '#E63946',
              fontSize: 15,
              fontWeight: 700,
              fontFamily: 'Nunito, sans-serif',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: 8,
              transition: 'background 0.15s',
            }}
            onMouseEnter={e => (e.currentTarget as HTMLButtonElement).style.background = 'rgba(230,57,70,0.22)'}
            onMouseLeave={e => (e.currentTarget as HTMLButtonElement).style.background = 'rgba(230,57,70,0.12)'}
          >
            <svg width="17" height="17" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
              <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9"/>
            </svg>
            Cerrar Sesión
          </button>
        </div>

        <div style={{ textAlign: 'center', color: '#3a3a5a', fontSize: 12 }}>
          UNO v1.0 · Hecho con ❤️
        </div>
      </div>
    </div>
  );
}
