import 'dart:async';

import 'package:combugas_clientes/core/theme/app_colors.dart';
import 'package:combugas_clientes/features/auth/data/auth_repository.dart';
import 'package:combugas_clientes/features/pedidos/data/pedido_repository.dart';
import 'package:combugas_clientes/features/pedidos/models/pedido_historial.dart';
import 'package:combugas_clientes/features/pedidos/screens/mis_pedidos_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'historial_test_support.dart';
import 'pedido_historial_fixture.dart';

void main() {
  testWidgets('oculta navegación inferior y la restaura al salir', (
    tester,
  ) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final container = _container(
      FakeHistorialRepository(getPedidosHandler: (_) async => const []),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MisPedidosScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      calls,
      contains(
        isA<MethodCall>()
            .having(
              (call) => call.method,
              'method',
              'SystemChrome.setEnabledSystemUIOverlays',
            )
            .having((call) => call.arguments, 'overlays', [
              'SystemUiOverlay.top',
            ]),
      ),
    );

    calls.clear();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(
      calls,
      contains(
        isA<MethodCall>()
            .having(
              (call) => call.method,
              'method',
              'SystemChrome.setEnabledSystemUIMode',
            )
            .having(
              (call) => call.arguments,
              'mode',
              'SystemUiMode.edgeToEdge',
            ),
      ),
    );
  });

  testWidgets('muestra loading y después lista respetando datos Android', (
    tester,
  ) async {
    final completer = Completer<List<PedidoHistorial>>();
    final repository = FakeHistorialRepository(
      getPedidosHandler: (_) => completer.future,
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    final router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(container, router));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete([pedidoFixture()]);
    await tester.pumpAndSettle();
    expect(find.textContaining('19/08/2026 02:35 PM'), findsOneWidget);
    expect(find.textContaining('HIDALGO'), findsOneWidget);
    expect(find.textContaining('EN CURSO'), findsOneWidget);

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.foregroundColor, AppColors.white);
    final title = tester.widget<Text>(find.text('Mis Pedidos'));
    expect(title.style, isNull);
    final refresh = appBar.actions!.whereType<IconButton>().single;
    expect(refresh.color, AppColors.white);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    for (final label in const [
      'Perfil',
      'Carburaciones',
      'Mis direcciones',
      'Mis Pedidos',
      'Cerrar sesión',
    ]) {
      expect(
        find.descendant(of: find.byType(Drawer), matching: find.text(label)),
        findsOneWidget,
      );
    }
    Navigator.of(tester.element(find.byType(Drawer))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('HIDALGO'));
    await tester.pumpAndSettle();
    expect(find.text('detalle 321'), findsOneWidget);
  });

  testWidgets('distingue vacío y error con reintento', (tester) async {
    var mode = 0;
    final repository = FakeHistorialRepository(
      getPedidosHandler: (_) async {
        if (mode == 0) return const [];
        if (mode == 1) throw Exception('offline');
        return [pedidoFixture()];
      },
    );
    var container = _container(repository);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MisPedidosScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No tienes pedidos registrados.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();

    mode = 1;
    container = _container(repository);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MisPedidosScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Reintentar'), findsOneWidget);
    mode = 2;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('HIDALGO'), findsOneWidget);
  });
}

ProviderContainer _container(FakeHistorialRepository repository) =>
    ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeHistoryAuthRepository()),
        pedidoRepositoryProvider.overrideWithValue(repository),
      ],
    );

GoRouter _router() => GoRouter(
  initialLocation: '/mis-pedidos',
  routes: [
    GoRoute(
      path: '/mis-pedidos',
      builder: (_, _) => const MisPedidosScreen(),
      routes: [
        GoRoute(
          path: ':id',
          builder:
              (_, state) =>
                  Scaffold(body: Text('detalle ${state.pathParameters['id']}')),
        ),
      ],
    ),
  ],
);

Widget _app(ProviderContainer container, GoRouter router) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    );
