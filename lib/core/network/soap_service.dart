import 'package:xml/xml.dart';

import 'soap_http_client.dart';
import 'soap_request_builder.dart';
import 'soap_response_parser.dart';

final class SoapService {
  SoapService({
    SoapHttpClient? httpClient,
    SoapRequestBuilder? requestBuilder,
    SoapResponseParser? responseParser,
  }) : _httpClient = httpClient ?? SoapHttpClient(),
       _requestBuilder = requestBuilder ?? const SoapRequestBuilder(),
       _responseParser = responseParser ?? const SoapResponseParser();

  final SoapHttpClient _httpClient;
  final SoapRequestBuilder _requestBuilder;
  final SoapResponseParser _responseParser;

  Future<XmlDocument> call({
    required Uri endpoint,
    required String namespace,
    required String methodName,
    Map<String, Object?> parameters = const {},
  }) async {
    final request = _requestBuilder.build(
      methodName: methodName,
      namespace: namespace,
      parameters: parameters,
    );
    final response = await _httpClient.post(
      endpoint: endpoint,
      soapAction: '$namespace$methodName',
      body: request,
    );
    return _responseParser.parse(response);
  }

  void close() => _httpClient.close();
}
