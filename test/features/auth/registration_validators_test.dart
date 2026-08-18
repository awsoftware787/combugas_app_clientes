import 'package:combugas_clientes/features/auth/validation/registration_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('replica las validaciones locales de RegistroActivity', () {
    expect(RegistrationValidators.name(''), isNotNull);
    expect(RegistrationValidators.name('CLIENTE'), isNull);
    expect(RegistrationValidators.phone('(871) 123-456'), isNotNull);
    expect(RegistrationValidators.phone('(871) 123-4567'), isNull);
    expect(RegistrationValidators.password('123'), isNotNull);
    expect(RegistrationValidators.password('1234'), isNull);
    expect(
      RegistrationValidators.passwordConfirmation('otra', 'clave'),
      isNotNull,
    );
    expect(
      RegistrationValidators.passwordConfirmation('clave', 'clave'),
      isNull,
    );
  });

  test('el código de verificación debe tener seis caracteres', () {
    expect(RegistrationValidators.verificationCode('12345'), isNotNull);
    expect(RegistrationValidators.verificationCode('123456'), isNull);
  });
}
