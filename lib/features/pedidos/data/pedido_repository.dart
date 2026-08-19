import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/producto.dart';
import '../models/create_order.dart';
import 'pedidos_soap_service.dart';

abstract interface class PedidoRepositoryContract {
  Future<List<Producto>> getPrecios();
  Future<MontosMinimos> getMontosMinimos();
  Future<List<TiempoFase>> getTiempos();
  Future<CreateOrderResult> createOrder(CreateOrderRequest request);
}

final class PedidoRepository implements PedidoRepositoryContract {
  const PedidoRepository(this._service);
  final PedidosService _service;
  @override
  Future<List<Producto>> getPrecios() => _service.getPrecios();
  @override
  Future<MontosMinimos> getMontosMinimos() => _service.getMontosMinimos();
  @override
  Future<List<TiempoFase>> getTiempos() => _service.getTiempos();
  @override
  Future<CreateOrderResult> createOrder(CreateOrderRequest request) =>
      _service.createOrder(request);
}

final pedidosSoapServiceProvider = Provider<PedidosSoapService>((ref) {
  final service = PedidosSoapService();
  ref.onDispose(service.close);
  return service;
});

final pedidoRepositoryProvider = Provider<PedidoRepositoryContract>(
  (ref) => PedidoRepository(ref.watch(pedidosSoapServiceProvider)),
);
