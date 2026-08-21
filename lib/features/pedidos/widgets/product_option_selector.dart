import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/producto.dart';

enum ProductOptionSelectorLayout { circles, cards, segments }

/// Selector visual compartido para presentaciones de cilindros y croquetas.
class ProductOptionSelector extends StatelessWidget {
  const ProductOptionSelector({
    super.key,
    required this.products,
    required this.selectedIndex,
    required this.onSelected,
    this.layout = ProductOptionSelectorLayout.circles,
  });

  final List<Producto> products;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final ProductOptionSelectorLayout layout;

  static bool supports(Producto product) =>
      product.esCroqueta ||
      product.id == ProductoIds.cilindro30 ||
      product.id == ProductoIds.cilindro45;

  static String labelFor(Producto product) {
    if (product.id == ProductoIds.cilindro30 ||
        product.id == ProductoIds.cilindro45) {
      final match = RegExp(
        r'(\d+)\s*kg',
        caseSensitive: false,
      ).firstMatch('${product.presentacion} ${product.descripcion}');
      if (match != null) return '${match.group(1)}kg';
    }
    return product.esCroqueta ? product.opcionCroqueta : product.descripcion;
  }

  @override
  Widget build(BuildContext context) => switch (layout) {
    ProductOptionSelectorLayout.circles => _buildCircles(),
    ProductOptionSelectorLayout.cards => _buildCards(context),
    ProductOptionSelectorLayout.segments => _buildSegments(),
  };

  Widget _buildSegments() => _SegmentOptionSelector(
    products: products,
    selectedIndex: selectedIndex,
    onSelected: onSelected,
  );

  Widget _buildCards(BuildContext context) => SizedBox(
    height: 64,
    child: LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final availableWidth = constraints.maxWidth;
        final itemWidth =
            products.length <= 2
                ? ((availableWidth - gap * (products.length - 1)) /
                        products.length)
                    .clamp(120.0, 220.0)
                : 136.0;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: availableWidth),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: List.generate(products.length, (index) {
                final product = products[index];
                final selected = index == selectedIndex;
                final color = selected ? AppColors.accent : AppColors.secondary;
                return Padding(
                  padding: EdgeInsets.only(
                    right: index == products.length - 1 ? 0 : gap,
                  ),
                  child: Semantics(
                    button: true,
                    selected: selected,
                    label: labelFor(product),
                    child: AnimatedContainer(
                      key: ValueKey('product-option-${product.id}'),
                      duration: const Duration(milliseconds: 180),
                      width: itemWidth,
                      height: 58,
                      decoration: BoxDecoration(
                        color:
                            selected
                                ? AppColors.accent.withValues(alpha: 0.06)
                                : AppColors.white,
                        border: Border.all(
                          color: color,
                          width: selected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => onSelected(index),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: color,
                                  ),
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    labelFor(product),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color:
                                          selected
                                              ? AppColors.accent
                                              : AppColors.menuBackground,
                                      fontWeight:
                                          selected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    ),
  );

  Widget _buildCircles() => SizedBox(
    height: 64,
    child: LayoutBuilder(
      builder:
          (context, constraints) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: List.generate(products.length, (index) {
                  final product = products[index];
                  final selected = index == selectedIndex;
                  final label = labelFor(product);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Semantics(
                      button: true,
                      selected: selected,
                      label: label,
                      child: AnimatedContainer(
                        key: ValueKey('product-option-${product.id}'),
                        duration: const Duration(milliseconds: 180),
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              selected ? AppColors.accent : AppColors.secondary,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => onSelected(index),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Center(
                                child: Text(
                                  label,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color:
                                        selected
                                            ? AppColors.white
                                            : Colors.black38,
                                    fontSize: label.length > 10 ? 9 : 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
    ),
  );
}

class _SegmentOptionSelector extends StatefulWidget {
  const _SegmentOptionSelector({
    required this.products,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<Producto> products;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  State<_SegmentOptionSelector> createState() => _SegmentOptionSelectorState();
}

class _SegmentOptionSelectorState extends State<_SegmentOptionSelector> {
  static const _gap = 6.0;
  static const _arrowWidth = 28.0;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _scroll(double distance) async {
    if (!_scrollController.hasClients) return;
    final target = (_scrollController.offset + distance).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    await _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final showArrows = widget.products.length > 3;
        final selectorWidth =
            constraints.maxWidth - (showArrows ? _arrowWidth * 2 : 0);
        final visibleItems = widget.products.length.clamp(1, 3);
        final itemWidth =
            (selectorWidth - _gap * (visibleItems - 1)) / visibleItems;
        final scrollStep = itemWidth + _gap;

        return Row(
          children: [
            if (showArrows)
              _ScrollArrow(
                key: const ValueKey('product-options-previous'),
                icon: Icons.chevron_left_rounded,
                tooltip: 'Presentaciones anteriores',
                onPressed: () => _scroll(-scrollStep),
              ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: selectorWidth),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(widget.products.length, (index) {
                      final product = widget.products[index];
                      final selected = index == widget.selectedIndex;
                      return Padding(
                        padding: EdgeInsets.only(
                          right: index == widget.products.length - 1 ? 0 : _gap,
                        ),
                        child: Semantics(
                          button: true,
                          selected: selected,
                          label: ProductOptionSelector.labelFor(product),
                          child: AnimatedContainer(
                            key: ValueKey('product-option-${product.id}'),
                            duration: const Duration(milliseconds: 180),
                            width: itemWidth,
                            height: 48,
                            decoration: BoxDecoration(
                              color:
                                  selected ? AppColors.accent : AppColors.white,
                              border: Border.all(
                                color:
                                    selected
                                        ? AppColors.accent
                                        : AppColors.secondary,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => widget.onSelected(index),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (selected) ...[
                                        const Icon(
                                          Icons.check_rounded,
                                          size: 16,
                                          color: AppColors.white,
                                        ),
                                        const SizedBox(width: 3),
                                      ],
                                      Flexible(
                                        child: Text(
                                          ProductOptionSelector.labelFor(
                                            product,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color:
                                                selected
                                                    ? AppColors.white
                                                    : AppColors
                                                        .menuBackgroundDark,
                                            fontSize: 12,
                                            fontWeight:
                                                selected
                                                    ? FontWeight.w700
                                                    : FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
            if (showArrows)
              _ScrollArrow(
                key: const ValueKey('product-options-next'),
                icon: Icons.chevron_right_rounded,
                tooltip: 'Más presentaciones',
                onPressed: () => _scroll(scrollStep),
              ),
          ],
        );
      },
    ),
  );
}

class _ScrollArrow extends StatelessWidget {
  const _ScrollArrow({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: _SegmentOptionSelectorState._arrowWidth,
    height: 48,
    child: IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 27, color: AppColors.menuBackgroundDark),
    ),
  );
}
