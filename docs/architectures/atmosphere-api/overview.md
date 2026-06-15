# atmosphere-api — Overview

## Propósito

API stateless de cálculo de Atmósfera Estándar ISA en la tropósfera: métodos analítico e
interpolación + comparación, con salida en SI e imperial.

## Tipo de servicio

API en Golang (Go 1.26.4).

## Módulos del dominio

- **calculation** — motor ISA: método analítico, interpolación, comparación y generación de la tabla (incluye constantes y capas del modelo ISA).
- **units** — conversión SI ↔ imperial y m ↔ ft.

## Notas adicionales

Stateless (sin base de datos). Corre detrás del proxy `ingress-network` con CORS habilitado.
Cálculo en `float64` con las constantes exactas ISA 1976 (R, ρ₀, a₀, μ₀ derivadas en runtime).
Validación de inputs con la stdlib (sin librería de validación). Empaquetado vía `docker/`
(compose dev/prod). Ver ADR-001 (stack), ADR-003 (stateless), ADR-004 (deployment), ADR-005 (precisión).

---

**Manifest:** [manifest.yaml](./manifest.yaml)
**Índice de arquitectura:** [index.md](./index.md)
