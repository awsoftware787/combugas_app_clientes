sealed class VerificationResult {
  const VerificationResult(this.message);

  final String message;
}

final class VerificationSuccess extends VerificationResult {
  const VerificationSuccess() : super('Verificación exitosa');
}

final class VerificationInvalidCode extends VerificationResult {
  const VerificationInvalidCode()
    : super('El código de verificación no es correcto');
}

final class VerificationFailure extends VerificationResult {
  const VerificationFailure(super.message);
}

sealed class ResendCodeResult {
  const ResendCodeResult(this.message);

  final String message;
}

final class ResendCodeSuccess extends ResendCodeResult {
  const ResendCodeSuccess() : super('Se ha enviado su código');
}

final class ResendCodeFailure extends ResendCodeResult {
  const ResendCodeFailure(super.message);
}
