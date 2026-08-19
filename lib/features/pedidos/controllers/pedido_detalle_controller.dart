import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_exception.dart';
import '../../auth/controllers/auth_controller.dart';
import '../data/pedido_repository.dart';
import '../models/pedido_historial.dart';
import 'mis_pedidos_controller.dart';

enum PedidoDetalleStatus { idle, loading, ready, error }

final class PedidoDetalleState {
  const PedidoDetalleState({
    this.status = PedidoDetalleStatus.idle,
    this.pedido,
    this.error,
    this.canceling = false,
    this.sessionLocked = false,
  });

  final PedidoDetalleStatus status;
  final PedidoHistorial? pedido;
  final String? error;
  final bool canceling;
  final bool sessionLocked;

  PedidoDetalleState copyWith({
    PedidoDetalleStatus? status,
    PedidoHistorial? pedido,
    String? error,
    bool clearError = false,
    bool? canceling,
    bool? sessionLocked,
  }) => PedidoDetalleState(
    status: status ?? this.status,
    pedido: pedido ?? this.pedido,
    error: clearError ? null : error ?? this.error,
    canceling: canceling ?? this.canceling,
    sessionLocked: sessionLocked ?? this.sessionLocked,
  );
}

final pedidoDetalleControllerProvider =
    NotifierProvider<PedidoDetalleController, PedidoDetalleState>(
      PedidoDetalleController.new,
    );

final class PedidoDetalleController extends Notifier<PedidoDetalleState> {
  @override
  PedidoDetalleState build() => const PedidoDetalleState();

  Future<void> load(int pedidoId, {bool refresh = false}) async {
    if (state.status == PedidoDetalleStatus.loading || state.canceling) return;
    if (!refresh) {
      final cached = ref.read(misPedidosControllerProvider).byId(pedidoId);
      if (cached != null) {
        state = PedidoDetalleState(
          status: PedidoDetalleStatus.ready,
          pedido: cached,
        );
        return;
      }
    }

    final clienteId = ref.read(authControllerProvider).session?.claveUsuario;
    if (clienteId == null) {
      state = const PedidoDetalleState(
        status: PedidoDetalleStatus.error,
        error: 'No existe una sesión activa.',
      );
      return;
    }
    state = PedidoDetalleState(
      status: PedidoDetalleStatus.loading,
      pedido: state.pedido,
    );
    try {
      final pedidos = await ref
          .read(pedidoRepositoryProvider)
          .getPedidos(clienteId);
      PedidoHistorial? selected;
      for (final pedido in pedidos) {
        if (pedido.id == pedidoId) {
          selected = pedido;
          break;
        }
      }
      if (selected == null) {
        throw const WebServiceException('El pedido solicitado no existe.');
      }
      state = PedidoDetalleState(
        status: PedidoDetalleStatus.ready,
        pedido: selected,
      );
    } catch (error) {
      state = PedidoDetalleState(
        status: PedidoDetalleStatus.error,
        pedido: state.pedido,
        error: _detailErrorMessage(error),
      );
    }
  }

  Future<bool> cancel() async {
    final pedido = state.pedido;
    if (pedido == null || !pedido.puedeCancelar || state.canceling) {
      return false;
    }
    state = state.copyWith(canceling: true, clearError: true);
    try {
      final result = await ref
          .read(pedidoRepositoryProvider)
          .cancelarPedido(pedido.id);
      if (result.sesionBloqueada) {
        state = state.copyWith(canceling: false, sessionLocked: true);
        return false;
      }
      if (!result.cancelado) {
        state = state.copyWith(
          canceling: false,
          error:
              result.mensaje.isEmpty
                  ? 'No fue posible cancelar el pedido.'
                  : result.mensaje,
        );
        return false;
      }
      final cancelled = pedido.copyWith(estatusPedido: false);
      state = PedidoDetalleState(
        status: PedidoDetalleStatus.ready,
        pedido: cancelled,
      );
      ref.read(misPedidosControllerProvider.notifier).markCancelled(pedido.id);
      return true;
    } catch (error) {
      state = state.copyWith(
        canceling: false,
        error: _detailErrorMessage(error),
      );
      return false;
    }
  }
}

String _detailErrorMessage(Object error) {
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
  return 'No fue posible consultar el pedido. Inténtalo nuevamente.';
}
