import 'package:flutter/material.dart';

/// Paleta semántica de la app. Todos los colores viven acá (sin `Color(0x...)`
/// inline en widgets — convención `theming` / `_base`).
abstract final class AppColors {
  // Marca / superficie.
  static const Color primary = Color(0xFF2563EB);
  static const Color background = Color(0xFF0F172A);
  static const Color surface = Color(0xFF1E293B);
  static const Color onSurface = Color(0xFFE2E8F0);

  // Texto secundario / bordes (tokens semánticos agregados por la calculadora;
  // siguen el naming de la convención `theming`, no se hardcodean en widgets).
  static const Color onSurfaceVariant = Color(0xFF94A3B8);
  static const Color border = Color(0xFF334155);

  // Estados semánticos.
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  static const Color error = Color(0xFFEF4444);

  /// Superficie tenue para alertas de error (fondo del banner).
  static const Color errorContainer = Color(0xFF3A1620);
}
