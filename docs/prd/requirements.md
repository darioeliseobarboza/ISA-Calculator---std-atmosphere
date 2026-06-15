---
created: 2026-06-12
last_updated: 2026-06-12
status: "Draft - In Definition"
---

# PRD — Requerimientos — Calculadora ISA (Atmósfera Estándar)

> Derivado del discovery: [análisis de dominio](../discovery/analisis-dominio.md) · [análisis funcional](../discovery/analisis-funcional.md)

## Entidades del Dominio

> Vocabulario compartido en todo el PRD. Identificadores en **inglés** (tipos `PascalCase`,
> campos/enums `camelCase`); la prosa queda en español. Las magnitudes físicas se computan
> internamente en unidades base SI y la altitud en **ft** (canónica).

### CalculationRequest
- **Atributos clave:** geopotentialAltitude (number, req, constraint: equivalente a 0 ≤ h ≤ 36089 ft), altitudeUnit (enum: m/ft, default: ft), tableStep (number, opt, default: 1000, en altitudeUnit, constraint: >0 y ≤ 36089 ft equivalente)
- **Relaciones:** produce AtmosphericResult (×2: analytical + interpolation), produce Comparison
- **Notas:** `altitudeUnit` define la unidad de entrada de `geopotentialAltitude` y `tableStep` (m o ft). La entrada se **normaliza a ft** internamente (unidad canónica de cálculo, alineada a la tabla ISA de referencia) y se valida en `0–36.089 ft` (≈ `0–11.000 m`, tropopausa). Los resultados se devuelven en SI **e** imperial simultáneamente. La respuesta **eco-devuelve la altitud en m y ft** (ambas), sea cual sea la unidad de entrada. Fuera de rango o entrada no numérica → se rechaza (no calcula).

### AtmosphericLayer
- **Atributos clave:** name (enum: troposphere, req), baseAltitude (number, req, ft), topAltitude (number, req, ft), baseTemperature (number, req, K), basePressure (number, req, Pa), baseDensity (number, req, kg/m³), lapseRate (number, req, K/ft), type (enum: gradient/isothermal, default: gradient)
- **Relaciones:** references PhysicalConstants
- **Notas:** dato de configuración/referencia. v1 tiene una sola instancia: `troposphere` (baseAltitude 0 ft, topAltitude 36.089 ft, baseTemperature 288.15 K, basePressure 101325 Pa, baseDensity 1.225 kg/m³, lapseRate −0.0019812 K/ft ≡ −6.5 K/km, type gradient). Modelada como entidad para dejar lugar a futuras capas (p. ej. tropopausa isotérmica) sin reescribir el motor.

### PhysicalConstants
- **Atributos clave:** universalGasConstant (number, 8.31432 J/(mol·K)), airMolarMass (number, 0.0289644 kg/mol), g0 (number, 9.80665 m/s²), gasConstant (number, = universalGasConstant/airMolarMass ≈ 287.05287 J/(kg·K), **derivada**), gamma (number, 1.4), sutherlandBeta (number, 1.458e-6 kg/(m·s·√K)), sutherlandS (number, 110.4 K), refTemperature (number, 288.15 K), refPressure (number, 101325 Pa), refDensity (number, = refPressure/(gasConstant·refTemperature) ≈ 1.2250 kg/m³, **derivada**), refSpeedOfSound (number, = √(γ·gasConstant·refTemperature) ≈ 340.294 m/s, **derivada**), refViscosity (number, = β·refTemperature^1.5/(refTemperature+S) ≈ 1.78937e-5 Pa·s, **derivada**)
- **Relaciones:** —
- **Notas:** constantes **exactas del estándar ISA 1976 / ICAO**; las derivadas (gasConstant, refDensity, refSpeedOfSound, refViscosity y el exponente n) se calculan en runtime con doble precisión (float64), no se hardcodean redondeadas. No se sustituyen por constantes físicas más nuevas (romperían la coherencia con la tabla).

### AtmosphericResult
- **Atributos clave:** method (enum: analytical/interpolation, req); magnitudes absolutas **expresadas en SI e imperial** (par {si, imperial} cada una): temperature, pressure, density, dynamicViscosity, kinematicViscosity, speedOfSound; relativos (adimensionales, valor único): theta, delta, sigma, speedOfSoundRatio (= a/a₀), viscosityRatio (= μ/μ₀)
- **Relaciones:** se deriva de AtmosphericLayer (si method=analytical) o de ISATable (si method=interpolation)
- **Notas:** cada magnitud absoluta se devuelve en **ambos** sistemas (SI e imperial) a la vez; los relativos son adimensionales (un único valor, igual en cualquier sistema). `dynamicViscosity` = μ (viscosidad absoluta); `kinematicViscosity` = ν = μ/ρ.

### TableNode
- **Atributos clave:** altitude (number, req, ft), temperature (number, K), pressure (number, Pa), density (number, kg/m³), dynamicViscosity (number, Pa·s)
- **Relaciones:** belongs_to ISATable
- **Notas:** la altitud del nodo está en **ft** (unidad canónica); las columnas físicas se guardan en unidades base (K, Pa, kg/m³, Pa·s) y se convierten a SI/imperial al construir la respuesta. ν y a **no** se tabulan (se derivan de los valores interpolados).

### ISATable
- **Atributos clave:** step (number, req, ft, default: 1000), minAltitude (number, = 0 ft), maxAltitude (number, = 36089 ft), nodeCount (int, derivado)
- **Relaciones:** has_many TableNode, generada de AtmosphericLayer
- **Notas:** generada por fórmula (no se embebe tabla publicada), con grilla en **ft** alineada a la tabla ISA de referencia. Se regenera cuando cambia `step`.

### Comparison
- **Atributos clave:** (agrega los dos resultados y sus diferencias)
- **Relaciones:** references AtmosphericResult (analytical), references AtmosphericResult (interpolation), has_many MagnitudeDifference
- **Notas:** el método analítico es la referencia del error.

### MagnitudeDifference
- **Atributos clave:** magnitude (enum: temperature/pressure/density/dynamicViscosity/kinematicViscosity/speedOfSound/theta/delta/sigma/speedOfSoundRatio/viscosityRatio, req), analyticalValue (number; par {si, imperial} si la magnitud es absoluta), interpolationValue (number; par {si, imperial} si es absoluta), absoluteDifference (number, = interpolation − analytical; par {si, imperial} si es absoluta), relativeErrorPct (number, = absoluteDifference/analyticalValue · 100; **único**, adimensional)
- **Relaciones:** belongs_to Comparison
- **Notas:** el `relativeErrorPct` es independiente del sistema de unidades (es un ratio). Si `analyticalValue` = 0 el error relativo no aplica (no ocurre en el rango ISA, pero queda contemplado).

## Core Features

### F-01: Cálculo y comparación ISA

**Descripción:** Núcleo del producto. Dada una altitud geopotencial, calcula los
parámetros atmosféricos ISA por **dos métodos** (analítico e interpolación) y los presenta
**lado a lado** con su diferencia/error. Devuelve cada magnitud absoluta en **SI e
imperial** a la vez, los relativos (adimensionales) y la **altitud en m y ft**.

**User Story:**
Como usuario técnico (U-01),
quiero calcular los parámetros ISA de una altitud por dos métodos y compararlos,
para obtener los valores y dimensionar el error de interpolación.

**Capabilities:**

| ID | Capability | Actor | Entity | Operation | Key Fields | Business Rules |
|----|-----------|-------|--------|-----------|------------|----------------|
| C-01 | Calcular punto ISA (ambos métodos + comparación) | U-01 | AtmosphericResult, Comparison | ACTION (compute) | **in:** geopotentialAltitude (number, req), altitudeUnit (enum: m/ft, default: ft), tableStep (number, opt, default: 1000 ft) · **out:** results.{analytical,interpolation} con temperature/pressure/density/dynamicViscosity/kinematicViscosity/speedOfSound (par {si,imperial}) + theta/delta/sigma/speedOfSoundRatio/viscosityRatio (adim); comparison[] (MagnitudeDifference); input.geopotentialAltitude ({m,ft}) | Normaliza la entrada a **ft** y valida `0–36.089 ft`. Calcula analytical (fórmulas ISA cerradas) e interpolation (grilla de tabla en ft). `relativeErrorPct = (interpolation − analytical)/analytical · 100`. Salida en SI e imperial simultáneos; relativos únicos |
| C-02 | Configurar paso de la tabla | U-01 | ISATable | ACTION (param) | tableStep (number, default: 1000 ft, constraint: >0 y ≤ 36089 ft equiv.) | Regenera la tabla; afecta solo al método de interpolación. Reducir el paso reduce el error |
| C-03 | Validar la entrada | Sistema (atmosphere-api) | CalculationRequest | ACTION (validate) | geopotentialAltitude, tableStep | Fuera de rango / no numérica / paso inválido → HTTP 400 con `error.code` (`outOfRange` \| `invalidInput` \| `invalidStep`); no calcula |

**Acceptance Criteria:**
- DADO que ingreso `geopotentialAltitude = 16404` con `altitudeUnit = "ft"` (≈ 5.000 m)
  CUANDO calculo
  ENTONCES obtengo T ≈ 255,65 K (≈ 460,2 °R), P ≈ 54.020 Pa (≈ 1.128 psf), ρ, μ, ν, a en SI e imperial
  Y la respuesta incluye `input.geopotentialAltitude = { "m": 5000.0, "ft": 16404 }`
  Y la comparación muestra **error ≈ 0 en temperature** y error apreciable en pressure/density

- DADO un cálculo con `tableStep = 500 ft` vs `tableStep = 2000 ft`
  CUANDO comparo el `relativeErrorPct` de la presión
  ENTONCES el error con 500 ft es **menor** que con 2000 ft

- DADO que ingreso `geopotentialAltitude = 40000` con `altitudeUnit = "ft"` (> 36.089 ft)
  CUANDO calculo
  ENTONCES la API responde HTTP 400 con `error.code = "outOfRange"` y no calcula

**Priority:** High

**Dependencies:** None (feature base)

---

### F-02: Fórmulas de conversión (referencia)

**Descripción:** Apartado de **referencia** (contenido estático en el frontend) que muestra,
por cada magnitud, la fórmula/factor para pasar de un sistema a otro (SI ↔ imperial, y
m ↔ ft para la altitud). No calcula: es material de consulta.

**User Story:**
Como usuario técnico (U-01),
quiero ver las fórmulas/factores de conversión por magnitud,
para entender y verificar cómo se pasa de un sistema de unidades al otro.

**Capabilities:**

| ID | Capability | Actor | Entity | Operation | Key Fields | Business Rules |
|----|-----------|-------|--------|-----------|------------|----------------|
| C-04 | Ver fórmulas de conversión | U-01 | — (contenido estático) | READ | por magnitud: siUnit, imperialUnit, factor/formula | Contenido estático en el frontend (sin endpoint). Cubre altitud (m↔ft), T, P, ρ, μ, ν, a; los relativos son adimensionales (sin conversión) |

**Acceptance Criteria:**
- DADO que abro la sección de fórmulas de conversión
  CUANDO la reviso
  ENTONCES veo, por magnitud, la fórmula/factor (p. ej. `1 ft = 0.3048 m`, `°R = K × 1.8`, `1 psf = 47.8803 Pa`)
  Y los relativos (θ, δ, σ, a/a₀, μ/μ₀) figuran como adimensionales (sin conversión)

**Priority:** Medium

**Dependencies:** None

---

## Non-Functional Requirements

### Performance

| ID | Requirement | Target | Measurement |
|----|------------|--------|-------------|
| NFR-P01 | Tiempo de cálculo (server-side) | < 100 ms (P95) por punto | Cómputo en memoria; test/APM local |
| NFR-P02 | Regeneración de tabla | < 100 ms con paso default (1.000 ft) | Test local |

### Usabilidad / Presentación

| ID | Requirement | Target | Measurement |
|----|------------|--------|-------------|
| NFR-U01 | Idioma | UI íntegramente en español (único en v1) | Revisión |
| NFR-U02 | Precisión numérica | 5 cifras significativas; notación científica para μ, ν y P/ρ cuando corresponda | Revisión / test |
| NFR-U03 | Doble unidad | Cada magnitud absoluta visible en SI e imperial a la vez | Test de UI |

### Portabilidad / Plataforma

| ID | Requirement | Target | Phase |
|----|------------|--------|-------|
| NFR-PL01 | Targets del frontend | Windows, Linux y Web (Flutter) | MVP |
| NFR-PL02 | Conectividad | Requiere alcanzar la API para calcular; sin red muestra error (no es offline) | MVP |

### Seguridad

| ID | Requirement | Target | Measurement |
|----|------------|--------|-------------|
| NFR-S01 | Autenticación | Ninguna en v1 (herramienta personal, sin datos sensibles) | — |
| NFR-S02 | CORS | Orígenes permitidos configurables en la API (para el target Web) | Config verificable |

### Calidad / Exactitud

| ID | Requirement | Target | Measurement |
|----|------------|--------|-------------|
| NFR-Q01 | Exactitud del método analítico | Reproduce el estándar ISA exacto (float64, constantes ISA 1976); cross-check vs. tabla UTN (ft, 3 decimales) dentro de su tolerancia de redondeo en `0–36.089 ft` | Test contra `docs/references/` |

## Assumptions

- El usuario tiene la API accesible (local o remota); el frontend requiere conectividad para calcular.
- Constantes **exactas del estándar ISA 1976/ICAO**: R*=8.31432 J/(mol·K), M₀=0.0289644 kg/mol, R=R*/M₀≈287.05287 J/(kg·K), T₀=288.15 K, P₀=101325 Pa, L=−6.5 K/km, g₀=9.80665 m/s², γ=1.4; Sutherland β=1.458e-6, S=110.4 K. ρ₀, a₀, μ₀ y el exponente n se **derivan en runtime** (float64). No se sustituyen por constantes físicas más nuevas (romperían la coherencia con ISA/la tabla).
- Cálculo interno en **float64 sin redondeo**; el redondeo (5 cifras significativas) es solo de presentación. La tabla UTN (3 decimales) es un cross-check, no el límite de precisión.
- El método **analítico** es ground-truth en `0–36.089 ft`; la tabla UTN (en ft) es la referencia de validación.
- Factores de conversión estándar (1 ft = 0.3048 m, °R = K×1.8, 1 psf = 47.8803 Pa, 1 slug/ft³ = 515.379 kg/m³, 1 slug/(ft·s) = 47.8803 Pa·s, 1 ft²/s = 0.092903 m²/s).

## Open Questions

- Tolerancia exacta de exactitud del método analítico vs. la tabla de referencia (se fija en testing).
- ¿Sumar más unidades a futuro (°C/°F, mb/inHg, kt), tal como aparecen en la tabla UTN? (v1 muestra SI + imperial). Diferido.
- Capa isoterma (36.089–64.000 ft), altitud geométrica y `ν/ν₀`: fuera de v1 (ya decididos).
