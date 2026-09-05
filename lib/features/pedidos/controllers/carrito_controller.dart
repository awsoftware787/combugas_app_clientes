import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/carrito_storage.dart';
import '../models/item_pedido.dart';
import '../models/producto.dart';

final class CarritoState {
  const CarritoState({this.items = const []});
  final List<ItemPedido> items;
  int get lineas => items.length;
  int get totalCentavos =>
      items.fold(0, (total, item) => total + item.importeCentavos);
}

final class AgregarResultado {
  const AgregarResultado({required this.agregado, required this.mensaje});
  final bool agregado;
  final String mensaje;
}

final carritoControllerProvider =
    NotifierProvider<CarritoController, CarritoState>(CarritoController.new);

final class CarritoController extends Notifier<CarritoState> {
  CarritoStore get _store => ref.read(carritoStoreProvider);

  @override
  CarritoState build() => CarritoState(items: _store.read());

  Future<AgregarResultado> agregarProducto({
    required Producto producto,
    required int cantidad,
    required int subcanalUsuario,
  }) async {
    if (producto.esAgua && subcanalUsuario != 1) {
      return const AgregarResultado(
        agregado: false,
        mensaje: 'Producto disponible solo para clientes domésticos.',
      );
    }
    final now = DateTime.now();
    final importe = producto.precioCentavos * cantidad;
    final nuevo = _item(producto, cantidad.toDouble(), importe, now);
    final items = [...state.items];
    final index = items.indexWhere((item) => _esMismoProducto(item, nuevo));
    if (index >= 0) {
      final previous = items[index];
      items[index] = previous.copyWith(
        descripcion: producto.descripcion,
        presentacion: producto.presentacion,
        tipoProductoId: producto.tipoProductoId,
        tipoProducto: producto.tipoProducto,
        urlIcono: producto.urlIcono,
        cantidad: previous.cantidad + cantidad,
        importeCentavos: previous.importeCentavos + importe,
        fecha: now,
      );
    } else {
      items.add(nuevo);
    }
    await _replace(items);
    return AgregarResultado(
      agregado: true,
      mensaje:
          producto.esAgua
              ? 'Producto agregado. Sin tiempo de entrega estimado.'
              : 'Producto agregado al carrito.',
    );
  }

  Future<AgregarResultado> agregarEstacionarioPorImporte({
    required Producto producto,
    required int importeCentavos,
    required MontosMinimos minimos,
  }) async {
    if (importeCentavos < minimos.dineroCentavos) {
      return AgregarResultado(
        agregado: false,
        mensaje: 'El monto mínimo es ${formatoMoneda(minimos.dineroCentavos)}.',
      );
    }
    if (producto.precioCentavos <= 0) {
      return const AgregarResultado(
        agregado: false,
        mensaje: 'El precio de gas estacionario no está disponible.',
      );
    }
    final litros = importeCentavos / producto.precioCentavos;
    await _agregarEstacionario(
      producto,
      litros,
      importeCentavos,
      '${formatoMoneda(importeCentavos)} gas estacionario = ${litros.toStringAsFixed(2)} litros',
    );
    return const AgregarResultado(
      agregado: true,
      mensaje: 'Producto agregado al carrito.',
    );
  }

  Future<AgregarResultado> agregarEstacionarioPorLitros({
    required Producto producto,
    required double litros,
    required MontosMinimos minimos,
  }) async {
    if (litros < minimos.litros) {
      return AgregarResultado(
        agregado: false,
        mensaje:
            'La cantidad mínima es ${minimos.litros.toStringAsFixed(2)} litros.',
      );
    }
    final importe = (litros * producto.precioCentavos).round();
    await _agregarEstacionario(
      producto,
      litros,
      importe,
      '${litros.toStringAsFixed(2)} litros gas estacionario = ${formatoMoneda(importe)}',
    );
    return const AgregarResultado(
      agregado: true,
      mensaje: 'Producto agregado al carrito.',
    );
  }

  Future<void> clear() => _replace(const []);

  Future<void> actualizarPrecios(List<Producto> productos) async {
    final porId = {for (final producto in productos) producto.id: producto};
    final items = state.items
        .map((item) {
          final producto = porId[item.productoId];
          if (producto == null || producto.precioCentavos <= 0) {
            throw StateError('Precio no disponible para ${item.productoId}');
          }
          final importe = (item.cantidad * producto.precioCentavos).round();
          return item.copyWith(
            importeCentavos: importe,
            descripcion:
                producto.esEstacionario
                    ? '${item.cantidad.toStringAsFixed(2)} litros gas estacionario = ${formatoMoneda(importe)}'
                    : producto.descripcion,
          );
        })
        .toList(growable: false);
    await _replace(items);
  }

  Future<void> eliminarLinea(int index) async {
    if (index < 0 || index >= state.items.length) return;
    final items = [...state.items]..removeAt(index);
    await _replace(items);
  }

  Future<void> incrementarLinea(int index) async {
    if (index < 0 || index >= state.items.length) return;
    await actualizarCantidad(index, state.items[index].cantidad + 1);
  }

  /// Decrementa la línea sin permitir que su cantidad llegue a cero.
  ///
  /// Devuelve `false` cuando la línea no existe o requiere confirmación para
  /// eliminarse. La interfaz puede entonces solicitar esa confirmación y usar
  /// [eliminarLinea] si el usuario la acepta.
  Future<bool> disminuirLinea(int index) async {
    if (index < 0 || index >= state.items.length) return false;
    final cantidad = state.items[index].cantidad;
    if (cantidad <= 1) return false;
    await actualizarCantidad(index, cantidad - 1);
    return true;
  }

  Future<void> actualizarCantidad(int index, double cantidad) async {
    if (index < 0 || index >= state.items.length || cantidad <= 0) return;
    final items = [...state.items];
    final previous = items[index];
    final unitPrice =
        previous.cantidad == 0
            ? 0
            : previous.importeCentavos / previous.cantidad;
    items[index] = previous.copyWith(
      cantidad: cantidad,
      importeCentavos: (unitPrice * cantidad).round(),
      fecha: DateTime.now(),
    );
    await _replace(items);
  }

  ItemPedido _item(
    Producto producto,
    double cantidad,
    int importe,
    DateTime fecha,
  ) => ItemPedido(
    productoId: producto.id,
    descripcion: producto.descripcion,
    cantidad: cantidad,
    importeCentavos: importe,
    fecha: fecha,
    servicioId: producto.servicioId,
    presentacion: producto.presentacion,
    tipoProductoId: producto.tipoProductoId,
    tipoProducto: producto.tipoProducto,
    urlIcono: producto.urlIcono,
  );

  bool _esMismoProducto(ItemPedido actual, ItemPedido nuevo) {
    // Gas estacionario conserva líneas independientes porque las altas por
    // importe y por litros representan modalidades distintas para el usuario.
    if (nuevo.productoId == ProductoIds.estacionario) return false;
    return actual.productoId == nuevo.productoId &&
        actual.servicioId == nuevo.servicioId &&
        _normalizarPresentacion(actual.presentacion) ==
            _normalizarPresentacion(nuevo.presentacion);
  }

  String _normalizarPresentacion(String value) => value.trim().toUpperCase();

  Future<void> _agregarEstacionario(
    Producto producto,
    double litros,
    int importe,
    String descripcion,
  ) async {
    final item = ItemPedido(
      productoId: producto.id,
      descripcion: descripcion,
      cantidad: litros,
      importeCentavos: importe,
      fecha: DateTime.now(),
      servicioId: producto.servicioId,
      presentacion: producto.presentacion,
      tipoProductoId: producto.tipoProductoId,
      tipoProducto: producto.tipoProducto,
      urlIcono: producto.urlIcono,
    );
    await _replace([...state.items, item]);
  }

  Future<void> _replace(List<ItemPedido> items) async {
    await _store.save(items);
    state = CarritoState(items: List.unmodifiable(items));
  }
}
