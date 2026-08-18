import 'package:xml/xml.dart';

final class SoapRequestBuilder {
  const SoapRequestBuilder();

  String build({
    required String methodName,
    required String namespace,
    Map<String, Object?> parameters = const {},
  }) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="utf-8"');
    builder.element(
      'soap:Envelope',
      attributes: {
        'xmlns:xsi': 'http://www.w3.org/2001/XMLSchema-instance',
        'xmlns:xsd': 'http://www.w3.org/2001/XMLSchema',
        'xmlns:soap': 'http://schemas.xmlsoap.org/soap/envelope/',
      },
      nest: () {
        builder.element(
          'soap:Body',
          nest: () {
            builder.element(
              methodName,
              attributes: {'xmlns': namespace},
              nest: () {
                for (final parameter in parameters.entries) {
                  if (parameter.value == null) {
                    builder.element(
                      parameter.key,
                      attributes: {'xsi:nil': 'true'},
                    );
                  } else {
                    builder.element(parameter.key, nest: parameter.value);
                  }
                }
              },
            );
          },
        );
      },
    );
    return builder.buildDocument().toXmlString();
  }
}
