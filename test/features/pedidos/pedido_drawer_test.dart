import 'package:combugas_clientes/features/auth/data/auth_repository.dart';
import 'package:combugas_clientes/features/pedidos/widgets/pedido_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'historial_test_support.dart';

void main() {
  testWidgets('Pedido navega a la ruta principal sin duplicarla', (
    tester,
  ) async {
    final container = _container(() async => true);
    addTearDown(container.dispose);
    final router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(container, router));
    await tester.pumpAndSettle();

    await _openDrawer(tester);
    await tester.tap(_drawerText('Pedido'));
    await tester.pumpAndSettle();
    expect(find.text('PANTALLA PEDIDO'), findsNWidgets(2));
    expect(router.routerDelegate.currentConfiguration.uri.path, '/pedido');

    await _openDrawer(tester);
    await tester.tap(_drawerText('Pedido'));
    await tester.pumpAndSettle();
    expect(find.text('PANTALLA PEDIDO'), findsNWidgets(2));
    expect(router.routerDelegate.currentConfiguration.uri.path, '/pedido');
  });

  testWidgets('Aviso abre el launcher y conserva la ruta', (tester) async {
    var calls = 0;
    final container = _container(() async {
      calls++;
      return true;
    });
    addTearDown(container.dispose);
    final router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(container, router));
    await tester.pumpAndSettle();

    await _openDrawer(tester);
    await tester.ensureVisible(_drawerText('Aviso de privacidad'));
    await tester.tap(_drawerText('Aviso de privacidad'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/origen');
  });

  testWidgets('muestra error si el aviso no puede abrirse', (tester) async {
    final container = _container(() async => false);
    addTearDown(container.dispose);
    final router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(container, router));
    await tester.pumpAndSettle();

    await _openDrawer(tester);
    await tester.ensureVisible(_drawerText('Aviso de privacidad'));
    await tester.tap(_drawerText('Aviso de privacidad'));
    await tester.pumpAndSettle();
    expect(find.text('No fue posible abrir el aviso.'), findsOneWidget);
  });
}

ProviderContainer _container(Future<bool> Function() launcher) =>
    ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeHistoryAuthRepository()),
        privacyNoticeLauncherProvider.overrideWithValue(launcher),
      ],
    );

GoRouter _router() => GoRouter(
  initialLocation: '/origen',
  routes: [
    GoRoute(
      path: '/origen',
      builder: (_, _) => const _DrawerPage(label: 'ORIGEN'),
    ),
    GoRoute(
      path: '/pedido',
      builder: (_, _) => const _DrawerPage(label: 'PANTALLA PEDIDO'),
    ),
  ],
);

Widget _app(ProviderContainer container, GoRouter router) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    );

Future<void> _openDrawer(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
}

Finder _drawerText(String label) =>
    find.descendant(of: find.byType(Drawer), matching: find.text(label));

class _DrawerPage extends StatelessWidget {
  const _DrawerPage({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(label)),
    drawer: const PedidoDrawer(),
    body: Center(child: Text(label)),
  );
}
