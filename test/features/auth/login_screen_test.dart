import 'package:combugas_clientes/features/auth/data/auth_repository.dart';
import 'package:combugas_clientes/features/auth/models/login_result.dart';
import 'package:combugas_clientes/features/auth/models/session_data.dart';
import 'package:combugas_clientes/features/auth/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('valida teléfono y contraseña vacíos sin llamar al servidor', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Debe especificar un teléfono válido'), findsOneWidget);
    expect(find.text('La contraseña no es válida'), findsOneWidget);
    expect(repository.loginCalls, 0);
  });
}

final class _FakeAuthRepository implements AuthRepositoryContract {
  int loginCalls = 0;

  @override
  SessionData? getSession() => null;

  @override
  Future<LoginResult> login({
    required String telefono,
    required String contrasena,
  }) async {
    loginCalls++;
    return const LoginInvalidCredentials();
  }

  @override
  Future<void> logout() async {}
}
