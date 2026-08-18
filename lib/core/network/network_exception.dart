sealed class NetworkException implements Exception {
  const NetworkException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

final class NoConnectionException extends NetworkException {
  const NoConnectionException([Object? cause])
    : super('No fue posible conectarse al servidor.', cause);
}

final class NetworkTimeoutException extends NetworkException {
  const NetworkTimeoutException([Object? cause])
    : super('La solicitud excedió el tiempo de espera.', cause);
}

final class InvalidHttpResponseException extends NetworkException {
  const InvalidHttpResponseException(this.statusCode, this.responseBody)
    : super('El servidor respondió con HTTP $statusCode.');

  final int statusCode;
  final String responseBody;
}

final class InvalidSoapResponseException extends NetworkException {
  const InvalidSoapResponseException([Object? cause])
    : super('La respuesta SOAP no tiene un formato válido.', cause);
}

final class WebServiceException extends NetworkException {
  const WebServiceException(super.message, [super.cause]);
}

final class UnexpectedNetworkException extends NetworkException {
  const UnexpectedNetworkException([Object? cause])
    : super('Ocurrió un error de red inesperado.', cause);
}
