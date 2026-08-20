import 'package:combugas_clientes/core/routes/session_route_guard.dart';
import 'package:combugas_clientes/features/auth/data/auth_repository.dart';
import 'package:combugas_clientes/features/auth/models/session_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('ruta privada sin sesión redirige a Productos', (tester) async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.widget('/privada'));
    await tester.pumpAndSettle();

    expect(harness.router.state.uri.path, '/productos');
    expect(find.text('PRODUCTOS'), findsOneWidget);
    expect(find.text('PRIVADA'), findsNothing);
  });

  testWidgets('Login con sesión redirige a Pedido', (tester) async {
    final harness = _Harness(authenticated: true);
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.widget('/login'));
    await tester.pumpAndSettle();

    expect(harness.router.state.uri.path, '/pedido');
    expect(find.text('PEDIDO'), findsOneWidget);
    expect(find.text('LOGIN'), findsNothing);
  });
}

final class _Harness {
  _Harness({bool authenticated = false})
    : container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _AuthRepository(authenticated),
          ),
        ],
      ),
      router = GoRouter(
        routes: [
          GoRoute(
            path: '/privada',
            builder:
                (_, _) => const SessionRouteGuard.private(
                  child: Scaffold(body: Text('PRIVADA')),
                ),
          ),
          GoRoute(
            path: '/login',
            builder:
                (_, _) => const SessionRouteGuard.publicOnly(
                  child: Scaffold(body: Text('LOGIN')),
                ),
          ),
          GoRoute(
            path: '/productos',
            builder: (_, _) => const Scaffold(body: Text('PRODUCTOS')),
          ),
          GoRoute(
            path: '/pedido',
            builder: (_, _) => const Scaffold(body: Text('PEDIDO')),
          ),
        ],
      );

  final ProviderContainer container;
  final GoRouter router;

  Widget widget(String location) {
    router.go(location);
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    );
  }

  void dispose() {
    router.dispose();
    container.dispose();
  }
}

final class _AuthRepository implements AuthRepositoryContract {
  const _AuthRepository(this.authenticated);
  final bool authenticated;

  @override
  SessionData? getSession() =>
      authenticated
          ? const SessionData(
            claveUsuario: 1,
            nombreUsuario: 'CLIENTE',
            claveTelefono: 2,
            subcanalUsuario: 1,
          )
          : null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
