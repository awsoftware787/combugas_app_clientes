import 'package:combugas_clientes/features/auth/data/registration_repository.dart';
import 'package:combugas_clientes/features/auth/models/register_request.dart';
import 'package:combugas_clientes/features/auth/models/register_result.dart';
import 'package:combugas_clientes/features/auth/models/verification_request.dart';
import 'package:combugas_clientes/features/auth/models/verification_result.dart';
import 'package:combugas_clientes/features/auth/screens/register_screen.dart';
import 'package:combugas_clientes/features/auth/screens/verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('registro válido pasa la clave a verificación', (tester) async {
    final repository = _FakeRegistrationRepository();
    final router = _router();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          registrationRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.enterText(find.byKey(const Key('register_name')), 'cliente');
    await tester.enterText(
      find.byKey(const Key('register_phone')),
      '8711234567',
    );
    await tester.enterText(find.byKey(const Key('register_password')), 'clave');
    await tester.enterText(
      find.byKey(const Key('register_confirmation')),
      'clave',
    );
    await tester.ensureVisible(find.text('Registrarse'));
    await tester.tap(find.text('Registrarse'));
    await tester.pumpAndSettle();

    expect(repository.validations, 1);
    expect(find.byKey(const Key('verification_code')), findsOneWidget);
    expect(find.text('cuenta: 44'), findsOneWidget);
  });

  testWidgets('registro incompleto no consulta el servidor', (tester) async {
    final repository = _FakeRegistrationRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          registrationRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: RegisterScreen()),
      ),
    );

    await tester.ensureVisible(find.text('Registrarse'));
    await tester.tap(find.text('Registrarse'));
    await tester.pump();

    expect(find.text('Debe especificar un nombre válido'), findsOneWidget);
    expect(repository.validations, 0);
  });

  testWidgets('confirma una coincidencia y enlaza las claves encontradas', (
    tester,
  ) async {
    const customer = CustomerMatch(
      customerKey: 71,
      name: 'CLIENTE ENCONTRADO',
      phoneKey: 72,
      addresses: ['CENTRO'],
      hasAccount: false,
    );
    final repository = _FakeRegistrationRepository(
      validationResult: const RegisterIdentityMatch(customer),
    );
    final router = _router();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          registrationRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.enterText(find.byKey(const Key('register_name')), 'cliente');
    await tester.enterText(
      find.byKey(const Key('register_phone')),
      '8711234567',
    );
    await tester.enterText(
      find.byKey(const Key('register_password')),
      'clave',
    );
    await tester.enterText(
      find.byKey(const Key('register_confirmation')),
      'clave',
    );
    await tester.ensureVisible(find.text('Registrarse'));
    await tester.tap(find.text('Registrarse'));
    await tester.pumpAndSettle();

    expect(find.text('CLIENTE ENCONTRADO'), findsOneWidget);
    expect(find.text('Con domicilio en CENTRO'), findsOneWidget);
    await tester.tap(find.text('Soy yo'));
    await tester.pumpAndSettle();

    expect(repository.directRegistrations, 1);
    expect(repository.lastCustomerKey, 71);
    expect(repository.lastPhoneKey, 72);
    expect(find.byKey(const Key('verification_code')), findsOneWidget);
  });

  testWidgets('verificación correcta vuelve al login', (tester) async {
    final repository = _FakeRegistrationRepository();
    final router = _router(initialLocation: '/verification');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          registrationRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('verification_code')),
      '123456',
    );
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(repository.verifications, 1);
    expect(find.text('LOGIN'), findsOneWidget);
  });

  testWidgets('reenvía el código una vez por toque', (tester) async {
    final repository = _FakeRegistrationRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          registrationRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: VerificationScreen(accountKey: 44)),
      ),
    );

    await tester.tap(find.text('Reenviar código'));
    await tester.pumpAndSettle();

    expect(repository.resends, 1);
    expect(find.text('Se ha enviado su código'), findsOneWidget);
  });

  testWidgets('código con formato inválido no consulta el servidor', (
    tester,
  ) async {
    final repository = _FakeRegistrationRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          registrationRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          home: VerificationScreen(accountKey: 44),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('verification_code')),
      '12345',
    );
    await tester.tap(find.text('Continuar'));
    await tester.pump();

    expect(
      find.text('El código de verificación no tiene el formato correcto'),
      findsOneWidget,
    );
    expect(repository.verifications, 0);
  });
}

GoRouter _router({String initialLocation = '/register'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const Text('LOGIN')),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/verification',
        builder:
            (_, __) => const Column(
              children: [
                Expanded(child: VerificationScreen(accountKey: 44)),
                Text('cuenta: 44'),
              ],
            ),
      ),
      GoRoute(
        path: '/registro-verificacion',
        builder:
            (_, state) => Column(
              children: [
                Expanded(
                  child: VerificationScreen(accountKey: state.extra! as int),
                ),
                Text('cuenta: ${state.extra}'),
              ],
            ),
      ),
    ],
  );
}

final class _FakeRegistrationRepository
    implements RegistrationRepositoryContract {
  _FakeRegistrationRepository({
    this.validationResult = const RegisterCreated(44),
  });

  final RegisterResult validationResult;
  int validations = 0;
  int directRegistrations = 0;
  int verifications = 0;
  int resends = 0;
  int? lastCustomerKey;
  int? lastPhoneKey;

  @override
  Future<RegisterResult> validateRegistration(RegisterRequest request) async {
    validations++;
    return validationResult;
  }

  @override
  Future<RegisterResult> registerDirect({
    required RegisterRequest request,
    required int? customerKey,
    required int? phoneKey,
  }) async {
    directRegistrations++;
    lastCustomerKey = customerKey;
    lastPhoneKey = phoneKey;
    return const RegisterCreated(44);
  }

  @override
  Future<ResendCodeResult> resendCode(int accountKey) async {
    resends++;
    return const ResendCodeSuccess();
  }

  @override
  Future<VerificationResult> verifyAccount(VerificationRequest request) async {
    verifications++;
    return const VerificationSuccess();
  }
}
