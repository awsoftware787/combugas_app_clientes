import 'dart:async';

import 'package:combugas_clientes/core/network/network_exception.dart';
import 'package:combugas_clientes/features/auth/data/auth_repository.dart';
import 'package:combugas_clientes/features/pedidos/controllers/mis_pedidos_controller.dart';
import 'package:combugas_clientes/features/pedidos/data/pedido_repository.dart';
import 'package:combugas_clientes/features/pedidos/models/pedido_historial.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../historial_test_support.dart';
import '../pedido_historial_fixture.dart';

void main() {
  test('diferencia loading de lista vacía real', () async {
    final completer = Completer<List<PedidoHistorial>>();
    final repository = FakeHistorialRepository(
      getPedidosHandler: (_) => completer.future,
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    final future = container.read(misPedidosControllerProvider.notifier).load();
    expect(
      container.read(misPedidosControllerProvider).status,
      MisPedidosStatus.loading,
    );
    completer.complete(const []);
    await future;
    final state = container.read(misPedidosControllerProvider);
    expect(state.status, MisPedidosStatus.ready);
    expect(state.pedidos, isEmpty);
  });

  test('conserva el orden del servidor y refresh reemplaza resultados', () async {
    final repository = FakeHistorialRepository(
      pedidos: [pedidoFixture(id: 2), pedidoFixture(id: 1)],
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(misPedidosControllerProvider.notifier);
    await controller.load();
    expect(
      container.read(misPedidosControllerProvider).pedidos.map((e) => e.id),
      [2, 1],
    );
    repository.pedidos = [pedidoFixture(id: 3)];
    await controller.load(refresh: true);
    expect(
      container.read(misPedidosControllerProvider).pedidos.single.id,
      3,
    );
  });

  test('error permite reintentar sin cerrar sesión', () async {
    var fail = true;
    final repository = FakeHistorialRepository(
      getPedidosHandler: (_) async {
        if (fail) throw const NoConnectionException();
        return [pedidoFixture()];
      },
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(misPedidosControllerProvider.notifier);
    await controller.load();
    expect(
      container.read(misPedidosControllerProvider).status,
      MisPedidosStatus.error,
    );
    fail = false;
    await controller.load();
    expect(container.read(misPedidosControllerProvider).pedidos, hasLength(1));
  });
}

ProviderContainer _container(FakeHistorialRepository repository) =>
    ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeHistoryAuthRepository()),
        pedidoRepositoryProvider.overrideWithValue(repository),
      ],
    );
