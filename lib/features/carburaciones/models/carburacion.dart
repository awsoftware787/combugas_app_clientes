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
}
