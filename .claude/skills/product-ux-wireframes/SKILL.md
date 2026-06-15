---
name: product-ux-wireframes
description: Iterate on mid-fidelity wireframes — regenerate or update Excalidraw and per-screen docs for existing UX documentation. Use after /product-ux-generate has bootstrapped the product.
argument-hint: "[surface1,surface2,...]"
allowed-tools: "Read, Write, Edit, Bash, Glob, Grep"
---

> **This skill is for iteration, not bootstrap.** The first time you generate UX docs + wireframes for a product, use `/product-ux-generate` — it generates everything end-to-end (research artifacts + product-maps + user-flows + wireframes) in a single run.
>
> Use this skill when `docs/ux/` already exists and you need to: add a new screen, change microcopy or block structure, update a state, change the accent color, or regenerate a surface's `.excalidraw` from scratch.
>
> **Implementation note:** the `.excalidraw` files are produced by deterministic Python scripts in `scripts/`. Stage 1 (`build_wireframes.py`) builds frames + blocks + states. Stage 2 (agent-driven, `add_arrows.py`) decides arrow positions per transition. See `scripts/SCHEMA.md`.

# Product UX Wireframes (mid-fi) — iteración

## Purpose

Iterate on mid-fidelity wireframes for an existing product. Re-generates or updates `screens/*.md` and `wireframes.excalidraw` for every surface (or specific surfaces if scoped by the user).

**Flow:**
```
Step 0: Initialize (load context)
  |
Step 1: Validate prerequisites
  |
Step 2: For each surface — update per-screen docs + Excalidraw
  |
Step 3: Report and wait for user feedback
  |
Step 4: Iterate on changes (modify .md and .excalidraw, repeat Step 3)
```

**Result:** Updated `docs/ux/surfaces/{surface}/screens/{screen}.md` per screen + updated `docs/ux/surfaces/{surface}/wireframes.excalidraw` per surface.

**This command does NOT:**
- Create or update product-overview.md, product-map.md, user-flows.md, research-contexts, benchmarks — use `/product-ux-generate` (bootstrap) or `/product-ux-agent` (interactive edits)
- Generate high-fi wireframes (`Specs visuales` stays empty, `Accesibilidad` partially populated)
- Render visual designs in external tools (Figma, Claude Design) — output is self-contained Excalidraw

## Role

**Adopt the [UX Researcher Agent](.claude/agents/ux-researcher.md) role**

## CRITICAL RULES

1. **Use Spanish for generated content** — All `.md` content and Excalidraw labels in Spanish. Skill itself in English. User-facing notifications in Spanish.

2. **Save first, then validate** — Generate all artifacts, save them, notify the user, wait for feedback. If changes are requested, modify both the `.md` files and the `.excalidraw` accordingly and notify again.

3. **Reference locations from Files index** — Do not hardcode paths. Read [Files index](.claude/utils/index.md) for `ux_folder`, `ux_surfaces_folder`, `ux_audiences_folder`.

4. **Do NOT dump full content in chat** — Save to files, show summary, let user review in their editor.

5. **ABORT if UX prerequisites are missing** — Required: `docs/ux/product-overview.md`, at least one surface with `product-map.md` + `user-flows.md`, at least one audience with `research-context.md`. If missing, instruct the user to run `/product-ux-generate` first.

6. **Process ALL surfaces — do not ask** — The skill iterates over every detected surface without prompting for selection.

7. **The `.md` is the SOURCE OF TRUTH** — It must contain everything needed to regenerate the wireframe (texts, icons, variants, states, transitions). Coordinates and Excalidraw IDs are NOT stored — they are derived from the structure. Block visibility per state is declared on the block itself (not as duplicate screen entries): use `hidden_in_states`, `visible_only_in_states`, or `state_overrides` — see `scripts/SCHEMA.md`. **Never split a logical screen into two JSON entries to work around visibility.**

8. **Real microcopy in every block — NO "Pendiente"** — Mid-fi requires real text. Button labels, headings, paragraphs, error messages, placeholder text — all must be the actual text the user will see. Decide reasonable copy from context if the source `.md` is vague; do not leave placeholders.

9. **Block variants are mandatory for interactive blocks** — Every `button` must declare `variant: primary | secondary | tertiary | disabled | error`. Every `text-input` must declare `state: default | focused | error | disabled` (per applicable state). The Estructura table includes a column for variant/level/state.

10. **Block types must come from the dictionary** — 36 types in 5 categories (see "Block dictionary" reference below). Unknown types render as `[type] {name}` (visible flag, not failure).

11. **Granularity: molecule/organism, NOT atom** — Represent "search-bar" as one block, not as input + icon + button atoms.

12. **States limited to the 8 fixed UI states** — Plus optional sub-states (modal abierto, dropdown open) declared with a `parent_state` field. Each state with `Aplica: Sí` becomes a frame. Each state must declare its real user-facing message (not "Pendiente").

24. **Overlays (drawers, modals, bottom-sheets) are separate screen objects with `overlay: true`** — They appear in the product-map's "Inventario de Overlays" section (not in the main screen table) and in `screens.json` as entries with `"overlay": true`, `"overlay_type"`, and `"triggered_by"`. The script renders them in a dedicated section below the main grid, labeled `[drawer]`, `[modal]`, etc. Transitions FROM parent screens TO overlays are declared normally in `transitions[]`. **Do NOT list overlays in the "Inventario de Pantallas" main table, and do NOT create a separate row in the main grid for them.**

13. **"Permiso/acceso denegado" applies ONLY for auth/role/ownership contexts** — Not for transient interaction states.

14. **Surface-level accent color** — Each surface declares ONE accent color (default `#2563eb`) at the top of `screens.json`. The script applies it to: primary buttons (filled), secondary buttons (outline), focused inputs, active tabs, links, dropdown open border. NO other element uses color — everything else stays grayscale. This keeps mid-fi distinct from high-fi.

15. **Icons by name from the Unicode map** — When declaring an icon (`icon: "search"`), use a name from the Unicode map in `excalidraw_lib.py`. Common names: search, menu, close, check, x, plus, minus, arrow-up/down/left/right, chevron-up/down, home, user, settings, edit, trash, heart, star, info, warning, error, success, more, calendar, clock, image, file, folder, link, share, download, upload, refresh, eye, eye-off, lock, mail, phone, bell, message. Unknown names fall back to `[name]` text — avoid unless the icon is critical.

16. **Annotations describe behavior** — Use `annotation` on a block to add an inline gray note describing behavior (e.g., "polling 30s", "valida >8 chars al submit", "sheet-style modal"). Useful for mid-fi to communicate behaviors without animating them.

17. **Headings have hierarchy** — `heading` blocks declare `level: h1 | h2 | h3`. h1 is for the screen's main title (one per screen typically). h2 for section titles. h3 for subsections.

18. **Real error messages, not generic** — In `error de validación` and `error de sistema` states, declare the actual user-facing message ("Email inválido. Probá de nuevo.", not "Error message"). The script renders this as the `alert` content.

19. **Mobile-first by default** — Frame size 400×800 unless `product-overview.md` declares otherwise. If desktop-first, use 1200×800.

20. **Layout: vertical = screens, horizontal = states** — Each screen = one row. Each state = one column within the row. Default state always in column 0.

21. **Overwrite without asking** — If `screens/*.md` or `wireframes.excalidraw` exist, overwrite them. The user has git for history.

22. **Generate Excalidraw via the bundled scripts — NEVER inline JSON** — Claude does NOT write Excalidraw JSON in chat or via Write tool. Two stages: (a) `build_wireframes.py` renders frames + blocks + states from `screens.json`. (b) `add_arrows.py` appends arrows from `arrows.json` decided by the agent.

23. **WAIT for user feedback at end** — After generating everything, present summary and wait. If user requests changes, apply them to both the relevant `.md` and the `.excalidraw`, then notify and wait again.

## Execution

### Step 0: Initialize

Load context.

**0.0 Parse `$ARGUMENTS` — surface scope**

The argument is optional and accepts a comma-separated list of surface names to limit the run.

- **No argument** (empty or whitespace-only) → `target_surfaces = "all"` — process every surface under **ux_surfaces_folder** with both `product-map.md` and `user-flows.md`.
- **Single surface** (`app-conductor`) → `target_surfaces = ["app-conductor"]`.
- **Multiple surfaces** (`app-conductor,dashboard-admin`) → split by comma, strip whitespace from each entry, deduplicate.

Validation:
- Each name listed MUST exist as a folder under **ux_surfaces_folder** AND contain both `product-map.md` and `user-flows.md`.
- If any listed surface fails the check:
  ```markdown
  No puedo procesar las siguientes superficies (no existen o les faltan documentos UX base):
  - {{lista de superficies inválidas}}

  Superficies disponibles:
  - {{lista de superficies válidas detectadas}}

  Ejecutá `/product-ux-wireframes` sin argumentos para procesar todas, o pasá una lista CSV de las válidas.
  ```
  **ABORT.**

**0.1 Read Files index**

1. Read [Files index](.claude/utils/index.md) to get folder locations
2. Identify key folders:
   - **ux_folder** — root of UX docs (`docs/ux/`)
   - **ux_surfaces_folder** — per-surface artifacts (`docs/ux/surfaces/`)
   - **ux_audiences_folder** — per-audience artifacts (`docs/ux/audiences/`)

**0.2 Read screen template**

Read [Screen Mid Template](.claude/templates/screen-mid-tmpl.yaml) to know the structure of per-screen `.md` files at mid-fi.

**0.3 Read scripts schema**

Read `.claude/skills/product-ux-wireframes/scripts/SCHEMA.md` to understand the canonical JSON structure required by the build script.

---

### Step 1: Validate prerequisites

Check that the UX documentation set exists.

**1.1 Required files:**

- **ux_folder**/product-overview.md
- At least one **ux_surfaces_folder**/{surface}/product-map.md
- At least one **ux_surfaces_folder**/{surface}/user-flows.md
- At least one **ux_audiences_folder**/{audience}/research-context.md

**1.2 If any required file is missing:**

```markdown
No puedo iterar wireframes: falta la documentación UX base.

Falta:
- {Lista de archivos faltantes}

Este skill es para iteración sobre documentación UX existente.
Ejecutá `/product-ux-generate` para generar el set completo desde cero (UX docs + wireframes).
```

**ABORT.**

---

### Step 2: Process each surface

Detect surfaces under **ux_surfaces_folder** that have both `product-map.md` and `user-flows.md`. Filter by **target_surfaces** from Step 0.0:

- If `target_surfaces == "all"` → process all detected surfaces, in order.
- If `target_surfaces` is a list → process only those (already validated in Step 0.0 to exist).

For each surface in scope, execute steps 2.1 through 2.5.

If `target_surfaces` is a list, also notify the user at the start of this step:

```markdown
Procesando solo las superficies seleccionadas: {{lista}}.
```

#### 2.1 Read surface UX docs

For the current surface:

1. Read **ux_folder**/product-overview.md (cached for all surfaces)
2. Read **ux_surfaces_folder**/{surface}/product-map.md
3. Read **ux_surfaces_folder**/{surface}/user-flows.md
4. Read **ux_audiences_folder**/{audience}/research-context.md for each audience listed in the product-map

#### 2.2 Decide visual style for the surface

- **`accent_color`**: read product-overview.md to see if a brand color is mentioned. If not, default to `#2563eb`. Use the same accent across all screens of the surface.
- **`grid_baseline`**: default 8.
- **`device`**: from product-overview default (mobile unless declared otherwise).

#### 2.3 Infer per-screen definitions

For each screen listed in the product-map's "Inventario de Pantallas":

**Identity:**
- `name`: kebab-case from screen name
- `route`: from product-map's "Ruta" column
- `device`: surface device
- `audiences`: from product-map (single or co-primary)

**Blocks:** infer from the screen's "Propósito" cell + descriptive notes. For each block decide:
- `type` from the dictionary
- `category` (informative)
- `content` — the **real text** that will be rendered (label, heading, microcopy)
- `variant` — for buttons (primary/secondary/disabled/...)
- `level` — for headings (h1/h2/h3) and paragraphs (body/caption)
- `kind` — for alerts (error/warning/info/success)
- `icon` — when applicable, name from the Unicode map
- `aspect_ratio` — for images
- `items` — for lists (list of `{title, subtitle, icon}`)
- `annotation` — inline behavior note when needed

**Applicable states:** evaluate each of the 8 fixed states. For each applicable, declare:
- The actual user-facing message
- Which blocks change and HOW (variant, state, content overrides)

Also evaluate sub-states (modal abierto, dropdown open). Declare them as additional state objects with `parent_state` if needed.

**Transitions:** from user-flows.md, extract user-driven and automatic transitions to/from this screen. For each transition, decide:
- `src`, `dst` (matching screen `name`s)
- `srcState` (default unless trigger lives in a non-default state — e.g., "Reintentar" button inside `error de sistema`)
- `srcBlock` — the block name that triggers the transition (button, link, input)
- Short `trigger` text (4-6 words)
- `automatic` boolean

**Decisions:** extract from product-map's notes anything relevant to this screen.

#### 2.4 Generate per-screen `.md` files

For each screen, generate `docs/ux/surfaces/{surface}/screens/{screen-name}.md` following the screen-mid template. Initial fidelity:

```yaml
fidelity:
  visuals: mid
  content: mid
  interactivity: low
```

Frontmatter must include `accent_color` (if first screen of surface) — subsequent screens may inherit (but it's also OK to repeat for clarity).

All template sections present. `Contenido` filled with real text. `Estados` filled with real messages. `Interacciones` populated with events and validations. `Specs visuales` empty (high-fi). `Accesibilidad` partial. `Decisiones y descartes` mandatory.

#### 2.5 Generate Excalidraw (two stages)

**2.5.a Produce canonical `screens.json`**

Write a JSON to `/tmp/wireframes-{surface}-{timestamp}.json` following `scripts/SCHEMA.md`. Include:
- `surface`, `device`, `accent_color`, `grid_baseline`
- `screens[]` with full block/state info from the `.md`
- `transitions[]` with `srcBlock` declared (required for arrow anchoring)

**2.5.b Render frames + emit coords**

```bash
python3 .claude/skills/product-ux-wireframes/scripts/build_wireframes.py \
  /tmp/wireframes-{surface}-{timestamp}.json \
  docs/ux/surfaces/{surface}/wireframes.excalidraw \
  /tmp/wireframes-{surface}-coords.json
```

Generates the `.excalidraw` with frames, blocks, states, and the `coords.json`.

**2.5.c Decide arrow layout, write `arrows.json`**

Read `coords.json` and the `transitions` list. For each transition or group of transitions from the same `srcBlock`:

**Group transitions by `(src, srcState, srcBlock)`**:
- N=1: emit individual `arrow` + `circle` + `label`
- N≥2: emit one `group` (fork-style)

For each individual transition (N=1):
1. **Arrow** — anchor `from` to source block right edge: `(block.x + block.width, block.y + block.height/2)`. End at `(frame.x + frame.width + gutter_x - 28 - 16, anchor_y)`. `dashed: true` if automatic.
2. **Circle** — at the arrow's `to` point, `y = arrow_to.y - 14`. `number`: `coords.screen_numbers[transition.dst]`.
3. **Label** — below the arrow, `width: 88`, font 10, color `#495057`, with the short trigger.

For each group (N≥2):
- `from`: `(block.x + block.width, block.y + block.height/2)`
- `fork_at_x`: `from.x + 50`
- `circle_x`: `frame.x + frame.width + gutter_x - 28 - 16`
- `destinations`: list of `{number, label}` per transition
- `dashed`: `true` if ALL transitions are automatic; `false` otherwise (split if mixed)

**Anti-collision:**
- Sort blocks top-down. After grouping, ensure consecutive arrows from different blocks have ≥36px vertical separation. If not, push the lower one down.
- If a group's last destination would push outside the frame, drop the lowest-priority destination (it stays in the `.md` only).

Write `arrows.json` to `/tmp/wireframes-{surface}-arrows.json`.

**2.5.d Append arrows**

```bash
python3 .claude/skills/product-ux-wireframes/scripts/add_arrows.py \
  docs/ux/surfaces/{surface}/wireframes.excalidraw \
  /tmp/wireframes-{surface}-arrows.json
```

Modifies the `.excalidraw` in place.

**Do NOT** read the generated `.excalidraw` into context — it's 1000+ elements.

---

### Step 3: Report and wait for feedback

After all surfaces are generated, present a summary:

```markdown
Wireframes mid-fi generados.

**{surface-1}:**
- {N} pantallas: {pantalla-1}, {pantalla-2}, ...
- {M} estados representados
- Accent color: {color hex}
- Archivos:
  - `docs/ux/surfaces/{surface-1}/screens/*.md` ({N} archivos)
  - `docs/ux/surfaces/{surface-1}/wireframes.excalidraw`

**{surface-2}:** ...

Para abrir el `.excalidraw`:
1. Ir a https://excalidraw.com
2. Menu → Open → seleccionar el archivo

**Revisá los archivos y decime si está correcto o querés cambios.**
```

**WAIT for user response.**

---

### Step 4: Iterate on changes

When the user requests changes:

**4.1 Identify scope of change**
- ¿A qué pantalla(s)/superficie(s) afecta?
- ¿Es cambio de estructura, contenido, variants, accent color, o layout del canvas?

**4.2 Apply changes**
- Edit the relevant screen `.md` files (the `.md` is the source of truth)
- For each affected surface, run all four sub-steps again (2.5.a → 2.5.d)
- If user changes the accent color, update both the `.md` frontmatter and the `screens.json`

**4.3 Notify and wait again**

```markdown
Cambios aplicados:
- {Cambio 1}
- {Cambio 2}

Archivos modificados:
- {paths}

**Revisá los cambios y decime si ahora está correcto o querés ajustar algo más.**
```

**WAIT for user response. Repeat Step 4 until the user confirms.**

---

## Output

Files saved per surface to **ux_surfaces_folder**/{surface}/ (see Files index for locations):

- `screens/{screen-name}.md` — One per screen at mid-fi:
  - Frontmatter with `fidelity: visuals: mid, content: mid, interactivity: low` and `accent_color`
  - Identidad, Entrada/Salida, Estructura (with variant column)
  - Contenido with REAL microcopy per block (no "Pendiente")
  - Estados with REAL user-facing messages
  - Interacciones populated (events, validations, feedback)
  - Specs visuales: "Pendiente — high-fi"
  - Accesibilidad: partial (contraste, foco, ARIA)
  - Decisiones y descartes (mandatory)

- `wireframes.excalidraw` — One per surface, contains:
  - Title + legend
  - Grid: rows = screens, columns = states
  - All applicable states per screen
  - Block variants visually distinguishable (primary buttons filled with accent color, secondary outlined, disabled gray)
  - Icons rendered as Unicode glyphs
  - Annotations as inline gray notes below blocks
  - Arrows (numbered destinations, fork-style for multi-destination)

---

## Block dictionary (reference)

The skill recognizes 36 block types in 5 categories. Use ONLY these types in screen `.md` files. For unmapped concepts, fall back to `section`.

### Layout (6)
`header` · `footer` · `sidebar` · `main` · `modal` · `section`

### Navigation (5)
`nav-bar` · `tabs` · `link` · `breadcrumbs` · `pagination`

### Content (10)
`heading` · `paragraph` · `image` · `icon` · `list` · `card` · `table` · `avatar` · `badge` · `chart`

### Input (9)
`text-input` · `button` · `dropdown` · `checkbox` · `radio` · `toggle` · `search-bar` · `slider` · `date-picker`

### Feedback (6)
`alert` · `toast` · `progress-bar` · `tooltip` · `empty-state` · `loader`

---

## Variants by block (mid-fi)

| Block | Field | Values |
|-------|-------|--------|
| `button` | `variant` | primary (filled accent), secondary (outline), tertiary (link-style), disabled (gray), error (red) |
| `text-input` | `state` | default, focused (accent border), error (red + msg), disabled |
| `heading` | `level` | h1 (28px), h2 (22px default), h3 (18px) |
| `paragraph` | `level` | body, caption |
| `alert` | `kind` | error (red), warning (orange), info (blue), success (green) |
| `dropdown` | `state` | closed (default), open |
| `tabs` | `active` | index of active tab |

---

## Accent color (mid-fi)

A single accent color per surface. Default `#2563eb`. Applied to:
- `button` variant `primary` (background fill)
- `button` variant `secondary` (border + text)
- `button` variant `tertiary` (text)
- `text-input` state `focused` (border)
- `tabs` active tab (text + bottom border)
- `link` (text)
- `dropdown` state `open` (border)

NO other elements use color (everything else stays in `#1e1e1e` + grays).

---

## Icon names (Unicode map)

The skill maps icon names to Unicode glyphs. Common names:

| Group | Names |
|-------|-------|
| Navigation | `menu`, `close`, `x`, `arrow-up`, `arrow-down`, `arrow-left`, `arrow-right`, `chevron-up`, `chevron-down`, `chevron-left`, `chevron-right`, `home`, `more` |
| User/social | `user`, `users`, `heart`, `star`, `mail`, `phone`, `bell`, `notification`, `message`, `comment`, `share` |
| Action | `search`, `check`, `checkmark`, `plus`, `minus`, `edit`, `trash`, `delete`, `refresh`, `download`, `upload`, `link`, `eye`, `eye-off`, `lock`, `unlock` |
| Status | `info`, `warning`, `error`, `alert`, `success` |
| Content | `image`, `file`, `folder`, `calendar`, `clock`, `time`, `play`, `pause`, `stop`, `filter`, `sort` |
| Settings | `settings` |

Unknown names render as `[name]` text (visible flag).

---

## 8 fixed UI states

| # | State | When it applies |
|---|-------|-----------------|
| 1 | default | Happy path |
| 2 | empty | First use / no data yet |
| 3 | loading | Fetching data |
| 4 | error de validación | User input invalid |
| 5 | error de sistema / sin conexión | Server failure or network loss |
| 6 | success | Confirmation after action |
| 7 | not found | Resource doesn't exist |
| 8 | estado terminal / readonly | Locked, immutable |

Sub-states (modal abierto, dropdown open) can be declared as additional state objects with `parent_state: default`.
