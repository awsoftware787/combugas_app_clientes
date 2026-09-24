import 'dart:async';

import 'package:combugas_clientes/core/constants/app_assets.dart';
import 'package:combugas_clientes/core/theme/app_colors.dart';
import 'package:combugas_clientes/features/auth/data/auth_repository.dart';
import 'package:combugas_clientes/features/auth/models/session_data.dart';
import 'package:combugas_clientes/features/direcciones/controllers/direccion_controller.dart';
import 'package:combugas_clientes/features/direcciones/data/direccion_repository.dart';
import 'package:combugas_clientes/features/direcciones/models/direccion.dart';
import 'package:combugas_clientes/features/pedidos/controllers/carrito_controller.dart';
import 'package:combugas_clientes/features/pedidos/data/carrito_storage.dart';
import 'package:combugas_clientes/features/pedidos/data/pedido_repository.dart';
import 'package:combugas_clientes/features/pedidos/models/create_order.dart';
import 'package:combugas_clientes/features/pedidos/models/item_pedido.dart';
import 'package:combugas_clientes/features/pedidos/models/producto.dart';
import 'package:combugas_clientes/features/pedidos/screens/carrito_screen.dart';
import 'package:combugas_clientes/features/pedidos/screens/confirmacion_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'bloquea confirmar hasta actualizar precios y persistir el recálculo',
    (tester) async {
      final repository = _PedidoRepository();
      final prices = Completer<List<Producto>>();
      repository.prices = prices.future;
      final store = _CartStore();
      final saved = Completer<void>();
      store.pendingSave = saved.future;
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_AuthRepository()),
          direccionRepositoryProvider.overrideWithValue(_DirectionRepository()),
          pedidoRepositoryProvider.overrideWithValue(repository),
          carritoStoreProvider.overrideWithValue(store),
        ],
      );
      addTearDown(container.dispose);
      await container.read(direccionControllerProvider.notifier).load();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ConfirmacionScreen()),
        ),
      );
      final button = find.byKey(const ValueKey('confirm-order'));
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      prices.complete(const [
        Producto(
          id: 2,
          descripcion: 'CILINDRO 30 KG',
          presentacion: '30 KG',
          servicioId: 1,
          precioCentavos: 65000,
        ),
      ]);
      await tester.pump();
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      saved.complete();
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
      expect(container.read(carritoControllerProvider).totalCentavos, 130000);
      expect(store.items.single.cantidad, 2);
      expect(store.items.single.importeCentavos, 130000);
    },
  );

  testWidgets('consulta fallida conserva carrito y permite reintentar', (
    tester,
  ) async {
    final repository = _PedidoRepository();
    final prices = Completer<List<Producto>>();
    repository.prices = prices.future;
    final store = _CartStore();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_AuthRepository()),
        direccionRepositoryProvider.overrideWithValue(_DirectionRepository()),
        pedidoRepositoryProvider.overrideWithValue(repository),
        carritoStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(container.dispose);
    await container.read(direccionControllerProvider.notifier).load();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ConfirmacionScreen()),
      ),
    );
    prices.completeError(StateError('sin conexión'));
    await tester.pumpAndSettle();
    final button = find.byKey(const ValueKey('confirm-order'));
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    expect(store.items, [_item]);
    repository.prices = null;
    await tester.scrollUntilVisible(find.text('Reintentar'), 300);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
  });
  testWidgets(
    'muestra dirección, producto con icono, total, pago y confirmar',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_AuthRepository()),
          direccionRepositoryProvider.overrideWithValue(_DirectionRepository()),
          pedidoRepositoryProvider.overrideWithValue(_PedidoRepository()),
          carritoStoreProvider.overrideWithValue(_CartStore()),
        ],
      );
      addTearDown(container.dispose);
      await container.read(direccionControllerProvider.notifier).load();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ConfirmacionScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CASA'), findsOneWidget);
      expect(find.textContaining('HIDALGO'), findsOneWidget);
      expect(find.text('CILINDRO 30 KG'), findsOneWidget);
      final image = tester.widget<Image>(
        find.byKey(const ValueKey('producto-2-imagen')),
      );
      expect((image.image as AssetImage).assetName, AppAssets.productFallback);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('cart-item-quantity-0')))
            .data,
        '2',
      );
      expect(find.byKey(const ValueKey('cart-item-minus-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('cart-item-plus-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('cart-item-delete-0')), findsOneWidget);
      expect(find.text(r'$1,200.00'), findsNothing);
      expect(find.text(r'$1200.00'), findsNWidgets(2));
      await tester.drag(find.byType(ListView), const Offset(0, -900));
      await tester.pumpAndSettle();
      expect(find.text('Efectivo'), findsOneWidget);
      expect(find.text('Tarjeta'), findsOneWidget);
      final confirmButton = find.byKey(const ValueKey('confirm-order'));
      expect(confirmButton, findsOneWidget);
      expect(
        tester.getBottomRight(confirmButton).dy,
        lessThanOrEqualTo(tester.view.physicalSize.height),
      );
      final confirm = tester.widget<FilledButton>(confirmButton);
      expect(
        confirm.style?.backgroundColor?.resolve(const {}),
        AppColors.addButtonGreen,
      );
      final clear = tester.widget<OutlinedButton>(
        find.byKey(const ValueKey('clear-confirmation')),
      );
      expect(find.byKey(const ValueKey('active-order-warning')), findsNothing);
      expect(clear.style?.foregroundColor?.resolve(const {}), AppColors.accent);
      expect(clear.style?.side?.resolve(const {})?.color, AppColors.accent);

      final accessButton = find.byKey(const ValueKey('access-key-button'));
      final access = tester.widget<OutlinedButton>(accessButton);
      expect(
        access.style?.foregroundColor?.resolve(const {}),
        AppColors.accessKeyBlue,
      );
      expect(
        access.style?.side?.resolve(const {})?.color,
        AppColors.accessKeyBlue,
      );
      await tester.tap(accessButton);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(accessButton);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('access-key-field')),
        'PORTÓN 3',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();
      expect(find.text('Clave de acceso: PORTÓN 3'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(accessButton);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('access-key-field')),
        '',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();
      expect(find.text('Clave de acceso'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('pedido activo reemplaza las acciones por aviso compacto', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_AuthRepository()),
        direccionRepositoryProvider.overrideWithValue(
          _DirectionRepository(address: _activeOrderAddress),
        ),
        pedidoRepositoryProvider.overrideWithValue(_PedidoRepository()),
        carritoStoreProvider.overrideWithValue(_CartStore()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(direccionControllerProvider.notifier).load();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ConfirmacionScreen()),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('clear-confirmation')), findsNothing);
    expect(find.byKey(const ValueKey('confirm-order')), findsNothing);
    expect(find.byKey(const ValueKey('confirmation-message')), findsNothing);
    final warningFinder = find.byKey(const ValueKey('active-order-warning'));
    expect(warningFinder, findsOneWidget);
    expect(
      find.descendant(
        of: warningFinder,
        matching: find.text('Ya existe un pedido activo para esta dirección.'),
      ),
      findsOneWidget,
    );

    final warning = tester.widget<Container>(warningFinder);
    final decoration = warning.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.primary);
    expect(decoration.borderRadius, BorderRadius.circular(12));
    final warningText = tester.widget<Text>(
      find.descendant(of: warningFinder, matching: find.byType(Text)),
    );
    expect(warningText.style?.color, AppColors.accent);
    expect(warningText.style?.fontWeight, FontWeight.w600);
    expect(tester.getSize(warningFinder).height, lessThan(60));
  });

  testWidgets('sincroniza cantidades con Carrito y permite quitar productos', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = _CartStore();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_AuthRepository()),
        direccionRepositoryProvider.overrideWithValue(_DirectionRepository()),
        pedidoRepositoryProvider.overrideWithValue(_PedidoRepository()),
        carritoStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(container.dispose);
    await container.read(direccionControllerProvider.notifier).load();

    Future<void> show(Widget screen) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: screen),
        ),
      );
      await tester.pumpAndSettle();
    }

    await show(const ConfirmacionScreen());
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('cart-item-plus-0')));
    await tester.pumpAndSettle();
    expect(container.read(carritoControllerProvider).items.single.cantidad, 3);
    expect(container.read(carritoControllerProvider).totalCentavos, 180000);

    await show(const CarritoScreen());
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('cart-item-quantity-0')))
          .data,
      '3',
    );
    await tester.tap(find.byKey(const ValueKey('cart-item-minus-0')));
    await tester.pumpAndSettle();
    expect(container.read(carritoControllerProvider).items.single.cantidad, 2);

    await show(const ConfirmacionScreen());
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('cart-item-quantity-0')))
          .data,
      '2',
    );
    await tester.tap(find.byKey(const ValueKey('cart-item-minus-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cart-item-minus-0')));
    await tester.pumpAndSettle();
    expect(find.text('Quitar producto'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'No'));
    await tester.pumpAndSettle();
    expect(container.read(carritoControllerProvider).items.single.cantidad, 1);

    await tester.tap(find.byKey(const ValueKey('cart-item-delete-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sí, quitar'));
    await tester.pumpAndSettle();
    expect(container.read(carritoControllerProvider).items, isEmpty);
    expect(find.text('Tu carrito está vacío.'), findsOneWidget);
    expect(find.text(r'$600.00'), findsNothing);
  });
}

final class _PedidoRepository implements PedidoRepositoryContract {
  Future<List<Producto>>? prices;
  @override
  Future<List<Producto>> getPrecios() async =>
      prices ??
      Future.value(const [
        Producto(
          id: 2,
          descripcion: 'CILINDRO 30 KG',
          presentacion: '30 KG',
          servicioId: 1,
          precioCentavos: 60000,
        ),
      ]);
  @override
  Future<List<TiempoFase>> getTiempos() async => const [
    TiempoFase(id: 2, tiempo: '45', unidad: 'Minutos'),
  ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _AuthRepository implements AuthRepositoryContract {
  @override
  SessionData? getSession() => const SessionData(
    claveUsuario: 12,
    nombreUsuario: 'CLIENTE',
    claveTelefono: 2,
    subcanalUsuario: 1,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _DirectionRepository implements DireccionRepositoryContract {
  const _DirectionRepository({this.address = _address});

  final Direccion address;

  @override
  Future<List<Direccion>> getDirecciones(int clienteId) async => [address];
  @override
  Direccion? getSelected() => address;
  @override
  Future<void> saveSelected(Direccion direccion) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _CartStore implements CarritoStore {
  Future<void>? pendingSave;
  List<ItemPedido> items = [_item];

  @override
  List<ItemPedido> read() => items;
  @override
  Future<void> save(List<ItemPedido> value) async {
    await pendingSave;
    items = [...value];
  }
}

final _item = ItemPedido(
  productoId: 2,
  descripcion: 'CILINDRO 30 KG',
  cantidad: 2,
  importeCentavos: 120000,
  fecha: DateTime(2026),
  servicioId: 1,
  presentacion: '30 KG',
);

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

const _activeOrderAddress = Direccion(
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
  tienePedido: true,
);
