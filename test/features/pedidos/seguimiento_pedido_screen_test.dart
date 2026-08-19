import 'dart:async';

import 'package:combugas_clientes/features/pedidos/data/pedido_repository.dart';
import 'package:combugas_clientes/features/pedidos/models/pedido_historial.dart';
import 'package:combugas_clientes/features/pedidos/screens/seguimiento_pedido_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'historial_test_support.dart';

void main() {
  testWidgets('muestra loading y luego el mapa con cancelar', (tester) async {
    final completer = Completer<PedidoSeguimientoInfo>();
    final repository = FakeHistorialRepository(
      getUnPedidoHandler: (_) => completer.future,
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    await tester.pumpWidget(_app(container));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(_tracking);
    await tester.pumpAndSettle();
    expect(find.text('mapa CASA / UNIDAD 12'), findsOneWidget);
    expect(find.text('Cancelar Pedido'), findsOneWidget);
    expect(repository.getUnPedidoCalls, 1);
  });

  testWidgets('error muestra reintento y recupera', (tester) async {
    var fail = true;
    final repository = FakeHistorialRepository(
      getUnPedidoHandler: (_) async {
        if (fail) throw Exception('offline');
        return _tracking;
      },
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();
    expect(find.text('Reintentar'), findsOneWidget);

    fail = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('mapa CASA / UNIDAD 12'), findsOneWidget);
  });
}

ProviderContainer _container(FakeHistorialRepository repository) =>
    ProviderContainer(
      overrides: [pedidoRepositoryProvider.overrideWithValue(repository)],
    );

Widget _app(ProviderContainer container) => UncontrolledProviderScope(
  container: container,
  child: MaterialApp(
    home: SeguimientoPedidoScreen(
      pedidoId: 321,
      mapBuilder:
          (info) => Center(
            child: Text(
              'mapa ${info.direccion.descripcion} / '
              '${info.asignaciones.single.vehiculo?.descripcion}',
            ),
          ),
    ),
  ),
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
