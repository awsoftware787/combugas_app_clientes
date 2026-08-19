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
  });

  final int id;
  final String descripcion;
  final String presentacion;
  final int servicioId;
  final int precioCentavos;

  bool get esAgua => servicioId == ServicioIds.agua;
  bool get esCroqueta => servicioId == ServicioIds.croquetas;
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
  const MontosMinimos({required this.dineroCentavos, required this.litros});

  const MontosMinimos.empty() : dineroCentavos = 0, litros = 0;

  final int dineroCentavos;
  final double litros;
}
