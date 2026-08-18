import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/external_urls.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/register_controller.dart';
import '../models/register_request.dart';
import '../models/register_result.dart';
import '../validation/registration_validators.dart';
import '../widgets/phone_input_formatter.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _acceptedRegistration = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final validationMessage =
        RegistrationValidators.name(_nameController.text) ??
        RegistrationValidators.phone(_phoneController.text) ??
        RegistrationValidators.password(_passwordController.text) ??
        RegistrationValidators.passwordConfirmation(
          _confirmationController.text,
          _passwordController.text,
        );
    if (validationMessage != null) {
      _showMessage(validationMessage);
      return;
    }

    final request = RegisterRequest(
      nombre: _nameController.text,
      telefono: _phoneController.text,
      contrasena: _passwordController.text,
    );
    final result = await ref
        .read(registerControllerProvider.notifier)
        .validateRegistration(request);
    if (!mounted) return;
    await _handleRegistrationResult(result, request);
  }

  Future<void> _handleRegistrationResult(
    RegisterResult result,
    RegisterRequest request,
  ) async {
    switch (result) {
      case RegisterCreated(:final accountKey):
        context.go('/registro-verificacion', extra: accountKey);
      case RegisterIdentityMatch(:final customer):
        await _showIdentityDialog(customer, request, hasAccount: false);
      case RegisterExistingAccount(:final customer):
        await _showIdentityDialog(customer, request, hasAccount: true);
      case RegisterFailure(:final message):
        _showMessage(message);
    }
  }

  Future<void> _showIdentityDialog(
    CustomerMatch customer,
    RegisterRequest request, {
    required bool hasAccount,
  }) async {
    final addresses = switch (customer.addresses) {
      [] => '',
      [final address] => 'Con domicilio en $address',
      final items => 'Con domicilios en\n${items.join('\n')}',
    };

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => Consumer(
            builder: (context, ref, child) {
              final isLoading = ref.watch(registerControllerProvider).isLoading;
              return AlertDialog(
                backgroundColor: AppColors.white,
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(AppAssets.logo, width: 150),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Se ha encontrado la siguiente información:',
                        style: TextStyle(color: AppColors.menuBackground),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      customer.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.menuBackgroundDark,
                        fontSize: 18,
                      ),
                    ),
                    if (addresses.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        addresses,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.menuBackgroundDark,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (isLoading)
                      const CircularProgressIndicator()
                    else ...[
                      SizedBox(
                        width: 150,
                        child: FilledButton(
                          onPressed:
                              hasAccount
                                  ? () {
                                    Navigator.of(dialogContext).pop();
                                    context.go('/login');
                                  }
                                  : () => _registerDirect(
                                    dialogContext,
                                    request,
                                    customerKey: customer.customerKey,
                                    phoneKey: customer.phoneKey,
                                  ),
                          child: Text(hasAccount ? 'Entrar' : 'Soy yo'),
                        ),
                      ),
                      if (!hasAccount) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 150,
                          child: DecoratedBox(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.legacyOrangeStart,
                                  AppColors.legacyOrangeEnd,
                                ],
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(24),
                              ),
                            ),
                            child: TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.white,
                              ),
                              onPressed:
                                  () => _registerDirect(
                                    dialogContext,
                                    request,
                                    customerKey: null,
                                    phoneKey: null,
                                  ),
                              child: const Text('No soy yo'),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              );
            },
          ),
    );
  }

  Future<void> _registerDirect(
    BuildContext dialogContext,
    RegisterRequest request, {
    required int? customerKey,
    required int? phoneKey,
  }) async {
    final result = await ref
        .read(registerControllerProvider.notifier)
        .registerDirect(
          request: request,
          customerKey: customerKey,
          phoneKey: phoneKey,
        );
    if (!mounted || !dialogContext.mounted) return;
    Navigator.of(dialogContext).pop();
    await _handleRegistrationResult(result, request);
  }

  Future<void> _openPrivacyNotice() async {
    final opened = await launchUrl(
      ExternalUrls.privacidad,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      _showMessage('No fue posible abrir el aviso.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(registerControllerProvider).isLoading;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.go('/login');
      },
      child: Scaffold(
        body: ColoredBox(
          color: AppColors.primary,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(AppAssets.logo, width: 300),
                      const SizedBox(height: 24),
                      TextField(
                        key: const Key('register_name'),
                        controller: _nameController,
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [_UpperCaseTextFormatter()],
                        decoration: const InputDecoration(hintText: 'Nombre'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('register_phone'),
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          PhoneInputFormatter(),
                        ],
                        decoration: const InputDecoration(
                          hintText: 'Teléfono celular',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('register_password'),
                        controller: _passwordController,
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: 'Contraseña',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('register_confirmation'),
                        controller: _confirmationController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          hintText: 'Confirmar contraseña',
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
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
                                  : const Text('Registrarse'),
                        ),
                      ),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text('¿Tienes cuenta?'),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: const Text('Entrar'),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: _openPrivacyNotice,
                        child: const Text('Aviso de privacidad'),
                      ),
                      SwitchListTile(
                        value: _acceptedRegistration,
                        onChanged:
                            (value) =>
                                setState(() => _acceptedRegistration = value),
                        title: const Text(
                          'Acepto registrarme para solicitar el servicio',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
