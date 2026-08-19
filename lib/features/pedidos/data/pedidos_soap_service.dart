import '../../../core/constants/service_endpoints.dart';
import '../../../core/constants/soap_constants.dart';
import '../../../core/network/soap_service.dart';
import '../models/producto.dart';
import 'pedidos_soap_parser.dart';

abstract interface class PedidosService {
  Future<List<Producto>> getPrecios();
  Future<MontosMinimos> getMontosMinimos();
}

final class PedidosSoapService implements PedidosService {
  PedidosSoapService({
    SoapService? soapService,
    PedidosSoapParser? parser,
    Uri? endpoint,
  }) : _soap = soapService ?? SoapService(),
       _parser = parser ?? const PedidosSoapParser(),
       _endpoint = endpoint;

  final SoapService _soap;
  final PedidosSoapParser _parser;
  final Uri? _endpoint;
  Uri get endpoint => _endpoint ?? ServiceEndpoints.pedidos;

  @override
  Future<List<Producto>> getPrecios() async =>
      _parser.parsePrecios(await _call(PedidosSoapMethods.obtenerPrecios));

  @override
  Future<MontosMinimos> getMontosMinimos() async => _parser.parseMontosMinimos(
    await _call(PedidosSoapMethods.obtenerMontosMinimos),
  );

  Future<dynamic> _call(String method) => _soap.call(
    endpoint: endpoint,
    namespace: SoapConstants.namespace,
    methodName: method,
  );

  void close() => _soap.close();
}
