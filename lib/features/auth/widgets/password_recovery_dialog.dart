import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../controllers/password_recovery_controller.dart';
import '../models/password_recovery_result.dart';
import 'phone_input_formatter.dart';

class PasswordRecoveryDialog extends ConsumerStatefulWidget {
  const PasswordRecoveryDialog({super.key});

  @override
  ConsumerState<PasswordRecoveryDialog> createState() =>
      _PasswordRecoveryDialogState();
}

class _PasswordRecoveryDialogState
    extends ConsumerState<PasswordRecoveryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _submissionInProgress = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submissionInProgress) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    _submissionInProgress = true;
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      final result = await ref
          .read(passwordRecoveryControllerProvider.notifier)
          .recoverPassword(_phoneController.text);
      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      if (result is PasswordRecoverySuccess) {
        Navigator.of(context).pop();
        messenger.showSnackBar(SnackBar(content: Text(result.message)));
      } else {
        messenger.showSnackBar(SnackBar(content: Text(result.message)));
      }
    } finally {
      _submissionInProgress = false;
    }
  }

  void _close() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(passwordRecoveryControllerProvider).isLoading;

    return PopScope(
      canPop: !isLoading,
      child: Dialog(
        backgroundColor: AppColors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Recuperar contraseña',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    key: const ValueKey('password-recovery-phone'),
                    controller: _phoneController,
                    enabled: !isLoading,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      PhoneInputFormatter(),
                    ],
                    decoration: const InputDecoration(
                      hintText: 'Teléfono celular',
                    ),
                    validator:
                        (value) =>
                            value?.length == 14
                                ? null
                                : 'Debe especificar un número de teléfono válido',
                    onFieldSubmitted: isLoading ? null : (_) => _submit(),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 140,
                        maxWidth: 200,
                      ),
                      child: FilledButton(
                        key: const ValueKey('password-recovery-submit'),
                        onPressed: isLoading ? null : _submit,
                        child:
                            isLoading
                                ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                                : const Text('ENVIAR'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: TextButton(
                      key: const ValueKey('password-recovery-back'),
                      onPressed: isLoading ? null : _close,
                      child: const Text('REGRESAR'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
