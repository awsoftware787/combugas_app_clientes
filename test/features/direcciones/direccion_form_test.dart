import 'dart:async';

import 'package:combugas_clientes/features/direcciones/models/catalogos_direccion.dart';
import 'package:combugas_clientes/features/direcciones/models/direccion.dart';
import 'package:combugas_clientes/features/direcciones/models/direccion_request.dart';
import 'package:combugas_clientes/features/direcciones/widgets/direccion_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  test('construye la consulta con nombres y contexto de México', () {
    expect(
      buildDireccionGeocodingQuery(
        colonia: _colonias.first,
        calle: _centroCalles.first,
        numero: ' 123 ',
      ),
      'HIDALGO 123, Colonia CENTRO, TORREÓN, COAHUILA, México',
    );
  });

  testWidgets('Desactivar usa el mismo color para texto y borde', (
    tester,
  ) async {
    await _pumpForm(tester, onDeactivate: () async {});

    await tester.ensureVisible(find.text('Desactivar'));
    final button = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('Desactivar'),
        matching: find.byWidgetPredicate((widget) => widget is OutlinedButton),
      ),
    );
    final foreground = button.style?.foregroundColor?.resolve(const {});

    expect(foreground, isNotNull);
    expect(button.style?.side?.resolve(const {})?.color, foreground);
  });

  testWidgets('crear dirección permite cambiar el punto del mapa', (
    tester,
  ) async {
    LatLng? shownPosition;
    await _pumpForm(
      tester,
      mapBuilder: ({required position, required onPositionChanged}) {
        shownPosition = position;
        return TextButton(
          key: const ValueKey('move-map-point'),
          onPressed: () => onPositionChanged(const LatLng(25.6, -103.5)),
          child: const Text('Mover punto'),
        );
      },
    );

    await tester.ensureVisible(find.byKey(const ValueKey('move-map-point')));
    await tester.tap(find.byKey(const ValueKey('move-map-point')));
    await tester.pump();

    expect(shownPosition, const LatLng(25.6, -103.5));
  });

  testWidgets('editar conserva coordenadas y guarda las nuevas al mover', (
    tester,
  ) async {
    final requests = <DireccionRequest>[];
    await _pumpForm(
      tester,
      initial: _address,
      onSave: (request) async => requests.add(request),
      mapBuilder:
          ({required position, required onPositionChanged}) => TextButton(
            key: const ValueKey('move-map-point'),
            onPressed: () => onPositionChanged(const LatLng(25.61, -103.51)),
            child: Text('${position.latitude},${position.longitude}'),
          ),
    );

    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    expect(requests.single.latitud, 25.5);
    expect(requests.single.longitud, -103.4);

    await tester.ensureVisible(find.byKey(const ValueKey('move-map-point')));
    await tester.tap(find.byKey(const ValueKey('move-map-point')));
    await tester.pump();
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pump();

    expect(requests.last.latitud, 25.61);
    expect(requests.last.longitud, -103.51);
  });

  testWidgets('busca colonia y calle, conserva IDs y actualiza dependencia', (
    tester,
  ) async {
    DireccionRequest? saved;
    await _pumpForm(tester, onSave: (request) async => saved = request);

    await tester.tap(find.byKey(const ValueKey('direccion-colonia')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('searchable-selector-search')),
      'cEnT',
    );
    await tester.pump();
    expect(find.text('CENTRO'), findsOneWidget);
    expect(find.text('CENTRO HISTÓRICO'), findsOneWidget);
    expect(find.text('LAS FUENTES'), findsNothing);
    await tester.tap(find.text('CENTRO'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('direccion-calle')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('searchable-selector-search')),
      'hid',
    );
    await tester.pump();
    expect(find.text('HIDALGO'), findsOneWidget);
    expect(find.text('MORELOS'), findsNothing);
    await tester.tap(find.text('HIDALGO'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('direccion-colonia')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('LAS FUENTES'));
    await tester.pumpAndSettle();
    expect(find.text('HIDALGO'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('direccion-calle')));
    await tester.pumpAndSettle();
    expect(find.text('INDEPENDENCIA'), findsOneWidget);
    expect(find.text('HIDALGO'), findsNothing);
    await tester.tap(find.text('INDEPENDENCIA'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'CASA');
    await tester.enterText(fields.at(1), '123');
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pump();

    expect(saved?.idColonia, 2);
    expect(saved?.idCalle, 21);
  });

  group('geocodificación automática', () {
    testWidgets('no consulta mientras falten colonia, calle o número', (
      tester,
    ) async {
      final queries = <String>[];
      await _pumpForm(
        tester,
        geocodeAddress: (query) async {
          queries.add(query);
          return const LatLng(25.7, -103.6);
        },
      );

      await tester.enterText(
        find.byKey(const ValueKey('direccion-numero')),
        '123',
      );
      await tester.pump(const Duration(milliseconds: 700));
      expect(queries, isEmpty);

      await _selectColonia(tester, 'CENTRO');
      await tester.pump(const Duration(milliseconds: 700));
      expect(queries, isEmpty);
    });

    testWidgets('consulta al seleccionar calle cuando el número ya existe', (
      tester,
    ) async {
      final queries = <String>[];
      await _pumpForm(
        tester,
        geocodeAddress: (query) async {
          queries.add(query);
          return const LatLng(25.7, -103.6);
        },
      );

      await tester.enterText(
        find.byKey(const ValueKey('direccion-numero')),
        '123',
      );
      await _selectColonia(tester, 'CENTRO');
      await _selectCalle(tester, 'HIDALGO');
      await tester.pump();

      expect(queries, [
        'HIDALGO 123, Colonia CENTRO, TORREÓN, COAHUILA, México',
      ]);
    });

    testWidgets('aplica debounce al escribir el número', (tester) async {
      var calls = 0;
      await _pumpForm(
        tester,
        geocodeAddress: (_) async {
          calls++;
          return const LatLng(25.7, -103.6);
        },
      );
      await _selectColonia(tester, 'CENTRO');
      await _selectCalle(tester, 'HIDALGO');

      await tester.enterText(
        find.byKey(const ValueKey('direccion-numero')),
        '123',
      );
      await tester.pump(const Duration(milliseconds: 649));
      expect(calls, 0);
      await tester.pump(const Duration(milliseconds: 1));
      expect(calls, 1);
    });

    testWidgets('consulta al perder foco sin esperar el debounce', (
      tester,
    ) async {
      var calls = 0;
      await _pumpForm(
        tester,
        geocodeAddress: (_) async {
          calls++;
          return const LatLng(25.7, -103.6);
        },
      );
      await _selectColonia(tester, 'CENTRO');
      await _selectCalle(tester, 'HIDALGO');
      await tester.enterText(
        find.byKey(const ValueKey('direccion-numero')),
        '123',
      );

      await tester.tap(find.byType(TextFormField).first);
      await tester.pump();
      expect(calls, 1);
    });

    testWidgets('actualiza marcador, cámara y coordenadas guardadas', (
      tester,
    ) async {
      LatLng? shownPosition;
      LatLng? cameraPosition;
      double? cameraZoom;
      DireccionRequest? saved;
      await _pumpForm(
        tester,
        initial: _address,
        geocodeAddress: (_) async => const LatLng(25.72, -103.62),
        moveCamera: (position, zoom) async {
          cameraPosition = position;
          cameraZoom = zoom;
        },
        onSave: (request) async => saved = request,
        mapBuilder: ({required position, required onPositionChanged}) {
          shownPosition = position;
          return const SizedBox.expand();
        },
      );

      await tester.enterText(
        find.byKey(const ValueKey('direccion-numero')),
        '124',
      );
      await tester.pump(const Duration(milliseconds: 650));
      await tester.pump();

      expect(shownPosition, const LatLng(25.72, -103.62));
      expect(cameraPosition, const LatLng(25.72, -103.62));
      expect(cameraZoom, 18);

      await tester.ensureVisible(find.text('Guardar'));
      await tester.tap(find.text('Guardar'));
      await tester.pump();
      expect(saved?.latitud, 25.72);
      expect(saved?.longitud, -103.62);
    });

    testWidgets('editar conserva coordenadas y no consulta al abrir', (
      tester,
    ) async {
      var calls = 0;
      LatLng? shownPosition;
      await _pumpForm(
        tester,
        initial: _address,
        geocodeAddress: (_) async {
          calls++;
          return const LatLng(25.7, -103.6);
        },
        mapBuilder: ({required position, required onPositionChanged}) {
          shownPosition = position;
          return const SizedBox.expand();
        },
      );

      await tester.pump(const Duration(seconds: 1));
      expect(calls, 0);
      expect(shownPosition, const LatLng(25.5, -103.4));

      await tester.tap(find.byKey(const ValueKey('direccion-numero')));
      await tester.tap(find.byType(TextFormField).first);
      await tester.pump();
      expect(calls, 0);
    });

    testWidgets('editar consulta solamente después de cambiar la dirección', (
      tester,
    ) async {
      var calls = 0;
      await _pumpForm(
        tester,
        initial: _address,
        geocodeAddress: (_) async {
          calls++;
          return const LatLng(25.7, -103.6);
        },
      );

      await tester.enterText(
        find.byKey(const ValueKey('direccion-numero')),
        '124',
      );
      await tester.pump(const Duration(milliseconds: 650));
      expect(calls, 1);
    });

    testWidgets('cambiar colonia limpia calle y no consulta sin otra calle', (
      tester,
    ) async {
      var calls = 0;
      await _pumpForm(
        tester,
        initial: _address,
        geocodeAddress: (_) async {
          calls++;
          return const LatLng(25.7, -103.6);
        },
      );

      await _selectColonia(tester, 'LAS FUENTES');
      await tester.pump(const Duration(milliseconds: 700));

      expect(calls, 0);
      await tester.tap(find.byKey(const ValueKey('direccion-calle')));
      await tester.pumpAndSettle();
      expect(find.text('INDEPENDENCIA'), findsOneWidget);
      expect(find.text('HIDALGO'), findsNothing);
    });

    testWidgets('el movimiento manual invalida una respuesta pendiente', (
      tester,
    ) async {
      final pending = Completer<LatLng?>();
      LatLng? shownPosition;
      ValueChanged<LatLng>? movePoint;
      await _pumpForm(
        tester,
        initial: _address,
        geocodeAddress: (_) => pending.future,
        mapBuilder: ({required position, required onPositionChanged}) {
          shownPosition = position;
          movePoint = onPositionChanged;
          return const SizedBox.expand();
        },
      );

      await tester.enterText(
        find.byKey(const ValueKey('direccion-numero')),
        '124',
      );
      await tester.pump(const Duration(milliseconds: 650));
      movePoint!(const LatLng(25.8, -103.7));
      await tester.pump();
      pending.complete(const LatLng(25.9, -103.8));
      await tester.pump();

      expect(shownPosition, const LatLng(25.8, -103.7));
    });

    testWidgets('descarta una respuesta anterior que termina al final', (
      tester,
    ) async {
      final first = Completer<LatLng?>();
      final second = Completer<LatLng?>();
      var calls = 0;
      LatLng? shownPosition;
      await _pumpForm(
        tester,
        initial: _address,
        geocodeAddress: (_) => calls++ == 0 ? first.future : second.future,
        mapBuilder: ({required position, required onPositionChanged}) {
          shownPosition = position;
          return const SizedBox.expand();
        },
      );

      await tester.enterText(
        find.byKey(const ValueKey('direccion-numero')),
        '124',
      );
      await tester.pump(const Duration(milliseconds: 650));
      await tester.enterText(
        find.byKey(const ValueKey('direccion-numero')),
        '125',
      );
      await tester.pump(const Duration(milliseconds: 650));
      second.complete(const LatLng(25.82, -103.72));
      await tester.pump();
      first.complete(const LatLng(25.81, -103.71));
      await tester.pump();

      expect(shownPosition, const LatLng(25.82, -103.72));
    });

    testWidgets('sin resultados conserva el punto y muestra aviso', (
      tester,
    ) async {
      LatLng? shownPosition;
      await _pumpForm(
        tester,
        initial: _address,
        geocodeAddress: (_) async => null,
        mapBuilder: ({required position, required onPositionChanged}) {
          shownPosition = position;
          return const SizedBox.expand();
        },
      );

      await tester.enterText(
        find.byKey(const ValueKey('direccion-numero')),
        '999',
      );
      await tester.pump(const Duration(milliseconds: 650));
      await tester.pump();

      expect(shownPosition, const LatLng(25.5, -103.4));
      expect(
        find.textContaining('No encontramos esa dirección'),
        findsOneWidget,
      );
    });

    testWidgets('un error conserva el punto y permite guardar', (tester) async {
      DireccionRequest? saved;
      await _pumpForm(
        tester,
        initial: _address,
        onSave: (request) async => saved = request,
        geocodeAddress: (_) async => throw Exception('sin red'),
      );

      await tester.enterText(
        find.byKey(const ValueKey('direccion-numero')),
        '999',
      );
      await tester.pump(const Duration(milliseconds: 650));
      await tester.pump();
      expect(find.textContaining('No fue posible ubicar'), findsOneWidget);

      await tester.ensureVisible(find.text('Guardar'));
      await tester.tap(find.text('Guardar'));
      await tester.pump();
      expect(saved?.latitud, 25.5);
      expect(saved?.longitud, -103.4);
    });
  });
}

Future<void> _pumpForm(
  WidgetTester tester, {
  Direccion? initial,
  Future<void> Function(DireccionRequest)? onSave,
  Future<void> Function()? onDeactivate,
  DireccionMapBuilder? mapBuilder,
  DireccionGeocoder? geocodeAddress,
  DireccionCameraMover? moveCamera,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DireccionForm(
          initial: initial,
          saving: false,
          loadColonias: () async => _colonias,
          loadCalles:
              (coloniaId) async =>
                  coloniaId == 1 ? _centroCalles : _fuentesCalles,
          loadCerradas: (_) async => const [],
          onSave: onSave ?? (_) async {},
          onDeactivate: onDeactivate,
          geocodeAddress: geocodeAddress ?? (_) async => null,
          moveCamera: moveCamera,
          mapBuilder:
              mapBuilder ??
              ({required position, required onPositionChanged}) =>
                  const SizedBox.expand(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _selectColonia(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(const ValueKey('direccion-colonia')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

Future<void> _selectCalle(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(const ValueKey('direccion-calle')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

const _colonias = [
  Colonia(
    id: 1,
    descripcion: 'CENTRO',
    idCiudad: 1,
    ciudad: 'TORREÓN',
    idEstado: 5,
    estado: 'COAHUILA',
  ),
  Colonia(
    id: 3,
    descripcion: 'CENTRO HISTÓRICO',
    idCiudad: 1,
    ciudad: 'TORREÓN',
    idEstado: 5,
    estado: 'COAHUILA',
  ),
  Colonia(
    id: 2,
    descripcion: 'LAS FUENTES',
    idCiudad: 1,
    ciudad: 'TORREÓN',
    idEstado: 5,
    estado: 'COAHUILA',
  ),
];

const _centroCalles = [
  Calle(id: 11, descripcion: 'HIDALGO'),
  Calle(id: 12, descripcion: 'MORELOS'),
];
const _fuentesCalles = [Calle(id: 21, descripcion: 'INDEPENDENCIA')];

const _address = Direccion(
  id: 9,
  descripcion: 'CASA',
  tipoCalle: 'CALLE',
  idCalle: 11,
  calle: 'HIDALGO',
  numeroInterior: '',
  numeroExterior: '123',
  idColonia: 1,
  colonia: 'CENTRO',
  idCiudad: 1,
  ciudad: 'TORREÓN',
  idEstado: 5,
  estado: 'COAHUILA',
  idZona: 0,
  zona: '',
  idCodigoPostal: 0,
  codigoPostal: '',
  referencias: '',
  activa: true,
  latitud: 25.5,
  longitud: -103.4,
  observaciones: '',
  entreCalle1: '',
  entreCalle2: '',
  entreCalle3: '',
  idSegmento: 1,
  cerrada: '',
  requiereClave: false,
  clave: '',
  idRuta: 0,
  tienePedido: false,
);
