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
    var items = [...state.items];
    if (producto.esCroqueta) {
      final index = items.indexWhere(
        (item) => item.esCroqueta && item.productoId == producto.id,
      );
      if (index >= 0) {
        final previous = items[index];
        items[index] = previous.copyWith(
          descripcion: producto.descripcion,
          presentacion: producto.presentacion,
          cantidad: previous.cantidad + cantidad,
          importeCentavos: previous.importeCentavos + importe,
          fecha: now,
        );
      } else {
        items.add(_item(producto, cantidad.toDouble(), importe, now));
      }
    } else {
      items.add(_item(producto, cantidad.toDouble(), importe, now));
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

  Future<void> eliminarLinea(int index) async {
    if (index < 0 || index >= state.items.length) return;
    final items = [...state.items]..removeAt(index);
    await _replace(items);
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
  );

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
    );
    await _replace([...state.items, item]);
  }

  Future<void> _replace(List<ItemPedido> items) async {
    await _store.save(items);
    state = CarritoState(items: List.unmodifiable(items));
  }
}
