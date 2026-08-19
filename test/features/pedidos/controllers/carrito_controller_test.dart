import 'package:combugas_clientes/features/pedidos/controllers/carrito_controller.dart';
import 'package:combugas_clientes/features/pedidos/data/carrito_storage.dart';
import 'package:combugas_clientes/features/pedidos/models/item_pedido.dart';
import 'package:combugas_clientes/features/pedidos/models/producto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('restaura, persiste y limpia el carrito', () async {
    final store = _Store([_item]);
    final container = _container(store);
    addTearDown(container.dispose);
    expect(container.read(carritoControllerProvider).lineas, 1);
    await container.read(carritoControllerProvider.notifier).clear();
    expect(container.read(carritoControllerProvider).items, isEmpty);
    expect(store.items, isEmpty);
  });

  test('total suma los importes reales en centavos sin perder precisión', () {
    final store = _Store([_item, _item.copyWith(importeCentavos: 59010)]);
    final container = _container(store);
    addTearDown(container.dispose);
    expect(container.read(carritoControllerProvider).totalCentavos, 119010);
    expect(formatoMoneda(119010), r'$1190.10');
  });

  test('productos normales crean líneas; croquetas iguales acumulan', () async {
    final store = _Store();
    final container = _container(store);
    addTearDown(container.dispose);
    final controller = container.read(carritoControllerProvider.notifier);
    await controller.agregarProducto(
      producto: _cylinder,
      cantidad: 2,
      subcanalUsuario: 1,
    );
    await controller.agregarProducto(
      producto: _cylinder,
      cantidad: 1,
      subcanalUsuario: 1,
    );
    await controller.agregarProducto(
      producto: _croquettes,
      cantidad: 2,
      subcanalUsuario: 1,
    );
    await controller.agregarProducto(
      producto: _croquettes,
      cantidad: 3,
      subcanalUsuario: 1,
    );
    final state = container.read(carritoControllerProvider);
    expect(state.lineas, 3);
    expect(state.items.first.importeCentavos, 120000);
    expect(state.items.last.cantidad, 5);
    expect(state.items.last.importeCentavos, 250000);
  });

  test('AWA requiere subcanal 1 y conserva carrito al rechazar', () async {
    final store = _Store();
    final container = _container(store);
    addTearDown(container.dispose);
    final result = await container
        .read(carritoControllerProvider.notifier)
        .agregarProducto(producto: _water, cantidad: 1, subcanalUsuario: 2);
    expect(result.agregado, isFalse);
    expect(container.read(carritoControllerProvider).items, isEmpty);
  });

  test('estacionario calcula litros, importe y valida mínimos', () async {
    final store = _Store();
    final container = _container(store);
    addTearDown(container.dispose);
    final controller = container.read(carritoControllerProvider.notifier);
    const minimums = MontosMinimos(dineroCentavos: 50000, litros: 40);
    final rejected = await controller.agregarEstacionarioPorImporte(
      producto: _stationary,
      importeCentavos: 49999,
      minimos: minimums,
    );
    expect(rejected.agregado, isFalse);
    final added = await controller.agregarEstacionarioPorLitros(
      producto: _stationary,
      litros: 50,
      minimos: minimums,
    );
    expect(added.agregado, isTrue);
    final item = container.read(carritoControllerProvider).items.single;
    expect(item.cantidad, 50);
    expect(item.importeCentavos, 60000);
  });

  test(
    'actualiza cantidad y elimina una línea persistiendo el cambio',
    () async {
      final store = _Store([_item]);
      final container = _container(store);
      addTearDown(container.dispose);
      final controller = container.read(carritoControllerProvider.notifier);
      await controller.actualizarCantidad(0, 3);
      expect(
        container.read(carritoControllerProvider).items.single.cantidad,
        3,
      );
      expect(
        container.read(carritoControllerProvider).items.single.importeCentavos,
        180000,
      );
      await controller.eliminarLinea(0);
      expect(store.items, isEmpty);
    },
  );
}

ProviderContainer _container(_Store store) => ProviderContainer(
  overrides: [carritoStoreProvider.overrideWithValue(store)],
);

final class _Store implements CarritoStore {
  _Store([this.items = const []]);
  List<ItemPedido> items;
  @override
  List<ItemPedido> read() => items;
  @override
  Future<void> save(List<ItemPedido> value) async => items = [...value];
}

const _cylinder = Producto(
  id: 2,
  descripcion: 'CILINDRO 30 KG',
  presentacion: '30 KG',
  servicioId: 1,
  precioCentavos: 60000,
);
const _water = Producto(
  id: 4,
  descripcion: 'GARRAFÓN',
  presentacion: '20 L',
  servicioId: 3,
  precioCentavos: 4000,
);
const _croquettes = Producto(
  id: 20,
  descripcion: 'BULTO ADULTO 20 KG',
  presentacion: 'BULTO ADULTO 20 KG',
  servicioId: 9,
  precioCentavos: 50000,
);
const _stationary = Producto(
  id: 9,
  descripcion: 'GAS ESTACIONARIO',
  presentacion: 'LITRO',
  servicioId: 1,
  precioCentavos: 1200,
);
final _item = ItemPedido(
  productoId: 2,
  descripcion: 'CILINDRO',
  cantidad: 1,
  importeCentavos: 60000,
  fecha: DateTime(2026),
  servicioId: 1,
  presentacion: '30 KG',
);
