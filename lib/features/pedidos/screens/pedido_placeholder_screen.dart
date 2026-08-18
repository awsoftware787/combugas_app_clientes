import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../direcciones/controllers/direccion_controller.dart';
import '../../direcciones/models/direccion.dart';

class PedidoPlaceholderScreen extends ConsumerStatefulWidget {
  const PedidoPlaceholderScreen({super.key});
  @override
  ConsumerState<PedidoPlaceholderScreen> createState() =>
      _PedidoPlaceholderScreenState();
}

class _PedidoPlaceholderScreenState
    extends ConsumerState<PedidoPlaceholderScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(direccionControllerProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).session;
    final directions = ref.watch(direccionControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Pedido')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(direccionControllerProvider.notifier).load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Dirección de entrega',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (directions.status == DireccionStatus.loading ||
                directions.status == DireccionStatus.idle)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (directions.status == DireccionStatus.error)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        directions.error ??
                            'No fue posible consultar las direcciones.',
                        textAlign: TextAlign.center,
                      ),
                      TextButton.icon(
                        onPressed:
                            () =>
                                ref
                                    .read(direccionControllerProvider.notifier)
                                    .load(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              )
            else if (directions.direcciones.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.location_off, size: 48),
                      const SizedBox(height: 8),
                      const Text('No tienes una dirección registrada.'),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () async {
                          await context.push('/direcciones/nueva');
                          if (mounted) {
                            await ref
                                .read(direccionControllerProvider.notifier)
                                .load();
                          }
                        },
                        icon: const Icon(Icons.add_location_alt),
                        label: const Text('Agregar dirección'),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              DropdownButtonFormField<Direccion>(
                value: directions.selected,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.home),
                  labelText: 'Dirección seleccionada',
                ),
                items:
                    directions.direcciones
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
                  if (item != null) {
                    ref.read(direccionControllerProvider.notifier).select(item);
                  }
                },
              ),
              if (directions.selected != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${directions.selected!.calleCompleta}\nCOLONIA ${directions.selected!.colonia}\n${directions.selected!.ciudad}, ${directions.selected!.estado}',
                  ),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  await context.push('/direcciones');
                  if (mounted) {
                    await ref.read(direccionControllerProvider.notifier).load();
                  }
                },
                icon: const Icon(Icons.edit_location_alt),
                label: const Text('Gestionar direcciones'),
              ),
            ],
            const SizedBox(height: 40),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(AppAssets.iconCart, width: 72, height: 72),
                  const SizedBox(height: 16),
                  const Text(
                    'PedidoActivity se migrará en un loop posterior.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (session == null) ...[
                    const Text('Actualmente estás navegando como invitado.'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Iniciar sesión'),
                    ),
                  ] else ...[
                    Text('Sesión iniciada: ${session.nombreUsuario}'),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () async {
                        await ref
                            .read(authControllerProvider.notifier)
                            .logout();
                        if (context.mounted) context.go('/login');
                      },
                      child: const Text('Cerrar sesión'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
