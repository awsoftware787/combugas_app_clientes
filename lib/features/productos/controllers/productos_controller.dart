import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_exception.dart';
import '../../pedidos/data/pedido_repository.dart';
import '../../pedidos/models/producto.dart';

enum ProductosStatus { idle, loading, ready, error }

final class ProductosState {
  const ProductosState({
    this.status = ProductosStatus.idle,
    this.productos = const [],
    this.error,
    this.refreshing = false,
  });

  final ProductosStatus status;
  final List<Producto> productos;
  final String? error;
  final bool refreshing;
}

final productosControllerProvider =
    NotifierProvider<ProductosController, ProductosState>(
      ProductosController.new,
    );

final class ProductosController extends Notifier<ProductosState> {
  @override
  ProductosState build() => const ProductosState();

  Future<void> load({bool refresh = false}) async {
    if (state.status == ProductosStatus.loading || state.refreshing) return;
    final previous = state.productos;
    state = ProductosState(
      status:
          previous.isEmpty ? ProductosStatus.loading : ProductosStatus.ready,
      productos: previous,
      refreshing: refresh && previous.isNotEmpty,
    );
    try {
      final productos = await ref.read(pedidoRepositoryProvider).getPrecios();
      state = ProductosState(
        status: ProductosStatus.ready,
        productos: productos,
      );
    } catch (error) {
      if (previous.isNotEmpty) {
        state = ProductosState(
          status: ProductosStatus.ready,
          productos: previous,
          error: 'No se pudieron actualizar los productos.',
        );
      } else {
        state = ProductosState(
          status: ProductosStatus.error,
          error: _message(error),
        );
      }
    }
  }

  String _message(Object error) {
    if (error is NoConnectionException) {
      return 'No fue posible conectarse al servidor.';
    }
    if (error is NetworkTimeoutException) {
      return 'El servidor tardó demasiado en responder.';
    }
    return 'No fue posible cargar productos';
  }
}
