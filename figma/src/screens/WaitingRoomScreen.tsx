import { useState, useEffect } from 'react';
import type { AppUser } from '../types/uno';

interface WaitingRoomScreenProps {
  user: AppUser;
  roomCode: string;
  isHost: boolean;
  onStart: (opponentCount: number) => void;
  onBack: () => void;
}

const FAKE_PLAYERS = ['Luna', 'Rayo', 'Nova'];
const PLAYER_COLORS = ['#E63946', '#FFD60A', '#2EC4B6', '#4CC9F0'];

interface RoomPlayer {
  name: string;
  ready: boolean;
  isMe: boolean;
}

export default function WaitingRoomScreen({ user, roomCode, isHost, onStart, onBack }: WaitingRoomScreenProps) {
  const [players, setPlayers] = useState<RoomPlayer[]>([
    { name: user.name, ready: false, isMe: true },
  ]);
  const [myReady, setMyReady] = useState(false);
  const [copied, setCopied] = useState(false);
  const [started, setStarted] = useState(false);

  // Simulate other players joining
  useEffect(() => {
    const count = isHost ? 2 : 1;
    const timers: ReturnType<typeof setTimeout>[] = [];
    FAKE_PLAYERS.slice(0, count).forEach((name, i) => {
      const t = setTimeout(() => {
        setPlayers(prev => [...prev, { name, ready: false, isMe: false }]);
        // Simulate them readying up after 1.5s
        const t2 = setTimeout(() => {
          setPlayers(prev => prev.map(p => p.name === name ? { ...p, ready: true } : p));
        }, 1500 + Math.random() * 1000);
        timers.push(t2);
      }, 1200 * (i + 1));
      timers.push(t);
    });
    return () => timers.forEach(clearTimeout);
  }, [isHost]);

  // If client, host auto-starts after a while
  useEffect(() => {
    if (!isHost) {
      const t = setTimeout(() => {
        if (!started) {
          setStarted(true);
          onStart(2);
        }
      }, 8000);
      return () => clearTimeout(t);
    }
  }, [isHost, started, onStart]);

  const handleReady = () => {
    const newReady = !myReady;
    setMyReady(newReady);
    setPlayers(prev => prev.map(p => p.isMe ? { ...p, ready: newReady } : p));
  };

  const handleStart = () => {
    setStarted(true);
    onStart(players.length - 1);
  };

  const handleCopy = () => {
    navigator.clipboard.writeText(roomCode).catch(() => {});
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const allReady = players.length >= 2 && players.every(p => p.ready);
  const canStart = isHost && players.length >= 2;

  return (
    <div style={{
      height: '100%',
      background: 'linear-gradient(160deg, #0d0d1a 0%, #0d1030 60%, #0d1a2e 100%)',
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
        <div>
          <h2 style={{ fontFamily: 'Fredoka One, cursive', fontSize: 24, color: '#f0f0f0', margin: 0 }}>
            Sala de Espera
          </h2>
          <p style={{ color: '#7a7aaa', fontSize: 12, margin: 0 }}>
            {isHost ? 'Eres el anfitrión' : 'Esperando al anfitrión...'}
          </p>
        </div>
      </div>

      <div style={{ flex: 1, overflowY: 'auto', padding: '0 24px 24px', display: 'flex', flexDirection: 'column', gap: 16 }}>
        {/* Room code */}
        <div style={{
          background: 'rgba(255,255,255,0.05)',
          border: '1px solid rgba(255,255,255,0.1)',
          borderRadius: 16,
          padding: '20px 24px',
          textAlign: 'center',
        }}>
          <p style={{ color: '#7a7aaa', fontSize: 12, margin: '0 0 8px', fontWeight: 700, letterSpacing: 1, textTransform: 'uppercase' }}>
            Código de sala
          </p>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 12 }}>
            <span style={{
              fontFamily: 'Fredoka One, cursive',
              fontSize: 38,
              color: '#FFD60A',
              letterSpacing: 6,
              textShadow: '0 0 20px rgba(255,214,10,0.4)',
            }}>{roomCode}</span>
            <button
              onClick={handleCopy}
              style={{
                padding: '8px 12px',
                background: copied ? 'rgba(46,196,182,0.2)' : 'rgba(255,255,255,0.08)',
                border: `1px solid ${copied ? '#2EC4B6' : 'rgba(255,255,255,0.15)'}`,
                borderRadius: 8,
                cursor: 'pointer',
                color: copied ? '#2EC4B6' : '#7a7aaa',
                fontSize: 12,
                fontWeight: 700,
                fontFamily: 'Nunito, sans-serif',
                transition: 'all 0.2s',
              }}
            >
              {copied ? '✓ Copiado' : '📋 Copiar'}
            </button>
          </div>
          <p style={{ color: '#7a7aaa', fontSize: 13, margin: '10px 0 0' }}>
            Comparte este código con tus amigos
          </p>
        </div>

        {/* Players list */}
        <div style={{
          background: 'rgba(255,255,255,0.04)',
          border: '1px solid rgba(255,255,255,0.08)',
          borderRadius: 16,
          overflow: 'hidden',
        }}>
          <div style={{ padding: '14px 20px', borderBottom: '1px solid rgba(255,255,255,0.06)' }}>
            <h3 style={{
              fontFamily: 'Fredoka One, cursive',
              fontSize: 18,
              color: '#f0f0f0',
              margin: 0,
            }}>Jugadores ({players.length}/4)</h3>
          </div>

          {players.map((p, i) => (
            <div
              key={p.name}
              className="animate-slide-up"
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 14,
                padding: '14px 20px',
                borderBottom: i < players.length - 1 ? '1px solid rgba(255,255,255,0.05)' : 'none',
                animationDelay: `${i * 0.1}s`,
              }}
            >
              <div style={{
                width: 40, height: 40,
                borderRadius: '50%',
                background: `linear-gradient(135deg, ${PLAYER_COLORS[i]}, ${PLAYER_COLORS[(i + 1) % PLAYER_COLORS.length]})`,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontFamily: 'Fredoka One, cursive',
                fontSize: 18, color: '#fff',
                flexShrink: 0,
                boxShadow: `0 3px 10px ${PLAYER_COLORS[i]}55`,
              }}>
                {p.name[0].toUpperCase()}
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ color: '#f0f0f0', fontWeight: 700, fontSize: 15 }}>
                  {p.name} {p.isMe && <span style={{ color: '#7a7aaa', fontWeight: 400, fontSize: 12 }}>(tú)</span>}
                </div>
                {i === 0 && isHost && (
                  <div style={{ color: '#FFD60A', fontSize: 12, fontWeight: 600 }}>👑 Anfitrión</div>
                )}
              </div>
              <div style={{
                padding: '5px 12px',
                borderRadius: 20,
                fontSize: 12,
                fontWeight: 700,
                background: p.ready ? 'rgba(46,196,182,0.15)' : 'rgba(122,122,170,0.15)',
                color: p.ready ? '#2EC4B6' : '#7a7aaa',
                border: `1px solid ${p.ready ? 'rgba(46,196,182,0.3)' : 'rgba(122,122,170,0.2)'}`,
              }}>
                {p.ready ? '✓ Listo' : 'Esperando'}
              </div>
            </div>
          ))}
        </div>

        {/* Status message */}
        {!isHost && (
          <div style={{
            background: 'rgba(76,201,240,0.08)',
            border: '1px solid rgba(76,201,240,0.2)',
            borderRadius: 12,
            padding: '14px 18px',
            display: 'flex',
            alignItems: 'center',
            gap: 10,
          }}>
            <div style={{
              width: 8, height: 8, borderRadius: '50%',
              background: '#4CC9F0',
              boxShadow: '0 0 8px #4CC9F0',
              animation: 'glow-pulse 1.5s ease-in-out infinite',
            }} />
            <span style={{ color: '#4CC9F0', fontSize: 14, fontWeight: 600 }}>
              Esperando que el anfitrión inicie la partida...
            </span>
          </div>
        )}

        {/* Action buttons */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {!isHost && (
            <button
              onClick={handleReady}
              style={{
                padding: '15px',
                background: myReady
                  ? 'rgba(46,196,182,0.15)'
                  : 'linear-gradient(135deg, #2EC4B6, #1A7268)',
                border: myReady ? '2px solid #2EC4B6' : 'none',
                borderRadius: 14,
                color: myReady ? '#2EC4B6' : '#fff',
                fontSize: 16,
                fontWeight: 800,
                fontFamily: 'Nunito, sans-serif',
                cursor: 'pointer',
                boxShadow: myReady ? 'none' : '0 6px 20px rgba(46,196,182,0.4)',
              }}
            >
              {myReady ? '✓ Listo' : '¡Listo!'}
            </button>
          )}

          {isHost && (
            <button
              onClick={handleStart}
              disabled={!canStart}
              style={{
                padding: '15px',
                background: canStart
                  ? 'linear-gradient(135deg, #E63946, #c41e3a)'
                  : 'rgba(255,255,255,0.06)',
                border: 'none',
                borderRadius: 14,
                color: canStart ? '#fff' : '#4a4a6a',
                fontSize: 16,
                fontWeight: 800,
                fontFamily: 'Nunito, sans-serif',
                cursor: canStart ? 'pointer' : 'not-allowed',
                boxShadow: canStart ? '0 6px 20px rgba(230,57,70,0.45)' : 'none',
                transition: 'all 0.2s',
              }}
            >
              {players.length < 2
                ? '⏳ Esperando jugadores...'
                : allReady
                ? '🚀 Iniciar Partida'
                : `🚀 Iniciar Partida (${players.filter(p => p.ready).length}/${players.length} listos)`}
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
