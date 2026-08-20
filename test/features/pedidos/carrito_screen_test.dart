import 'package:combugas_clientes/core/constants/app_assets.dart';
import 'package:combugas_clientes/core/theme/app_colors.dart';
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
    expect((image.image as AssetImage).assetName, AppAssets.productCylinder);
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
