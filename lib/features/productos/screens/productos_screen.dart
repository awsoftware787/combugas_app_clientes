import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/branded_app_bar_title.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../pedidos/models/item_pedido.dart';
import '../../pedidos/models/producto.dart';
import '../../pedidos/presentation/product_catalog.dart';
import '../../pedidos/presentation/producto_asset_resolver.dart';
import '../../pedidos/widgets/pedido_drawer.dart';
import '../../pedidos/widgets/product_option_selector.dart';
import '../controllers/productos_controller.dart';

class ProductosRouteScreen extends ConsumerWidget {
  const ProductosRouteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(authControllerProvider).session != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/pedido');
      });
      return const SizedBox.shrink();
    }
    return const ProductosScreen();
  }
}

class ProductosScreen extends ConsumerStatefulWidget {
  const ProductosScreen({super.key});

  @override
  ConsumerState<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends ConsumerState<ProductosScreen> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(productosControllerProvider.notifier).load(),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productosControllerProvider);
    final catalog = buildProductCatalog(state.productos);
    if (_page >= catalog.length && catalog.isNotEmpty) {
      _page = catalog.length - 1;
    }
    return Scaffold(
      drawer: const PedidoDrawer(),
      appBar: AppBar(title: const BrandedAppBarTitle('Productos')),
      body: SafeArea(
        child: switch (state.status) {
          ProductosStatus.idle || ProductosStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          ProductosStatus.error => _ProductsError(
            onRetry:
                () => ref.read(productosControllerProvider.notifier).load(),
          ),
          ProductosStatus.ready => _buildReadyContent(context, catalog),
        },
      ),
    );
  }

  Widget _buildReadyContent(
    BuildContext context,
    List<ProductCatalogGroup> catalog,
  ) => LayoutBuilder(
    builder: (context, constraints) {
      final contentWidth =
          constraints.maxWidth > 600 ? 560.0 : constraints.maxWidth - 40;
      final cardHeight = (contentWidth * 1.15).clamp(430.0, 500.0).toDouble();
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          if (catalog.isEmpty)
            const SizedBox(
              height: 420,
              child: Center(child: Text('No hay productos disponibles.')),
            )
          else ...[
            Center(
              child: SizedBox(
                width: contentWidth,
                height: cardHeight,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: catalog.length,
                  onPageChanged: (value) => setState(() => _page = value),
                  itemBuilder:
                      (context, index) => _PublicProductPage(
                        key: ValueKey(catalog[index].key),
                        group: catalog[index],
                        onPrevious:
                            index == 0
                                ? null
                                : () => _pageController.previousPage(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                ),
                        onNext:
                            index == catalog.length - 1
                                ? null
                                : () => _pageController.nextPage(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                ),
                      ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: SizedBox(
                width: contentWidth,
                child: const _ProductBenefits(),
              ),
            ),
            const SizedBox(height: 14),
            _ProductIndicator(current: _page + 1, total: catalog.length),
          ],
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: contentWidth,
              height: 54,
              child: FilledButton.icon(
                key: const ValueKey('public-products-continue'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/login');
                  }
                },
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text(
                  'Continuar',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _PublicProductPage extends StatefulWidget {
  const _PublicProductPage({
    super.key,
    required this.group,
    required this.onPrevious,
    required this.onNext,
  });

  final ProductCatalogGroup group;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  State<_PublicProductPage> createState() => _PublicProductPageState();
}

class _PublicProductPageState extends State<_PublicProductPage> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    if (_selected >= widget.group.products.length) _selected = 0;
    final product = widget.group.products[_selected];
    final label =
        product.esCroqueta ? product.opcionCroqueta : product.descripcion;
    return _PublicProductCard(
      group: widget.group,
      product: product,
      label: label,
      selectedIndex: _selected,
      onSelected: (value) => setState(() => _selected = value),
      onPrevious: widget.onPrevious,
      onNext: widget.onNext,
    );
  }
}

class _PublicProductCard extends StatelessWidget {
  const _PublicProductCard({
    required this.group,
    required this.product,
    required this.label,
    required this.selectedIndex,
    required this.onSelected,
    required this.onPrevious,
    required this.onNext,
  });

  final ProductCatalogGroup group;
  final Producto product;
  final String label;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadowOverlay.withValues(alpha: 0.12),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Text(
                  group.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.menuBackgroundDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                _CarouselArrow(
                  tooltip: 'Producto anterior',
                  asset: AppAssets.previousImage,
                  onPressed: onPrevious,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Image.asset(
                    ProductoAssetResolver.forProducto(product),
                    key: ValueKey('product-image-${product.id}'),
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 8),
                _CarouselArrow(
                  tooltip: 'Producto siguiente',
                  asset: AppAssets.nextImage,
                  onPressed: onNext,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (ProductOptionSelector.supports(product))
            ProductOptionSelector(
              products: group.products,
              selectedIndex: selectedIndex,
              onSelected: onSelected,
              layout: ProductOptionSelectorLayout.cards,
            )
          else
            SizedBox(
              height: 42,
              child: Center(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.22),
              border: Border.all(color: AppColors.secondary),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.sell_outlined,
                  size: 20,
                  color: AppColors.menuBackground,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group.isStationary ? 'Precio por litro' : 'Precio',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  formatoMoneda(product.precioCentavos),
                  key: ValueKey('product-price-${product.id}'),
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _CarouselArrow extends StatelessWidget {
  const _CarouselArrow({
    required this.tooltip,
    required this.asset,
    required this.onPressed,
  });

  final String tooltip;
  final String asset;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.white,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: AppColors.shadowOverlay.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Opacity(
        opacity: onPressed == null ? 0.3 : 1,
        child: Image.asset(asset, width: 22, height: 22),
      ),
    ),
  );
}

class _ProductBenefits extends StatelessWidget {
  const _ProductBenefits();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
    decoration: BoxDecoration(
      color: AppColors.white,
      border: Border.all(color: AppColors.secondary),
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Benefit(
          icon: Icons.verified_user_outlined,
          title: 'Seguro',
          description: 'Cilindros certificados y de alta calidad',
        ),
        _Benefit(
          icon: Icons.local_shipping_outlined,
          title: 'Confiable',
          description: 'Llevamos el gas hasta tu hogar',
        ),
        _Benefit(
          icon: Icons.support_agent,
          title: 'Atención',
          description: 'Soporte rápido y personalizado',
        ),
      ],
    ),
  );
}

class _Benefit extends StatelessWidget {
  const _Benefit({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Icon(icon, color: AppColors.accent, size: 24),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Text(
            description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.menuBackground,
              fontSize: 10,
              height: 1.2,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ProductIndicator extends StatelessWidget {
  const _ProductIndicator({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const _IndicatorDot(color: AppColors.accent),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text(
          '$current / $total',
          key: const ValueKey('public-products-indicator'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      const _IndicatorDot(color: AppColors.secondary),
    ],
  );
}

class _IndicatorDot extends StatelessWidget {
  const _IndicatorDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 9,
    height: 9,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _ProductsError extends StatelessWidget {
  const _ProductsError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_off, size: 56, color: AppColors.accent),
        const SizedBox(height: 12),
        const Text('No fue posible cargar productos'),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
        ),
      ],
    ),
  );
}
