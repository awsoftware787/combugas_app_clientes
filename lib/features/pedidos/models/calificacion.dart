final class CalificacionRequest {
  const CalificacionRequest({
    required this.entregado,
    required this.puntuacion,
    required this.comentarios,
    required this.pedidoId,
    required this.clienteId,
  });

  final bool entregado;
  final int puntuacion;
  final String comentarios;
  final int pedidoId;
  final int clienteId;

  Map<String, Object?> get soapParameters => {
    '_blEntregado': entregado,
    '_strPuntuacion': puntuacion.toDouble().toStringAsFixed(1),
    '_strComentarios': comentarios,
    '_intPedido': pedidoId,
    '_intCliente': clienteId,
  };
}

final class CalificacionResult {
  const CalificacionResult({required this.mensaje});
  final String mensaje;
}
