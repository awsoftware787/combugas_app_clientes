import 'dart:async';

import 'package:flutter/material.dart';

/// Evita una salida accidental cuando [child] es la ruta raíz.
///
/// Si existe una ruta anterior, el retroceso conserva el comportamiento normal.
class AppExitGuard extends StatefulWidget {
  const AppExitGuard({
    super.key,
    required this.child,
    this.interval = const Duration(seconds: 2),
  });

  static const message = 'Presiona nuevamente para salir de la aplicación';

  final Widget child;
  final Duration interval;

  @override
  State<AppExitGuard> createState() => _AppExitGuardState();
}

class _AppExitGuardState extends State<AppExitGuard> {
  Timer? _resetTimer;
  bool _exitArmed = false;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  void _requestExit() {
    _resetTimer?.cancel();
    setState(() => _exitArmed = true);
    _resetTimer = Timer(widget.interval, () {
      if (mounted) setState(() => _exitArmed = false);
    });

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(AppExitGuard.message),
          duration: Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final hasPreviousRoute = Navigator.of(context).canPop();
    return PopScope<Object?>(
      canPop: hasPreviousRoute || _exitArmed,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_exitArmed) _requestExit();
      },
      child: widget.child,
    );
  }
}
