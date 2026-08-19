import 'package:combugas_clientes/core/network/soap_http_client.dart';
import 'package:combugas_clientes/core/network/soap_service.dart';
import 'package:combugas_clientes/features/pedidos/data/pedidos_soap_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('precios y mínimos usan pedidos.asmx sin parámetros', () async {
    final endpoint = Uri.parse('http://localhost/ws/pedidos.asmx');
    var calls = 0;
    final service = PedidosSoapService(
      endpoint: endpoint,
      soapService: SoapService(
        httpClient: SoapHttpClient(
          client: MockClient((request) async {
            calls++;
            expect(request.url, endpoint);
            expect(request.body, isNot(contains('<_')));
            final method =
                request.body.contains('<getPrecios ')
                    ? 'getPrecios'
                    : 'getMontosMinimos';
            expect(
              request.headers['SOAPAction'],
              'awserver.noip.me:8888/$method',
            );
            final data =
                method == 'getPrecios'
                    ? '[]'
                    : '[{"montominimo_dinero":0,"montominimo_litros":0}]';
            return http.Response(_response(method, data), 200);
          }),
        ),
      ),
    );
    expect(await service.getPrecios(), isEmpty);
    expect((await service.getMontosMinimos()).litros, 0);
    expect(calls, 2);
    service.close();
  });
}

String _response(String method, String data) => '''
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><${method}Response><${method}Result>
<Result>true</Result><Message>OK</Message><Data><![CDATA[$data]]></Data>
</${method}Result></${method}Response></soap:Body></soap:Envelope>''';
