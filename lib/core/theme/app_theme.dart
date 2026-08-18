import 'package:flutter/material.dart';

final class AppTheme {
  const AppTheme._();

  static ThemeData get light => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
    useMaterial3: true,
  );
}
