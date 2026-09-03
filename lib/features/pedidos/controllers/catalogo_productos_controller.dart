import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_exception.dart';
import '../data/pedido_repository.dart';
import '../models/producto.dart';

enum CatalogoProductosStatus { idle, loading, ready, error }

final class CatalogoProductosState {
  const CatalogoProductosState({
    this.status = CatalogoProductosStatus.idle,
    this.productos = const [],
    this.error,
    this.refreshing = false,
  });

  final CatalogoProductosStatus status;
  final List<Producto> productos;
  final String? error;
  final bool refreshing;

  Producto? producto(int id) {
    for (final producto in productos) {
      if (producto.id == id) return producto;
    }
    return null;
  }
}

final catalogoProductosControllerProvider =
    NotifierProvider<CatalogoProductosController, CatalogoProductosState>(
      CatalogoProductosController.new,
    );

/// Catálogo de sesión compartido por Productos, Pedido y el detalle histórico.
final class CatalogoProductosController
    extends Notifier<CatalogoProductosState> {
  Future<void>? _pending;

  @override
  CatalogoProductosState build() => const CatalogoProductosState();

  Future<void> load({bool refresh = false}) {
    final pending = _pending;
    if (pending != null) return pending;
    if (!refresh && state.status == CatalogoProductosStatus.ready) {
      return Future.value();
    }
    final request = _load(refresh: refresh);
    _pending = request;
    return request.whenComplete(() {
      if (identical(_pending, request)) _pending = null;
    });
  }

  Future<void> _load({required bool refresh}) async {
    final previous = state.productos;
    state = CatalogoProductosState(
      status:
          previous.isEmpty
              ? CatalogoProductosStatus.loading
              : CatalogoProductosStatus.ready,
      productos: previous,
      refreshing: refresh && previous.isNotEmpty,
    );
    try {
      final productos = await ref.read(pedidoRepositoryProvider).getPrecios();
      state = CatalogoProductosState(
        status: CatalogoProductosStatus.ready,
        productos: productos,
      );
    } catch (error) {
      if (previous.isNotEmpty) {
        state = CatalogoProductosState(
          status: CatalogoProductosStatus.ready,
          productos: previous,
          error:
              'No se pudieron actualizar los productos. Se conserva la lista anterior.',
        );
      } else {
        state = CatalogoProductosState(
          status: CatalogoProductosStatus.error,
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
    if (error is WebServiceException && error.message.isNotEmpty) {
      return error.message;
    }
    if (error is InvalidSoapResponseException) {
      return 'No fue posible procesar los productos del servidor.';
    }
    return 'No fue posible cargar los productos. Inténtalo nuevamente.';
  }
}
