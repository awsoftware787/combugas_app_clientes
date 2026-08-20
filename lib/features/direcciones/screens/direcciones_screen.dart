import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/branded_app_bar_title.dart';
import '../../pedidos/widgets/pedido_drawer.dart';
import '../controllers/direccion_controller.dart';
import '../widgets/direccion_card.dart';

class DireccionesScreen extends ConsumerStatefulWidget {
  const DireccionesScreen({super.key});
  @override
  ConsumerState<DireccionesScreen> createState() => _DireccionesScreenState();
}

class _DireccionesScreenState extends ConsumerState<DireccionesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(direccionControllerProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(direccionControllerProvider);
    return Scaffold(
      drawer: const PedidoDrawer(),
      appBar: AppBar(
        title: const BrandedAppBarTitle('Mis direcciones'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/direcciones/nueva');
          if (mounted) {
            await ref.read(direccionControllerProvider.notifier).load();
          }
        },
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Agregar'),
      ),
      body: switch (state.status) {
        DireccionStatus.idle || DireccionStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        DireccionStatus.error => _ErrorView(
          message: state.error ?? 'No fue posible consultar las direcciones.',
          onRetry: () => ref.read(direccionControllerProvider.notifier).load(),
        ),
        DireccionStatus.ready when state.direcciones.isEmpty => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No tienes direcciones registradas.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        DireccionStatus.ready => RefreshIndicator(
          onRefresh:
              () => ref.read(direccionControllerProvider.notifier).load(),
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 6, bottom: 96),
            itemCount: state.direcciones.length,
            itemBuilder: (context, index) {
              final item = state.direcciones[index];
              return DireccionCard(
                direccion: item,
                selected: state.selected?.id == item.id,
                onSelect:
                    () => ref
                        .read(direccionControllerProvider.notifier)
                        .select(item),
                onEdit: () async {
                  await context.push('/direcciones/editar/${item.id}');
                  if (mounted) {
                    await ref.read(direccionControllerProvider.notifier).load();
                  }
                },
              );
            },
          ),
        ),
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 56),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
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
