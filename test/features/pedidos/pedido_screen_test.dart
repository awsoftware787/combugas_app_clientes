import 'dart:async';

import 'package:combugas_clientes/core/theme/app_colors.dart';
import 'package:combugas_clientes/features/auth/data/auth_repository.dart';
import 'package:combugas_clientes/features/auth/models/login_result.dart';
import 'package:combugas_clientes/features/auth/models/session_data.dart';
import 'package:combugas_clientes/features/direcciones/data/direccion_repository.dart';
import 'package:combugas_clientes/features/direcciones/models/catalogos_direccion.dart';
import 'package:combugas_clientes/features/direcciones/models/direccion.dart';
import 'package:combugas_clientes/features/direcciones/models/direccion_request.dart';
import 'package:combugas_clientes/features/pedidos/controllers/carrito_controller.dart';
import 'package:combugas_clientes/features/pedidos/data/carrito_storage.dart';
import 'package:combugas_clientes/features/pedidos/data/pedido_repository.dart';
import 'package:combugas_clientes/features/pedidos/models/item_pedido.dart';
import 'package:combugas_clientes/features/pedidos/models/create_order.dart';
import 'package:combugas_clientes/features/pedidos/models/calificacion.dart';
import 'package:combugas_clientes/features/pedidos/models/pedido_historial.dart';
import 'package:combugas_clientes/features/pedidos/models/producto.dart';
import 'package:combugas_clientes/features/pedidos/screens/pedido_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra selector, producto, agrega, badge y limpia', (
    tester,
  ) async {
    final cart = _CartStore();
    final container = _container(cart: cart, directions: const [_address]);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PedidoScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dirección de entrega'), findsOneWidget);
    expect(find.text('Gas en cilindro'), findsOneWidget);
    expect(find.text('CASA'), findsWidgets);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.home)).color,
      AppColors.accent,
    );

    final clear = tester.widget<TextButton>(
      find.byKey(const ValueKey('clear-order')),
    );
    expect(clear.onPressed, isNull);
    expect(clear.style?.foregroundColor?.resolve(const {}), AppColors.accent);

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.foregroundColor, AppColors.white);
    expect(tester.widget<Text>(find.text('Pedido')).style, isNull);
    expect(
      appBar.actions!.whereType<IconButton>().single.color,
      AppColors.white,
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('product-amount')))
          .style
          ?.color,
      AppColors.accent,
    );
    for (final key in const ['quantity-minus', 'quantity-plus']) {
      final button = tester.widget<IconButton>(find.byKey(ValueKey(key)));
      expect(
        button.style?.foregroundColor?.resolve(const {}),
        AppColors.quantityButtonBlue,
      );
    }

    final add = find.text('Agregar').hitTestable();
    final addButton = tester.widget<FilledButton>(
      find.ancestor(of: add, matching: find.byType(FilledButton)),
    );
    expect(
      addButton.style?.backgroundColor?.resolve(const {}),
      AppColors.addButtonGreen,
    );
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(container.read(carritoControllerProvider).lineas, 1);
    expect(container.read(carritoControllerProvider).items.single.cantidad, 1);
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('quantity-value')).hitTestable(),
          )
          .data,
      '1',
    );

    final enabledClear = tester.widget<TextButton>(
      find.byKey(const ValueKey('clear-order')),
    );
    expect(enabledClear.onPressed, isNotNull);
    expect(
      enabledClear.style?.foregroundColor?.resolve({WidgetState.pressed}),
      AppColors.accent,
    );

    await tester.tap(find.text('Limpiar'));
    await tester.pumpAndSettle();
    expect(container.read(carritoControllerProvider).lineas, 0);
  });

  testWidgets('reinicia a uno cilindro, agua y croqueta tras agregar', (
    tester,
  ) async {
    final container = _container(
      cart: _CartStore(),
      directions: const [_address],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PedidoScreen()),
      ),
    );
    await tester.pumpAndSettle();

    for (var page = 0; page < 3; page++) {
      final plus = find.byKey(const ValueKey('quantity-plus')).hitTestable();
      await tester.ensureVisible(plus);
      for (var index = 0; index < 3; index++) {
        await tester.tap(plus);
        await tester.pump();
      }
      await tester.tap(find.text('Agregar').hitTestable());
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('quantity-value')).hitTestable(),
            )
            .data,
        '1',
      );
      if (page < 2) {
        await tester.drag(find.byType(PageView), const Offset(-500, 0));
        await tester.pumpAndSettle();
      }
    }

    final items = container.read(carritoControllerProvider).items;
    expect(items.map((item) => item.productoId), [2, 4, 20]);
    expect(items.map((item) => item.cantidad), everyElement(4));
  });

  testWidgets('Drawer conserva orden y cliente sin dirección puede agregar', (
    tester,
  ) async {
    final container = _container(cart: _CartStore(), directions: const []);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PedidoScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No tienes una dirección registrada.'), findsOneWidget);
    expect(find.text('Agregar dirección'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    final labels = [
      'Pedido',
      'Perfil',
      'Carburaciones',
      'Mis direcciones',
      'Mis Pedidos',
      'Aviso de privacidad',
      'Cerrar sesión',
    ];
    final drawer = find.byType(Drawer);
    for (final label in labels) {
      expect(
        find.descendant(of: drawer, matching: find.text(label)),
        findsOneWidget,
      );
    }
    final positions =
        labels
            .map(
              (label) =>
                  tester
                      .getTopLeft(
                        find.descendant(of: drawer, matching: find.text(label)),
                      )
                      .dy,
            )
            .toList();
    expect(positions, orderedEquals([...positions]..sort()));
    expect(find.text('VALERIA CORDERO'), findsOneWidget);
  });

  testWidgets('reserva el espacio del selector mientras carga direcciones', (
    tester,
  ) async {
    final directions = Completer<List<Direccion>>();
    final container = _container(
      cart: _CartStore(),
      directions: const [],
      directionsFuture: directions.future,
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PedidoScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    final skeleton = find.byKey(const ValueKey('direcciones-skeleton'));
    expect(skeleton, findsOneWidget);
    expect(tester.getSize(skeleton).height, 116);
    expect(find.text('Dirección de entrega'), findsOneWidget);

    directions.complete(const [_address]);
    await tester.pumpAndSettle();
    expect(skeleton, findsNothing);
    expect(find.byType(DropdownButtonFormField<Direccion>), findsOneWidget);
  });
}

ProviderContainer _container({
  required _CartStore cart,
  required List<Direccion> directions,
  Future<List<Direccion>>? directionsFuture,
}) => ProviderContainer(
  overrides: [
    authRepositoryProvider.overrideWithValue(_AuthRepository()),
    direccionRepositoryProvider.overrideWithValue(
      _DirectionRepository(directions, loadFuture: directionsFuture),
    ),
    pedidoRepositoryProvider.overrideWithValue(_PedidoRepository()),
    carritoStoreProvider.overrideWithValue(cart),
  ],
);

final class _AuthRepository implements AuthRepositoryContract {
  @override
  SessionData? getSession() => const SessionData(
    claveUsuario: 12,
    nombreUsuario: 'VALERIA CORDERO',
    claveTelefono: 2,
    subcanalUsuario: 1,
  );
  @override
  Future<LoginResult> login({
    required String telefono,
    required String contrasena,
  }) => throw UnimplementedError();
  @override
  Future<void> logout() async {}
}

final class _PedidoRepository implements PedidoRepositoryContract {
  @override
  Future<CalificacionResult> calificarServicio(CalificacionRequest request) =>
      throw UnimplementedError();
  @override
  Future<CancelarPedidoResult> cancelarPedido(int pedidoId) =>
      throw UnimplementedError();
  @override
  Future<List<PedidoHistorial>> getPedidos(int clienteId) async => const [];
  @override
  Future<PedidoSeguimientoInfo> getUnPedido(int pedidoId) =>
      throw UnimplementedError();
  @override
  Future<CreateOrderResult> createOrder(CreateOrderRequest request) =>
      throw UnimplementedError();
  @override
  Future<List<TiempoFase>> getTiempos() async => const [];
  @override
  Future<List<Producto>> getPrecios() async => const [
    Producto(
      id: 2,
      descripcion: 'CILINDRO 30 KG',
      presentacion: '30 KG',
      servicioId: 1,
      precioCentavos: 60000,
    ),
    Producto(
      id: 4,
      descripcion: 'GARRAFÓN NATURAL',
      presentacion: '20 L',
      servicioId: 3,
      precioCentavos: 5000,
    ),
    Producto(
      id: 20,
      descripcion: 'BULTO DE ADULTO 20 KG',
      presentacion: '20 KG',
      servicioId: 9,
      precioCentavos: 40000,
    ),
  ];
  @override
  Future<MontosMinimos> getMontosMinimos() async => const MontosMinimos.empty();
}

final class _CartStore implements CarritoStore {
  List<ItemPedido> items = [];
  @override
  List<ItemPedido> read() => items;
  @override
  Future<void> save(List<ItemPedido> value) async => items = [...value];
}

final class _DirectionRepository implements DireccionRepositoryContract {
  _DirectionRepository(this.directions, {this.loadFuture});
  final List<Direccion> directions;
  final Future<List<Direccion>>? loadFuture;
  Direccion? selected;
  @override
  Future<List<Direccion>> getDirecciones(int clienteId) async {
    if (loadFuture != null) return loadFuture!;
    return directions;
  }
  @override
  Direccion? getSelected() => selected;
  @override
  Future<void> saveSelected(Direccion direccion) async => selected = direccion;
  @override
  Future<void> clearSelected() async => selected = null;
  @override
  Future<Direccion> getDireccion(int direccionId) async => _address;
  @override
  Future<List<Colonia>> getColonias() async => const [];
  @override
  Future<List<Calle>> getCalles(int coloniaId) async => const [];
  @override
  Future<List<Cerrada>> getCerradas(int coloniaId) async => const [];
  @override
  Future<DireccionOperationResult> guardar(
    int clienteId,
    DireccionRequest request,
  ) => throw UnimplementedError();
  @override
  Future<DireccionOperationResult> actualizar(
    int direccionId,
    DireccionRequest request,
  ) => throw UnimplementedError();
  @override
  Future<DireccionOperationResult> desactivar(int direccionId, int clienteId) =>
      throw UnimplementedError();
}

const _address = Direccion(
  id: 9,
  descripcion: 'CASA',
  tipoCalle: 'CALLE',
  idCalle: 2,
  calle: 'HIDALGO',
  numeroInterior: '',
  numeroExterior: '123',
  idColonia: 3,
  colonia: 'CENTRO',
  idCiudad: 1,
  ciudad: 'TORREÓN',
  idEstado: 5,
  estado: 'COAHUILA',
  idZona: 0,
  zona: '',
  idCodigoPostal: 0,
  codigoPostal: '',
  referencias: '',
  activa: true,
  latitud: 25.5,
  longitud: -103.4,
  observaciones: '',
  entreCalle1: '',
  entreCalle2: '',
  entreCalle3: '',
  idSegmento: 1,
  cerrada: '',
  requiereClave: false,
  clave: '',
  idRuta: 0,
  tienePedido: false,
);
