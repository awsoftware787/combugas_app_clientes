import 'package:combugas_clientes/core/network/network_exception.dart';
import 'package:combugas_clientes/features/auth/data/auth_repository.dart';
import 'package:combugas_clientes/features/auth/models/login_result.dart';
import 'package:combugas_clientes/features/auth/models/session_data.dart';
import 'package:combugas_clientes/features/direcciones/controllers/direccion_controller.dart';
import 'package:combugas_clientes/features/direcciones/data/direccion_repository.dart';
import 'package:combugas_clientes/features/direcciones/models/catalogos_direccion.dart';
import 'package:combugas_clientes/features/direcciones/models/direccion.dart';
import 'package:combugas_clientes/features/direcciones/models/direccion_request.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('load pasa por loading, selecciona la primera y la persiste', () async {
    final repository = _FakeDirectionsRepository(directions: [address]);
    final container = _container(repository);
    addTearDown(container.dispose);
    final future = container.read(direccionControllerProvider.notifier).load();
    expect(
      container.read(direccionControllerProvider).status,
      DireccionStatus.loading,
    );
    await future;
    final state = container.read(direccionControllerProvider);
    expect(state.status, DireccionStatus.ready);
    expect(state.selected?.id, 9);
    expect(repository.selected?.id, 9);
  });

  test(
    'restaura selección por id y descarta una selección desactivada',
    () async {
      final repository = _FakeDirectionsRepository(
        directions: [address],
        selected: _address(99),
      );
      final container = _container(repository);
      addTearDown(container.dispose);
      await container.read(direccionControllerProvider.notifier).load();
      expect(container.read(direccionControllerProvider).selected?.id, 9);
    },
  );

  test('error de red termina en estado error con reintento posible', () async {
    final repository = _FakeDirectionsRepository(
      error: const NoConnectionException(),
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(direccionControllerProvider.notifier).load();
    expect(
      container.read(direccionControllerProvider).status,
      DireccionStatus.error,
    );
    expect(
      container.read(direccionControllerProvider).error,
      'No fue posible conectarse al servidor.',
    );
  });

  test('guardar, actualizar y desactivar refrescan el listado', () async {
    final repository = _FakeDirectionsRepository(directions: [address]);
    final container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(direccionControllerProvider.notifier);
    await controller.load();
    const request = DireccionRequest(
      descripcion: 'CASA',
      idColonia: 3,
      idCerrada: 1,
      idCalle: 2,
      numero: '123',
      latitud: 25.5,
      longitud: -103.4,
    );
    expect((await controller.save(request)).succeeded, isTrue);
    expect((await controller.save(request, direccionId: 9)).succeeded, isTrue);
    expect((await controller.deactivate(9)).succeeded, isTrue);
    expect(repository.saved, 1);
    expect(repository.updated, 1);
    expect(repository.deactivated, 1);
  });
}

ProviderContainer _container(_FakeDirectionsRepository repository) =>
    ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        direccionRepositoryProvider.overrideWithValue(repository),
      ],
    );

const address = Direccion(
  id: 9,
  descripcion: 'CASA',
  tipoCalle: 'CALLE',
  idCalle: 2,
  calle: 'HIDALGO',
  numeroInterior: '',
  numeroExterior: '123',
  idColonia: 3,
  colonia: 'CENTRO',
  idCiudad: 1,
  ciudad: 'TORREÓN',
  idEstado: 5,
  estado: 'COAHUILA',
  idZona: 0,
  zona: '',
  idCodigoPostal: 0,
  codigoPostal: '',
  referencias: '',
  activa: true,
  latitud: 25.5,
  longitud: -103.4,
  observaciones: '',
  entreCalle1: '',
  entreCalle2: '',
  entreCalle3: '',
  idSegmento: 1,
  cerrada: '',
  requiereClave: false,
  clave: '',
  idRuta: 0,
  tienePedido: false,
);
Direccion _address(int id) => Direccion(
  id: id,
  descripcion: 'OTRA',
  tipoCalle: address.tipoCalle,
  idCalle: address.idCalle,
  calle: address.calle,
  numeroInterior: '',
  numeroExterior: address.numeroExterior,
  idColonia: address.idColonia,
  colonia: address.colonia,
  idCiudad: address.idCiudad,
  ciudad: address.ciudad,
  idEstado: address.idEstado,
  estado: address.estado,
  idZona: 0,
  zona: '',
  idCodigoPostal: 0,
  codigoPostal: '',
  referencias: '',
  activa: true,
  latitud: address.latitud,
  longitud: address.longitud,
  observaciones: '',
  entreCalle1: '',
  entreCalle2: '',
  entreCalle3: '',
  idSegmento: 1,
  cerrada: '',
  requiereClave: false,
  clave: '',
  idRuta: 0,
  tienePedido: false,
);

final class _FakeDirectionsRepository implements DireccionRepositoryContract {
  _FakeDirectionsRepository({
    this.directions = const [],
    this.selected,
    this.error,
  });
  final List<Direccion> directions;
  Direccion? selected;
  final Object? error;
  int saved = 0;
  int updated = 0;
  int deactivated = 0;
  @override
  Future<List<Direccion>> getDirecciones(int clienteId) async {
    if (error != null) throw error!;
    return directions;
  }

  @override
  Direccion? getSelected() => selected;
  @override
  Future<void> saveSelected(Direccion direccion) async => selected = direccion;
  @override
  Future<void> clearSelected() async => selected = null;
  @override
  Future<DireccionOperationResult> guardar(
    int clienteId,
    DireccionRequest request,
  ) async {
    saved++;
    return const DireccionOperationResult(succeeded: true, message: 'OK');
  }

  @override
  Future<DireccionOperationResult> actualizar(
    int direccionId,
    DireccionRequest request,
  ) async {
    updated++;
    return const DireccionOperationResult(succeeded: true, message: 'OK');
  }

  @override
  Future<DireccionOperationResult> desactivar(
    int direccionId,
    int clienteId,
  ) async {
    deactivated++;
    return const DireccionOperationResult(succeeded: true, message: 'OK');
  }

  @override
  Future<Direccion> getDireccion(int direccionId) async => address;
  @override
  Future<List<Colonia>> getColonias() async => const [];
  @override
  Future<List<Calle>> getCalles(int coloniaId) async => const [];
  @override
  Future<List<Cerrada>> getCerradas(int coloniaId) async => const [];
}

final class _FakeAuthRepository implements AuthRepositoryContract {
  @override
  SessionData? getSession() => const SessionData(
    claveUsuario: 12,
    nombreUsuario: 'Cliente',
    claveTelefono: 3,
    subcanalUsuario: 1,
  );
  @override
  Future<LoginResult> login({
    required String telefono,
    required String contrasena,
  }) => throw UnimplementedError();
  @override
  Future<void> logout() async {}
}
