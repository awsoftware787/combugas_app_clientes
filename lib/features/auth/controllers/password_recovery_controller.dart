import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_exception.dart';
import '../data/password_recovery_repository.dart';
import '../models/password_recovery_result.dart';

enum PasswordRecoveryStatus { idle, loading }

final class PasswordRecoveryState {
  const PasswordRecoveryState(this.status);

  const PasswordRecoveryState.idle() : status = PasswordRecoveryStatus.idle;

  final PasswordRecoveryStatus status;

  bool get isLoading => status == PasswordRecoveryStatus.loading;
}

final passwordRecoveryControllerProvider =
    NotifierProvider<PasswordRecoveryController, PasswordRecoveryState>(
      PasswordRecoveryController.new,
    );

final class PasswordRecoveryController extends Notifier<PasswordRecoveryState> {
  @override
  PasswordRecoveryState build() => const PasswordRecoveryState.idle();

  Future<PasswordRecoveryResult> recoverPassword(String telefono) async {
    if (state.isLoading) {
      return const PasswordRecoveryFailure('La recuperación ya está en curso.');
    }

    state = const PasswordRecoveryState(PasswordRecoveryStatus.loading);
    try {
      final result = await ref
          .read(passwordRecoveryRepositoryProvider)
          .recoverPassword(telefono);
      state = const PasswordRecoveryState.idle();
      return result;
    } on NoConnectionException {
      return _fail('No fue posible conectarse al servidor.');
    } on NetworkTimeoutException {
      return _fail('El servidor tardó demasiado en responder.');
    } on InvalidHttpResponseException {
      return _fail('El servidor no pudo procesar la solicitud.');
    } on InvalidSoapResponseException {
      return _fail('No fue posible procesar la respuesta del servidor.');
    } on NetworkException {
      return _fail(
        'No fue posible recuperar la contraseña. Inténtalo nuevamente.',
      );
    } catch (_) {
      return _fail('Ocurrió un error inesperado. Inténtalo nuevamente.');
    }
  }

  PasswordRecoveryFailure _fail(String message) {
    state = const PasswordRecoveryState.idle();
    return PasswordRecoveryFailure(message);
  }
}
