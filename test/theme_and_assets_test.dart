import 'package:combugas_clientes/core/constants/app_assets.dart';
import 'package:combugas_clientes/core/theme/app_colors.dart';
import 'package:combugas_clientes/core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'todos los assets centralizados están registrados en el bundle',
    () async {
      for (final asset in AppAssets.values) {
        final data = await rootBundle.load(asset);
        expect(data.lengthInBytes, greaterThan(0), reason: asset);
      }
    },
  );

  test('el tema claro usa la identidad visual de Android', () {
    final theme = AppTheme.lightTheme;

    expect(theme.colorScheme.primary, AppColors.primary);
    expect(theme.colorScheme.secondary, AppColors.accent);
    expect(theme.scaffoldBackgroundColor, AppColors.white);
    expect(theme.appBarTheme.backgroundColor, AppColors.primary);
    expect(theme.appBarTheme.centerTitle, isTrue);
    expect(theme.appBarTheme.titleTextStyle?.color, AppColors.accent);
    expect(theme.floatingActionButtonTheme.backgroundColor, AppColors.accent);

    final decoration = theme.inputDecorationTheme;
    expect(decoration.enabledBorder, isA<OutlineInputBorder>());
    expect(decoration.focusedBorder, isA<OutlineInputBorder>());
    expect(decoration.errorBorder, isA<OutlineInputBorder>());
    expect(decoration.focusedErrorBorder, isA<OutlineInputBorder>());
    expect(decoration.disabledBorder, isA<OutlineInputBorder>());
    expect(
      (decoration.enabledBorder! as OutlineInputBorder).borderSide.style,
      BorderStyle.solid,
    );
  });
}
