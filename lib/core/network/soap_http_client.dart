import 'dart:async';

import 'package:http/http.dart' as http;

import 'network_config.dart';
import 'network_exception.dart';

final class SoapHttpClient {
  SoapHttpClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<String> post({
    required Uri endpoint,
    required String soapAction,
    required String body,
  }) async {
    try {
      final response = await _client
          .post(
            endpoint,
            headers: {
              'Content-Type': 'text/xml; charset=utf-8',
              'SOAPAction': soapAction,
            },
            body: body,
          )
          .timeout(NetworkConfig.requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw InvalidHttpResponseException(response.statusCode, response.body);
      }

      return response.body;
    } on NetworkException {
      rethrow;
    } on TimeoutException catch (error) {
      throw NetworkTimeoutException(error);
    } on http.ClientException catch (error) {
      throw NoConnectionException(error);
    } catch (error) {
      throw UnexpectedNetworkException(error);
    }
  }

  void close() => _client.close();
}
