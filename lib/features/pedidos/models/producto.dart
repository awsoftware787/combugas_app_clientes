abstract final class ProductoIds {
  static const cilindro30 = 2;
  static const cilindro45 = 3;
  static const garrafonNatural = 4;
  static const sixNatural = 8;
  static const garrafonAlcalino = 7;
  static const sixAlcalino = 14;
  static const estacionario = 9;
}

abstract final class ServicioIds {
  static const gas = 1;
  static const agua = 3;
  static const croquetas = 9;
}

final class Producto {
  const Producto({
    required this.id,
    required this.descripcion,
    required this.presentacion,
    required this.servicioId,
    required this.precioCentavos,
    this.tipoProductoId,
    this.tipoProducto,
    this.urlIcono,
    this.montoMinimoEstCentavos = 0,
    this.litroMinimoEst = 0,
  });

  final int id;
  final String descripcion;
  final String presentacion;
  final int servicioId;
  final int precioCentavos;
  final int? tipoProductoId;
  final String? tipoProducto;
  final String? urlIcono;
  final int montoMinimoEstCentavos;
  final double litroMinimoEst;

  bool get esAgua => servicioId == ServicioIds.agua;
  bool get esCroqueta => servicioId == ServicioIds.croquetas;
  bool get esCroqueta2Kg =>
      esCroqueta && RegExp(r'\b2\s*KG\b').hasMatch(_texto);
  bool get esEstacionario => id == ProductoIds.estacionario;
  bool get esBulto => _texto.contains('BULTO');
  bool get esBolsa => _texto.contains('BOLSA');
  String get _texto => '$presentacion $descripcion'.toUpperCase();

  String get opcionCroqueta =>
      descripcion
          .replaceFirst(RegExp(r'^BULTO DE\s+', caseSensitive: false), '')
          .replaceFirst(RegExp(r'^BULTO\s+', caseSensitive: false), '')
          .replaceFirst(RegExp(r'^BOLSA DE\s+', caseSensitive: false), '')
          .replaceFirst(RegExp(r'^BOLSA\s+', caseSensitive: false), '')
          .trim();
}

final class MontosMinimos {
  const MontosMinimos({
    required this.dineroCentavos,
    required this.litros,
    this.unidades = 1,
    this.isMultiploCroquetas = false,
    this.valorMultiploCroquetas = 1,
  });

  const MontosMinimos.empty()
    : dineroCentavos = 0,
      litros = 0,
      unidades = 1,
      isMultiploCroquetas = false,
      valorMultiploCroquetas = 1;

  final int dineroCentavos;
  final double litros;
  final int unidades;
  final bool isMultiploCroquetas;
  final int valorMultiploCroquetas;

  int cantidadInicial(Producto producto) =>
      producto.esCroqueta2Kg && unidades > 0 ? unidades : 1;

  int incremento(Producto producto) =>
      producto.esCroqueta2Kg &&
              isMultiploCroquetas &&
              valorMultiploCroquetas > 0
          ? valorMultiploCroquetas
          : 1;

  String? validarCantidad(Producto producto, int cantidad) {
    if (!producto.esCroqueta2Kg) return null;
    final minimo = cantidadInicial(producto);
    final multiplo = incremento(producto);
    if (cantidad >= minimo && cantidad % multiplo == 0) return null;
    return multiplo > 1
        ? 'La cantidad mínima es $minimo bolsas y debe ser múltiplo de $multiplo.'
        : 'La cantidad mínima es $minimo bolsas.';
  }
}
