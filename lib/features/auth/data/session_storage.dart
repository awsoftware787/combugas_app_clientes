import 'dart:convert';

import '../../../core/storage/local_storage.dart';
import '../models/session_data.dart';

abstract interface class SessionStore {
  Future<void> saveSession(SessionData session);

  SessionData? getSession();

  bool hasSession();

  Future<void> clearSession();
}

final class SessionStorage implements SessionStore {
  const SessionStorage(this._storage);

  static const _sessionKey = 'auth_session';

  final LocalStorage _storage;

  @override
  Future<void> saveSession(SessionData session) {
    return _storage.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  @override
  SessionData? getSession() {
    final storedSession = _storage.getString(_sessionKey);
    if (storedSession == null || storedSession.isEmpty) return null;

    try {
      final json = jsonDecode(storedSession);
      return SessionData.fromJson(json as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  bool hasSession() => getSession() != null;

  @override
  Future<void> clearSession() => _storage.remove(_sessionKey);
}
