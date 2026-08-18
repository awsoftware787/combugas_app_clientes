import 'dart:convert';

import 'package:xml/xml.dart';

import '../../../core/network/network_exception.dart';
import '../models/login_result.dart';
import '../models/session_data.dart';

final class LoginSoapParser {
  const LoginSoapParser();

  LoginResult parse(XmlDocument document) {
    try {
      final loginResult = _element(document, 'loginResult');
      final succeeded = _text(loginResult, 'Result').toLowerCase() == 'true';
      final message = _text(loginResult, 'Message');
      final data = _text(loginResult, 'Data');

      if (succeeded && message == 'LOG') {
        final payload = _jsonObject(data);
        if (_int(payload, '_mercado') != 1) {
          return const LoginInstitutionalAccount();
        }
        if (_bool(payload, '_bloqueado')) {
          return LoginBlockedAccount(
            payload['_motivo_bloqueado']?.toString() ?? '',
          );
        }

        return LoginSuccess(
          session: SessionData(
            claveUsuario: _int(payload, '_clave'),
            nombreUsuario: payload['_nombre'] as String,
            claveTelefono: _int(payload, '_telefono'),
            subcanalUsuario: _int(payload, '_subCanal'),
          ),
          hasAddress: _int(payload, '_tieneDireccion') > 0,
        );
      }

      if (succeeded && message == 'NACT') {
        return LoginInactiveAccount(_int(_jsonObject(data), '_claveApp'));
      }

      if (message == 'NOTLOG') {
        return const LoginInvalidCredentials();
      }

      return const LoginServiceFailure(
        'No fue posible iniciar sesión. Inténtalo nuevamente.',
      );
    } on LoginServiceFailure {
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

  Map<String, dynamic> _jsonObject(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) {
      throw const InvalidSoapResponseException();
    }
    return decoded;
  }

  int _int(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.parse(value.toString());
  }

  bool _bool(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value is bool) return value;
    return value.toString().toLowerCase() == 'true';
  }
}
