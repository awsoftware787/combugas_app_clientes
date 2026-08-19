import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_exception.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../direcciones/controllers/direccion_controller.dart';
import '../data/pedido_repository.dart';
import '../data/ultimo_pedido_storage.dart';
import '../models/create_order.dart';
import '../models/item_pedido.dart';
import '../models/metodo_pago.dart';
import '../models/producto.dart';
import 'carrito_controller.dart';
import 'mis_pedidos_controller.dart';

enum ConfirmacionStatus { idle, loadingTime, ready, saving, success, error }

final class ConfirmacionState {
  const ConfirmacionState({
    this.status = ConfirmacionStatus.idle,
    this.metodoPago = MetodoPago.efectivo,
    this.tiempoEntrega,
    this.message,
    this.result,
  });

  final ConfirmacionStatus status;
  final MetodoPago metodoPago;
  final String? tiempoEntrega;
  final String? message;
  final CreateOrderResult? result;
  bool get saving => status == ConfirmacionStatus.saving;

  ConfirmacionState copyWith({
    ConfirmacionStatus? status,
    MetodoPago? metodoPago,
    String? tiempoEntrega,
    bool clearTiempo = false,
    String? message,
    bool clearMessage = false,
    CreateOrderResult? result,
  }) => ConfirmacionState(
    status: status ?? this.status,
    metodoPago: metodoPago ?? this.metodoPago,
    tiempoEntrega: clearTiempo ? null : tiempoEntrega ?? this.tiempoEntrega,
    message: clearMessage ? null : message ?? this.message,
    result: result ?? this.result,
  );
}

final currentDateTimeProvider = Provider<DateTime Function()>(
  (_) => DateTime.now,
);

final confirmacionControllerProvider =
    NotifierProvider<ConfirmacionController, ConfirmacionState>(
      ConfirmacionController.new,
    );

final class ConfirmacionController extends Notifier<ConfirmacionState> {
  @override
  ConfirmacionState build() => const ConfirmacionState();

  void selectPayment(MetodoPago payment) {
    if (state.saving) return;
    state = state.copyWith(metodoPago: payment, clearMessage: true);
  }

  Future<void> prepare(List<ItemPedido> items) async {
    state = const ConfirmacionState();
    await loadDeliveryTime(items);
  }

  Future<void> loadDeliveryTime(List<ItemPedido> items) async {
    if (state.status != ConfirmacionStatus.idle) return;
    if (items.isEmpty) {
      state = state.copyWith(status: ConfirmacionStatus.ready);
      return;
    }
    if (items.every((item) => item.productoId == ProductoIds.garrafonNatural)) {
      state = state.copyWith(
        status: ConfirmacionStatus.ready,
        tiempoEntrega: 'Sin tiempo de entrega estimado',
      );
      return;
    }
    state = state.copyWith(status: ConfirmacionStatus.loadingTime);
    try {
      final fases = await ref.read(pedidoRepositoryProvider).getTiempos();
      final target =
          items.any((item) => item.productoId == ProductoIds.estacionario)
              ? 5
              : 2;
      TiempoFase? selected;
      for (final fase in fases) {
        if (fase.id == target) {
          selected = fase;
          break;
        }
      }
      state = state.copyWith(
        status: ConfirmacionStatus.ready,
        tiempoEntrega:
            selected?.descripcion.isNotEmpty == true
                ? selected!.descripcion
                : '45 Minutos',
      );
    } catch (_) {
      // Android oculta el estimado si esta consulta secundaria falla.
      state = state.copyWith(
        status: ConfirmacionStatus.ready,
        clearTiempo: true,
      );
    }
  }

  Future<CreateOrderResult?> submit({String? accessKey}) async {
    if (state.saving || state.result != null) return null;
    final cart = ref.read(carritoControllerProvider);
    final session = ref.read(authControllerProvider).session;
    final address = ref.read(direccionControllerProvider).selected;
    final now = ref.read(currentDateTimeProvider)();

    final validation = switch ((cart.items.isEmpty, session, address)) {
      (true, _, _) => 'Debe añadir por lo menos un producto.',
      (_, null, _) => 'No existe una sesión activa.',
      (_, _, null) => 'Selecciona una dirección de entrega.',
      (_, _, final address?) when address.tienePedido =>
        'Ya existe un pedido activo para esta dirección.',
      _ when now.hour < 7 || now.hour > 19 =>
        'El horario para realizar pedidos es de 7:00 a 20:00 horas.',
      _ => null,
    };
    if (validation != null) {
      state = state.copyWith(
        status: ConfirmacionStatus.error,
        message: validation,
      );
      return null;
    }

    final request = CreateOrderRequest.fromItems(
      direccionId: address!.id,
      clienteId: session!.claveUsuario,
      telefonoId: session.claveTelefono,
      metodoPagoId: state.metodoPago.id,
      items: cart.items,
      observaciones: accessKey,
    );
    state = state.copyWith(
      status: ConfirmacionStatus.saving,
      clearMessage: true,
    );
    try {
      final result = await ref
          .read(pedidoRepositoryProvider)
          .createOrder(request);

      // Desde aquí el servidor ya confirmó el pedido: no se permite reintentar.
      state = state.copyWith(
        status: ConfirmacionStatus.success,
        result: result,
      );
      ref.invalidate(misPedidosControllerProvider);
      try {
        await ref.read(ultimoPedidoStoreProvider).save(result);
        await ref.read(carritoControllerProvider.notifier).clear();
      } catch (_) {
        state = state.copyWith(
          message:
              'El pedido se creó, pero no fue posible actualizar todos los datos locales.',
        );
      }
      return result;
    } catch (error) {
      state = state.copyWith(
        status: ConfirmacionStatus.error,
        message: _message(error),
      );
      return null;
    }
  }

  String _message(Object error) {
    if (error is NetworkTimeoutException) {
      return 'El servidor tardó demasiado en responder. El resultado del pedido es incierto; verifica Mis Pedidos antes de reintentar.';
    }
    if (error is NoConnectionException) {
      return 'No fue posible conectarse. Tu carrito permanece intacto.';
    }
    if (error is WebServiceException) {
      return switch (error.message) {
        'NOHORARIO' =>
          'El pedido fue rechazado porque está fuera del horario de servicio.',
        'PEDIDOERR' =>
          'Ha ocurrido un error al procesar tu pedido. Inténtalo más tarde.',
        'ERRASIGNACION' =>
          'No fue posible asignar el pedido. Verifica los datos e inténtalo más tarde.',
        final value when value.isNotEmpty => value,
        _ => 'El servidor rechazó el pedido.',
      };
    }
    if (error is InvalidSoapResponseException) {
      return 'La respuesta del servidor no fue válida. Tu carrito permanece intacto.';
    }
    return 'No fue posible procesar el pedido. Tu carrito permanece intacto.';
  }
}
