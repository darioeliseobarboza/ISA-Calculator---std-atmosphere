---
created: 2026-06-12
last_updated: 2026-06-12
status: "Análisis de dominio cerrado"
analisis_funcional: docs/discovery/analisis-funcional.md
---

# Análisis de Dominio (DDD-light) — Calculadora ISA

> **Convención de nombres:** los identificadores (entidades, campos, enums) van en
> **inglés** — tipos en `PascalCase`, campos/enums en `camelCase`. La prosa queda en español.

## Lenguaje Ubicuo

| Término | Definición | Identificador |
|---|---|---|
| ISA | Atmósfera Estándar Internacional; modelo que define T, P, ρ por altitud | — |
| Altitud geopotencial | Altitud usada por el modelo ISA (corrige la variación de g con la altura) | `geopotentialAltitude` |
| Capa atmosférica | Tramo del modelo con un gradiente térmico propio (v1: solo **tropósfera**, 0–36.089 ft) | `AtmosphericLayer` |
| Método analítico | Cálculo directo con las fórmulas cerradas de la ISA; **referencia** del error | `method: analytical` |
| Método de interpolación | Interpolación lineal dentro de una tabla generada por fórmula | `method: interpolation` |
| Nodo | Fila tabulada (h, T, P, ρ, μ) de la tabla | `TableNode` |
| Paso (Δh) | Separación entre nodos de la tabla (default 1.000 ft) | `tableStep` / `step` |
| Tabla ISA | Conjunto de nodos entre 0 y 36.089 ft a un paso dado | `ISATable` |
| Viscosidad dinámica (μ) | Viscosidad por la fórmula de Sutherland; se deriva de T | `dynamicViscosity` |
| Viscosidad cinemática (ν) | ν = μ/ρ | `kinematicViscosity` |
| Velocidad del sonido (a) | a = √(γ·R·T), γ=1.4 | `speedOfSound` |
| Valores relativos | Ratios adimensionales al nivel del mar ISA: θ, δ, σ, a/a₀, μ/μ₀ | `theta`,`delta`,`sigma`,`speedOfSoundRatio`,`viscosityRatio` |
| Diferencia / error relativo | Δ = interp − analítico; ε = Δ/analítico · 100 | `absoluteDifference` / `relativeErrorPct` |
| Sistema de unidades | Sistemas de **salida**: SI e imperial (ambos a la vez) | `si` / `imperial` |
| Unidad de altitud | Unidad de la **entrada** (m o ft); se normaliza a ft | `altitudeUnit` |

---

## Entidades

> Notación reutilizable verbatim por `/product-initialize`:
> `campo (tipo, req/opt, constraint)`, `estado (enum: a/b/c, default: a)`.
> La altitud se maneja internamente en **ft** (unidad canónica); las demás magnitudes
> físicas se computan en unidades base SI (K, Pa, kg/m³, …) y se devuelven en SI **e** imperial.

### CalculationRequest
- **Atributos clave:** geopotentialAltitude (number, req, constraint: equivalente a 0 ≤ h ≤ 36089 ft), altitudeUnit (enum: m/ft, default: ft, req), tableStep (number, opt, default: 1000, en altitudeUnit, constraint: >0 y ≤ 36089 ft equivalente)
- **Relaciones:** produce AtmosphericResult (×2: analytical + interpolation) y Comparison
- **Notas:** `altitudeUnit` define la unidad de entrada de `geopotentialAltitude` y `tableStep` (m o ft). La entrada se **normaliza a ft** internamente (unidad canónica, alineada a la tabla ISA de referencia) y se valida en `0–36.089 ft` (≈ `0–11.000 m`). Los resultados se devuelven en SI e imperial simultáneamente. La respuesta **eco-devuelve la altitud en m y ft** (ambas). Fuera de rango o no numérica → se rechaza (no se calcula).

### AtmosphericLayer
- **Atributos clave:** name (enum: troposphere, req), baseAltitude (number, req, ft), topAltitude (number, req, ft), baseTemperature (number, req, K), basePressure (number, req, Pa), baseDensity (number, req, kg/m³), lapseRate (number, req, K/ft), type (enum: gradient/isothermal, default: gradient)
- **Relaciones:** references PhysicalConstants
- **Notas:** dato de **configuración/referencia**. v1 tiene una sola instancia: `troposphere` (base 0 ft, tope 36.089 ft, baseTemperature 288.15 K, basePressure 101325 Pa, baseDensity 1.225 kg/m³, lapseRate −0.0019812 K/ft ≡ −6.5 K/km, type gradient). Modelada como entidad para dejar lugar a futuras capas (p. ej. tropopausa isotérmica) sin reescribir el motor.

### PhysicalConstants
- **Atributos clave:** universalGasConstant (number, 8.31432 J/(mol·K)), airMolarMass (number, 0.0289644 kg/mol), g0 (number, 9.80665 m/s²), gasConstant (number, = universalGasConstant/airMolarMass ≈ 287.05287 J/(kg·K), **derivada**), gamma (number, 1.4), sutherlandBeta (number, 1.458e-6 kg/(m·s·√K)), sutherlandS (number, 110.4 K), refTemperature (number, 288.15 K), refPressure (number, 101325 Pa), refDensity (number, = refPressure/(gasConstant·refTemperature) ≈ 1.2250 kg/m³, **derivada**), refSpeedOfSound (number, = √(γ·gasConstant·refTemperature) ≈ 340.294 m/s, **derivada**), refViscosity (number, = β·refTemperature^1.5/(refTemperature+S) ≈ 1.78937e-5 Pa·s, **derivada**)
- **Relaciones:** —
- **Notas:** constantes **exactas del estándar ISA 1976 / ICAO** (no se sustituyen por constantes físicas más nuevas, que romperían la coherencia con la tabla). Las derivadas (gasConstant, refDensity, refSpeedOfSound, refViscosity y el exponente `n = g0/(gasConstant·|lapseRate|) ≈ 5.25588`) se calculan **en runtime con doble precisión (float64)**, no se hardcodean redondeadas. La tabla UTN (3 decimales) es un **cross-check**, no el techo de precisión.

### AtmosphericResult
- **Atributos clave:** method (enum: analytical/interpolation, req); magnitudes absolutas **en SI e imperial** (par {si, imperial}): temperature, pressure, density, dynamicViscosity, kinematicViscosity, speedOfSound; relativos (adimensionales, valor único): theta, delta, sigma, speedOfSoundRatio (= a/a₀), viscosityRatio (= μ/μ₀)
- **Relaciones:** se deriva de AtmosphericLayer (si method=analytical) o de ISATable (si method=interpolation)
- **Notas:** cada magnitud absoluta se devuelve en **ambos** sistemas (SI e imperial) a la vez; los relativos son adimensionales (único valor).

### TableNode
- **Atributos clave:** altitude (number, req, ft), temperature (number, K), pressure (number, Pa), density (number, kg/m³), dynamicViscosity (number, Pa·s)
- **Relaciones:** belongs_to ISATable
- **Notas:** la altitud del nodo está en **ft** (grilla canónica); las columnas físicas se guardan en unidades base (K, Pa, kg/m³, Pa·s). ν y a **no** se tabulan (se derivan de los valores interpolados).

### ISATable
- **Atributos clave:** step (number, req, ft, default: 1000), minAltitude (number, = 0 ft), maxAltitude (number, = 36089 ft), nodeCount (int, derivado)
- **Relaciones:** has_many TableNode, generada de AtmosphericLayer
- **Notas:** generada por fórmula (no se embebe tabla publicada), grilla en **ft** alineada a la tabla ISA de referencia. Se regenera cuando cambia `step`.

### Comparison
- **Atributos clave:** (agrega los dos resultados y sus diferencias)
- **Relaciones:** references AtmosphericResult (analytical), references AtmosphericResult (interpolation), has_many MagnitudeDifference
- **Notas:** el método analítico es la referencia del error.

### MagnitudeDifference
- **Atributos clave:** magnitude (enum: temperature/pressure/density/dynamicViscosity/kinematicViscosity/speedOfSound/theta/delta/sigma/speedOfSoundRatio/viscosityRatio, req), analyticalValue (number; par {si, imperial} si la magnitud es absoluta), interpolationValue (number; par {si, imperial} si es absoluta), absoluteDifference (number, = interpolation − analytical; par {si, imperial} si es absoluta), relativeErrorPct (number, = absoluteDifference/analyticalValue · 100; **único**, adimensional)
- **Relaciones:** belongs_to Comparison
- **Notas:** el `relativeErrorPct` es independiente del sistema de unidades (ratio). Si `analyticalValue` = 0 el error relativo no aplica (no ocurre en el rango ISA, pero queda contemplado).

---

## Ciclos de Vida y Estados

**Ninguna entidad de dominio tiene ciclo de vida ni estado persistente.** El dominio es
un **motor de cálculo puro (stateless)**: una consulta entra, se computa y se devuelve;
nada se guarda. No hay máquinas de estado de negocio que modelar.

El único "estado" es transitorio y vive en **Presentación** (UI), no en el dominio:

| Estado (UI) | Cuándo | Transiciones permitidas | Prohibidas |
|---|---|---|---|
| idle | Sin entrada válida aún | → validando | — |
| validando | Se ingresó una altitud/paso | → calculado, → error | — |
| calculado | Respuesta recibida y mostrada | → validando (nueva consulta) | — |
| error | Entrada inválida o fallo de la petición | → validando | → calculado (sin recalcular) |

---

## Invariantes y Reglas de Negocio

1. **CalculationRequest** — `geopotentialAltitude` se normaliza desde `altitudeUnit` (m/ft) a **ft** y debe quedar en `[0, 36089] ft` (≈ 0–11.000 m); fuera de rango no se calcula.
2. **CalculationRequest** — `tableStep > 0` y `≤ 36089 ft` equivalente.
3. **AtmosphericLayer (tropósfera)** — `T = baseTemperature + lapseRate · h`, con `lapseRate = −0.0019812 K/ft` (≡ −6.5 K/km) y `h` en ft.
4. **Cálculo analítico** — `P = P₀·(T/T₀)^n` y `ρ = ρ₀·(T/T₀)^(n−1)`, con `n = g0/(gasConstant·|lapseRate|) ≈ 5.25588`.
5. **Cálculo** — `a = √(γ·gasConstant·T)`; `μ = β·T^1.5/(T+S)`; `ν = μ/ρ` (T en K).
6. **Valores relativos** — `theta=T/T₀`, `delta=P/P₀`, `sigma=ρ/ρ₀`, `speedOfSoundRatio=√theta`, `viscosityRatio=μ/μ₀`; referencia = nivel del mar ISA; adimensionales (idénticos en cualquier sistema de unidades).
7. **Cálculo** — la altitud se maneja en **ft** (canónica) y el resto en unidades base SI; la entrada se normaliza desde `altitudeUnit` a ft y la salida se entrega en SI **e** imperial a la vez.
8. **ISATable** — los nodos se generan con las mismas fórmulas analíticas; se tabulan temperature, pressure, density, dynamicViscosity; ν y a se derivan.
9. **Interpolación** — `dynamicViscosity` se interpola de su columna; `ν = μ_interp/ρ_interp`; `a = √(γ·gasConstant·T_interp)`.
10. **Interpolación** — si `h` coincide con un nodo, el resultado = valor del nodo (error ≈ 0).
11. **Comparison** — el analítico es la referencia; `relativeErrorPct = (interpolation − analytical)/analytical · 100`.
12. **Monotonía (tropósfera)** — T, P y ρ decrecen al aumentar `h` (chequeo de sanidad).
13. **Stateless** — ninguna consulta ni resultado se persiste (sin historial en v1).

---

## Eventos de Dominio

> Conceptuales. En una arquitectura request/response stateless son eventos **lógicos**;
> el transporte (HTTP u otro) se decide en `/product-discovery-technical`.

| Evento | Disparado por | Datos clave | Contexto |
|---|---|---|---|
| CalculationRequested | El frontend solicita un cálculo | geopotentialAltitude, altitudeUnit, tableStep | Cálculo Atmosférico |
| CalculationCompleted | Se computan ambos métodos + comparación | results (analytical/interpolation) + comparison | Cálculo Atmosférico |
| InputRejected | Altitud/paso fuera de rango o no numérico | code, message | Cálculo Atmosférico |
| TableRegenerated | Cambió el paso de la tabla | step, nodeCount | Cálculo Atmosférico |

---

## Contextos Delimitados

| Contexto | Entidades | Responsabilidad | Servicio(s) |
|---|---|---|---|
| **Cálculo Atmosférico** | CalculationRequest, AtmosphericLayer, PhysicalConstants, AtmosphericResult, TableNode, ISATable, Comparison, MagnitudeDifference | Ejecutar ambos métodos, generar la tabla, computar comparación/error y **convertir las unidades de salida**. Stateless. | **atmosphere-api** (backend) |
| **Presentación** | — (sin entidades de dominio; solo estado de UI) | Entrada del usuario, selección de unidad de altitud, formato/precisión, render de la comparación. **No calcula.** | **atmosphere-app** (frontend: Windows, Linux, Web) |

**Relaciones entre contextos:** Presentación es **downstream** de Cálculo Atmosférico —
consume los resultados por petición y solo los muestra. Toda la lógica de dominio
(fórmulas, tabla, comparación, conversión de unidades) vive en `atmosphere-api`.

---

## Notas de Consistencia

- Los nombres de magnitudes coinciden con el análisis funcional (T, P, ρ, μ, ν, a +
  relativos θ/δ/σ/a-a₀/μ-μ₀); los identificadores de código van en inglés (ver convención arriba).
- **Unidades** en el contexto de Cálculo (`atmosphere-api`): la `CalculationRequest` lleva
  `altitudeUnit` (entrada, se normaliza a ft); la respuesta trae cada magnitud absoluta
  en SI **e** imperial a la vez. El frontend elige la unidad de entrada y muestra ambos sistemas.
- **Sin persistencia (stateless):** el contexto de Cálculo no requiere base de datos.
- **AtmosphericLayer** se modela como configuración extensible: v1 tiene solo la
  tropósfera, pero el modelo admite sumar capas a futuro.
- Coherencia con la arquitectura cliente-servidor: el cálculo es remoto (`atmosphere-api`),
  el frontend (`atmosphere-app`) solo presenta.
