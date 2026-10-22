import 'package:flutter/material.dart';
import 'login_view.dart';

/// Pantalla de Configuración 100% Responsiva
class SettingsView extends StatelessWidget {
  final AppUser user;
  final VoidCallback onBack;
  final VoidCallback onLogout;

  const SettingsView({
    super.key,
    required this.user,
    required this.onBack,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> stats = const <Map<String, String>>[
      <String, String>{'label': 'Partidas jugadas', 'value': '0'},
      <String, String>{'label': 'Victorias', 'value': '0'},
      <String, String>{'label': 'UNOs gritados', 'value': '0'},
    ];

    final List<Map<String, String>> options = const <Map<String, String>>[
      <String, String>{'icon': '🔔', 'label': 'Notificaciones', 'desc': 'Sonidos del juego', 'value': 'Activado'},
      <String, String>{'icon': '🎨', 'label': 'Tema', 'desc': 'Apariencia visual', 'value': 'Oscuro'},
      <String, String>{'icon': '🌐', 'label': 'Idioma', 'desc': 'Language / Idioma', 'value': 'Español'},
    ];

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
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: <Widget>[
                      // Cabecera Responsiva
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: <Widget>[
                            InkWell(
                              onTap: onBack,
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
                                'Configuración',
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

                      // Contenido Responsivo
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            // Tarjeta de Perfil
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: <Color>[
                                    const Color(0xFFE63946).withValues(alpha: 0.15),
                                    const Color(0xFF1A1040).withValues(alpha: 0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE63946).withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: <Widget>[
                                  Container(
                                    width: 54,
                                    height: 54,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: <Color>[Color(0xFFE63946), Color(0xFFC41E3A)],
                                      ),
                                      boxShadow: <BoxShadow>[
                                        BoxShadow(color: Color(0x80E63946), blurRadius: 14, offset: Offset(0, 4)),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        user.initial,
                                        style: const TextStyle(
                                          color: Color(0xFFFFD60A),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          user.name,
                                          style: const TextStyle(
                                            color: Color(0xFFF0F0F0),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 18,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: <Widget>[
                                            Icon(
                                              user.method == 'google' ? Icons.g_mobiledata : Icons.cast,
                                              color: const Color(0xFF7A7AAA),
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                user.method == 'google' ? 'Cuenta Google' : 'Usuario local',
                                                style: const TextStyle(color: Color(0xFF7A7AAA), fontSize: 12),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Tarjeta de Estadísticas Responsiva
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Text(
                                      'Estadísticas',
                                      style: TextStyle(color: Color(0xFFF0F0F0), fontWeight: FontWeight.w900, fontSize: 16),
                                    ),
                                  ),
                                  Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
                                  Row(
                                    children: <Widget>[
                                      for (int i = 0; i < stats.length; i++) ...<Widget>[
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                                            child: Column(
                                              children: <Widget>[
                                                FittedBox(
                                                  child: Text(
                                                    stats[i]['value']!,
                                                    style: const TextStyle(color: Color(0xFFFFD60A), fontWeight: FontWeight.w900, fontSize: 24),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  stats[i]['label']!,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(color: Color(0xFF7A7AAA), fontSize: 10, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (i < stats.length - 1)
                                          Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.06)),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Tarjeta de Opciones
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Text(
                                      'Opciones',
                                      style: TextStyle(color: Color(0xFFF0F0F0), fontWeight: FontWeight.w900, fontSize: 16),
                                    ),
                                  ),
                                  Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
                                  for (int i = 0; i < options.length; i++) ...<Widget>[
                                    ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                                      leading: Text(options[i]['icon']!, style: const TextStyle(fontSize: 20)),
                                      title: Text(
                                        options[i]['label']!,
                                        style: const TextStyle(color: Color(0xFFF0F0F0), fontWeight: FontWeight.bold, fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      subtitle: Text(
                                        options[i]['desc']!,
                                        style: const TextStyle(color: Color(0xFF7A7AAA), fontSize: 11),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.06),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          options[i]['value']!,
                                          style: const TextStyle(color: Color(0xFF7A7AAA), fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    if (i < options.length - 1) Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Zona de Cuenta / Cerrar Sesión
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE63946).withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE63946).withValues(alpha: 0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Text('Cuenta', style: TextStyle(color: Color(0xFFE63946), fontWeight: FontWeight.w900, fontSize: 16)),
                                  const SizedBox(height: 10),
                                  OutlinedButton.icon(
                                    onPressed: onLogout,
                                    icon: const Icon(Icons.logout, size: 18),
                                    label: const Text('Cerrar Sesión'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFE63946),
                                      backgroundColor: const Color(0xFFE63946).withValues(alpha: 0.12),
                                      side: const BorderSide(color: Color(0xFFE63946), width: 1.5),
                                      minimumSize: const Size(double.infinity, 46),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            const Center(
                              child: Text('UNO v1.0 · Hecho con ❤️', style: TextStyle(color: Color(0xFF3A3A5A), fontSize: 12)),
                            ),
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
