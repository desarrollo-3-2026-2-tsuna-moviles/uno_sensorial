import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/gesture_service.dart';
import '../services/sensor_service.dart';
import 'game_viewmodel.dart';
import 'sensor_viewmodel.dart';

/// ViewModel que traduce los gestos detectados (RF-20 a RF-22) en acciones del juego.
///
/// Cada gesto llama al mismo método del [GameViewModel] que su botón táctil
/// equivalente, así ambas vías aplican exactamente las mismas reglas.
class GestureViewModel extends ChangeNotifier {
  GestureViewModel({
    required this.gameViewModel,
    required SensorViewModel sensorViewModel,
  }) {
    _service = GestureService(onGesture: _onGesture);
    _accSubscription = sensorViewModel.accelerometerSamples.listen(
      (SensorSample s) => _service.addAccelerometer(s.value, s.timestamp),
    );
    _gyroSubscription = sensorViewModel.gyroscopeSamples.listen(
      (SensorSample s) => _service.addGyroscope(s.value, s.timestamp),
    );
    gameViewModel.addListener(_syncWithGame);
    _syncWithGame();
  }

  final GameViewModel gameViewModel;
  late final GestureService _service;
  StreamSubscription<SensorSample>? _accSubscription;
  StreamSubscription<SensorSample>? _gyroSubscription;

  bool _gesturesEnabled = true;
  GestureType? _lastGesture;
  int _gestureCount = 0;

  bool get gesturesEnabled => _gesturesEnabled;

  /// Último gesto reconocido (para dar feedback visual en el HUD).
  GestureType? get lastGesture => _lastGesture;

  /// Aumenta con cada gesto reconocido (para animar el feedback).
  int get gestureCount => _gestureCount;

  /// RF-20: umbral configurable del gesto de lanzar (rad/s).
  double get throwThreshold => _service.throwThreshold;
  set throwThreshold(double value) {
    _service.throwThreshold = value;
    notifyListeners();
  }

  void toggleGestures() {
    _gesturesEnabled = !_gesturesEnabled;
    notifyListeners();
  }

  /// El giro de Reversa solo se escucha mientras el juego lo espera.
  void _syncWithGame() {
    _service.reverseTwistEnabled = gameViewModel.isAwaitingReverseConfirmation;
  }

  void _onGesture(GestureType gesture) {
    if (!_gesturesEnabled) return;

    switch (gesture) {
      case GestureType.throwCard:
        // RF-20: solo con una carta seleccionada.
        if (gameViewModel.selectedCard == null) return;
        gameViewModel.playSelectedCard();
      case GestureType.reverseTwist:
        if (!gameViewModel.isAwaitingReverseConfirmation) return;
        gameViewModel.confirmReverse();
      case GestureType.unoShake:
        gameViewModel.callUno();
    }

    _lastGesture = gesture;
    _gestureCount++;
    notifyListeners();
  }

  @override
  void dispose() {
    _accSubscription?.cancel();
    _gyroSubscription?.cancel();
    gameViewModel.removeListener(_syncWithGame);
    super.dispose();
  }
}
