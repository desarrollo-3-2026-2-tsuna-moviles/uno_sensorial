import { useState } from 'react';

interface MultiplayerScreenProps {
  onCreateRoom: (code: string) => void;
  onJoinRoom: (code: string) => void;
  onBack: () => void;
}

function generateCode(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  return Array.from({ length: 6 }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
}

export default function MultiplayerScreen({ onCreateRoom, onJoinRoom, onBack }: MultiplayerScreenProps) {
  const [mode, setMode] = useState<'choose' | 'join'>('choose');
  const [code, setCode] = useState('');
  const [error, setError] = useState('');

  const handleCreate = () => {
    onCreateRoom(generateCode());
  };

  const handleJoin = () => {
    if (code.trim().length < 4) { setError('Ingresa un código válido'); return; }
    onJoinRoom(code.trim().toUpperCase());
  };

  return (
    <div style={{
      height: '100%',
      background: 'linear-gradient(160deg, #0d0d1a 0%, #0d1030 60%, #0d1a2e 100%)',
      display: 'flex',
      flexDirection: 'column',
    }}>
      {/* Header */}
      <div style={{
        display: 'flex',
        alignItems: 'center',
        padding: '20px 24px',
        gap: 12,
      }}>
        <button
          onClick={onBack}
          style={{
            width: 40, height: 40,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            background: 'rgba(255,255,255,0.07)',
            border: '1px solid rgba(255,255,255,0.12)',
            borderRadius: 10,
            cursor: 'pointer',
            color: '#f0f0f0',
          }}
        >
          <svg width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
            <path d="M15 18l-6-6 6-6"/>
          </svg>
        </button>
        <h2 style={{
          fontFamily: 'Fredoka One, cursive',
          fontSize: 26,
          color: '#f0f0f0',
          margin: 0,
        }}>Multijugador</h2>
      </div>

      {/* Content */}
      <div style={{
        flex: 1,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '0 28px 40px',
      }}>
        {/* Network icon */}
        <div style={{
          width: 80,
          height: 80,
          borderRadius: '50%',
          background: 'linear-gradient(135deg, #4CC9F0, #1565A3)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          marginBottom: 24,
          boxShadow: '0 8px 32px rgba(76,201,240,0.4)',
        }}>
          <svg width="38" height="38" fill="none" stroke="#fff" strokeWidth="2" viewBox="0 0 24 24">
            <circle cx="12" cy="12" r="10"/>
            <path d="M2 12h20M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/>
          </svg>
        </div>

        {mode === 'choose' ? (
          <div className="animate-slide-up" style={{ width: '100%', maxWidth: 380, display: 'flex', flexDirection: 'column', gap: 16 }}>
            <h1 style={{
              fontFamily: 'Fredoka One, cursive',
              fontSize: 32,
              color: '#f0f0f0',
              textAlign: 'center',
              margin: '0 0 8px',
            }}>Juega en red</h1>
            <p style={{ color: '#7a7aaa', textAlign: 'center', margin: '0 0 16px', fontSize: 15 }}>
              Crea una sala o únete a una existente
            </p>

            <button
              onClick={handleCreate}
              style={{
                padding: '18px 24px',
                background: 'linear-gradient(135deg, #4CC9F0, #1565A3)',
                border: 'none',
                borderRadius: 16,
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                gap: 16,
                boxShadow: '0 8px 28px rgba(76,201,240,0.35)',
                transition: 'transform 0.15s ease',
              }}
              onMouseEnter={e => (e.currentTarget as HTMLButtonElement).style.transform = 'translateY(-3px)'}
              onMouseLeave={e => (e.currentTarget as HTMLButtonElement).style.transform = ''}
            >
              <div style={{
                width: 48, height: 48,
                background: 'rgba(255,255,255,0.15)',
                borderRadius: 12,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: 24, flexShrink: 0,
              }}>➕</div>
              <div style={{ textAlign: 'left' }}>
                <div style={{ fontFamily: 'Fredoka One, cursive', fontSize: 20, color: '#fff' }}>
                  Crear Partida
                </div>
                <div style={{ color: 'rgba(255,255,255,0.65)', fontSize: 13, fontWeight: 600 }}>
                  Genera un código para amigos
                </div>
              </div>
            </button>

            <button
              onClick={() => setMode('join')}
              style={{
                padding: '18px 24px',
                background: 'rgba(255,255,255,0.05)',
                border: '1.5px solid rgba(255,255,255,0.14)',
                borderRadius: 16,
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                gap: 16,
                transition: 'border-color 0.15s, background 0.15s',
              }}
              onMouseEnter={e => { (e.currentTarget as HTMLButtonElement).style.background = 'rgba(255,255,255,0.1)'; (e.currentTarget as HTMLButtonElement).style.borderColor = 'rgba(255,255,255,0.3)'; }}
              onMouseLeave={e => { (e.currentTarget as HTMLButtonElement).style.background = 'rgba(255,255,255,0.05)'; (e.currentTarget as HTMLButtonElement).style.borderColor = 'rgba(255,255,255,0.14)'; }}
            >
              <div style={{
                width: 48, height: 48,
                background: 'rgba(255,255,255,0.08)',
                borderRadius: 12,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: 24, flexShrink: 0,
              }}>🔗</div>
              <div style={{ textAlign: 'left' }}>
                <div style={{ fontFamily: 'Fredoka One, cursive', fontSize: 20, color: '#f0f0f0' }}>
                  Conectarse a Partida
                </div>
                <div style={{ color: '#7a7aaa', fontSize: 13, fontWeight: 600 }}>
                  Ingresa un código de sala
                </div>
              </div>
            </button>
          </div>
        ) : (
          <div className="animate-slide-up" style={{ width: '100%', maxWidth: 380, display: 'flex', flexDirection: 'column', gap: 16 }}>
            <h1 style={{ fontFamily: 'Fredoka One, cursive', fontSize: 28, color: '#f0f0f0', textAlign: 'center', margin: '0 0 4px' }}>
              Ingresa el código
            </h1>
            <p style={{ color: '#7a7aaa', textAlign: 'center', margin: '0 0 12px', fontSize: 14 }}>
              Pídele el código al anfitrión de la sala
            </p>

            <input
              autoFocus
              value={code}
              onChange={e => { setCode(e.target.value.toUpperCase()); setError(''); }}
              onKeyDown={e => e.key === 'Enter' && handleJoin()}
              placeholder="Ej: ABCD12"
              maxLength={8}
              style={{
                padding: '16px',
                backgroundColor: 'rgba(255,255,255,0.07)',
                border: `2px solid ${error ? '#E63946' : 'rgba(255,255,255,0.15)'}`,
                borderRadius: 12,
                color: '#f0f0f0',
                fontSize: 24,
                fontFamily: 'Fredoka One, cursive',
                textAlign: 'center',
                letterSpacing: 4,
                outline: 'none',
              }}
            />
            {error && <p style={{ color: '#E63946', fontSize: 13, margin: '-8px 0 0', textAlign: 'center' }}>{error}</p>}

            <button
              onClick={handleJoin}
              style={{
                padding: '15px',
                background: 'linear-gradient(135deg, #4CC9F0, #1565A3)',
                border: 'none',
                borderRadius: 12,
                color: '#fff',
                fontSize: 16,
                fontWeight: 800,
                fontFamily: 'Nunito, sans-serif',
                cursor: 'pointer',
                boxShadow: '0 4px 16px rgba(76,201,240,0.4)',
              }}
            >
              Unirse
            </button>
            <button
              onClick={() => { setMode('choose'); setError(''); setCode(''); }}
              style={{ background: 'none', border: 'none', color: '#7a7aaa', fontSize: 14, cursor: 'pointer', fontFamily: 'Nunito, sans-serif' }}
            >
              ← Volver
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
