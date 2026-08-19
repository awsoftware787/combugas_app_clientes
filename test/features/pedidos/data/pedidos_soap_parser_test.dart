import 'package:combugas_clientes/core/network/network_exception.dart';
import 'package:combugas_clientes/features/pedidos/data/pedidos_soap_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

import '../pedido_historial_fixture.dart';

void main() {
  const parser = PedidosSoapParser();

  test('parsea precios fijos y croquetas con centavos exactos', () {
    final products = parser.parsePrecios(XmlDocument.parse(_prices));
    expect(products, hasLength(2));
    expect(products.first.id, 2);
    expect(products.first.precioCentavos, 63550);
    expect(products.last.esCroqueta, isTrue);
    expect(products.last.esBulto, isTrue);
    expect(products.last.opcionCroqueta, 'ADULTO 20 KG');
  });

  test('parsea montos mínimos para dinero y litros', () {
    final minimums = parser.parseMontosMinimos(XmlDocument.parse(_minimums));
    expect(minimums.dineroCentavos, 50000);
    expect(minimums.litros, 42.5);
  });

  test('propaga error funcional del servicio', () {
    expect(
      () => parser.parsePrecios(XmlDocument.parse(_failure)),
      throwsA(isA<WebServiceException>()),
    );
  });

  test('parsea tiempos y el id devuelto al crear pedido', () {
    final times = parser.parseTiempos(XmlDocument.parse(_times));
    expect(times.single.id, 2);
    expect(times.single.descripcion, '45 Minutos');
    final result = parser.parseCreateOrder(XmlDocument.parse(_created));
    expect(result.pedidoId, 321);
  });

  test('rechazo de validaSalvarPedido conserva el mensaje del servidor', () {
    expect(
      () => parser.parseCreateOrder(XmlDocument.parse(_createFailure)),
      throwsA(
        isA<WebServiceException>().having(
          (error) => error.message,
          'message',
          'NOHORARIO',
        ),
      ),
    );
  });

  test('getPedidos parsea listado completo, total, fecha y estado', () {
    final pedidos = parser.parsePedidos(
      XmlDocument.parse(_envelope('getPedidos', 'true', pedidoJson)),
    );
    expect(pedidos, hasLength(1));
    expect(pedidos.single.id, 321);
    expect(pedidos.single.direccion.direccionCompleta, contains('HIDALGO'));
    expect(pedidos.single.productos, hasLength(2));
    expect(pedidos.single.totalCentavos, 89010);
    expect(pedidos.single.puedeCancelar, isTrue);
  });

  test('getPedidos distingue lista vacía real', () {
    expect(
      parser.parsePedidos(
        XmlDocument.parse(_envelope('getPedidos', 'true', '[]')),
      ),
      isEmpty,
    );
  });

  test('getUnPedido parsea dirección y asignación de seguimiento', () {
    final result = parser.parseUnPedido(
      XmlDocument.parse(
        _envelope('getUnPedido', 'true', seguimientoJson, message: 'OKPED'),
      ),
    );
    expect(result.direccion.id, 9);
    expect(result.asignaciones.single.operadorId, 4);
    expect(result.asignaciones.single.nombreOperador, 'JUAN');
    expect(result.asignaciones.single.vehiculo?.descripcion, 'UNIDAD 12');
    expect(result.asignaciones.single.vehiculo?.latitud, 25.56);
    expect(result.asignaciones.single.vehiculo?.longitud, -103.45);
  });

  test('cancelarPedido reconoce CANCELADO y propaga rechazo funcional', () {
    final result = parser.parseCancelarPedido(
      XmlDocument.parse(
        _envelope('cancelarPedido', 'true', '', message: 'CANCELADO'),
      ),
    );
    expect(result.cancelado, isTrue);
    expect(
      () => parser.parseCancelarPedido(
        XmlDocument.parse(
          _envelope('cancelarPedido', 'false', '', message: 'ERROR'),
        ),
      ),
      throwsA(isA<WebServiceException>()),
    );
  });

  test('calificarServicio reconoce éxito y conserva el mensaje', () {
    final result = parser.parseCalificacion(
      XmlDocument.parse(
        _envelope(
          'calificarServicio',
          'true',
          '',
          message: 'CALIFICACION GUARDADA',
        ),
      ),
    );
    expect(result.mensaje, 'CALIFICACION GUARDADA');
  });

  test('calificarServicio acepta la respuesta ASMX real sin Data', () {
    final result = parser.parseCalificacion(
      XmlDocument.parse(_calificacionRealSinData),
    );
    expect(result.mensaje, 'CALIFOK');
  });

  test('calificarServicio interpreta rechazo ASMX real sin Data', () {
    expect(
      () => parser.parseCalificacion(
        XmlDocument.parse(_calificacionErrorRealSinData),
      ),
      throwsA(
        isA<WebServiceException>().having(
          (error) => error.message,
          'message',
          'CALIFERR',
        ),
      ),
    );
  });

  test('calificarServicio propaga el rechazo funcional', () {
    expect(
      () => parser.parseCalificacion(
        XmlDocument.parse(
          _envelope(
            'calificarServicio',
            'false',
            '',
            message: 'NO FUE POSIBLE GUARDAR',
          ),
        ),
      ),
      throwsA(
        isA<WebServiceException>().having(
          (error) => error.message,
          'message',
          'NO FUE POSIBLE GUARDAR',
        ),
      ),
    );
  });
}

String _envelope(
  String method,
  String result,
  String data, {
  String message = 'ERROR DE PRUEBA',
}) => '''
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><${method}Response><${method}Result>
<Result>$result</Result><Message>$message</Message><Data><![CDATA[$data]]></Data>
</${method}Result></${method}Response></soap:Body></soap:Envelope>''';

final _prices = _envelope(
  'getPrecios',
  'true',
  '[{"_idProducto":2,"_precioProducto":635.50,"_idServicio":1,"_descripcionProducto":"CILINDRO 30 KG"},{"_idProducto":20,"_precioProducto":499.99,"_idServicio":9,"_descripcionProducto":"BULTO DE ADULTO 20 KG"}]',
);
final _minimums = _envelope(
  'getMontosMinimos',
  'true',
  '[{"montominimo_dinero":500,"montominimo_litros":42.5}]',
);
final _failure = _envelope('getPrecios', 'false', '[]');
final _times = _envelope(
  'getTiemposFases',
  'true',
  '[{"_idTF":2,"_tiempoTF":"45","_unidad":"Minutos"}]',
);
final _created = _envelope('validaSalvarPedido', 'true', '321');
final _createFailure = '''
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><validaSalvarPedidoResponse><validaSalvarPedidoResult>
<Result>false</Result><Message>NOHORARIO</Message><Data></Data>
</validaSalvarPedidoResult></validaSalvarPedidoResponse></soap:Body></soap:Envelope>''';

const _calificacionRealSinData = '''
<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><calificarServicioResponse xmlns="awserver.noip.me:8888/"><calificarServicioResult><Result>true</Result><Message>CALIFOK</Message></calificarServicioResult></calificarServicioResponse></soap:Body></soap:Envelope>''';

const _calificacionErrorRealSinData = '''
<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><calificarServicioResponse xmlns="awserver.noip.me:8888/"><calificarServicioResult><Result>false</Result><Message>CALIFERR</Message></calificarServicioResult></calificarServicioResponse></soap:Body></soap:Envelope>''';
