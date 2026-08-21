import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/branded_app_bar_title.dart';
import '../../direcciones/controllers/direccion_controller.dart';
import '../controllers/carrito_controller.dart';
import '../controllers/confirmacion_controller.dart';
import '../models/item_pedido.dart';
import '../models/metodo_pago.dart';
import '../widgets/cart_item_tile.dart';

class ConfirmacionScreen extends ConsumerStatefulWidget {
  const ConfirmacionScreen({super.key});

  @override
  ConsumerState<ConfirmacionScreen> createState() => _ConfirmacionScreenState();
}

class _ConfirmacionScreenState extends ConsumerState<ConfirmacionScreen> {
  String? _accessKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(confirmacionControllerProvider.notifier)
          .prepare(ref.read(carritoControllerProvider).items);
    });
  }

  @override
  Widget build(BuildContext context) {
    final confirmation = ref.watch(confirmacionControllerProvider);
    final cart = ref.watch(carritoControllerProvider);
    final address = ref.watch(direccionControllerProvider).selected;
    return PopScope(
      canPop: !confirmation.saving,
      child: Scaffold(
        appBar: AppBar(title: const BrandedAppBarTitle('Confirmar pedido')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Dirección de entrega',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: Image.asset(
                  AppAssets.iconAddress,
                  width: 42,
                  height: 42,
                  fit: BoxFit.contain,
                ),
                title: Text(address?.etiqueta ?? 'Sin dirección seleccionada'),
                subtitle:
                    address == null
                        ? null
                        : Text('${address.calleCompleta}, ${address.colonia}'),
              ),
            ),
            const SizedBox(height: 16),
            Text('Productos', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (cart.items.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Tu carrito está vacío.'),
                ),
              )
            else
              ...cart.items.map(
                (item) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: CartItemTile(item: item),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            _Total(total: cart.totalCentavos),
            const SizedBox(height: 20),
            Text(
              'Forma de pago',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...MetodoPago.values.map(
              (payment) => Card(
                child: RadioListTile<MetodoPago>(
                  value: payment,
                  groupValue: confirmation.metodoPago,
                  onChanged:
                      confirmation.saving
                          ? null
                          : (value) {
                            if (value != null) {
                              ref
                                  .read(confirmacionControllerProvider.notifier)
                                  .selectPayment(value);
                            }
                          },
                  secondary: Image.asset(
                    payment.asset,
                    width: 46,
                    height: 46,
                    fit: BoxFit.contain,
                  ),
                  title: Text(payment.descripcion),
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: const ValueKey('access-key-button'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accessKeyBlue,
                side: const BorderSide(color: AppColors.accessKeyBlue),
              ),
              onPressed: confirmation.saving ? null : _editAccessKey,
              child: Text(
                _accessKey == null
                    ? 'Clave de acceso'
                    : 'Clave de acceso: $_accessKey',
              ),
            ),
            if (confirmation.status == ConfirmacionStatus.loadingTime)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (confirmation.tiempoEntrega != null)
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Tiempo estimado'),
                subtitle: Text(confirmation.tiempoEntrega!),
              ),
            if (confirmation.message != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  confirmation.message!,
                  key: const ValueKey('confirmation-message'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
        bottomNavigationBar: _ConfirmationActions(
          saving: confirmation.saving,
          enabled: cart.items.isNotEmpty,
          onClear: _clearCart,
          onConfirm: _confirm,
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Confirmar pedido'),
            content: Text(
              'Está a punto de generar un pedido, ¿desea continuar?'
              '${_accessKey == null ? '' : '\nClave de acceso: $_accessKey'}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.addButtonGreen,
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Confirmar'),
              ),
            ],
          ),
    );
    if (accepted != true || !mounted) return;
    final result = await ref
        .read(confirmacionControllerProvider.notifier)
        .submit(accessKey: _accessKey);
    if (!mounted || result == null) return;
    context.go('/pedido-guardado', extra: result);
  }

  Future<void> _clearCart() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Limpiar'),
            content: const Text('¿Está seguro de limpiar su pedido?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('No'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Sí'),
              ),
            ],
          ),
    );
    if (accepted != true) return;
    await ref.read(carritoControllerProvider.notifier).clear();
    if (mounted) context.pop();
  }

  Future<void> _editAccessKey() async {
    final value = await showDialog<String>(
      context: context,
      builder: (_) => _AccessKeyDialog(initialValue: _accessKey),
    );
    if (value == null || !mounted) return;
    setState(() => _accessKey = value.trim().isEmpty ? null : value.trim());
  }
}

class _ConfirmationActions extends StatelessWidget {
  const _ConfirmationActions({
    required this.saving,
    required this.enabled,
    required this.onClear,
    required this.onConfirm,
  });

  final bool saving;
  final bool enabled;
  final VoidCallback onClear;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).scaffoldBackgroundColor,
    elevation: 8,
    child: SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                key: const ValueKey('clear-confirmation'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent),
                ),
                onPressed: saving || !enabled ? null : onClear,
                child: const Text('Limpiar'),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 52,
              child: FilledButton(
                key: const ValueKey('confirm-order'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.addButtonGreen,
                  foregroundColor: AppColors.white,
                ),
                onPressed: saving || !enabled ? null : onConfirm,
                child:
                    saving
                        ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                        : const Text('Confirmar'),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _AccessKeyDialog extends StatefulWidget {
  const _AccessKeyDialog({this.initialValue});
  final String? initialValue;

  @override
  State<_AccessKeyDialog> createState() => _AccessKeyDialogState();
}

class _AccessKeyDialogState extends State<_AccessKeyDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Clave de acceso'),
    content: TextField(
      key: const ValueKey('access-key-field'),
      controller: _controller,
      autofocus: true,
      decoration: const InputDecoration(labelText: 'Clave'),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _controller.text),
        child: const Text('Guardar'),
      ),
    ],
  );
}

class _Total extends StatelessWidget {
  const _Total({required this.total});
  final int total;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text('Total', style: Theme.of(context).textTheme.titleMedium),
      Text(
        formatoMoneda(total),
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    ],
  );
}
