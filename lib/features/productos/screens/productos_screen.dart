import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../pedidos/models/item_pedido.dart';
import '../../pedidos/models/producto.dart';
import '../../pedidos/widgets/product_display_card.dart';
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
    final productos = state.productos;
    if (_page >= productos.length && productos.isNotEmpty) {
      _page = productos.length - 1;
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        actions: [
          IconButton(
            tooltip: 'Actualizar productos',
            onPressed:
                state.refreshing
                    ? null
                    : () => ref
                        .read(productosControllerProvider.notifier)
                        .load(refresh: true),
            icon:
                state.refreshing
                    ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: switch (state.status) {
          ProductosStatus.idle || ProductosStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          ProductosStatus.error => _ProductsError(
            onRetry:
                () => ref.read(productosControllerProvider.notifier).load(),
          ),
          ProductosStatus.ready => ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              if (productos.isEmpty)
                const SizedBox(
                  height: 420,
                  child: Center(child: Text('No hay productos disponibles.')),
                )
              else ...[
                SizedBox(
                  height: 430,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: productos.length,
                    onPageChanged: (value) => setState(() => _page = value),
                    itemBuilder: (context, index) {
                      final product = productos[index];
                      return ProductDisplayCard(
                        product: product,
                        title: _title(product),
                        priceLabel:
                            product.id == ProductoIds.estacionario
                                ? 'Precio por litro: ${formatoMoneda(product.precioCentavos)}'
                                : 'Precio: ${formatoMoneda(product.precioCentavos)}',
                        productSelector: Text(
                          product.esCroqueta
                              ? product.opcionCroqueta
                              : product.descripcion,
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Producto anterior',
                      onPressed:
                          _page == 0
                              ? null
                              : () => _pageController.previousPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              ),
                      icon: Image.asset(AppAssets.previousImage, width: 24),
                    ),
                    Text('${_page + 1} / ${productos.length}'),
                    IconButton(
                      tooltip: 'Producto siguiente',
                      onPressed:
                          _page == productos.length - 1
                              ? null
                              : () => _pageController.nextPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              ),
                      icon: Image.asset(AppAssets.nextImage, width: 24),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                key: const ValueKey('public-products-continue'),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/login');
                  }
                },
                child: const Text('Continuar'),
              ),
            ],
          ),
        },
      ),
    );
  }

  String _title(Producto product) {
    if (product.id == ProductoIds.estacionario) return 'Gas estacionario';
    if (product.esCroqueta) return 'Croquetas';
    if (product.id == ProductoIds.cilindro30 ||
        product.id == ProductoIds.cilindro45) {
      return 'Gas en cilindro';
    }
    return product.presentacion.isEmpty
        ? product.descripcion
        : product.presentacion;
  }
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
