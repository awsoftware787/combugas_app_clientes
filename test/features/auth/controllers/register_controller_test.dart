import 'dart:async';

import 'package:combugas_clientes/core/network/network_exception.dart';
import 'package:combugas_clientes/features/auth/controllers/register_controller.dart';
import 'package:combugas_clientes/features/auth/data/registration_repository.dart';
import 'package:combugas_clientes/features/auth/models/register_request.dart';
import 'package:combugas_clientes/features/auth/models/register_result.dart';
import 'package:combugas_clientes/features/auth/models/verification_request.dart';
import 'package:combugas_clientes/features/auth/models/verification_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const request = RegisterRequest(
    nombre: 'CLIENTE',
    telefono: '(871) 123-4567',
    contrasena: 'clave',
  );

  test('evita dos registros simultáneos y termina en éxito', () async {
    final completer = Completer<RegisterResult>();
    final repository = _FakeRegistrationRepository(
      validate: (_) => completer.future,
    );
    final container = ProviderContainer(
      overrides: [registrationRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final controller = container.read(registerControllerProvider.notifier);

    final first = controller.validateRegistration(request);
    expect(container.read(registerControllerProvider).isLoading, isTrue);
    final second = await controller.validateRegistration(request);
    expect(second, isA<RegisterFailure>());

    completer.complete(const RegisterCreated(17));
    expect(await first, isA<RegisterCreated>());
    expect(
      container.read(registerControllerProvider).status,
      RegisterStatus.success,
    );
  });

  test('convierte una falla de conexión en mensaje seguro', () async {
    final repository = _FakeRegistrationRepository(
      validate: (_) => Future.error(const NoConnectionException()),
    );
    final container = ProviderContainer(
      overrides: [registrationRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(registerControllerProvider.notifier)
        .validateRegistration(request);

    expect(result, isA<RegisterFailure>());
    expect(result.message, 'No fue posible conectarse al servidor.');
  });

  test('verifica y reenvía utilizando la clave temporal', () async {
    final repository = _FakeRegistrationRepository(
      validate: (_) async => const RegisterCreated(17),
    );
    final container = ProviderContainer(
      overrides: [registrationRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final controller = container.read(registerControllerProvider.notifier);

    expect(
      await controller.verifyAccount(
        const VerificationRequest(accountKey: 17, code: '123456'),
      ),
      isA<VerificationSuccess>(),
    );
    expect(await controller.resendCode(17), isA<ResendCodeSuccess>());
    expect(repository.lastAccountKey, 17);
  });
}

final class _FakeRegistrationRepository
    implements RegistrationRepositoryContract {
  _FakeRegistrationRepository({required this.validate});

  final Future<RegisterResult> Function(RegisterRequest request) validate;
  int? lastAccountKey;

  @override
  Future<RegisterResult> validateRegistration(RegisterRequest request) {
    return validate(request);
  }

  @override
  Future<RegisterResult> registerDirect({
    required RegisterRequest request,
    required int? customerKey,
    required int? phoneKey,
  }) async => const RegisterCreated(17);

  @override
  Future<ResendCodeResult> resendCode(int accountKey) async {
    lastAccountKey = accountKey;
    return const ResendCodeSuccess();
  }

  @override
  Future<VerificationResult> verifyAccount(VerificationRequest request) async {
    lastAccountKey = request.accountKey;
    return const VerificationSuccess();
  }
}
