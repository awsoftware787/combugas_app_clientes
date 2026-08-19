import 'dart:async';

import 'package:combugas_clientes/core/network/network_exception.dart';
import 'package:combugas_clientes/features/auth/data/auth_repository.dart';
import 'package:combugas_clientes/features/pedidos/controllers/calificacion_controller.dart';
import 'package:combugas_clientes/features/pedidos/data/pedido_repository.dart';
import 'package:combugas_clientes/features/pedidos/models/calificacion.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../historial_test_support.dart';

void main() {
  test('pasa por saving, envía contrato real y termina en success', () async {
    final completer = Completer<CalificacionResult>();
    final repository = FakeHistorialRepository(
      calificarHandler: (_) => completer.future,
    );
    final container = _container(repository);
    addTearDown(container.dispose);

    final future = container
        .read(calificacionControllerProvider.notifier)
        .submit(
          pedidoId: 321,
          entregado: false,
          puntuacion: 4,
          comentarios: 'Buen servicio',
        );
    expect(container.read(calificacionControllerProvider).saving, isTrue);
    expect(repository.calificarCalls, 1);
    expect(repository.calificacionRecibida?.clienteId, 12);
    expect(repository.calificacionRecibida?.pedidoId, 321);
    expect(repository.calificacionRecibida?.entregado, isFalse);
    expect(repository.calificacionRecibida?.puntuacion, 4);
    expect(repository.calificacionRecibida?.comentarios, 'Buen servicio');

    completer.complete(const CalificacionResult(mensaje: 'OK'));
    expect(await future, isTrue);
    expect(
      container.read(calificacionControllerProvider).status,
      CalificacionStatus.success,
    );
  });

  test('error permite reintentar y no duplica solicitudes', () async {
    final completer = Completer<CalificacionResult>();
    var fail = true;
    final repository = FakeHistorialRepository(
      calificarHandler: (_) {
        if (fail) throw const WebServiceException('ERROR CALIFICACIÓN');
        return completer.future;
      },
    );
    final container = _container(repository);
    addTearDown(container.dispose);

    expect(
      await container
          .read(calificacionControllerProvider.notifier)
          .submit(
            pedidoId: 321,
            entregado: true,
            puntuacion: 5,
            comentarios: '',
          ),
      isFalse,
    );
    expect(
      container.read(calificacionControllerProvider).message,
      contains('ERROR'),
    );

    fail = false;
    final retry = container
        .read(calificacionControllerProvider.notifier)
        .submit(pedidoId: 321, entregado: true, puntuacion: 5, comentarios: '');
    expect(
      await container
          .read(calificacionControllerProvider.notifier)
          .submit(
            pedidoId: 321,
            entregado: true,
            puntuacion: 5,
            comentarios: '',
          ),
      isFalse,
    );
    expect(repository.calificarCalls, 2);
    completer.complete(const CalificacionResult(mensaje: 'OK'));
    expect(await retry, isTrue);
  });

  test('convierte timeout en mensaje seguro', () async {
    final repository = FakeHistorialRepository(
      calificarHandler: (_) async => throw const NetworkTimeoutException(),
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    await container
        .read(calificacionControllerProvider.notifier)
        .submit(pedidoId: 321, entregado: true, puntuacion: 5, comentarios: '');
    expect(
      container.read(calificacionControllerProvider).message,
      contains('tardó'),
    );
  });
}

ProviderContainer _container(FakeHistorialRepository repository) =>
    ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeHistoryAuthRepository()),
        pedidoRepositoryProvider.overrideWithValue(repository),
      ],
    );
