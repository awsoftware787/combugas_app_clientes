import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/controllers/auth_controller.dart';
import '../startup/startup_splash_screen.dart';

/// Evita mostrar contenido de una ruta mientras se resuelve su redirección.
class SessionRouteGuard extends ConsumerWidget {
  const SessionRouteGuard.private({super.key, required this.child})
    : requiresSession = true;

  const SessionRouteGuard.publicOnly({super.key, required this.child})
    : requiresSession = false;

  final Widget child;
  final bool requiresSession;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSession = ref.watch(authControllerProvider).session != null;
    final allowed = requiresSession ? hasSession : !hasSession;
    if (allowed) return child;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      context.go(requiresSession ? '/productos' : '/pedido');
    });
    return const StartupSplashScreen();
  }
}
