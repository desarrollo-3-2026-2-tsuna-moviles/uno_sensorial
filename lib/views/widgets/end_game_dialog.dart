import 'package:flutter/material.dart';
import '../../models/player_model.dart';

/// Diálogo de Fin de Partida (RF-14): muestra al ganador y el resumen de la mesa.
/// Solo presentación: quien lo abra decide cuándo y qué hacer con los botones.
class EndGameDialog extends StatelessWidget {
  final PlayerModel winner;

  /// Todos los jugadores de la partida (el ganador incluido).
  final List<PlayerModel> players;

  /// Id del jugador local, para mostrar "¡Ganaste!" o "Perdiste".
  final String localPlayerId;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  const EndGameDialog({
    super.key,
    required this.winner,
    required this.players,
    required this.localPlayerId,
    required this.onPlayAgain,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final bool localWon = winner.id == localPlayerId;

    // Clasificación: menos cartas restantes = mejor puesto (el ganador no tiene ninguna)
    final List<PlayerModel> standings = List<PlayerModel>.of(players)
      ..sort((PlayerModel a, PlayerModel b) => a.cardCount.compareTo(b.cardCount));

    return Dialog(
      backgroundColor: const Color(0xFF16163A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(localWon ? '🏆' : '🃏', textAlign: TextAlign.center, style: const TextStyle(fontSize: 44)),
              const SizedBox(height: 8),
              Text(
                localWon ? '¡Ganaste!' : 'Ganó ${winner.name}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFF0F0F0), fontWeight: FontWeight.w900, fontSize: 24),
              ),
              const SizedBox(height: 4),
              const Text(
                'Resumen de la partida',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF7A7AAA), fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              for (int i = 0; i < standings.length; i++) _StandingRow(
                position: i + 1,
                player: standings[i],
                isWinner: standings[i].id == winner.id,
                isLocal: standings[i].id == localPlayerId,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onPlayAgain,
                icon: const Icon(Icons.replay_rounded, size: 22),
                label: const Text('Jugar de nuevo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE63946),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(48, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: onExit,
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                child: const Text('Volver al menú', style: TextStyle(color: Color(0xFF7A7AAA))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StandingRow extends StatelessWidget {
  final int position;
  final PlayerModel player;
  final bool isWinner;
  final bool isLocal;

  const _StandingRow({
    required this.position,
    required this.player,
    required this.isWinner,
    required this.isLocal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isWinner ? const Color(0xFFFFD700).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isWinner ? Colors.amberAccent : Colors.white12),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 24,
            child: Text('$position', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w900)),
          ),
          Expanded(
            child: Text(
              isLocal ? '${player.name} (Tú)' : player.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFFF0F0F0), fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            isWinner ? 'Sin cartas' : '${player.cardCount} cartas',
            style: TextStyle(
              color: isWinner ? Colors.amberAccent : const Color(0xFF7A7AAA),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
