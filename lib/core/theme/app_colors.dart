import 'package:flutter/material.dart';

/// Colores obtenidos de los recursos visuales del proyecto Android original.
abstract final class AppColors {
  static const primary = Color(0xFFEFC031);
  static const primaryDark = Color(0xFFEFC031);
  static const primaryLight = Color(0xFFFFECB3);
  static const accent = Color(0xFFCC2229);
  static const blue = Color(0xFF2337FF);
  static const secondary = Color(0xFFE0E0E0);
  static const link = Color(0xFF1976D2);
  static const menuBackground = Color(0xFF5F5F5F);
  static const menuBackgroundDark = Color(0xFF545454);
  static const success = Color(0xFF009540);
  static const addButtonGreen = success;
  static const quantityButtonBlue = link;
  static const white = Color(0xFFFFFFFF);

  // Colores activos definidos fuera de colors.xml en el proyecto Android.
  static const accessKeyBlue = Color(0xFF3399FF);
  static const legacyOrangeStart = Color(0xFFFF683B);
  static const legacyOrangeEnd = Color(0xFFFF8337);
  static const danger = Color(0xFFD32F2F);
  static const shadowOverlay = Color(0x88444444);
}
