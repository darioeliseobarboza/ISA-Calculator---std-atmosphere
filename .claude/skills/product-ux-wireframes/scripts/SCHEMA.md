# `screens.json` Schema (mid-fi)

Canonical input format for `build_wireframes.py`. The agent (Claude) produces this JSON by reading the human-readable `screens/*.md` files plus `user-flows.md`. The script does NOT parse markdown — it only validates and renders this JSON.

Mid-fi extensions over low-fi:
- Surface-level `accent_color` and `grid_baseline`
- Block-level `variant` (button: primary/secondary/...), `state` (input/dropdown), `level` (heading/paragraph), `kind` (alert), `icon`, `value`, `error_msg`, `aspect_ratio`, `items`, `options`, `annotation`
- Real content (microcopy, headings, error messages) in `content` and dedicated fields

## File location

The JSON is **temporary**, written by the agent to a path under `/tmp/`:

```
/tmp/wireframes-{surface}-{timestamp}.json
```

It is NOT versioned, NOT placed under `docs/`, and NOT preserved after the build.

## Top-level structure

```json
{
  "surface": "string",
  "device": "mobile" | "desktop" | "tablet",
  "accent_color": "#2563eb",
  "grid_baseline": 8,
  "screens": [ ... ],
  "transitions": [ ... ]
}
```

| Key | Required | Type | Description |
|-----|----------|------|-------------|
| `surface` | Yes | string | Surface name (matches the surface folder under `docs/ux/surfaces/`) |
| `device` | Yes | enum | Primary device — drives frame size (mobile=400×800, desktop=1200×800) |
| `accent_color` | No | string | Hex color used for primary buttons, focused inputs, active tabs, links. Default `#2563eb` |
| `grid_baseline` | No | int | Pixel baseline for grid alignment (informational; default `8`) |
| `screens` | Yes | array | Non-empty list of screen objects, in display order (first one = top row) |
| `transitions` | No | array | List of transitions between screens. Empty/omitted = no arrows |

## Screen object

```json
{
  "name": "kebab-case-id",
  "displayName": "Human-readable name",
  "audiences": ["audience-1", "audience-2"],
  "overlay": false,
  "overlay_type": "drawer",
  "triggered_by": "parent-screen-name",
  "blocks": [ ... ],
  "states": [ ... ]
}
```

| Key | Required | Type | Description |
|-----|----------|------|-------------|
| `name` | Yes | string | Internal id, used to reference in transitions. Kebab-case |
| `displayName` | Yes | string | Shown as the row label and frame name |
| `audiences` | No | array | Audience names (informative) |
| `overlay` | No | boolean | `true` if this is an overlay (drawer, bottom-sheet, modal, popover) rather than a full-screen route. Default `false` |
| `overlay_type` | No | string | `drawer` · `bottom-sheet` · `modal` · `popover`. Required when `overlay: true` (informative — affects label in canvas) |
| `triggered_by` | No | string | `name` of the parent screen that opens this overlay. Used by the layout engine to position the overlay frame near the parent |
| `blocks` | Yes | array | Ordered list of block objects (top-to-bottom in the wireframe) |
| `states` | Yes | array | Non-empty list of state objects |

## Block object

```json
{
  "name": "Block label (internal id)",
  "type": "button",
  "category": "input",
  "content": "Confirmar equipo",
  "variant": "primary",
  "icon": "check",
  "annotation": "click → confirma + redirect"
}
```

### Common keys

| Key | Required | Type | Description |
|-----|----------|------|-------------|
| `name` | Yes | string | Internal label (used as id and fallback content) |
| `type` | Yes | string | One of the 36 dictionary types |
| `category` | No | string | layout / navigation / content / input / feedback (informative) |
| `content` | No | string | Real text rendered on the block (microcopy, label, heading) — defaults to `name` |
| `icon` | No | string | Icon name from the Unicode map (search, check, menu, arrow-right, etc.). Falls back to `[name]` text if unknown |
| `annotation` | No | string | Inline note rendered in small gray text below the block (e.g., "polling 30s", "valida >8 chars") |
| `hidden_in_states` | No | string[] | State names in which this block is NOT rendered. Case-insensitive match. Backward-compatible — omitting this field renders the block in all states (original behavior). Example: `["default", "loading"]` |
| `visible_only_in_states` | No | string[] | Inverse of `hidden_in_states`. Block is rendered ONLY in the listed states. Mutually exclusive with `hidden_in_states` (use one or the other). Example: `["error de validación", "error de sistema"]` |
| `state_overrides` | No | object | Map of state name → field overrides applied on top of the base block before rendering. Any block field can be overridden (content, variant, kind, icon, annotation, etc.). Overrides are applied case-sensitively first, then with lowercase fallback. Example: `{"loading": {"variant": "disabled", "content": "Guardando…"}}` |

### Type-specific keys

**`button`**
- `variant`: `primary` (filled accent) · `secondary` (outline) · `tertiary` (link-style) · `disabled` (gray) · `error` (red). Default `primary`.

**`text-input`**
- `state`: `default` · `focused` (accent border) · `error` (red border + msg) · `disabled`. Default `default`.
- `value`: real input text (rendered instead of placeholder)
- `error_msg`: error message rendered below the input (visible only when `state: error`)

**`heading`**
- `level`: `h1` (28px) · `h2` (22px, default) · `h3` (18px)

**`paragraph`**
- `level`: `body` (default) · `caption` (smaller, gray)
- `lines`: number of placeholder lines (used only when `content` is empty)

**`alert`**
- `kind`: `error` (red) · `warning` (orange) · `info` (blue) · `success` (green). Default `error`. Auto-icon by kind unless `icon` provided.

**`image`**
- `aspect_ratio`: e.g., `4:3`, `16:9`. Rendered as text inside the placeholder
- `h`: explicit height in px (default 200)

**`list`**
- `items`: list of `{title, subtitle, icon}` for real items. If absent, falls back to `items_count`.
- `items_count`: fallback count (default 3)

**`dropdown`**
- `state`: `closed` (default) · `open` (renders options below)
- `options`: list of strings shown when `state: open` (max 6)

**`tabs`**
- `labels`: list of tab labels (or pipe-separated in `content`)
- `active`: index of active tab (default 0)

**`nav-bar`**
- `labels`: list of nav items

**`section`**
- `h`: explicit height (default 50)

**`card`**, **`badge`**, **`progress-bar`**, **`avatar`**, **`toggle`**, **`checkbox`**, **`radio`** — see SKILL.md for behavior.

### Block types (dictionary)
- Layout: `header`, `footer`, `sidebar`, `main`, `modal`, `section`
- Navigation: `nav-bar`, `tabs`, `link`, `breadcrumbs`, `pagination`
- Content: `heading`, `paragraph`, `image`, `icon`, `list`, `card`, `table`, `avatar`, `badge`, `chart`
- Input: `text-input`, `button`, `dropdown`, `checkbox`, `radio`, `toggle`, `search-bar`, `slider`, `date-picker`
- Feedback: `alert`, `toast`, `progress-bar`, `tooltip`, `empty-state`, `loader`

## State object

```json
{
  "name": "default",
  "applies": true
}
```

| Key | Required | Type | Description |
|-----|----------|------|-------------|
| `name` | Yes | string | Lowercase. One of: `default`, `empty`, `loading`, `error de validación`, `error de sistema`, `success`, `not found`, `terminal`, `readonly`, `permiso denegado` |
| `applies` | Yes | boolean | If `false`, the state is not rendered (no frame). If `true`, a frame is generated |

States are rendered **in this order**: `default` first (column 0), then the rest as declared.

## Transition object

```json
{
  "src": "screen-name-id",
  "srcState": "default",
  "srcBlock": "Block name in src.blocks[]",
  "dst": "screen-name-id",
  "trigger": "click 'Confirm'",
  "automatic": false
}
```

| Key | Required | Type | Description |
|-----|----------|------|-------------|
| `src` | Yes | string | Source screen `name` (must match a screen's `name`) |
| `srcState` | No | string | Source state name. Default `"default"`. Use other state names when the trigger lives in a non-default state |
| `srcBlock` | No | string | Block `name` within `src.blocks[]` that triggers the transition. Used by the agent to know which block to anchor the arrow to |
| `dst` | Yes | string | Destination screen `name` (must match a screen's `name`) |
| `trigger` | No | string | Short label (4-6 words, ~25 chars). Used by the agent as the label text |
| `automatic` | No | boolean | If `true`, arrow is dashed (auto transition). Default `false` (solid, user-driven) |

**IMPORTANT**: `transitions` is metadata only. The script `build_wireframes.py` does NOT render arrows from this list. Arrows are produced in a second step:

1. `build_wireframes.py` emits a `coords.json` containing all frame/block positions and the `transitions` list.
2. The agent reads `coords.json`, decides individual coordinates per transition (anchoring to specific blocks, avoiding collisions, picking trigger label widths), and writes an `arrows.json` (see `arrows.json` schema below).
3. `add_arrows.py` reads the `arrows.json` and appends elements to the existing `.excalidraw`.

This separation lets the agent take per-transition decisions that the script cannot generalize (anti-collision, label truncation, prioritization).

## Complete example

```json
{
  "surface": "web-11",
  "device": "mobile",
  "accent_color": "#2563eb",
  "grid_baseline": 8,
  "screens": [
    {
      "name": "home",
      "displayName": "Home",
      "audiences": ["fan-casual-share"],
      "blocks": [
        {"name": "header", "type": "header", "icon": "menu", "content": "11"},
        {"name": "Hero heading", "type": "heading", "level": "h1", "content": "Armá tu 11 ideal"},
        {"name": "Hero subtitle", "type": "paragraph", "level": "caption", "content": "Sin registro · 5 minutos · listo para compartir"},
        {"name": "Hero image", "type": "image", "aspect_ratio": "16:9", "content": "Card de ejemplo"},
        {"name": "CTA primario", "type": "button", "variant": "primary", "icon": "arrow-right", "content": "Armá tu 11"},
        {"name": "CTA secundario", "type": "button", "variant": "secondary", "content": "Crear sala draft"},
        {"name": "Campo código", "type": "text-input", "icon": "search", "content": "Tenés un código? ingresalo", "annotation": "valida 6 chars alfanuméricos"},
        {"name": "Link feed", "type": "link", "icon": "arrow-right", "content": "Ver feed"},
        {"name": "indicador-offline", "type": "alert", "kind": "warning", "content": "Sin conexión · Los cambios se guardan localmente", "visible_only_in_states": ["error de sistema"]}
      ],
      "states": [
        {"name": "default", "applies": true},
        {"name": "loading", "applies": true},
        {"name": "error de sistema", "applies": true}
      ]
    },
    {
      "name": "armar",
      "displayName": "Armar",
      "audiences": ["fan-casual-share"],
      "blocks": [
        {"name": "header", "type": "header", "icon": "arrow-left", "content": "Volver"},
        {"name": "Cancha", "type": "image", "aspect_ratio": "1:1", "content": "Cancha + 11 puestos clickables", "h": 380, "annotation": "tap puesto → abre selector en sheet"},
        {"name": "Formación", "type": "section", "content": "Formación · 4-3-3"},
        {"name": "Botón Confirmar", "type": "button", "variant": "primary", "icon": "check", "content": "Confirmar equipo",
          "state_overrides": {"loading": {"variant": "disabled", "content": "Guardando…"}, "error de validación": {"variant": "error"}}}
      ],
      "states": [
        {"name": "default", "applies": true},
        {"name": "empty", "applies": true},
        {"name": "loading", "applies": true},
        {"name": "error de validación", "applies": true},
        {"name": "permiso denegado", "applies": false}
      ]
    }
  ],
  "transitions": [
    {"src": "home", "srcBlock": "CTA primario", "dst": "armar", "trigger": "click 'Armá tu 11'", "automatic": false},
    {"src": "armar", "srcBlock": "Botón Confirmar", "dst": "pagina-publica", "trigger": "post-confirmación", "automatic": true},
    {"src": "home", "srcBlock": "Botón menú", "dst": "menu-navegacion", "trigger": "abre menú", "automatic": false}
  ]
}
```

### Overlay example

An overlay is a screen object with `"overlay": true`. It is rendered in a separate section below the main grid, not as a row in it.

```json
{
  "name": "menu-navegacion",
  "displayName": "Menú de navegación",
  "overlay": true,
  "overlay_type": "drawer",
  "triggered_by": "home",
  "blocks": [
    {"name": "header-menu", "type": "header", "content": "Menú"},
    {"name": "item-perfil", "type": "link", "icon": "user", "content": "Perfil y Vehículos"},
    {"name": "item-mantenimiento", "type": "link", "icon": "settings", "content": "Mantenimiento"},
    {"name": "item-notificaciones", "type": "link", "icon": "bell", "content": "Notificaciones",
      "annotation": "badge con contador de no leídas"}
  ],
  "states": [
    {"name": "default", "applies": true}
  ]
}
```

## Validation errors

The script fails with `[build_wireframes] ERROR: ...` and exit code 1 on:

- Missing required top-level key (`surface`, `device`, `screens`)
- `device` not in `mobile`/`desktop`/`tablet`
- `screens` empty
- Screen missing `name`, `displayName`, `blocks`, or `states`
- `states` empty
- Block missing `name` or `type`
- State `applies` not boolean

Unknown block types do **not** fail — they render as `[type] {name}` so the issue is visible without breaking the build.

---

# `coords.json` Schema

**Output** of `build_wireframes.py`. Emitted alongside the `.excalidraw` so the agent can decide where to draw arrows.

```json
{
  "surface": "web-11",
  "device": "mobile",
  "accent_color": "#2563eb",
  "grid_baseline": 8,
  "frame_w": 400,
  "frame_h": 800,
  "gutter_x": 140,
  "gutter_y": 120,
  "row_start_y": 0,
  "col_start_x": 0,
  "screen_numbers": {"home": 1, "armar": 2, ...},
  "display_names": {"home": "Home", "armar": "Armar", ...},
  "frames": {
    "home__default": {
      "screen": "home",
      "state": "default",
      "x": 0, "y": 4600, "width": 400, "height": 800,
      "frameId": "zvBAOcMDC3qvYbVi5V2IX"
    }
  },
  "blocks": {
    "home": {
      "header": {"x": 10, "y": 4610, "width": 380, "height": 50},
      "CTA primario": {"x": 20, "y": 4730, "width": 360, "height": 50}
    }
  },
  "transitions": [...]
}
```

| Key | Description |
|-----|-------------|
| `frame_w`, `frame_h` | Frame dimensions in pixels (mobile=400×800, desktop=1200×800) |
| `gutter_x`, `gutter_y` | Spacing between frames (states/screens) |
| `screen_numbers` | Map screen `name` → row number (1..N) for use in destination circles. Only includes non-overlay screens |
| `overlay_numbers` | Map overlay screen `name` → label string (`"O-01"`, `"O-02"`, ...) for use in destination circles |
| `frames` | Each `{screen}__{state}` key → frame position and `frameId` |
| `blocks` | Each screen → block name → absolute (x, y, width, height) on the canvas. Only emitted for default state (other states have the same layout) |
| `transitions` | Original transitions list from `screens.json`, copied verbatim |

The agent uses this to compute arrow start/end coordinates anchored to specific blocks.

---

# `arrows.json` Schema

**Input** of `add_arrows.py`. Produced by the agent after consuming `coords.json` + the `transitions` list.

```json
{
  "arrows": [
    {
      "from": {"x": 392, "y": 4755},
      "to": {"x": 496, "y": 4755},
      "dashed": false,
      "color": "#1e1e1e"
    }
  ],
  "labels": [
    {
      "x": 404, "y": 4738,
      "text": "click 'Armá tu 11'",
      "fontSize": 10,
      "color": "#495057",
      "width": 88,
      "align": "left"
    }
  ],
  "circles": [
    {
      "x": 496, "y": 4741,
      "size": 28,
      "number": "2",
      "color": "#1e1e1e",
      "fontSize": 14
    }
  ]
}
```

All three top-level keys (`arrows`, `labels`, `circles`) are optional — include only what you need.

## Arrow object

| Key | Required | Description |
|-----|----------|-------------|
| `from` | Yes | `{x, y}` start point in absolute canvas coords |
| `to` | Yes | `{x, y}` end point |
| `dashed` | No | `true` for automatic transitions. Default `false` |
| `color` | No | Stroke color. Default `#1e1e1e` (black) |

## Label object

| Key | Required | Description |
|-----|----------|-------------|
| `x`, `y` | Yes | Top-left in absolute canvas coords |
| `text` | Yes | The label text |
| `fontSize` | No | Default `10` |
| `color` | No | Default `#495057` (dark gray) |
| `width` | No | Constrains text width. The agent picks this to avoid invading neighboring frames or circles |
| `height` | No | Optional explicit height |
| `align` | No | `left`, `center`, `right`. Default `left` |

## Circle object

| Key | Required | Description |
|-----|----------|-------------|
| `x`, `y` | Yes | Top-left of the circle's bounding box |
| `number` | Yes | Number to render inside (matches a screen's row number) |
| `size` | No | Diameter. Default `28` |
| `color` | No | Stroke and number color. Default `#1e1e1e` |
| `fontSize` | No | Number text size. Default `14` |

## Group object (fork-style arrow with multiple destinations)

Use a `group` when one source block triggers multiple transitions (e.g., the same input field can go to "valid result" or "not found"). Renders as:
- A trunk line from the source to a fork point
- N branch arrows from the fork point to each destination circle
- Destinations stacked vertically, centered on the source Y

```
[source] ─────●─→ ⑧ label A
              └─→ ④ label B
```

```json
{
  "groups": [
    {
      "from": {"x": 392, "y": 4935},
      "fork_at_x": 460,
      "destinations": [
        {"number": "8", "label": "código válido"},
        {"number": "4", "label": "código inválido"}
      ],
      "dashed": false
    }
  ]
}
```

| Key | Required | Description |
|-----|----------|-------------|
| `from` | Yes | `{x, y}` source point (typically the right edge of the source block at its vertical center) |
| `fork_at_x` | Yes | X coordinate where the trunk ends and branches start |
| `destinations` | Yes | Non-empty list of `{number, label}` objects. Branch Ys stack with `stack_offset` apart, centered around `from.y` |
| `dashed` | No | Default `false`. Applied to both trunk and branches |
| `color` | No | Default `#1e1e1e` |
| `circle_x` | No | X of the destination circles. Default `fork_at_x + 36` |
| `circle_size` | No | Default `28` |
| `stack_offset` | No | Vertical distance between destinations. Default `36` |
| `label_font_size` | No | Default `10` |
| `label_color` | No | Default `#495057` |
| `label_offset_x` | No | Distance from circle to label. Default `circle_size + 6` |
| `label_width` | No | Constrains label text width. Default `120` |

For 1 destination, use a regular `arrow` + `circle` + `label` instead — the group form has no fork. Reserve `groups` for N≥2 destinations from the same source.

## Failure

The script fails with `[add_arrows] ERROR: ...` and exit code 1 on:

- Missing target file or arrows JSON
- Arrow entry missing `from` or `to`
- Label entry missing `x`, `y`, or `text`
- Circle entry missing `x`, `y`, or `number`
- Group entry missing `from`, `destinations`, or `fork_at_x`
- Group with empty `destinations`

The script does **NOT** check for collisions with frames or other elements. The agent is responsible for picking values that don't overlap.
