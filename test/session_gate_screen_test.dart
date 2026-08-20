import 'package:combugas_clientes/core/startup/session_gate_screen.dart';
import 'package:combugas_clientes/core/startup/startup_splash_screen.dart';
import 'package:combugas_clientes/features/auth/data/auth_repository.dart';
import 'package:combugas_clientes/features/auth/models/session_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('sin sesión abre Productos sin mostrar Login', (tester) async {
    final router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router, const _AuthRepository()));
    expect(find.byType(StartupSplashScreen), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('PRODUCTOS INVITADO'), findsOneWidget);
    expect(find.text('LOGIN'), findsNothing);
    expect(router.state.uri.path, '/productos');
  });

  testWidgets('con sesión conserva Pedido como destino inicial', (
    tester,
  ) async {
    final router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      _app(
        router,
        const _AuthRepository(
          session: SessionData(
            claveUsuario: 12,
            nombreUsuario: 'CLIENTE',
            claveTelefono: 2,
            subcanalUsuario: 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PEDIDO AUTENTICADO'), findsOneWidget);
    expect(find.text('PRODUCTOS INVITADO'), findsNothing);
    expect(router.state.uri.path, '/pedido');
  });
}

GoRouter _router() => GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, _) => const SessionGateScreen()),
    GoRoute(
      path: '/productos',
      builder: (_, _) => const Scaffold(body: Text('PRODUCTOS INVITADO')),
    ),
    GoRoute(
      path: '/pedido',
      builder: (_, _) => const Scaffold(body: Text('PEDIDO AUTENTICADO')),
    ),
    GoRoute(
      path: '/login',
      builder: (_, _) => const Scaffold(body: Text('LOGIN')),
    ),
  ],
);

Widget _app(GoRouter router, AuthRepositoryContract repository) =>
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(routerConfig: router),
    );

final class _AuthRepository implements AuthRepositoryContract {
  const _AuthRepository({this.session});
  final SessionData? session;

  @override
  SessionData? getSession() => session;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
