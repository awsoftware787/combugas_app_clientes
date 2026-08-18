import 'app_environment.dart';

final class ServiceEndpoints {
  ServiceEndpoints._();

  static const _devBaseUrl = String.fromEnvironment('SERVICE_BASE_URL_DEV');
  static const _testBaseUrl = String.fromEnvironment('SERVICE_BASE_URL_TEST');
  static const _prodBaseUrl = String.fromEnvironment('SERVICE_BASE_URL_PROD');

  static String get baseUrl => switch (currentEnvironment) {
    AppEnvironment.dev => _devBaseUrl,
    AppEnvironment.test => _testBaseUrl,
    AppEnvironment.prod => _prodBaseUrl,
  };

  static Uri get clientes => _serviceUri('ws/clientes.asmx');
  static Uri get direcciones => _serviceUri('ws/direcciones.asmx');
  static Uri get pedidos => _serviceUri('ws/pedidos.asmx');

  static Uri _serviceUri(String service) {
    if (baseUrl.trim().isEmpty) {
      throw StateError(
        'No se configuró la URL base para el ambiente '
        '${currentEnvironment.name}.',
      );
    }

    final normalizedBase = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    return Uri.parse(normalizedBase).resolve(service);
  }
}
