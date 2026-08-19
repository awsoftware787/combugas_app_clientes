import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/controllers/auth_controller.dart';
import '../data/evaluacion_pendiente_service.dart';

typedef PendingRatingCallback = void Function(EvaluacionPendiente pendiente);

class CalificacionPendienteGate extends ConsumerStatefulWidget {
  const CalificacionPendienteGate({
    super.key,
    required this.child,
    required this.onPending,
    this.pollInterval = const Duration(seconds: 10),
  });

  final Widget child;
  final PendingRatingCallback onPending;
  final Duration pollInterval;

  @override
  ConsumerState<CalificacionPendienteGate> createState() =>
      _CalificacionPendienteGateState();
}

class _CalificacionPendienteGateState
    extends ConsumerState<CalificacionPendienteGate>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _checking = false;
  int? _observedClientId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(widget.pollInterval, (_) => unawaited(_check()));
  }

  @override
  void didUpdateWidget(CalificacionPendienteGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pollInterval != widget.pollInterval) {
      _timer?.cancel();
      _timer = Timer.periodic(widget.pollInterval, (_) => unawaited(_check()));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_check());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientId = ref.watch(
      authControllerProvider.select((state) => state.session?.claveUsuario),
    );
    if (clientId != _observedClientId) {
      _observedClientId = clientId;
      if (clientId != null) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => unawaited(_check()),
        );
      }
    }
    return widget.child;
  }

  Future<void> _check() async {
    if (_checking || !mounted) return;
    final clientId = ref.read(authControllerProvider).session?.claveUsuario;
    if (clientId == null || clientId <= 0) return;

    _checking = true;
    try {
      final pending = await ref
          .read(evaluacionPendienteServiceProvider)
          .consultar(clientId);
      final activeClientId =
          ref.read(authControllerProvider).session?.claveUsuario;
      if (pending != null && mounted && activeClientId == clientId) {
        widget.onPending(pending);
      }
    } catch (_) {
      // Igual que Android: una falla temporal no bloquea el resto de la app.
    } finally {
      _checking = false;
    }
  }
}
