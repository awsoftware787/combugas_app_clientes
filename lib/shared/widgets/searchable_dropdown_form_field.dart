import 'package:flutter/material.dart';

class SearchableDropdownFormField<T> extends StatelessWidget {
  const SearchableDropdownFormField({
    super.key,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.labelText,
    required this.onChanged,
    this.validator,
    this.enabled = true,
  });

  final T? value;
  final List<T> items;
  final String Function(T item) itemLabel;
  final String labelText;
  final ValueChanged<T> onChanged;
  final FormFieldValidator<T>? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) => FormField<T>(
    key: ValueKey(value),
    initialValue: value,
    validator: validator,
    builder:
        (field) => InkWell(
          onTap:
              enabled
                  ? () async {
                    final selected = await showDialog<T>(
                      context: context,
                      builder:
                          (context) => _SearchableSelectionDialog<T>(
                            title: labelText,
                            items: items,
                            itemLabel: itemLabel,
                          ),
                    );
                    if (selected == null) return;
                    field.didChange(selected);
                    onChanged(selected);
                  }
                  : null,
          borderRadius: BorderRadius.circular(4),
          child: InputDecorator(
            isEmpty: field.value == null,
            decoration: InputDecoration(
              labelText: labelText,
              errorText: field.errorText,
              enabled: enabled,
              suffixIcon: const Icon(Icons.arrow_drop_down),
            ),
            child: Text(
              field.value == null ? '' : itemLabel(field.value as T),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
  );
}

class _SearchableSelectionDialog<T> extends StatefulWidget {
  const _SearchableSelectionDialog({
    required this.title,
    required this.items,
    required this.itemLabel,
  });

  final String title;
  final List<T> items;
  final String Function(T item) itemLabel;

  @override
  State<_SearchableSelectionDialog<T>> createState() =>
      _SearchableSelectionDialogState<T>();
}

class _SearchableSelectionDialogState<T>
    extends State<_SearchableSelectionDialog<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _query.trim().toLowerCase();
    final filtered = widget.items
        .where(
          (item) =>
              widget.itemLabel(item).toLowerCase().contains(normalizedQuery),
        )
        .toList(growable: false);

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        height: 360,
        child: Column(
          children: [
            TextField(
              key: const ValueKey('searchable-selector-search'),
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Buscar ${widget.title.toLowerCase()}',
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 8),
            Expanded(
              child:
                  filtered.isEmpty
                      ? const Center(child: Text('No hay resultados.'))
                      : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return ListTile(
                            title: Text(widget.itemLabel(item)),
                            onTap: () => Navigator.pop(context, item),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
