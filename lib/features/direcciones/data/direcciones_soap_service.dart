import '../../../core/constants/service_endpoints.dart';
import '../../../core/constants/soap_constants.dart';
import '../../../core/network/soap_service.dart';
import '../models/catalogos_direccion.dart';
import '../models/direccion.dart';
import '../models/direccion_request.dart';
import '../../carburaciones/models/carburacion.dart';
import 'direcciones_soap_parser.dart';

abstract interface class DireccionesService {
  Future<List<Direccion>> getDirecciones(int clienteId);
  Future<Direccion> getDireccion(int direccionId);
  Future<List<Colonia>> getColonias();
  Future<List<Calle>> getCalles(int coloniaId);
  Future<List<Cerrada>> getCerradas(int coloniaId);
  Future<List<Carburacion>> getCarburaciones();
  Future<DireccionOperationResult> guardar(
    int clienteId,
    DireccionRequest request,
  );
  Future<DireccionOperationResult> actualizar(
    int direccionId,
    DireccionRequest request,
  );
  Future<DireccionOperationResult> desactivar(int direccionId, int clienteId);
}

final class DireccionesSoapService implements DireccionesService {
  DireccionesSoapService({
    SoapService? soapService,
    DireccionesSoapParser? parser,
    Uri? endpoint,
  }) : _soap = soapService ?? SoapService(),
       _parser = parser ?? const DireccionesSoapParser(),
       _endpoint = endpoint;
  final SoapService _soap;
  final DireccionesSoapParser _parser;
  final Uri? _endpoint;
  Uri get endpoint => _endpoint ?? ServiceEndpoints.direcciones;

  @override
  Future<List<Direccion>> getDirecciones(int clienteId) async =>
      _parser.parseDirecciones(
        await _call(DireccionesSoapMethods.obtenerTodas, {
          '_intClaveCliente': clienteId,
        }),
        DireccionesSoapMethods.obtenerTodas,
      );

  @override
  Future<Direccion> getDireccion(int direccionId) async =>
      _parser.parseDireccion(
        await _call(DireccionesSoapMethods.obtenerUna, {
          '_intClaveDireccion': direccionId,
        }),
      );

  @override
  Future<List<Colonia>> getColonias() async => _parser.parseColonias(
    await _call(DireccionesSoapMethods.obtenerColonias),
  );
  @override
  Future<List<Calle>> getCalles(int coloniaId) async => _parser.parseCalles(
    await _call(DireccionesSoapMethods.obtenerCalles, {
      '_intIdColonia': coloniaId,
    }),
  );
  @override
  Future<List<Cerrada>> getCerradas(int coloniaId) async =>
      _parser.parseCerradas(
        await _call(DireccionesSoapMethods.obtenerCerradas, {
          '_intIdColonia': coloniaId,
        }),
      );

  @override
  Future<List<Carburacion>> getCarburaciones() async =>
      _parser.parseCarburaciones(
        await _call(DireccionesSoapMethods.obtenerCarburaciones),
      );

  @override
  Future<DireccionOperationResult> guardar(
    int clienteId,
    DireccionRequest request,
  ) async => _parser.parseOperation(
    await _call(
      DireccionesSoapMethods.guardar,
      _requestParameters(request, clienteId: clienteId),
    ),
    DireccionesSoapMethods.guardar,
  );
  @override
  Future<DireccionOperationResult> actualizar(
    int direccionId,
    DireccionRequest request,
  ) async => _parser.parseOperation(
    await _call(
      DireccionesSoapMethods.actualizar,
      _requestParameters(request, direccionId: direccionId),
    ),
    DireccionesSoapMethods.actualizar,
  );
  @override
  Future<DireccionOperationResult> desactivar(
    int direccionId,
    int clienteId,
  ) async => _parser.parseOperation(
    await _call(DireccionesSoapMethods.desactivar, {
      '_idDireccion': direccionId,
      '_idCliente': clienteId,
    }),
    DireccionesSoapMethods.desactivar,
  );

  Map<String, Object?> _requestParameters(
    DireccionRequest request, {
    int? clienteId,
    int? direccionId,
  }) => {
    if (clienteId != null) '_intClaveCliente': clienteId,
    if (direccionId != null) '_intClaveDireccion': direccionId,
    '_strDescripcionDireccion': request.descripcion,
    '_intClaveColonia': request.idColonia,
    '_intIdCerrada': request.idCerrada,
    '_intClaveCalle': request.idCalle,
    '_strNumero': request.numero,
    '_strCodigoP': 'SIN CODIGO',
    '_dblLatitud': request.latitud,
    '_dblLongitud': request.longitud,
  };

  Future<dynamic> _call(
    String method, [
    Map<String, Object?> parameters = const {},
  ]) => _soap.call(
    endpoint: endpoint,
    namespace: SoapConstants.namespace,
    methodName: method,
    parameters: parameters,
  );
  void close() => _soap.close();
}
