import { useState, useEffect, useCallback, useRef } from 'react';
import UnoCard from '../components/UnoCard';
import { initGame, playCard, drawCards, getAIMove, canPlayCard } from '../game/uno';
import type { CardColor, GameState } from '../types/uno';

interface GameScreenProps {
  playerName: string;
  opponentCount: number;
  onGameEnd: () => void;
}

const COLOR_BG: Record<CardColor, string> = {
  red: '#E63946',
  yellow: '#FFD60A',
  green: '#2EC4B6',
  blue: '#4CC9F0',
  wild: '#7a7aaa',
};

const COLOR_LABEL: Record<CardColor, string> = {
  red: 'Rojo',
  yellow: 'Amarillo',
  green: 'Verde',
  blue: 'Azul',
  wild: 'Comodín',
};

const PLAYER_AVATAR_COLORS = ['#E63946', '#4CC9F0', '#2EC4B6', '#FFD60A'];

export default function GameScreen({ playerName, opponentCount, onGameEnd }: GameScreenProps) {
  const [gameState, setGameState] = useState<GameState>(() =>
    initGame(playerName, opponentCount),
  );
  const [pendingWildIndex, setPendingWildIndex] = useState<number | null>(null);
  const [shakeIndex, setShakeIndex] = useState<number | null>(null);
  const [unoToast, setUnoToast] = useState<string | null>(null);
  const handRef = useRef<HTMLDivElement>(null);

  const isPlayerTurn = gameState.currentPlayerIndex === 0 && gameState.phase === 'playing';
  const topCard = gameState.discardPile[gameState.discardPile.length - 1];

  // AI turn effect
  useEffect(() => {
    const { players, currentPlayerIndex, phase } = gameState;
    const current = players[currentPlayerIndex];
    if (phase !== 'playing' || !current?.isAI || pendingWildIndex !== null) return;

    const delay = 700 + Math.random() * 600;
    const timer = setTimeout(() => {
      setGameState(prev => {
        const p = prev.players[prev.currentPlayerIndex];
        if (!p?.isAI || prev.phase !== 'playing') return prev;
        const move = getAIMove(prev, prev.currentPlayerIndex);
        if (move === null) {
          return drawCards(prev, prev.currentPlayerIndex, prev.pendingDraw > 0 ? prev.pendingDraw : 1);
        }
        return playCard(prev, prev.currentPlayerIndex, move.cardIndex, move.chosenColor);
      });
    }, delay);

    return () => clearTimeout(timer);
  }, [gameState.turnKey, pendingWildIndex]);

  // UNO toast
  useEffect(() => {
    const unoPlayer = gameState.players.find(p => p.saidUno && p.hand.length === 1);
    if (unoPlayer) {
      setUnoToast(`¡${unoPlayer.name} dijo UNO! 🃏`);
      const t = setTimeout(() => setUnoToast(null), 2500);
      return () => clearTimeout(t);
    }
  }, [gameState.turnKey]);

  const shakeCard = useCallback((index: number) => {
    setShakeIndex(index);
    setTimeout(() => setShakeIndex(null), 400);
  }, []);

  const handleCardClick = (cardIndex: number) => {
    if (!isPlayerTurn || pendingWildIndex !== null) return;
    const card = gameState.players[0].hand[cardIndex];

    if (gameState.pendingDraw > 0) {
      const canStack =
        (topCard.value === 'draw2' && card.value === 'draw2') ||
        (topCard.value === 'wild4' && card.value === 'wild4');
      if (!canStack) { shakeCard(cardIndex); return; }
    } else if (!canPlayCard(card, topCard, gameState.currentColor)) {
      shakeCard(cardIndex);
      return;
    }

    if (card.color === 'wild') {
      setPendingWildIndex(cardIndex);
    } else {
      setGameState(prev => playCard(prev, 0, cardIndex));
    }
  };

  const handleColorSelect = (color: CardColor) => {
    if (pendingWildIndex === null) return;
    const idx = pendingWildIndex;
    setPendingWildIndex(null);
    setGameState(prev => playCard(prev, 0, idx, color));
  };

  const handleDraw = () => {
    if (!isPlayerTurn || pendingWildIndex !== null) return;
    setGameState(prev => drawCards(prev, 0, prev.pendingDraw > 0 ? prev.pendingDraw : 1));
  };

  const playerHand = gameState.players[0]?.hand ?? [];
  const aiPlayers = gameState.players.slice(1);

  const isCardPlayable = (cardIndex: number) => {
    if (!isPlayerTurn) return false;
    const card = playerHand[cardIndex];
    if (gameState.pendingDraw > 0) {
      return (topCard.value === 'draw2' && card.value === 'draw2') ||
             (topCard.value === 'wild4' && card.value === 'wild4');
    }
    return canPlayCard(card, topCard, gameState.currentColor);
  };

  const hasPlayableCard = playerHand.some((_, i) => isCardPlayable(i));

  return (
    <div style={{
      height: '100%',
      background: 'radial-gradient(ellipse at 50% 30%, #1a0a2e 0%, #0d0d1a 60%, #0d1a2e 100%)',
      display: 'flex',
      flexDirection: 'column',
      position: 'relative',
      overflow: 'hidden',
    }}>
      {/* Background grid */}
      <div style={{
        position: 'absolute', inset: 0,
        backgroundImage: 'radial-gradient(circle at 1px 1px, rgba(255,255,255,0.04) 1px, transparent 0)',
        backgroundSize: '32px 32px',
        pointerEvents: 'none',
      }} />

      {/* UNO Toast */}
      {unoToast && (
        <div className="animate-pop-in" style={{
          position: 'absolute',
          top: 80,
          left: '50%',
          transform: 'translateX(-50%)',
          background: 'linear-gradient(135deg, #E63946, #c41e3a)',
          borderRadius: 14,
          padding: '10px 24px',
          zIndex: 40,
          boxShadow: '0 8px 32px rgba(230,57,70,0.6)',
        }}>
          <span style={{ fontFamily: 'Fredoka One, cursive', fontSize: 18, color: '#FFD60A' }}>
            {unoToast}
          </span>
        </div>
      )}

      {/* Top bar */}
      <div style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        padding: '12px 16px',
        background: 'rgba(0,0,0,0.3)',
        backdropFilter: 'blur(10px)',
        borderBottom: '1px solid rgba(255,255,255,0.06)',
        zIndex: 10,
        flexShrink: 0,
      }}>
        <button
          onClick={onGameEnd}
          style={{
            padding: '6px 14px',
            background: 'rgba(255,255,255,0.07)',
            border: '1px solid rgba(255,255,255,0.12)',
            borderRadius: 8,
            color: '#7a7aaa',
            fontSize: 13,
            fontWeight: 700,
            fontFamily: 'Nunito, sans-serif',
            cursor: 'pointer',
            display: 'flex', alignItems: 'center', gap: 6,
          }}
        >
          <svg width="14" height="14" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
            <path d="M15 18l-6-6 6-6"/>
          </svg>
          Salir
        </button>

        {/* Direction + current color */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{
            display: 'flex', alignItems: 'center', gap: 6,
            background: 'rgba(255,255,255,0.06)',
            borderRadius: 8, padding: '4px 10px',
          }}>
            <span style={{ color: '#7a7aaa', fontSize: 13 }}>
              {gameState.direction === 1 ? '→' : '←'}
            </span>
            <div style={{
              width: 14, height: 14, borderRadius: '50%',
              backgroundColor: COLOR_BG[gameState.currentColor],
              boxShadow: `0 0 8px ${COLOR_BG[gameState.currentColor]}`,
            }} />
            <span style={{ color: '#f0f0f0', fontSize: 12, fontWeight: 700 }}>
              {COLOR_LABEL[gameState.currentColor]}
            </span>
          </div>

          <div style={{
            fontFamily: 'Fredoka One, cursive',
            fontSize: 20, color: '#FFD60A',
            background: 'rgba(230,57,70,0.2)',
            borderRadius: 8, padding: '2px 12px',
          }}>UNO</div>
        </div>

        {/* Deck count */}
        <div style={{ color: '#7a7aaa', fontSize: 13, fontWeight: 600 }}>
          🃏 {gameState.deck.length}
        </div>
      </div>

      {/* AI Players area */}
      <div style={{
        display: 'flex',
        justifyContent: 'center',
        gap: 16,
        padding: '10px 16px',
        flexShrink: 0,
      }}>
        {aiPlayers.map((ai, i) => {
          const isCurrentAI = gameState.currentPlayerIndex === i + 1;
          const displayCount = Math.min(ai.hand.length, 8);
          return (
            <div
              key={ai.id}
              style={{
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                gap: 6,
                background: isCurrentAI ? 'rgba(255,255,255,0.08)' : 'rgba(255,255,255,0.03)',
                border: isCurrentAI ? `1.5px solid ${PLAYER_AVATAR_COLORS[(i + 1) % 4]}55` : '1px solid rgba(255,255,255,0.06)',
                borderRadius: 14,
                padding: '8px 14px',
                transition: 'all 0.3s ease',
                boxShadow: isCurrentAI ? `0 0 20px ${PLAYER_AVATAR_COLORS[(i + 1) % 4]}30` : 'none',
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                <div style={{
                  width: 28, height: 28, borderRadius: '50%',
                  background: PLAYER_AVATAR_COLORS[(i + 1) % 4],
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontFamily: 'Fredoka One, cursive', fontSize: 13, color: '#fff',
                }}>
                  {ai.name[0]}
                </div>
                <span style={{ color: '#f0f0f0', fontSize: 13, fontWeight: 700 }}>{ai.name}</span>
                {ai.saidUno && (
                  <span style={{
                    background: '#E63946',
                    color: '#FFD60A',
                    fontSize: 10,
                    fontWeight: 900,
                    borderRadius: 4,
                    padding: '1px 5px',
                    fontFamily: 'Fredoka One, cursive',
                  }}>UNO!</span>
                )}
              </div>
              <div style={{ display: 'flex', gap: -8 }}>
                {Array.from({ length: displayCount }).map((_, j) => (
                  <div key={j} style={{ marginLeft: j === 0 ? 0 : -14, zIndex: j }}>
                    <UnoCard
                      card={{ id: `back-${ai.id}-${j}`, color: 'wild', value: 'wild' }}
                      size="xs"
                      faceDown
                    />
                  </div>
                ))}
                {ai.hand.length > displayCount && (
                  <div style={{
                    marginLeft: 4, height: 54,
                    display: 'flex', alignItems: 'center',
                    color: '#7a7aaa', fontSize: 12, fontWeight: 700,
                  }}>+{ai.hand.length - displayCount}</div>
                )}
              </div>
              <span style={{ color: '#7a7aaa', fontSize: 11 }}>
                {ai.hand.length} carta{ai.hand.length !== 1 ? 's' : ''}
              </span>
            </div>
          );
        })}
      </div>

      {/* Center game area */}
      <div style={{
        flex: 1,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 12,
        padding: '0 16px',
        minHeight: 0,
      }}>
        {/* Message */}
        <div style={{
          background: 'rgba(0,0,0,0.4)',
          backdropFilter: 'blur(8px)',
          borderRadius: 10,
          padding: '6px 16px',
          maxWidth: '90%',
          textAlign: 'center',
        }}>
          <span style={{ color: '#f0f0f0', fontSize: 13, fontWeight: 600 }}>
            {gameState.message}
          </span>
        </div>

        {gameState.pendingDraw > 0 && (
          <div style={{
            background: 'rgba(230,57,70,0.15)',
            border: '1px solid rgba(230,57,70,0.35)',
            borderRadius: 8,
            padding: '5px 14px',
          }}>
            <span style={{ color: '#E63946', fontSize: 13, fontWeight: 700 }}>
              ⚠ Debes robar {gameState.pendingDraw} cartas o apilar
            </span>
          </div>
        )}

        {/* Draw pile + discard pile */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 24 }}>
          {/* Draw pile */}
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
            <div
              onClick={handleDraw}
              style={{
                position: 'relative',
                cursor: isPlayerTurn && !hasPlayableCard ? 'pointer' : 'default',
              }}
            >
              {[2, 1, 0].map(offset => (
                <div
                  key={offset}
                  style={{
                    position: offset === 0 ? 'relative' : 'absolute',
                    top: offset === 0 ? undefined : -offset * 3,
                    left: offset === 0 ? undefined : -offset * 2,
                    zIndex: 3 - offset,
                    opacity: offset === 0 ? 1 : 0.7 - offset * 0.1,
                  }}
                >
                  <UnoCard
                    card={{ id: 'back', color: 'wild', value: 'wild' }}
                    size="lg"
                    faceDown
                    className={isPlayerTurn && !hasPlayableCard ? 'animate-glow' : ''}
                  />
                </div>
              ))}
            </div>
            <span style={{ color: '#7a7aaa', fontSize: 11, fontWeight: 600 }}>ROBAR</span>
          </div>

          {/* Discard pile */}
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
            <div style={{ position: 'relative' }}>
              {gameState.discardPile.length > 1 && (
                <div style={{
                  position: 'absolute',
                  top: 3, left: 3, zIndex: 0,
                }}>
                  <UnoCard
                    card={gameState.discardPile[gameState.discardPile.length - 2]}
                    size="lg"
                  />
                </div>
              )}
              <div style={{ position: 'relative', zIndex: 1 }}>
                <UnoCard
                  card={topCard}
                  size="lg"
                  style={{
                    boxShadow: `0 0 30px 6px ${COLOR_BG[gameState.currentColor]}66`,
                  }}
                />
              </div>
            </div>
            <span style={{ color: '#7a7aaa', fontSize: 11, fontWeight: 600 }}>DESCARTE</span>
          </div>
        </div>

        {isPlayerTurn && !hasPlayableCard && (
          <div style={{
            background: 'rgba(46,196,182,0.1)',
            border: '1px solid rgba(46,196,182,0.25)',
            borderRadius: 8,
            padding: '5px 14px',
          }}>
            <span style={{ color: '#2EC4B6', fontSize: 13, fontWeight: 600 }}>
              Sin cartas válidas · Toca el mazo para robar
            </span>
          </div>
        )}
      </div>

      {/* Player hand */}
      <div style={{
        flexShrink: 0,
        background: 'rgba(0,0,0,0.4)',
        backdropFilter: 'blur(12px)',
        borderTop: '1px solid rgba(255,255,255,0.08)',
        padding: '10px 0 16px',
      }}>
        {/* Player info */}
        <div style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          padding: '0 16px 8px',
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <div style={{
              width: 28, height: 28, borderRadius: '50%',
              background: PLAYER_AVATAR_COLORS[0],
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontFamily: 'Fredoka One, cursive', fontSize: 13, color: '#fff',
              boxShadow: isPlayerTurn ? `0 0 12px ${PLAYER_AVATAR_COLORS[0]}` : 'none',
            }}>
              {playerName[0].toUpperCase()}
            </div>
            <span style={{
              color: isPlayerTurn ? '#f0f0f0' : '#7a7aaa',
              fontSize: 13, fontWeight: 700,
            }}>
              {playerName} {isPlayerTurn && <span style={{ color: '#2EC4B6' }}>· Tu turno</span>}
            </span>
          </div>
          <span style={{ color: '#7a7aaa', fontSize: 12 }}>
            {playerHand.length} carta{playerHand.length !== 1 ? 's' : ''}
          </span>
        </div>

        {/* Hand cards */}
        <div
          ref={handRef}
          style={{
            display: 'flex',
            gap: 0,
            overflowX: 'auto',
            padding: '4px 16px 4px',
            scrollbarWidth: 'thin',
          }}
        >
          {playerHand.map((card, i) => {
            const playable = isCardPlayable(i);
            return (
              <div
                key={card.id}
                style={{
                  marginLeft: i === 0 ? 0 : -20,
                  zIndex: i,
                  position: 'relative',
                  transition: 'transform 0.15s ease',
                  flexShrink: 0,
                }}
                onMouseEnter={e => {
                  if (isPlayerTurn) (e.currentTarget as HTMLDivElement).style.transform = 'translateY(-14px)';
                }}
                onMouseLeave={e => {
                  (e.currentTarget as HTMLDivElement).style.transform = '';
                }}
              >
                <UnoCard
                  card={card}
                  size="md"
                  onClick={() => handleCardClick(i)}
                  playable={isPlayerTurn ? playable : undefined}
                  shake={shakeIndex === i}
                />
              </div>
            );
          })}
        </div>
      </div>

      {/* Color picker overlay */}
      {pendingWildIndex !== null && (
        <div style={{
          position: 'absolute', inset: 0,
          background: 'rgba(0,0,0,0.85)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          zIndex: 50,
          backdropFilter: 'blur(8px)',
        }}>
          <div className="animate-pop-in" style={{
            background: 'rgba(22,22,58,0.95)',
            border: '1px solid rgba(255,255,255,0.12)',
            borderRadius: 24,
            padding: '32px 36px',
            textAlign: 'center',
            maxWidth: 340,
          }}>
            <div style={{ fontSize: 36, marginBottom: 12 }}>🎨</div>
            <h2 style={{
              fontFamily: 'Fredoka One, cursive',
              fontSize: 26, color: '#f0f0f0',
              margin: '0 0 6px',
            }}>Elige un color</h2>
            <p style={{ color: '#7a7aaa', margin: '0 0 24px', fontSize: 14 }}>
              Selecciona el color que quieres activar
            </p>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
              {(['red', 'yellow', 'green', 'blue'] as CardColor[]).map(color => (
                <button
                  key={color}
                  onClick={() => handleColorSelect(color)}
                  style={{
                    height: 72,
                    backgroundColor: COLOR_BG[color],
                    border: '2px solid rgba(255,255,255,0.2)',
                    borderRadius: 14,
                    cursor: 'pointer',
                    fontFamily: 'Fredoka One, cursive',
                    fontSize: 16,
                    color: color === 'yellow' ? '#1a1a00' : '#fff',
                    fontWeight: 900,
                    transition: 'transform 0.1s, box-shadow 0.1s',
                    boxShadow: `0 4px 16px ${COLOR_BG[color]}55`,
                  }}
                  onMouseEnter={e => {
                    (e.currentTarget as HTMLButtonElement).style.transform = 'scale(1.06)';
                    (e.currentTarget as HTMLButtonElement).style.boxShadow = `0 8px 28px ${COLOR_BG[color]}88`;
                  }}
                  onMouseLeave={e => {
                    (e.currentTarget as HTMLButtonElement).style.transform = '';
                    (e.currentTarget as HTMLButtonElement).style.boxShadow = `0 4px 16px ${COLOR_BG[color]}55`;
                  }}
                >
                  {COLOR_LABEL[color]}
                </button>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Game over overlay */}
      {gameState.phase === 'game-over' && (
        <div style={{
          position: 'absolute', inset: 0,
          background: 'rgba(0,0,0,0.88)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          zIndex: 60,
          backdropFilter: 'blur(12px)',
        }}>
          <div className="animate-pop-in" style={{
            background: 'rgba(22,22,58,0.97)',
            border: '1px solid rgba(255,255,255,0.12)',
            borderRadius: 28,
            padding: '48px 44px',
            textAlign: 'center',
            maxWidth: 380,
            boxShadow: '0 32px 80px rgba(0,0,0,0.7)',
          }}>
            {gameState.winner === 0 ? (
              <>
                <div style={{ fontSize: 56, marginBottom: 12 }}>🏆</div>
                <h1 style={{
                  fontFamily: 'Fredoka One, cursive',
                  fontSize: 40, color: '#FFD60A',
                  margin: '0 0 8px',
                  textShadow: '0 0 20px rgba(255,214,10,0.5)',
                }}>¡Ganaste!</h1>
                <p style={{ color: '#7a7aaa', margin: '0 0 32px', fontSize: 16 }}>
                  ¡Increíble partida, {playerName}!
                </p>
              </>
            ) : (
              <>
                <div style={{ fontSize: 56, marginBottom: 12 }}>🎮</div>
                <h1 style={{
                  fontFamily: 'Fredoka One, cursive',
                  fontSize: 36, color: '#f0f0f0',
                  margin: '0 0 8px',
                }}>
                  {gameState.winner !== null
                    ? `¡${gameState.players[gameState.winner].name} ganó!`
                    : 'Fin del juego'}
                </h1>
                <p style={{ color: '#7a7aaa', margin: '0 0 32px', fontSize: 16 }}>
                  ¡Mejor suerte la próxima vez!
                </p>
              </>
            )}

            {/* Final hand counts */}
            <div style={{
              background: 'rgba(255,255,255,0.05)',
              borderRadius: 14,
              padding: '16px',
              marginBottom: 28,
              display: 'flex',
              flexDirection: 'column',
              gap: 8,
            }}>
              {gameState.players.map((p, i) => (
                <div key={p.id} style={{
                  display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                  color: i === gameState.winner ? '#FFD60A' : '#7a7aaa',
                  fontSize: 14, fontWeight: 700,
                }}>
                  <span>{i === 0 ? 'Tú' : p.name} {i === gameState.winner ? '👑' : ''}</span>
                  <span>{p.hand.length} cartas restantes</span>
                </div>
              ))}
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              <button
                onClick={() => setGameState(initGame(playerName, opponentCount))}
                style={{
                  padding: '14px',
                  background: 'linear-gradient(135deg, #E63946, #c41e3a)',
                  border: 'none', borderRadius: 14,
                  color: '#fff', fontSize: 16, fontWeight: 800,
                  fontFamily: 'Nunito, sans-serif', cursor: 'pointer',
                  boxShadow: '0 6px 20px rgba(230,57,70,0.5)',
                }}
              >
                🔄 Jugar de Nuevo
              </button>
              <button
                onClick={onGameEnd}
                style={{
                  padding: '14px',
                  background: 'rgba(255,255,255,0.06)',
                  border: '1px solid rgba(255,255,255,0.12)',
                  borderRadius: 14,
                  color: '#7a7aaa', fontSize: 15, fontWeight: 700,
                  fontFamily: 'Nunito, sans-serif', cursor: 'pointer',
                }}
              >
                Volver al Menú
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
