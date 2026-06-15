# ADR-003: Servicio stateless (sin persistencia)

**Status:** Accepted
**Date:** 2026-06-12
**Deciders:** Darío (dueño del producto), Technical Leader
**Tags:** persistencia, stateless, base-de-datos

## Context

El dominio es un **motor de cálculo puro**: una consulta entra, se computa y se devuelve.
No hay entidades de negocio que persistir y el **historial/exportación** está fuera de v1.

## Decision

`atmosphere-api` es **stateless**: sin base de datos, sin almacenamiento en disco, sin
sesión. Cada `POST /v1/calculate` se computa en memoria y se responde.

## Implementation Rules

- `atmosphere-api` MUST ser stateless: NO base de datos, NO persistencia en disco, NO estado de sesión entre requests.
- La `ISATable` se genera **en memoria** por request (puede cachearse en memoria del proceso, pero NO persistirse).
- NO se guarda historial de cálculos en v1.
- El servicio MUST poder escalar horizontalmente sin estado compartido (cualquier instancia responde cualquier request).

## Consequences

### Positive
- Despliegue y operación triviales (sin DB que administrar/backupear).
- Escala horizontal sin coordinación.

### Negative
- Sin historial ni resultados guardados (consistente con el alcance v1).

### Risks
- **Riesgo:** si más adelante se pide historial/export, habrá que introducir persistencia. **Mitigación:** está nombrado como diferido en el discovery; agregar una DB es aditivo y no rompe el contrato actual.

## Alternatives Considered

### Alternative 1: Base de datos para historial de cálculos
**Pros:** permite guardar/recuperar cálculos.
**Cons:** historial/export está fuera de v1; suma infraestructura innecesaria.
**Why rejected:** fuera de alcance v1; mantiene el sistema simple.

## References

- [docs/discovery/analisis-tecnico.md](../discovery/analisis-tecnico.md) (Arq-1)
- [docs/discovery/analisis-dominio.md](../discovery/analisis-dominio.md) (Ciclos de Vida y Estados; invariante "Stateless")
