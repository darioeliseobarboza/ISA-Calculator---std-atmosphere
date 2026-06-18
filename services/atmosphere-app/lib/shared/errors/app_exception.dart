/// Modelo de errores de dominio (convención `error-handling`).
///
/// Widgets y notifiers manejan `AppException`, nunca excepciones crudas de
/// plataforma/transporte. El mapeo desde transporte ocurre en la capa de datos
/// (networking), no en widgets.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  /// Mapea el resultado de transporte (status + body) a un error de dominio.
  ///
  /// `status == null` representa "sin red / timeout" (no hubo respuesta HTTP).
  /// El shape de error `{ "error": { code, message } }` (ADR-001) se mapea en
  /// [ValidationException] (400) para reutilizar en FG-2 con `/v1/calculate`.
  factory AppException.fromResponse(int? status, dynamic body) {
    return switch (status) {
      401 => const UnauthorizedException(),
      404 => const NotFoundException(),
      400 => ValidationException(_msg(body), _fields(body)),
      null => const NetworkException(),
      _ => const UnexpectedException(),
    };
  }

  static String _msg(dynamic body) {
    if (body is Map && body['error'] is Map) {
      final message = (body['error'] as Map)['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return 'validation error';
  }

  static Map<String, String> _fields(dynamic body) {
    if (body is Map && body['error'] is Map) {
      final code = (body['error'] as Map)['code'];
      if (code is String && code.isNotEmpty) {
        return {'code': code};
      }
    }
    return const {};
  }
}

/// Sin conectividad o timeout (no hubo respuesta HTTP).
class NetworkException extends AppException {
  const NetworkException([super.message = 'network error']);
}

/// Recurso no encontrado (404).
class NotFoundException extends AppException {
  const NotFoundException([super.message = 'not found']);
}

/// No autorizado (401).
class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'unauthorized']);
}

/// Error de validación de la API (400). Reutilizado en FG-2 con `/v1/calculate`.
class ValidationException extends AppException {
  const ValidationException(super.message, this.fields);

  final Map<String, String> fields;
}

/// Cualquier otro error inesperado (status >= 400 no contemplado arriba).
class UnexpectedException extends AppException {
  const UnexpectedException([super.message = 'unexpected error']);
}
