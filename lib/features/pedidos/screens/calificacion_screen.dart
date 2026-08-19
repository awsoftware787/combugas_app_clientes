import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/calificacion_controller.dart';
import '../data/evaluacion_pendiente_service.dart';

class CalificacionScreen extends ConsumerStatefulWidget {
  const CalificacionScreen({super.key, required this.pendiente});

  final EvaluacionPendiente? pendiente;

  @override
  ConsumerState<CalificacionScreen> createState() => _CalificacionScreenState();
}

class _CalificacionScreenState extends ConsumerState<CalificacionScreen> {
  final _commentsController = TextEditingController();
  bool _delivered = true;
  int _rating = 5;

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calificacionControllerProvider);
    final description = widget.pendiente?.descripcionDireccion.trim() ?? '';
    final question =
        description.isEmpty
            ? '¿Su pedido fue entregado?'
            : '¿Su pedido fue entregado en: $description?';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !state.saving) context.go('/pedido');
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                color: AppColors.secondary,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Column(
                  children: [
                    Image.asset(AppAssets.logo, height: 50),
                    const SizedBox(height: 4),
                    const Text(
                      'Confirmación de pedido de entrega',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.accent, fontSize: 18),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        question,
                        key: const ValueKey('delivery-question'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: true, label: Text('Sí')),
                            ButtonSegment(value: false, label: Text('No')),
                          ],
                          selected: {_delivered},
                          onSelectionChanged:
                              state.saving
                                  ? null
                                  : (selection) => setState(
                                    () => _delivered = selection.single,
                                  ),
                        ),
                      ),
                      const Divider(height: 28, color: AppColors.accent),
                      const Text(
                        'Evalúe el servicio recibido',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      CalificacionRating(
                        value: _rating,
                        enabled: !state.saving,
                        onChanged: (value) => setState(() => _rating = value),
                      ),
                      const Divider(height: 28, color: AppColors.accent),
                      const Text(
                        'Comentarios:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        key: const ValueKey('rating-comments'),
                        controller: _commentsController,
                        enabled: !state.saving,
                        minLines: 4,
                        maxLines: 4,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(120),
                        ],
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${120 - _commentsController.text.length} caracteres restantes',
                          key: const ValueKey('remaining-characters'),
                        ),
                      ),
                      if (state.status == CalificacionStatus.error &&
                          state.message != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          state.message!,
                          key: const ValueKey('rating-error'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.accent),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Center(
                        child: SizedBox(
                          width: 180,
                          child: FilledButton(
                            key: const ValueKey('submit-rating'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.white,
                            ),
                            onPressed:
                                state.saving || widget.pendiente == null
                                    ? null
                                    : _submit,
                            child:
                                state.saving
                                    ? const SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.white,
                                      ),
                                    )
                                    : const Text('Enviar'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final pending = widget.pendiente;
    if (pending == null) return;
    final success = await ref
        .read(calificacionControllerProvider.notifier)
        .submit(
          pedidoId: pending.pedidoId,
          entregado: _delivered,
          puntuacion: _rating,
          comentarios: _commentsController.text,
        );
    if (!mounted || !success) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gracias por enviarnos sus comentarios.')),
    );
    context.go('/pedido');
  }
}

class CalificacionRating extends StatelessWidget {
  const CalificacionRating({
    super.key,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(5, (index) {
      final rating = index + 1;
      return IconButton(
        key: ValueKey('rating-star-$rating'),
        tooltip: '$rating estrellas',
        onPressed: enabled ? () => onChanged(rating) : null,
        color: AppColors.primary,
        disabledColor: AppColors.primary,
        icon: Icon(rating <= value ? Icons.star : Icons.star_border),
      );
    }),
  );
}
