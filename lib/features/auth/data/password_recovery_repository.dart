import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/password_recovery_result.dart';
import 'auth_repository.dart';
import 'clientes_soap_service.dart';

abstract interface class PasswordRecoveryRepositoryContract {
  Future<PasswordRecoveryResult> recoverPassword(String telefono);
}

final class PasswordRecoveryRepository
    implements PasswordRecoveryRepositoryContract {
  const PasswordRecoveryRepository(this._clientesService);

  final PasswordRecoveryClientesService _clientesService;

  @override
  Future<PasswordRecoveryResult> recoverPassword(String telefono) {
    return _clientesService.recoverPassword(telefono);
  }
}

final passwordRecoveryRepositoryProvider = Provider<
  PasswordRecoveryRepositoryContract
>((ref) => PasswordRecoveryRepository(ref.watch(clientesSoapServiceProvider)));
