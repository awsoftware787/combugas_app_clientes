import 'package:combugas_clientes/features/direcciones/models/direccion.dart';
import 'package:combugas_clientes/features/direcciones/widgets/direccion_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tarjeta muestra dirección, selección y acciones', (
    tester,
  ) async {
    var selected = false;
    var edited = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DireccionCard(
            direccion: address,
            selected: true,
            onSelect: () => selected = true,
            onEdit: () => edited = true,
          ),
        ),
      ),
    );
    expect(find.text('CASA'), findsOneWidget);
    expect(find.text('CALLE HIDALGO 123'), findsOneWidget);
    expect(find.text('COLONIA CENTRO'), findsOneWidget);
    await tester.tap(find.text('CASA'));
    expect(selected, isTrue);
    await tester.tap(find.byTooltip('Editar'));
    expect(edited, isTrue);
  });
}

const address = Direccion(
  id: 9,
  descripcion: 'CASA',
  tipoCalle: 'CALLE',
  idCalle: 2,
  calle: 'HIDALGO',
  numeroInterior: '',
  numeroExterior: '123',
  idColonia: 3,
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
