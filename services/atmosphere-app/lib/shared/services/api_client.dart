import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:atmosphere_app/shared/config/env.dart';
import 'package:atmosphere_app/shared/errors/app_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Cliente HTTP fino sobre `http.Client` (convención `networking`).
///
/// `http` no tiene interceptores: el armado de URL, el timeout explícito y el
/// mapeo de errores a [AppException] viven acá, centralizados. Nunca loguea
/// respuestas completas ni headers.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    required http.Client inner,
    required this.timeout,
    // El parámetro es público (`inner`) pero el campo es privado (`_inner`)
    // a propósito: oculta el cliente como detalle de implementación.
    // ignore: prefer_initializing_formals
  }) : _inner = inner;

  final String baseUrl;
  final Duration timeout;
  final http.Client _inner;

  /// `GET {baseUrl}{path}` con timeout explícito. Decodifica el body de forma
  /// segura (body vacío -> mapa vacío). Mapea `status >= 400` y errores de
  /// transporte (sin red / timeout) a [AppException].
  Future<Map<String, dynamic>> getJson(String path) async {
    final http.Response res;
    try {
      res = await _inner.get(Uri.parse('$baseUrl$path')).timeout(timeout);
    } on SocketException {
      throw const NetworkException();
    } on TimeoutException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    }

    final decoded = res.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode >= 400) {
      throw AppException.fromResponse(res.statusCode, decoded);
    }
    return decoded;
  }

  /// `POST {baseUrl}{path}` con `Content-Type: application/json`, body
  /// `jsonEncode(body)` y timeout explícito. Espeja [getJson]: decodifica el
  /// body de forma segura y mapea `status >= 400` y errores de transporte
  /// (sin red / timeout) a [AppException].
  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final http.Response res;
    try {
      res = await _inner
          .post(
            Uri.parse('$baseUrl$path'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(timeout);
    } on SocketException {
      throw const NetworkException();
    } on TimeoutException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    }

    final decoded = res.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode >= 400) {
      throw AppException.fromResponse(res.statusCode, decoded);
    }
    return decoded;
  }
}

/// Provee el [ApiClient] configurado con la base URL del entorno y un timeout
/// explícito (convención `networking` + `env-config`).
final apiClientProvider = Provider<ApiClient>((ref) {
  final env = ref.read(envProvider);
  return ApiClient(
    baseUrl: env.apiBaseUrl,
    inner: http.Client(),
    timeout: const Duration(seconds: 15),
  );
});
