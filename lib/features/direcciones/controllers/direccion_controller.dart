import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_exception.dart';
import '../../auth/controllers/auth_controller.dart';
import '../data/direccion_repository.dart';
import '../models/catalogos_direccion.dart';
import '../models/direccion.dart';
import '../models/direccion_request.dart';

enum DireccionStatus { idle, loading, ready, error }

final class DireccionState {
  const DireccionState({
    this.status = DireccionStatus.idle,
    this.direcciones = const [],
    this.selected,
    this.error,
    this.saving = false,
  });
  final DireccionStatus status;
  final List<Direccion> direcciones;
  final Direccion? selected;
  final String? error;
  final bool saving;
  DireccionState copyWith({
    DireccionStatus? status,
    List<Direccion>? direcciones,
    Direccion? selected,
    bool clearSelected = false,
    String? error,
    bool clearError = false,
    bool? saving,
  }) => DireccionState(
    status: status ?? this.status,
    direcciones: direcciones ?? this.direcciones,
    selected: clearSelected ? null : selected ?? this.selected,
    error: clearError ? null : error ?? this.error,
    saving: saving ?? this.saving,
  );
}

final direccionControllerProvider =
    NotifierProvider<DireccionController, DireccionState>(
      DireccionController.new,
    );

final class DireccionController extends Notifier<DireccionState> {
  @override
  DireccionState build() => const DireccionState();
  DireccionRepositoryContract get _repository =>
      ref.read(direccionRepositoryProvider);
  int? get _clienteId => ref.read(authControllerProvider).session?.claveUsuario;

  Future<void> load() async {
    final clienteId = _clienteId;
    if (clienteId == null) {
      state = const DireccionState(
        status: DireccionStatus.error,
        error: 'No existe una sesión activa.',
      );
      return;
    }
    state = state.copyWith(status: DireccionStatus.loading, clearError: true);
    try {
      final direcciones = await _repository.getDirecciones(clienteId);
      final stored = _repository.getSelected();
      Direccion? selected;
      if (stored != null) {
        for (final item in direcciones) {
          if (item.id == stored.id) {
            selected = item;
            break;
          }
        }
      }
      selected ??= direcciones.isEmpty ? null : direcciones.first;
      if (selected == null) {
        await _repository.clearSelected();
      } else {
        await _repository.saveSelected(selected);
      }
      state = DireccionState(
        status: DireccionStatus.ready,
        direcciones: direcciones,
        selected: selected,
      );
    } catch (error) {
      state = state.copyWith(
        status: DireccionStatus.error,
        error: _message(error),
      );
    }
  }

  Future<void> select(Direccion direccion) async {
    await _repository.saveSelected(direccion);
    state = state.copyWith(selected: direccion);
  }

  Future<List<Colonia>> getColonias() => _repository.getColonias();
  Future<List<Calle>> getCalles(int coloniaId) =>
      _repository.getCalles(coloniaId);
  Future<List<Cerrada>> getCerradas(int coloniaId) =>
      _repository.getCerradas(coloniaId);
  Future<Direccion> getDireccion(int direccionId) =>
      _repository.getDireccion(direccionId);

  Future<DireccionOperationResult> save(
    DireccionRequest request, {
    int? direccionId,
  }) async {
    if (state.saving) {
      return const DireccionOperationResult(
        succeeded: false,
        message: 'La solicitud ya está en curso.',
      );
    }
    final clienteId = _clienteId;
    if (clienteId == null) {
      return const DireccionOperationResult(
        succeeded: false,
        message: 'No existe una sesión activa.',
      );
    }
    state = state.copyWith(saving: true, clearError: true);
    try {
      final result =
          direccionId == null
              ? await _repository.guardar(clienteId, request)
              : await _repository.actualizar(direccionId, request);
      if (result.succeeded) await load();
      return result;
    } catch (error) {
      final message = _message(error);
      state = state.copyWith(error: message);
      return DireccionOperationResult(succeeded: false, message: message);
    } finally {
      state = state.copyWith(saving: false);
    }
  }

  Future<DireccionOperationResult> deactivate(int direccionId) async {
    if (state.saving) {
      return const DireccionOperationResult(
        succeeded: false,
        message: 'La solicitud ya está en curso.',
      );
    }
    final clienteId = _clienteId;
    if (clienteId == null) {
      return const DireccionOperationResult(
        succeeded: false,
        message: 'No existe una sesión activa.',
      );
    }
    state = state.copyWith(saving: true, clearError: true);
    try {
      final result = await _repository.desactivar(direccionId, clienteId);
      if (result.succeeded) await load();
      return result;
    } catch (error) {
      final message = _message(error);
      return DireccionOperationResult(succeeded: false, message: message);
    } finally {
      state = state.copyWith(saving: false);
    }
  }

  String _message(Object error) {
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
    return 'Ocurrió un error. Inténtalo nuevamente.';
  }
}
