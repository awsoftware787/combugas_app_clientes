import 'package:xml/xml.dart';

import 'network_exception.dart';

final class SoapResponseParser {
  const SoapResponseParser();

  XmlDocument parse(String responseBody) {
    try {
      final document = XmlDocument.parse(responseBody);
      final faults = document.descendants.whereType<XmlElement>().where(
        (element) => element.name.local == 'Fault',
      );

      if (faults.isNotEmpty) {
        final fault = faults.first;
        final messages = fault.descendants.whereType<XmlElement>().where(
          (element) => element.name.local == 'faultstring',
        );
        final message = messages.isEmpty ? '' : messages.first.innerText.trim();
        throw WebServiceException(
          message.isNotEmpty
              ? message
              : 'El WebService devolvió un error SOAP.',
        );
      }

      return document;
    } on WebServiceException {
      rethrow;
    } on XmlParserException catch (error) {
      throw InvalidSoapResponseException(error);
    } catch (error) {
      throw InvalidSoapResponseException(error);
    }
  }
}
