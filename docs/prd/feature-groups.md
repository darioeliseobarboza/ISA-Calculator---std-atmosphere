---
created: 2026-06-12
last_updated: 2026-06-12
status: "Pending Formalization"
---

# PRD — Feature Groups — Calculadora ISA (Atmósfera Estándar)

> Derivado del discovery: [análisis funcional](../discovery/analisis-funcional.md) · [análisis técnico](../discovery/analisis-tecnico.md)

## Overview

Este documento contiene los feature groups identificados durante la inicialización del
producto **Calculadora ISA**.

**Feature groups son agrupaciones de funcionalidad relacionada** que deben ser capturadas
como requests, diseñadas técnicamente y formalizadas en stories antes de iniciar
implementación.

**Proceso para formalizar cada feature group:**
1. `/product-new-request` — Capturar requerimiento y clarificar alcance
2. `/product-design-request REQ-XXX` — Diseñar solución técnica y proponer story split
3. `/product-create-stories REQ-XXX` — Crear stories implementables

**Status actual:** 3 feature groups pendientes de formalización.

---

## Feature Group 1: Esqueleto / Walking Skeleton

**Status:** Pending

**Descripción:**
Infraestructura mínima y "sistema vivo" end-to-end, sin features de negocio. Se crean
las dos bases de código —`atmosphere-api` (Go + `net/http`, stateless) y `atmosphere-app`
(Flutter + Riverpod + `http`)— con un endpoint trivial `GET /health` en la API y una
pantalla en el frontend que lo consume y muestra el estado. Se configura **CORS** (para el
target Web) y el **empaquetado** de los tres targets: Dockerfile para Web y documentación
de build de escritorio (Windows/Linux).

Es foundational: prueba que el frontend (en los tres targets) alcanza la API y obtiene
respuesta, estableciendo el camino cliente-servidor sobre el que se construye todo lo demás.

**Por qué es importante?:**
- Es la base técnica de todos los demás feature groups.
- Valida temprano el camino cliente-servidor y el empaquetado multiplataforma (lo más riesgoso del producto).
- Establece la estructura de los repos y el patrón de build/despliegue.

**Capabilities que implementa:**
- Ninguna capability de negocio (infraestructura + `GET /health`).
- Habilita NFR-PL01 (3 targets), NFR-PL02 (conectividad) y NFR-S02 (CORS).

**Precondiciones:**
- Ninguna (es el primer feature group).

**Postcondiciones:**
- `atmosphere-api` corriendo con `GET /health`.
- `atmosphere-app` compila y corre en Windows, Linux y Web, y consume `/health`.
- CORS configurado; Dockerfile (web) y documentación de build (desktop) disponibles.

**Valor entregado:**
- El sistema está "vivo" end-to-end: el frontend, en cualquiera de los tres targets, llega a la API y muestra que responde.

---

## Feature Group 2: Cálculo analítico + presentación

**Status:** Pending

**Descripción:**
Primer valor real del producto. Se implementa el **motor analítico** de la tropósfera en
`atmosphere-api`: capa `AtmosphericLayer` (tropósfera), constantes exactas ISA 1976 (con
R, ρ₀, a₀, μ₀ y el exponente derivados en runtime, float64), fórmulas de T, P, ρ, Sutherland
(μ) y derivados (ν, a) y los relativos (θ, δ, σ, a/a₀, μ/μ₀). Se expone `POST /v1/calculate`
(solo método analítico en esta etapa) que normaliza la entrada a **ft**, valida `0–36.089 ft`,
y devuelve cada magnitud absoluta en **SI e imperial** + la altitud eco en `{m, ft}`.

En `atmosphere-app`: pantalla de entrada (altitud + `altitudeUnit` m/ft), manejo de
errores de validación, y presentación de resultados en doble unidad con formato/precisión
(`intl`, 5 cifras significativas). Incluye la **sección de fórmulas de conversión** (F-02,
contenido estático).

**Por qué es importante?:**
- Entrega el cálculo de los parámetros ISA por el método de referencia (analítico), que es el ground-truth del producto.
- Deja al usuario una herramienta ya útil aunque todavía no exista la comparación.

**Capabilities que implementa:**
- C-01 (parte analítica): cálculo ISA por método analítico (from F-01).
- C-03: validación de la entrada (from F-01).
- C-04: ver fórmulas de conversión (from F-02).
- NFR-U01/U02/U03 (idioma, precisión, doble unidad), NFR-Q01 (exactitud vs. tabla UTN), NFR-P01.

**Precondiciones:**
- FG-1 completo (servicios, build multiplataforma, CORS, camino cliente-servidor).

**Postcondiciones:**
- `POST /v1/calculate` calcula por método analítico y responde en SI e imperial + altitud `{m,ft}`.
- Validación de rango (`0–36.089 ft`) con errores `outOfRange` / `invalidInput`.
- Frontend con pantalla de cálculo (un método) y sección de fórmulas de conversión.

**Valor entregado:**
- El usuario ingresa una altitud (en m o ft) y obtiene T, P, ρ, μ, ν, a y los relativos en SI e imperial.
- El usuario consulta las fórmulas/factores de conversión por magnitud.

---

## Feature Group 3: Interpolación + comparación

**Status:** Pending

**Descripción:**
Completa el objetivo central del producto. En `atmosphere-api` se agrega el **método por
interpolación**: generación de la `ISATable` (grilla en ft, paso configurable, nodos
calculados por las mismas fórmulas analíticas), interpolación lineal de las columnas y
derivación de ν y a; y el cálculo de la **`Comparison`** (diferencia absoluta y
`relativeErrorPct` por magnitud, con el analítico como referencia). `POST /v1/calculate`
pasa a devolver **ambos métodos** + la comparación + metadata de la tabla.

En `atmosphere-app`: vista de **comparación lado a lado** (analítico vs. interpolación con
su Δ y error %) y control para configurar el **paso** de la tabla.

**Por qué es importante?:**
- Es la razón de ser del producto: comparar los dos métodos y cuantificar el error de interpolación.
- Permite estudiar cómo el paso de la tabla afecta el error.

**Capabilities que implementa:**
- C-01 (interpolación + comparación): completa el cálculo por ambos métodos (from F-01).
- C-02: configurar el paso de la tabla (from F-01).
- NFR-P02 (regeneración de tabla).

**Precondiciones:**
- FG-2 completo (motor analítico, endpoint, conversión de unidades, presentación de un método).

**Postcondiciones:**
- `POST /v1/calculate` devuelve analítico + interpolación + `comparison` + `table`.
- Frontend muestra ambos métodos lado a lado con diferencia/error y permite ajustar el paso.

**Valor entregado:**
- El usuario ve los dos métodos en paralelo con su diferencia/error y ajusta el paso de la tabla para estudiar su efecto.

---

## Sequencing Notes

**Feature Group 1 (Esqueleto)** debe completarse primero: sin las dos bases de código, el
build multiplataforma y el camino cliente-servidor (CORS incluido), no se puede construir
ningún feature de negocio.

**Feature Group 2 (Analítico + presentación)** depende de FG-1 y entrega el primer valor:
el motor analítico es el ground-truth, así que va antes que la interpolación. La sección de
fórmulas se incluye acá por afinidad con la presentación en doble unidad (y porque sola
sería un grupo demasiado chico).

**Feature Group 3 (Interpolación + comparación)** depende de FG-2: la interpolación y la
comparación necesitan el motor analítico como referencia del error. Cierra el objetivo
central del producto.
