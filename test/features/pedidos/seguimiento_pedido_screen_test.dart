import 'dart:async';

import 'package:combugas_clientes/core/theme/app_colors.dart';
import 'package:combugas_clientes/features/pedidos/controllers/seguimiento_controller.dart';
import 'package:combugas_clientes/features/pedidos/data/pedido_repository.dart';
import 'package:combugas_clientes/features/pedidos/models/pedido_historial.dart';
import 'package:combugas_clientes/features/pedidos/screens/seguimiento_pedido_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
    final cancel = tester.widget<FilledButton>(
      find.byKey(const ValueKey('cancel-tracking-order')),
    );
    expect(cancel.style?.backgroundColor?.resolve(const {}), AppColors.accent);
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

  testWidgets('mapa conserva casa y agrega un solo vehículo válido', (
    tester,
  ) async {
    final repository = FakeHistorialRepository(
      getUnPedidoHandler: (_) async => _tracking,
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    await tester.pumpWidget(_mapApp(container));
    await tester.pumpAndSettle();

    final markers = tester.widget<GoogleMap>(find.byType(GoogleMap)).markers;
    expect(markers.map((marker) => marker.markerId.value), {
      'domicilio',
      'vehiculo',
    });
    final vehicle = markers.singleWhere(
      (marker) => marker.markerId.value == 'vehiculo',
    );
    expect(vehicle.position, const LatLng(25.56, -103.45));
    expect(vehicle.infoWindow.title, 'UNIDAD 12');
  });

  testWidgets('coordenadas 0,0 no agregan marcador de vehículo', (
    tester,
  ) async {
    final repository = FakeHistorialRepository(
      getUnPedidoHandler: (_) async => _trackingWithVehicle(0, 0),
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    await tester.pumpWidget(_mapApp(container));
    await tester.pumpAndSettle();

    final markers = tester.widget<GoogleMap>(find.byType(GoogleMap)).markers;
    expect(markers.map((marker) => marker.markerId.value), {'domicilio'});
  });

  testWidgets('refresh mueve el mismo marcador sin acumular posiciones', (
    tester,
  ) async {
    var calls = 0;
    final repository = FakeHistorialRepository(
      getUnPedidoHandler: (_) async {
        calls++;
        return calls == 1 ? _tracking : _trackingWithVehicle(25.58, -103.47);
      },
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    await tester.pumpWidget(_mapApp(container));
    await tester.pumpAndSettle();

    await container
        .read(seguimientoControllerProvider.notifier)
        .load(321, refresh: true);
    await tester.pumpAndSettle();

    final markers = tester.widget<GoogleMap>(find.byType(GoogleMap)).markers;
    final vehicles = markers.where(
      (marker) => marker.markerId.value == 'vehiculo',
    );
    expect(vehicles, hasLength(1));
    expect(vehicles.single.position, const LatLng(25.58, -103.47));
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

Widget _mapApp(ProviderContainer container) => UncontrolledProviderScope(
  container: container,
  child: const MaterialApp(home: SeguimientoPedidoScreen(pedidoId: 321)),
);

PedidoSeguimientoInfo _trackingWithVehicle(double latitude, double longitude) =>
    PedidoSeguimientoInfo(
      direccion: _tracking.direccion,
      asignaciones: [
        PedidoAsignacion(
          operadorId: 4,
          nombreOperador: 'JUAN',
          rutaId: 8,
          vehiculo: PedidoVehiculo(
            descripcion: 'UNIDAD 12',
            latitud: latitude,
            longitud: longitude,
          ),
        ),
      ],
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
