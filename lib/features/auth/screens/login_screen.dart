import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/external_urls.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../models/login_result.dart';
import '../widgets/phone_input_formatter.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _telefonoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  bool _mostrarContrasena = false;

  @override
  void dispose() {
    _telefonoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final result = await ref
        .read(authControllerProvider.notifier)
        .login(
          telefono: _telefonoController.text,
          contrasena: _contrasenaController.text,
        );
    if (!mounted) return;

    switch (result) {
      case LoginSuccess(:final hasAddress):
        context.go(hasAddress ? '/pedido' : '/perfil-pendiente');
      case LoginInactiveAccount(:final accountKey):
        context.go('/registro-verificacion', extra: accountKey);
      case LoginBlockedAccount(:final reason):
        context.go('/cuenta-bloqueada', extra: reason);
      case LoginInstitutionalAccount():
        await showDialog<void>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Importante'),
                content: Text(result.message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Aceptar'),
                  ),
                ],
              ),
        );
      case LoginInvalidCredentials() || LoginServiceFailure():
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  Future<void> _abrirAvisoPrivacidad() async {
    final opened = await launchUrl(
      ExternalUrls.privacidad,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No fue posible abrir el aviso.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.primary],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        AppAssets.logo,
                        width: 280,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _telefonoController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          PhoneInputFormatter(),
                        ],
                        decoration: _inputDecoration('Teléfono celular'),
                        validator: (value) {
                          if (value?.length != 14) {
                            return 'Debe especificar un teléfono válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _contrasenaController,
                        obscureText: !_mostrarContrasena,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _iniciarSesion(),
                        decoration: _inputDecoration('Contraseña').copyWith(
                          suffixIcon: IconButton(
                            tooltip: 'Mostrar contraseña',
                            onPressed:
                                () => setState(
                                  () =>
                                      _mostrarContrasena = !_mostrarContrasena,
                                ),
                            icon: Image.asset(
                              AppAssets.iconShowPassword,
                              width: 24,
                              height: 24,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La contraseña no es válida';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed:
                              authState.isLoading ? null : _iniciarSesion,
                          child:
                              authState.isLoading
                                  ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  )
                                  : const Text('Entrar'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            '¿No tienes cuenta?',
                            style: TextStyle(color: AppColors.white),
                          ),
                          TextButton(
                            onPressed: () => context.go('/registro'),
                            child: const Text('Regístrate'),
                          ),
                        ],
                      ),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            '¿Olvidaste tu contraseña?',
                            style: TextStyle(color: AppColors.white),
                          ),
                          TextButton(
                            onPressed: () => context.go('/recuperar'),
                            child: const Text('Recupérala'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Servicio solo disponible para doméstico',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.white),
                      ),
                      TextButton(
                        onPressed: _abrirAvisoPrivacidad,
                        child: const Text('Aviso de privacidad'),
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.white,
    );
  }
}
