import 'dart:async';

import 'package:combugas_clientes/core/network/network_exception.dart';
import 'package:combugas_clientes/features/auth/controllers/password_recovery_controller.dart';
import 'package:combugas_clientes/features/auth/data/password_recovery_repository.dart';
import 'package:combugas_clientes/features/auth/models/password_recovery_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('impide solicitudes simultáneas', () async {
    final completer = Completer<PasswordRecoveryResult>();
    final repository = _FakeRecoveryRepository((_) => completer.future);
    final container = ProviderContainer(
      overrides: [
        passwordRecoveryRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(
      passwordRecoveryControllerProvider.notifier,
    );

    final first = controller.recoverPassword('(871) 123-4567');
    final second = await controller.recoverPassword('(871) 123-4567');

    expect(repository.calls, 1);
    expect(second, isA<PasswordRecoveryFailure>());
    completer.complete(const PasswordRecoverySuccess());
    expect(await first, isA<PasswordRecoverySuccess>());
    expect(
      container.read(passwordRecoveryControllerProvider).isLoading,
      isFalse,
    );
  });

  test('timeout devuelve mensaje seguro y permite reintentar', () async {
    var attempt = 0;
    final repository = _FakeRecoveryRepository((_) async {
      attempt++;
      if (attempt == 1) throw const NetworkTimeoutException();
      return const PasswordRecoverySuccess();
    });
    final container = ProviderContainer(
      overrides: [
        passwordRecoveryRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(
      passwordRecoveryControllerProvider.notifier,
    );

    final failure = await controller.recoverPassword('(871) 123-4567');
    final success = await controller.recoverPassword('(871) 123-4567');

    expect(failure.message, 'El servidor tardó demasiado en responder.');
    expect(success, isA<PasswordRecoverySuccess>());
    expect(repository.calls, 2);
  });
}

final class _FakeRecoveryRepository
    implements PasswordRecoveryRepositoryContract {
  _FakeRecoveryRepository(this.handler);

  final Future<PasswordRecoveryResult> Function(String phone) handler;
  int calls = 0;

  @override
  Future<PasswordRecoveryResult> recoverPassword(String telefono) {
    calls++;
    return handler(telefono);
  }
}
