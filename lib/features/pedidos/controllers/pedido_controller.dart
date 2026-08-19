import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_exception.dart';
import '../data/pedido_repository.dart';
import '../models/producto.dart';

enum PedidoStatus { idle, loading, ready, error }

final class PedidoState {
  const PedidoState({
    this.status = PedidoStatus.idle,
    this.productos = const [],
    this.montosMinimos = const MontosMinimos.empty(),
    this.error,
    this.refreshing = false,
  });

  final PedidoStatus status;
  final List<Producto> productos;
  final MontosMinimos montosMinimos;
  final String? error;
  final bool refreshing;

  Producto? producto(int id) {
    for (final item in productos) {
      if (item.id == id) return item;
    }
    return null;
  }

  List<Producto> get bultos => productos
      .where((item) => item.esCroqueta && item.esBulto)
      .toList(growable: false);
  List<Producto> get bolsas => productos
      .where((item) => item.esCroqueta && item.esBolsa)
      .toList(growable: false);
}

final pedidoControllerProvider =
    NotifierProvider<PedidoController, PedidoState>(PedidoController.new);

final class PedidoController extends Notifier<PedidoState> {
  @override
  PedidoState build() => const PedidoState();

  Future<void> load({bool refresh = false}) async {
    if (state.status == PedidoStatus.loading || state.refreshing) return;
    final hasCatalog = state.productos.isNotEmpty;
    state = PedidoState(
      status: hasCatalog ? PedidoStatus.ready : PedidoStatus.loading,
      productos: state.productos,
      montosMinimos: state.montosMinimos,
      refreshing: refresh && hasCatalog,
    );
    try {
      final repository = ref.read(pedidoRepositoryProvider);
      final productos = await repository.getPrecios();
      final minimos = await repository.getMontosMinimos();
      state = PedidoState(
        status: PedidoStatus.ready,
        productos: productos,
        montosMinimos: minimos,
      );
    } catch (error) {
      final message = _message(error);
      if (hasCatalog) {
        state = PedidoState(
          status: PedidoStatus.ready,
          productos: state.productos,
          montosMinimos: state.montosMinimos,
          error:
              'No se pudieron actualizar los productos. Se conserva la lista anterior.',
        );
      } else {
        state = PedidoState(status: PedidoStatus.error, error: message);
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
    if (error is WebServiceException && error.message.isNotEmpty) {
      return error.message;
    }
    if (error is InvalidSoapResponseException) {
      return 'No fue posible procesar los productos del servidor.';
    }
    return 'No fue posible cargar los productos. Inténtalo nuevamente.';
  }
}
