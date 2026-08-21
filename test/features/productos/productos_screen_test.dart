import 'package:combugas_clientes/core/theme/app_colors.dart';
import 'package:combugas_clientes/features/auth/data/auth_repository.dart';
import 'package:combugas_clientes/features/auth/models/session_data.dart';
import 'package:combugas_clientes/features/auth/screens/login_screen.dart';
import 'package:combugas_clientes/features/pedidos/data/pedido_repository.dart';
import 'package:combugas_clientes/features/pedidos/models/producto.dart';
import 'package:combugas_clientes/features/productos/screens/productos_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('catálogo público muestra productos sin controles de pedido', (
    tester,
  ) async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.widget(initialLocation: '/productos'));
    await tester.pumpAndSettle();

    expect(find.text('Productos'), findsOneWidget);
    expect(find.byKey(const ValueKey('product-image-2')), findsOneWidget);
    expect(find.text('Precio'), findsOneWidget);
    expect(find.text(r'$500.00'), findsOneWidget);
    expect(find.text('30kg'), findsOneWidget);
    expect(find.text('45kg'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('product-option-3')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('product-image-3')), findsOneWidget);
    expect(find.text(r'$750.00'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('1 / 1'), findsOneWidget);
    expect(find.text('Seguro'), findsOneWidget);
    expect(find.text('Confiable'), findsOneWidget);
    expect(find.text('Atención'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
    final continueButton = find.byKey(
      const ValueKey('public-products-continue'),
    );
    expect(tester.getSize(continueButton).height, 54);
    expect(
      tester
          .widget<FilledButton>(continueButton)
          .style
          ?.backgroundColor
          ?.resolve(const {}),
      AppColors.accent,
    );
    expect(find.byIcon(Icons.favorite), findsNothing);
    expect(find.byIcon(Icons.favorite_border), findsNothing);
    expect(find.text('Dirección de entrega'), findsNothing);
    expect(find.text('Agregar'), findsNothing);
    expect(find.byKey(const ValueKey('quantity-plus')), findsNothing);
    expect(find.byKey(const ValueKey('quantity-minus')), findsNothing);
    expect(find.text('Carrito'), findsNothing);
    expect(find.text('Limpiar'), findsNothing);
    expect(find.byTooltip('Actualizar productos'), findsNothing);
  });

  testWidgets('recorre los ocho grupos sin overflow en teléfono pequeño', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final harness = _Harness(products: _allProducts);
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.widget(initialLocation: '/productos'));
    await tester.pumpAndSettle();

    const expectedProductIds = [2, 9, 4, 7, 8, 14, 20, 30];
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('1 / 8'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, 500));
    await tester.pumpAndSettle();
    for (var index = 0; index < expectedProductIds.length; index++) {
      expect(
        find.byKey(ValueKey('product-image-${expectedProductIds[index]}')),
        findsOneWidget,
      );
      if (index == 6) {
        expect(find.byKey(const ValueKey('product-option-22')), findsOneWidget);
        expect(find.byKey(const ValueKey('product-option-23')), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      if (index < expectedProductIds.length - 1) {
        await tester.tap(find.byTooltip('Producto siguiente'));
        await tester.pumpAndSettle();
      }
    }

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('8 / 8'), findsOneWidget);
  });

  for (final screenSize in const [Size(390, 844), Size(430, 932)]) {
    testWidgets('diseño responsive sin overflow en $screenSize', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = screenSize;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final harness = _Harness(products: _allProducts);
      addTearDown(harness.dispose);
      await tester.pumpWidget(harness.widget(initialLocation: '/productos'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('product-image-2')), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -700));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('public-products-continue')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Productos abre Login y Login no ofrece volver a Productos', (
    tester,
  ) async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.widget(initialLocation: '/productos'));
    await tester.pumpAndSettle();

    expect(find.text('Productos'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('public-products-continue')));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Ver productos'), findsNothing);
    expect(find.byKey(const ValueKey('view-public-products')), findsNothing);
  });

  testWidgets('usuario autenticado en /productos es redirigido a Pedido', (
    tester,
  ) async {
    final harness = _Harness(authenticated: true);
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.widget(initialLocation: '/productos'));
    await tester.pumpAndSettle();

    expect(find.text('PEDIDO AUTENTICADO'), findsOneWidget);
    expect(harness.router.state.uri.path, '/pedido');
  });
}

final class _Harness {
  _Harness({bool authenticated = false, List<Producto> products = _products})
    : container = ProviderContainer(
        overrides: [
          pedidoRepositoryProvider.overrideWithValue(
            _ProductsRepository(products),
          ),
          authRepositoryProvider.overrideWithValue(
            _AuthRepository(authenticated: authenticated),
          ),
        ],
      ),
      router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
          GoRoute(
            path: '/productos',
            builder: (_, _) => const ProductosRouteScreen(),
          ),
          GoRoute(
            path: '/pedido',
            builder: (_, _) => const Scaffold(body: Text('PEDIDO AUTENTICADO')),
          ),
          GoRoute(
            path: '/registro',
            builder: (_, _) => const Scaffold(body: Text('REGISTRO')),
          ),
          GoRoute(
            path: '/recuperar',
            builder: (_, _) => const Scaffold(body: Text('RECUPERAR')),
          ),
        ],
      );

  final ProviderContainer container;
  final GoRouter router;

  Widget widget({String initialLocation = '/login'}) {
    router.go(initialLocation);
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

final class _ProductsRepository implements PedidoRepositoryContract {
  const _ProductsRepository(this.products);

  final List<Producto> products;

  @override
  Future<List<Producto>> getPrecios() async => products;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _products = [
  Producto(
    id: ProductoIds.cilindro30,
    descripcion: 'CILINDRO 30 KG',
    presentacion: '30 KG',
    servicioId: ServicioIds.gas,
    precioCentavos: 50000,
  ),
  Producto(
    id: ProductoIds.cilindro45,
    descripcion: 'CILINDRO 45 KG',
    presentacion: '45 KG',
    servicioId: ServicioIds.gas,
    precioCentavos: 75000,
  ),
];

const _allProducts = [
  ..._products,
  Producto(
    id: ProductoIds.estacionario,
    descripcion: 'GAS ESTACIONARIO',
    presentacion: 'LITRO',
    servicioId: ServicioIds.gas,
    precioCentavos: 1150,
  ),
  Producto(
    id: ProductoIds.garrafonNatural,
    descripcion: 'GARRAFÓN DE AGUA NATURAL',
    presentacion: '20 L',
    servicioId: ServicioIds.agua,
    precioCentavos: 4500,
  ),
  Producto(
    id: ProductoIds.garrafonAlcalino,
    descripcion: 'GARRAFÓN DE AGUA ALKALINA',
    presentacion: '20 L',
    servicioId: ServicioIds.agua,
    precioCentavos: 5500,
  ),
  Producto(
    id: ProductoIds.sixNatural,
    descripcion: 'SIX DE AGUA NATURAL',
    presentacion: 'SIX',
    servicioId: ServicioIds.agua,
    precioCentavos: 6000,
  ),
  Producto(
    id: ProductoIds.sixAlcalino,
    descripcion: 'SIX DE AGUA ALKALINA',
    presentacion: 'SIX',
    servicioId: ServicioIds.agua,
    precioCentavos: 7000,
  ),
  Producto(
    id: 20,
    descripcion: 'BULTO DE ADULTO 20 KG',
    presentacion: '20 KG',
    servicioId: ServicioIds.croquetas,
    precioCentavos: 40000,
  ),
  Producto(
    id: 22,
    descripcion: 'BULTO DE CACHORRO 20 KG',
    presentacion: '20 KG',
    servicioId: ServicioIds.croquetas,
    precioCentavos: 42000,
  ),
  Producto(
    id: 23,
    descripcion: 'BULTO DE ADULTO RAZA PEQUEÑA 10 KG',
    presentacion: '10 KG',
    servicioId: ServicioIds.croquetas,
    precioCentavos: 38000,
  ),
  Producto(
    id: 30,
    descripcion: 'BOLSA DE ADULTO 4 KG',
    presentacion: '4 KG',
    servicioId: ServicioIds.croquetas,
    precioCentavos: 12000,
  ),
];

final class _AuthRepository implements AuthRepositoryContract {
  _AuthRepository({required this.authenticated});
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
