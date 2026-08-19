import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../controllers/carrito_controller.dart';
import '../models/item_pedido.dart';
import '../widgets/cart_item_tile.dart';

class CarritoScreen extends ConsumerWidget {
  const CarritoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(carritoControllerProvider);
    return Scaffold(
      appBar: AppBar(
        foregroundColor: AppColors.white,
        title: const Text('Carrito', style: TextStyle(color: AppColors.white)),
        actions: [
          if (cart.items.isNotEmpty)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.white),
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
                  return CartItemTile(
                    item: item,
                    trailing: IconButton(
                      tooltip: 'Eliminar',
                      onPressed:
                          () => ref
                              .read(carritoControllerProvider.notifier)
                              .eliminarLinea(index),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.accent,
                      ),
                    ),
                  );
                },
              ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed:
              cart.items.isEmpty ? null : () => context.push('/confirmacion'),
          child: const Text('Continuar'),
        ),
      ),
    );
  }
}
