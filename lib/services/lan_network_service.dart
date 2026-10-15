import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;

/// Modelo de información de jugador transmitido por la red LAN
class PlayerInfo {
  final String id;
  final String name;
  final int seatIndex;
  vmath.Quaternion rotation;

  PlayerInfo({
    required this.id,
    required this.name,
    required this.seatIndex,
    vmath.Quaternion? rotation,
  }) : rotation = rotation ?? vmath.Quaternion.identity();

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'seatIndex': seatIndex,
      };

  factory PlayerInfo.fromJson(Map<String, dynamic> json) => PlayerInfo(
        id: json['id'] as String,
        name: json['name'] as String,
        seatIndex: json['seatIndex'] as int,
      );
}

/// Servicio de Capa Data/Service que gestiona conexiones de Sockets TCP/WebSocket en red local
class LanNetworkService extends ChangeNotifier {
  static const int defaultPort = 4040;

  HttpServer? _server;
  WebSocket? _clientSocket;
  final List<WebSocket> _hostSockets = <WebSocket>[];

  String _localIp = 'Obteniendo IP...';
  bool _isHost = false;
  bool _isConnected = false;
  String _myPlayerId = '';
  int _mySeatIndex = 0;

  final List<PlayerInfo> _players = <PlayerInfo>[];
  final Map<String, vmath.Quaternion> _playerOrientations = <String, vmath.Quaternion>{};

  String get localIp => _localIp;
  bool get isHost => _isHost;
  bool get isConnected => _isConnected;
  String get myPlayerId => _myPlayerId;
  int get mySeatIndex => _mySeatIndex;
  List<PlayerInfo> get players => List<PlayerInfo>.unmodifiable(_players);
  Map<String, vmath.Quaternion> get playerOrientations => Map<String, vmath.Quaternion>.unmodifiable(_playerOrientations);

  LanNetworkService() {
    fetchLocalIp();
  }

  Future<String> fetchLocalIp() async {
    try {
      final List<NetworkInterface> interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      for (final NetworkInterface interface in interfaces) {
        for (final InternetAddress address in interface.addresses) {
          if (!address.isLoopback && address.address.startsWith('192.168.') || address.address.startsWith('10.')) {
            _localIp = address.address;
            notifyListeners();
            return _localIp;
          }
        }
      }

      if (interfaces.isNotEmpty && interfaces.first.addresses.isNotEmpty) {
        _localIp = interfaces.first.addresses.first.address;
        notifyListeners();
        return _localIp;
      }
    } catch (e) {
      debugPrint('Error obteniendo IP local: $e');
    }

    _localIp = '127.0.0.1';
    notifyListeners();
    return _localIp;
  }

  Future<bool> startHost({int port = defaultPort}) async {
    try {
      await stopService();

      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _isHost = true;
      _isConnected = true;
      _myPlayerId = 'host_0';
      _mySeatIndex = 0;

      final PlayerInfo hostPlayer = PlayerInfo(
        id: _myPlayerId,
        name: 'Jugador 1 (Host)',
        seatIndex: 0,
      );
      _players.clear();
      _players.add(hostPlayer);
      _playerOrientations[_myPlayerId] = vmath.Quaternion.identity();

      _server!.listen((HttpRequest request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          final WebSocket socket = await WebSocketTransformer.upgrade(request);
          _handleNewClientConnection(socket);
        }
      });

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error iniciando servidor Host: $e');
      _isHost = false;
      _isConnected = false;
      notifyListeners();
      return false;
    }
  }

  void _handleNewClientConnection(WebSocket socket) {
    _hostSockets.add(socket);

    final int newSeatIndex = _players.length;
    final String clientId = 'player_$newSeatIndex';
    final PlayerInfo newPlayer = PlayerInfo(
      id: clientId,
      name: 'Jugador ${newSeatIndex + 1}',
      seatIndex: newSeatIndex,
    );

    _players.add(newPlayer);
    _playerOrientations[clientId] = vmath.Quaternion.identity();

    final Map<String, dynamic> initPayload = <String, dynamic>{
      'type': 'init',
      'playerId': clientId,
      'seatIndex': newSeatIndex,
      'players': _players.map((PlayerInfo p) => p.toJson()).toList(),
    };
    socket.add(jsonEncode(initPayload));

    _broadcastRoomState();

    socket.listen(
      (dynamic data) {
        _processReceivedMessage(data as String);
      },
      onDone: () {
        _hostSockets.remove(socket);
        _players.removeWhere((PlayerInfo p) => p.id == clientId);
        _playerOrientations.remove(clientId);
        _broadcastRoomState();
        notifyListeners();
      },
      onError: (_) {
        _hostSockets.remove(socket);
      },
    );

    notifyListeners();
  }

  Future<bool> connectToHost(String hostIp, {int port = defaultPort}) async {
    try {
      await stopService();

      _isHost = false;
      final String wsUrl = 'ws://$hostIp:$port';
      _clientSocket = await WebSocket.connect(wsUrl).timeout(const Duration(seconds: 5));

      _isConnected = true;

      _clientSocket!.listen(
        (dynamic data) {
          _processReceivedMessage(data as String);
        },
        onDone: () {
          _isConnected = false;
          notifyListeners();
        },
        onError: (dynamic error) {
          _isConnected = false;
          notifyListeners();
        },
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error conectando a $hostIp:$port -> $e');
      _isConnected = false;
      notifyListeners();
      return false;
    }
  }

  void _processReceivedMessage(String jsonStr) {
    try {
      final Map<String, dynamic> msg = jsonDecode(jsonStr) as Map<String, dynamic>;
      final String type = msg['type'] as String;

      if (type == 'init') {
        _myPlayerId = msg['playerId'] as String;
        _mySeatIndex = msg['seatIndex'] as int;
        _updatePlayersFromList(msg['players'] as List<dynamic>);
      } else if (type == 'room_state') {
        _updatePlayersFromList(msg['players'] as List<dynamic>);
      } else if (type == 'motion') {
        final String senderId = msg['playerId'] as String;
        final double x = (msg['x'] as num).toDouble();
        final double y = (msg['y'] as num).toDouble();
        final double z = (msg['z'] as num).toDouble();
        final double w = (msg['w'] as num).toDouble();

        _playerOrientations[senderId] = vmath.Quaternion(x, y, z, w);

        if (_isHost) {
          _broadcastToClients(jsonStr, excludeSenderId: senderId);
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error procesando mensaje JSON: $e');
    }
  }

  void _updatePlayersFromList(List<dynamic> listJson) {
    _players.clear();
    for (final dynamic item in listJson) {
      final PlayerInfo p = PlayerInfo.fromJson(item as Map<String, dynamic>);
      _players.add(p);
      if (!_playerOrientations.containsKey(p.id)) {
        _playerOrientations[p.id] = vmath.Quaternion.identity();
      }
    }
    notifyListeners();
  }

  void sendLocalMotion(vmath.Quaternion q) {
    if (!_isConnected || _myPlayerId.isEmpty) return;

    _playerOrientations[_myPlayerId] = q;

    final Map<String, dynamic> motionPayload = <String, dynamic>{
      'type': 'motion',
      'playerId': _myPlayerId,
      'x': q.x,
      'y': q.y,
      'z': q.z,
      'w': q.w,
    };

    final String jsonStr = jsonEncode(motionPayload);

    if (_isHost) {
      _broadcastToClients(jsonStr);
    } else {
      _clientSocket?.add(jsonStr);
    }
  }

  void _broadcastRoomState() {
    final Map<String, dynamic> payload = <String, dynamic>{
      'type': 'room_state',
      'players': _players.map((PlayerInfo p) => p.toJson()).toList(),
    };
    _broadcastToClients(jsonEncode(payload));
  }

  void _broadcastToClients(String message, {String? excludeSenderId}) {
    for (int i = 0; i < _hostSockets.length; i++) {
      try {
        _hostSockets[i].add(message);
      } catch (_) {}
    }
  }

  Future<void> stopService() async {
    for (final WebSocket s in _hostSockets) {
      try {
        await s.close();
      } catch (_) {}
    }
    _hostSockets.clear();

    await _clientSocket?.close();
    _clientSocket = null;

    await _server?.close(force: true);
    _server = null;

    _isHost = false;
    _isConnected = false;
    _players.clear();
    _playerOrientations.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    stopService();
    super.dispose();
  }
}
