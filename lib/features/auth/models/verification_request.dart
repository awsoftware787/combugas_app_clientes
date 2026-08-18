final class VerificationRequest {
  const VerificationRequest({required this.accountKey, required this.code});

  final int accountKey;
  final String code;
}
