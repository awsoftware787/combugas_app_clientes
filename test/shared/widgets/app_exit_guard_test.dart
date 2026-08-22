import 'package:combugas_clientes/shared/widgets/app_exit_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('primer retroceso en raíz muestra mensaje y arma la salida', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppExitGuard(child: Scaffold(body: Text('Raíz'))),
      ),
    );

    expect(_guardCanPop(tester), isFalse);

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.text('Raíz'), findsOneWidget);
    expect(find.text(AppExitGuard.message), findsOneWidget);
    expect(_guardCanPop(tester), isTrue);

    final handledByFlutter = await tester.binding.handlePopRoute();
    expect(handledByFlutter, isFalse);
  });

  testWidgets('al vencer el intervalo vuelve a requerir dos retrocesos', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppExitGuard(
          interval: Duration(milliseconds: 500),
          child: Scaffold(body: Text('Raíz')),
        ),
      ),
    );

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(_guardCanPop(tester), isTrue);

    await tester.pump(const Duration(milliseconds: 501));

    expect(_guardCanPop(tester), isFalse);
  });

  testWidgets('si existe pantalla anterior retrocede sin mostrar mensaje', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder:
              (context) => Scaffold(
                body: FilledButton(
                  onPressed:
                      () => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder:
                              (_) => const AppExitGuard(
                                child: Scaffold(body: Text('Detalle')),
                              ),
                        ),
                      ),
                  child: const Text('Abrir'),
                ),
              ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(_guardCanPop(tester), isTrue);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Detalle'), findsNothing);
    expect(find.text('Abrir'), findsOneWidget);
    expect(find.text(AppExitGuard.message), findsNothing);
  });
}

bool _guardCanPop(WidgetTester tester) {
  final guard = tester.widget(
    find.byWidgetPredicate((widget) => widget is PopScope),
  );
  return (guard as dynamic).canPop as bool;
}
