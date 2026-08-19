import 'dart:async';

import 'package:combugas_clientes/core/network/soap_http_client.dart';
import 'package:combugas_clientes/core/network/soap_service.dart';
import 'package:combugas_clientes/core/network/network_exception.dart';
import 'package:combugas_clientes/features/pedidos/data/pedidos_soap_service.dart';
import 'package:combugas_clientes/features/pedidos/models/create_order.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../pedido_historial_fixture.dart';

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

  test('validaSalvarPedido envía el contrato Android exacto', () async {
    final endpoint = Uri.parse('http://localhost/ws/pedidos.asmx');
    final service = PedidosSoapService(
      endpoint: endpoint,
      soapService: SoapService(
        httpClient: SoapHttpClient(
          client: MockClient((request) async {
            expect(
              request.headers['SOAPAction'],
              'awserver.noip.me:8888/validaSalvarPedido',
            );
            for (final parameter in [
              '_intIdDireccion',
              '_intIdCliente',
              '_intIdTelefono',
              '_intIdMetodoPago',
              '_strDetallePedido',
              '_observacionesPedido',
            ]) {
              expect(request.body, contains('<$parameter'));
            }
            expect(request.body, contains('PORTON 3'));
            expect(request.body, contains('{"clave":2'));
            return http.Response(_response('validaSalvarPedido', '321'), 200);
          }),
        ),
      ),
    );
    final result = await service.createOrder(
      const CreateOrderRequest(
        direccionId: 9,
        clienteId: 12,
        telefonoId: 2,
        metodoPagoId: 4,
        detalles: [CreateOrderDetail(clave: 2, cantidad: 1, importe: 600)],
        observaciones: 'PORTON 3',
      ),
    );
    expect(result.pedidoId, 321);
    service.close();
  });

  test(
    'historial, consulta individual y cancelación usan contrato Android',
    () async {
      final endpoint = Uri.parse('http://localhost/ws/pedidos.asmx');
      final service = PedidosSoapService(
        endpoint: endpoint,
        soapService: SoapService(
          httpClient: SoapHttpClient(
            client: MockClient((request) async {
              late final String method;
              late final String data;
              var message = 'OK';
              if (request.body.contains('<getPedidos ')) {
                method = 'getPedidos';
                data = pedidoJson;
                expect(
                  request.body,
                  contains('<_intIdCliente>12</_intIdCliente>'),
                );
              } else if (request.body.contains('<getUnPedido ')) {
                method = 'getUnPedido';
                data = seguimientoJson;
                message = 'OKPED';
                expect(
                  request.body,
                  contains('<_intIdPedido>321</_intIdPedido>'),
                );
              } else {
                method = 'cancelarPedido';
                data = '';
                message = 'CANCELADO';
                expect(
                  request.body,
                  contains('<_intIdPedido>321</_intIdPedido>'),
                );
              }
              expect(
                request.headers['SOAPAction'],
                'awserver.noip.me:8888/$method',
              );
              return http.Response(
                _response(method, data, message: message),
                200,
              );
            }),
          ),
        ),
      );
      expect(await service.getPedidos(12), hasLength(1));
      expect((await service.getUnPedido(321)).direccion.id, 9);
      expect((await service.cancelarPedido(321)).cancelado, isTrue);
      service.close();
    },
  );

  test('getPedidos propaga HTTP inválido y SOAP inválido', () async {
    Future<void> expectFailure(http.Response response, Matcher matcher) async {
      final service = PedidosSoapService(
        endpoint: Uri.parse('http://localhost/ws/pedidos.asmx'),
        soapService: SoapService(
          httpClient: SoapHttpClient(client: MockClient((_) async => response)),
        ),
      );
      await expectLater(service.getPedidos(12), throwsA(matcher));
      service.close();
    }

    await expectFailure(
      http.Response('server error', 503),
      isA<InvalidHttpResponseException>(),
    );
    await expectFailure(
      http.Response('not xml', 200),
      isA<InvalidSoapResponseException>(),
    );
  });

  test('getUnPedido cubre error, vacío, timeout y SOAP inválido', () async {
    Future<void> expectTrackingFailure(
      Future<http.Response> Function(http.Request request) handler,
      Matcher matcher,
    ) async {
      final service = PedidosSoapService(
        endpoint: Uri.parse('http://localhost/ws/pedidos.asmx'),
        soapService: SoapService(
          httpClient: SoapHttpClient(client: MockClient(handler)),
        ),
      );
      await expectLater(service.getUnPedido(321), throwsA(matcher));
      service.close();
    }

    await expectTrackingFailure(
      (_) async => http.Response(
        _response(
          'getUnPedido',
          '',
          message: 'SINASIGNACION',
        ).replaceFirst('<Result>true</Result>', '<Result>false</Result>'),
        200,
      ),
      isA<WebServiceException>(),
    );
    await expectTrackingFailure(
      (_) async =>
          http.Response(_response('getUnPedido', '', message: 'OKPED'), 200),
      isA<InvalidSoapResponseException>(),
    );
    await expectTrackingFailure(
      (_) => Future<http.Response>.error(TimeoutException('timeout')),
      isA<NetworkTimeoutException>(),
    );
    await expectTrackingFailure(
      (_) async => http.Response('not xml', 200),
      isA<InvalidSoapResponseException>(),
    );
  });
}

String _response(String method, String data, {String message = 'OK'}) => '''
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><${method}Response><${method}Result>
<Result>true</Result><Message>$message</Message><Data><![CDATA[$data]]></Data>
</${method}Result></${method}Response></soap:Body></soap:Envelope>''';
