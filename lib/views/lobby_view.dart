import 'package:flutter/material.dart';
import '../models/player_model.dart';
import '../viewmodels/lobby_viewmodel.dart';
import '../viewmodels/sensor_viewmodel.dart';
import 'game_3d_view.dart';

/// Vista de la arquitectura MVVM para el Lobby Multijugador LAN
class LobbyView extends StatefulWidget {
  final LobbyViewModel lobbyViewModel;
  final SensorViewModel sensorViewModel;

  const LobbyView({
    super.key,
    required this.lobbyViewModel,
    required this.sensorViewModel,
  });

  @override
  State<LobbyView> createState() => _LobbyViewState();
}

class _LobbyViewState extends State<LobbyView> {
  final TextEditingController _hostIpController = TextEditingController();

  @override
  void dispose() {
    _hostIpController.dispose();
    super.dispose();
  }

  void _onStartHost() async {
    final bool success = await widget.lobbyViewModel.startHost();
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sala Host creada en ${widget.lobbyViewModel.localIp}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al crear la sala Host'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onConnectToHost() async {
    final String hostIp = _hostIpController.text.trim();
    if (hostIp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa la dirección IP del Host')),
      );
      return;
    }

    final bool success = await widget.lobbyViewModel.connectToHost(hostIp);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Conectado exitosamente al Host $hostIp'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo conectar a $hostIp'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _enterGame() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Game3DView(
          lobbyViewModel: widget.lobbyViewModel,
          sensorViewModel: widget.sensorViewModel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.lobbyViewModel,
      builder: (BuildContext context, Widget? child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Lobby Multijugador - UNO MVVM'),
            centerTitle: true,
            actions: <Widget>[
              IconButton(
                tooltip: 'Refrescar IP',
                icon: const Icon(Icons.refresh),
                onPressed: widget.lobbyViewModel.fetchLocalIp,
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Tarjeta de IP Local
                Card(
                  color: Colors.blueGrey.shade900,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.wifi, color: Colors.cyanAccent, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text('Tu Dirección IP LAN:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 2),
                              Text(
                                widget.lobbyViewModel.localIp,
                                style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                if (!widget.lobbyViewModel.isConnected) ...<Widget>[
                  // Crear Sala Host
                  ElevatedButton.icon(
                    onPressed: widget.lobbyViewModel.isLoading ? null : _onStartHost,
                    icon: const Icon(Icons.dns),
                    label: const Text('Crear Sala (Ser Host)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Row(
                    children: <Widget>[
                      Expanded(child: Divider(color: Colors.white24)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('O UNIRSE A HOST', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ),
                      Expanded(child: Divider(color: Colors.white24)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Unirse a Sala mediante IP
                  TextField(
                    controller: _hostIpController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Dirección IP del Host',
                      hintText: 'Ej. 192.168.1.15',
                      prefixIcon: const Icon(Icons.computer),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: widget.lobbyViewModel.isLoading ? null : _onConnectToHost,
                    icon: const Icon(Icons.login),
                    label: const Text('Unirse a Sala (Cliente)'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.cyanAccent),
                      foregroundColor: Colors.cyanAccent,
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ] else ...<Widget>[
                  // Jugadores Conectados
                  Card(
                    color: Colors.green.shade900.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                widget.lobbyViewModel.isHost ? 'HOST DE SALA' : 'CLIENTE CONECTADO',
                                style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.power_settings_new, color: Colors.redAccent),
                                onPressed: widget.lobbyViewModel.disconnect,
                                tooltip: 'Desconectar',
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white24),
                          const SizedBox(height: 8),
                          Text(
                            'Jugadores (${widget.lobbyViewModel.players.length}):',
                            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          for (final PlayerModel player in widget.lobbyViewModel.players)
                            ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                backgroundColor: player.id == widget.lobbyViewModel.myPlayerId ? Colors.blueAccent : Colors.amber,
                                child: Text('${player.seatIndex + 1}'),
                              ),
                              title: Text(
                                '${player.name} ${player.id == widget.lobbyViewModel.myPlayerId ? "(Tú)" : ""}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('Asiento: ${player.seatIndex + 1}'),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    onPressed: _enterGame,
                    icon: const Icon(Icons.view_in_ar, size: 24),
                    label: const Text('ENTRAR A LA MESA 3D'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],

                if (widget.lobbyViewModel.isLoading) ...<Widget>[
                  const SizedBox(height: 24),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
