import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_exception.dart';
import '../data/auth_repository.dart';
import '../models/login_result.dart';
import '../models/session_data.dart';

enum AuthStatus { idle, loading, authenticated, unauthenticated, error }

final class AuthState {
  const AuthState({required this.status, this.session, this.message});

  final AuthStatus status;
  final SessionData? session;
  final String? message;

  bool get isLoading => status == AuthStatus.loading;
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

final class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    final session = ref.watch(authRepositoryProvider).getSession();
    return AuthState(
      status:
          session == null
              ? AuthStatus.unauthenticated
              : AuthStatus.authenticated,
      session: session,
    );
  }

  Future<LoginResult> login({
    required String telefono,
    required String contrasena,
  }) async {
    if (state.isLoading) {
      return const LoginServiceFailure('El inicio de sesión ya está en curso.');
    }

    state = const AuthState(status: AuthStatus.loading);
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .login(telefono: telefono, contrasena: contrasena);

      if (result is LoginSuccess) {
        state = AuthState(
          status: AuthStatus.authenticated,
          session: result.session,
        );
      } else {
        state = AuthState(status: AuthStatus.error, message: result.message);
      }
      return result;
    } on NoConnectionException {
      return _fail('No fue posible conectarse al servidor.');
    } on NetworkTimeoutException {
      return _fail('El servidor tardó demasiado en responder.');
    } on InvalidSoapResponseException {
      return _fail('No fue posible procesar la respuesta del servidor.');
    } on NetworkException {
      return _fail('No fue posible iniciar sesión. Inténtalo nuevamente.');
    } catch (_) {
      return _fail('Ocurrió un error inesperado. Inténtalo nuevamente.');
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  LoginServiceFailure _fail(String message) {
    state = AuthState(status: AuthStatus.error, message: message);
    return LoginServiceFailure(message);
  }
}
