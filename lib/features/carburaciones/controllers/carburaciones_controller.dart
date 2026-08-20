import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_exception.dart';
import '../data/carburaciones_repository.dart';
import '../models/carburacion.dart';

enum CarburacionesStatus { idle, loading, ready, error }

final class CarburacionesState {
  const CarburacionesState({
    this.status = CarburacionesStatus.idle,
    this.carburaciones = const [],
    this.error,
    this.refreshing = false,
  });

  final CarburacionesStatus status;
  final List<Carburacion> carburaciones;
  final String? error;
  final bool refreshing;
}

final carburacionesControllerProvider =
    NotifierProvider<CarburacionesController, CarburacionesState>(
      CarburacionesController.new,
    );

final class CarburacionesController extends Notifier<CarburacionesState> {
  @override
  CarburacionesState build() => const CarburacionesState();

  Future<void> load({bool refresh = false}) async {
    if (state.status == CarburacionesStatus.loading || state.refreshing) return;
    final previous = state.carburaciones;
    state = CarburacionesState(
      status:
          previous.isEmpty
              ? CarburacionesStatus.loading
              : CarburacionesStatus.ready,
      carburaciones: previous,
      refreshing: refresh && previous.isNotEmpty,
    );
    try {
      final values =
          await ref.read(carburacionesRepositoryProvider).getCarburaciones();
      state = CarburacionesState(
        status: CarburacionesStatus.ready,
        carburaciones: values,
      );
    } catch (error) {
      state = CarburacionesState(
        status:
            previous.isEmpty
                ? CarburacionesStatus.error
                : CarburacionesStatus.ready,
        carburaciones: previous,
        error: _message(error),
      );
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
    return 'No fue posible cargar las carburaciones.';
  }
}
