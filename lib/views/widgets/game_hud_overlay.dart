import 'package:flutter/material.dart';
import '../../viewmodels/game_3d_viewmodel.dart';

/// Superposición de Interfaz de Usuario (HUD de Botones e Información) sobre el escenario 3D
class GameHudOverlay extends StatelessWidget {
  final Game3DViewModel game3DViewModel;
  final VoidCallback onExit;
  final VoidCallback? onResetMouseRotation;

  const GameHudOverlay({
    super.key,
    required this.game3DViewModel,
    required this.onExit,
    this.onResetMouseRotation,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              // Barra Superior (Botón Salir + Botón Reset Mouse + Estado + Botón UNO!)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // Botón Salir (Área táctil >= 48x48 dp)
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                        child: InkWell(
                          onTap: onExit,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Row(
                              children: <Widget>[
                                Icon(Icons.arrow_back, color: Colors.white, size: 18),
                                SizedBox(width: 6),
                                Text('Menú', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ),

                      if (onResetMouseRotation != null) ...<Widget>[
                        const SizedBox(width: 8),
                        // Botón de Restablecer Rotación de Mouse para Desarrollo en PC
                        ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                          child: InkWell(
                            onTap: onResetMouseRotation,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.shade900,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.6)),
                              ),
                              child: const Row(
                                children: <Widget>[
                                  Icon(Icons.mouse, color: Colors.cyanAccent, size: 16),
                                  SizedBox(width: 4),
                                  Text('Reset', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Mensaje de Estado e Indicador de Modo
                  Flexible(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber, width: 1.5),
                      ),
                      child: Text(
                        game3DViewModel.statusMessage,
                        style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),

                  // Botón Gritar "UNO!" (Área táctil >= 48x48 dp)
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    child: ElevatedButton(
                      onPressed: () => game3DViewModel.shoutUno('Tú'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE63946),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text('¡UNO!', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
