import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/carrito_controller.dart';
import '../models/item_pedido.dart';

class CarritoScreen extends ConsumerWidget {
  const CarritoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(carritoControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito'),
        actions: [
          if (cart.items.isNotEmpty)
            TextButton(
              onPressed:
                  () => ref.read(carritoControllerProvider.notifier).clear(),
              child: const Text('Limpiar'),
            ),
        ],
      ),
      body:
          cart.items.isEmpty
              ? const Center(child: Text('Tu carrito está vacío.'))
              : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: cart.items.length + 1,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, index) {
                  if (index == cart.items.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            formatoMoneda(cart.totalCentavos),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }
                  final item = cart.items[index];
                  return ListTile(
                    title: Text(item.descripcion),
                    subtitle: Text(
                      'Cantidad: ${_cantidad(item.cantidad)} · ${formatoMoneda(item.importeCentavos)}',
                    ),
                    trailing: IconButton(
                      tooltip: 'Eliminar',
                      onPressed:
                          () => ref
                              .read(carritoControllerProvider.notifier)
                              .eliminarLinea(index),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  );
                },
              ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: () => context.push('/confirmacion'),
          child: const Text('Continuar'),
        ),
      ),
    );
  }

  String _cantidad(double value) =>
      value == value.roundToDouble()
          ? value.toInt().toString()
          : value.toStringAsFixed(2);
}
