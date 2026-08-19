import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_storage.dart';
import '../../../core/storage/local_storage_provider.dart';
import '../models/create_order.dart';

abstract interface class UltimoPedidoStore {
  Future<void> save(CreateOrderResult result);
}

final class UltimoPedidoStorage implements UltimoPedidoStore {
  const UltimoPedidoStorage(this._storage);
  static const storageKey = 'ultimo_pedido';
  final LocalStorage _storage;

  @override
  Future<void> save(CreateOrderResult result) => _storage.setString(
    storageKey,
    jsonEncode({'idPedido': result.pedidoId, 'mensaje': result.mensaje}),
  );
}

final ultimoPedidoStoreProvider = Provider<UltimoPedidoStore>(
  (ref) => UltimoPedidoStorage(ref.watch(localStorageProvider)),
);
