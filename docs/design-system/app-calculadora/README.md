# Design System — `app-calculadora`

> **Placeholder inicial** — Esta estructura fue generada automáticamente por
> `/product-ux-generate`. Reemplazá el contenido placeholder con las
> definiciones reales del Design System de este surface.
>
> Para iterar este Design System, ejecutá `/product-design-system-update`
> en modo interactivo. El skill preguntará a qué surface aplica el cambio
> (este es uno de ellos).

## Estado actual

- **Surface:** `app-calculadora`
- **Versión:** `0.1.0` (placeholder inicial)
- **Estado:** sin definir — esperando aportes del equipo de diseño

## Estructura

```
docs/design-system/app-calculadora/
├── README.md              ← este archivo
├── CHANGELOG.md           ← historial de cambios + versionado semver (independiente)
├── governance.md          ← cómo proponer cambios al DS de este surface
├── foundations/           ← primitivas visuales
│   ├── color.md
│   ├── typography.md
│   ├── spacing.md
│   ├── grid.md
│   ├── iconography.md
│   ├── motion.md
│   ├── elevation.md
│   └── voice-tone.md
├── tokens/                ← jerarquía de tokens (3 tiers)
│   ├── reference.md       ← primitivas: color.blue.500, space.4
│   ├── semantic.md        ← alias: bg.primary, text.muted
│   └── component.md       ← por componente: button.primary.bg
├── components/            ← catálogo de componentes (spec por archivo)
│   └── (a llenar)
├── patterns/              ← composiciones (forms, empty-states, navigation)
│   └── (a llenar)
└── guidelines/            ← transversal a este surface
    ├── accessibility.md
    ├── i18n.md
    └── content.md
```

## Flujo de trabajo

1. **Definir foundations** (color, typography, spacing) — base obligatoria.
2. **Definir tokens** semánticos y de componente — derivar de foundations.
3. **Documentar components** uno a uno — usar `/product-design-system-update`.
4. **Iterar** — el equipo de diseño puede ejecutar `/product-design-system-update`
   cuantas veces quiera para modificar, agregar o eliminar.

## Versionado (semver, independiente de otros surfaces)

- **MAJOR** (X.0.0): breaking change. Renombrar componente, remover variant,
  cambiar API. Requiere revisar wireframes que pinneen versiones anteriores.
- **MINOR** (0.X.0): agregar componente, agregar variant, agregar foundation.
- **PATCH** (0.0.X): corrección, ajuste de spec, microcopy en guidelines.

Cambios deprecados se marcan `deprecated: true` con migration path antes de
removerse en el siguiente MAJOR.

Otros surfaces del producto pueden tener versiones distintas. Cada surface
es soberano de su propio DS.
