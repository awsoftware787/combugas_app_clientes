import 'package:combugas_clientes/core/constants/app_assets.dart';
import 'package:combugas_clientes/core/theme/app_colors.dart';
import 'package:combugas_clientes/features/auth/data/auth_repository.dart';
import 'package:combugas_clientes/features/pedidos/controllers/mis_pedidos_controller.dart';
import 'package:combugas_clientes/features/pedidos/data/pedido_repository.dart';
import 'package:combugas_clientes/features/pedidos/screens/pedido_detalle_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'historial_test_support.dart';
import 'pedido_historial_fixture.dart';

void main() {
  testWidgets('detalle muestra datos, productos, iconos, total y acciones', (
    tester,
  ) async {
    final repository = FakeHistorialRepository(pedidos: [pedidoFixture()]);
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(misPedidosControllerProvider.notifier).load();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PedidoDetalleScreen(pedidoId: 321)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('HIDALGO'), findsOneWidget);
    expect(find.text('Efectivo'), findsOneWidget);
    expect(find.text('CILINDRO 30 KG'), findsOneWidget);
    expect(find.text('BULTO DE 20KG'), findsOneWidget);
    expect(find.text(r'$890.10'), findsOneWidget);
    expect(find.text('en curso'), findsOneWidget);
    expect(find.text('Cancelar Pedido'), findsOneWidget);
    expect(find.text('Seguimiento'), findsOneWidget);
    final cancel = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Cancelar Pedido'),
    );
    expect(cancel.style?.foregroundColor?.resolve(const {}), AppColors.accent);
    expect(cancel.style?.side?.resolve(const {})?.color, AppColors.accent);
    final tracking = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Seguimiento'),
    );
    expect(
      tracking.style?.backgroundColor?.resolve(const {}),
      AppColors.menuBackground,
    );

    final cylinder = tester.widget<Image>(
      find.byKey(const ValueKey('producto-2-imagen')),
    );
    final croquettes = tester.widget<Image>(
      find.byKey(const ValueKey('producto-20-imagen')),
    );
    expect((cylinder.image as AssetImage).assetName, AppAssets.productCylinder);
    expect(
      (croquettes.image as AssetImage).assetName,
      AppAssets.productDogFoodBulk,
    );
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.foregroundColor, AppColors.white);
    expect(find.text('Detalle del pedido'), findsOneWidget);
  });

  testWidgets('confirma cancelación y actualiza pantalla sin reabrir', (
    tester,
  ) async {
    final repository = FakeHistorialRepository(pedidos: [pedidoFixture()]);
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(misPedidosControllerProvider.notifier).load();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PedidoDetalleScreen(pedidoId: 321)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar Pedido'));
    await tester.pumpAndSettle();
    expect(find.text('¿Está seguro de cancelar su pedido?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Sí'));
    await tester.pumpAndSettle();
    expect(find.text('cancelado'), findsOneWidget);
    expect(find.text('Cancelar Pedido'), findsNothing);
    expect(repository.cancelCalls, 1);
  });

  testWidgets('error de detalle muestra reintento', (tester) async {
    final repository = FakeHistorialRepository(
      getPedidosHandler: (_) async => throw Exception('offline'),
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PedidoDetalleScreen(pedidoId: 321)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Reintentar'), findsOneWidget);
  });
}

ProviderContainer _container(FakeHistorialRepository repository) =>
    ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeHistoryAuthRepository()),
        pedidoRepositoryProvider.overrideWithValue(repository),
      ],
    );
