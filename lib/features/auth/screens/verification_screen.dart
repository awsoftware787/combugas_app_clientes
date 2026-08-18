import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/register_controller.dart';
import '../models/verification_request.dart';
import '../models/verification_result.dart';
import '../validation/registration_validators.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({required this.accountKey, super.key});

  final int accountKey;

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (widget.accountKey == 0) {
      _showMessage('Ha ocurrido un error crítico, vuelva a intentarlo');
      context.go('/login');
      return;
    }
    final validation = RegistrationValidators.verificationCode(
      _codeController.text,
    );
    if (validation != null) {
      _showMessage(validation);
      return;
    }

    final result = await ref
        .read(registerControllerProvider.notifier)
        .verifyAccount(
          VerificationRequest(
            accountKey: widget.accountKey,
            code: _codeController.text,
          ),
        );
    if (!mounted) return;
    _showMessage(result.message);
    if (result is VerificationSuccess) context.go('/login');
  }

  Future<void> _resend() async {
    if (widget.accountKey == 0) {
      _showMessage('Ha ocurrido un error crítico, vuelva a intentarlo');
      context.go('/login');
      return;
    }
    final result = await ref
        .read(registerControllerProvider.notifier)
        .resendCode(widget.accountKey);
    if (mounted) _showMessage(result.message);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(registerControllerProvider).isLoading;

    return Scaffold(
      body: ColoredBox(
        color: AppColors.primary,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(AppAssets.logo, width: 300),
                    const SizedBox(height: 24),
                    TextField(
                      key: const Key('verification_code'),
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      onSubmitted: (_) => _verify(),
                      decoration: const InputDecoration(
                        hintText: 'Código de verificación',
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: isLoading ? null : _verify,
                        child:
                            isLoading
                                ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                                : const Text('Continuar'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('¿No ha recibido el código?'),
                    TextButton(
                      onPressed: isLoading ? null : _resend,
                      child: const Text('Reenviar código'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
