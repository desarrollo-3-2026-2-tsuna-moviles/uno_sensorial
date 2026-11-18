import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_view.dart';

/// Pantalla de Sala de Espera 100% Responsiva y Optimizada a 120 FPS
class WaitingRoomView extends StatefulWidget {
  final AppUser user;
  final String roomCode;
  final bool isHost;
  final VoidCallback onStartGame;
  final VoidCallback onBack;

  const WaitingRoomView({
    super.key,
    required this.user,
    required this.roomCode,
    required this.isHost,
    required this.onStartGame,
    required this.onBack,
  });

  @override
  State<WaitingRoomView> createState() => _WaitingRoomViewState();
}

class _WaitingRoomViewState extends State<WaitingRoomView> {
  bool _myReady = false;
  bool _copied = false;

  final List<Color> _playerColors = const <Color>[
    Color(0xFFE63946),
    Color(0xFFFFD60A),
    Color(0xFF2EC4B6),
    Color(0xFF4CC9F0),
  ];

  void _handleCopyCode() {
    Clipboard.setData(ClipboardData(text: widget.roomCode));
    setState(() => _copied = true);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> roomPlayers = <Map<String, dynamic>>[
      <String, dynamic>{'name': widget.user.name, 'ready': widget.isHost || _myReady, 'isMe': true, 'isHost': widget.isHost},
      <String, dynamic>{'name': 'Luna', 'ready': true, 'isMe': false, 'isHost': !widget.isHost},
      <String, dynamic>{'name': 'Rayo', 'ready': false, 'isMe': false, 'isHost': false},
    ];

    final bool canStart = widget.isHost && roomPlayers.length >= 2;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Color(0xFF0D0D1A),
              Color(0xFF0D1030),
              Color(0xFF0D1A2E),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: <Widget>[
                      // Cabecera
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Row(
                          children: <Widget>[
                            InkWell(
                              onTap: widget.onBack,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.07),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                                ),
                                child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFF0F0F0), size: 16),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Text(
                                    'Sala de Espera',
                                    style: TextStyle(color: Color(0xFFF0F0F0), fontWeight: FontWeight.w900, fontSize: 22),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    widget.isHost ? 'Eres el anfitrión' : 'Esperando al anfitrión...',
                                    style: const TextStyle(color: Color(0xFF7A7AAA), fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            // Bloque Responsivo de Código de Sala Aislado con RepaintBoundary
                            RepaintBoundary(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                ),
                                child: Column(
                                  children: <Widget>[
                                    const Text(
                                      'CÓDIGO DE SALA',
                                      style: TextStyle(
                                        color: Color(0xFF7A7AAA),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 12,
                                      runSpacing: 8,
                                      children: <Widget>[
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            widget.roomCode,
                                            style: const TextStyle(
                                              color: Color(0xFFFFD60A),
                                              fontWeight: FontWeight.w900,
                                              fontSize: 34,
                                              letterSpacing: 4,
                                              shadows: <Shadow>[
                                                Shadow(color: Color(0x66FFD60A), blurRadius: 20),
                                              ],
                                            ),
                                          ),
                                        ),
                                        OutlinedButton(
                                          onPressed: _handleCopyCode,
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: _copied ? const Color(0xFF2EC4B6) : const Color(0xFF7A7AAA),
                                            side: BorderSide(
                                              color: _copied ? const Color(0xFF2EC4B6) : Colors.white.withValues(alpha: 0.15),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: Text(_copied ? '✓ Copiado' : '📋 Copiar', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Comparte este código con tus amigos',
                                      style: TextStyle(color: Color(0xFF7A7AAA), fontSize: 12),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Lista de Jugadores Aislada con RepaintBoundary
                            RepaintBoundary(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                ),
                                child: Column(
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                      child: Row(
                                        children: <Widget>[
                                          Text(
                                            'Jugadores (${roomPlayers.length}/4)',
                                            style: const TextStyle(color: Color(0xFFF0F0F0), fontWeight: FontWeight.w900, fontSize: 16),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),

                                    for (int i = 0; i < roomPlayers.length; i++) ...<Widget>[
                                      ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                                        leading: CircleAvatar(
                                          radius: 18,
                                          backgroundColor: _playerColors[i % _playerColors.length],
                                          child: Text(
                                            (roomPlayers[i]['name'] as String)[0].toUpperCase(),
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                                          ),
                                        ),
                                        title: Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: Text(
                                                '${roomPlayers[i]['name']}${(roomPlayers[i]['isMe'] as bool) ? ' (tú)' : ''}',
                                                style: const TextStyle(color: Color(0xFFF0F0F0), fontWeight: FontWeight.bold, fontSize: 14),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        subtitle: (roomPlayers[i]['isHost'] as bool)
                                            ? const Text('👑 Anfitrión', style: TextStyle(color: Color(0xFFFFD60A), fontSize: 11, fontWeight: FontWeight.bold))
                                            : null,
                                        trailing: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: (roomPlayers[i]['ready'] as bool) ? const Color(0x262EC4B6) : const Color(0x267A7AAA),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: (roomPlayers[i]['ready'] as bool) ? const Color(0x4D2EC4B6) : const Color(0x337A7AAA),
                                            ),
                                          ),
                                          child: Text(
                                            (roomPlayers[i]['ready'] as bool) ? '✓ Listo' : 'Esperando',
                                            style: TextStyle(
                                              color: (roomPlayers[i]['ready'] as bool) ? const Color(0xFF2EC4B6) : const Color(0xFF7A7AAA),
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (i < roomPlayers.length - 1) Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            if (!widget.isHost) ...<Widget>[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CC9F0).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF4CC9F0).withValues(alpha: 0.2)),
                                ),
                                child: const Row(
                                  children: <Widget>[
                                    Icon(Icons.wifi, color: Color(0xFF4CC9F0), size: 18),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Esperando que el anfitrión inicie la partida...',
                                        style: TextStyle(color: Color(0xFF4CC9F0), fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),

                              ElevatedButton(
                                onPressed: () => setState(() => _myReady = !_myReady),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _myReady ? const Color(0x262EC4B6) : const Color(0xFF2EC4B6),
                                  foregroundColor: _myReady ? const Color(0xFF2EC4B6) : Colors.white,
                                  minimumSize: const Size(double.infinity, 48),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  side: _myReady ? const BorderSide(color: Color(0xFF2EC4B6), width: 2) : null,
                                  elevation: _myReady ? 0 : 6,
                                ),
                                child: Text(_myReady ? '✓ Listo' : '¡Listo!', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                              ),
                            ] else ...<Widget>[
                              ElevatedButton(
                                onPressed: canStart ? widget.onStartGame : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE63946),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.white.withValues(alpha: 0.06),
                                  disabledForegroundColor: const Color(0xFF4A4A6A),
                                  minimumSize: const Size(double.infinity, 48),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: canStart ? 6 : 0,
                                ),
                                child: Text(
                                  canStart ? '🚀 Iniciar Partida' : '⏳ Esperando jugadores...',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
