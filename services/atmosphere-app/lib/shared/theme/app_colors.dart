import 'package:flutter/material.dart';

/// Paleta semántica de la app. Todos los colores viven acá (sin `Color(0x...)`
/// inline en widgets — convención `theming` / `_base`).
abstract final class AppColors {
  // Marca / superficie.
  static const Color primary = Color(0xFF2563EB);
  static const Color background = Color(0xFF0F172A);
  static const Color surface = Color(0xFF1E293B);
  static const Color onSurface = Color(0xFFE2E8F0);

  // Estados semánticos (los que la pantalla de health distingue).
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
}
