import 'package:flutter/material.dart';

import '../models/item_pedido.dart';
import '../models/producto.dart';
import 'producto_icono.dart';

class CartItemTile extends StatelessWidget {
  const CartItemTile({
    super.key,
    required this.item,
    this.controls,
    this.productoCatalogo,
    this.historicalFallback = false,
  });

  final ItemPedido item;
  final Widget? controls;
  final Producto? productoCatalogo;
  final bool historicalFallback;

  @override
  Widget build(BuildContext context) => Semantics(
    label: item.descripcion,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 72,
          height: 72,
          child: ProductoIcono.item(
            item: item,
            productoCatalogo: productoCatalogo,
            genericFallback: historicalFallback && productoCatalogo == null,
            imageKey: ValueKey('producto-${item.productoId}-imagen'),
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
              if (controls != null) ...[
                const SizedBox(height: 4),
                Align(alignment: Alignment.centerRight, child: controls!),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

String formatoCantidad(double value) =>
    value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
