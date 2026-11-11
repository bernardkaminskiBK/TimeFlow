import '../models/persisted_stopwatch_session.dart';

abstract interface class StopwatchSessionRepository {
  Future<PersistedStopwatchSession?> loadSession();

  Future<void> saveSession(PersistedStopwatchSession session);

  Future<void> clearSession();
}
