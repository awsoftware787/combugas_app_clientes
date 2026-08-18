import 'package:combugas_clientes/core/storage/local_storage.dart';
import 'package:combugas_clientes/features/auth/data/session_storage.dart';
import 'package:combugas_clientes/features/auth/models/session_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const session = SessionData(
    claveUsuario: 12,
    nombreUsuario: 'Cliente',
    claveTelefono: 34,
    subcanalUsuario: 7,
  );

  test('guarda y recupera la sesión', () async {
    final storage = SessionStorage(_MemoryStorage());

    await storage.saveSession(session);

    expect(storage.hasSession(), isTrue);
    expect(storage.getSession(), session);
  });

  test('logout elimina únicamente la sesión', () async {
    final localStorage = _MemoryStorage();
    final storage = SessionStorage(localStorage);
    await localStorage.setString('pedido', '[{"producto":1}]');
    await storage.saveSession(session);

    await storage.clearSession();

    expect(storage.hasSession(), isFalse);
    expect(localStorage.getString('pedido'), '[{"producto":1}]');
  });
}

final class _MemoryStorage implements LocalStorage {
  final Map<String, Object> values = {};

  @override
  Future<void> clear() async => values.clear();

  @override
  bool? getBool(String key) => values[key] as bool?;

  @override
  String? getString(String key) => values[key] as String?;

  @override
  Future<void> remove(String key) async => values.remove(key);

  @override
  Future<void> setBool(String key, bool value) async => values[key] = value;

  @override
  Future<void> setString(String key, String value) async => values[key] = value;
}
