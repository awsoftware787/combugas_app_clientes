import 'package:combugas_clientes/core/network/network_exception.dart';
import 'package:combugas_clientes/features/auth/data/registration_soap_parser.dart';
import 'package:combugas_clientes/features/auth/data/verification_soap_parser.dart';
import 'package:combugas_clientes/features/auth/models/register_result.dart';
import 'package:combugas_clientes/features/auth/models/verification_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

void main() {
  const registrationParser = RegistrationSoapParser();
  const verificationParser = VerificationSoapParser();

  group('registroClienteValidacion', () {
    test('OK devuelve la clave creada', () {
      final result = registrationParser.parseValidation(
        _response('registroClienteValidacion', true, 'OK', '51'),
      );

      expect(result, isA<RegisterCreated>());
      expect((result as RegisterCreated).accountKey, 51);
    });

    test('EX sin cuenta solicita confirmar identidad', () {
      final result = registrationParser.parseValidation(
        _response(
          'registroClienteValidacion',
          true,
          'EX',
          '[{"_cCliente":7,"_cNombre":"CLIENTE","_cIdTelefono":8,'
              '"_cuenta":0,"_cDireccion":'
              '[{"_descrDireccion":"CENTRO"}]}]',
        ),
      );

      expect(result, isA<RegisterIdentityMatch>());
      final customer = (result as RegisterIdentityMatch).customer;
      expect(customer.customerKey, 7);
      expect(customer.phoneKey, 8);
      expect(customer.addresses, ['CENTRO']);
    });

    test('EX con cuenta existente dirige al login', () {
      final result = registrationParser.parseValidation(
        _response(
          'registroClienteValidacion',
          true,
          'EX',
          '[{"_cCliente":7,"_cNombre":"CLIENTE","_cIdTelefono":8,'
              '"_cuenta":1,"_cDireccion":[]}]',
        ),
      );

      expect(result, isA<RegisterExistingAccount>());
    });

    test('rechaza una respuesta sin el resultado esperado', () {
      expect(
        () => registrationParser.parseValidation(XmlDocument.parse('<x/>')),
        throwsA(isA<InvalidSoapResponseException>()),
      );
    });
  });

  test('registroClienteDirecto devuelve la clave creada', () {
    final result = registrationParser.parseDirect(
      _response('registroClienteDirecto', true, 'OK', '73'),
    );

    expect((result as RegisterCreated).accountKey, 73);
  });

  group('verificación', () {
    test('acepta un código válido', () {
      final result = verificationParser.parseVerification(
        _response('verificarCuenta', true, 'OK', ''),
      );

      expect(result, isA<VerificationSuccess>());
    });

    test('identifica un código inválido', () {
      final result = verificationParser.parseVerification(
        _response('verificarCuenta', false, 'ERROR', ''),
      );

      expect(result, isA<VerificationInvalidCode>());
    });

    test('identifica el reenvío correcto', () {
      final result = verificationParser.parseResend(
        _response('reenviarCodigo', true, 'OK', ''),
      );

      expect(result, isA<ResendCodeSuccess>());
    });
  });
}

XmlDocument _response(String method, bool result, String message, String data) {
  return XmlDocument.parse('''
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <${method}Response xmlns="awserver.noip.me:8888/">
      <${method}Result>
        <Result>$result</Result>
        <Message>$message</Message>
        <Data>$data</Data>
      </${method}Result>
    </${method}Response>
  </soap:Body>
</soap:Envelope>
''');
}
