import 'package:combugas_clientes/core/network/network_exception.dart';
import 'package:combugas_clientes/core/network/soap_http_client.dart';
import 'package:combugas_clientes/core/network/soap_service.dart';
import 'package:combugas_clientes/features/pedidos/data/evaluacion_pendiente_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final endpoint = Uri.parse('http://localhost/ws/clientes.asmx');

  test('CONFIRMA devuelve pedido y dirección del contrato Android', () async {
    final service = _service(
      endpoint,
      message: 'CONFIRMA',
      data: '[{"Id_Pedido":321,"DescripcionDireccion":"CASA"}]',
      verifyRequest: (request) {
        expect(request.url, endpoint);
        expect(
          request.headers['SOAPAction'],
          'awserver.noip.me:8888/pendienteFormulario',
        );
        expect(
          request.body,
          contains('<_intClaveCliente>12</_intClaveCliente>'),
        );
      },
    );

    final pending = await service.consultar(12);
    expect(pending?.pedidoId, 321);
    expect(pending?.descripcionDireccion, 'CASA');
    service.close();
  });

  test('NOCONFIRMA permite continuar sin formulario', () async {
    final service = _service(endpoint, message: 'NOCONFIRMA', data: '[]');
    expect(await service.consultar(12), isNull);
    service.close();
  });

  test('CONFIRMA con datos inválidos propaga SOAP inválido', () async {
    final service = _service(endpoint, message: 'CONFIRMA', data: 'no-json');
    await expectLater(
      service.consultar(12),
      throwsA(isA<InvalidSoapResponseException>()),
    );
    service.close();
  });
}

EvaluacionPendienteService _service(
  Uri endpoint, {
  required String message,
  required String data,
  void Function(http.Request request)? verifyRequest,
}) => EvaluacionPendienteService(
  endpoint: endpoint,
  soapService: SoapService(
    httpClient: SoapHttpClient(
      client: MockClient((request) async {
        verifyRequest?.call(request);
        return http.Response(_response(message, data), 200);
      }),
    ),
  ),
);

String _response(String message, String data) => '''
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><pendienteFormularioResponse><pendienteFormularioResult>
<Result>true</Result><Message>$message</Message><Data><![CDATA[$data]]></Data>
</pendienteFormularioResult></pendienteFormularioResponse></soap:Body></soap:Envelope>''';
