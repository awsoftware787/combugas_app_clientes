import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../direcciones/controllers/direccion_controller.dart';
import '../controllers/carrito_controller.dart';
import '../models/item_pedido.dart';

class ConfirmacionPlaceholderScreen extends ConsumerWidget {
  const ConfirmacionPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final direccion = ref.watch(direccionControllerProvider).selected;
    final carrito = ref.watch(carritoControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar pedido')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'ConfirmacionActivity se migrará en un loop posterior.',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text('Dirección: ${direccion?.etiqueta ?? 'Sin dirección'}'),
          if (direccion != null) Text(direccion.calleCompleta),
          const SizedBox(height: 20),
          Text('Productos: ${carrito.lineas}'),
          Text('Total: ${formatoMoneda(carrito.totalCentavos)}'),
          const SizedBox(height: 24),
          const Text(
            'En esta pantalla no se envía ni se guarda ningún pedido real.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
