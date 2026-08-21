import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';

class CuentaSuspendidaScreen extends StatelessWidget {
  const CuentaSuspendidaScreen({
    super.key,
    required this.reason,
    this.callLauncher,
  });

  static const phoneNumber = '732-1111';

  final String reason;
  final Future<bool> Function(Uri uri)? callLauncher;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.primary,
    body: SafeArea(
      child: LayoutBuilder(
        builder:
            (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        AppAssets.logo,
                        width: 400,
                        height: 120,
                        fit: BoxFit.fill,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Estimado usuario, actualmente su cuenta se encuentra suspendida',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Motivo:',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        reason,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 26),
                      const Text(
                        'Por favor llame al siguiente número para desbloquear su cuenta',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 18,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        phoneNumber,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Material(
                        color: AppColors.legacyOrangeStart,
                        elevation: 4,
                        shadowColor: AppColors.shadowOverlay,
                        shape: const CircleBorder(),
                        child: InkWell(
                          key: const ValueKey('call-suspended-account'),
                          customBorder: const CircleBorder(),
                          onTap: () => _call(context),
                          child: const SizedBox.square(
                            dimension: 72,
                            child: Icon(
                              Icons.phone,
                              color: AppColors.white,
                              size: 34,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ),
    ),
  );

  Future<void> _call(BuildContext context) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');

    final fullPhone =
        cleanPhone.startsWith('871') ? cleanPhone : '871$cleanPhone';

    final uri = Uri(scheme: 'tel', path: fullPhone);
    final opened = await (callLauncher?.call(uri) ?? launchUrl(uri));
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No fue posible abrir el teléfono.')),
      );
    }
  }
}
