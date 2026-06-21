---
name: formulas
surface: app-calculadora
route: "/ (overlay)"
device: desktop
audiences:
  - ingeniero-tecnico
accent_color: "#2563eb"
overlay: true
overlay_type: drawer
triggered_by: calculadora
fidelity:
  visuals: mid
  content: mid
  interactivity: low
version: "1.0"
date: 2026-06-21
---

# Pantalla: Fórmulas de conversión (overlay · drawer)

## Identidad

- **Audiencia primaria:** [ingeniero-tecnico](../../../audiences/ingeniero-tecnico/research-context.md) — verifica de dónde salen los números.
- **JTBD / Propósito:** consultar la fórmula/factor de conversión por magnitud (SI↔imperial y m↔ft) sin abandonar el cálculo en curso. Contenido estático, no calcula (C-04 / F-02).
- **Dispositivo principal:** desktop

## Entrada y salida

**Entradas:**
- Desde [Calculadora] (P-01) · click "Fórmulas de conversión".

**Salidas user-driven:**
- A [Calculadora] (P-01) · click "Cerrar" (vuelve sin perder el cálculo en curso).

**Salidas automáticas:**
- Ninguna.

## Estructura

| # | Nombre | Tipo | Variant/Level/State | Categoría | Visibilidad | Propósito |
|---|--------|------|---------------------|-----------|-------------|-----------|
| 1 | header-formulas | header | — | layout | todos los estados | Título del panel |
| 2 | Intro | paragraph | caption | content | todos los estados | Aclara que es referencia estática |
| 3 | Lista fórmulas | list | — | content | todos los estados | Fórmula/factor por magnitud |
| 4 | Nota relativos | paragraph | caption | content | todos los estados | Relativos = adimensionales |
| 5 | Cerrar | button | secondary | input | todos los estados | Cerrar el drawer |

## Contenido

### header-formulas
- Texto/label: "Fórmulas de conversión"

### Intro
- Texto/label: "Referencia estática · SI ↔ imperial y m ↔ ft. No calcula."

### Lista fórmulas
- Texto/label: "Por magnitud"
- Items:
  - "Altitud — 1 ft = 0,3048 m"
  - "Temperatura — °R = K × 1,8"
  - "Presión — 1 lbf/ft² (psf) = 47,8803 Pa"
  - "Densidad — 1 slug/ft³ = 515,379 kg/m³"
  - "Viscosidad dinámica — 1 slug/(ft·s) = 47,8803 Pa·s"
  - "Viscosidad cinemática — 1 ft²/s = 0,092903 m²/s"
  - "Velocidad del sonido — 1 ft/s = 0,3048 m/s"

### Nota relativos
- Texto/label: "Relativos (θ, δ, σ, a/a₀, μ/μ₀): adimensionales, sin conversión."

### Cerrar
- Texto/label: "Cerrar"
- Icono: x

## Estados

### default
- Aplica: Sí
- Mensaje: —
- Cambios: ninguno (contenido estático único).

### empty
- Aplica: No — siempre tiene contenido (referencia fija).

### loading
- Aplica: No — no hay carga (contenido del frontend, sin API).

### error de validación
- Aplica: No — no hay entrada de datos.

### error de sistema / sin conexión
- Aplica: No — no depende de la API; se muestra siempre.

### success
- Aplica: No.

### not found
- Aplica: No.

### estado terminal / readonly
- Aplica: No (es solo lectura por naturaleza, pero no es un estado conmutado).

## Interacciones

**Eventos:**
- Cerrar · on click → cierra el drawer y vuelve a P-01 con el cálculo intacto

**Validaciones:**
- Ninguna (no hay entrada).

**Feedback:**
- Cerrar → el drawer se oculta; P-01 conserva su estado previo.

## Specs visuales

Pendiente — high-fi.

## Accesibilidad

- **Contraste:** texto en gris oscuro #1e1e1e sobre blanco; sin color salvo el borde del botón "Cerrar" (accent).
- **Orden de foco:** al abrir, foco al header del drawer → Lista → Cerrar.
- **ARIA / labels:** role="dialog" aria-label="Fórmulas de conversión"; icon x="Cerrar fórmulas".
- **Keyboard:** Esc cierra el drawer; foco atrapado dentro del drawer mientras está abierto.

## Decisiones y descartes

**Decisiones tomadas:**
- Drawer (no ruta aparte): consulta puntual sin abandonar el contexto del cálculo (product-map).
- Lista por magnitud con nomenclatura estándar y sobria: la audiencia técnica espera factores explícitos.

**Alternativas descartadas:**
- Ruta/pantalla separada: introduce navegación y "volver" que no aporta a un mono-pantalla.
- Panel persistente lado a lado: se reevaluaría solo si la consulta resulta prolongada (product-map Pregunta 3).

**Preguntas abiertas:**
- ¿Consulta puntual (drawer alcanza) o prolongada/comparada (panel persistente)? — product-map Pregunta 3.
