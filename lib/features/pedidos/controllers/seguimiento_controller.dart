import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_exception.dart';
import '../data/pedido_repository.dart';
import '../models/pedido_historial.dart';
import 'mis_pedidos_controller.dart';

enum SeguimientoStatus { idle, loading, ready, error }

final class SeguimientoState {
  const SeguimientoState({
    this.status = SeguimientoStatus.idle,
    this.info,
    this.error,
    this.canceling = false,
    this.sessionLocked = false,
  });

  final SeguimientoStatus status;
  final PedidoSeguimientoInfo? info;
  final String? error;
  final bool canceling;
  final bool sessionLocked;

  SeguimientoState copyWith({
    SeguimientoStatus? status,
    PedidoSeguimientoInfo? info,
    String? error,
    bool clearError = false,
    bool? canceling,
    bool? sessionLocked,
  }) => SeguimientoState(
    status: status ?? this.status,
    info: info ?? this.info,
    error: clearError ? null : error ?? this.error,
    canceling: canceling ?? this.canceling,
    sessionLocked: sessionLocked ?? this.sessionLocked,
  );
}

final seguimientoControllerProvider =
    NotifierProvider<SeguimientoController, SeguimientoState>(
      SeguimientoController.new,
    );

final class SeguimientoController extends Notifier<SeguimientoState> {
  @override
  SeguimientoState build() => const SeguimientoState();

  Future<void> load(int pedidoId, {bool refresh = false}) async {
    if (state.status == SeguimientoStatus.loading || state.canceling) return;
    state = SeguimientoState(
      status: SeguimientoStatus.loading,
      info: refresh ? state.info : null,
    );
    try {
      final info = await ref
          .read(pedidoRepositoryProvider)
          .getUnPedido(pedidoId);
      state = SeguimientoState(status: SeguimientoStatus.ready, info: info);
    } catch (error) {
      state = SeguimientoState(
        status: SeguimientoStatus.error,
        info: state.info,
        error: seguimientoErrorMessage(error),
      );
    }
  }

  Future<bool> cancel(int pedidoId) async {
    if (state.canceling) return false;
    state = state.copyWith(canceling: true, clearError: true);
    try {
      final result = await ref
          .read(pedidoRepositoryProvider)
          .cancelarPedido(pedidoId);
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
      ref.invalidate(misPedidosControllerProvider);
      state = state.copyWith(canceling: false);
      return true;
    } catch (error) {
      state = state.copyWith(
        canceling: false,
        error: seguimientoErrorMessage(error),
      );
      return false;
    }
  }
}

String seguimientoErrorMessage(Object error) {
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
  return 'No fue posible consultar el seguimiento. Inténtalo nuevamente.';
}
