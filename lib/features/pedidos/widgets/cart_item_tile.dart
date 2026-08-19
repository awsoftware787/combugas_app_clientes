import 'package:flutter/material.dart';

import '../models/item_pedido.dart';
import '../presentation/producto_asset_resolver.dart';

class CartItemTile extends StatelessWidget {
  const CartItemTile({super.key, required this.item, this.trailing});

  final ItemPedido item;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Semantics(
    label: item.descripcion,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 72,
          height: 72,
          child: Image.asset(
            ProductoAssetResolver.forItem(item),
            key: ValueKey('producto-${item.productoId}-imagen'),
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.descripcion,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (item.presentacion.trim().isNotEmpty &&
                  item.presentacion.trim() != item.descripcion.trim())
                Text(item.presentacion),
              Text('Cantidad: ${formatoCantidad(item.cantidad)}'),
              Text(
                formatoMoneda(item.importeCentavos),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

String formatoCantidad(double value) =>
    value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
