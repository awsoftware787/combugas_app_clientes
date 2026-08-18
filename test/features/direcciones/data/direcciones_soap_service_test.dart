import 'package:combugas_clientes/core/network/soap_http_client.dart';
import 'package:combugas_clientes/core/network/soap_service.dart';
import 'package:combugas_clientes/features/direcciones/data/direcciones_soap_service.dart';
import 'package:combugas_clientes/features/direcciones/models/direccion_request.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final endpoint = Uri.parse('http://localhost/ws/direcciones.asmx');
  const request = DireccionRequest(
    descripcion: 'CASA',
    idColonia: 3,
    idCerrada: 1,
    idCalle: 2,
    numero: '123',
    latitud: 25.5,
    longitud: -103.4,
  );

  test('getDirecciones usa endpoint, SOAPAction y parámetro Android', () async {
    final service = _service(endpoint, (http.Request call) async {
      expect(call.url, endpoint);
      expect(
        call.headers['SOAPAction'],
        'awserver.noip.me:8888/getDirecciones',
      );
      expect(call.body, contains('<_intClaveCliente>12</_intClaveCliente>'));
      return _response('getDirecciones', '[]');
    });
    expect(await service.getDirecciones(12), isEmpty);
    service.close();
  });

  test('guardar y actualizar envían los nueve campos del contrato', () async {
    var calls = 0;
    final service = _service(endpoint, (http.Request call) async {
      calls++;
      expect(
        call.body,
        contains('<_strDescripcionDireccion>CASA</_strDescripcionDireccion>'),
      );
      expect(call.body, contains('<_intClaveColonia>3</_intClaveColonia>'));
      expect(call.body, contains('<_intIdCerrada>1</_intIdCerrada>'));
      expect(call.body, contains('<_intClaveCalle>2</_intClaveCalle>'));
      expect(call.body, contains('<_strCodigoP>SIN CODIGO</_strCodigoP>'));
      expect(call.body, contains('<_dblLatitud>25.5</_dblLatitud>'));
      final method =
          call.body.contains('<guardaDireccion ')
              ? 'guardaDireccion'
              : 'actualizaDireccion';
      return _response(method, '');
    });
    expect((await service.guardar(12, request)).succeeded, isTrue);
    expect((await service.actualizar(9, request)).succeeded, isTrue);
    expect(calls, 2);
    service.close();
  });

  test('desactivar envía dirección y cliente', () async {
    final service = _service(endpoint, (http.Request call) async {
      expect(call.body, contains('<_idDireccion>9</_idDireccion>'));
      expect(call.body, contains('<_idCliente>12</_idCliente>'));
      return _response('desactivaDireccion', '');
    });
    expect((await service.desactivar(9, 12)).succeeded, isTrue);
    service.close();
  });
}

DireccionesSoapService _service(
  Uri endpoint,
  Future<http.Response> Function(http.Request) handler,
) => DireccionesSoapService(
  endpoint: endpoint,
  soapService: SoapService(
    httpClient: SoapHttpClient(client: MockClient(handler)),
  ),
);

http.Response _response(String method, String data) => http.Response('''
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><${method}Response><${method}Result>
<Result>true</Result><Message>OK</Message><Data><![CDATA[$data]]></Data>
</${method}Result></${method}Response></soap:Body></soap:Envelope>''', 200);
