import 'package:combugas_clientes/core/network/soap_http_client.dart';
import 'package:combugas_clientes/core/network/soap_service.dart';
import 'package:combugas_clientes/features/auth/data/clientes_soap_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final endpoint = Uri.parse('http://localhost/ws/clientes.asmx');

  test(
    'traerInfoCliente envía la clave y convierte los datos del perfil',
    () async {
      final service = _service(endpoint, (request) {
        expect(request.headers['SOAPAction'], endsWith('traerInfoCliente'));
        expect(
          request.body,
          contains('<_intClaveUsuario>12</_intClaveUsuario>'),
        );
        return _response(
          'traerInfoCliente',
          true,
          'OK',
          '{"_nombre":"CLIENTE","_telefono":"8711234567",'
              '"_correo":"cliente@example.com","_tieneDireccion":2}',
        );
      });

      final perfil = await service.getPerfil(12);

      expect(perfil.nombre, 'CLIENTE');
      expect(perfil.telefono, '8711234567');
      expect(perfil.correo, 'cliente@example.com');
      expect(perfil.cantidadDirecciones, 2);
      expect(perfil.tieneDireccion, isTrue);
      service.close();
    },
  );

  test('actualizaCorreo conserva el nombre legado _strCorrreo', () async {
    final service = _service(endpoint, (request) {
      expect(request.headers['SOAPAction'], endsWith('actualizaCorreo'));
      expect(request.body, contains('<_intClaveUsuario>12</_intClaveUsuario>'));
      expect(
        request.body,
        contains('<_strCorrreo>cliente@example.com</_strCorrreo>'),
      );
      return _response('actualizaCorreo', true, 'OK', '');
    });

    final result = await service.actualizarCorreo(12, 'cliente@example.com');

    expect(result.succeeded, isTrue);
    service.close();
  });

  test('eliminarCuenta usa id_cliente y respeta Result=false', () async {
    final service = _service(endpoint, (request) {
      expect(request.headers['SOAPAction'], endsWith('eliminarCuenta'));
      expect(request.body, contains('<id_cliente>12</id_cliente>'));
      return _response('eliminarCuenta', false, 'NO ELIMINADA', '');
    });

    final result = await service.eliminarCuenta(12);

    expect(result.succeeded, isFalse);
    expect(result.message, 'NO ELIMINADA');
    service.close();
  });

  test('correo JSON null se representa como ausencia de correo', () async {
    final service = _service(
      endpoint,
      (_) => _response(
        'traerInfoCliente',
        true,
        'OK',
        '{"_nombre":"CLIENTE","_telefono":"1",'
            '"_correo":null,"_tieneDireccion":0}',
      ),
    );

    final perfil = await service.getPerfil(12);

    expect(perfil.correo, isNull);
    expect(perfil.tieneDireccion, isFalse);
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
