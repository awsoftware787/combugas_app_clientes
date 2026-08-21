import 'package:xml/xml.dart';

import '../../../core/network/network_exception.dart';
import '../models/password_recovery_result.dart';

final class PasswordRecoverySoapParser {
  const PasswordRecoverySoapParser();

  PasswordRecoveryResult parse(XmlDocument document) {
    try {
      final result = _element(document, 'recuperarContrasenaResult');
      final succeeded = _text(result, 'Result').toLowerCase() == 'true';
      final message = _text(result, 'Message').toUpperCase();

      if (succeeded && message == 'RECUPERAOK') {
        return const PasswordRecoverySuccess();
      }
      if (succeeded) return const PasswordRecoveryPhoneNotFound();
      return const PasswordRecoveryFailure(
        'Ha ocurrido un error al procesar su solicitud. Para recuperar su '
        'contraseña, llame a call center COMBUGAS.',
      );
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
}
