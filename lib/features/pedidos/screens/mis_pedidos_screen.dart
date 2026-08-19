import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../controllers/mis_pedidos_controller.dart';
import '../widgets/pedido_list_item.dart';
import '../widgets/pedido_drawer.dart';

class MisPedidosScreen extends ConsumerStatefulWidget {
  const MisPedidosScreen({super.key});

  @override
  ConsumerState<MisPedidosScreen> createState() => _MisPedidosScreenState();
}

class _MisPedidosScreenState extends ConsumerState<MisPedidosScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(misPedidosControllerProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<MisPedidosState>(misPedidosControllerProvider, (previous, next) {
      if (next.status == MisPedidosStatus.ready &&
          next.error != null &&
          next.error != previous?.error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });
    final state = ref.watch(misPedidosControllerProvider);
    return Scaffold(
      drawer: const PedidoDrawer(),
      appBar: AppBar(
        foregroundColor: AppColors.white,
        title: const Text(
          'Mis Pedidos',
          style: TextStyle(color: AppColors.white),
        ),
        actions: [
          IconButton(
            tooltip: 'Recargar pedidos',
            color: AppColors.white,
            onPressed:
                state.refreshing
                    ? null
                    : () => ref
                        .read(misPedidosControllerProvider.notifier)
                        .load(refresh: true),
            icon:
                state.refreshing
                    ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                    : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: switch (state.status) {
        MisPedidosStatus.idle || MisPedidosStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        MisPedidosStatus.error => _HistoryError(
          message: state.error ?? 'No fue posible consultar tus pedidos.',
          onRetry: () => ref.read(misPedidosControllerProvider.notifier).load(),
        ),
        MisPedidosStatus.ready when state.pedidos.isEmpty => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No tienes pedidos registrados.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        MisPedidosStatus.ready => ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: state.pedidos.length,
          itemBuilder: (context, index) {
            final pedido = state.pedidos[index];
            return PedidoListItem(
              pedido: pedido,
              onTap: () => context.push('/mis-pedidos/${pedido.id}'),
            );
          },
        ),
      },
    );
  }
}

class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.message, required this.onRetry});
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
