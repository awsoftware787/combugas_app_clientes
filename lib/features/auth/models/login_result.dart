import 'session_data.dart';

sealed class LoginResult {
  const LoginResult(this.message);

  final String message;
}

final class LoginSuccess extends LoginResult {
  const LoginSuccess({required this.session, required this.hasAddress})
    : super('Inicio de sesión correcto.');

  final SessionData session;
  final bool hasAddress;
}

final class LoginInvalidCredentials extends LoginResult {
  const LoginInvalidCredentials()
    : super('El usuario o contraseña no son correctos.');
}

final class LoginInactiveAccount extends LoginResult {
  const LoginInactiveAccount(this.accountKey)
    : super('Su cuenta no ha sido activada.');

  final int accountKey;
}

final class LoginInstitutionalAccount extends LoginResult {
  const LoginInstitutionalAccount()
    : super('Servicio disponible solo para clientes domésticos.');
}

final class LoginBlockedAccount extends LoginResult {
  const LoginBlockedAccount(this.reason)
    : super('Su cuenta se encuentra suspendida.');

  final String reason;
}

final class LoginServiceFailure extends LoginResult {
  const LoginServiceFailure(super.message);
}
