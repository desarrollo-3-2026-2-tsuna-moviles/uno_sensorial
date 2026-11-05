import type { Card, CardColor, CardValue, GameState, Player } from '../types/uno';

const COLORS: CardColor[] = ['red', 'yellow', 'green', 'blue'];
const AI_NAMES = ['Luna', 'Rayo', 'Nova', 'Max'];

export function shuffle<T>(arr: T[]): T[] {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

export function createDeck(): Card[] {
  const cards: Card[] = [];
  let id = 0;
  for (const color of COLORS) {
    cards.push({ id: `${id++}`, color, value: '0' });
    for (let n = 1; n <= 9; n++) {
      const v = String(n) as CardValue;
      cards.push({ id: `${id++}`, color, value: v });
      cards.push({ id: `${id++}`, color, value: v });
    }
    for (const v of ['skip', 'reverse', 'draw2'] as CardValue[]) {
      cards.push({ id: `${id++}`, color, value: v });
      cards.push({ id: `${id++}`, color, value: v });
    }
  }
  for (let i = 0; i < 4; i++) {
    cards.push({ id: `${id++}`, color: 'wild', value: 'wild' });
    cards.push({ id: `${id++}`, color: 'wild', value: 'wild4' });
  }
  return cards;
}

export function canPlayCard(card: Card, topCard: Card, currentColor: CardColor): boolean {
  if (card.color === 'wild') return true;
  if (card.color === currentColor) return true;
  if (card.value === topCard.value) return true;
  return false;
}

export function initGame(playerName: string, opponentCount: number): GameState {
  const players: Player[] = [
    { id: 'player', name: playerName, isAI: false, hand: [], saidUno: false },
    ...Array.from({ length: opponentCount }, (_, i) => ({
      id: `ai${i}`,
      name: AI_NAMES[i % AI_NAMES.length],
      isAI: true,
      hand: [],
      saidUno: false,
    })),
  ];

  const deck = shuffle(createDeck());

  for (const player of players) {
    player.hand = deck.splice(0, 7);
  }

  let startIdx = deck.findIndex(c => c.value !== 'wild' && c.value !== 'wild4' && c.value !== 'skip');
  if (startIdx === -1) startIdx = 0;
  const [startCard] = deck.splice(startIdx, 1);

  return {
    players,
    deck,
    discardPile: [startCard],
    currentPlayerIndex: 0,
    direction: 1,
    currentColor: startCard.color,
    phase: 'playing',
    winner: null,
    pendingDraw: startCard.value === 'draw2' ? 2 : 0,
    message: `¡Que comience el UNO! Turno de ${players[0].name}`,
    turnKey: 0,
  };
}

export function playCard(
  state: GameState,
  playerIndex: number,
  cardIndex: number,
  chosenColor?: CardColor,
): GameState {
  const player = state.players[playerIndex];
  const card = player.hand[cardIndex];
  const newHand = player.hand.filter((_, i) => i !== cardIndex);
  const saidUno = newHand.length === 1;

  const newPlayers = state.players.map((p, i) =>
    i === playerIndex ? { ...p, hand: newHand, saidUno } : { ...p, saidUno: false },
  );

  const newDiscard = [...state.discardPile, card];
  const newColor: CardColor = chosenColor ?? (card.color === 'wild' ? 'red' : card.color);
  const n = newPlayers.length;
  let dir = state.direction;
  let pending = 0;
  let skipNext = false;

  if (card.value === 'reverse') {
    dir = dir === 1 ? -1 : 1;
    if (n === 2) skipNext = true;
  }
  if (card.value === 'skip') skipNext = true;
  if (card.value === 'draw2') { pending = state.pendingDraw + 2; skipNext = true; }
  if (card.value === 'wild4') { pending = state.pendingDraw + 4; skipNext = true; }

  let next = ((playerIndex + dir) + n) % n;
  if (skipNext) next = ((next + dir) + n) % n;

  if (newHand.length === 0) {
    return {
      ...state,
      players: newPlayers,
      discardPile: newDiscard,
      currentColor: newColor,
      phase: 'game-over',
      winner: playerIndex,
      message: `¡${player.name} ganó! 🎉`,
      turnKey: state.turnKey + 1,
      direction: dir,
      pendingDraw: pending,
      currentPlayerIndex: playerIndex,
    };
  }

  return {
    ...state,
    players: newPlayers,
    discardPile: newDiscard,
    direction: dir,
    currentColor: newColor,
    currentPlayerIndex: next,
    pendingDraw: pending,
    phase: 'playing',
    message: saidUno
      ? `¡${player.name} dijo UNO! Turno de ${newPlayers[next].name}`
      : `Turno de ${newPlayers[next].name}`,
    turnKey: state.turnKey + 1,
  };
}

function reshuffleIfNeeded(state: GameState): GameState {
  if (state.deck.length > 0) return state;
  const top = state.discardPile[state.discardPile.length - 1];
  return { ...state, deck: shuffle(state.discardPile.slice(0, -1)), discardPile: [top] };
}

export function drawCards(state: GameState, playerIndex: number, count: number): GameState {
  let s = reshuffleIfNeeded(state);
  const drawn: Card[] = [];
  const deckCopy = [...s.deck];
  for (let i = 0; i < count && deckCopy.length > 0; i++) {
    drawn.push(deckCopy.shift()!);
  }
  const newPlayers = s.players.map((p, i) =>
    i === playerIndex ? { ...p, hand: [...p.hand, ...drawn] } : p,
  );
  const n = newPlayers.length;
  const next = ((playerIndex + s.direction) + n) % n;
  return {
    ...s,
    deck: deckCopy,
    players: newPlayers,
    currentPlayerIndex: next,
    pendingDraw: 0,
    message: `${s.players[playerIndex].name} robó ${count} carta${count !== 1 ? 's' : ''}. Turno de ${newPlayers[next].name}`,
    turnKey: s.turnKey + 1,
  };
}

export function getAIMove(
  state: GameState,
  playerIndex: number,
): { cardIndex: number; chosenColor?: CardColor } | null {
  const player = state.players[playerIndex];
  const topCard = state.discardPile[state.discardPile.length - 1];

  if (state.pendingDraw > 0) {
    const stackIdx = player.hand.findIndex(c =>
      (topCard.value === 'draw2' && c.value === 'draw2') ||
      (topCard.value === 'wild4' && c.value === 'wild4'),
    );
    return stackIdx !== -1 ? { cardIndex: stackIdx } : null;
  }

  const playable = player.hand
    .map((card, idx) => ({ card, idx }))
    .filter(({ card }) => canPlayCard(card, topCard, state.currentColor));

  if (playable.length === 0) return null;

  const priority = (card: Card) => {
    if (card.value === 'draw2' || card.value === 'skip' || card.value === 'reverse') return 3;
    if (card.color !== 'wild') return 2;
    return card.value === 'wild' ? 1 : 0;
  };

  playable.sort((a, b) => priority(b.card) - priority(a.card));
  const chosen = playable[0];

  let chosenColor: CardColor | undefined;
  if (chosen.card.color === 'wild') {
    const counts: Partial<Record<CardColor, number>> = {};
    for (const c of player.hand) {
      if (c.color !== 'wild') counts[c.color] = (counts[c.color] ?? 0) + 1;
    }
    chosenColor = COLORS.reduce((a, b) => (counts[a] ?? 0) >= (counts[b] ?? 0) ? a : b);
  }

  return { cardIndex: chosen.idx, chosenColor };
}
