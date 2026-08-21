import 'package:combugas_clientes/core/network/soap_http_client.dart';
import 'package:combugas_clientes/core/network/soap_service.dart';
import 'package:combugas_clientes/features/auth/data/clientes_soap_service.dart';
import 'package:combugas_clientes/features/auth/models/password_recovery_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('envía el contrato exacto de recuperarContrasena', () async {
    final endpoint = Uri.parse('http://localhost/ws/clientes.asmx');
    final client = MockClient((request) async {
      expect(request.url, endpoint);
      expect(
        request.headers['SOAPAction'],
        'awserver.noip.me:8888/recuperarContrasena',
      );
      expect(
        request.body,
        contains('<recuperarContrasena xmlns="awserver.noip.me:8888/">'),
      );
      expect(
        request.body,
        contains('<_strTelefono>(871) 123-4567</_strTelefono>'),
      );
      return http.Response(_successfulResponse, 200);
    });
    final service = ClientesSoapService(
      soapService: SoapService(httpClient: SoapHttpClient(client: client)),
      endpoint: endpoint,
    );

    final result = await service.recoverPassword('(871) 123-4567');

    expect(result, isA<PasswordRecoverySuccess>());
    service.close();
  });
}

const _successfulResponse = '''
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <recuperarContrasenaResponse xmlns="awserver.noip.me:8888/">
      <recuperarContrasenaResult>
        <Result>true</Result><Message>RECUPERAOK</Message>
      </recuperarContrasenaResult>
    </recuperarContrasenaResponse>
  </soap:Body>
</soap:Envelope>
''';
