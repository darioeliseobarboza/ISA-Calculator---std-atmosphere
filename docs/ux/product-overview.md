---
document: Product Overview
version: "1.0"
date: 2026-06-21
status: "Draft - Punto de partida para discusión"
device: desktop-first
---

# Product Overview — Calculadora ISA (Atmósfera Estándar)

> Documento raíz del set de UX. Define audiencias, superficies y la relación
> entre ellas. Todos los demás artefactos UX referencian acá.

## Visión del Producto

**Problema:** Obtener los parámetros atmosféricos ISA (temperatura, presión, densidad, viscosidad, velocidad del sonido) a una altitud dada se resuelve a mano, con tablas impresas o planillas sueltas: lento, propenso a error y sin ver fácilmente cuánto difiere un método de cálculo de otro.

**Propuesta de valor:** Una herramienta personal de ingeniería que, dada una altitud geopotencial en la tropósfera, calcula los parámetros por dos métodos (analítico e interpolación) y los muestra lado a lado con su diferencia/error, en unidades SI e imperial a la vez. El valor central no es solo obtener los números rápido, sino **comparar y cuantificar el error** entre métodos.

**Plataforma:** cliente de escritorio/web (Windows, Linux y Web, Flutter). El caso primario es **escritorio** → los wireframes se diseñan **desktop-first** (1200×800).

## Inventario de Superficies

- **app-calculadora** — Único cliente con UI (app Flutter en Windows/Linux/Web). La usa el `ingeniero-tecnico` para ingresar una altitud, ver los parámetros ISA (analítico, y en FG-3 la comparación con interpolación) en SI e imperial, y consultar las fórmulas de conversión. El backend `atmosphere-api` no es una superficie (no tiene UI).

## Inventario de Audiencias

- **ingeniero-tecnico** — Ingeniero/técnico que usa la herramienta de forma personal para obtener los parámetros ISA de una altitud y comparar métodos. Único usuario del producto; sin roles, cuentas ni autenticación. Necesita precisión, lectura clara de magnitudes en doble unidad y entender el error entre métodos.

## Matriz Audiencia ↔ Superficie

| Audiencia \ Superficie | app-calculadora |
|-------------------------|-----------------|
| ingeniero-tecnico       | Ingresa altitud y unidad; consume los parámetros ISA en SI e imperial; consulta las fórmulas de conversión |

> Producto **mono-superficie**: no hay flujos que crucen entre superficies (ver `cross-surface-flows.md`).

## Glosario de Dominio

- **ISA (Atmósfera Estándar Internacional)** — Modelo de referencia que define cómo varían T, P, ρ, etc. con la altitud; en v1 se cubre la tropósfera.
- **Altitud geopotencial** — Altitud de entrada del cálculo; se ingresa en m o ft y se normaliza internamente a ft (unidad canónica).
- **Tropósfera** — Capa modelada en v1: `0–36.089 ft` (≈ 0–11.000 m), gradiente de temperatura −6,5 K/km.
- **Método analítico** — Cálculo por fórmulas cerradas del estándar ISA; es el valor de referencia (ground-truth).
- **Método por interpolación** — Cálculo interpolando una tabla generada por fórmula (paso configurable); llega en FG-3.
- **Comparación / error relativo** — Diferencia absoluta y error porcentual de cada magnitud entre interpolación y analítico (FG-3).
- **Magnitudes absolutas** — Temperatura (T), presión (P), densidad (ρ), viscosidad dinámica (μ), viscosidad cinemática (ν), velocidad del sonido (a).
- **Relativos** — Valores adimensionales respecto al nivel del mar ISA: θ (T/T₀), δ (P/P₀), σ (ρ/ρ₀), a/a₀, μ/μ₀.
- **Doble unidad (SI / imperial)** — Cada magnitud absoluta se muestra en ambos sistemas a la vez (SI: K, Pa, kg/m³…; imperial: °R, lbf/ft², slug/ft³…).
- **Fórmulas de conversión** — Sección de referencia estática que muestra, por magnitud, la fórmula/factor para pasar de un sistema a otro (SI↔imperial y m↔ft).
- **Paso de la tabla** — Distancia entre nodos de la grilla de interpolación; reducirlo reduce el error (FG-3).

---

**Próximos artefactos:** Cada audiencia y superficie listada arriba tiene su documentación detallada en `docs/ux/audiences/{nombre}/` y `docs/ux/surfaces/{nombre}/` respectivamente.
