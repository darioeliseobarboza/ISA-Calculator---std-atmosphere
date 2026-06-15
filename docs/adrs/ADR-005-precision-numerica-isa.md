# ADR-005: Precisión numérica (float64 + constantes exactas ISA 1976 derivadas)

**Status:** Accepted
**Date:** 2026-06-12
**Deciders:** Darío (dueño del producto), Technical Leader
**Tags:** precision, constantes, isa-1976, calidad

## Context

La tabla ISA de referencia (UTN) está **redondeada a 3 decimales**. El usuario pidió la
**máxima exactitud coherente**. La ganancia real de exactitud no está en buscar "más
decimales" de la tabla, sino en computar con las **constantes exactas del estándar ISA
1976/ICAO** en doble precisión y derivar el resto en runtime. Sustituir las constantes por
valores físicos más nuevos (p. ej. R\* de 2019) daría números incoherentes con la ISA y con
la tabla.

## Decision

- Cómputo en **`float64`**.
- Constantes **base exactas ISA 1976/ICAO**; los valores derivados (R, ρ₀, a₀, μ₀ y el exponente n) se calculan **en runtime**, sin hardcodear redondeados.
- **Sin redondeo interno**; el redondeo (5 cifras significativas) es solo de presentación.
- La tabla UTN es **cross-check** (dentro de su tolerancia de 3 decimales), no el techo de precisión.

## Implementation Rules

- Todo el cómputo MUST hacerse en `float64`.
- Constantes base (exactas) MUST ser: `R* = 8.31432 J/(mol·K)`, `M₀ = 0.0289644 kg/mol`, `T₀ = 288.15 K`, `P₀ = 101325 Pa`, `L = −0.0065 K/m` (= `−0.0019812 K/ft`), `g₀ = 9.80665 m/s²`, `γ = 1.4`, `β = 1.458e-6 kg/(m·s·√K)`, `S = 110.4 K`.
- Valores derivados MUST calcularse en runtime (NO hardcodear redondeados): `R = R*/M₀`, `ρ₀ = P₀/(R·T₀)`, `a₀ = √(γ·R·T₀)`, `μ₀ = β·T₀^1.5/(T₀+S)`, `n = g₀/(R·|L|)`.
- MUST NOT sustituir las constantes ISA 1976 por valores físicos más nuevos (mantener coherencia con la ISA y la tabla de referencia).
- MUST NOT redondear en el cálculo; el redondeo es SOLO de presentación: **5 cifras significativas**, con notación científica para μ, ν y P/ρ cuando corresponda.
- Validación: el método analítico MUST coincidir con la tabla UTN (en ft) dentro de su tolerancia de redondeo (3 decimales) en `0–36.089 ft`.

## Consequences

### Positive
- Resultados más precisos que la tabla (p. ej. ν₀ = 1.4607e-5 vs. 1.460 de la tabla).
- Coherencia total con el estándar ISA y con la tabla de referencia.

### Negative
- Hay que distinguir explícitamente "precisión de cálculo" (float64) de "precisión de presentación" (5 sig figs).

### Risks
- **Riesgo:** usar por error constantes físicas modernas y divergir de la tabla. **Mitigación:** constantes fijadas en este ADR + test de cross-check contra la tabla UTN.

## Alternatives Considered

### Alternative 1: Usar los valores redondeados de la tabla (3 decimales)
**Pros:** coincide exacto con la tabla impresa.
**Cons:** pierde precisión; arrastra el redondeo de la fuente.
**Why rejected:** el usuario quiere máxima exactitud; la tabla es validación, no fuente de precisión.

### Alternative 2: Constantes físicas más nuevas (R\* 2019, etc.)
**Pros:** "más modernas".
**Cons:** incoherentes con el estándar ISA 1976 y con la tabla.
**Why rejected:** rompería la coherencia con la ISA.

## References

- [docs/discovery/analisis-funcional.md](../discovery/analisis-funcional.md) (Decisión #21; Reglas FG-1)
- [docs/prd/requirements.md](../prd/requirements.md) (PhysicalConstants; NFR-Q01; Assumptions)
- [US Standard Atmosphere 1976 — NOAA](https://www.ngdc.noaa.gov/stp/space-weather/online-publications/miscellaneous/us-standard-atmosphere-1976/us-standard-atmosphere_st76-1562_noaa.pdf)
