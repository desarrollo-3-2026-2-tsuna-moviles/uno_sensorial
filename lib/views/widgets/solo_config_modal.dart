import 'package:flutter/material.dart';

/// Modal de Configuración Previa para Modo Un Jugador
/// Incluye un menú desplegable corto (1 a 5 jugadores/bots), el selector de dificultad
/// y botón para iniciar el escenario 3D.
class SoloConfigModal extends StatefulWidget {
  final Function(int botCount, String difficulty) onStartGame;

  const SoloConfigModal({
    super.key,
    required this.onStartGame,
  });

  @override
  State<SoloConfigModal> createState() => _SoloConfigModalState();
}

class _SoloConfigModalState extends State<SoloConfigModal> {
  int _selectedBotCount = 2; // Valor por defecto: 2 bots
  String _selectedDifficulty = 'Normal';

  static const List<String> _difficulties = <String>['Fácil', 'Normal', 'Difícil'];

  final List<Map<String, dynamic>> _botOptions = const <Map<String, dynamic>>[
    <String, dynamic>{'count': 1, 'label': '1 Bot (Partida 1v1)'},
    <String, dynamic>{'count': 2, 'label': '2 Bots (Partida de 3)'},
    <String, dynamic>{'count': 3, 'label': '3 Bots (Partida de 4)'},
    <String, dynamic>{'count': 4, 'label': '4 Bots (Partida de 5)'},
    <String, dynamic>{'count': 5, 'label': '5 Bots (Partida de 6)'},
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF16163A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Título
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE63946).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('🃏', style: TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Modo Un Jugador',
                    style: TextStyle(
                      color: Color(0xFFF0F0F0),
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Selector Desplegable (Dropdown) de 1 a 5 Jugadores/Bots
            const Text(
              'Seleccionar Cantidad de Rivales',
              style: TextStyle(color: Color(0xFF7A7AAA), fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<int>(
              initialValue: _selectedBotCount,
              isExpanded: true,
              dropdownColor: const Color(0xFF1A1A3A),
              style: const TextStyle(color: Color(0xFFF0F0F0), fontSize: 15, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.07),
                prefixIcon: const Icon(Icons.smart_toy, color: Color(0xFFE63946)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE63946), width: 1.5),
                ),
              ),
              items: _botOptions.map((Map<String, dynamic> opt) {
                return DropdownMenuItem<int>(
                  value: opt['count'] as int,
                  child: Text(opt['label'] as String),
                );
              }).toList(),
              onChanged: (int? val) {
                if (val != null) {
                  setState(() => _selectedBotCount = val);
                }
              },
            ),
            const SizedBox(height: 20),

            // Selector de dificultad
            const Text(
              'Dificultad de los Bots',
              style: TextStyle(color: Color(0xFF7A7AAA), fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: _difficulties
                  .map((String d) => ButtonSegment<String>(value: d, label: Text(d)))
                  .toList(),
              selected: <String>{_selectedDifficulty},
              onSelectionChanged: (Set<String> value) {
                setState(() => _selectedDifficulty = value.first);
              },
              style: SegmentedButton.styleFrom(
                minimumSize: const Size(48, 48),
                backgroundColor: Colors.white.withValues(alpha: 0.07),
                foregroundColor: const Color(0xFFF0F0F0),
                selectedBackgroundColor: const Color(0xFFE63946),
                selectedForegroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              ),
            ),
            const SizedBox(height: 24),

            // Botón de Iniciar Partida / Jugar
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onStartGame(_selectedBotCount, _selectedDifficulty);
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 24),
              label: const Text('🚀 Jugar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE63946),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                elevation: 6,
              ),
            ),
            const SizedBox(height: 8),

            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar', style: TextStyle(color: Color(0xFF7A7AAA))),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
