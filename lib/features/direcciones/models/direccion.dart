final class Direccion {
  const Direccion({
    required this.id,
    required this.descripcion,
    required this.tipoCalle,
    required this.idCalle,
    required this.calle,
    required this.numeroInterior,
    required this.numeroExterior,
    required this.idColonia,
    required this.colonia,
    required this.idCiudad,
    required this.ciudad,
    required this.idEstado,
    required this.estado,
    required this.idZona,
    required this.zona,
    required this.idCodigoPostal,
    required this.codigoPostal,
    required this.referencias,
    required this.activa,
    required this.latitud,
    required this.longitud,
    required this.observaciones,
    required this.entreCalle1,
    required this.entreCalle2,
    required this.entreCalle3,
    required this.idSegmento,
    required this.cerrada,
    required this.requiereClave,
    required this.clave,
    required this.idRuta,
    required this.tienePedido,
    this.idCerrada = 1,
  });

  final int id;
  final String descripcion;
  final String tipoCalle;
  final int idCalle;
  final String calle;
  final String numeroInterior;
  final String numeroExterior;
  final int idColonia;
  final String colonia;
  final int idCiudad;
  final String ciudad;
  final int idEstado;
  final String estado;
  final int idZona;
  final String zona;
  final int idCodigoPostal;
  final String codigoPostal;
  final String referencias;
  final bool activa;
  final double latitud;
  final double longitud;
  final String observaciones;
  final String entreCalle1;
  final String entreCalle2;
  final String entreCalle3;
  final int idSegmento;
  final int idCerrada;
  final String cerrada;
  final bool requiereClave;
  final String clave;
  final int idRuta;
  final bool tienePedido;

  String get etiqueta =>
      descripcion.trim().isEmpty ? 'Domicilio en $colonia' : descripcion;
  String get calleCompleta {
    final segmento =
        idSegmento <= 1 || cerrada.trim().isEmpty ? '' : ', $cerrada';
    return '${tipoCalle.trim()} ${calle.trim()} ${numeroExterior.trim()}$segmento'
        .trim();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'descripcion': descripcion,
    'tipoCalle': tipoCalle,
    'idCalle': idCalle,
    'calle': calle,
    'numeroInterior': numeroInterior,
    'numeroExterior': numeroExterior,
    'idColonia': idColonia,
    'colonia': colonia,
    'idCiudad': idCiudad,
    'ciudad': ciudad,
    'idEstado': idEstado,
    'estado': estado,
    'idZona': idZona,
    'zona': zona,
    'idCodigoPostal': idCodigoPostal,
    'codigoPostal': codigoPostal,
    'referencias': referencias,
    'activa': activa,
    'latitud': latitud,
    'longitud': longitud,
    'observaciones': observaciones,
    'entreCalle1': entreCalle1,
    'entreCalle2': entreCalle2,
    'entreCalle3': entreCalle3,
    'idSegmento': idSegmento,
    'idCerrada': idCerrada,
    'cerrada': cerrada,
    'requiereClave': requiereClave,
    'clave': clave,
    'idRuta': idRuta,
    'tienePedido': tienePedido,
  };

  factory Direccion.fromJson(Map<String, dynamic> json) => Direccion(
    id: _int(json['id']),
    descripcion: _text(json['descripcion']),
    tipoCalle: _text(json['tipoCalle']),
    idCalle: _int(json['idCalle']),
    calle: _text(json['calle']),
    numeroInterior: _text(json['numeroInterior']),
    numeroExterior: _text(json['numeroExterior']),
    idColonia: _int(json['idColonia']),
    colonia: _text(json['colonia']),
    idCiudad: _int(json['idCiudad']),
    ciudad: _text(json['ciudad']),
    idEstado: _int(json['idEstado']),
    estado: _text(json['estado']),
    idZona: _int(json['idZona']),
    zona: _text(json['zona']),
    idCodigoPostal: _int(json['idCodigoPostal']),
    codigoPostal: _text(json['codigoPostal']),
    referencias: _text(json['referencias']),
    activa: _bool(json['activa']),
    latitud: _double(json['latitud']),
    longitud: _double(json['longitud']),
    observaciones: _text(json['observaciones']),
    entreCalle1: _text(json['entreCalle1']),
    entreCalle2: _text(json['entreCalle2']),
    entreCalle3: _text(json['entreCalle3']),
    idSegmento: _int(json['idSegmento']),
    idCerrada: _int(json['idCerrada'], 1),
    cerrada: _text(json['cerrada']),
    requiereClave: _bool(json['requiereClave']),
    clave: _text(json['clave']),
    idRuta: _int(json['idRuta']),
    tienePedido: _bool(json['tienePedido']),
  );

  static int _int(Object? value, [int fallback = 0]) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? fallback;
  static double _double(Object? value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
  static bool _bool(Object? value) =>
      value == true || value == 1 || '$value'.toLowerCase() == 'true';
  static String _text(Object? value) =>
      value == null || value == 'null' ? '' : '$value';
}
