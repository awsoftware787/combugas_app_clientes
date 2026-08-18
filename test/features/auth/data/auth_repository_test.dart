import 'package:combugas_clientes/features/auth/data/auth_repository.dart';
import 'package:combugas_clientes/features/auth/data/clientes_soap_service.dart';
import 'package:combugas_clientes/features/auth/data/session_storage.dart';
import 'package:combugas_clientes/features/auth/models/login_result.dart';
import 'package:combugas_clientes/features/auth/models/session_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const session = SessionData(
    claveUsuario: 12,
    nombreUsuario: 'Cliente',
    claveTelefono: 34,
    subcanalUsuario: 7,
  );

  test('login correcto guarda la sesión', () async {
    final sessionStore = _FakeSessionStore();
    final repository = AuthRepository(
      clientesService: _FakeClientesService(
        const LoginSuccess(session: session, hasAddress: true),
      ),
      sessionStorage: sessionStore,
    );

    final result = await repository.login(
      telefono: '(871) 123-4567',
      contrasena: 'secreta',
    );

    expect(result, isA<LoginSuccess>());
    expect(sessionStore.session, session);
  });

  test('login incorrecto no guarda sesión', () async {
    final sessionStore = _FakeSessionStore();
    final repository = AuthRepository(
      clientesService: _FakeClientesService(const LoginInvalidCredentials()),
      sessionStorage: sessionStore,
    );

    final result = await repository.login(
      telefono: '(871) 123-4567',
      contrasena: 'incorrecta',
    );

    expect(result, isA<LoginInvalidCredentials>());
    expect(sessionStore.session, isNull);
  });

  test('logout elimina la sesión', () async {
    final sessionStore = _FakeSessionStore()..session = session;
    final repository = AuthRepository(
      clientesService: _FakeClientesService(const LoginInvalidCredentials()),
      sessionStorage: sessionStore,
    );

    await repository.logout();

    expect(sessionStore.session, isNull);
  });
}

final class _FakeClientesService implements ClientesService {
  const _FakeClientesService(this.result);

  final LoginResult result;

  @override
  Future<LoginResult> login({
    required String telefono,
    required String contrasena,
  }) async => result;
}

final class _FakeSessionStore implements SessionStore {
  SessionData? session;

  @override
  Future<void> clearSession() async => session = null;

  @override
  SessionData? getSession() => session;

  @override
  bool hasSession() => session != null;

  @override
  Future<void> saveSession(SessionData value) async => session = value;
}
