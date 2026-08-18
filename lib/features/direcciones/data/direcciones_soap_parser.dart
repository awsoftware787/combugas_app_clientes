import 'dart:convert';

import 'package:xml/xml.dart';

import '../../../core/network/network_exception.dart';
import '../models/catalogos_direccion.dart';
import '../models/direccion.dart';
import '../models/direccion_request.dart';

final class DireccionesSoapParser {
  const DireccionesSoapParser();

  List<Direccion> parseDirecciones(XmlDocument document, String method) {
    final response = _response(document, method);
    if (!response.succeeded) throw WebServiceException(response.message);
    return _list(response.data).map(_direccion).toList(growable: false);
  }

  Direccion parseDireccion(XmlDocument document) {
    final addresses = parseDirecciones(document, 'getUnaDireccion');
    if (addresses.isEmpty) throw const InvalidSoapResponseException();
    return addresses.first;
  }

  List<Colonia> parseColonias(XmlDocument document) {
    final response = _response(document, 'getColonias');
    if (!response.succeeded) throw WebServiceException(response.message);
    return _list(response.data)
        .map(
          (item) => Colonia(
            id: _int(item['_idColonia']),
            descripcion: _text(item['_descrColonia']),
            idCiudad: _int(item['_idCiudad']),
            ciudad: _text(item['_descrCiudad']),
            idEstado: _int(item['_idEstado']),
            estado: _text(item['_descrEstado']),
          ),
        )
        .toList(growable: false);
  }

  List<Calle> parseCalles(XmlDocument document) => _simpleCatalog(
    document,
    'getCalles',
    '_idCalle',
    '_descrCalle',
    (id, description) => Calle(id: id, descripcion: description),
  );

  List<Cerrada> parseCerradas(XmlDocument document) => _simpleCatalog(
    document,
    'getCerradas',
    '_idCerrada',
    '_descripcionCerrada',
    (id, description) => Cerrada(id: id, descripcion: description),
  );

  DireccionOperationResult parseOperation(XmlDocument document, String method) {
    final response = _response(document, method);
    return DireccionOperationResult(
      succeeded: response.succeeded,
      message: response.message,
    );
  }

  List<T> _simpleCatalog<T>(
    XmlDocument document,
    String method,
    String idKey,
    String descriptionKey,
    T Function(int, String) create,
  ) {
    final response = _response(document, method);
    if (!response.succeeded) throw WebServiceException(response.message);
    return _list(response.data)
        .map((item) => create(_int(item[idKey]), _text(item[descriptionKey])))
        .toList(growable: false);
  }

  Direccion _direccion(Map<String, dynamic> item) => Direccion(
    id: _int(item['_id_direccion']),
    descripcion: _text(item['_descr_direccion']),
    tipoCalle: _text(item['_descr_tipo_calle']),
    idCalle: _int(item['_id_calle']),
    calle: _text(item['_descr_calle']),
    numeroInterior: _text(item['_no_interior']),
    numeroExterior: _text(item['_no_exterior']),
    idColonia: _int(item['_id_colonia']),
    colonia: _text(item['_descr_colonia']),
    idCiudad: _int(item['_id_ciudad']),
    ciudad: _text(item['_descr_ciudad']),
    idEstado: _int(item['_id_estado']),
    estado: _text(item['_descr_estado']),
    idZona: _int(item['_id_zona']),
    zona: _text(item['_descr_zona']),
    idCodigoPostal: _int(item['_id_cp']),
    codigoPostal: _text(item['_descr_cp']),
    referencias: _text(item['_referencias']),
    activa: _bool(item['_status']),
    latitud: _double(item['_latitud']),
    longitud: _double(item['_longitud']),
    observaciones: _text(item['_observaciones']),
    entreCalle1: _text(item['_entre_1']),
    entreCalle2: _text(item['_entre_2']),
    entreCalle3: _text(item['_entre_3']),
    idSegmento: _int(item['_id_segmento']),
    idCerrada: _int(item['_id_cerrada'], _int(item['_id_segmento'], 1)),
    cerrada: _text(item['_decr_cerrada'] ?? item['_descripcion_cerrada']),
    requiereClave: _bool(item['_req_clave']),
    clave: _text(item['_clave']),
    idRuta: _int(item['_id_ruta']),
    tienePedido: _bool(item['_tienePedido']),
  );

  _SoapPayload _response(XmlDocument document, String method) {
    try {
      final result = document.descendants.whereType<XmlElement>().firstWhere(
        (element) => element.name.local == '${method}Result',
      );
      String value(String name) =>
          result.descendants
              .whereType<XmlElement>()
              .firstWhere((element) => element.name.local == name)
              .innerText
              .trim();
      return _SoapPayload(
        succeeded: value('Result').toLowerCase() == 'true',
        message: value('Message'),
        data: value('Data'),
      );
    } catch (error) {
      throw InvalidSoapResponseException(error);
    }
  }

  List<Map<String, dynamic>> _list(String value) {
    try {
      if (value.trim().isEmpty) return const [];
      final decoded = jsonDecode(value);
      if (decoded is! List) throw const FormatException();
      return decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (error) {
      throw InvalidSoapResponseException(error);
    }
  }

  int _int(Object? value, [int fallback = 0]) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? fallback;
  double _double(Object? value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
  bool _bool(Object? value) =>
      value == true || value == 1 || '$value'.toLowerCase() == 'true';
  String _text(Object? value) =>
      value == null || value == 'null' ? '' : '$value';
}

final class _SoapPayload {
  const _SoapPayload({
    required this.succeeded,
    required this.message,
    required this.data,
  });
  final bool succeeded;
  final String message;
  final String data;
}
