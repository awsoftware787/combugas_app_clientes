import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/branded_app_bar_title.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../pedidos/widgets/pedido_drawer.dart';
import '../controllers/perfil_controller.dart';
import '../models/perfil_cliente.dart';

class PerfilScreen extends ConsumerStatefulWidget {
  const PerfilScreen({super.key});

  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(perfilControllerProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(perfilControllerProvider);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _regresar();
      },
      child: Scaffold(
        drawer: const PedidoDrawer(),
        appBar: AppBar(title: const BrandedAppBarTitle('Perfil')),
        body: switch (state.status) {
          PerfilStatus.idle || PerfilStatus.loading when state.perfil == null =>
            const Center(child: CircularProgressIndicator()),
          PerfilStatus.error when state.perfil == null => _PerfilError(
            message: state.error ?? 'No fue posible consultar el perfil.',
            onRetry: () => ref.read(perfilControllerProvider.notifier).load(),
          ),
          _ => _PerfilContent(
            perfil: state.perfil!,
            updatingEmail: state.updatingEmail,
            deletingAccount: state.deletingAccount,
            onUpdateEmail: _actualizarCorreo,
            onAddAddress: () => _openAddress('/direcciones/nueva'),
            onViewAddresses: () => _openAddress('/direcciones'),
            onLogout: _cerrarSesion,
            onDelete: _confirmarEliminarCuenta,
            onRefresh: () => ref.read(perfilControllerProvider.notifier).load(),
          ),
        },
      ),
    );
  }

  Future<void> _openAddress(String route) async {
    await context.push(route);
    if (mounted) await ref.read(perfilControllerProvider.notifier).load();
  }

  void _regresar() {
    final perfil = ref.read(perfilControllerProvider).perfil;
    if (perfil == null || !perfil.tieneDireccion) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agregue una dirección para continuar')),
      );
      return;
    }
    context.go('/pedido');
  }

  Future<void> _actualizarCorreo() async {
    final current = ref.read(perfilControllerProvider).perfil?.correo ?? '';
    var correoDraft = current;
    String? error;
    var saving = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('Actualizar correo electrónico'),
                  content: TextFormField(
                    key: const ValueKey('profile-email-field'),
                    initialValue: current,
                    onChanged: (value) => correoDraft = value,
                    enabled: !saving,
                    autofocus: true,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'ejemplo@correo.com',
                      labelText: 'Correo electrónico',
                      errorText: error,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed:
                          saving ? null : () => Navigator.pop(dialogContext),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      key: const ValueKey('save-profile-email'),
                      onPressed:
                          saving
                              ? null
                              : () async {
                                final correo = correoDraft.trim();
                                if (!_isValidEmail(correo)) {
                                  setDialogState(
                                    () => error = 'El email no es válido',
                                  );
                                  return;
                                }
                                setDialogState(() {
                                  saving = true;
                                  error = null;
                                });
                                final result = await ref
                                    .read(perfilControllerProvider.notifier)
                                    .actualizarCorreo(correo);
                                if (!dialogContext.mounted) return;
                                if (result.succeeded) {
                                  Navigator.pop(dialogContext);
                                  return;
                                }
                                setDialogState(() {
                                  saving = false;
                                  error =
                                      result.message.isEmpty
                                          ? 'No fue posible actualizar el correo.'
                                          : result.message;
                                });
                              },
                      child:
                          saving
                              ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Guardar'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _cerrarSesion() async {
    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) context.go('/productos');
  }

  Future<void> _confirmarEliminarCuenta() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            icon: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.danger,
            ),
            title: const Text('Eliminar cuenta'),
            content: const Text(
              '¿Estás seguro de que deseas eliminar tu cuenta?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sí'),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;
    final result =
        await ref.read(perfilControllerProvider.notifier).eliminarCuenta();
    if (!mounted) return;
    if (!result.succeeded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message.isEmpty
                ? 'Error al eliminar tus datos'
                : result.message,
          ),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Su cuenta ha sido eliminada. Para volver a utilizar la aplicación tendrá que registrarse nuevamente.',
        ),
      ),
    );
    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) context.go('/productos');
  }
}

class _PerfilContent extends StatelessWidget {
  const _PerfilContent({
    required this.perfil,
    required this.updatingEmail,
    required this.deletingAccount,
    required this.onUpdateEmail,
    required this.onAddAddress,
    required this.onViewAddresses,
    required this.onLogout,
    required this.onDelete,
    required this.onRefresh,
  });

  final PerfilCliente perfil;
  final bool updatingEmail;
  final bool deletingAccount;
  final VoidCallback onUpdateEmail;
  final VoidCallback onAddAddress;
  final VoidCallback onViewAddresses;
  final VoidCallback onLogout;
  final VoidCallback onDelete;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onRefresh,
    child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Image.asset(AppAssets.profileImage, height: 80)),
              const SizedBox(height: 20),
              const _ProfileLabel('Nombre:'),
              Text(
                perfil.nombre,
                key: const ValueKey('profile-name'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              const _ProfileLabel('Teléfono:'),
              Text(_formatPhone(perfil.telefono), textAlign: TextAlign.center),
              const SizedBox(height: 14),
              const _ProfileLabel('Correo electrónico:'),
              Text(
                perfil.correo ?? 'No hay correo registrado',
                textAlign: TextAlign.center,
              ),
              Center(
                child: TextButton(
                  key: const ValueKey('update-profile-email'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.link),
                  onPressed: updatingEmail ? null : onUpdateEmail,
                  child: const Text('Actualizar correo electrónico'),
                ),
              ),
              const SizedBox(height: 10),
              const _ProfileLabel('Direcciones:'),
              const SizedBox(height: 6),
              LayoutBuilder(
                builder: (context, constraints) {
                  final buttons = <Widget>[
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.quantityButtonBlue,
                      ),
                      onPressed: onAddAddress,
                      icon: const Icon(Icons.add_location_alt),
                      label: const Text('Añadir dirección'),
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.quantityButtonBlue,
                      ),
                      onPressed: onViewAddresses,
                      icon: const Icon(Icons.location_on),
                      label: const Text('Ver direcciones'),
                    ),
                  ];
                  if (constraints.maxWidth < 390) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        buttons.first,
                        const SizedBox(height: 10),
                        buttons.last,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: buttons.first),
                      const SizedBox(width: 10),
                      Expanded(child: buttons.last),
                    ],
                  );
                },
              ),
              const SizedBox(height: 26),
              Center(
                child: SizedBox(
                  width: 220,
                  child: FilledButton(
                    key: const ValueKey('profile-logout'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.quantityButtonBlue,
                    ),
                    onPressed: deletingAccount ? null : onLogout,
                    child: const Text('Cerrar sesión'),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: SizedBox(
                  width: 220,
                  child: FilledButton(
                    key: const ValueKey('delete-account'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: AppColors.white,
                    ),
                    onPressed: deletingAccount ? null : onDelete,
                    child:
                        deletingAccount
                            ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                            : const Text('Eliminar cuenta'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ProfileLabel extends StatelessWidget {
  const _ProfileLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    style: const TextStyle(
      color: AppColors.accent,
      fontWeight: FontWeight.bold,
    ),
  );
}

class _PerfilError extends StatelessWidget {
  const _PerfilError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 56),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}

bool _isValidEmail(String value) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);

String _formatPhone(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 10) return value;
  return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-'
      '${digits.substring(6)}';
}
