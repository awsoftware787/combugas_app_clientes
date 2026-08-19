import '../../../core/constants/service_endpoints.dart';
import '../../../core/constants/soap_constants.dart';
import '../../../core/network/soap_service.dart';
import '../models/producto.dart';
import '../models/create_order.dart';
import '../models/calificacion.dart';
import '../models/pedido_historial.dart';
import 'pedidos_soap_parser.dart';

abstract interface class PedidosService {
  Future<List<Producto>> getPrecios();
  Future<MontosMinimos> getMontosMinimos();
  Future<List<TiempoFase>> getTiempos();
  Future<CreateOrderResult> createOrder(CreateOrderRequest request);
  Future<List<PedidoHistorial>> getPedidos(int clienteId);
  Future<PedidoSeguimientoInfo> getUnPedido(int pedidoId);
  Future<CancelarPedidoResult> cancelarPedido(int pedidoId);
  Future<CalificacionResult> calificarServicio(CalificacionRequest request);
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

  @override
  Future<List<PedidoHistorial>> getPedidos(int clienteId) async =>
      _parser.parsePedidos(
        await _call(
          PedidosSoapMethods.obtenerTodos,
          parameters: {'_intIdCliente': clienteId},
        ),
      );

  @override
  Future<PedidoSeguimientoInfo> getUnPedido(int pedidoId) async =>
      _parser.parseUnPedido(
        await _call(
          PedidosSoapMethods.obtenerUno,
          parameters: {'_intIdPedido': pedidoId},
        ),
      );

  @override
  Future<CancelarPedidoResult> cancelarPedido(int pedidoId) async =>
      _parser.parseCancelarPedido(
        await _call(
          PedidosSoapMethods.cancelar,
          parameters: {'_intIdPedido': pedidoId},
        ),
      );

  @override
  Future<CalificacionResult> calificarServicio(
    CalificacionRequest request,
  ) async => _parser.parseCalificacion(
    await _call(
      PedidosSoapMethods.calificar,
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
    logExchange: method == PedidosSoapMethods.calificar,
  );

  void close() => _soap.close();
}
