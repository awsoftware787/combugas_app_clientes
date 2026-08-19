import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../models/pedido_historial.dart';
import '../presentation/pedido_formatters.dart';

class PedidoListItem extends StatelessWidget {
  const PedidoListItem({super.key, required this.pedido, required this.onTap});

  final PedidoHistorial pedido;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = pedidoStatusColor(pedido.status);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FECHA: ${formatoFechaPedido(pedido.fecha)} - '
                      '${pedidoStatusLabel(pedido.status).toUpperCase()}',
                      key: ValueKey('pedido-${pedido.id}-status'),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'DIRECCIÓN: ${pedido.direccion.direccionCompleta}',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Image.asset(
                AppAssets.iconExpand,
                width: 36,
                height: 36,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color pedidoStatusColor(PedidoHistorialStatus status) => switch (status) {
  PedidoHistorialStatus.enCurso => AppColors.link,
  PedidoHistorialStatus.completo => AppColors.success,
  PedidoHistorialStatus.cancelado => AppColors.accent,
};
