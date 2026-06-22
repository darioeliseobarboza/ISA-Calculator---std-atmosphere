import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('es')];

  /// Título / header de la pantalla de cálculo
  ///
  /// In es, this message translates to:
  /// **'Calculadora ISA · Atmósfera Estándar'**
  String get calcTitle;

  /// Label del campo de altitud
  ///
  /// In es, this message translates to:
  /// **'Altitud geopotencial'**
  String get calcAltitudeLabel;

  /// Helper text del campo de altitud
  ///
  /// In es, this message translates to:
  /// **'numérico; se normaliza a ft y se valida 0–36.089 ft'**
  String get calcAltitudeHelper;

  /// Label del selector de unidad
  ///
  /// In es, this message translates to:
  /// **'Unidad'**
  String get calcUnitLabel;

  /// Helper del selector de unidad
  ///
  /// In es, this message translates to:
  /// **'opciones m / ft · default ft'**
  String get calcUnitHelper;

  /// Opción metros del selector de unidad
  ///
  /// In es, this message translates to:
  /// **'m'**
  String get calcUnitMeters;

  /// Opción pies del selector de unidad
  ///
  /// In es, this message translates to:
  /// **'ft'**
  String get calcUnitFeet;

  /// Label del control de paso de tabla (deshabilitado en FG-2)
  ///
  /// In es, this message translates to:
  /// **'Paso de tabla — disponible en FG-3'**
  String get calcTableStepDisabled;

  /// aria-label del icono del control de paso de tabla
  ///
  /// In es, this message translates to:
  /// **'Ajustar paso de tabla'**
  String get calcTableStepA11y;

  /// Label del botón calcular
  ///
  /// In es, this message translates to:
  /// **'Calcular'**
  String get calcCalculate;

  /// Label del botón calcular mientras carga
  ///
  /// In es, this message translates to:
  /// **'Calculando…'**
  String get calcCalculating;

  /// Label del botón de fórmulas (drawer de S-006)
  ///
  /// In es, this message translates to:
  /// **'Fórmulas de conversión'**
  String get calcFormulas;

  /// aria-label del icono del botón de fórmulas
  ///
  /// In es, this message translates to:
  /// **'Abrir fórmulas de conversión'**
  String get calcFormulasA11y;

  /// Header del drawer de fórmulas de conversión (O-01)
  ///
  /// In es, this message translates to:
  /// **'Fórmulas de conversión'**
  String get formulasTitle;

  /// Intro (caption) del drawer: aclara que es referencia estática
  ///
  /// In es, this message translates to:
  /// **'Referencia estática · SI ↔ imperial y m ↔ ft. No calcula.'**
  String get formulasIntro;

  /// Label de la lista de fórmulas por magnitud
  ///
  /// In es, this message translates to:
  /// **'Por magnitud'**
  String get formulasListLabel;

  /// Factor de conversión de altitud (m ↔ ft)
  ///
  /// In es, this message translates to:
  /// **'Altitud — 1 ft = 0,3048 m'**
  String get formulasItemAltitude;

  /// Factor de conversión de temperatura (SI ↔ imperial)
  ///
  /// In es, this message translates to:
  /// **'Temperatura — °R = K × 1,8'**
  String get formulasItemTemperature;

  /// Factor de conversión de presión (SI ↔ imperial)
  ///
  /// In es, this message translates to:
  /// **'Presión — 1 lbf/ft² (psf) = 47,8803 Pa'**
  String get formulasItemPressure;

  /// Factor de conversión de densidad (SI ↔ imperial)
  ///
  /// In es, this message translates to:
  /// **'Densidad — 1 slug/ft³ = 515,379 kg/m³'**
  String get formulasItemDensity;

  /// Factor de conversión de viscosidad dinámica (SI ↔ imperial)
  ///
  /// In es, this message translates to:
  /// **'Viscosidad dinámica — 1 slug/(ft·s) = 47,8803 Pa·s'**
  String get formulasItemDynamicViscosity;

  /// Factor de conversión de viscosidad cinemática (SI ↔ imperial)
  ///
  /// In es, this message translates to:
  /// **'Viscosidad cinemática — 1 ft²/s = 0,092903 m²/s'**
  String get formulasItemKinematicViscosity;

  /// Factor de conversión de velocidad del sonido (SI ↔ imperial)
  ///
  /// In es, this message translates to:
  /// **'Velocidad del sonido — 1 ft/s = 0,3048 m/s'**
  String get formulasItemSpeedOfSound;

  /// Nota (caption): los relativos son adimensionales, sin conversión
  ///
  /// In es, this message translates to:
  /// **'Relativos (θ, δ, σ, a/a₀, μ/μ₀): adimensionales, sin conversión.'**
  String get formulasRelativesNote;

  /// Label del botón que cierra el drawer de fórmulas
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get formulasClose;

  /// aria-label / tooltip del icono del botón Cerrar del drawer
  ///
  /// In es, this message translates to:
  /// **'Cerrar fórmulas'**
  String get formulasCloseA11y;

  /// Mensaje del loader de resultados
  ///
  /// In es, this message translates to:
  /// **'Calculando parámetros…'**
  String get calcLoading;

  /// Empty-state inicial sin datos
  ///
  /// In es, this message translates to:
  /// **'Ingresá una altitud y calculá para ver los parámetros ISA.'**
  String get calcEmptyState;

  /// Alerta de validación (400 outOfRange)
  ///
  /// In es, this message translates to:
  /// **'Altitud fuera de rango: el modelo cubre 0–36.089 ft (≈ 0–11.000 m). Corregí el valor.'**
  String get calcOutOfRange;

  /// Alerta de validación (400 invalidInput)
  ///
  /// In es, this message translates to:
  /// **'La entrada no es válida. Revisá el valor ingresado.'**
  String get calcInvalidInput;

  /// Alerta de error de sistema / sin conexión
  ///
  /// In es, this message translates to:
  /// **'No se pudo conectar con la API. Tu entrada se conservó — reintentá.'**
  String get calcConnectionError;

  /// Error de validación de formato numérico client-side
  ///
  /// In es, this message translates to:
  /// **'Ingresá un número'**
  String get calcNotANumber;

  /// Mensaje de error en el campo altitud ante outOfRange
  ///
  /// In es, this message translates to:
  /// **'Fuera de rango (0–36.089 ft)'**
  String get calcFieldOutOfRange;

  /// Mensaje de error en el campo altitud ante invalidInput
  ///
  /// In es, this message translates to:
  /// **'Valor no válido'**
  String get calcFieldInvalidInput;

  /// Título de la tabla de resultados
  ///
  /// In es, this message translates to:
  /// **'Resultados por magnitud (SI / imperial)'**
  String get calcResultsTitle;

  /// Anotación del recorte FG-2 en la tabla
  ///
  /// In es, this message translates to:
  /// **'FG-2: solo Analítico. FG-3 agrega columnas Interpolación · Δ · error %'**
  String get calcResultsAnnotation;

  /// Etiqueta de la magnitud temperatura
  ///
  /// In es, this message translates to:
  /// **'Temperatura (T)'**
  String get calcMagTemperature;

  /// Etiqueta de la magnitud presión
  ///
  /// In es, this message translates to:
  /// **'Presión (P)'**
  String get calcMagPressure;

  /// Etiqueta de la magnitud densidad
  ///
  /// In es, this message translates to:
  /// **'Densidad (ρ)'**
  String get calcMagDensity;

  /// Etiqueta de la viscosidad dinámica
  ///
  /// In es, this message translates to:
  /// **'Viscosidad dinámica (μ)'**
  String get calcMagDynamicViscosity;

  /// Etiqueta de la viscosidad cinemática
  ///
  /// In es, this message translates to:
  /// **'Viscosidad cinemática (ν)'**
  String get calcMagKinematicViscosity;

  /// Etiqueta de la velocidad del sonido
  ///
  /// In es, this message translates to:
  /// **'Velocidad del sonido (a)'**
  String get calcMagSpeedOfSound;

  /// Título de la sección de relativos
  ///
  /// In es, this message translates to:
  /// **'Relativos (adimensionales)'**
  String get calcRelativesTitle;

  /// Línea de relativos adimensionales formateados
  ///
  /// In es, this message translates to:
  /// **'θ={theta} · δ={delta} · σ={sigma} · a/a₀={aRatio} · μ/μ₀={muRatio}'**
  String calcRelatives(
    String theta,
    String delta,
    String sigma,
    String aRatio,
    String muRatio,
  );

  /// Badge de la altitud de entrada eco-devuelta en m y ft
  ///
  /// In es, this message translates to:
  /// **'Altitud: {meters} m · {feet} ft'**
  String calcAltitudeEcho(String meters, String feet);

  /// Nota del footer sobre cálculo/precisión
  ///
  /// In es, this message translates to:
  /// **'El cálculo lo hace la API · valores en SI e imperial · 5 cifras significativas'**
  String get calcFooter;

  /// aria-label de la tabla de resultados
  ///
  /// In es, this message translates to:
  /// **'Tabla de resultados por magnitud'**
  String get calcResultsTableA11y;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
