---
foundation: grid
version: 0.1.0
last_updated: 2026-06-21
status: placeholder
---

# Grid

> **Placeholder inicial** — Definir según breakpoints reales del producto.

## Propósito

Sistema de grilla y breakpoints para layout responsive. Define columnas,
gutters y safe areas en cada breakpoint.

## Breakpoints (placeholder)

| Token | Min width | Columnas | Gutter | Margen |
|-------|-----------|----------|--------|--------|
| `bp.xs` | 0 | 4 | 16px | 16px |
| `bp.sm` | 640px | 8 | 16px | 24px |
| `bp.md` | 768px | 12 | 24px | 32px |
| `bp.lg` | 1024px | 12 | 24px | 48px |
| `bp.xl` | 1280px | 12 | 32px | 64px |

## Guidelines

**Do:**
- Diseñar mobile-first y escalar.
- Usar la grilla del breakpoint actual para alinear contenido.

**Don't:**
- No mezclar grillas (4 col mobile + 12 col desktop como capas independientes).
- No fixed widths sin breakpoint declarado.

## Accesibilidad

- Contenido debe ser usable a 200% de zoom sin scroll horizontal.
- En mobile, evitar columnas de texto demasiado angostas (<320px).

## Historial

- 2026-06-21 v0.1.0 — Placeholder inicial.
