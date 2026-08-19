import 'dart:convert';

import 'package:xml/xml.dart';

import '../../../core/network/network_exception.dart';
import '../models/producto.dart';

final class PedidosSoapParser {
  const PedidosSoapParser();

  List<Producto> parsePrecios(XmlDocument document) {
    final payload = _response(document, 'getPrecios');
    if (!payload.succeeded) throw WebServiceException(payload.message);
    return _list(payload.data)
        .map(
          (item) => Producto(
            id: _int(item['_idProducto']),
            descripcion: _text(item['_descripcionProducto']),
            presentacion: _text(
              item['_presentacionProducto'] ?? item['_descripcionProducto'],
            ),
            servicioId: _int(item['_idServicio']),
            precioCentavos: (_double(item['_precioProducto']) * 100).round(),
          ),
        )
        .toList(growable: false);
  }

  MontosMinimos parseMontosMinimos(XmlDocument document) {
    final payload = _response(document, 'getMontosMinimos');
    if (!payload.succeeded) throw WebServiceException(payload.message);
    final values = _list(payload.data);
    if (values.isEmpty) throw const InvalidSoapResponseException();
    return MontosMinimos(
      dineroCentavos:
          (_double(values.first['montominimo_dinero']) * 100).round(),
      litros: _double(values.first['montominimo_litros']),
    );
  }

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
      final decoded = value.trim().isEmpty ? <dynamic>[] : jsonDecode(value);
      if (decoded is! List) throw const FormatException();
      return decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(growable: false);
    } catch (error) {
      throw InvalidSoapResponseException(error);
    }
  }

  int _int(Object? value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;
  double _double(Object? value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
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
