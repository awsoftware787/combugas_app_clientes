final class CustomerMatch {
  const CustomerMatch({
    required this.customerKey,
    required this.name,
    required this.phoneKey,
    required this.addresses,
    required this.hasAccount,
  });

  final int customerKey;
  final String name;
  final int phoneKey;
  final List<String> addresses;
  final bool hasAccount;
}

sealed class RegisterResult {
  const RegisterResult(this.message);

  final String message;
}

final class RegisterCreated extends RegisterResult {
  const RegisterCreated(this.accountKey) : super('Registro correcto.');

  final int accountKey;
}

final class RegisterIdentityMatch extends RegisterResult {
  const RegisterIdentityMatch(this.customer)
    : super('Se encontró un cliente con los datos proporcionados.');

  final CustomerMatch customer;
}

final class RegisterExistingAccount extends RegisterResult {
  const RegisterExistingAccount(this.customer)
    : super('El cliente encontrado ya cuenta con acceso.');

  final CustomerMatch customer;
}

final class RegisterFailure extends RegisterResult {
  const RegisterFailure(super.message);
}
