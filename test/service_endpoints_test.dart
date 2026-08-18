import 'package:combugas_clientes/core/constants/service_endpoints.dart';
import 'package:combugas_clientes/core/constants/soap_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('construye las URLs de los servicios del ambiente configurado', () {
    const configuredBaseUrl = String.fromEnvironment('SERVICE_BASE_URL_DEV');
    if (configuredBaseUrl.isEmpty) {
      expect(() => ServiceEndpoints.clientes, throwsStateError);
      return;
    }

    expect(
      ServiceEndpoints.clientes.toString(),
      'http://cgtng.sytes.net:8888/wscli/ws/clientes.asmx',
    );
    expect(
      ServiceEndpoints.direcciones.toString(),
      'http://cgtng.sytes.net:8888/wscli/ws/direcciones.asmx',
    );
    expect(
      ServiceEndpoints.pedidos.toString(),
      'http://cgtng.sytes.net:8888/wscli/ws/pedidos.asmx',
    );
  });

  test('conserva el namespace y los nombres SOAP heredados', () {
    expect(SoapConstants.namespace, 'awserver.noip.me:8888/');
    expect(ClientesSoapMethods.login, 'login');
    expect(DireccionesSoapMethods.obtenerTodas, 'getDirecciones');
    expect(PedidosSoapMethods.guardar, 'validaSalvarPedido');
  });
}
