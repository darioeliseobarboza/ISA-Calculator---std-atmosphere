---
name: calculadora
surface: app-calculadora
route: /
device: desktop
audiences:
  - ingeniero-tecnico
accent_color: "#2563eb"
fidelity:
  visuals: mid
  content: mid
  interactivity: low
version: "1.0"
date: 2026-06-21
---

# Pantalla: Calculadora

## Identidad

- **Audiencia primaria:** [ingeniero-tecnico](../../../audiences/ingeniero-tecnico/research-context.md) — ingresa una altitud, lee los parámetros ISA en SI e imperial y (FG-3) contrasta analítico vs. interpolación.
- **JTBD / Propósito:** obtener los parámetros atmosféricos ISA de una altitud sin calcularlos a mano, leyendo SI e imperial a la vez, en un único ciclo entrada→cálculo→lectura.
- **Dispositivo principal:** desktop

## Entrada y salida

**Entradas:**
- Desde fuera (abrir la app — es la pantalla raíz).

**Salidas user-driven:**
- A [Fórmulas de conversión] (O-01) · click "Fórmulas de conversión".
- A [Paso de tabla] (O-02) · **FG-3** — en FG-2 el control está deshabilitado y no abre el overlay.

**Salidas automáticas:**
- Ninguna (calcular cambia de estado dentro de la misma pantalla, no navega).

## Estructura

| # | Nombre | Tipo | Variant/Level/State | Categoría | Visibilidad | Propósito |
|---|--------|------|---------------------|-----------|-------------|-----------|
| 1 | header | header | — | layout | todos los estados | Identidad del producto |
| 2 | Campo altitud | text-input | default | input | todos (state_overrides: error de validación→error) | Ingreso de la altitud geopotencial |
| 3 | Selector unidad | dropdown | closed | input | todos los estados | Unidad de la altitud (m/ft) |
| 4 | Control paso de tabla | button | disabled | input | todos los estados | Deshabilitado en FG-2 — el paso aplica solo al método de interpolación (FG-3) |
| 5 | Botón calcular | button | primary | input | todos (state_overrides: loading→disabled) | Disparar el cálculo |
| 6 | Botón fórmulas | button | tertiary | input | todos los estados | Abrir el drawer de fórmulas |
| 7 | Loader resultados | loader | — | feedback | visible_only_in_states: loading | Indicar cálculo en curso |
| 8 | Resultados vacíos | empty-state | — | feedback | visible_only_in_states: empty | Guía inicial sin datos |
| 9 | Alerta validación | alert | error | feedback | visible_only_in_states: error de validación | Aviso de entrada inválida / fuera de rango |
| 10 | Alerta sistema | alert | error | feedback | visible_only_in_states: error de sistema | Aviso de fallo de conexión |
| 11 | Tabla de resultados | list | — | content | hidden_in_states: empty, loading, error de validación, error de sistema | Magnitudes en SI e imperial |
| 12 | Relativos | section | — | content | hidden_in_states: empty, loading, error de validación, error de sistema | Adimensionales θ/δ/σ/(a/a₀)/(μ/μ₀) |
| 13 | Altitud eco | badge | — | content | hidden_in_states: empty, loading, error de validación, error de sistema | Altitud de entrada en m y ft |
| 14 | footer | footer | — | layout | todos los estados | Nota de cálculo/precisión |

## Contenido

### header
- Texto/label: "Calculadora ISA · Atmósfera Estándar"

### Campo altitud
- Texto/label: "Altitud geopotencial"
- Annotation: "numérico; se normaliza a ft y se valida 0–36.089 ft"

### Selector unidad
- Texto/label: "Unidad: ft"
- Annotation: "opciones m / ft · default ft"

### Control paso de tabla
- Texto/label: "Paso de tabla — disponible en FG-3"
- Icono: settings
- Annotation: "FG-2: deshabilitado (el paso solo aplica al método de interpolación, FG-3)"

### Botón calcular
- Texto/label: "Calcular"
- Icono: arrow-right

### Botón fórmulas
- Texto/label: "Fórmulas de conversión"
- Icono: file

### Loader resultados
- Texto/label: "Calculando parámetros…"

### Resultados vacíos
- Texto/label: "Ingresá una altitud y calculá para ver los parámetros ISA."

### Alerta validación
- Texto/label: "Altitud fuera de rango: el modelo cubre 0–36.089 ft (≈ 0–11.000 m). Corregí el valor."

### Alerta sistema
- Texto/label: "No se pudo conectar con la API. Tu entrada se conservó — reintentá."

### Tabla de resultados
- Texto/label: "Resultados por magnitud (SI / imperial)"
- Items:
  - "Temperatura (T) — 255,65 K · 460,17 °R"
  - "Presión (P) — 5,4020·10⁴ Pa · 1.128,1 lbf/ft²"
  - "Densidad (ρ) — 0,73643 kg/m³ · 1,4290·10⁻³ slug/ft³"
  - "Viscosidad dinámica (μ) — 1,6286·10⁻⁵ Pa·s · 3,401·10⁻⁷ slug/(ft·s)"
  - "Viscosidad cinemática (ν) — 2,2117·10⁻⁵ m²/s · 2,381·10⁻⁴ ft²/s"
  - "Velocidad del sonido (a) — 320,55 m/s · 1.051,7 ft/s"
- Annotation: "FG-2: solo Analítico. FG-3 agrega columnas Interpolación · Δ · error %"

### Relativos
- Texto/label: "Relativos (adimensionales): θ=0,88720 · δ=0,53314 · σ=0,60106 · a/a₀=0,94192 · μ/μ₀=0,91015"

### Altitud eco
- Texto/label: "Altitud: 5.000 m · 16.404 ft"

### footer
- Texto/label: "El cálculo lo hace la API · valores en SI e imperial · 5 cifras significativas"

## Estados

### default
- Aplica: Sí
- Mensaje: —
- Cambios: muestra Tabla de resultados + Relativos + Altitud eco (resultado de un cálculo). Loader, empty-state y alertas ocultos.

### empty
- Aplica: Sí
- Mensaje: "Ingresá una altitud y calculá para ver los parámetros ISA."
- Cambios:
  - Resultados vacíos: visible (empty-state)
  - Tabla de resultados / Relativos / Altitud eco: ocultos

### loading
- Aplica: Sí
- Mensaje: "Calculando parámetros…"
- Cambios:
  - Loader resultados: visible
  - Botón calcular: variant=disabled, content="Calculando…" (state_override)
  - Tabla de resultados / Relativos / Altitud eco: ocultos

### error de validación
- Aplica: Sí
- Mensaje: "Altitud fuera de rango: el modelo cubre 0–36.089 ft (≈ 0–11.000 m). Corregí el valor."
- Cambios:
  - Campo altitud: state=error, error_msg="Fuera de rango (0–36.089 ft)" (state_override)
  - Alerta validación: visible
  - Tabla de resultados / Relativos / Altitud eco: ocultos

### error de sistema / sin conexión
- Aplica: Sí
- Mensaje: "No se pudo conectar con la API. Tu entrada se conservó — reintentá."
- Cambios:
  - Alerta sistema: visible
  - Tabla de resultados / Relativos / Altitud eco: ocultos
  - Campo altitud / Selector unidad: conservan lo ingresado

### success
- Aplica: No — el éxito se manifiesta como el render del resultado (estado default).

### not found
- Aplica: No — no hay recurso por ID.

### estado terminal / readonly
- Aplica: No — la pantalla nunca es readonly.

## Interacciones

**Eventos:**
- Botón calcular · on click / Enter → `POST /v1/calculate`; default→loading→(default | error)
- Botón fórmulas · on click → abre drawer O-01 (Fórmulas de conversión)
- Control paso de tabla · deshabilitado en FG-2 → no abre O-02 (se habilita en FG-3)
- Selector unidad · on change → cambia la unidad de la altitud de entrada

**Validaciones:**
- Campo altitud · si no es numérico → mensaje "Ingresá un número" (`invalidInput`)
- Campo altitud · si fuera de 0–36.089 ft → mensaje "Fuera de rango (0–36.089 ft)" (`outOfRange`)

**Feedback:**
- Cálculo OK → estado default con la tabla de magnitudes en doble unidad + altitud eco {m, ft}
- Cálculo inválido → estado error de validación inline (sin resultados)
- Fallo de red → estado error de sistema (entrada conservada, opción de reintentar)

## Specs visuales

Pendiente — high-fi.

## Accesibilidad

- **Contraste:** accent #2563eb sobre blanco cumple AA (4.5:1) para texto ≥18pt; los valores numéricos van en gris oscuro #1e1e1e.
- **Orden de foco:** Campo altitud → Selector unidad → Control paso → Botón calcular → Botón fórmulas → (resultados).
- **ARIA / labels:** icon settings="Ajustar paso de tabla", icon file="Abrir fórmulas de conversión". La tabla de resultados se anuncia por filas (magnitud + valor SI + valor imperial).
- **Keyboard:** Enter en el campo altitud dispara el cálculo.

## Decisiones y descartes

**Decisiones tomadas:**
- Una sola pantalla entrada+resultados: el JTBD primario es un ciclo entrada→cálculo→lectura sin saltos (product-map P-01).
- Doble unidad por fila en la tabla: NFR-U03 exige ver SI e imperial a la vez (sin toggle).
- Paso de tabla como control que abre overlay: es secundario/exploratorio (FG-3), no debe competir con la entrada principal.
- **Recorte FG-2 (REQ-002):** el bloque de resultados muestra **solo el método analítico** (sin columnas Interpolación / Δ / error %) y el **control de paso queda deshabilitado**. La comparación analítico/interpolación y el ajuste del paso se habilitan en FG-3. El layout de la pantalla no cambia entre FG-2 y FG-3 (se evita rediseño).

**Alternativas descartadas:**
- Toggle SI/imperial: descartado (anti-patrón detectado en benchmark; el usuario quiere ambos a la vez).
- Pantallas separadas de entrada y de resultados: agrega navegación innecesaria en un producto mono-pantalla.

**Preguntas abiertas:**
- Jerarquía visual SI vs. imperial (igual o imperial atenuado) — product-map Pregunta 4.
- Comparación siempre visible vs. conmutable "solo analítico / comparación" — product-map Pregunta 2.
