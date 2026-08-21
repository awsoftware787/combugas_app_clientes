import 'package:combugas_clientes/core/network/network_exception.dart';
import 'package:combugas_clientes/features/auth/data/password_recovery_soap_parser.dart';
import 'package:combugas_clientes/features/auth/models/password_recovery_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

void main() {
  const parser = PasswordRecoverySoapParser();

  test('RECUPERAOK es exitoso aunque Data no exista', () {
    final result = parser.parse(_response(result: true, message: 'RECUPERAOK'));

    expect(result, isA<PasswordRecoverySuccess>());
  });

  test('NOTEL conserva el mensaje funcional de Android', () {
    final result = parser.parse(_response(result: true, message: 'NOTEL'));

    expect(result, isA<PasswordRecoveryPhoneNotFound>());
    expect(
      result.message,
      'No se ha encontrado el número de teléfono especificado',
    );
  });

  test('Result false devuelve el error funcional de Android', () {
    final result = parser.parse(
      _response(result: false, message: 'RECUPERAERROR', data: 'detalle'),
    );

    expect(result, isA<PasswordRecoveryFailure>());
    expect(result.message, contains('call center COMBUGAS'));
  });

  test('rechaza una respuesta sin recuperarContrasenaResult', () {
    expect(
      () => parser.parse(XmlDocument.parse('<invalid/>')),
      throwsA(isA<InvalidSoapResponseException>()),
    );
  });
}

XmlDocument _response({
  required bool result,
  required String message,
  String? data,
}) => XmlDocument.parse('''
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <recuperarContrasenaResponse xmlns="awserver.noip.me:8888/">
      <recuperarContrasenaResult>
        <Result>$result</Result>
        <Message>$message</Message>
        ${data == null ? '' : '<Data>$data</Data>'}
      </recuperarContrasenaResult>
    </recuperarContrasenaResponse>
  </soap:Body>
</soap:Envelope>
''');
