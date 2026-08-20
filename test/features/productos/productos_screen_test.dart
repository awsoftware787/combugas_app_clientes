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
    expect(find.text(r'Precio: $500.00'), findsOneWidget);
    expect(find.text('30kg'), findsOneWidget);
    expect(find.text('45kg'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('product-option-3')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('product-image-3')), findsOneWidget);
    expect(find.text(r'Precio: $750.00'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
    expect(find.text('Dirección de entrega'), findsNothing);
    expect(find.text('Agregar'), findsNothing);
    expect(find.byKey(const ValueKey('quantity-plus')), findsNothing);
    expect(find.byKey(const ValueKey('quantity-minus')), findsNothing);
    expect(find.text('Carrito'), findsNothing);
    expect(find.text('Limpiar'), findsNothing);
  });

  testWidgets('Productos abre Login y Login no ofrece volver a Productos', (
    tester,
  ) async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.widget(initialLocation: '/productos'));
    await tester.pumpAndSettle();

    expect(find.text('Productos'), findsOneWidget);

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
  _Harness({bool authenticated = false})
    : container = ProviderContainer(
        overrides: [
          pedidoRepositoryProvider.overrideWithValue(_ProductsRepository()),
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
  @override
  Future<List<Producto>> getPrecios() async => const [
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

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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
