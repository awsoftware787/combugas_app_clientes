import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/controllers/auth_controller.dart';
import 'startup_splash_screen.dart';

/// Conserva el splash mientras dirige al usuario según la sesión restaurada.
class SessionGateScreen extends ConsumerWidget {
  const SessionGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSession = ref.watch(authControllerProvider).session != null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.go(hasSession ? '/pedido' : '/productos');
      }
    });
    return const StartupSplashScreen();
  }
}
