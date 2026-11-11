import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/persisted_stopwatch_session.dart';
import '../../domain/repositories/stopwatch_session_repository.dart';

class SharedPreferencesStopwatchSessionRepository
    implements StopwatchSessionRepository {
  SharedPreferencesStopwatchSessionRepository(this._preferences);

  static const _sessionKey = 'active_stopwatch_session_v1';

  final SharedPreferences _preferences;

  @override
  Future<PersistedStopwatchSession?> loadSession() async {
    final encoded = _preferences.getString(_sessionKey);
    if (encoded == null) return null;

    try {
      final json = jsonDecode(encoded) as Map<String, Object?>;
      return PersistedStopwatchSession.fromJson(json);
    } on FormatException {
      await clearSession();
      return null;
    } on TypeError {
      await clearSession();
      return null;
    } on ArgumentError {
      await clearSession();
      return null;
    }
  }

  @override
  Future<void> saveSession(PersistedStopwatchSession session) async {
    await _preferences.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  @override
  Future<void> clearSession() async {
    await _preferences.remove(_sessionKey);
  }
}
