export type CardColor = 'red' | 'yellow' | 'green' | 'blue' | 'wild';
export type CardValue =
  | '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9'
  | 'skip' | 'reverse' | 'draw2' | 'wild' | 'wild4';

export interface Card {
  id: string;
  color: CardColor;
  value: CardValue;
}

export type GamePhase = 'playing' | 'game-over';

export interface Player {
  id: string;
  name: string;
  isAI: boolean;
  hand: Card[];
  saidUno: boolean;
}

export interface GameState {
  players: Player[];
  deck: Card[];
  discardPile: Card[];
  currentPlayerIndex: number;
  direction: 1 | -1;
  currentColor: CardColor;
  phase: GamePhase;
  winner: number | null;
  pendingDraw: number;
  message: string;
  turnKey: number;
}

export interface AppUser {
  name: string;
  initial: string;
  method: 'google' | 'local';
}

export type AppScreen = 'login' | 'menu' | 'multiplayer' | 'waiting-room' | 'settings' | 'game';
