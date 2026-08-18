import 'package:combugas_clientes/core/network/network_exception.dart';
import 'package:combugas_clientes/features/auth/data/login_soap_parser.dart';
import 'package:combugas_clientes/features/auth/models/login_result.dart';
import 'package:combugas_clientes/features/auth/models/session_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

void main() {
  const parser = LoginSoapParser();

  test('parsea un login correcto', () {
    final result = parser.parse(
      _response(
        result: true,
        message: 'LOG',
        data:
            '{"_claveApp":9,"_clave":12,"_nombre":"Cliente",'
            '"_telefono":34,"_activo":true,"_bloqueado":false,'
            '"_motivo_bloqueado":"","_tieneDireccion":1,'
            '"_mercado":1,"_subCanal":7}',
      ),
    );

    expect(result, isA<LoginSuccess>());
    final success = result as LoginSuccess;
    expect(success.hasAddress, isTrue);
    expect(
      success.session,
      const SessionData(
        claveUsuario: 12,
        nombreUsuario: 'Cliente',
        claveTelefono: 34,
        subcanalUsuario: 7,
      ),
    );
  });

  test('identifica credenciales incorrectas', () {
    final result = parser.parse(
      _response(
        result: false,
        message: 'NOTLOG',
        data: '"ERROR DE USUARIO O CONTRASEÑA"',
      ),
    );

    expect(result, isA<LoginInvalidCredentials>());
  });

  test('identifica una cuenta no activada', () {
    final result = parser.parse(
      _response(result: true, message: 'NACT', data: '{"_claveApp":91}'),
    );

    expect(result, isA<LoginInactiveAccount>());
    expect((result as LoginInactiveAccount).accountKey, 91);
  });

  test('rechaza una respuesta SOAP sin loginResult', () {
    expect(
      () => parser.parse(XmlDocument.parse('<invalid/>')),
      throwsA(isA<InvalidSoapResponseException>()),
    );
  });
}

XmlDocument _response({
  required bool result,
  required String message,
  required String data,
}) {
  return XmlDocument.parse('''
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <loginResponse xmlns="awserver.noip.me:8888/">
      <loginResult>
        <Result>$result</Result>
        <Message>$message</Message>
        <Data>$data</Data>
      </loginResult>
    </loginResponse>
  </soap:Body>
</soap:Envelope>
''');
}
