import 'package:combugas_clientes/features/auth/data/auth_repository.dart';
import 'package:combugas_clientes/features/perfil/controllers/perfil_controller.dart';
import 'package:combugas_clientes/features/perfil/data/perfil_repository.dart';
import 'package:combugas_clientes/features/perfil/models/perfil_cliente.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../pedidos/historial_test_support.dart';

void main() {
  test('consulta perfil y actualiza correo solo ante Result=true', () async {
    final repository = FakePerfilRepository();
    final container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(perfilControllerProvider.notifier);

    await controller.load();
    expect(container.read(perfilControllerProvider).status, PerfilStatus.ready);
    expect(container.read(perfilControllerProvider).perfil?.nombre, 'CLIENTE');

    repository.updateResult = const PerfilOperationResult(
      succeeded: false,
      message: 'SIN CAMBIOS',
    );
    await controller.actualizarCorreo('fallo@example.com');
    expect(
      container.read(perfilControllerProvider).perfil?.correo,
      'anterior@example.com',
    );

    repository.updateResult = const PerfilOperationResult(
      succeeded: true,
      message: 'OK',
    );
    await controller.actualizarCorreo('nuevo@example.com');
    expect(
      container.read(perfilControllerProvider).perfil?.correo,
      'nuevo@example.com',
    );
  });

  test(
    'expone resultado fallido al eliminar y mantiene sesión intacta',
    () async {
      final repository = FakePerfilRepository(
        deleteResult: const PerfilOperationResult(
          succeeded: false,
          message: 'NO ELIMINADA',
        ),
      );
      final auth = FakeHistoryAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          perfilRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final result =
          await container
              .read(perfilControllerProvider.notifier)
              .eliminarCuenta();

      expect(result.succeeded, isFalse);
      expect(result.message, 'NO ELIMINADA');
      expect(container.read(perfilControllerProvider).deletingAccount, isFalse);
    },
  );
}

ProviderContainer _container(FakePerfilRepository repository) =>
    ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeHistoryAuthRepository()),
        perfilRepositoryProvider.overrideWithValue(repository),
      ],
    );

final class FakePerfilRepository implements PerfilRepositoryContract {
  FakePerfilRepository({
    this.deleteResult = const PerfilOperationResult(
      succeeded: true,
      message: 'OK',
    ),
  });

  PerfilOperationResult updateResult = const PerfilOperationResult(
    succeeded: true,
    message: 'OK',
  );
  PerfilOperationResult deleteResult;

  @override
  Future<PerfilCliente> getPerfil(int clienteId) async => const PerfilCliente(
    nombre: 'CLIENTE',
    telefono: '8711234567',
    correo: 'anterior@example.com',
    cantidadDirecciones: 1,
  );

  @override
  Future<PerfilOperationResult> actualizarCorreo(
    int clienteId,
    String correo,
  ) async => updateResult;

  @override
  Future<PerfilOperationResult> eliminarCuenta(int clienteId) async =>
      deleteResult;
}
