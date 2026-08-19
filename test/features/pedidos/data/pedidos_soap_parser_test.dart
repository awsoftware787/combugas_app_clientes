import 'package:combugas_clientes/core/network/network_exception.dart';
import 'package:combugas_clientes/features/pedidos/data/pedidos_soap_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

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
}

String _envelope(String method, String result, String data) => '''
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><${method}Response><${method}Result>
<Result>$result</Result><Message>ERROR DE PRUEBA</Message><Data><![CDATA[$data]]></Data>
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
