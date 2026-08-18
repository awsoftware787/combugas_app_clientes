import 'package:xml/xml.dart';

import '../../../core/network/network_exception.dart';
import '../models/verification_result.dart';

final class VerificationSoapParser {
  const VerificationSoapParser();

  VerificationResult parseVerification(XmlDocument document) {
    try {
      final result = _element(document, 'verificarCuentaResult');
      final succeeded = _text(result, 'Result').toLowerCase() == 'true';
      return succeeded
          ? const VerificationSuccess()
          : const VerificationInvalidCode();
    } on InvalidSoapResponseException {
      rethrow;
    } catch (error) {
      throw InvalidSoapResponseException(error);
    }
  }

  ResendCodeResult parseResend(XmlDocument document) {
    try {
      final result = _element(document, 'reenviarCodigoResult');
      final succeeded = _text(result, 'Result').toLowerCase() == 'true';
      final message = _text(result, 'Message');
      if (succeeded && message == 'OK') return const ResendCodeSuccess();
      return const ResendCodeFailure(
        'No se ha podido reenviar la información solicitada, revise su '
        'conexión e inténtelo nuevamente',
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
