import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Data class holding normalized device tilt angles in radians.
@immutable
class SensorTiltData {
  final double pitch; // X-axis tilt (tilt forward / backward)
  final double roll;  // Y-axis tilt (tilt left / right)

  const SensorTiltData({this.pitch = 0.0, this.roll = 0.0});

  static const zero = SensorTiltData();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SensorTiltData &&
          runtimeType == other.runtimeType &&
          (pitch - other.pitch).abs() < 0.001 &&
          (roll - other.roll).abs() < 0.001;

  @override
  int get hashCode => pitch.hashCode ^ roll.hashCode;
}

/// Service managing device accelerometer sensors for 3D card perspective tilt.
///
/// Features:
/// - Low-pass exponential moving average to filter sensor noise.
/// - Clamps and normalizes angles to comfortable viewing limits (±22° / ±0.38 rad).
/// - Reference counted start/stop to conserve battery when no showcase is active.
/// - Graceful fallback on emulators, desktop, or unsupported platforms.
class SensorTiltService {
  SensorTiltService._();
  static final SensorTiltService instance = SensorTiltService._();

  final ValueNotifier<SensorTiltData> tiltNotifier =
      ValueNotifier<SensorTiltData>(SensorTiltData.zero);

  StreamSubscription<AccelerometerEvent>? _sub;
  int _listenerCount = 0;

  double _filteredPitch = 0.0;
  double _filteredRoll = 0.0;

  /// Start listening to device tilt sensors. Increments reference count.
  void start() {
    _listenerCount++;
    if (_sub != null) return;

    try {
      _sub = accelerometerEventStream(
        samplingPeriod: SensorInterval.gameInterval,
      ).listen(
        _onAccelerometerEvent,
        onError: (_) {
          // Gracefully fallback to zero on unsupported hardware
          stop(force: true);
        },
        cancelOnError: true,
      );
    } catch (_) {
      // Platform does not support accelerometer
      _sub = null;
    }
  }

  /// Stop listening to device tilt sensors. Decrements reference count.
  void stop({bool force = false}) {
    if (force) {
      _listenerCount = 0;
    } else {
      _listenerCount = (_listenerCount - 1).clamp(0, 9999);
    }

    if (_listenerCount == 0 && _sub != null) {
      _sub?.cancel();
      _sub = null;
      _filteredPitch = 0.0;
      _filteredRoll = 0.0;
      tiltNotifier.value = SensorTiltData.zero;
    }
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    // Standard portrait orientation:
    // event.x is lateral tilt (roll). Range: ~ -9.8 (tilted right) to +9.8 (tilted left).
    // event.y is longitudinal tilt (pitch). Natural phone hold angle is ~45° (y ≈ 5-7 m/s²).
    // event.z is gravity perpendicular to screen.

    // Normalized targets (-1.0 to 1.0)
    final targetRoll = (-event.x / 7.0).clamp(-1.0, 1.0);
    // Baseline natural resting tilt around y=6.0
    final targetPitch = ((event.y - 6.0) / 7.0).clamp(-1.0, 1.0);

    // Max rotation angles (approx ±20 degrees = 0.35 rad)
    const maxAngleRad = 0.35;
    final radRoll = targetRoll * maxAngleRad;
    final radPitch = targetPitch * maxAngleRad;

    // Exponential smoothing (alpha = 0.18 for smooth responsive tracking)
    _filteredRoll = _filteredRoll * 0.82 + radRoll * 0.18;
    _filteredPitch = _filteredPitch * 0.82 + radPitch * 0.18;

    tiltNotifier.value = SensorTiltData(
      pitch: _filteredPitch,
      roll: _filteredRoll,
    );
  }
}
