import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/branded_app_bar_title.dart';
import '../controllers/direccion_controller.dart';
import '../models/direccion.dart';
import '../models/direccion_request.dart';
import '../widgets/direccion_form.dart';

class DireccionFormScreen extends ConsumerStatefulWidget {
  const DireccionFormScreen({super.key, this.direccionId});
  final int? direccionId;
  @override
  ConsumerState<DireccionFormScreen> createState() =>
      _DireccionFormScreenState();
}

class _DireccionFormScreenState extends ConsumerState<DireccionFormScreen> {
  late Future<Direccion?> _initial;
  @override
  void initState() {
    super.initState();
    _initial =
        widget.direccionId == null
            ? Future.value()
            : ref
                .read(direccionControllerProvider.notifier)
                .getDireccion(widget.direccionId!);
  }

  Future<void> _save(DireccionRequest request) async {
    final result = await ref
        .read(direccionControllerProvider.notifier)
        .save(request, direccionId: widget.direccionId);
    if (!mounted) return;
    if (result.succeeded) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Se guardó correctamente')));
      Navigator.of(context).pop(true);
      return;
    }
    final message =
        result.message == 'EXISTE'
            ? 'Ya tiene registrada esta dirección'
            : (result.message.isEmpty
                ? 'Ocurrió un error al guardar la información, inténtelo nuevamente'
                : result.message);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _deactivate() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Desactivar dirección'),
            content: const Text(
              '¿Seguro que deseas desactivar esta dirección?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sí'),
              ),
            ],
          ),
    );
    if (accepted != true || widget.direccionId == null) return;
    final result = await ref
        .read(direccionControllerProvider.notifier)
        .deactivate(widget.direccionId!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.succeeded
              ? 'Dirección desactivada correctamente'
              : 'Ocurrió un error al desactivar la dirección, inténtelo nuevamente',
        ),
      ),
    );
    if (result.succeeded) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(
      direccionControllerProvider.select((state) => state.saving),
    );
    return Scaffold(
      appBar: AppBar(
        title: BrandedAppBarTitle(
          widget.direccionId == null ? 'Añadir dirección' : 'Editar dirección',
        ),
      ),
      body: FutureBuilder<Direccion?>(
        future: _initial,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No fue posible cargar la dirección.'),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed:
                          () => setState(
                            () =>
                                _initial = ref
                                    .read(direccionControllerProvider.notifier)
                                    .getDireccion(widget.direccionId!),
                          ),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }
          return DireccionForm(
            initial: snapshot.data,
            saving: saving,
            loadColonias:
                ref.read(direccionControllerProvider.notifier).getColonias,
            loadCalles:
                ref.read(direccionControllerProvider.notifier).getCalles,
            loadCerradas:
                ref.read(direccionControllerProvider.notifier).getCerradas,
            onSave: _save,
            onDeactivate: widget.direccionId == null ? null : _deactivate,
          );
        },
      ),
    );
  }
}
