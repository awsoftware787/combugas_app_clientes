import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/register_request.dart';
import '../models/register_result.dart';
import '../models/verification_request.dart';
import '../models/verification_result.dart';
import 'auth_repository.dart';
import 'clientes_soap_service.dart';

abstract interface class RegistrationRepositoryContract {
  Future<RegisterResult> validateRegistration(RegisterRequest request);

  Future<RegisterResult> registerDirect({
    required RegisterRequest request,
    required int? customerKey,
    required int? phoneKey,
  });

  Future<VerificationResult> verifyAccount(VerificationRequest request);

  Future<ResendCodeResult> resendCode(int accountKey);
}

final class RegistrationRepository implements RegistrationRepositoryContract {
  const RegistrationRepository(this._clientesService);

  final RegistrationClientesService _clientesService;

  @override
  Future<RegisterResult> validateRegistration(RegisterRequest request) {
    return _clientesService.validateRegistration(request);
  }

  @override
  Future<RegisterResult> registerDirect({
    required RegisterRequest request,
    required int? customerKey,
    required int? phoneKey,
  }) {
    return _clientesService.registerDirect(
      request: request,
      customerKey: customerKey,
      phoneKey: phoneKey,
    );
  }

  @override
  Future<VerificationResult> verifyAccount(VerificationRequest request) {
    return _clientesService.verifyAccount(request);
  }

  @override
  Future<ResendCodeResult> resendCode(int accountKey) {
    return _clientesService.resendCode(accountKey);
  }
}

final registrationRepositoryProvider = Provider<RegistrationRepositoryContract>(
  (ref) => RegistrationRepository(ref.watch(clientesSoapServiceProvider)),
);
