import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../controllers/carrito_controller.dart';
import '../controllers/pedido_controller.dart';
import '../models/item_pedido.dart';
import '../models/producto.dart';
import 'cart_item_tile.dart';

class CartItemControls extends ConsumerWidget {
  const CartItemControls({
    super.key,
    required this.item,
    required this.index,
    this.enabled = true,
  });

  final ItemPedido item;
  final int index;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _QuantityButton(
        key: ValueKey('cart-item-minus-$index'),
        tooltip: 'Disminuir cantidad',
        icon: Icons.remove,
        onPressed: enabled ? () => _decrementOrRemove(context, ref) : null,
      ),
      SizedBox(
        width: 36,
        child: Text(
          formatoCantidad(item.cantidad),
          key: ValueKey('cart-item-quantity-$index'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      _QuantityButton(
        key: ValueKey('cart-item-plus-$index'),
        tooltip: 'Aumentar cantidad',
        icon: Icons.add,
        onPressed: enabled ? () => _increase(context, ref) : null,
      ),
      const SizedBox(width: 4),
      IconButton(
        key: ValueKey('cart-item-delete-$index'),
        tooltip: 'Eliminar',
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        onPressed: enabled ? () => _confirmAndRemove(context, ref) : null,
        icon: const Icon(Icons.delete_outline, color: AppColors.accent),
      ),
    ],
  );

  Future<void> _decrementOrRemove(BuildContext context, WidgetRef ref) async {
    if (await _changeCroquettes(context, ref, -1)) return;
    final changed = await ref
        .read(carritoControllerProvider.notifier)
        .disminuirLinea(index);
    if (changed || !context.mounted) return;
    await _confirmAndRemove(context, ref);
  }

  Future<void> _increase(BuildContext context, WidgetRef ref) async {
    if (await _changeCroquettes(context, ref, 1)) return;
    await ref.read(carritoControllerProvider.notifier).incrementarLinea(index);
  }

  Future<bool> _changeCroquettes(
    BuildContext context,
    WidgetRef ref,
    int direction,
  ) async {
    final product = Producto(
      id: item.productoId,
      descripcion: item.descripcion,
      presentacion: item.presentacion,
      servicioId: item.servicioId,
      precioCentavos: 0,
    );
    if (!product.esCroqueta2Kg) return false;
    final minimums = ref.read(pedidoControllerProvider).montosMinimos;
    final quantity =
        item.cantidad.toInt() + direction * minimums.incremento(product);
    final error = minimums.validarCantidad(product, quantity);
    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
    } else {
      await ref
          .read(carritoControllerProvider.notifier)
          .actualizarCantidad(index, quantity.toDouble());
    }
    return true;
  }

  Future<void> _confirmAndRemove(BuildContext context, WidgetRef ref) async {
    final accepted = await showRemoveProductDialog(context);
    if (!accepted || !context.mounted) return;
    await ref.read(carritoControllerProvider.notifier).eliminarLinea(index);
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    visualDensity: VisualDensity.compact,
    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    style: IconButton.styleFrom(foregroundColor: AppColors.quantityButtonBlue),
    onPressed: onPressed,
    icon: Icon(icon, size: 20),
  );
}

Future<bool> showRemoveProductDialog(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Quitar producto'),
            content: const Text('¿Deseas quitar este producto del pedido?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('No'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Sí, quitar'),
              ),
            ],
          ),
    ) ??
    false;
