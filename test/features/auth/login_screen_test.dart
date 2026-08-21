import 'package:combugas_clientes/core/services/app_version_service.dart';
import 'package:combugas_clientes/features/auth/data/auth_repository.dart';
import 'package:combugas_clientes/features/auth/models/login_result.dart';
import 'package:combugas_clientes/features/auth/models/session_data.dart';
import 'package:combugas_clientes/features/auth/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('valida teléfono y contraseña vacíos sin llamar al servidor', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          appVersionProvider.overrideWithValue(Future.value('v1.0.0')),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Debe especificar un teléfono válido'), findsOneWidget);
    expect(find.text('La contraseña no es válida'), findsOneWidget);
    expect(find.text('Ver productos'), findsNothing);
    expect(find.text('Productos'), findsNothing);
    expect(find.byKey(const ValueKey('view-public-products')), findsNothing);
    expect(repository.loginCalls, 0);
  });

  testWidgets('login correcto abre Pedido aunque todavía no tenga dirección', (
    tester,
  ) async {
    const session = SessionData(
      claveUsuario: 12,
      nombreUsuario: 'CLIENTE',
      claveTelefono: 34,
      subcanalUsuario: 7,
    );
    final repository = _FakeAuthRepository(
      result: const LoginSuccess(session: session, hasAddress: false),
    );
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/pedido', builder: (_, __) => const Text('PEDIDO')),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          appVersionProvider.overrideWithValue(Future.value('v1.0.0')),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, '8711234567');
    await tester.enterText(find.byType(TextFormField).last, 'clave');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(repository.loginCalls, 1);
    expect(find.text('PEDIDO'), findsOneWidget);
  });

  testWidgets('muestra la versión abajo a la derecha sin mover el formulario', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final repository = _FakeAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          appVersionProvider.overrideWithValue(Future.value('v1.0.0')),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final versionRect = tester.getRect(find.text('v1.0.0'));
    expect(360 - versionRect.right, closeTo(16, 1));
    expect(640 - versionRect.bottom, closeTo(10, 1));
    expect(tester.getCenter(find.byType(Form)).dx, closeTo(180, 1));
    expect(tester.takeException(), isNull);
  });
}

final class _FakeAuthRepository implements AuthRepositoryContract {
  _FakeAuthRepository({this.result = const LoginInvalidCredentials()});

  final LoginResult result;
  int loginCalls = 0;

  @override
  SessionData? getSession() => null;

  @override
  Future<LoginResult> login({
    required String telefono,
    required String contrasena,
  }) async {
    loginCalls++;
    return result;
  }

  @override
  Future<void> logout() async {}
}
