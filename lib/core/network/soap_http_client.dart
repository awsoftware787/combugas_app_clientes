import 'dart:async';

import 'package:flutter/foundation.dart';
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
    bool logExchange = false,
  }) async {
    try {
      if (kDebugMode && logExchange) {
        debugPrint('Request confirmación pedido: $body');
        debugPrint('SOAP endpoint: $endpoint');
        debugPrint('SOAPAction: $soapAction');
      }
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

      if (kDebugMode && logExchange) {
        debugPrint(
          'Response confirmación pedido statusCode: '
          '${response.statusCode}',
        );
        debugPrint('Response confirmación pedido body: ${response.body}');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw InvalidHttpResponseException(response.statusCode, response.body);
      }

      return response.body;
    } on NetworkException catch (error, stackTrace) {
      if (kDebugMode && logExchange) {
        debugPrint('Exception confirmación pedido: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      rethrow;
    } on TimeoutException catch (error) {
      if (kDebugMode && logExchange) {
        debugPrint('Exception confirmación pedido: $error');
      }
      throw NetworkTimeoutException(error);
    } on http.ClientException catch (error) {
      if (kDebugMode && logExchange) {
        debugPrint('Exception confirmación pedido: $error');
      }
      throw NoConnectionException(error);
    } catch (error, stackTrace) {
      if (kDebugMode && logExchange) {
        debugPrint('Exception confirmación pedido: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      throw UnexpectedNetworkException(error);
    }
  }

  void close() => _client.close();
}
