import '../../../core/constants/service_endpoints.dart';
import '../../../core/constants/soap_constants.dart';
import '../../../core/network/soap_service.dart';
import '../models/login_result.dart';
import 'login_soap_parser.dart';

abstract interface class ClientesService {
  Future<LoginResult> login({
    required String telefono,
    required String contrasena,
  });
}

final class ClientesSoapService implements ClientesService {
  ClientesSoapService({
    SoapService? soapService,
    LoginSoapParser? loginParser,
    Uri? endpoint,
  }) : _soapService = soapService ?? SoapService(),
       _loginParser = loginParser ?? const LoginSoapParser(),
       _endpoint = endpoint;

  final SoapService _soapService;
  final LoginSoapParser _loginParser;
  final Uri? _endpoint;

  @override
  Future<LoginResult> login({
    required String telefono,
    required String contrasena,
  }) async {
    final response = await _soapService.call(
      endpoint: _endpoint ?? ServiceEndpoints.clientes,
      namespace: SoapConstants.namespace,
      methodName: ClientesSoapMethods.login,
      parameters: {'_strTelefono': telefono, '_strContrasena': contrasena},
    );
    return _loginParser.parse(response);
  }

  void close() => _soapService.close();
}
