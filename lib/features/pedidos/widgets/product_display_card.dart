import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/producto.dart';
import '../presentation/producto_asset_resolver.dart';

/// Presentación común de un producto para Pedido y el catálogo público.
class ProductDisplayCard extends StatelessWidget {
  const ProductDisplayCard({
    super.key,
    required this.product,
    required this.title,
    required this.priceLabel,
    this.priceKey,
    this.productSelector,
    this.controls,
  });

  final Producto product;
  final String title;
  final String priceLabel;
  final Key? priceKey;
  final Widget? productSelector;
  final Widget? controls;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Image.asset(
              ProductoAssetResolver.forProducto(product),
              key: ValueKey('product-image-${product.id}'),
              fit: BoxFit.contain,
            ),
          ),
          productSelector ??
              Text(product.descripcion, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            priceLabel,
            key: priceKey ?? ValueKey('product-price-${product.id}'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (controls != null) ...[const SizedBox(height: 8), controls!],
        ],
      ),
    ),
  );
}
