import { useState } from 'react';
import type { AppUser } from '../types/uno';

interface LoginScreenProps {
  onLogin: (user: AppUser) => void;
}

const FLOATING_CARDS = [
  { color: '#E63946', rot: -15, x: '8%', y: '12%', delay: '0s', label: '7' },
  { color: '#FFD60A', rot: 20, x: '82%', y: '8%', delay: '0.4s', label: '+2' },
  { color: '#2EC4B6', rot: -8, x: '5%', y: '72%', delay: '0.8s', label: '↺' },
  { color: '#4CC9F0', rot: 14, x: '86%', y: '65%', delay: '0.2s', label: '⊘' },
  { color: '#E63946', rot: 30, x: '75%', y: '35%', delay: '1s', label: '3' },
  { color: '#2EC4B6', rot: -20, x: '18%', y: '42%', delay: '0.6s', label: '5' },
];

export default function LoginScreen({ onLogin }: LoginScreenProps) {
  const [mode, setMode] = useState<'choose' | 'local'>('choose');
  const [name, setName] = useState('');
  const [error, setError] = useState('');

  const handleGoogle = () => {
    onLogin({ name: 'Jugador', initial: 'J', method: 'google' });
  };

  const handleLocal = () => {
    if (!name.trim()) { setError('Ingresa un nombre'); return; }
    const n = name.trim();
    onLogin({ name: n, initial: n[0].toUpperCase(), method: 'local' });
  };

  return (
    <div style={{
      height: '100%',
      background: 'linear-gradient(135deg, #0d0d1a 0%, #1a0a2e 50%, #0d1a2e 100%)',
      position: 'relative',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      overflow: 'hidden',
    }}>
      {/* Floating background cards */}
      {FLOATING_CARDS.map((c, i) => (
        <div
          key={i}
          className="animate-float"
          style={{
            position: 'absolute',
            left: c.x,
            top: c.y,
            width: 52,
            height: 78,
            backgroundColor: c.color,
            borderRadius: 8,
            border: '2px solid rgba(255,255,255,0.2)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            '--rot': `${c.rot}deg`,
            transform: `rotate(${c.rot}deg)`,
            animationDelay: c.delay,
            opacity: 0.35,
            fontSize: 20,
            fontFamily: 'Fredoka One, cursive',
            color: '#fff',
            fontWeight: 900,
          } as React.CSSProperties}
        >
          {c.label}
        </div>
      ))}

      {/* Main card */}
      <div className="animate-slide-up" style={{
        background: 'rgba(22, 22, 58, 0.92)',
        backdropFilter: 'blur(20px)',
        border: '1px solid rgba(255,255,255,0.12)',
        borderRadius: 24,
        padding: '48px 40px',
        width: '100%',
        maxWidth: 400,
        boxShadow: '0 32px 80px rgba(0,0,0,0.6)',
        position: 'relative',
        zIndex: 1,
      }}>
        {/* UNO Logo */}
        <div style={{ textAlign: 'center', marginBottom: 32 }}>
          <div style={{
            display: 'inline-flex',
            alignItems: 'center',
            justifyContent: 'center',
            background: 'linear-gradient(135deg, #E63946, #c41e3a)',
            borderRadius: 20,
            padding: '10px 32px',
            boxShadow: '0 8px 32px rgba(230,57,70,0.5)',
            marginBottom: 16,
          }}>
            <span style={{
              fontFamily: 'Fredoka One, cursive',
              fontSize: 56,
              color: '#FFD60A',
              letterSpacing: 4,
              textShadow: '0 3px 8px rgba(0,0,0,0.4)',
            }}>UNO</span>
          </div>
          <p style={{ color: '#7a7aaa', fontSize: 15, margin: 0 }}>
            El juego de cartas más épico
          </p>
        </div>

        {mode === 'choose' ? (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
            <button
              onClick={handleGoogle}
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: 12,
                padding: '14px 20px',
                backgroundColor: '#fff',
                color: '#1a1a2e',
                border: 'none',
                borderRadius: 12,
                fontSize: 15,
                fontWeight: 700,
                fontFamily: 'Nunito, sans-serif',
                cursor: 'pointer',
                transition: 'transform 0.1s, box-shadow 0.1s',
                boxShadow: '0 4px 16px rgba(0,0,0,0.3)',
              }}
              onMouseEnter={e => { (e.currentTarget as HTMLButtonElement).style.transform = 'translateY(-2px)'; (e.currentTarget as HTMLButtonElement).style.boxShadow = '0 8px 24px rgba(0,0,0,0.4)'; }}
              onMouseLeave={e => { (e.currentTarget as HTMLButtonElement).style.transform = ''; (e.currentTarget as HTMLButtonElement).style.boxShadow = '0 4px 16px rgba(0,0,0,0.3)'; }}
            >
              <svg width="20" height="20" viewBox="0 0 24 24">
                <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
                <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
              </svg>
              Continuar con Google
            </button>

            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <div style={{ flex: 1, height: 1, backgroundColor: 'rgba(255,255,255,0.1)' }} />
              <span style={{ color: '#7a7aaa', fontSize: 13 }}>o</span>
              <div style={{ flex: 1, height: 1, backgroundColor: 'rgba(255,255,255,0.1)' }} />
            </div>

            <button
              onClick={() => setMode('local')}
              style={{
                padding: '14px 20px',
                backgroundColor: 'transparent',
                color: '#f0f0f0',
                border: '1.5px solid rgba(255,255,255,0.18)',
                borderRadius: 12,
                fontSize: 15,
                fontWeight: 700,
                fontFamily: 'Nunito, sans-serif',
                cursor: 'pointer',
                transition: 'border-color 0.15s, background 0.15s',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: 10,
              }}
              onMouseEnter={e => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'rgba(255,255,255,0.06)'; (e.currentTarget as HTMLButtonElement).style.borderColor = 'rgba(255,255,255,0.32)'; }}
              onMouseLeave={e => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'transparent'; (e.currentTarget as HTMLButtonElement).style.borderColor = 'rgba(255,255,255,0.18)'; }}
            >
              <svg width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                <rect x="2" y="3" width="20" height="14" rx="2"/>
                <path d="M8 21h8M12 17v4"/>
              </svg>
              Red local / Sin cuenta
            </button>
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
            <div>
              <label style={{ display: 'block', color: '#7a7aaa', fontSize: 13, marginBottom: 8, fontWeight: 600 }}>
                Tu nombre
              </label>
              <input
                autoFocus
                value={name}
                onChange={e => { setName(e.target.value); setError(''); }}
                onKeyDown={e => e.key === 'Enter' && handleLocal()}
                placeholder="Ej: Jugador1"
                maxLength={16}
                style={{
                  width: '100%',
                  padding: '13px 16px',
                  backgroundColor: 'rgba(255,255,255,0.07)',
                  border: `1.5px solid ${error ? '#E63946' : 'rgba(255,255,255,0.15)'}`,
                  borderRadius: 10,
                  color: '#f0f0f0',
                  fontSize: 16,
                  fontFamily: 'Nunito, sans-serif',
                  outline: 'none',
                  boxSizing: 'border-box',
                }}
              />
              {error && <p style={{ color: '#E63946', fontSize: 13, margin: '6px 0 0' }}>{error}</p>}
            </div>

            <button
              onClick={handleLocal}
              style={{
                padding: '14px',
                background: 'linear-gradient(135deg, #E63946, #c41e3a)',
                border: 'none',
                borderRadius: 12,
                color: '#fff',
                fontSize: 16,
                fontWeight: 800,
                fontFamily: 'Nunito, sans-serif',
                cursor: 'pointer',
                boxShadow: '0 4px 16px rgba(230,57,70,0.4)',
              }}
            >
              Entrar al juego
            </button>

            <button
              onClick={() => { setMode('choose'); setError(''); setName(''); }}
              style={{
                padding: '10px',
                backgroundColor: 'transparent',
                border: 'none',
                color: '#7a7aaa',
                fontSize: 14,
                fontFamily: 'Nunito, sans-serif',
                cursor: 'pointer',
              }}
            >
              ← Volver
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
