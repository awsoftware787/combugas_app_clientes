import 'item_pedido.dart';

enum PedidoHistorialStatus {
  enCurso,
  pendienteConfirmacion,
  completo,
  cancelado,
}

final class PedidoHistorial {
  const PedidoHistorial({
    required this.id,
    required this.fecha,
    required this.direccion,
    required this.metodoPago,
    required this.productos,
    required this.estatusPedido,
    required this.completo,
    required this.confirmadoOperador,
    required this.confirmadoCliente,
  });

  final int id;
  final DateTime? fecha;
  final PedidoDireccion direccion;
  final String metodoPago;
  final List<PedidoHistorialItem> productos;
  final bool estatusPedido;
  final bool completo;
  final bool confirmadoOperador;
  final bool confirmadoCliente;

  PedidoHistorialStatus get status {
    if (!estatusPedido) return PedidoHistorialStatus.cancelado;
    if (completo && confirmadoCliente) return PedidoHistorialStatus.completo;
    if (completo || confirmadoOperador) {
      return PedidoHistorialStatus.pendienteConfirmacion;
    }
    return PedidoHistorialStatus.enCurso;
  }

  bool get puedeCancelar => status == PedidoHistorialStatus.enCurso;
  bool get puedeSeguir => status == PedidoHistorialStatus.enCurso;
  int get totalCentavos =>
      productos.fold(0, (total, producto) => total + producto.importeCentavos);

  PedidoHistorial copyWith({bool? estatusPedido, bool? completo}) =>
      PedidoHistorial(
        id: id,
        fecha: fecha,
        direccion: direccion,
        metodoPago: metodoPago,
        productos: productos,
        estatusPedido: estatusPedido ?? this.estatusPedido,
        completo: completo ?? this.completo,
        confirmadoOperador: confirmadoOperador,
        confirmadoCliente: confirmadoCliente,
      );
}

final class PedidoDireccion {
  const PedidoDireccion({
    required this.id,
    required this.descripcion,
    required this.tipoCalle,
    required this.calle,
    required this.idCerrada,
    required this.cerrada,
    required this.numeroInterior,
    required this.numeroExterior,
    required this.colonia,
    required this.ciudad,
    required this.estado,
    required this.codigoPostal,
    required this.latitud,
    required this.longitud,
  });

  final int id;
  final String descripcion;
  final String tipoCalle;
  final String calle;
  final int idCerrada;
  final String cerrada;
  final String numeroInterior;
  final String numeroExterior;
  final String colonia;
  final String ciudad;
  final String estado;
  final String codigoPostal;
  final double latitud;
  final double longitud;

  String get direccionCompleta {
    final segmento =
        idCerrada <= 1 || cerrada.trim().isEmpty ? '' : ', $cerrada';
    return '$tipoCalle $calle $numeroExterior$segmento, $colonia, $ciudad, $estado'
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

final class PedidoHistorialItem {
  const PedidoHistorialItem({
    required this.productoId,
    required this.descripcion,
    required this.cantidad,
    required this.importeCentavos,
    this.servicioId = 0,
    this.presentacion = '',
  });

  final int productoId;
  final String descripcion;
  final double cantidad;
  final int importeCentavos;
  final int servicioId;
  final String presentacion;

  ItemPedido toCartItem() => ItemPedido(
    productoId: productoId,
    descripcion: descripcion,
    cantidad: cantidad,
    importeCentavos: importeCentavos,
    fecha: DateTime.fromMillisecondsSinceEpoch(0),
    servicioId: servicioId,
    presentacion: presentacion,
  );
}

final class PedidoSeguimientoInfo {
  const PedidoSeguimientoInfo({
    required this.direccion,
    required this.asignaciones,
  });
  final PedidoDireccion direccion;
  final List<PedidoAsignacion> asignaciones;
}

final class PedidoAsignacion {
  const PedidoAsignacion({
    required this.operadorId,
    required this.nombreOperador,
    required this.rutaId,
    this.vehiculo,
  });
  final int operadorId;
  final String nombreOperador;
  final int rutaId;
  final PedidoVehiculo? vehiculo;
}

final class PedidoVehiculo {
  const PedidoVehiculo({
    required this.descripcion,
    required this.latitud,
    required this.longitud,
  });

  final String descripcion;
  final double latitud;
  final double longitud;
}

final class CancelarPedidoResult {
  const CancelarPedidoResult({required this.mensaje});
  final String mensaje;
  bool get cancelado => mensaje == 'CANCELADO';
  bool get sesionBloqueada => mensaje == 'LOCK';
}
