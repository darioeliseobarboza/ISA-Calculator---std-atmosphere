import 'package:atmosphere_app/shared/calculation/calculation_repository.dart';
import 'package:atmosphere_app/shared/errors/app_exception.dart';
import 'package:atmosphere_app/shared/models/altitude_unit.dart';
import 'package:atmosphere_app/shared/models/calculation_request.dart';
import 'package:atmosphere_app/shared/models/calculation_response.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estados de la calculadora (convención `state-management`).
///
/// - [empty]: estado inicial, sin cálculo previo.
/// - [loading]: solicitud en curso.
/// - [success]: la API devolvió 200 y hay un [CalculatorState.result].
/// - [validationError]: la API devolvió 400 (p. ej. `outOfRange`).
/// - [connectionError]: sin red / timeout (no hubo respuesta HTTP).
enum CalculatorStatus {
  empty,
  loading,
  success,
  validationError,
  connectionError,
}

/// Sentinela para distinguir "no tocar el campo" de "setear null" en [copyWith]
/// de campos nullable ([result], [error], [errorCode]).
const Object _unset = Object();

/// Estado inmutable de la pantalla `calculator` (convención `state-management`).
///
/// Conserva el último input ingresado ([lastAltitude]/[lastUnit]) para permitir
/// reintentar tras un error sin reescribir la entrada.
class CalculatorState {
  const CalculatorState({
    this.status = CalculatorStatus.empty,
    this.result,
    this.error,
    this.errorCode,
    this.lastAltitude,
    this.lastUnit = AltitudeUnit.feet,
  });

  final CalculatorStatus status;

  /// Resultado del último cálculo exitoso (`null` salvo en [CalculatorStatus.success]).
  final CalculationResponse? result;

  /// Mensaje de error de dominio (el del 400 o el de red). `null` si no hay error.
  final String? error;

  /// Código del error de validación de la API (p. ej. `outOfRange`), para que la
  /// UI elija el mensaje localizado. `null` salvo en [CalculatorStatus.validationError].
  final String? errorCode;

  /// Última altitud enviada (se conserva para reintentar).
  final num? lastAltitude;

  /// Última unidad enviada (se conserva para reintentar). Default `ft` (ADR-002).
  final AltitudeUnit lastUnit;

  CalculatorState copyWith({
    CalculatorStatus? status,
    Object? result = _unset,
    Object? error = _unset,
    Object? errorCode = _unset,
    num? lastAltitude,
    AltitudeUnit? lastUnit,
  }) {
    return CalculatorState(
      status: status ?? this.status,
      result: identical(result, _unset)
          ? this.result
          : result as CalculationResponse?,
      error: identical(error, _unset) ? this.error : error as String?,
      errorCode: identical(errorCode, _unset)
          ? this.errorCode
          : errorCode as String?,
      lastAltitude: lastAltitude ?? this.lastAltitude,
      lastUnit: lastUnit ?? this.lastUnit,
    );
  }
}

/// Notifier del dominio `calculator` (convención `state-management`).
///
/// Expone el método de intención [calculate]; captura `AppException` y la
/// traduce al campo de error del estado (nunca relanza). Distingue
/// `ValidationException` (validación de la API) de `NetworkException` (conexión).
class CalculationNotifier extends StateNotifier<CalculatorState> {
  CalculationNotifier(this._repository) : super(const CalculatorState());

  final CalculationRepository _repository;

  /// Dispara `POST /v1/calculate`. Transiciona `→ loading → (success |
  /// validationError | connectionError)`. Conserva el input para reintentos.
  Future<void> calculate({
    required num geopotentialAltitude,
    AltitudeUnit altitudeUnit = AltitudeUnit.feet,
  }) async {
    state = state.copyWith(
      status: CalculatorStatus.loading,
      error: null,
      errorCode: null,
      lastAltitude: geopotentialAltitude,
      lastUnit: altitudeUnit,
    );

    try {
      final response = await _repository.calculate(
        CalculationRequest(
          geopotentialAltitude: geopotentialAltitude,
          altitudeUnit: altitudeUnit,
        ),
      );
      state = state.copyWith(
        status: CalculatorStatus.success,
        result: response,
        error: null,
        errorCode: null,
      );
    } on ValidationException catch (e) {
      state = state.copyWith(
        status: CalculatorStatus.validationError,
        result: null,
        error: e.message,
        errorCode: e.fields['code'],
      );
    } on NetworkException catch (e) {
      state = state.copyWith(
        status: CalculatorStatus.connectionError,
        result: null,
        error: e.message,
        errorCode: null,
      );
    } on AppException catch (e) {
      // Cualquier otro error de dominio (status >= 400 inesperado) se trata como
      // error de conexión/sistema a efectos de presentación.
      state = state.copyWith(
        status: CalculatorStatus.connectionError,
        result: null,
        error: e.message,
        errorCode: null,
      );
    }
  }
}
