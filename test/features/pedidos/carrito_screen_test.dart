import 'package:combugas_clientes/core/constants/app_assets.dart';
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
    expect(tester.takeException(), isNull);
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
