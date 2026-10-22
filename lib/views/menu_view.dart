import 'package:flutter/material.dart';
import 'login_view.dart';

/// MenuPrincipalView que recrea el diseño de Figma y soporta navegación
/// hacia Un Jugador, Multijugador, Configuración y Estadísticas (RNF-07).
class MenuPrincipalView extends StatelessWidget {
  final AppUser user;
  final VoidCallback onSolo;
  final VoidCallback onMultiplayer;
  final VoidCallback onSettings;
  final VoidCallback onStats;

  const MenuPrincipalView({
    super.key,
    required this.user,
    required this.onSolo,
    required this.onMultiplayer,
    required this.onSettings,
    required this.onStats,
  });

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
              Color(0xFF12122E),
              Color(0xFF0D1A2E),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: <Widget>[
                // Cabecera Responsiva con Avatar e Insignia UNO
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: <Widget>[
                      // Bloque de Usuario
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE63946).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE63946).withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 34,
                                height: 34,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: <Color>[Color(0xFFE63946), Color(0xFFC41E3A)],
                                  ),
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(color: Color(0x66E63946), blurRadius: 8, offset: Offset(0, 2)),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    user.initial,
                                    style: const TextStyle(
                                      color: Color(0xFFFFD60A),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text(
                                      user.name,
                                      style: const TextStyle(
                                        color: Color(0xFFF0F0F0),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    Text(
                                      user.method == 'google' ? 'Google' : 'Local',
                                      style: const TextStyle(color: Color(0xFF7A7AAA), fontSize: 10),
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
                      const SizedBox(width: 10),

                      // Logo UNO
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: <Color>[Color(0xFFE63946), Color(0xFFC41E3A)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(color: Color(0x73E63946), blurRadius: 12, offset: Offset(0, 4)),
                          ],
                        ),
                        child: const Text(
                          'UNO',
                          style: TextStyle(
                            color: Color(0xFFFFD60A),
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Línea decorativa
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.06),
                ),

                // Título Principal Responsivo
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '¿Qué quieres hacer?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFF0F0F0),
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Elige un modo de juego',
                    style: TextStyle(color: Color(0xFF7A7AAA), fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),

                // Tarjetas de Opciones de Menú (RNF-07)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: <Widget>[
                      _MenuOptionCard(
                        label: 'Un Jugador',
                        description: 'Enfréntate a la IA (Bots)',
                        iconText: '🃏',
                        colors: const <Color>[Color(0xFFE63946), Color(0xFFA01C27)],
                        glowColor: const Color(0x66E63946),
                        onTap: onSolo,
                      ),
                      const SizedBox(height: 14),
                      _MenuOptionCard(
                        label: 'Multijugador',
                        description: 'Juega con amigos en red local',
                        iconText: '🌐',
                        colors: const <Color>[Color(0xFF4CC9F0), Color(0xFF1565A3)],
                        glowColor: const Color(0x594CC9F0),
                        onTap: onMultiplayer,
                      ),
                      const SizedBox(height: 14),
                      _MenuOptionCard(
                        label: 'Configuración',
                        description: 'Cuenta y opciones del juego',
                        iconText: '⚙️',
                        colors: const <Color>[Color(0xFF2A2A60), Color(0xFF16163A)],
                        glowColor: const Color(0x337A7AAA),
                        onTap: onSettings,
                      ),
                      const SizedBox(height: 14),
                      _MenuOptionCard(
                        label: 'Estadísticas',
                        description: 'Partidas, victorias y récord',
                        iconText: '📊',
                        colors: const <Color>[Color(0xFFF57F17), Color(0xFFE65100)],
                        glowColor: const Color(0x4DF57F17),
                        onTap: onStats,
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

class _MenuOptionCard extends StatelessWidget {
  final String label;
  final String description;
  final String iconText;
  final List<Color> colors;
  final Color glowColor;
  final VoidCallback onTap;

  const _MenuOptionCard({
    required this.label,
    required this.description,
    required this.iconText,
    required this.colors,
    required this.glowColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: glowColor,
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      iconText,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.6),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
