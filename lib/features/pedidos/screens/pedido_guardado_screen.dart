import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../models/create_order.dart';

class PedidoGuardadoScreen extends StatelessWidget {
  const PedidoGuardadoScreen({super.key, this.result});
  final CreateOrderResult? result;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.menuBackground,
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(AppAssets.logo, width: 250, fit: BoxFit.contain),
              const SizedBox(height: 28),
              Container(
                width: 150,
                height: 150,
                padding: const EdgeInsets.all(25),
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: Image.asset(AppAssets.iconDone, fit: BoxFit.contain),
              ),
              const SizedBox(height: 20),
              const Text(
                'Tu pedido ha sido guardado correctamente.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.white, fontSize: 20),
              ),
              if (result != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Pedido ${result!.pedidoId}',
                  key: const ValueKey('saved-order-id'),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.menuBackground,
                ),
                onPressed: () => context.go('/mis-pedidos'),
                child: const Text('Mis Pedidos'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
