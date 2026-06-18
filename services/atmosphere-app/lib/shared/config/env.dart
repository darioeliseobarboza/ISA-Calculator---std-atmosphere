import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Configuración de entorno tipada (convención `env-config`).
///
/// Se carga y valida una sola vez al arranque (fail-fast). La app consume el
/// [Env] tipado, nunca `dotenv.env[...]` directo.
class Env {
  const Env._(this.apiBaseUrl);

  /// Base URL de `atmosphere-api` (sin barra final). Viene de `API_BASE_URL`.
  final String apiBaseUrl;

  /// Construye el [Env] desde las variables ya cargadas en `dotenv`.
  /// Lanza [StateError] si falta alguna variable requerida (fail-fast).
  factory Env.fromDotenv() => Env._(_required('API_BASE_URL'));

  static String _required(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw StateError('missing env $key');
    }
    return value;
  }
}

/// Provee el [Env]. Se overridea en `main` con el valor cargado al arranque
/// (patrón de la convención `env-config`).
final envProvider = Provider<Env>(
  (_) => throw UnimplementedError('envProvider debe overridearse en main()'),
);
