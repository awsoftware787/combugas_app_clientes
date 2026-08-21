import 'dart:math' as math;

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
    final mediaQuery = MediaQuery.of(context);
    final targetHeight = mediaQuery.size.height * 0.52;
    final availableHeight =
        mediaQuery.size.height - mediaQuery.viewInsets.bottom - 48;
    final dialogHeight = math.max(
      220.0,
      math.min(targetHeight, availableHeight),
    );
    final normalizedQuery = _query.trim().toLowerCase();
    final filtered = widget.items
        .where(
          (item) =>
              widget.itemLabel(item).toLowerCase().contains(normalizedQuery),
        )
        .toList(growable: false);

    final borderColor = Theme.of(context).dividerColor;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: BorderSide(color: borderColor, width: 1),
    );

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: mediaQuery.size.width * 0.06,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        key: const ValueKey('searchable-selector-dialog'),
        width: mediaQuery.size.width * 0.88,
        height: dialogHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Seleccionar ${widget.title.toLowerCase()}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints.tightFor(
                      width: 36,
                      height: 36,
                    ),
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 46,
                child: TextField(
                  key: const ValueKey('searchable-selector-search'),
                  autofocus: true,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Buscar ${widget.title.toLowerCase()}...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 42,
                      minHeight: 44,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: inputBorder,
                    enabledBorder: inputBorder,
                    focusedBorder: inputBorder.copyWith(
                      borderSide: BorderSide(color: primaryColor, width: 1),
                    ),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child:
                    filtered.isEmpty
                        ? const Center(
                          child: Text(
                            'No se encontraron resultados',
                            style: TextStyle(fontSize: 14),
                          ),
                        )
                        : ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: filtered.length,
                          separatorBuilder:
                              (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return InkWell(
                              key: ValueKey(
                                'searchable-selector-option-$index',
                              ),
                              onTap: () => Navigator.pop(context, item),
                              child: SizedBox(
                                height: 50,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      widget.itemLabel(item),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
