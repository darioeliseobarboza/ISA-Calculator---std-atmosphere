# ADR-002: Unidad canónica de cálculo en pies (ft) y salida SI + imperial simultánea

**Status:** Accepted
**Date:** 2026-06-12
**Deciders:** Darío (dueño del producto), Technical Leader
**Tags:** unidades, dominio, contrato-api

## Context

La tabla ISA de referencia que se usa para validar (UTN) está expresada en **pies (ft)**.
Para que la interpolación caiga sobre los nodos de esa tabla y se evite el desajuste de
conversión, conviene calcular en ft. El usuario puede ingresar la altitud en **m o ft**,
y quiere ver los resultados en **SI e imperial a la vez**.

## Decision

- **Unidad canónica interna de altitud = ft.** Toda altitud (entrada y grilla de la tabla) se normaliza a ft antes de calcular.
- La entrada lleva `altitudeUnit` (`m`/`ft`, default `ft`); independiente de la salida.
- Validación de rango en `0–36.089 ft` (≈ 0–11.000 m, tropopausa).
- **Salida: cada magnitud absoluta en SI e imperial simultáneamente** (objeto `{si, imperial}`); los relativos son adimensionales (valor único). No hay toggle ni campo de sistema de unidades en el request.
- La respuesta eco-devuelve la altitud en **m y ft**.

## Implementation Rules

- La unidad canónica interna de altitud MUST ser **ft**; la entrada se normaliza a ft con `1 ft = 0.3048 m` (exacto) antes de validar/calcular.
- `altitudeUnit` MUST ser enum `m` | `ft`, default `ft`.
- Validación MUST ser `0 ≤ h ≤ 36089 ft`; fuera de rango → `400` `outOfRange`.
- Cada magnitud **absoluta** (`temperature`, `pressure`, `density`, `dynamicViscosity`, `kinematicViscosity`, `speedOfSound`) MUST devolverse como objeto `{ "si": number, "imperial": number }`.
- Los **relativos** (`theta`, `delta`, `sigma`, `speedOfSoundRatio`, `viscosityRatio`) MUST ser un número único (adimensional).
- Unidades: **SI** = K, Pa, kg/m³, Pa·s, m²/s, m/s; **imperial** = °R, lbf/ft² (psf), slug/ft³, slug/(ft·s), ft²/s, ft/s.
- La respuesta MUST incluir `input.geopotentialAltitude` como `{ "m": number, "ft": number }`.
- El request MUST NOT incluir un campo de sistema de unidades (la respuesta trae ambos).

## Consequences

### Positive
- La interpolación se alinea con la tabla de referencia (en ft).
- El usuario ve ambos sistemas sin cambiar de modo.
- Entrada flexible (m o ft) desacoplada de la salida.

### Negative
- La respuesta es más grande (cada absoluto duplicado SI/imperial).
- Conversión de unidades concentrada en la API (más lógica de presentación en el backend).

### Risks
- **Riesgo:** errores de conversión. **Mitigación:** factores estándar fijos (ADR-005 / sección de fórmulas) y validación contra la tabla UTN.

## Alternatives Considered

### Alternative 1: Toggle de un sistema a la vez
**Pros:** respuesta más compacta.
**Cons:** el usuario quiere ver ambos a la vez.
**Why rejected:** decisión explícita del usuario (ver ambos simultáneamente).

### Alternative 2: Unidad canónica en metros (SI)
**Pros:** las constantes ISA son métricas.
**Cons:** la tabla de referencia está en ft → desajuste en la grilla de interpolación.
**Why rejected:** se prioriza coherencia con la tabla de referencia (en ft).

## References

- [docs/discovery/analisis-tecnico.md](../discovery/analisis-tecnico.md) (Arq-5)
- [docs/discovery/analisis-dominio.md](../discovery/analisis-dominio.md) (CalculationRequest, AtmosphericResult)
- [docs/references/atmosfera_tipo_internacional_ISA.pdf](../references/atmosfera_tipo_internacional_ISA.pdf)
