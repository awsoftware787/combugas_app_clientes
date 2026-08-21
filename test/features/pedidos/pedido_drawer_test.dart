import 'package:combugas_clientes/core/services/app_version_service.dart';
import 'package:combugas_clientes/core/theme/app_colors.dart';
import 'package:combugas_clientes/features/auth/data/auth_repository.dart';
import 'package:combugas_clientes/features/auth/models/session_data.dart';
import 'package:combugas_clientes/features/pedidos/widgets/pedido_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'historial_test_support.dart';

void main() {
  testWidgets(
    'menú público muestra solo opciones públicas y conserva regreso',
    (tester) async {
      final container = _container(() async => true, authenticated: false);
      addTearDown(container.dispose);
      final router = _router(initialLocation: '/productos');
      addTearDown(router.dispose);
      await tester.pumpWidget(_app(container, router));
      await tester.pumpAndSettle();

      await _openDrawer(tester);
      expect(
        tester.widget<Drawer>(find.byType(Drawer)).backgroundColor,
        AppColors.menuBackground,
      );
      expect(_drawerText('Carburaciones'), findsOneWidget);
      expect(_drawerText('Aviso de privacidad'), findsOneWidget);
      expect(_drawerText('Iniciar sesión'), findsOneWidget);
      expect(_drawerText('v1.0.0'), findsOneWidget);
      expect(
        tester.widget<Text>(_drawerText('Carburaciones')).style?.color,
        AppColors.white,
      );
      expect(
        tester.widget<Text>(_drawerText('Aviso de privacidad')).style?.color,
        AppColors.white,
      );
      expect(
        tester
            .widget<Icon>(
              find.descendant(
                of: find.byType(Drawer),
                matching: find.byIcon(Icons.local_gas_station),
              ),
            )
            .color,
        AppColors.white,
      );
      expect(
        tester
            .widget<Icon>(
              find.descendant(
                of: find.byType(Drawer),
                matching: find.byIcon(Icons.privacy_tip_outlined),
              ),
            )
            .color,
        AppColors.white,
      );
      expect(_drawerText('Pedido'), findsNothing);
      expect(_drawerText('Perfil'), findsNothing);
      expect(_drawerText('Mis direcciones'), findsNothing);
      expect(_drawerText('Mis pedidos'), findsNothing);
      expect(_drawerText('Cerrar sesión'), findsNothing);

      await tester.tap(_drawerText('Carburaciones'));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/carburaciones');
      expect(router.canPop(), isTrue);

      router.pop();
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/productos');

      await _openDrawer(tester);
      await tester.tap(_drawerText('Iniciar sesión'));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/login');
    },
  );

  testWidgets('aviso público cierra drawer y conserva Productos', (
    tester,
  ) async {
    var calls = 0;
    final container = _container(() async {
      calls++;
      return true;
    }, authenticated: false);
    addTearDown(container.dispose);
    final router = _router(initialLocation: '/productos');
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(container, router));
    await tester.pumpAndSettle();

    await _openDrawer(tester);
    await tester.tap(_drawerText('Aviso de privacidad'));
    await tester.pumpAndSettle();

    expect(calls, 1);
    expect(find.byType(Drawer), findsNothing);
    expect(router.state.uri.path, '/productos');
  });

  for (final screenSize in const [Size(320, 640), Size(430, 932)]) {
    testWidgets('drawer ocupa el 60 por ciento en pantalla $screenSize', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = screenSize;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final container = _container(() async => true);
      addTearDown(container.dispose);
      final router = _router();
      addTearDown(router.dispose);
      await tester.pumpWidget(_app(container, router));
      await tester.pumpAndSettle();

      await _openDrawer(tester);

      expect(
        tester.getSize(find.byType(Drawer)).width,
        screenSize.width * 0.60,
      );
      expect(_drawerText('Mis direcciones'), findsOneWidget);
      expect(_drawerText('Aviso de privacidad'), findsOneWidget);
    });
  }

  testWidgets('menú autenticado respeta orden, separadores y logout inferior', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final container = _container(() async => true);
    addTearDown(container.dispose);
    final router = _router(initialLocation: '/pedido');
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(container, router));
    await tester.pumpAndSettle();

    await _openDrawer(tester);

    final labels = [
      'Pedido',
      'Mis pedidos',
      'Mis direcciones',
      'Perfil',
      'Carburaciones',
      'Aviso de privacidad',
      'Cerrar sesión',
    ];
    final positions =
        labels
            .map((label) => tester.getTopLeft(_drawerText(label)).dy)
            .toList();
    expect(positions, orderedEquals([...positions]..sort()));
    expect(
      find.descendant(of: find.byType(Drawer), matching: find.byType(Divider)),
      findsNWidgets(2),
    );
    final avatar = tester.widget<Image>(
      find.descendant(of: find.byType(Drawer), matching: find.byType(Image)),
    );
    expect(avatar.width, 92);
    expect(avatar.height, 92);
    expect(
      tester.getBottomRight(_drawerText('Cerrar sesión')).dy,
      greaterThan(tester.getBottomRight(_drawerText('Aviso de privacidad')).dy),
    );
    expect(_drawerText('v1.0.0'), findsOneWidget);
    expect(
      tester.getTopLeft(_drawerText('v1.0.0')).dy,
      lessThan(tester.getTopLeft(_drawerText('Cerrar sesión')).dy),
    );
    expect(tester.takeException(), isNull);
  });

  for (final entry
      in const {
        '/pedido': 'Pedido',
        '/mis-pedidos': 'Mis pedidos',
        '/direcciones': 'Mis direcciones',
        '/perfil': 'Perfil',
        '/carburaciones': 'Carburaciones',
      }.entries) {
    testWidgets('${entry.value} aparece como opción activa', (tester) async {
      final container = _container(() async => true);
      addTearDown(container.dispose);
      final router = _router(initialLocation: entry.key);
      addTearDown(router.dispose);
      await tester.pumpWidget(_app(container, router));
      await tester.pumpAndSettle();

      await _openDrawer(tester);

      final text = tester.widget<Text>(_drawerText(entry.value));
      final decoration = _drawerItemDecoration(tester, entry.value);
      final border = decoration.border! as Border;
      expect(text.style?.fontWeight, FontWeight.w700);
      expect(decoration.color, AppColors.white.withValues(alpha: 0.09));
      expect(border.left.color, AppColors.primary);
      expect(border.left.width, 4);
    });
  }

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

  testWidgets('secciones principales usan go y logout limpia el stack', (
    tester,
  ) async {
    final container = _container(() async => true);
    addTearDown(container.dispose);
    final router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(container, router));
    await tester.pumpAndSettle();

    await _openDrawer(tester);
    await tester.tap(_drawerText('Perfil'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/perfil');
    expect(router.canPop(), isFalse);

    await _openDrawer(tester);
    await tester.ensureVisible(_drawerText('Cerrar sesión'));
    await tester.tap(_drawerText('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/productos');
    expect(router.canPop(), isFalse);
  });
}

ProviderContainer _container(
  Future<bool> Function() launcher, {
  bool authenticated = true,
}) => ProviderContainer(
  overrides: [
    authRepositoryProvider.overrideWithValue(
      authenticated
          ? FakeHistoryAuthRepository()
          : const _PublicAuthRepository(),
    ),
    privacyNoticeLauncherProvider.overrideWithValue(launcher),
    appVersionProvider.overrideWithValue(Future.value('v1.0.0')),
  ],
);

GoRouter _router({String initialLocation = '/origen'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: '/origen',
      builder: (_, _) => const _DrawerPage(label: 'ORIGEN'),
    ),
    GoRoute(
      path: '/pedido',
      builder: (_, _) => const _DrawerPage(label: 'PANTALLA PEDIDO'),
    ),
    GoRoute(
      path: '/perfil',
      builder: (_, _) => const _DrawerPage(label: 'PANTALLA PERFIL'),
    ),
    GoRoute(
      path: '/productos',
      builder: (_, _) => const _DrawerPage(label: 'PRODUCTOS'),
    ),
    GoRoute(
      path: '/login',
      builder: (_, _) => const Scaffold(body: Text('LOGIN')),
    ),
    for (final route in const [
      '/carburaciones',
      '/direcciones',
      '/mis-pedidos',
    ])
      GoRoute(path: route, builder: (_, _) => _DrawerPage(label: route)),
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

BoxDecoration _drawerItemDecoration(WidgetTester tester, String label) {
  final container =
      find
          .ancestor(of: _drawerText(label), matching: find.byType(Container))
          .first;
  return tester.widget<Container>(container).decoration! as BoxDecoration;
}

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

final class _PublicAuthRepository implements AuthRepositoryContract {
  const _PublicAuthRepository();

  @override
  SessionData? getSession() => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
