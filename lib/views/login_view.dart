import 'dart:math';
import 'package:flutter/material.dart';

/// Modelo ligero para el usuario autenticado
class AppUser {
  final String name;
  final String initial;
  final String method; // 'google' o 'local'

  const AppUser({
    required this.name,
    required this.initial,
    required this.method,
  });
}

/// Pantalla de Inicio de Sesión 100% Responsiva y Optimizada a 120 FPS
class LoginView extends StatefulWidget {
  final Function(AppUser user) onLogin;

  const LoginView({
    super.key,
    required this.onLogin,
  });

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  String _mode = 'choose'; // 'choose' o 'local'
  final TextEditingController _nameController = TextEditingController();
  String _errorMessage = '';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleGoogleLogin() {
    widget.onLogin(const AppUser(
      name: 'Jugador Google',
      initial: 'J',
      method: 'google',
    ));
  }

  void _handleLocalLogin() {
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Ingresa un nombre');
      return;
    }
    widget.onLogin(AppUser(
      name: name,
      initial: name[0].toUpperCase(),
      method: 'local',
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Color(0xFF0D0D1A),
              Color(0xFF1A0A2E),
              Color(0xFF0D1A2E),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            // Cartas Flotantes Decorativas con Aislamiento de Pintura RepaintBoundary (Sin Opacity saveLayer)
            const RepaintBoundary(
              child: _FloatingCardsBackground(),
            ),

            // Estructura de Scroll Responsivo y Optimizado
            SafeArea(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 400),
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                            decoration: BoxDecoration(
                              color: const Color(0xF116163A),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                              boxShadow: const <BoxShadow>[
                                BoxShadow(
                                  color: Colors.black54,
                                  blurRadius: 40,
                                  offset: Offset(0, 20),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                // Insignia / Logo de UNO
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: <Color>[Color(0xFFE63946), Color(0xFFC41E3A)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: const <BoxShadow>[
                                      BoxShadow(
                                        color: Color(0x80E63946),
                                        blurRadius: 20,
                                        offset: Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    'UNO',
                                    style: TextStyle(
                                      color: Color(0xFFFFD60A),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 44,
                                      letterSpacing: 4,
                                      shadows: <Shadow>[
                                        Shadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'El juego de cartas más épico',
                                  style: TextStyle(color: Color(0xFF7A7AAA), fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 28),

                                if (_mode == 'choose') ...<Widget>[
                                  // Botón Continuar con Google
                                  ElevatedButton(
                                    onPressed: _handleGoogleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF1A1A2E),
                                      minimumSize: const Size(double.infinity, 48),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      elevation: 4,
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: <Widget>[
                                        Icon(Icons.g_mobiledata, size: 28, color: Color(0xFF4285F4)),
                                        SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            'Continuar con Google',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Divisor "o"
                                  Row(
                                    children: <Widget>[
                                      Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 12),
                                        child: Text('o', style: TextStyle(color: Color(0xFF7A7AAA), fontSize: 13)),
                                      ),
                                      Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Botón Red Local / Sin Cuenta
                                  OutlinedButton.icon(
                                    onPressed: () => setState(() => _mode = 'local'),
                                    icon: const Icon(Icons.cast, size: 20),
                                    label: const Text(
                                      'Red local / Sin cuenta',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFF0F0F0),
                                      side: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                                      minimumSize: const Size(double.infinity, 48),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ),
                                ] else ...<Widget>[
                                  // Modo Local
                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Tu nombre',
                                      style: TextStyle(color: Color(0xFF7A7AAA), fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _nameController,
                                    maxLength: 16,
                                    style: const TextStyle(color: Color(0xFFF0F0F0), fontSize: 16),
                                    decoration: InputDecoration(
                                      hintText: 'Ej: Jugador1',
                                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                                      filled: true,
                                      fillColor: Colors.white.withValues(alpha: 0.07),
                                      errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: Color(0xFFE63946), width: 1.5),
                                      ),
                                    ),
                                    onSubmitted: (_) => _handleLocalLogin(),
                                  ),
                                  const SizedBox(height: 16),

                                  ElevatedButton(
                                    onPressed: _handleLocalLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE63946),
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(double.infinity, 48),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      elevation: 6,
                                    ),
                                    child: const Text(
                                      'Entrar al juego',
                                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _mode = 'choose';
                                        _errorMessage = '';
                                        _nameController.clear();
                                      });
                                    },
                                    child: const Text('← Volver', style: TextStyle(color: Color(0xFF7A7AAA))),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renderiza las cartas flotantes traslúcidas de fondo optimizadas sin Opacity saveLayer
class _FloatingCardsBackground extends StatelessWidget {
  const _FloatingCardsBackground();

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> cards = <Map<String, dynamic>>[
      <String, dynamic>{'color': const Color(0xFFE63946), 'rot': -0.26, 'x': -0.38, 'y': -0.35, 'label': '7'},
      <String, dynamic>{'color': const Color(0xFFFFD60A), 'rot': 0.35, 'x': 0.38, 'y': -0.40, 'label': '+2'},
      <String, dynamic>{'color': const Color(0xFF2EC4B6), 'rot': -0.14, 'x': -0.40, 'y': 0.35, 'label': '↺'},
      <String, dynamic>{'color': const Color(0xFF4CC9F0), 'rot': 0.24, 'x': 0.40, 'y': 0.32, 'label': '⊘'},
      <String, dynamic>{'color': const Color(0xFFE63946), 'rot': 0.52, 'x': 0.32, 'y': -0.05, 'label': '3'},
      <String, dynamic>{'color': const Color(0xFF2EC4B6), 'rot': -0.35, 'x': -0.32, 'y': -0.02, 'label': '5'},
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double w = constraints.maxWidth;
        final double h = constraints.maxHeight;

        return Stack(
          children: cards.map((Map<String, dynamic> c) {
            final double cx = (w / 2) + (c['x'] as double) * w;
            final double cy = (h / 2) + (c['y'] as double) * h;
            final Color baseColor = c['color'] as Color;

            return Positioned(
              left: cx.clamp(0.0, max(0.0, w - 52)),
              top: cy.clamp(0.0, max(0.0, h - 78)),
              child: Transform.rotate(
                angle: c['rot'] as double,
                child: Container(
                  width: 52,
                  height: 78,
                  decoration: BoxDecoration(
                    color: baseColor.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      c['label'] as String,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
