import 'package:combugas_clientes/core/storage/local_storage.dart';
import 'package:combugas_clientes/features/direcciones/data/direccion_selection_storage.dart';
import 'package:combugas_clientes/features/direcciones/models/direccion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'persiste y recupera el objeto equivalente a objDireccionSeleccionada',
    () async {
      final storage = DireccionSelectionStorage(_MemoryStorage());
      await storage.saveSelected(address);
      expect(storage.getSelected()?.id, 9);
      await storage.clearSelected();
      expect(storage.getSelected(), isNull);
    },
  );
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

final class _MemoryStorage implements LocalStorage {
  final Map<String, Object> values = {};
  @override
  Future<void> clear() async => values.clear();
  @override
  bool? getBool(String key) => values[key] as bool?;
  @override
  String? getString(String key) => values[key] as String?;
  @override
  Future<void> remove(String key) async => values.remove(key);
  @override
  Future<void> setBool(String key, bool value) async => values[key] = value;
  @override
  Future<void> setString(String key, String value) async => values[key] = value;
}
