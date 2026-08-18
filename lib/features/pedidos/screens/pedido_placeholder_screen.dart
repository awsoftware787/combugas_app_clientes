import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../auth/controllers/auth_controller.dart';

class PedidoPlaceholderScreen extends ConsumerWidget {
  const PedidoPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final session = authState.session;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Pedido')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                    await ref.read(authControllerProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                  child: const Text('Cerrar sesión'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
