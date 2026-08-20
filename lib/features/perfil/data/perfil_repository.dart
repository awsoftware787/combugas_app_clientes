import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../../auth/data/clientes_soap_service.dart';
import '../models/perfil_cliente.dart';

abstract interface class PerfilRepositoryContract {
  Future<PerfilCliente> getPerfil(int clienteId);
  Future<PerfilOperationResult> actualizarCorreo(int clienteId, String correo);
  Future<PerfilOperationResult> eliminarCuenta(int clienteId);
}

final class PerfilRepository implements PerfilRepositoryContract {
  const PerfilRepository(this._service);

  final PerfilClientesService _service;

  @override
  Future<PerfilCliente> getPerfil(int clienteId) =>
      _service.getPerfil(clienteId);

  @override
  Future<PerfilOperationResult> actualizarCorreo(
    int clienteId,
    String correo,
  ) => _service.actualizarCorreo(clienteId, correo);

  @override
  Future<PerfilOperationResult> eliminarCuenta(int clienteId) =>
      _service.eliminarCuenta(clienteId);
}

final perfilRepositoryProvider = Provider<PerfilRepositoryContract>((ref) {
  return PerfilRepository(ref.watch(clientesSoapServiceProvider));
});
