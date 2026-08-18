import 'package:combugas_clientes/core/network/network_exception.dart';
import 'package:combugas_clientes/features/direcciones/data/direcciones_soap_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

void main() {
  const parser = DireccionesSoapParser();

  test('parsea todos los campos reales de getDirecciones', () {
    final result = parser.parseDirecciones(
      XmlDocument.parse(_direcciones),
      'getDirecciones',
    );
    expect(result, hasLength(1));
    final address = result.single;
    expect(address.id, 9);
    expect(address.etiqueta, 'CASA');
    expect(address.calleCompleta, 'CALLE HIDALGO 123, PRIVADA SOL');
    expect(address.requiereClave, isTrue);
    expect(address.tienePedido, isFalse);
    expect(address.latitud, 25.5);
    expect(address.longitud, -103.4);
  });

  test('parsea catálogos dependientes', () {
    final colonias = parser.parseColonias(XmlDocument.parse(_colonias));
    final calles = parser.parseCalles(XmlDocument.parse(_calles));
    final cerradas = parser.parseCerradas(XmlDocument.parse(_cerradas));
    expect(colonias.single.ciudad, 'TORREÓN');
    expect(calles.single.descripcion, 'HIDALGO');
    expect(cerradas.single.id, 4);
  });

  test('respuesta funcional fallida produce WebServiceException', () {
    expect(
      () => parser.parseDirecciones(
        XmlDocument.parse(_failure),
        'getDirecciones',
      ),
      throwsA(isA<WebServiceException>()),
    );
  });
}

String envelope(String method, String result, String message, String data) =>
    '''
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><${method}Response><${method}Result>
<Result>$result</Result><Message>$message</Message><Data><![CDATA[$data]]></Data>
</${method}Result></${method}Response></soap:Body></soap:Envelope>''';

final _direcciones = envelope(
  'getDirecciones',
  'true',
  'OK',
  '''[{"_id_direccion":9,"_descr_direccion":"CASA","_descr_tipo_calle":"CALLE","_id_calle":2,"_descr_calle":"HIDALGO","_no_interior":"","_no_exterior":"123","_id_colonia":3,"_descr_colonia":"CENTRO","_id_ciudad":1,"_descr_ciudad":"TORREÓN","_id_estado":5,"_descr_estado":"COAHUILA","_id_zona":6,"_descr_zona":"NORTE","_id_cp":27000,"_descr_cp":"27000","_referencias":"PORTÓN ROJO","_status":true,"_latitud":25.5,"_longitud":-103.4,"_observaciones":"","_entre_1":"A","_entre_2":"B","_entre_3":"","_id_segmento":4,"_decr_cerrada":"PRIVADA SOL","_req_clave":1,"_clave":"1234","_id_ruta":8,"_tienePedido":0}]''',
);
final _colonias = envelope(
  'getColonias',
  'true',
  'OK',
  '[{"_idColonia":3,"_descrColonia":"CENTRO","_idCiudad":1,"_descrCiudad":"TORREÓN","_idEstado":5,"_descrEstado":"COAHUILA"}]',
);
final _calles = envelope(
  'getCalles',
  'true',
  'OK',
  '[{"_idCalle":2,"_descrCalle":"HIDALGO"}]',
);
final _cerradas = envelope(
  'getCerradas',
  'true',
  'OK',
  '[{"_idCerrada":4,"_descripcionCerrada":"PRIVADA SOL"}]',
);
final _failure = envelope('getDirecciones', 'false', 'ERROR', '[]');
