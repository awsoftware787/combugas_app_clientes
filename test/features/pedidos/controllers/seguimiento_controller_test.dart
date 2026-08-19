import 'dart:async';

import 'package:combugas_clientes/core/network/network_exception.dart';
import 'package:combugas_clientes/features/pedidos/controllers/seguimiento_controller.dart';
import 'package:combugas_clientes/features/pedidos/data/pedido_repository.dart';
import 'package:combugas_clientes/features/pedidos/models/pedido_historial.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../historial_test_support.dart';

void main() {
  test('transita loading a success y conserva datos al refrescar', () async {
    final completer = Completer<PedidoSeguimientoInfo>();
    final repository = FakeHistorialRepository(
      getUnPedidoHandler: (_) => completer.future,
    );
    final container = _container(repository);
    addTearDown(container.dispose);

    final future = container
        .read(seguimientoControllerProvider.notifier)
        .load(321);
    expect(
      container.read(seguimientoControllerProvider).status,
      SeguimientoStatus.loading,
    );
    completer.complete(_tracking);
    await future;

    final state = container.read(seguimientoControllerProvider);
    expect(state.status, SeguimientoStatus.ready);
    expect(state.info?.direccion.descripcion, 'CASA');
    expect(repository.getUnPedidoCalls, 1);
  });

  test('expone error de red y permite reintentar', () async {
    var fail = true;
    final repository = FakeHistorialRepository(
      getUnPedidoHandler: (_) async {
        if (fail) throw const NetworkTimeoutException();
        return _tracking;
      },
    );
    final container = _container(repository);
    addTearDown(container.dispose);

    await container.read(seguimientoControllerProvider.notifier).load(321);
    expect(
      container.read(seguimientoControllerProvider).status,
      SeguimientoStatus.error,
    );
    expect(
      container.read(seguimientoControllerProvider).error,
      contains('tardó'),
    );
    fail = false;
    await container
        .read(seguimientoControllerProvider.notifier)
        .load(321, refresh: true);
    expect(
      container.read(seguimientoControllerProvider).status,
      SeguimientoStatus.ready,
    );
  });

  test('cancelación exitosa invalida el historial', () async {
    final repository = FakeHistorialRepository(
      getUnPedidoHandler: (_) async => _tracking,
    );
    final container = _container(repository);
    addTearDown(container.dispose);

    expect(
      await container.read(seguimientoControllerProvider.notifier).cancel(321),
      isTrue,
    );
    expect(repository.cancelCalls, 1);
  });
}

ProviderContainer _container(FakeHistorialRepository repository) =>
    ProviderContainer(
      overrides: [pedidoRepositoryProvider.overrideWithValue(repository)],
    );

const _tracking = PedidoSeguimientoInfo(
  direccion: PedidoDireccion(
    id: 9,
    descripcion: 'CASA',
    tipoCalle: 'CALLE',
    calle: 'HIDALGO',
    idCerrada: 1,
    cerrada: '',
    numeroInterior: '',
    numeroExterior: '123',
    colonia: 'CENTRO',
    ciudad: 'TORREÓN',
    estado: 'COAHUILA',
    codigoPostal: '27000',
    latitud: 25.5,
    longitud: -103.4,
  ),
  asignaciones: [
    PedidoAsignacion(
      operadorId: 4,
      nombreOperador: 'JUAN',
      rutaId: 8,
      vehiculo: PedidoVehiculo(
        descripcion: 'UNIDAD 12',
        latitud: 25.56,
        longitud: -103.45,
      ),
    ),
  ],
);
