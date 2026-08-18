final class DireccionRequest {
  const DireccionRequest({
    required this.descripcion,
    required this.idColonia,
    required this.idCerrada,
    required this.idCalle,
    required this.numero,
    required this.latitud,
    required this.longitud,
  });
  final String descripcion;
  final int idColonia;
  final int idCerrada;
  final int idCalle;
  final String numero;
  final double latitud;
  final double longitud;
}

final class DireccionOperationResult {
  const DireccionOperationResult({
    required this.succeeded,
    required this.message,
  });
  final bool succeeded;
  final String message;
}
