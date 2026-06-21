---
name: paso-tabla
surface: app-calculadora
route: "/ (overlay)"
device: desktop
audiences:
  - ingeniero-tecnico
accent_color: "#2563eb"
overlay: true
overlay_type: popover
triggered_by: calculadora
fidelity:
  visuals: mid
  content: mid
  interactivity: low
version: "1.0"
date: 2026-06-21
---

# Pantalla: Paso de tabla (overlay · popover)

> **Alcance:** llega con **FG-3** (método por interpolación). Se inventaria ahora para no rediseñar P-01 cuando llegue.

## Identidad

- **Audiencia primaria:** [ingeniero-tecnico](../../../audiences/ingeniero-tecnico/research-context.md) — estudia cómo cambia el error de interpolación según el muestreo.
- **JTBD / Propósito:** ajustar `tableStep` y disparar el recálculo del método de interpolación, para observar cómo baja el error al reducir Δh (C-02).
- **Dispositivo principal:** desktop

## Entrada y salida

**Entradas:**
- Desde [Calculadora] (P-01) · click "Paso de tabla: 1.000 ft".

**Salidas user-driven:**
- A [Calculadora] (P-01) · click "Aplicar y recalcular" (recalcula la interpolación).

**Salidas automáticas:**
- Ninguna.

## Estructura

| # | Nombre | Tipo | Variant/Level/State | Categoría | Visibilidad | Propósito |
|---|--------|------|---------------------|-----------|-------------|-----------|
| 1 | header-paso | header | — | layout | todos los estados | Título del popover |
| 2 | Campo paso | text-input | default | input | todos (state_overrides: error de validación→error) | Ingreso del paso de tabla |
| 3 | Nota paso | paragraph | caption | content | todos los estados | Efecto del paso sobre el error |
| 4 | Aplicar | button | primary | input | todos los estados | Aplicar y recalcular interpolación |

## Contenido

### header-paso
- Texto/label: "Paso de la tabla"

### Campo paso
- Texto/label: "Paso (en la unidad activa)"
- Annotation: "default 1.000 ft · > 0 y ≤ 36.089 ft"

### Nota paso
- Texto/label: "Afecta solo al método de interpolación. Reducir el paso reduce el error de interpolación."

### Aplicar
- Texto/label: "Aplicar y recalcular"
- Icono: refresh

## Estados

### default
- Aplica: Sí
- Mensaje: —
- Cambios: ninguno (estado base del popover).

### error de validación
- Aplica: Sí
- Mensaje: "Paso inválido: debe ser > 0 y ≤ 36.089 ft."
- Cambios:
  - Campo paso: state=error, error_msg="Paso inválido (> 0 y ≤ 36.089 ft)" (state_override) — corresponde a `invalidStep`

### empty
- Aplica: No — el campo arranca con el default 1.000 ft.

### loading
- Aplica: No — el recálculo se refleja en P-01, no en el popover.

### error de sistema / sin conexión
- Aplica: No — el fallo de red se muestra en P-01 (Alerta sistema), no acá.

### success
- Aplica: No — el éxito se manifiesta en P-01 (comparación actualizada).

### not found
- Aplica: No.

### estado terminal / readonly
- Aplica: No.

## Interacciones

**Eventos:**
- Aplicar · on click → `POST /v1/calculate` con el nuevo paso; cierra el popover y actualiza la comparación en P-01

**Validaciones:**
- Campo paso · si ≤ 0, no numérico o > 36.089 ft → mensaje "Paso inválido (> 0 y ≤ 36.089 ft)" (`invalidStep`)

**Feedback:**
- Paso válido → P-01 recalcula la interpolación y actualiza Δ / error %
- Paso inválido → estado error de validación inline en el popover; conserva el último resultado válido en P-01

## Specs visuales

Pendiente — high-fi.

## Accesibilidad

- **Contraste:** botón "Aplicar" primary con accent #2563eb cumple AA; mensaje de error en rojo con texto ≥4.5:1.
- **Orden de foco:** al abrir, foco a Campo paso → Aplicar.
- **ARIA / labels:** role="dialog" aria-label="Paso de la tabla"; icon refresh="Recalcular".
- **Keyboard:** Enter aplica; Esc cierra sin cambiar el paso.

## Decisiones y descartes

**Decisiones tomadas:**
- Popover anclado al control de paso: el ajuste es secundario y exploratorio (se toca pocas veces).
- Default 1.000 ft a la vista: alinea con el default del PRD y evita estado vacío.

**Alternativas descartadas:**
- Campo inline permanente en P-01: compite con la entrada principal (product-map Pregunta 1).
- Pantalla aparte: desproporcionado para un único parámetro.

**Preguntas abiertas:**
- ¿Inline en la entrada o popover bajo demanda? — product-map Pregunta 1.
