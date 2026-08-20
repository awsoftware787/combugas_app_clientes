import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/branded_app_bar_title.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/pedido_detalle_controller.dart';
import '../models/item_pedido.dart';
import '../presentation/pedido_formatters.dart';
import '../widgets/cart_item_tile.dart';
import '../widgets/pedido_list_item.dart';

class PedidoDetalleScreen extends ConsumerStatefulWidget {
  const PedidoDetalleScreen({super.key, required this.pedidoId});
  final int pedidoId;

  @override
  ConsumerState<PedidoDetalleScreen> createState() =>
      _PedidoDetalleScreenState();
}

class _PedidoDetalleScreenState extends ConsumerState<PedidoDetalleScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(pedidoDetalleControllerProvider.notifier)
          .load(widget.pedidoId),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PedidoDetalleState>(pedidoDetalleControllerProvider, (
      previous,
      next,
    ) async {
      if (next.sessionLocked && previous?.sessionLocked != true) {
        await ref.read(authControllerProvider.notifier).logout();
        if (context.mounted) context.go('/productos');
      }
    });
    final state = ref.watch(pedidoDetalleControllerProvider);
    return Scaffold(
      appBar: AppBar(
        foregroundColor: AppColors.white,
        title: const BrandedAppBarTitle('Detalle del pedido'),
        actions: [
          IconButton(
            tooltip: 'Recargar pedido',
            color: AppColors.white,
            onPressed:
                state.canceling
                    ? null
                    : () => ref
                        .read(pedidoDetalleControllerProvider.notifier)
                        .load(widget.pedidoId, refresh: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: switch (state.status) {
        PedidoDetalleStatus.idle || PedidoDetalleStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        PedidoDetalleStatus.error when state.pedido == null => _DetailError(
          message: state.error ?? 'No fue posible consultar el pedido.',
          onRetry:
              () => ref
                  .read(pedidoDetalleControllerProvider.notifier)
                  .load(widget.pedidoId, refresh: true),
        ),
        _ => _PedidoDetailBody(
          state: state,
          onCancel: _cancel,
          onTracking: () => context.push('/seguimiento/${widget.pedidoId}'),
        ),
      },
    );
  }

  Future<void> _cancel() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Cancelar'),
            content: const Text('¿Está seguro de cancelar su pedido?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('No'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Sí'),
              ),
            ],
          ),
    );
    if (accepted != true || !mounted) return;
    final success =
        await ref.read(pedidoDetalleControllerProvider.notifier).cancel();
    if (!mounted) return;
    final message =
        success
            ? 'El pedido fue cancelado.'
            : ref.read(pedidoDetalleControllerProvider).error;
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _PedidoDetailBody extends StatelessWidget {
  const _PedidoDetailBody({
    required this.state,
    required this.onCancel,
    required this.onTracking,
  });
  final PedidoDetalleState state;
  final VoidCallback onCancel;
  final VoidCallback onTracking;

  @override
  Widget build(BuildContext context) {
    final pedido = state.pedido!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoTile(
          asset: AppAssets.iconAddress,
          label: 'Dirección:',
          value: pedido.direccion.direccionCompleta,
        ),
        const Divider(),
        _InfoTile(
          asset:
              pedido.metodoPago.toLowerCase() == 'tarjeta'
                  ? AppAssets.iconCard
                  : AppAssets.iconCash,
          label: 'Forma de pago:',
          value: pedido.metodoPago,
        ),
        const Divider(),
        Text('Productos', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...pedido.productos.map(
          (product) => Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: CartItemTile(item: product.toCartItem()),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              formatoMoneda(pedido.totalCentavos),
              key: const ValueKey('pedido-detail-total'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const Divider(height: 32),
        Row(
          children: [
            Expanded(
              child: _LabelValue(
                label: 'Fecha:',
                value: formatoFechaPedido(pedido.fecha),
              ),
            ),
            Expanded(
              child: _LabelValue(
                label: 'Estatus:',
                value: pedidoStatusLabel(pedido.status),
                color: pedidoStatusColor(pedido.status),
              ),
            ),
          ],
        ),
        if (state.error != null) ...[
          const SizedBox(height: 12),
          Text(
            state.error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (pedido.puedeCancelar) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                  ),
                  onPressed: state.canceling ? null : onCancel,
                  child:
                      state.canceling
                          ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Cancelar Pedido'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.menuBackground,
                    foregroundColor: AppColors.white,
                  ),
                  onPressed: state.canceling ? null : onTracking,
                  child: const Text('Seguimiento'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.asset,
    required this.label,
    required this.value,
  });
  final String asset;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Image.asset(asset, width: 48, height: 48, fit: BoxFit.contain),
      const SizedBox(width: 12),
      Expanded(child: _LabelValue(label: label, value: value)),
    ],
  );
}

class _LabelValue extends StatelessWidget {
  const _LabelValue({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: AppColors.accent,
          fontWeight: FontWeight.bold,
        ),
      ),
      Text(value, style: TextStyle(color: color)),
    ],
  );
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
