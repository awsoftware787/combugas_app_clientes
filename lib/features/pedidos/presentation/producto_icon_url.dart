import '../../../core/constants/service_endpoints.dart';

/// Compatibilidad centralizada para URLs de desarrollo devueltas como localhost.
/// El arreglo definitivo debe realizarse en el Web Service.
String? normalizeProductoIconUrl(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return null;
  final remote = Uri.tryParse(text);
  if (remote == null || !remote.hasScheme || remote.host.isEmpty) return null;
  if (remote.host != 'localhost' &&
      remote.host != '127.0.0.1' &&
      remote.host != '::1') {
    return remote.toString();
  }
  try {
    final base = Uri.parse(ServiceEndpoints.baseUrl);
    if (base.host.isEmpty) return remote.toString();
    return Uri(
      scheme: base.scheme,
      userInfo: base.userInfo,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: remote.path,
      query: remote.hasQuery ? remote.query : null,
      fragment: remote.hasFragment ? remote.fragment : null,
    ).toString();
  } catch (_) {
    return remote.toString();
  }
}
