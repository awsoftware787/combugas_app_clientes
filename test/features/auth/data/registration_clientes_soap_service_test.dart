import 'package:combugas_clientes/core/network/soap_http_client.dart';
import 'package:combugas_clientes/core/network/soap_service.dart';
import 'package:combugas_clientes/features/auth/data/clientes_soap_service.dart';
import 'package:combugas_clientes/features/auth/models/register_request.dart';
import 'package:combugas_clientes/features/auth/models/register_result.dart';
import 'package:combugas_clientes/features/auth/models/verification_request.dart';
import 'package:combugas_clientes/features/auth/models/verification_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final endpoint = Uri.parse('http://localhost/ws/clientes.asmx');
  const registerRequest = RegisterRequest(
    nombre: 'CLIENTE',
    telefono: '(871) 123-4567',
    contrasena: 'clave',
  );

  test('envía el contrato exacto de registroValidacion', () async {
    final service = _service(endpoint, (request) {
      expect(
        request.headers['SOAPAction'],
        endsWith('registroClienteValidacion'),
      );
      expect(request.body, contains('<_strNombre>CLIENTE</_strNombre>'));
      expect(
        request.body,
        contains('<_strTelefono>(871) 123-4567</_strTelefono>'),
      );
      expect(request.body, contains('<_strContrasena>clave</_strContrasena>'));
      return _response('registroClienteValidacion', true, 'OK', '21');
    });

    final result = await service.validateRegistration(registerRequest);

    expect(result, isA<RegisterCreated>());
    service.close();
  });

  test('registroDirecto conserva orden y serializa claves nulas', () async {
    final service = _service(endpoint, (request) {
      expect(request.headers['SOAPAction'], endsWith('registroClienteDirecto'));
      final body = request.body;
      expect(body, contains('<_intClave xsi:nil="true"/>'));
      expect(body, contains('<_intClaveTelefono xsi:nil="true"/>'));
      expect(
        body.indexOf('<_intClave '),
        lessThan(body.indexOf('<_strNombre>')),
      );
      expect(
        body.indexOf('<_strContrasena>'),
        lessThan(body.indexOf('<_intClaveTelefono ')),
      );
      return _response('registroClienteDirecto', true, 'OK', '22');
    });

    final result = await service.registerDirect(
      request: registerRequest,
      customerKey: null,
      phoneKey: null,
    );

    expect(result, isA<RegisterCreated>());
    service.close();
  });

  test('envía clave y código exactos al verificarCuenta', () async {
    final service = _service(endpoint, (request) {
      expect(request.headers['SOAPAction'], endsWith('verificarCuenta'));
      expect(request.body, contains('<_intClaveUsuario>31</_intClaveUsuario>'));
      expect(
        request.body,
        contains('<_strCodigoVerif>123456</_strCodigoVerif>'),
      );
      return _response('verificarCuenta', true, 'OK', '');
    });

    final result = await service.verifyAccount(
      const VerificationRequest(accountKey: 31, code: '123456'),
    );

    expect(result, isA<VerificationSuccess>());
    service.close();
  });

  test('envía únicamente la clave al reenviarCodigo', () async {
    final service = _service(endpoint, (request) {
      expect(request.headers['SOAPAction'], endsWith('reenviarCodigo'));
      expect(request.body, contains('<_intClaveUsuario>31</_intClaveUsuario>'));
      return _response('reenviarCodigo', true, 'OK', '');
    });

    final result = await service.resendCode(31);

    expect(result, isA<ResendCodeSuccess>());
    service.close();
  });
}

ClientesSoapService _service(
  Uri endpoint,
  String Function(http.Request request) handler,
) {
  final client = MockClient((request) async {
    expect(request.url, endpoint);
    return http.Response(handler(request), 200);
  });
  return ClientesSoapService(
    endpoint: endpoint,
    soapService: SoapService(httpClient: SoapHttpClient(client: client)),
  );
}

String _response(String method, bool result, String message, String data) => '''
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <${method}Response xmlns="awserver.noip.me:8888/">
      <${method}Result>
        <Result>$result</Result><Message>$message</Message><Data>$data</Data>
      </${method}Result>
    </${method}Response>
  </soap:Body>
</soap:Envelope>
''';
