import 'package:combugas_clientes/core/constants/app_assets.dart';
import 'package:combugas_clientes/core/theme/app_colors.dart';
import 'package:combugas_clientes/features/auth/screens/cuenta_suspendida_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra el motivo dinámico y el contenido solicitado', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CuentaSuspendidaScreen(reason: 'CANCELACIONES REITERADAS'),
      ),
    );

    expect(
      find.text(
        'Estimado usuario, actualmente su cuenta se encuentra suspendida',
      ),
      findsOneWidget,
    );
    expect(find.text('Motivo:'), findsOneWidget);
    expect(find.text('CANCELACIONES REITERADAS'), findsOneWidget);
    expect(
      find.text(
        'Por favor llame al siguiente número para desbloquear su cuenta',
      ),
      findsOneWidget,
    );
    expect(find.text('732-1111'), findsOneWidget);
    expect(find.byIcon(Icons.phone), findsOneWidget);
    final logo = tester.widget<Image>(find.byType(Image));
    expect((logo.image as AssetImage).assetName, AppAssets.logo);
    expect(logo.width, 280);
    expect(logo.height, 110);
    expect(find.byType(AppBar), findsNothing);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      AppColors.primary,
    );
  });

  testWidgets('el botón abre el marcador con el número sin formato', (
    tester,
  ) async {
    Uri? launchedUri;
    await tester.pumpWidget(
      MaterialApp(
        home: CuentaSuspendidaScreen(
          reason: 'MOTIVO DINÁMICO',
          callLauncher: (uri) async {
            launchedUri = uri;
            return true;
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('call-suspended-account')));
    await tester.pump();

    expect(launchedUri, Uri.parse('tel:8717321111'));
  });

  testWidgets('no desborda en un teléfono pequeño con motivo largo', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: CuentaSuspendidaScreen(
          reason: 'CANCELACIONES REITERADAS POR INCUMPLIMIENTO EN EL SERVICIO',
        ),
      ),
    );

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(
      find.byKey(const ValueKey('call-suspended-account')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
