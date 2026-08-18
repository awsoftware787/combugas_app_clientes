import 'dart:convert';

import 'package:xml/xml.dart';

import '../../../core/network/network_exception.dart';
import '../models/register_result.dart';

final class RegistrationSoapParser {
  const RegistrationSoapParser();

  RegisterResult parseValidation(XmlDocument document) {
    try {
      final result = _element(document, 'registroClienteValidacionResult');
      final succeeded = _text(result, 'Result').toLowerCase() == 'true';
      final message = _text(result, 'Message');
      final data = _text(result, 'Data');

      if (!succeeded) {
        return const RegisterFailure(
          'Ha ocurrido un error, inténtelo más tarde',
        );
      }
      if (message == 'OK') return RegisterCreated(int.parse(data));
      if (message != 'EX') {
        return const RegisterFailure(
          'Ha ocurrido un error, inténtelo más tarde',
        );
      }

      final decoded = jsonDecode(data);
      if (decoded is! List || decoded.isEmpty || decoded.first is! Map) {
        throw const InvalidSoapResponseException();
      }
      final payload = Map<String, dynamic>.from(decoded.first as Map);
      final rawAddresses = payload['_cDireccion'];
      final addresses = <String>[];
      if (rawAddresses is List) {
        for (final address in rawAddresses) {
          if (address is Map && address['_descrDireccion'] != null) {
            addresses.add(address['_descrDireccion'].toString());
          }
        }
      }

      final customer = CustomerMatch(
        customerKey: _int(payload, '_cCliente'),
        name: payload['_cNombre']?.toString() ?? '',
        phoneKey: _int(payload, '_cIdTelefono'),
        addresses: List.unmodifiable(addresses),
        hasAccount: _optionalInt(payload, '_cuenta') != 0,
      );
      return customer.hasAccount
          ? RegisterExistingAccount(customer)
          : RegisterIdentityMatch(customer);
    } on RegisterFailure {
      rethrow;
    } on InvalidSoapResponseException {
      rethrow;
    } catch (error) {
      throw InvalidSoapResponseException(error);
    }
  }

  RegisterResult parseDirect(XmlDocument document) {
    try {
      final result = _element(document, 'registroClienteDirectoResult');
      final succeeded = _text(result, 'Result').toLowerCase() == 'true';
      if (!succeeded) {
        return const RegisterFailure(
          'Ocurrió un error, inténtelo nuevamente más tarde',
        );
      }
      return RegisterCreated(int.parse(_text(result, 'Data')));
    } on RegisterFailure {
      rethrow;
    } on InvalidSoapResponseException {
      rethrow;
    } catch (error) {
      throw InvalidSoapResponseException(error);
    }
  }

  XmlElement _element(XmlNode parent, String localName) {
    return parent.descendants.whereType<XmlElement>().firstWhere(
      (element) => element.name.local == localName,
      orElse: () => throw const InvalidSoapResponseException(),
    );
  }

  String _text(XmlNode parent, String localName) {
    return _element(parent, localName).innerText.trim();
  }

  int _int(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value is num) return value.toInt();
    return int.parse(value.toString());
  }

  int _optionalInt(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value == null) return 0;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}
