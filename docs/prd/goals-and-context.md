---
created: 2026-06-12
last_updated: 2026-06-12
status: "Draft - In Definition"
---

# PRD — Objetivos y Contexto — Calculadora ISA (Atmósfera Estándar)

> Derivado del discovery: [análisis funcional](../discovery/analisis-funcional.md) · [análisis de dominio](../discovery/analisis-dominio.md)

## Información General del Producto

### Nombre

Calculadora ISA (Atmósfera Estándar Internacional)

### Planteo del Problema

Obtener los parámetros atmosféricos de la Atmósfera Estándar Internacional (temperatura,
presión, densidad, viscosidad) a una altitud dada suele resolverse a mano, con tablas
impresas o planillas sueltas. Eso es lento, propenso a error y no deja ver fácilmente
cuánto difiere un método de cálculo de otro.

La Calculadora ISA es una herramienta personal de ingeniería que, dada una **altitud
geopotencial** en la tropósfera, calcula los parámetros por **dos métodos** (analítico
con fórmulas cerradas y por interpolación de una tabla) y los muestra **lado a lado con
su diferencia/error**. Está pensada para usarse en Windows, Linux y Web, con salida en
unidades SI e imperiales (ambas a la vez).

El valor central no es solo obtener los números rápido, sino **comparar y cuantificar el
error** entre ambos métodos de cálculo.

### Usuarios Objetivo

- **U-01: Usuario técnico / ingeniero (uso personal)**: ingresa una altitud geopotencial
  y consume los parámetros ISA y la comparación entre métodos. No hay roles ni
  autenticación; es un producto mono-usuario.

## Objetivos y Criterios de Éxito

### Objetivos Primarios

1. **G-01: Calcular los parámetros ISA en la tropósfera**: dada una altitud geopotencial
   en `0–36.089 ft` (≈ 0–11.000 m), obtener T, P, ρ, μ (dinámica), ν (cinemática), a
   (velocidad del sonido) y los relativos θ, δ, σ, a/a₀, μ/μ₀.
2. **G-02: Comparar y cuantificar el error entre métodos**: calcular por método analítico
   y por interpolación, y mostrar la diferencia absoluta y el error relativo por magnitud.
3. **G-03: Operar multiplataforma con unidades flexibles**: funcionar en Windows, Linux y
   Web, con salida en SI e imperial (ambas a la vez).

### Criterios de Éxito

| Métrica | Target | Cuándo | Valida |
|---|---|---|---|
| Exactitud del método analítico | Coincide con la tabla ISA de referencia (UTN — `docs/references/`) dentro de tolerancia (valor exacto a fijar en testing) | Al cerrar v1 | G-01 |
| Error de T (interpolación) | ε ≈ 0 (T es lineal en la tropósfera) | Por cálculo | G-02 |
| Error de P/ρ/μ vs. paso | ε disminuye al reducir Δh | Por cálculo | G-02 |
| Targets de empaquetado | Compila/empaqueta para Windows, Linux y Web | Al cerrar v1 | G-03 |

## Contexto

### Decisiones Clave

Promovidas desde el log de decisiones del análisis funcional (con su rationale). Log
completo: [docs/discovery/analisis-funcional.md](../discovery/analisis-funcional.md) (tabla "Decisiones Tomadas").

- **Naturaleza**: herramienta personal, mono-usuario, sin cuentas ni autenticación — uso individual.
- **Rango v1**: solo tropósfera `0–36.089 ft` (≡ 0–11.000 m geopotencial), una capa, gradiente −6.5 K/km, piso en 0 — acota el modelo a una sola capa.
- **Dos métodos**: analítico (fórmulas cerradas) + interpolación lineal — comparar ambos es el objetivo central.
- **Tabla de interpolación**: generada por fórmula en grilla de ft, paso configurable (default 1.000 ft) — aísla el error de interpolación y permite estudiar el efecto del paso.
- **Viscosidad en interpolación**: columna μ precalculada (Sutherland) e interpolada directo — μ tiene su propio error comparable contra el analítico.
- **Magnitudes**: T, P, ρ, μ, ν=μ/ρ, a=√(γRT) + relativos θ, δ, σ, a/a₀, μ/μ₀ — relativos respecto al nivel del mar ISA.
- **Unidades**: resultados en SI **e** imperial **simultáneamente** (sin toggle); los relativos son adimensionales (valor único).
- **Altitud de entrada**: geopotencial; geométrica diferida. La **unidad de la altitud** de entrada (m o ft) es seleccionable; internamente el cálculo y la tabla trabajan en **ft** (unidad canónica, alineada a la tabla de referencia).
- **Referencia del error**: el analítico es el valor "exacto"; error = absoluto + relativo (%).
- **Constantes**: estándar **exacto ISA 1976/ICAO** (R*=8.31432, M₀=0.0289644 → R≈287.05287; T₀=288.15 K, P₀=101325 Pa, L=−6.5 K/km, g₀=9.80665, γ=1.4) + Sutherland (β=1.458e-6, S=110.4 K); cálculo en doble precisión, ρ₀/a₀/μ₀ derivados. La tabla UTN (3 decimales) es cross-check.
- **Tabla de referencia**: tabla ISA en ft (UTN — `docs/references/atmosfera_tipo_internacional_ISA.pdf`) como fuente de validación del método analítico.
- **i18n**: UI en español, un idioma en v1.
- **Arquitectura cliente-servidor**: el cálculo lo realiza una API y el frontend solo muestra; el stack y el empaquetado se definen en el análisis técnico.

### Sistemas Existentes

Ninguno. Producto greenfield, sin integraciones externas ni sistemas a reemplazar.

## Alcance

### Dentro del Alcance (v1)

- Cálculo de punto único: altitud geopotencial → magnitudes.
- Método analítico (fórmulas ISA cerradas) + método por interpolación (tabla generada por fórmula).
- Comparación lado a lado + diferencia/error.
- Magnitudes T, P, ρ, μ, ν, a + relativos θ, δ, σ, a/a₀, μ/μ₀.
- Unidades SI + imperial (mostradas simultáneamente).
- API de cálculo (backend) + frontend multiplataforma (Windows, Linux, Web).
- Altitud eco-devuelta en m y ft (ambas) en cada cálculo.
- Sección de fórmulas de conversión (referencia, estática en el frontend).

### Fuera del Alcance (v1)

- Capas sobre 11 km (tropopausa, estratósfera, etc.) — diferido.
- Altitud geométrica y conversión geopotencial↔geométrica — diferido.
- Atmósfera no estándar (desviación ISA / offset de temperatura).
- Cuentas de usuario / autenticación.
- Exportar / historial de cálculos; modo batch (generación de tabla por rango).
- Relativo ν/ν₀ (v1 incluye μ/μ₀).
- Multi-idioma (solo español).

### Restricciones

- **Arquitectura**: cliente-servidor — el cálculo se realiza en una API; el frontend solo presenta los resultados obtenidos por petición.
- **Conectividad**: requiere alcanzar la API para calcular (no es offline).
- **Plataformas**: el frontend debe distribuirse para Windows, Linux y Web.
- **Seguridad**: sin autenticación en v1; el cálculo no maneja datos sensibles.
- **Tecnología**: el stack concreto (lenguaje de la API, framework del frontend, comunicación, empaquetado) está definido en [docs/discovery/analisis-tecnico.md](../discovery/analisis-tecnico.md).
