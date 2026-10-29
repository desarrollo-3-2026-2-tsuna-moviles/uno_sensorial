import 'dart:math';
import 'package:flutter/material.dart';

/// Pantalla del Menú Multijugador 100% Responsiva
class MultiplayerView extends StatefulWidget {
  final Function(String code) onCreateRoom;
  final Function(String code) onJoinRoom;
  final VoidCallback onBack;

  const MultiplayerView({
    super.key,
    required this.onCreateRoom,
    required this.onJoinRoom,
    required this.onBack,
  });

  @override
  State<MultiplayerView> createState() => _MultiplayerViewState();
}

class _MultiplayerViewState extends State<MultiplayerView> {
  String _mode = 'choose'; // 'choose' o 'join'
  final TextEditingController _codeController = TextEditingController();
  String _errorMessage = '';

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  String _generateRoomCode() {
    const String chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final Random random = Random();
    return List<String>.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  void _handleCreate() {
    final String code = _generateRoomCode();
    widget.onCreateRoom(code);
  }

  void _handleJoin() {
    final String code = _codeController.text.trim().toUpperCase();
    if (code.length < 4) {
      setState(() => _errorMessage = 'Ingresa un código válido');
      return;
    }
    widget.onJoinRoom(code);
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
                      // Cabecera con Botón Volver Responsivo
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Multijugador',
                                style: TextStyle(
                                  color: Color(0xFFF0F0F0),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Contenido Principal
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 380),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                // Ícono Central Brillante de Red Global
                                Container(
                                  width: 68,
                                  height: 68,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: <Color>[Color(0xFF4CC9F0), Color(0xFF1565A3)],
                                    ),
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                        color: Color(0x664CC9F0),
                                        blurRadius: 24,
                                        offset: Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.public, color: Colors.white, size: 34),
                                ),
                                const SizedBox(height: 18),

                                if (_mode == 'choose') ...<Widget>[
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: const Text(
                                      'Juega en red',
                                      style: TextStyle(
                                        color: Color(0xFFF0F0F0),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 28,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Crea una sala o únete a una existente',
                                    style: TextStyle(color: Color(0xFF7A7AAA), fontSize: 13),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),

                                  // Opción 1: Crear Partida
                                  _MultiplayerOptionButton(
                                    title: 'Crear Partida',
                                    subtitle: 'Genera un código para amigos',
                                    iconText: '➕',
                                    gradient: const LinearGradient(
                                      colors: <Color>[Color(0xFF4CC9F0), Color(0xFF1565A3)],
                                    ),
                                    shadowColor: const Color(0x594CC9F0),
                                    onTap: _handleCreate,
                                  ),
                                  const SizedBox(height: 14),

                                  // Opción 2: Conectarse a Partida
                                  _MultiplayerOptionButton(
                                    title: 'Conectarse a Partida',
                                    subtitle: 'Ingresa un código de sala',
                                    iconText: '🔗',
                                    isOutlined: true,
                                    onTap: () => setState(() => _mode = 'join'),
                                  ),
                                ] else ...<Widget>[
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: const Text(
                                      'Ingresa el código',
                                      style: TextStyle(
                                        color: Color(0xFFF0F0F0),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 26,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Pídele el código al anfitrión de la sala',
                                    style: TextStyle(color: Color(0xFF7A7AAA), fontSize: 13),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 18),

                                  // Campo de Texto para Código de Sala
                                  TextField(
                                    controller: _codeController,
                                    textCapitalization: TextCapitalization.characters,
                                    maxLength: 8,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFFF0F0F0),
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 4,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Ej: ABCD12',
                                      hintStyle: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.25),
                                        fontSize: 18,
                                        letterSpacing: 2,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withValues(alpha: 0.07),
                                      errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 2),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 2),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFF4CC9F0), width: 2),
                                      ),
                                    ),
                                    onChanged: (_) {
                                      if (_errorMessage.isNotEmpty) setState(() => _errorMessage = '');
                                    },
                                  ),
                                  const SizedBox(height: 14),

                                  ElevatedButton(
                                    onPressed: _handleJoin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4CC9F0),
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(double.infinity, 48),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      elevation: 6,
                                    ),
                                    child: const Text(
                                      'Unirse',
                                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _mode = 'choose';
                                        _errorMessage = '';
                                        _codeController.clear();
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

class _MultiplayerOptionButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final String iconText;
  final LinearGradient? gradient;
  final Color? shadowColor;
  final bool isOutlined;
  final VoidCallback onTap;

  const _MultiplayerOptionButton({
    required this.title,
    required this.subtitle,
    required this.iconText,
    this.gradient,
    this.shadowColor,
    this.isOutlined = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: shadowColor != null
            ? <BoxShadow>[
                BoxShadow(
                  color: shadowColor!,
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              gradient: isOutlined ? null : gradient,
              color: isOutlined ? Colors.white.withValues(alpha: 0.05) : null,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isOutlined ? Colors.white.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.1),
                width: isOutlined ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(iconText, style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: TextStyle(
                          color: isOutlined ? const Color(0xFFF0F0F0) : Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: isOutlined ? const Color(0xFF7A7AAA) : Colors.white.withValues(alpha: 0.75),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
