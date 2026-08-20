final class Carburacion {
  const Carburacion({
    required this.descripcion,
    required this.latitud,
    required this.longitud,
    required this.tipo,
  });

  final String descripcion;
  final double latitud;
  final double longitud;

  /// Android usa 1 para gas y cualquier otro valor para gas + otro servicio.
  final int tipo;

  bool get esSoloGas => tipo == 1;

  bool get tieneCoordenadasUtilizables =>
      latitud.isFinite &&
      longitud.isFinite &&
      latitud != 0 &&
      longitud != 0 &&
      latitud >= -90 &&
      latitud <= 90 &&
      longitud >= -180 &&
      longitud <= 180;
}
