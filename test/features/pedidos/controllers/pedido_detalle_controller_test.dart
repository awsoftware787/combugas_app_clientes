import 'dart:async';

import 'package:combugas_clientes/core/network/network_exception.dart';
import 'package:combugas_clientes/features/auth/data/auth_repository.dart';
import 'package:combugas_clientes/features/pedidos/controllers/mis_pedidos_controller.dart';
import 'package:combugas_clientes/features/pedidos/controllers/pedido_detalle_controller.dart';
import 'package:combugas_clientes/features/pedidos/data/pedido_repository.dart';
import 'package:combugas_clientes/features/pedidos/models/pedido_historial.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../historial_test_support.dart';
import '../pedido_historial_fixture.dart';

void main() {
  test('carga detalle completo desde el listado y calcula total', () async {
    final repository = FakeHistorialRepository(pedidos: [pedidoFixture()]);
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(misPedidosControllerProvider.notifier).load();
    await container.read(pedidoDetalleControllerProvider.notifier).load(321);
    final detail = container.read(pedidoDetalleControllerProvider).pedido!;
    expect(detail.productos, hasLength(2));
    expect(detail.totalCentavos, 89010);
    expect(repository.getPedidosCalls, 1);
  });

  test('cancelación exitosa actualiza detalle y listado', () async {
    final repository = FakeHistorialRepository(pedidos: [pedidoFixture()]);
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(misPedidosControllerProvider.notifier).load();
    final controller = container.read(pedidoDetalleControllerProvider.notifier);
    await controller.load(321);
    expect(await controller.cancel(), isTrue);
    expect(
      container.read(pedidoDetalleControllerProvider).pedido!.status,
      PedidoHistorialStatus.cancelado,
    );
    expect(
      container.read(misPedidosControllerProvider).pedidos.single.status,
      PedidoHistorialStatus.cancelado,
    );
  });

  test('timeout conserva detalle y evita cancelación doble', () async {
    final completer = Completer<CancelarPedidoResult>();
    final repository = FakeHistorialRepository(
      pedidos: [pedidoFixture()],
      cancelHandler: (_) => completer.future,
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(misPedidosControllerProvider.notifier).load();
    final controller = container.read(pedidoDetalleControllerProvider.notifier);
    await controller.load(321);
    final first = controller.cancel();
    expect(await controller.cancel(), isFalse);
    expect(repository.cancelCalls, 1);
    completer.completeError(const NetworkTimeoutException());
    expect(await first, isFalse);
    final state = container.read(pedidoDetalleControllerProvider);
    expect(state.pedido!.status, PedidoHistorialStatus.enCurso);
    expect(state.error, contains('tardó'));
  });

  test('LOCK marca sesión bloqueada', () async {
    final repository = FakeHistorialRepository(
      pedidos: [pedidoFixture()],
      cancelHandler:
          (_) async => const CancelarPedidoResult(mensaje: 'LOCK'),
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(misPedidosControllerProvider.notifier).load();
    final controller = container.read(pedidoDetalleControllerProvider.notifier);
    await controller.load(321);
    expect(await controller.cancel(), isFalse);
    expect(container.read(pedidoDetalleControllerProvider).sessionLocked, isTrue);
  });
}

ProviderContainer _container(FakeHistorialRepository repository) =>
    ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeHistoryAuthRepository()),
        pedidoRepositoryProvider.overrideWithValue(repository),
      ],
    );
