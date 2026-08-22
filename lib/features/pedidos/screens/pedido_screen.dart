import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/branded_app_bar_title.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../direcciones/controllers/direccion_controller.dart';
import '../../direcciones/models/direccion.dart';
import '../controllers/carrito_controller.dart';
import '../controllers/pedido_controller.dart';
import '../models/item_pedido.dart';
import '../models/producto.dart';
import '../presentation/product_catalog.dart';
import '../widgets/pedido_drawer.dart';
import '../widgets/product_display_card.dart';
import '../widgets/product_option_selector.dart';

class PedidoScreen extends ConsumerStatefulWidget {
  const PedidoScreen({super.key});

  @override
  ConsumerState<PedidoScreen> createState() => _PedidoScreenState();
}

class _PedidoScreenState extends ConsumerState<PedidoScreen> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await Future.wait([
        ref.read(direccionControllerProvider.notifier).load(),
        ref.read(pedidoControllerProvider.notifier).load(),
      ]);
      if (!mounted) return;
      final hour = DateTime.now().hour;
      if (hour < 7 || hour > 19) {
        _message('El horario de servicio es de 7:00 a.m. a 8:00 p.m.');
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PedidoState>(pedidoControllerProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _message(next.error!);
        });
      }
    });
    final pedido = ref.watch(pedidoControllerProvider);
    final direcciones = ref.watch(direccionControllerProvider);
    final carrito = ref.watch(carritoControllerProvider);
    final pages = _pages(pedido);
    if (_page >= pages.length && pages.isNotEmpty) _page = pages.length - 1;

    return Scaffold(
      drawer: const PedidoDrawer(),
      appBar: AppBar(
        foregroundColor: AppColors.white,
        title: const BrandedAppBarTitle('Pedido'),
        actions: [
          TextButton(
            key: const ValueKey('clear-order'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accent,
              disabledForegroundColor: Colors.white54,
            ),
            onPressed:
                carrito.items.isEmpty
                    ? null
                    : () =>
                        ref.read(carritoControllerProvider.notifier).clear(),
            child: const Text('Limpiar'),
          ),
          IconButton(
            tooltip: 'Actualizar productos',
            color: AppColors.white,
            onPressed:
                pedido.refreshing
                    ? null
                    : () => ref
                        .read(pedidoControllerProvider.notifier)
                        .load(refresh: true),
            icon:
                pedido.refreshing
                    ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.refresh),
          ),
          _CartButton(count: carrito.lineas, onPressed: _openCart),
        ],
      ),
      body: SafeArea(
        child: switch (pedido.status) {
          PedidoStatus.idle || PedidoStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          PedidoStatus.error => _LoadError(
            message: pedido.error ?? 'No fue posible cargar los productos.',
            onRetry: () => ref.read(pedidoControllerProvider.notifier).load(),
          ),
          PedidoStatus.ready => ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              _DireccionSelector(
                state: direcciones,
                onSelect:
                    (item) => ref
                        .read(direccionControllerProvider.notifier)
                        .select(item),
                onAdd: _addAddress,
                onRetry:
                    () => ref.read(direccionControllerProvider.notifier).load(),
              ),
              const SizedBox(height: 18),
              if (pages.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Text(
                    'El servidor no devolvió productos disponibles.',
                    textAlign: TextAlign.center,
                  ),
                )
              else ...[
                SizedBox(
                  height: 430,
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (value) => setState(() => _page = value),
                    children: pages,
                  ),
                ),
                const SizedBox(height: 8),
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
                      icon: Image.asset(
                        AppAssets.previousImage,
                        width: 24,
                        height: 24,
                      ),
                    ),
                    ...List.generate(
                      pages.length,
                      (index) => Container(
                        width: index == _page ? 20 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color:
                              index == _page
                                  ? AppColors.accent
                                  : Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Producto siguiente',
                      onPressed:
                          _page == pages.length - 1
                              ? null
                              : () => _pageController.nextPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              ),
                      icon: Image.asset(
                        AppAssets.nextImage,
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _continue,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continuar'),
              ),
            ],
          ),
        },
      ),
    );
  }

  List<Widget> _pages(PedidoState state) {
    final session = ref.read(authControllerProvider).session;
    final subchannel = session?.subcanalUsuario ?? 0;
    return buildProductCatalog(state.productos).map((group) {
      if (group.isStationary) {
        return _StationaryPage(
          key: ValueKey(group.key),
          product: group.products.single,
          minimums: state.montosMinimos,
        );
      }
      return _ProductPage(
        key: ValueKey(group.key),
        title: group.title,
        products: group.products,
        subchannel: subchannel,
      );
    }).toList();
  }

  Future<void> _addAddress() async {
    await context.push('/direcciones/nueva');
    if (mounted) await ref.read(direccionControllerProvider.notifier).load();
  }

  void _continue() {
    if (!_hasAddress()) return;
    context.push('/confirmacion');
  }

  void _openCart() {
    if (!_hasAddress()) return;
    context.push('/carrito');
  }

  bool _hasAddress() {
    if (ref.read(direccionControllerProvider).selected != null) return true;
    _message('Selecciona una dirección de entrega para continuar.');
    return false;
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DireccionSelector extends StatelessWidget {
  const _DireccionSelector({
    required this.state,
    required this.onSelect,
    required this.onAdd,
    required this.onRetry,
  });
  final DireccionState state;
  final ValueChanged<Direccion> onSelect;
  final VoidCallback onAdd;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.status == DireccionStatus.loading ||
        state.status == DireccionStatus.idle) {
      return const _DireccionSelectorSkeleton();
    }
    if (state.status == DireccionStatus.error) {
      return Row(
        children: [
          Expanded(
            child: Text(state.error ?? 'No se cargaron las direcciones.'),
          ),
          IconButton(onPressed: onRetry, icon: const Icon(Icons.refresh)),
        ],
      );
    }
    if (state.direcciones.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('No tienes una dirección registrada.'),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_location_alt),
                label: const Text('Agregar dirección'),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dirección de entrega',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<Direccion>(
          value: state.selected,
          isExpanded: true,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.home, color: AppColors.accent),
          ),
          items:
              state.direcciones
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(
                        item.etiqueta,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
          onChanged: (item) {
            if (item != null) onSelect(item);
          },
        ),
        if (state.selected != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${state.selected!.calleCompleta}, COLONIA ${state.selected!.colonia}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

class _DireccionSelectorSkeleton extends StatelessWidget {
  const _DireccionSelectorSkeleton();

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const ValueKey('direcciones-skeleton'),
    height: 116,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dirección de entrega',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(36),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: FractionallySizedBox(
            widthFactor: 0.68,
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.menuBackground.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ProductPage extends ConsumerStatefulWidget {
  const _ProductPage({
    super.key,
    required this.title,
    required this.products,
    required this.subchannel,
  });
  final String title;
  final List<Producto> products;
  final int subchannel;

  @override
  ConsumerState<_ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends ConsumerState<_ProductPage> {
  int _quantity = 1;
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) {
      return const Center(child: Text('Producto no disponible.'));
    }
    if (_selected >= widget.products.length) _selected = 0;
    final product = widget.products[_selected];
    final label =
        product.esCroqueta ? product.opcionCroqueta : product.descripcion;
    return ProductDisplayCard(
      product: product,
      title: widget.title,
      priceLabel: formatoMoneda(product.precioCentavos * _quantity),
      priceKey: const ValueKey('product-amount'),
      productSelector:
          ProductOptionSelector.supports(product)
              ? ProductOptionSelector(
                products: widget.products,
                selectedIndex: _selected,
                onSelected: (value) => setState(() => _selected = value),
                layout: ProductOptionSelectorLayout.segments,
              )
              : Text(label, textAlign: TextAlign.center),
      controls: Row(
        children: [
          Expanded(
            flex: 5,
            child: _QuantitySelector(
              quantity: _quantity,
              onDecrease:
                  _quantity > 1 ? () => setState(() => _quantity--) : null,
              onIncrease: () => setState(() => _quantity++),
              onReset: () => setState(() => _quantity = 1),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: SizedBox(
              height: 48,
              child: FilledButton.icon(
                key: const ValueKey('product-add'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.addButtonGreen,
                  foregroundColor: AppColors.white,
                ),
                onPressed: () async {
                  final result = await ref
                      .read(carritoControllerProvider.notifier)
                      .agregarProducto(
                        producto: product,
                        cantidad: _quantity,
                        subcanalUsuario: widget.subchannel,
                      );
                  if (!context.mounted) return;
                  if (result.agregado) {
                    setState(() => _quantity = 1);
                  }
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(result.mensaje)));
                },
                icon: const Icon(Icons.shopping_cart_outlined, size: 20),
                label: const Text('Agregar'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  const _QuantitySelector({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
    required this.onReset,
  });

  final int quantity;
  final VoidCallback? onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    decoration: BoxDecoration(
      color: AppColors.white,
      border: Border.all(color: AppColors.quantityButtonBlue),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        IconButton(
          key: const ValueKey('quantity-minus'),
          style: IconButton.styleFrom(
            foregroundColor: AppColors.quantityButtonBlue,
            disabledForegroundColor: AppColors.quantityButtonBlue,
          ),
          constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
          padding: EdgeInsets.zero,
          onPressed: onDecrease,
          onLongPress: onReset,
          icon: const Icon(Icons.remove, size: 20),
        ),
        Expanded(
          child: Text(
            '$quantity',
            key: const ValueKey('quantity-value'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          key: const ValueKey('quantity-plus'),
          style: IconButton.styleFrom(
            foregroundColor: AppColors.quantityButtonBlue,
          ),
          constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
          padding: EdgeInsets.zero,
          onPressed: onIncrease,
          onLongPress: onReset,
          icon: const Icon(Icons.add, size: 20),
        ),
      ],
    ),
  );
}

enum _StationaryMode { importe, litros }

class _StationaryPage extends ConsumerStatefulWidget {
  const _StationaryPage({
    super.key,
    required this.product,
    required this.minimums,
  });
  final Producto product;
  final MontosMinimos minimums;

  @override
  ConsumerState<_StationaryPage> createState() => _StationaryPageState();
}

class _StationaryPageState extends ConsumerState<_StationaryPage> {
  final _controller = TextEditingController();
  _StationaryMode _mode = _StationaryMode.importe;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ProductDisplayCard(
    product: widget.product,
    title: 'Gas estacionario',
    priceCaption: 'Importe por litro:',
    priceLabel: formatoMoneda(widget.product.precioCentavos),
    priceKey: const ValueKey('stationary-amount'),
    productSelector: SegmentedButton<_StationaryMode>(
      style: const ButtonStyle(
        side: WidgetStatePropertyAll(BorderSide(color: AppColors.secondary)),
      ),
      segments: const [
        ButtonSegment(value: _StationaryMode.importe, label: Text('Importe')),
        ButtonSegment(value: _StationaryMode.litros, label: Text('Litros')),
      ],
      selected: {_mode},
      onSelectionChanged: (value) {
        setState(() {
          _mode = value.first;
          _controller.clear();
        });
      },
    ),
    controls: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              labelText:
                  _mode == _StationaryMode.importe
                      ? 'Monto en pesos'
                      : 'Cantidad de litros',
              prefixText: _mode == _StationaryMode.importe ? '\$ ' : null,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.addButtonGreen,
              foregroundColor: AppColors.white,
            ),
            onPressed: _add,
            icon: const Icon(Icons.shopping_cart_outlined, size: 20),
            label: const Text('Agregar'),
          ),
        ),
      ],
    ),
  );

  Future<void> _add() async {
    final value = double.tryParse(_controller.text);
    if (value == null || value <= 0) {
      _show('Ingresa una cantidad válida.');
      return;
    }
    final controller = ref.read(carritoControllerProvider.notifier);
    final result =
        _mode == _StationaryMode.importe
            ? await controller.agregarEstacionarioPorImporte(
              producto: widget.product,
              importeCentavos: (value * 100).round(),
              minimos: widget.minimums,
            )
            : await controller.agregarEstacionarioPorLitros(
              producto: widget.product,
              litros: value,
              minimos: widget.minimums,
            );
    if (!mounted) return;
    if (result.agregado) _controller.clear();
    _show(result.mensaje);
  }

  void _show(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class _CartButton extends StatelessWidget {
  const _CartButton({required this.count, required this.onPressed});
  final int count;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      IconButton(
        tooltip: 'Carrito',
        onPressed: onPressed,
        icon: Image.asset(AppAssets.iconCart, width: 26, height: 26),
      ),
      if (count > 0)
        Positioned(
          right: 3,
          top: 2,
          child: Container(
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$count',
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ),
    ],
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 52),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}
