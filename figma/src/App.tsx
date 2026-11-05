import { useState } from 'react';
import type { AppUser, AppScreen } from './types/uno';
import LoginScreen from './screens/LoginScreen';
import MenuScreen from './screens/MenuScreen';
import MultiplayerScreen from './screens/MultiplayerScreen';
import WaitingRoomScreen from './screens/WaitingRoomScreen';
import SettingsScreen from './screens/SettingsScreen';
import GameScreen from './screens/GameScreen';

interface AppState {
  screen: AppScreen;
  user: AppUser | null;
  roomCode: string;
  isHost: boolean;
  opponentCount: number;
}

export default function App() {
  const [state, setState] = useState<AppState>({
    screen: 'login',
    user: null,
    roomCode: '',
    isHost: false,
    opponentCount: 2,
  });

  const go = (screen: AppScreen, extra?: Partial<AppState>) =>
    setState(prev => ({ ...prev, screen, ...extra }));

  const handleLogin = (user: AppUser) => go('menu', { user });

  const handleCreateRoom = (code: string) => go('waiting-room', { roomCode: code, isHost: true });

  const handleJoinRoom = (code: string) => go('waiting-room', { roomCode: code, isHost: false });

  const handleStart = (opponentCount: number) => go('game', { opponentCount });

  const handleLogout = () =>
    setState({ screen: 'login', user: null, roomCode: '', isHost: false, opponentCount: 2 });

  const { screen, user } = state;

  return (
    <div style={{ height: '100%', overflow: 'hidden' }}>
      {screen === 'login' && (
        <LoginScreen onLogin={handleLogin} />
      )}

      {screen === 'menu' && user && (
        <MenuScreen
          user={user}
          onSolo={() => go('game', { opponentCount: 2 })}
          onMultiplayer={() => go('multiplayer')}
          onSettings={() => go('settings')}
        />
      )}

      {screen === 'multiplayer' && (
        <MultiplayerScreen
          onCreateRoom={handleCreateRoom}
          onJoinRoom={handleJoinRoom}
          onBack={() => go('menu')}
        />
      )}

      {screen === 'waiting-room' && user && (
        <WaitingRoomScreen
          user={user}
          roomCode={state.roomCode}
          isHost={state.isHost}
          onStart={handleStart}
          onBack={() => go('multiplayer')}
        />
      )}

      {screen === 'settings' && user && (
        <SettingsScreen
          user={user}
          onBack={() => go('menu')}
          onLogout={handleLogout}
        />
      )}

      {screen === 'game' && user && (
        <GameScreen
          playerName={user.name}
          opponentCount={state.opponentCount}
          onGameEnd={() => go('menu')}
        />
      )}
    </div>
  );
}
