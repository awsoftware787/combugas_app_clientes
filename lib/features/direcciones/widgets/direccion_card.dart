import 'package:flutter/material.dart';

import '../models/direccion.dart';

class DireccionCard extends StatelessWidget {
  const DireccionCard({
    super.key,
    required this.direccion,
    required this.selected,
    required this.onSelect,
    required this.onEdit,
  });
  final Direccion direccion;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Radio<int>(
              value: direccion.id,
              groupValue: selected ? direccion.id : null,
              onChanged: (_) => onSelect(),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    direccion.etiqueta,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(direccion.calleCompleta),
                  Text('COLONIA ${direccion.colonia}'),
                  Text('${direccion.ciudad}, ${direccion.estado}'),
                ],
              ),
            ),
            IconButton(
              onPressed: onEdit,
              tooltip: 'Editar',
              icon: const Icon(Icons.edit),
            ),
          ],
        ),
      ),
    ),
  );
}
