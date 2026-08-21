sealed class PasswordRecoveryResult {
  const PasswordRecoveryResult(this.message);

  final String message;
}

final class PasswordRecoverySuccess extends PasswordRecoveryResult {
  const PasswordRecoverySuccess()
    : super('En breve recibirá un mensaje con su clave de acceso');
}

final class PasswordRecoveryPhoneNotFound extends PasswordRecoveryResult {
  const PasswordRecoveryPhoneNotFound()
    : super('No se ha encontrado el número de teléfono especificado');
}

final class PasswordRecoveryFailure extends PasswordRecoveryResult {
  const PasswordRecoveryFailure(super.message);
}
