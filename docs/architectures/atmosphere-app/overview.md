# atmosphere-app — Overview

## Propósito

Frontend multiplataforma (Windows/Linux/Web) de la Calculadora ISA: ingresar altitud y
unidad, ver la comparación analítico vs. interpolación en SI e imperial, y consultar las
fórmulas de conversión.

## Tipo de servicio

Frontend en Flutter (Dart).

## Módulos / superficies

- **calculator** — pantalla de cálculo y comparación (entrada de altitud/unidad + resultados en SI e imperial).
- **formulas** — sección de referencia con las fórmulas/factores de conversión.

> FG-1 arranca con una pantalla provisional de *health* (prueba de vida contra la API), que FG-2 reemplaza por `calculator`.

## Notas adicionales

Consume `atmosphere-api` (`POST /v1/calculate`, `GET /health`). Muestra ambos sistemas
(SI e imperial) a la vez; el formato numérico usa `intl` (5 cifras significativas, notación
científica donde corresponde — NFR-U02). No calcula ni persiste. El target Web se sirve por
contenedor nginx; los targets desktop son binarios nativos. Sin autenticación. Ver ADR-001
(stack), ADR-002 (unidades) y ADR-004 (deployment).

---

**Manifest:** [manifest.yaml](./manifest.yaml)
**Índice de arquitectura:** [index.md](./index.md)
