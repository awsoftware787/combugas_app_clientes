import 'dart:convert';

import 'package:xml/xml.dart';

import '../../../core/network/network_exception.dart';
import '../models/perfil_cliente.dart';

final class PerfilSoapParser {
  const PerfilSoapParser();

  PerfilCliente parsePerfil(XmlDocument document) {
    final response = _response(document, 'traerInfoCliente');
    if (!response.succeeded) throw WebServiceException(response.message);
    try {
      final decoded = jsonDecode(response.data);
      if (decoded is! Map) throw const FormatException();
      final data = Map<String, dynamic>.from(decoded);
      return PerfilCliente(
        nombre: _text(data['_nombre']),
        telefono: _text(data['_telefono']),
        correo: _nullableText(data['_correo']),
        cantidadDirecciones: _int(data['_tieneDireccion']),
      );
    } catch (error) {
      throw InvalidSoapResponseException(error);
    }
  }

  PerfilOperationResult parseOperation(XmlDocument document, String method) {
    final response = _response(document, method);
    return PerfilOperationResult(
      succeeded: response.succeeded,
      message: response.message,
    );
  }

  _PerfilPayload _response(XmlDocument document, String method) {
    try {
      final result = document.descendants.whereType<XmlElement>().firstWhere(
        (element) => element.name.local == '${method}Result',
      );
      String requiredValue(String name) =>
          result.descendants
              .whereType<XmlElement>()
              .firstWhere((element) => element.name.local == name)
              .innerText
              .trim();
      String optionalValue(String name) {
        final matches = result.descendants.whereType<XmlElement>().where(
          (element) => element.name.local == name,
        );
        return matches.isEmpty ? '' : matches.first.innerText.trim();
      }

      return _PerfilPayload(
        succeeded: requiredValue('Result').toLowerCase() == 'true',
        message: optionalValue('Message'),
        data: optionalValue('Data'),
      );
    } catch (error) {
      throw InvalidSoapResponseException(error);
    }
  }

  int _int(Object? value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;
  String _text(Object? value) =>
      value == null || '$value'.toLowerCase() == 'null' ? '' : '$value';
  String? _nullableText(Object? value) {
    final text = _text(value).trim();
    return text.isEmpty ? null : text;
  }
}

final class _PerfilPayload {
  const _PerfilPayload({
    required this.succeeded,
    required this.message,
    required this.data,
  });

  final bool succeeded;
  final String message;
  final String data;
}
