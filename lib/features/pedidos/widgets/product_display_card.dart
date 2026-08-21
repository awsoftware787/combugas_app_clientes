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
    this.priceCaption = 'Importe:',
    this.priceKey,
    this.productSelector,
    this.controls,
  });

  final Producto product;
  final String title;
  final String priceLabel;
  final String priceCaption;
  final Key? priceKey;
  final Widget? productSelector;
  final Widget? controls;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
    color: AppColors.white,
    surfaceTintColor: AppColors.white,
    elevation: 2,
    shadowColor: AppColors.shadowOverlay.withValues(alpha: 0.14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 38),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.menuBackgroundDark,
                fontWeight: FontWeight.w700,
              ),
            ),
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
          const SizedBox(height: 10),
          Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.06),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.16),
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.sell_outlined,
                  size: 20,
                  color: AppColors.menuBackgroundDark,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    priceCaption,
                    style: const TextStyle(
                      color: AppColors.menuBackgroundDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  priceLabel,
                  key: priceKey ?? ValueKey('product-price-${product.id}'),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (controls != null) ...[const SizedBox(height: 10), controls!],
        ],
      ),
    ),
  );
}
