import type { Card, CardColor } from '../types/uno';

const COLOR_BG: Record<CardColor, string> = {
  red: '#E63946',
  yellow: '#FFD60A',
  green: '#2EC4B6',
  blue: '#4CC9F0',
  wild: '#1a1040',
};

const COLOR_DARK: Record<CardColor, string> = {
  red: '#8B1C24',
  yellow: '#9B7E00',
  green: '#1A7268',
  blue: '#1565A3',
  wild: '#0d0d1a',
};

const COLOR_TEXT: Record<CardColor, string> = {
  red: '#FFFFFF',
  yellow: '#1a1a00',
  green: '#FFFFFF',
  blue: '#FFFFFF',
  wild: '#FFFFFF',
};

const VALUE_LABEL: Record<string, string> = {
  '0': '0', '1': '1', '2': '2', '3': '3', '4': '4',
  '5': '5', '6': '6', '7': '7', '8': '8', '9': '9',
  skip: '⊘', reverse: '↺', draw2: '+2', wild: '', wild4: '',
};

const SIZES = {
  xs: { w: 36, h: 54, corner: 7, center: 13, r: 5 },
  sm: { w: 48, h: 72, corner: 8, center: 17, r: 6 },
  md: { w: 64, h: 96, corner: 10, center: 22, r: 8 },
  lg: { w: 90, h: 135, corner: 14, center: 32, r: 11 },
};

interface UnoCardProps {
  card: Card;
  size?: keyof typeof SIZES;
  faceDown?: boolean;
  onClick?: () => void;
  playable?: boolean;
  shake?: boolean;
  selected?: boolean;
  className?: string;
  style?: React.CSSProperties;
}

export default function UnoCard({
  card,
  size = 'md',
  faceDown = false,
  onClick,
  playable,
  shake,
  selected,
  className = '',
  style,
}: UnoCardProps) {
  const { w, h, corner, center, r } = SIZES[size];
  const label = VALUE_LABEL[card.value] ?? card.value;
  const isWild = card.color === 'wild';

  const baseStyle: React.CSSProperties = {
    width: w,
    height: h,
    borderRadius: r,
    flexShrink: 0,
    position: 'relative',
    overflow: 'hidden',
    border: '2px solid rgba(255,255,255,0.35)',
    cursor: onClick ? 'pointer' : 'default',
    userSelect: 'none',
    transition: 'transform 0.15s ease, box-shadow 0.15s ease, opacity 0.15s ease',
    ...(selected && { transform: 'translateY(-16px)', boxShadow: '0 8px 24px rgba(0,0,0,0.5)' }),
    ...style,
  };

  if (faceDown) {
    return (
      <div
        className={`${className} ${shake ? 'animate-shake' : ''}`}
        style={baseStyle}
        onClick={onClick}
      >
        <div style={{
          position: 'absolute', inset: 0,
          background: 'linear-gradient(135deg, #C41E3A 0%, #8B1C24 100%)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <div style={{
            border: '2px solid rgba(255,255,255,0.25)',
            borderRadius: r - 2,
            padding: '4px 8px',
            transform: 'rotate(-15deg)',
          }}>
            <span style={{
              fontFamily: 'Fredoka One, cursive',
              color: '#FFD60A',
              fontSize: Math.round(center * 0.85),
              fontWeight: 900,
              letterSpacing: 1,
            }}>UNO</span>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div
      className={`${className} ${shake ? 'animate-shake' : ''} ${playable === false ? 'opacity-40' : ''}`}
      style={{
        ...baseStyle,
        backgroundColor: COLOR_BG[card.color],
        boxShadow: playable
          ? `0 0 14px 3px ${COLOR_BG[card.color]}88`
          : '0 3px 10px rgba(0,0,0,0.4)',
      }}
      onClick={onClick}
    >
      {/* White inner frame */}
      <div style={{
        position: 'absolute', inset: 3,
        borderRadius: r - 2,
        border: '1.5px solid rgba(255,255,255,0.25)',
        pointerEvents: 'none',
      }} />

      {/* Top-left corner */}
      <span style={{
        position: 'absolute', top: 3, left: 5,
        color: COLOR_TEXT[card.color],
        fontSize: corner,
        fontWeight: 900,
        lineHeight: 1,
        fontFamily: 'Fredoka One, cursive',
        textShadow: '0 1px 2px rgba(0,0,0,0.3)',
      }}>{label}</span>

      {/* Center oval */}
      <div style={{
        position: 'absolute',
        inset: '14%',
        borderRadius: '50%',
        transform: 'rotate(28deg)',
        overflow: 'hidden',
        backgroundColor: isWild ? undefined : COLOR_DARK[card.color],
      }}>
        {isWild ? (
          <>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gridTemplateRows: '1fr 1fr', width: '100%', height: '100%' }}>
              <div style={{ backgroundColor: '#E63946' }} />
              <div style={{ backgroundColor: '#FFD60A' }} />
              <div style={{ backgroundColor: '#4CC9F0' }} />
              <div style={{ backgroundColor: '#2EC4B6' }} />
            </div>
            <div style={{
              position: 'absolute', inset: 0,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <span style={{
                color: '#fff',
                fontFamily: 'Fredoka One, cursive',
                fontSize: center * 0.85,
                fontWeight: 900,
                transform: 'rotate(-28deg)',
                textShadow: '0 1px 4px rgba(0,0,0,0.7)',
              }}>{card.value === 'wild4' ? '+4' : 'W'}</span>
            </div>
          </>
        ) : (
          <div style={{ width: '100%', height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <span style={{
              color: '#fff',
              fontFamily: 'Fredoka One, cursive',
              fontSize: center,
              fontWeight: 900,
              transform: 'rotate(-28deg)',
              textShadow: '0 1px 3px rgba(0,0,0,0.3)',
            }}>{label}</span>
          </div>
        )}
      </div>

      {/* Bottom-right corner */}
      <span style={{
        position: 'absolute', bottom: 3, right: 5,
        color: COLOR_TEXT[card.color],
        fontSize: corner,
        fontWeight: 900,
        lineHeight: 1,
        transform: 'rotate(180deg)',
        fontFamily: 'Fredoka One, cursive',
        textShadow: '0 1px 2px rgba(0,0,0,0.3)',
      }}>{label}</span>
    </div>
  );
}
