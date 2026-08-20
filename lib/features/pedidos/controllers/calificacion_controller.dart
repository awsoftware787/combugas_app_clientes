import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_exception.dart';
import '../../auth/controllers/auth_controller.dart';
import '../data/pedido_repository.dart';
import '../models/calificacion.dart';
import 'mis_pedidos_controller.dart';

enum CalificacionStatus { idle, saving, success, error }

final class CalificacionState {
  const CalificacionState({
    this.status = CalificacionStatus.idle,
    this.message,
    this.pedidoId,
  });

  final CalificacionStatus status;
  final String? message;
  final int? pedidoId;
  bool get saving => status == CalificacionStatus.saving;
}

final calificacionControllerProvider =
    NotifierProvider<CalificacionController, CalificacionState>(
      CalificacionController.new,
    );

final class CalificacionController extends Notifier<CalificacionState> {
  @override
  CalificacionState build() => const CalificacionState();

  /// Prepara el controlador para el pedido que muestra la pantalla actual.
  ///
  /// El provider vive durante toda la sesión. Sin este reinicio, un envío
  /// anterior en estado [CalificacionStatus.success] bloqueaba silenciosamente
  /// la primera pulsación de Enviar de la siguiente confirmación.
  void prepare(int? pedidoId) {
    if (pedidoId == null || pedidoId <= 0 || state.saving) return;
    if (state.pedidoId != pedidoId ||
        state.status == CalificacionStatus.success) {
      state = CalificacionState(pedidoId: pedidoId);
    }
  }

  Future<bool> submit({
    required int pedidoId,
    required bool entregado,
    required int puntuacion,
    required String comentarios,
  }) async {
    if (state.saving || state.status == CalificacionStatus.success) {
      return false;
    }
    final clienteId = ref.read(authControllerProvider).session?.claveUsuario;
    if (pedidoId <= 0 || clienteId == null || clienteId <= 0) {
      state = const CalificacionState(
        status: CalificacionStatus.error,
        message: 'No fue posible identificar el pedido o el cliente.',
      );
      return false;
    }

    state = CalificacionState(
      status: CalificacionStatus.saving,
      pedidoId: pedidoId,
    );
    if (kDebugMode) {
      debugPrint(
        'Calificación: iniciando envío '
        '(pedido=$pedidoId, entregado=$entregado, puntuación=$puntuacion, '
        'caracteres=${comentarios.length})',
      );
    }
    try {
      await ref
          .read(pedidoRepositoryProvider)
          .calificarServicio(
            CalificacionRequest(
              entregado: entregado,
              puntuacion: puntuacion,
              comentarios: comentarios,
              pedidoId: pedidoId,
              clienteId: clienteId,
            ),
          );
      state = CalificacionState(
        status: CalificacionStatus.success,
        message: 'Gracias por enviarnos sus comentarios.',
        pedidoId: pedidoId,
      );
      ref.invalidate(misPedidosControllerProvider);
      return true;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error al enviar evaluación: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      state = CalificacionState(
        status: CalificacionStatus.error,
        message: _calificacionErrorMessage(error),
        pedidoId: pedidoId,
      );
      return false;
    }
  }
}

String _calificacionErrorMessage(Object error) {
  if (error is NoConnectionException) {
    return 'No fue posible conectarse al servidor.';
  }
  if (error is NetworkTimeoutException) {
    return 'El servidor tardó demasiado en responder.';
  }
  if (error is InvalidSoapResponseException) {
    return 'No fue posible procesar la respuesta del servidor.';
  }
  if (error is WebServiceException) {
    return 'No fue posible enviar la evaluación. Inténtalo nuevamente.';
  }
  return 'No fue posible enviar la calificación. Inténtalo nuevamente.';
}
