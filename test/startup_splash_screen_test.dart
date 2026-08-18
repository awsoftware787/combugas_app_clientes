import 'package:combugas_clientes/core/constants/app_assets.dart';
import 'package:combugas_clientes/core/startup/startup_splash_screen.dart';
import 'package:combugas_clientes/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('centra el logo y adapta su ancho a la pantalla', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: StartupSplashScreen()));

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final image = tester.widget<Image>(find.byType(Image));
    final imageRect = tester.getRect(find.byType(Image));

    expect(scaffold.backgroundColor, AppColors.primary);
    expect(image.image, const AssetImage(AppAssets.logo));
    expect(image.fit, BoxFit.contain);
    expect(imageRect.width, 312);
    expect(imageRect.center.dx, 180);
    expect(imageRect.center.dy, 400);
  });
}
