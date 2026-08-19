import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_storage.dart';
import '../../../core/storage/local_storage_provider.dart';
import '../models/item_pedido.dart';

abstract interface class CarritoStore {
  List<ItemPedido> read();
  Future<void> save(List<ItemPedido> items);
}

final class CarritoStorage implements CarritoStore {
  const CarritoStorage(this._storage);
  static const storageKey = 'pedido';
  final LocalStorage _storage;

  @override
  List<ItemPedido> read() {
    final value = _storage.getString(storageKey);
    if (value == null || value.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(value) as List;
      return decoded
          .map((item) => ItemPedido.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> save(List<ItemPedido> items) => _storage.setString(
    storageKey,
    jsonEncode(items.map((item) => item.toJson()).toList()),
  );
}

final carritoStoreProvider = Provider<CarritoStore>(
  (ref) => CarritoStorage(ref.watch(localStorageProvider)),
);
