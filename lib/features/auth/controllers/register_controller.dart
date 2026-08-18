import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_exception.dart';
import '../data/registration_repository.dart';
import '../models/register_request.dart';
import '../models/register_result.dart';
import '../models/verification_request.dart';
import '../models/verification_result.dart';

enum RegisterStatus { idle, loading, success, error }

final class RegisterState {
  const RegisterState({required this.status, this.message});

  final RegisterStatus status;
  final String? message;

  bool get isLoading => status == RegisterStatus.loading;
}

final registerControllerProvider =
    NotifierProvider<RegisterController, RegisterState>(RegisterController.new);

final class RegisterController extends Notifier<RegisterState> {
  @override
  RegisterState build() => const RegisterState(status: RegisterStatus.idle);

  Future<RegisterResult> validateRegistration(RegisterRequest request) async {
    if (!_begin()) {
      return const RegisterFailure('El registro ya está en curso.');
    }
    try {
      final result = await ref
          .read(registrationRepositoryProvider)
          .validateRegistration(request);
      _finish(result is RegisterFailure ? result.message : null);
      return result;
    } catch (error) {
      return _registerFailure(error);
    }
  }

  Future<RegisterResult> registerDirect({
    required RegisterRequest request,
    required int? customerKey,
    required int? phoneKey,
  }) async {
    if (!_begin()) {
      return const RegisterFailure('El registro ya está en curso.');
    }
    try {
      final result = await ref
          .read(registrationRepositoryProvider)
          .registerDirect(
            request: request,
            customerKey: customerKey,
            phoneKey: phoneKey,
          );
      _finish(result is RegisterFailure ? result.message : null);
      return result;
    } catch (error) {
      return _registerFailure(error);
    }
  }

  Future<VerificationResult> verifyAccount(VerificationRequest request) async {
    if (!_begin()) {
      return const VerificationFailure('La verificación ya está en curso.');
    }
    try {
      final result = await ref
          .read(registrationRepositoryProvider)
          .verifyAccount(request);
      _finish(result is VerificationFailure ? result.message : null);
      return result;
    } catch (error) {
      return _verificationFailure(error);
    }
  }

  Future<ResendCodeResult> resendCode(int accountKey) async {
    if (!_begin()) {
      return const ResendCodeFailure('Hay una solicitud en curso.');
    }
    try {
      final result = await ref
          .read(registrationRepositoryProvider)
          .resendCode(accountKey);
      _finish(result is ResendCodeFailure ? result.message : null);
      return result;
    } catch (error) {
      final message = _messageFor(
        error,
        fallback:
            'No se ha podido reenviar la información solicitada, revise su '
            'conexión e inténtelo nuevamente',
      );
      _finish(message);
      return ResendCodeFailure(message);
    }
  }

  bool _begin() {
    if (state.isLoading) return false;
    state = const RegisterState(status: RegisterStatus.loading);
    return true;
  }

  void _finish(String? error) {
    state = RegisterState(
      status: error == null ? RegisterStatus.success : RegisterStatus.error,
      message: error,
    );
  }

  RegisterFailure _registerFailure(Object error) {
    final message = _messageFor(
      error,
      fallback: 'Ocurrió un error, inténtelo nuevamente más tarde',
    );
    _finish(message);
    return RegisterFailure(message);
  }

  VerificationFailure _verificationFailure(Object error) {
    final message = _messageFor(
      error,
      fallback:
          'No se ha podido activar su cuenta, revise su conexión e inténtelo '
          'nuevamente',
    );
    _finish(message);
    return VerificationFailure(message);
  }

  String _messageFor(Object error, {required String fallback}) {
    return switch (error) {
      NoConnectionException() => 'No fue posible conectarse al servidor.',
      NetworkTimeoutException() => 'El servidor tardó demasiado en responder.',
      InvalidSoapResponseException() =>
        'No fue posible procesar la respuesta del servidor.',
      NetworkException() => fallback,
      _ => fallback,
    };
  }
}
