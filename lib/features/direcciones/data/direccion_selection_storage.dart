import 'dart:convert';

import '../../../core/storage/local_storage.dart';
import '../models/direccion.dart';

abstract interface class DireccionSelectionStore {
  Direccion? getSelected();
  Future<void> saveSelected(Direccion direccion);
  Future<void> clearSelected();
}

final class DireccionSelectionStorage implements DireccionSelectionStore {
  const DireccionSelectionStorage(this._storage);
  static const key = 'objDireccionSeleccionada';
  final LocalStorage _storage;

  @override
  Direccion? getSelected() {
    final value = _storage.getString(key);
    if (value == null || value.isEmpty) return null;
    try {
      return Direccion.fromJson(
        Map<String, dynamic>.from(jsonDecode(value) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveSelected(Direccion direccion) =>
      _storage.setString(key, jsonEncode(direccion.toJson()));
  @override
  Future<void> clearSelected() => _storage.remove(key);
}
