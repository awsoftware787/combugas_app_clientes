import 'dart:async';

import 'package:combugas_clientes/core/network/network_exception.dart';
import 'package:combugas_clientes/features/auth/controllers/auth_controller.dart';
import 'package:combugas_clientes/features/auth/data/auth_repository.dart';
import 'package:combugas_clientes/features/auth/models/login_result.dart';
import 'package:combugas_clientes/features/auth/models/session_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const session = SessionData(
    claveUsuario: 12,
    nombreUsuario: 'Cliente',
    claveTelefono: 34,
    subcanalUsuario: 7,
  );

  test('restaura una sesión existente al iniciar', () {
    final repository = _FakeAuthRepository(
      onLogin: () async => const LoginInvalidCredentials(),
      session: session,
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final state = container.read(authControllerProvider);

    expect(state.status, AuthStatus.authenticated);
    expect(state.session, session);
  });

  test('cambia de loading a authenticated', () async {
    final completer = Completer<LoginResult>();
    final repository = _FakeAuthRepository(onLogin: () => completer.future);
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final controller = container.read(authControllerProvider.notifier);

    final login = controller.login(telefono: 'telefono', contrasena: 'clave');
    expect(container.read(authControllerProvider).status, AuthStatus.loading);

    completer.complete(const LoginSuccess(session: session, hasAddress: true));
    await login;

    final state = container.read(authControllerProvider);
    expect(state.status, AuthStatus.authenticated);
    expect(state.session, session);
  });

  test('login incorrecto cambia a error', () async {
    final repository = _FakeAuthRepository(
      onLogin: () async => const LoginInvalidCredentials(),
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container
        .read(authControllerProvider.notifier)
        .login(telefono: 'telefono', contrasena: 'incorrecta');

    final state = container.read(authControllerProvider);
    expect(state.status, AuthStatus.error);
    expect(state.message, 'El usuario o contraseña no son correctos.');
  });

  test('error de conexión produce un mensaje seguro', () async {
    final repository = _FakeAuthRepository(
      onLogin: () => Future.error(const NoConnectionException()),
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(authControllerProvider.notifier)
        .login(telefono: 'telefono', contrasena: 'clave');

    expect(result, isA<LoginServiceFailure>());
    expect(
      container.read(authControllerProvider).message,
      'No fue posible conectarse al servidor.',
    );
  });
}

final class _FakeAuthRepository implements AuthRepositoryContract {
  _FakeAuthRepository({required this.onLogin, this.session});

  final Future<LoginResult> Function() onLogin;
  SessionData? session;

  @override
  SessionData? getSession() => session;

  @override
  Future<LoginResult> login({
    required String telefono,
    required String contrasena,
  }) => onLogin();

  @override
  Future<void> logout() async => session = null;
}
