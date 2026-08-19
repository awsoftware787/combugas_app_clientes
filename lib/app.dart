import 'package:flutter/material.dart';

import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/pedidos/widgets/calificacion_pendiente_gate.dart';

class CombugasApp extends StatelessWidget {
  const CombugasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'COMBUGAS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      builder:
          (context, child) => CalificacionPendienteGate(
            onPending: (pending) {
              final path =
                  appRouter.routerDelegate.currentConfiguration.uri.path;
              if (path != '/calificacion') {
                appRouter.go('/calificacion', extra: pending);
              }
            },
            child: child ?? const SizedBox.shrink(),
          ),
    );
  }
}
