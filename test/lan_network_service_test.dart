import 'package:flutter_test/flutter_test.dart';
import 'package:uno_game/services/lan_network_service.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;

/// Espera hasta que [condition] se cumpla (o falla tras [timeout]).
Future<void> waitFor(bool Function() condition, {Duration timeout = const Duration(seconds: 3)}) async {
  final DateTime deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('La condición no se cumplió en $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  const int port = 40417;
  late LanNetworkService host;
  final List<LanNetworkService> clients = <LanNetworkService>[];

  Future<LanNetworkService> join(String name) async {
    final LanNetworkService c = LanNetworkService();
    clients.add(c);
    expect(await c.connectToHost('127.0.0.1', playerName: name, port: port), isTrue);
    await waitFor(() => c.myPlayerId.isNotEmpty);
    return c;
  }

  setUp(() async {
    host = LanNetworkService();
    expect(await host.startHost(playerName: 'Host', port: port), isTrue);
  });

  tearDown(() async {
    for (final LanNetworkService c in clients) {
      await c.stopService();
    }
    clients.clear();
    await host.stopService();
  });

  test('un jugador que entra después de que otro salió no reutiliza un id existente', () async {
    final LanNetworkService p1 = await join('P1');
    final LanNetworkService p2 = await join('P2');
    await waitFor(() => host.players.length == 3);

    await p1.stopService();
    clients.remove(p1);
    await waitFor(() => host.players.length == 2);

    final LanNetworkService p3 = await join('P3');
    await waitFor(() => host.players.length == 3);

    final Set<String> ids = host.players.map((PlayerInfo p) => p.id).toSet();
    final Set<int> seats = host.players.map((PlayerInfo p) => p.seatIndex).toSet();
    expect(ids.length, 3, reason: 'ids duplicados: $ids');
    expect(seats.length, 3, reason: 'asientos duplicados: $seats');
    expect(p3.myPlayerId, isNot(p2.myPlayerId));

    // Si P2 se desconecta, P3 debe seguir en la sala.
    await p2.stopService();
    clients.remove(p2);
    await waitFor(() => host.players.length == 2);
    expect(host.players.map((PlayerInfo p) => p.id), contains(p3.myPlayerId));
  });

  test('el host reenvía el movimiento a los demás pero no se lo devuelve al remitente', () async {
    final LanNetworkService a = await join('A');
    final LanNetworkService b = await join('B');
    await waitFor(() => host.players.length == 3);

    // sendLocalMotion guarda el mismo objeto; un eco del host crearía uno nuevo.
    vmath.Quaternion? lastSent;
    int echoes = 0;
    a.addListener(() {
      final vmath.Quaternion? own = a.playerOrientations[a.myPlayerId];
      if (lastSent != null && !identical(own, lastSent)) echoes++;
    });

    final vmath.Quaternion sent = vmath.Quaternion(0.1, 0.2, 0.3, 0.9);
    lastSent = sent;
    a.sendLocalMotion(sent);
    await waitFor(() => b.playerOrientations[a.myPlayerId]?.w == sent.w);
    expect(host.playerOrientations[a.myPlayerId]?.x, closeTo(0.1, 1e-9));

    // B también se mueve: A recibe notificaciones, pero nunca su propio movimiento de vuelta.
    b.sendLocalMotion(vmath.Quaternion(0, 0, 0, 1));
    await waitFor(() => a.playerOrientations[b.myPlayerId]?.w == 1.0);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(identical(a.playerOrientations[a.myPlayerId], sent), isTrue);
    expect(echoes, 0);
  });

  test('dispose sin esperar a stopService no lanza "used after being disposed"', () async {
    final LanNetworkService c = await join('C');
    clients.remove(c);
    c.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
}
