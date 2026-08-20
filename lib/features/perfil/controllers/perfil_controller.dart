import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_exception.dart';
import '../../auth/controllers/auth_controller.dart';
import '../data/perfil_repository.dart';
import '../models/perfil_cliente.dart';

enum PerfilStatus { idle, loading, ready, error }

final class PerfilState {
  const PerfilState({
    this.status = PerfilStatus.idle,
    this.perfil,
    this.error,
    this.updatingEmail = false,
    this.deletingAccount = false,
  });

  final PerfilStatus status;
  final PerfilCliente? perfil;
  final String? error;
  final bool updatingEmail;
  final bool deletingAccount;

  PerfilState copyWith({
    PerfilStatus? status,
    PerfilCliente? perfil,
    String? error,
    bool clearError = false,
    bool? updatingEmail,
    bool? deletingAccount,
  }) => PerfilState(
    status: status ?? this.status,
    perfil: perfil ?? this.perfil,
    error: clearError ? null : error ?? this.error,
    updatingEmail: updatingEmail ?? this.updatingEmail,
    deletingAccount: deletingAccount ?? this.deletingAccount,
  );
}

final perfilControllerProvider =
    NotifierProvider<PerfilController, PerfilState>(PerfilController.new);

final class PerfilController extends Notifier<PerfilState> {
  @override
  PerfilState build() => const PerfilState();

  int? get _clienteId => ref.read(authControllerProvider).session?.claveUsuario;
  PerfilRepositoryContract get _repository =>
      ref.read(perfilRepositoryProvider);

  Future<void> load() async {
    final clienteId = _clienteId;
    if (clienteId == null || clienteId <= 0) {
      state = const PerfilState(
        status: PerfilStatus.error,
        error: 'No existe una sesión activa.',
      );
      return;
    }
    state = state.copyWith(status: PerfilStatus.loading, clearError: true);
    try {
      final perfil = await _repository.getPerfil(clienteId);
      state = PerfilState(status: PerfilStatus.ready, perfil: perfil);
    } catch (error) {
      state = state.copyWith(
        status: PerfilStatus.error,
        error: perfilErrorMessage(error),
      );
    }
  }

  Future<PerfilOperationResult> actualizarCorreo(String correo) async {
    final clienteId = _clienteId;
    if (clienteId == null || clienteId <= 0) {
      return const PerfilOperationResult(
        succeeded: false,
        message: 'No existe una sesión activa.',
      );
    }
    if (state.updatingEmail) {
      return const PerfilOperationResult(
        succeeded: false,
        message: 'La actualización ya está en curso.',
      );
    }
    state = state.copyWith(updatingEmail: true, clearError: true);
    try {
      final result = await _repository.actualizarCorreo(
        clienteId,
        correo.trim(),
      );
      if (result.succeeded && state.perfil != null) {
        state = state.copyWith(
          perfil: state.perfil!.copyWith(correo: correo.trim()),
        );
      }
      return result;
    } catch (error) {
      return PerfilOperationResult(
        succeeded: false,
        message: perfilErrorMessage(error),
      );
    } finally {
      state = state.copyWith(updatingEmail: false);
    }
  }

  Future<PerfilOperationResult> eliminarCuenta() async {
    final clienteId = _clienteId;
    if (clienteId == null || clienteId <= 0) {
      return const PerfilOperationResult(
        succeeded: false,
        message: 'No existe una sesión activa.',
      );
    }
    if (state.deletingAccount) {
      return const PerfilOperationResult(
        succeeded: false,
        message: 'La eliminación ya está en curso.',
      );
    }
    state = state.copyWith(deletingAccount: true, clearError: true);
    try {
      return await _repository.eliminarCuenta(clienteId);
    } catch (error) {
      return PerfilOperationResult(
        succeeded: false,
        message: perfilErrorMessage(error),
      );
    } finally {
      state = state.copyWith(deletingAccount: false);
    }
  }
}

String perfilErrorMessage(Object error) {
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
