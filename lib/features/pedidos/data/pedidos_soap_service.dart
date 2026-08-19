import '../../../core/constants/service_endpoints.dart';
import '../../../core/constants/soap_constants.dart';
import '../../../core/network/soap_service.dart';
import '../models/producto.dart';
import '../models/create_order.dart';
import 'pedidos_soap_parser.dart';

abstract interface class PedidosService {
  Future<List<Producto>> getPrecios();
  Future<MontosMinimos> getMontosMinimos();
  Future<List<TiempoFase>> getTiempos();
  Future<CreateOrderResult> createOrder(CreateOrderRequest request);
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

  @override
  Future<List<TiempoFase>> getTiempos() async =>
      _parser.parseTiempos(await _call(PedidosSoapMethods.obtenerTiempos));

  @override
  Future<CreateOrderResult> createOrder(CreateOrderRequest request) async =>
      _parser.parseCreateOrder(
        await _call(
          PedidosSoapMethods.guardar,
          parameters: request.soapParameters,
        ),
      );

  Future<dynamic> _call(
    String method, {
    Map<String, Object?> parameters = const {},
  }) => _soap.call(
    endpoint: endpoint,
    namespace: SoapConstants.namespace,
    methodName: method,
    parameters: parameters,
  );

  void close() => _soap.close();
}
