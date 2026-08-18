import '../../../core/constants/service_endpoints.dart';
import '../../../core/constants/soap_constants.dart';
import '../../../core/network/soap_service.dart';
import '../models/login_result.dart';
import '../models/register_request.dart';
import '../models/register_result.dart';
import '../models/verification_request.dart';
import '../models/verification_result.dart';
import 'login_soap_parser.dart';
import 'registration_soap_parser.dart';
import 'verification_soap_parser.dart';

abstract interface class ClientesService {
  Future<LoginResult> login({
    required String telefono,
    required String contrasena,
  });
}

abstract interface class RegistrationClientesService {
  Future<RegisterResult> validateRegistration(RegisterRequest request);

  Future<RegisterResult> registerDirect({
    required RegisterRequest request,
    required int? customerKey,
    required int? phoneKey,
  });

  Future<VerificationResult> verifyAccount(VerificationRequest request);

  Future<ResendCodeResult> resendCode(int accountKey);
}

final class ClientesSoapService
    implements ClientesService, RegistrationClientesService {
  ClientesSoapService({
    SoapService? soapService,
    LoginSoapParser? loginParser,
    RegistrationSoapParser? registrationParser,
    VerificationSoapParser? verificationParser,
    Uri? endpoint,
  }) : _soapService = soapService ?? SoapService(),
       _loginParser = loginParser ?? const LoginSoapParser(),
       _registrationParser =
           registrationParser ?? const RegistrationSoapParser(),
       _verificationParser =
           verificationParser ?? const VerificationSoapParser(),
       _endpoint = endpoint;

  final SoapService _soapService;
  final LoginSoapParser _loginParser;
  final RegistrationSoapParser _registrationParser;
  final VerificationSoapParser _verificationParser;
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

  @override
  Future<RegisterResult> validateRegistration(RegisterRequest request) async {
    final response = await _soapService.call(
      endpoint: _endpoint ?? ServiceEndpoints.clientes,
      namespace: SoapConstants.namespace,
      methodName: ClientesSoapMethods.registroValidacion,
      parameters: {
        '_strNombre': request.nombre,
        '_strTelefono': request.telefono,
        '_strContrasena': request.contrasena,
      },
    );
    return _registrationParser.parseValidation(response);
  }

  @override
  Future<RegisterResult> registerDirect({
    required RegisterRequest request,
    required int? customerKey,
    required int? phoneKey,
  }) async {
    final response = await _soapService.call(
      endpoint: _endpoint ?? ServiceEndpoints.clientes,
      namespace: SoapConstants.namespace,
      methodName: ClientesSoapMethods.registroDirecto,
      parameters: {
        '_intClave': customerKey,
        '_strNombre': request.nombre,
        '_strTelefono': request.telefono,
        '_strContrasena': request.contrasena,
        '_intClaveTelefono': phoneKey,
      },
    );
    return _registrationParser.parseDirect(response);
  }

  @override
  Future<VerificationResult> verifyAccount(VerificationRequest request) async {
    final response = await _soapService.call(
      endpoint: _endpoint ?? ServiceEndpoints.clientes,
      namespace: SoapConstants.namespace,
      methodName: ClientesSoapMethods.activarCuenta,
      parameters: {
        '_intClaveUsuario': request.accountKey,
        '_strCodigoVerif': request.code,
      },
    );
    return _verificationParser.parseVerification(response);
  }

  @override
  Future<ResendCodeResult> resendCode(int accountKey) async {
    final response = await _soapService.call(
      endpoint: _endpoint ?? ServiceEndpoints.clientes,
      namespace: SoapConstants.namespace,
      methodName: ClientesSoapMethods.reenviarCodigo,
      parameters: {'_intClaveUsuario': accountKey},
    );
    return _verificationParser.parseResend(response);
  }

  void close() => _soapService.close();
}
