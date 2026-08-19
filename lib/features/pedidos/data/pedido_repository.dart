import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/producto.dart';
import 'pedidos_soap_service.dart';

abstract interface class PedidoRepositoryContract {
  Future<List<Producto>> getPrecios();
  Future<MontosMinimos> getMontosMinimos();
}

final class PedidoRepository implements PedidoRepositoryContract {
  const PedidoRepository(this._service);
  final PedidosService _service;
  @override
  Future<List<Producto>> getPrecios() => _service.getPrecios();
  @override
  Future<MontosMinimos> getMontosMinimos() => _service.getMontosMinimos();
}

final pedidosSoapServiceProvider = Provider<PedidosSoapService>((ref) {
  final service = PedidosSoapService();
  ref.onDispose(service.close);
  return service;
});

final pedidoRepositoryProvider = Provider<PedidoRepositoryContract>(
  (ref) => PedidoRepository(ref.watch(pedidosSoapServiceProvider)),
);
