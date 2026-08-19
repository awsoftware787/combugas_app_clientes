import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_exception.dart';
import '../../auth/controllers/auth_controller.dart';
import '../data/pedido_repository.dart';
import '../models/pedido_historial.dart';

enum MisPedidosStatus { idle, loading, ready, error }

final class MisPedidosState {
  const MisPedidosState({
    this.status = MisPedidosStatus.idle,
    this.pedidos = const [],
    this.error,
    this.refreshing = false,
  });

  final MisPedidosStatus status;
  final List<PedidoHistorial> pedidos;
  final String? error;
  final bool refreshing;

  PedidoHistorial? byId(int id) {
    for (final pedido in pedidos) {
      if (pedido.id == id) return pedido;
    }
    return null;
  }
}

final misPedidosControllerProvider =
    NotifierProvider<MisPedidosController, MisPedidosState>(
      MisPedidosController.new,
    );

final class MisPedidosController extends Notifier<MisPedidosState> {
  @override
  MisPedidosState build() => const MisPedidosState();

  Future<void> load({bool refresh = false}) async {
    if (state.status == MisPedidosStatus.loading || state.refreshing) return;
    final clienteId = ref.read(authControllerProvider).session?.claveUsuario;
    if (clienteId == null) {
      state = const MisPedidosState(
        status: MisPedidosStatus.error,
        error: 'No existe una sesión activa.',
      );
      return;
    }
    final hasData = state.pedidos.isNotEmpty;
    state = MisPedidosState(
      status: hasData ? MisPedidosStatus.ready : MisPedidosStatus.loading,
      pedidos: state.pedidos,
      refreshing: refresh && hasData,
    );
    try {
      final pedidos = await ref
          .read(pedidoRepositoryProvider)
          .getPedidos(clienteId);
      // Android conserva exactamente el orden entregado por el servidor.
      state = MisPedidosState(status: MisPedidosStatus.ready, pedidos: pedidos);
    } catch (error) {
      if (hasData) {
        state = MisPedidosState(
          status: MisPedidosStatus.ready,
          pedidos: state.pedidos,
          error: _pedidoErrorMessage(error),
        );
      } else {
        state = MisPedidosState(
          status: MisPedidosStatus.error,
          error: _pedidoErrorMessage(error),
        );
      }
    }
  }

  void markCancelled(int pedidoId) {
    state = MisPedidosState(
      status: MisPedidosStatus.ready,
      pedidos: state.pedidos
          .map(
            (pedido) =>
                pedido.id == pedidoId
                    ? pedido.copyWith(estatusPedido: false)
                    : pedido,
          )
          .toList(growable: false),
    );
  }
}

String _pedidoErrorMessage(Object error) {
  if (error is NoConnectionException) {
    return 'No fue posible conectarse al servidor.';
  }
  if (error is NetworkTimeoutException) {
    return 'El servidor tardó demasiado en responder.';
  }
  if (error is InvalidSoapResponseException) {
    return 'No fue posible procesar la respuesta del servidor.';
  }
  if (error is WebServiceException && error.message.isNotEmpty) {
    return error.message;
  }
  return 'No fue posible consultar tus pedidos. Inténtalo nuevamente.';
}
