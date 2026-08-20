import 'dart:async';

import 'package:combugas_clientes/core/network/network_exception.dart';
import 'package:combugas_clientes/core/theme/app_colors.dart';
import 'package:combugas_clientes/features/auth/data/auth_repository.dart';
import 'package:combugas_clientes/features/pedidos/controllers/calificacion_controller.dart';
import 'package:combugas_clientes/features/pedidos/data/evaluacion_pendiente_service.dart';
import 'package:combugas_clientes/features/pedidos/data/pedido_repository.dart';
import 'package:combugas_clientes/features/pedidos/models/calificacion.dart';
import 'package:combugas_clientes/features/pedidos/screens/calificacion_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'historial_test_support.dart';

void main() {
  testWidgets(
    'primer toque envía tras una calificación previa sin reiniciar provider',
    (tester) async {
      final repository = FakeHistorialRepository();
      final container = _container(repository);
      addTearDown(container.dispose);
      final controller = container.read(
        calificacionControllerProvider.notifier,
      );
      expect(
        await controller.submit(
          pedidoId: 100,
          entregado: true,
          puntuacion: 5,
          comentarios: '',
        ),
        isTrue,
      );
      expect(repository.calificarCalls, 1);

      final router = _router();
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('submit-rating')));
      await tester.pumpAndSettle();

      expect(repository.calificarCalls, 2);
      expect(repository.calificacionRecibida?.pedidoId, 321);
    },
  );

  testWidgets('reproduce formulario Android y conserva datos ante error', (
    tester,
  ) async {
    final repository = FakeHistorialRepository(
      calificarHandler:
          (_) async => throw const WebServiceException('SERVICIO OCUPADO'),
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    await tester.pumpWidget(_home(container));
    await tester.pumpAndSettle();

    expect(find.text('Confirmación de pedido de entrega'), findsOneWidget);
    final header = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('Confirmación de pedido de entrega'),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(header.color, AppColors.primary);
    expect(find.textContaining('CASA'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNWidgets(5));
    expect(find.text('120 caracteres restantes'), findsOneWidget);
    expect(find.text('Sí'), findsOneWidget);
    expect(find.text('No'), findsOneWidget);
    final comments = tester.widget<TextField>(
      find.byKey(const ValueKey('rating-comments')),
    );
    expect(comments.decoration?.border, isA<OutlineInputBorder>());
    expect(comments.decoration?.enabledBorder, isA<OutlineInputBorder>());
    expect(comments.decoration?.focusedBorder, isA<OutlineInputBorder>());
    expect(
      (comments.decoration?.border! as OutlineInputBorder).borderRadius,
      BorderRadius.circular(8),
    );

    await tester.tap(find.byKey(const ValueKey('rating-star-2')));
    await tester.enterText(
      find.byKey(const ValueKey('rating-comments')),
      'No llegó completo',
    );
    await tester.tap(find.text('No'));
    await tester.tap(find.byKey(const ValueKey('submit-rating')));
    await tester.pumpAndSettle();

    expect(
      find.text('No fue posible enviar la evaluación. Inténtalo nuevamente.'),
      findsOneWidget,
    );
    expect(find.text('No llegó completo'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNWidgets(2));
    expect(repository.calificacionRecibida?.entregado, isFalse);
    expect(repository.calificacionRecibida?.puntuacion, 2);
    expect(repository.calificacionRecibida?.comentarios, 'No llegó completo');
  });

  testWidgets('loading deshabilita envío y éxito vuelve a Pedido', (
    tester,
  ) async {
    final completer = Completer<CalificacionResult>();
    final repository = FakeHistorialRepository(
      calificarHandler: (_) => completer.future,
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    final router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    final submitFinder = find.byKey(const ValueKey('submit-rating'));
    final submit = tester.widget<FilledButton>(submitFinder);
    expect(submit.style?.backgroundColor?.resolve(const {}), AppColors.accent);

    await tester.tap(submitFinder);
    await tester.pump();
    expect(tester.widget<FilledButton>(submitFinder).onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(const CalificacionResult(mensaje: 'OK'));
    await tester.pumpAndSettle();
    expect(find.text('PEDIDO PRINCIPAL'), findsOneWidget);
    expect(find.text('Gracias por enviarnos sus comentarios.'), findsOneWidget);
  });
}

ProviderContainer _container(FakeHistorialRepository repository) =>
    ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeHistoryAuthRepository()),
        pedidoRepositoryProvider.overrideWithValue(repository),
      ],
    );

Widget _home(ProviderContainer container) => UncontrolledProviderScope(
  container: container,
  child: const MaterialApp(home: CalificacionScreen(pendiente: _pending)),
);

GoRouter _router() => GoRouter(
  initialLocation: '/calificacion',
  routes: [
    GoRoute(
      path: '/calificacion',
      builder: (_, _) => const CalificacionScreen(pendiente: _pending),
    ),
    GoRoute(
      path: '/pedido',
      builder: (_, _) => const Scaffold(body: Text('PEDIDO PRINCIPAL')),
    ),
  ],
);

const _pending = EvaluacionPendiente(
  pedidoId: 321,
  descripcionDireccion: 'CASA',
);
