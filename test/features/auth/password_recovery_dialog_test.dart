import 'dart:async';

import 'package:combugas_clientes/core/network/network_exception.dart';
import 'package:combugas_clientes/core/theme/app_theme.dart';
import 'package:combugas_clientes/features/auth/data/auth_repository.dart';
import 'package:combugas_clientes/features/auth/data/password_recovery_repository.dart';
import 'package:combugas_clientes/features/auth/models/login_result.dart';
import 'package:combugas_clientes/features/auth/models/password_recovery_result.dart';
import 'package:combugas_clientes/features/auth/models/session_data.dart';
import 'package:combugas_clientes/features/auth/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('abre el modal y REGRESAR conserva los datos del Login', (
    tester,
  ) async {
    final repository = _FakeRecoveryRepository.success();
    await _pumpLogin(tester, repository);
    final loginFields = find.byType(TextFormField);
    await tester.enterText(loginFields.first, '8711234567');
    await tester.enterText(loginFields.last, 'secreta');

    await _openDialog(tester);

    expect(find.text('Recuperar contraseña'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Teléfono celular'),
      ),
      findsOneWidget,
    );
    expect(find.text('ENVIAR'), findsOneWidget);
    expect(find.text('REGRESAR'), findsOneWidget);
    expect(find.byType(ModalBarrier), findsWidgets);

    await tester.tap(find.text('REGRESAR'));
    await tester.pumpAndSettle();

    expect(find.text('Recuperar contraseña'), findsNothing);
    expect(find.text('Entrar'), findsOneWidget);
    final remainingFields = find.byType(TextFormField);
    expect(
      tester.widget<TextFormField>(remainingFields.first).controller?.text,
      '(871) 123-4567',
    );
    expect(
      tester.widget<TextFormField>(remainingFields.last).controller?.text,
      'secreta',
    );
  });

  testWidgets('Back cierra sólo el modal', (tester) async {
    await _pumpLogin(tester, _FakeRecoveryRepository.success());
    await _openDialog(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Recuperar contraseña'), findsNothing);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('vacío e incompleto no llaman al repository', (tester) async {
    final repository = _FakeRecoveryRepository.success();
    await _pumpLogin(tester, repository);
    await _openDialog(tester);

    await tester.tap(find.text('ENVIAR'));
    await tester.pump();

    expect(
      find.text('Debe especificar un número de teléfono válido'),
      findsOneWidget,
    );
    expect(repository.calls, 0);

    await tester.enterText(
      find.byKey(const ValueKey('password-recovery-phone')),
      '87112',
    );
    await tester.tap(find.text('ENVIAR'));
    await tester.pump();

    expect(repository.calls, 0);
  });

  testWidgets('envía una sola vez el teléfono enmascarado y muestra loading', (
    tester,
  ) async {
    final completer = Completer<PasswordRecoveryResult>();
    final repository = _FakeRecoveryRepository((_) => completer.future);
    await _pumpLogin(tester, repository);
    await _openDialog(tester);
    await tester.enterText(
      find.byKey(const ValueKey('password-recovery-phone')),
      '8711234567',
    );

    await tester.tap(find.text('ENVIAR'));
    await tester.tap(find.text('ENVIAR'));
    await tester.pump();

    expect(repository.calls, 1);
    expect(repository.lastPhone, '(871) 123-4567');
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(const PasswordRecoverySuccess());
    await tester.pumpAndSettle();

    expect(find.text('Recuperar contraseña'), findsNothing);
    expect(
      find.text('En breve recibirá un mensaje con su clave de acceso'),
      findsOneWidget,
    );
  });

  testWidgets('error funcional conserva modal y teléfono', (tester) async {
    final repository = _FakeRecoveryRepository(
      (_) async => const PasswordRecoveryPhoneNotFound(),
    );
    await _pumpLogin(tester, repository);
    await _openDialog(tester);
    final phone = find.byKey(const ValueKey('password-recovery-phone'));
    await tester.enterText(phone, '8711234567');

    await tester.tap(find.text('ENVIAR'));
    await tester.pumpAndSettle();

    expect(find.text('Recuperar contraseña'), findsOneWidget);
    expect(
      find.text('No se ha encontrado el número de teléfono especificado'),
      findsOneWidget,
    );
    expect(
      tester.widget<TextFormField>(phone).controller?.text,
      '(871) 123-4567',
    );
  });

  testWidgets('timeout conserva datos y permite reintentar', (tester) async {
    var attempt = 0;
    final repository = _FakeRecoveryRepository((_) async {
      attempt++;
      if (attempt == 1) throw const NetworkTimeoutException();
      return const PasswordRecoverySuccess();
    });
    await _pumpLogin(tester, repository);
    await _openDialog(tester);
    final phone = find.byKey(const ValueKey('password-recovery-phone'));
    await tester.enterText(phone, '8711234567');

    await tester.tap(find.text('ENVIAR'));
    await tester.pumpAndSettle();

    expect(find.text('Recuperar contraseña'), findsOneWidget);
    expect(
      find.text('El servidor tardó demasiado en responder.'),
      findsOneWidget,
    );
    expect(
      tester.widget<TextFormField>(phone).controller?.text,
      '(871) 123-4567',
    );

    await tester.tap(find.text('ENVIAR'));
    await tester.pumpAndSettle();

    expect(repository.calls, 2);
    expect(find.text('Recuperar contraseña'), findsNothing);
  });

  testWidgets('permanece accesible en pantalla pequeña con teclado abierto', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetViewInsets);
    await _pumpLogin(tester, _FakeRecoveryRepository.success());
    await _openDialog(tester);

    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.showKeyboard(
      find.byKey(const ValueKey('password-recovery-phone')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('password-recovery-submit')).hitTestable(),
      findsOneWidget,
    );
    expect(find.text('REGRESAR').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpLogin(
  WidgetTester tester,
  PasswordRecoveryRepositoryContract recoveryRepository,
) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        passwordRecoveryRepositoryProvider.overrideWithValue(
          recoveryRepository,
        ),
      ],
      child: MaterialApp(theme: AppTheme.lightTheme, home: const LoginScreen()),
    ),
  );
}

Future<void> _openDialog(WidgetTester tester) async {
  await tester.tap(find.text('Recupérala'));
  await tester.pumpAndSettle();
}

final class _FakeRecoveryRepository
    implements PasswordRecoveryRepositoryContract {
  _FakeRecoveryRepository(this.handler);

  _FakeRecoveryRepository.success()
    : handler = ((_) async => const PasswordRecoverySuccess());

  final Future<PasswordRecoveryResult> Function(String phone) handler;
  int calls = 0;
  String? lastPhone;

  @override
  Future<PasswordRecoveryResult> recoverPassword(String telefono) {
    calls++;
    lastPhone = telefono;
    return handler(telefono);
  }
}

final class _FakeAuthRepository implements AuthRepositoryContract {
  @override
  SessionData? getSession() => null;

  @override
  Future<LoginResult> login({
    required String telefono,
    required String contrasena,
  }) async => const LoginInvalidCredentials();

  @override
  Future<void> logout() async {}
}
