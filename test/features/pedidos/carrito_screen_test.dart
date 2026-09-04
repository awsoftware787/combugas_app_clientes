import 'package:combugas_clientes/core/constants/app_assets.dart';
import 'package:combugas_clientes/core/theme/app_colors.dart';
import 'package:combugas_clientes/features/pedidos/controllers/carrito_controller.dart';
import 'package:combugas_clientes/features/pedidos/data/carrito_storage.dart';
import 'package:combugas_clientes/features/pedidos/models/item_pedido.dart';
import 'package:combugas_clientes/features/pedidos/screens/carrito_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('cada fila muestra la imagen correcta además del texto', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(
      overrides: [
        carritoStoreProvider.overrideWithValue(_Store([_item])),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CarritoScreen()),
      ),
    );
    final image = tester.widget<Image>(
      find.byKey(const ValueKey('producto-2-imagen')),
    );
    expect((image.image as AssetImage).assetName, AppAssets.productFallback);
    expect(find.text('CILINDRO 30 KG'), findsOneWidget);
    expect(find.text(r'$600.00'), findsNWidgets(2));
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.foregroundColor, AppColors.white);
    expect(tester.widget<Text>(find.text('Carrito')).style, isNull);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.delete_outline)).color,
      AppColors.accent,
    );
    final clear = tester.widget<TextButton>(
      find.byKey(const ValueKey('clear-cart')),
    );
    expect(clear.onPressed, isNotNull);
    expect(clear.style?.foregroundColor?.resolve(const {}), AppColors.accent);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Limpiar permanece visible y deshabilitado con carrito vacío', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [carritoStoreProvider.overrideWithValue(_Store([]))],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CarritoScreen()),
      ),
    );
    await tester.pumpAndSettle();
    final clear = tester.widget<TextButton>(
      find.byKey(const ValueKey('clear-cart')),
    );
    expect(clear.onPressed, isNull);
    expect(
      clear.style?.foregroundColor?.resolve({WidgetState.disabled}),
      Colors.white54,
    );
  });

  testWidgets('modifica cantidades y confirma antes de quitar una línea', (
    tester,
  ) async {
    final store = _Store([
      _item.copyWith(cantidad: 2, importeCentavos: 120000),
    ]);
    final container = ProviderContainer(
      overrides: [carritoStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CarritoScreen()),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('cart-item-plus-0')));
    await tester.pumpAndSettle();
    expect(container.read(carritoControllerProvider).items.single.cantidad, 3);
    expect(container.read(carritoControllerProvider).totalCentavos, 180000);
    expect(find.text(r'$1800.00'), findsNWidgets(2));

    await tester.tap(find.byKey(const ValueKey('cart-item-minus-0')));
    await tester.pumpAndSettle();
    expect(container.read(carritoControllerProvider).items.single.cantidad, 2);

    await tester.tap(find.byKey(const ValueKey('cart-item-minus-0')));
    await tester.pumpAndSettle();
    expect(container.read(carritoControllerProvider).items.single.cantidad, 1);
    await tester.tap(find.byKey(const ValueKey('cart-item-minus-0')));
    await tester.pumpAndSettle();
    expect(find.text('Quitar producto'), findsOneWidget);
    expect(
      find.text('¿Deseas quitar este producto del pedido?'),
      findsOneWidget,
    );
    expect(container.read(carritoControllerProvider).items.single.cantidad, 1);

    await tester.tap(find.widgetWithText(TextButton, 'No'));
    await tester.pumpAndSettle();
    expect(container.read(carritoControllerProvider).items.single.cantidad, 1);
    expect(find.text('Tu carrito está vacío.'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('cart-item-delete-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sí, quitar'));
    await tester.pumpAndSettle();
    expect(container.read(carritoControllerProvider).items, isEmpty);
    expect(store.items, isEmpty);
    expect(find.text('Tu carrito está vacío.'), findsOneWidget);
    expect(find.text('Total'), findsNothing);
  });
}

final _item = ItemPedido(
  productoId: 2,
  descripcion: 'CILINDRO 30 KG',
  cantidad: 1,
  importeCentavos: 60000,
  fecha: DateTime(2026),
  servicioId: 1,
  presentacion: '30 KG',
);

final class _Store implements CarritoStore {
  _Store(this.items);
  List<ItemPedido> items;
  @override
  List<ItemPedido> read() => items;
  @override
  Future<void> save(List<ItemPedido> value) async => items = [...value];
}
