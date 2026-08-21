import 'package:combugas_clientes/core/routes/app_router.dart';
import 'package:combugas_clientes/features/auth/data/auth_repository.dart';
import 'package:combugas_clientes/features/auth/models/session_data.dart';
import 'package:combugas_clientes/features/carburaciones/data/carburaciones_repository.dart';
import 'package:combugas_clientes/features/carburaciones/models/carburacion.dart';
import 'package:combugas_clientes/features/carburaciones/screens/carburaciones_screen.dart';
import 'package:combugas_clientes/features/direcciones/data/direcciones_soap_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

void main() {
  testWidgets('ruta real de Carburaciones permite acceso sin sesión', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(const _PublicAuthRepository()),
        carburacionesRepositoryProvider.overrideWithValue(
          _EmptyCarburacionesRepository(),
        ),
        carburacionesLocationProvider.overrideWithValue(() async => null),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(() => appRouter.go('/'));
    appRouter.go('/carburaciones');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: appRouter),
      ),
    );
    await tester.pumpAndSettle();

    expect(appRouter.state.uri.path, '/carburaciones');
    expect(find.byType(CarburacionesScreen), findsOneWidget);
    expect(find.text('No hay carburaciones disponibles.'), findsOneWidget);
  });

  test('parsea los campos reales de getCarburaciones', () {
    final document = XmlDocument.parse('''
      <Envelope><Body><getCarburacionesResponse><getCarburacionesResult>
        <Result>true</Result><Message>OK</Message>
        <Data>[{"ec_descripcion":"CENTRO","ec_latitud":25.56,"ec_longitud":-103.45,"ec_tipo":1}]</Data>
      </getCarburacionesResult></getCarburacionesResponse></Body></Envelope>
    ''');

    final values = const DireccionesSoapParser().parseCarburaciones(document);

    expect(values, hasLength(1));
    expect(values.single.descripcion, 'CENTRO');
    expect(values.single.latitud, 25.56);
    expect(values.single.longitud, -103.45);
    expect(values.single.tipo, 1);
    expect(values.single.esSoloGas, isTrue);
    expect(values.single.tieneCoordenadasUtilizables, isTrue);
  });

  test('valida coordenadas utilizables para la navegación', () {
    const valid = Carburacion(
      descripcion: 'CENTRO',
      latitud: 25.56,
      longitud: -103.45,
      tipo: 1,
    );
    const missing = Carburacion(
      descripcion: 'SIN COORDENADAS',
      latitud: 0,
      longitud: 0,
      tipo: 1,
    );
    const outOfRange = Carburacion(
      descripcion: 'FUERA DE RANGO',
      latitud: 91,
      longitud: -181,
      tipo: 1,
    );

    expect(valid.tieneCoordenadasUtilizables, isTrue);
    expect(missing.tieneCoordenadasUtilizables, isFalse);
    expect(outOfRange.tieneCoordenadasUtilizables, isFalse);
  });

  testWidgets('muestra mapa y no depende de ubicación', (tester) async {
    final container = ProviderContainer(
      overrides: [
        carburacionesRepositoryProvider.overrideWithValue(
          _CarburacionesRepository(),
        ),
        carburacionesLocationProvider.overrideWithValue(() async => null),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: CarburacionesScreen(
            mapBuilder:
                (values) =>
                    Center(child: Text('MAPA ${values.single.descripcion}')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('MAPA CENTRO'), findsOneWidget);
    expect(find.byTooltip('Actualizar carburaciones'), findsNothing);
  });
}

final class _CarburacionesRepository
    implements CarburacionesRepositoryContract {
  @override
  Future<List<Carburacion>> getCarburaciones() async => const [
    Carburacion(
      descripcion: 'CENTRO',
      latitud: 25.56,
      longitud: -103.45,
      tipo: 1,
    ),
  ];
}

final class _EmptyCarburacionesRepository
    implements CarburacionesRepositoryContract {
  @override
  Future<List<Carburacion>> getCarburaciones() async => const [];
}

final class _PublicAuthRepository implements AuthRepositoryContract {
  const _PublicAuthRepository();

  @override
  SessionData? getSession() => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
