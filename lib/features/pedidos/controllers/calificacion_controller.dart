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
  });

  final CalificacionStatus status;
  final String? message;
  bool get saving => status == CalificacionStatus.saving;
}

final calificacionControllerProvider =
    NotifierProvider<CalificacionController, CalificacionState>(
      CalificacionController.new,
    );

final class CalificacionController extends Notifier<CalificacionState> {
  @override
  CalificacionState build() => const CalificacionState();

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

    state = const CalificacionState(status: CalificacionStatus.saving);
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
      state = const CalificacionState(
        status: CalificacionStatus.success,
        message: 'Gracias por enviarnos sus comentarios.',
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
