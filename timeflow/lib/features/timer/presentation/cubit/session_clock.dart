import 'package:flutter/services.dart';

class SessionClockSnapshot {
  const SessionClockSnapshot({
    required this.elapsedRealtime,
    required this.bootCount,
  });

  final Duration elapsedRealtime;
  final int? bootCount;
}

abstract interface class SessionClock {
  Future<SessionClockSnapshot?> snapshot();
}

class AndroidSessionClock implements SessionClock {
  static const _channel = MethodChannel('timeflow/session_clock');

  @override
  Future<SessionClockSnapshot?> snapshot() async {
    try {
      final result = await _channel.invokeMapMethod<String, Object?>(
        'getSnapshot',
      );
      if (result == null) return null;

      return SessionClockSnapshot(
        elapsedRealtime: Duration(
          milliseconds: result['elapsedRealtimeMillis']! as int,
        ),
        bootCount: result['bootCount'] as int?,
      );
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
