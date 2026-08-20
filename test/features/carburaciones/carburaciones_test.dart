import 'package:combugas_clientes/features/carburaciones/data/carburaciones_repository.dart';
import 'package:combugas_clientes/features/carburaciones/models/carburacion.dart';
import 'package:combugas_clientes/features/carburaciones/screens/carburaciones_screen.dart';
import 'package:combugas_clientes/features/direcciones/data/direcciones_soap_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

void main() {
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
