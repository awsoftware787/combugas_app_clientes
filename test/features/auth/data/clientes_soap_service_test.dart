import 'package:combugas_clientes/core/network/soap_http_client.dart';
import 'package:combugas_clientes/core/network/soap_service.dart';
import 'package:combugas_clientes/features/auth/data/clientes_soap_service.dart';
import 'package:combugas_clientes/features/auth/models/login_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('envía endpoint, SOAPAction, método y parámetros exactos', () async {
    final endpoint = Uri.parse('http://localhost/ws/clientes.asmx');
    final client = MockClient((request) async {
      expect(request.url, endpoint);
      expect(request.headers['SOAPAction'], 'awserver.noip.me:8888/login');
      expect(request.body, contains('<login xmlns="awserver.noip.me:8888/">'));
      expect(
        request.body,
        contains('<_strTelefono>(871) 123-4567</_strTelefono>'),
      );
      expect(
        request.body,
        contains('<_strContrasena>secreta</_strContrasena>'),
      );
      return http.Response(_successfulResponse, 200);
    });
    final soapService = SoapService(httpClient: SoapHttpClient(client: client));
    final service = ClientesSoapService(
      soapService: soapService,
      endpoint: endpoint,
    );

    final result = await service.login(
      telefono: '(871) 123-4567',
      contrasena: 'secreta',
    );

    expect(result, isA<LoginSuccess>());
    service.close();
  });
}

const _successfulResponse = '''
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <loginResponse xmlns="awserver.noip.me:8888/">
      <loginResult>
        <Result>true</Result>
        <Message>LOG</Message>
        <Data>{"_clave":12,"_nombre":"Cliente","_telefono":34,"_bloqueado":false,"_tieneDireccion":1,"_mercado":1,"_subCanal":7}</Data>
      </loginResult>
    </loginResponse>
  </soap:Body>
</soap:Envelope>
''';
