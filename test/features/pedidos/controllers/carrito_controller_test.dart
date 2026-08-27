import 'package:combugas_clientes/features/pedidos/controllers/carrito_controller.dart';
import 'package:combugas_clientes/features/pedidos/data/carrito_storage.dart';
import 'package:combugas_clientes/features/pedidos/models/create_order.dart';
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

  test('productos iguales acumulan cantidad e importe en una línea', () async {
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
    expect(state.lineas, 2);
    expect(state.items.first.cantidad, 3);
    expect(state.items.first.importeCentavos, 180000);
    expect(state.items.last.cantidad, 5);
    expect(state.items.last.importeCentavos, 250000);
  });

  test(
    'garrafón agregado varias veces queda unificado en carrito y pedido',
    () async {
      final store = _Store();
      final container = _container(store);
      addTearDown(container.dispose);
      final controller = container.read(carritoControllerProvider.notifier);
      for (final cantidad in [1, 2, 3]) {
        await controller.agregarProducto(
          producto: _water,
          cantidad: cantidad,
          subcanalUsuario: 1,
        );
      }

      final cart = container.read(carritoControllerProvider);
      expect(cart.lineas, 1);
      expect(cart.items.single.cantidad, 6);
      expect(cart.items.single.importeCentavos, 24000);
      expect(cart.totalCentavos, 24000);

      final request = CreateOrderRequest.fromItems(
        direccionId: 1,
        clienteId: 2,
        telefonoId: 3,
        metodoPagoId: 1,
        items: cart.items,
      );
      expect(request.detalles, hasLength(1));
      expect(request.detalles.single.clave, _water.id);
      expect(request.detalles.single.cantidad, 6);
      expect(request.detalles.single.importe, 240);
    },
  );

  test(
    'productos o presentaciones diferentes conservan líneas separadas',
    () async {
      final store = _Store();
      final container = _container(store);
      addTearDown(container.dispose);
      final controller = container.read(carritoControllerProvider.notifier);
      for (final product in [_water, _croquettesSmall, _croquettes]) {
        await controller.agregarProducto(
          producto: product,
          cantidad: 1,
          subcanalUsuario: 1,
        );
      }

      final items = container.read(carritoControllerProvider).items;
      expect(items, hasLength(3));
      expect(items.map((item) => item.presentacion), [
        '20 L',
        'BULTO ADULTO 10 KG',
        'BULTO ADULTO 20 KG',
      ]);
    },
  );

  test('cantidad modificada con más se acumula al volver a agregar', () async {
    final store = _Store();
    final container = _container(store);
    addTearDown(container.dispose);
    final controller = container.read(carritoControllerProvider.notifier);
    await controller.agregarProducto(
      producto: _water,
      cantidad: 3,
      subcanalUsuario: 1,
    );
    await controller.incrementarLinea(0);
    await controller.agregarProducto(
      producto: _water,
      cantidad: 2,
      subcanalUsuario: 1,
    );

    final cart = container.read(carritoControllerProvider);
    expect(cart.lineas, 1);
    expect(cart.items.single.cantidad, 6);
    expect(cart.items.single.importeCentavos, 24000);
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
    await controller.agregarEstacionarioPorImporte(
      producto: _stationary,
      importeCentavos: 60000,
      minimos: minimums,
    );
    final items = container.read(carritoControllerProvider).items;
    expect(items, hasLength(2));
    expect(items.every((item) => item.cantidad == 50), isTrue);
    expect(items.every((item) => item.importeCentavos == 60000), isTrue);
    expect(items.first.descripcion, contains('litros gas estacionario'));
    expect(items.last.descripcion, contains('gas estacionario ='));
  });

  test(
    'incrementa, disminuye sin llegar a cero y elimina persistiendo',
    () async {
      final store = _Store([_item]);
      final container = _container(store);
      addTearDown(container.dispose);
      final controller = container.read(carritoControllerProvider.notifier);
      await controller.incrementarLinea(0);
      expect(
        container.read(carritoControllerProvider).items.single.cantidad,
        2,
      );
      expect(
        container.read(carritoControllerProvider).items.single.importeCentavos,
        120000,
      );
      expect(await controller.disminuirLinea(0), isTrue);
      expect(
        container.read(carritoControllerProvider).items.single.cantidad,
        1,
      );
      expect(await controller.disminuirLinea(0), isFalse);
      expect(
        container.read(carritoControllerProvider).items.single.cantidad,
        1,
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
const _croquettesSmall = Producto(
  id: 20,
  descripcion: 'BULTO ADULTO 10 KG',
  presentacion: 'BULTO ADULTO 10 KG',
  servicioId: 9,
  precioCentavos: 30000,
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
