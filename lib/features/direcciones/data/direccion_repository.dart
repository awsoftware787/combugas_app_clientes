import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_storage_provider.dart';
import '../models/catalogos_direccion.dart';
import '../models/direccion.dart';
import '../models/direccion_request.dart';
import 'direccion_selection_storage.dart';
import 'direcciones_soap_service.dart';

abstract interface class DireccionRepositoryContract {
  Future<List<Direccion>> getDirecciones(int clienteId);
  Future<Direccion> getDireccion(int direccionId);
  Future<List<Colonia>> getColonias();
  Future<List<Calle>> getCalles(int coloniaId);
  Future<List<Cerrada>> getCerradas(int coloniaId);
  Future<DireccionOperationResult> guardar(
    int clienteId,
    DireccionRequest request,
  );
  Future<DireccionOperationResult> actualizar(
    int direccionId,
    DireccionRequest request,
  );
  Future<DireccionOperationResult> desactivar(int direccionId, int clienteId);
  Direccion? getSelected();
  Future<void> saveSelected(Direccion direccion);
  Future<void> clearSelected();
}

final class DireccionRepository implements DireccionRepositoryContract {
  const DireccionRepository({
    required DireccionesService service,
    required DireccionSelectionStore selectionStore,
  }) : _service = service,
       _selectionStore = selectionStore;
  final DireccionesService _service;
  final DireccionSelectionStore _selectionStore;

  @override
  Future<List<Direccion>> getDirecciones(int clienteId) =>
      _service.getDirecciones(clienteId);
  @override
  Future<Direccion> getDireccion(int direccionId) =>
      _service.getDireccion(direccionId);
  @override
  Future<List<Colonia>> getColonias() => _service.getColonias();
  @override
  Future<List<Calle>> getCalles(int coloniaId) => _service.getCalles(coloniaId);
  @override
  Future<List<Cerrada>> getCerradas(int coloniaId) =>
      _service.getCerradas(coloniaId);
  @override
  Future<DireccionOperationResult> guardar(
    int clienteId,
    DireccionRequest request,
  ) => _service.guardar(clienteId, request);
  @override
  Future<DireccionOperationResult> actualizar(
    int direccionId,
    DireccionRequest request,
  ) => _service.actualizar(direccionId, request);
  @override
  Future<DireccionOperationResult> desactivar(int direccionId, int clienteId) =>
      _service.desactivar(direccionId, clienteId);
  @override
  Direccion? getSelected() => _selectionStore.getSelected();
  @override
  Future<void> saveSelected(Direccion direccion) =>
      _selectionStore.saveSelected(direccion);
  @override
  Future<void> clearSelected() => _selectionStore.clearSelected();
}

final direccionesSoapServiceProvider = Provider<DireccionesSoapService>((ref) {
  final service = DireccionesSoapService();
  ref.onDispose(service.close);
  return service;
});

final direccionRepositoryProvider = Provider<DireccionRepositoryContract>(
  (ref) => DireccionRepository(
    service: ref.watch(direccionesSoapServiceProvider),
    selectionStore: DireccionSelectionStorage(ref.watch(localStorageProvider)),
  ),
);
