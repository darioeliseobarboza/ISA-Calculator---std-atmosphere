---
name: product-ux-generate
description: Generate complete UX documentation set (overview, benchmarks, research-contexts, product-maps, user-flows, cross-surface-flows) from PRD, then generate mid-fidelity Excalidraw wireframes for every surface
allowed-tools: "Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, WebSearch"
---

> **Implementation note:** the `.excalidraw` files in Steps 10-11 are produced by deterministic Python scripts in `.claude/skills/product-ux-wireframes/scripts/`. The bridge between human-readable `.md` files and the scripts is canonical JSON (in `/tmp/`). Stage 1 builds frames + blocks + states. Stage 2 (agent-driven) decides arrow positions per transition. See `scripts/SCHEMA.md`.
>
> To iterate on wireframes after the initial run (add a screen, change microcopy, regenerate a surface), use `/product-ux-wireframes` — it picks up from the existing UX docs and overwrites only the Excalidraw output.

# UX Generate

## Purpose

Bootstrap the complete UX documentation set for a product from scratch, then generate mid-fidelity wireframes for every surface. Single command covers the full design phase: research artifacts → screen inventory → wireframes.

**Flow:**
```
Step 0:  Validate & Setup
  |
Step 1:  Load PRD context
  |
Step 2:  Detect audiences and surfaces (with user confirmation)
  |
Step 3:  Generate product-overview.md
  |
Step 4:  Generate benchmarks (per audience, in parallel)
  |
Step 5:  Generate research-contexts (per audience, in parallel)
  |
Step 6:  Generate product-maps (per surface, in parallel)
  |
Step 7:  Generate user-flows (per surface, in parallel)
  |
Step 8:  Generate cross-surface-flows.md
  |
Step 8.5: Bootstrap Design System scaffold (skip if exists)
  |
Step 9:  UX docs summary — announce wireframe generation start
  |
Step 10: For each surface — generate per-screen .md + Excalidraw
  |
Step 11: Wireframes summary — wait for user feedback / iterate
```

**Result:** Full `docs/ux/` tree populated + `docs/ux/surfaces/{surface}/screens/{screen}.md` per screen + `docs/ux/surfaces/{surface}/wireframes.excalidraw` per surface + `docs/design-system/` scaffold.

**This command does NOT:**
- Modify existing UX artifacts — for that, use `/product-ux-agent`
- Generate high-fi wireframes (`Specs visuales` stays empty, `Accesibilidad` partially populated)
- Render visual designs in external tools (Figma, Claude Design) — the output is self-contained Excalidraw

For interactive editing of existing UX artifacts, use `/product-ux-agent`.
For iterating wireframes after the initial run, use `/product-ux-wireframes`.

## Role

**Adopt the [UX Researcher Agent](.claude/agents/ux-researcher.md) role**

## CRITICAL RULES

### UX documentation rules

1. **ABORT if PRD does not exist** — Requires `goals-and-context.md` and `requirements.md` in **prd_folder**. Run `/product-initialize` first if missing.
2. **ABORT if technical architecture does not exist** — Requires `architecture.md` in **prd_folder**. Without architecture, services (and therefore surfaces) cannot be identified. Run `/product-initialize-technical` first if missing.
3. **ABORT if `ux_folder` already exists** — This skill is for bootstrapping. If `docs/ux/` exists, suggest `/product-ux-agent` for UX modifications or `/product-ux-wireframes` for regenerating wireframes only.
4. **Use Spanish for generated content** — Match the language of the PRD. All user interactions in Spanish.
5. **Save first, then continue** — Save each artifact, do not stop for intermediate approval. Show summary at Step 9 before continuing to wireframes.
6. **Reference locations from Files Index** — Use folder IDs (`prd_folder`, `ux_folder`, `ux_audiences_folder`, `ux_surfaces_folder`).
7. **Do NOT dump full content in chat** — Save to files, show summary.
8. **Follow the 7 firm rules** of the methodology (defined in the agent file): persona genérica, audiencias por JTBD, sin versionado de archivos, alcance Fase 1-2, trazabilidad obligatoria, vocabulario funcional, no rellenar.
9. **Generation order is mandatory** — Each step depends on the previous. Do not parallelize across phase boundaries.
10. **Use templates strictly** — Read each template from Files Index before drafting its corresponding artifact.
11. **Parallel steps MUST use the `ux-researcher` subagent** — Steps 4, 5, 6, and 7 launch one subagent per audience/surface. ALWAYS pass `subagent_type: "ux-researcher"` to the `Agent` tool.

### Wireframe rules

12. **The `.md` is the SOURCE OF TRUTH** — It must contain everything needed to regenerate the wireframe (texts, icons, variants, states, transitions). Coordinates and Excalidraw IDs are NOT stored — they are derived from the structure. Block visibility per state is declared on the block itself (not as duplicate screen entries): use `hidden_in_states`, `visible_only_in_states`, or `state_overrides` — see `scripts/SCHEMA.md`. **Never split a logical screen into two JSON entries to work around visibility.**

13. **Real microcopy in every block — NO "Pendiente"** — Mid-fi requires real text. Button labels, headings, paragraphs, error messages, placeholder text — all must be the actual text the user will see.

14. **Block variants are mandatory for interactive blocks** — Every `button` must declare `variant: primary | secondary | tertiary | disabled | error`. Every `text-input` must declare `state: default | focused | error | disabled` per applicable state. The Estructura table includes a column for variant/level/state.

15. **Block types must come from the dictionary** — 36 types in 5 categories (see reference section below). Unknown types render as `[type] {name}` (visible flag, not failure).

16. **Granularity: molecule/organism, NOT atom** — Represent "search-bar" as one block, not as input + icon + button atoms.

17. **States limited to the 8 fixed UI states** — Plus optional sub-states declared with a `parent_state` field. Each state with `Aplica: Sí` becomes a frame. Each state must declare its real user-facing message.

18. **Overlays (drawers, modals, bottom-sheets) are separate screen objects with `overlay: true`** — They appear in the product-map's "Inventario de Overlays" section (not in the main screen table) and in `screens.json` as entries with `"overlay": true`, `"overlay_type"`, and `"triggered_by"`. The script renders them in a dedicated section below the main grid. Transitions FROM parent screens TO overlays are declared normally in `transitions[]`. **Do NOT list overlays in the "Inventario de Pantallas" main table.**

19. **Surface-level accent color** — Each surface declares ONE accent color (default `#2563eb`) at the top of `screens.json`. Applied to primary buttons, secondary button borders, focused inputs, active tabs, links. Everything else stays grayscale.

20. **Icons by name from the Unicode map** — Use names from the Unicode map in `excalidraw_lib.py` (see reference section). Unknown names fall back to `[name]` text.

21. **Generate Excalidraw via the bundled scripts — NEVER inline JSON** — Two stages: (a) `build_wireframes.py` renders frames + blocks + states from `screens.json`. (b) `add_arrows.py` appends arrows from `arrows.json` decided by the agent.

22. **"Permiso/acceso denegado" applies ONLY for auth/role/ownership contexts** — Not for transient interaction states.

23. **Mobile-first by default** — Frame size 400×800 unless `product-overview.md` declares otherwise. Desktop-first: 1200×800.

24. **Layout: vertical = screens, horizontal = states** — Each screen = one row. Each state = one column. Default state always in column 0.

25. **Overwrite without asking** — If `screens/*.md` or `wireframes.excalidraw` exist, overwrite them. The user has git for history.

26. **WAIT for user feedback after wireframes** — After generating all surfaces, present summary and wait. If user requests changes, apply them to both `.md` and `.excalidraw`, notify and wait again.

---

## Execution

### Step 0: Validate & Setup

**0.1 Load Context**

1. Read [Files index](.claude/utils/index.md) to get all locations
2. Identify key folders:
   - **prd_folder** — PRD location (input)
   - **references_folder** — External references (optional input)
   - **ux_folder** — Root UX output
   - **ux_audiences_folder** — Per-audience artifacts
   - **ux_surfaces_folder** — Per-surface artifacts

**0.2 Validate Prerequisites**

```bash
ls docs/prd/goals-and-context.md docs/prd/requirements.md docs/prd/architecture.md 2>/dev/null
ls -d docs/ux 2>/dev/null
```

**If PRD files are missing, ABORT:**

```markdown
No encuentro el PRD necesario para ejecutar este skill.

Faltan archivos en **prd_folder**:
- goals-and-context.md
- requirements.md

**Ejecutá primero** `/product-initialize` para crear la documentación base del producto.
```

**If technical architecture is missing, ABORT:**

```markdown
No encuentro la documentación de arquitectura técnica necesaria para ejecutar este skill.

Falta archivo en **prd_folder**:
- architecture.md

Sin arquitectura no puedo identificar los servicios del producto, y por lo tanto no puedo mapear las superficies (regla: 1 superficie = 1 app/web/cliente deployable).

**Ejecutá primero** `/product-initialize-technical` para crear la documentación de arquitectura.
```

**If `docs/ux/` already exists, ABORT:**

```markdown
Ya existe documentación UX en `docs/ux/`.

Este skill es para inicialización desde cero. Para modificar o extender la documentación UX existente, usá:

- **`/product-ux-agent`** — Modo interactivo para editar los artefactos UX existentes.
- **`/product-ux-wireframes`** — Para regenerar o iterar solo los wireframes.

Si querés rehacer todo desde cero, eliminá `docs/ux/` manualmente y volvé a ejecutar este skill.
```

**0.3 Read wireframe templates and schema**

Read these now so Steps 10-11 don't need extra I/O:
1. Read [Screen Mid Template](.claude/templates/screen-mid-tmpl.yaml)
2. Read `.claude/skills/product-ux-wireframes/scripts/SCHEMA.md`

**0.4 Create base UX folder structure**

```bash
mkdir -p docs/ux/audiences docs/ux/surfaces
```

---

### Step 1: Load PRD Context

Read all PRD files and references. Do not summarize yet — gather first.

**1.1 Read PRD**

Read from **prd_folder**:
- `goals-and-context.md` (users U-XX, goals G-XX, scope)
- `requirements.md` (domain entities, capabilities C-XX, business rules)
- `feature-groups.md` (if exists — useful for detecting surfaces)

**1.2 Read references (if any)**

```bash
ls docs/references/ 2>/dev/null
```

If exists, read `index.md` and any files relevant to UX (brand, prior client products, integrations affecting UX).

**1.3 Detect PRD language**

Identify language. The full UX document set MUST match this language.

---

### Step 2: Detect Audiences and Surfaces

Propose candidate audiences and surfaces inferred from the PRD. Confirm with the user before generating.

**2.1 Propose candidates**

Based on the PRD, infer:

- **Audiences** — From Target Users (U-XX), capability Actor column, and distinct JTBDs. Remember Rule 2: split by JTBD, not by U-XX label.
- **Surfaces** — From feature groups, capability groupings, and explicit mentions in goals-and-context.md.

Notify user:

```markdown
## Audiencias y superficies detectadas

Basándome en el PRD, identifico:

**Audiencias** (separadas por JTBD distintos):
- **{{audience-1-slug}}** — {{1 línea: rol y contexto}}
- **{{audience-2-slug}}** — {{1 línea}}

**Superficies** (áreas coherentes del producto):
- **{{surface-1-slug}}** — {{1 línea: qué área cubre}}
- **{{surface-2-slug}}** — {{1 línea}}

**Matriz preliminar (audiencia ↔ superficie):**
- {{audience-1}} usa: {{surface-1}}, {{surface-2}}
- {{audience-2}} usa: {{surface-2}}

**¿Es correcto? Modificarías algo?**

Podés:
- Agregar / quitar / renombrar audiencias o superficies
- Corregir la matriz
- Confirmar para continuar
```

**WAIT for user response.**

**2.2 Iterate until confirmed**

If the user requests changes, update the proposal and re-confirm. Repeat until user explicitly confirms.

**Slug naming rules:**
- Lowercase, hyphens (kebab-case)
- Audience: descriptive of role + context (e.g., `operador-turno`, `admin-sistema`)
- Surface: descriptive of area + platform if relevant (e.g., `app-operador`, `dashboard-supervisor`)

**2.3 Create folder structure**

For each confirmed audience and surface:

```bash
mkdir -p docs/ux/audiences/{{audience-name}}
mkdir -p docs/ux/surfaces/{{surface-name}}
```

---

### Step 3: Generate `product-overview.md`

Generate the root UX document.

**3.1 Read template**

Read **UX Overview Template** from Files Index.

**3.2 Draft and save**

Follow the template structure. Use confirmed audiences, surfaces, and matrix from Step 2. Extract glossary terms from PRD entities and key concepts (5-15 terms).

Save to **ux_folder**/`product-overview.md`.

Continue without notifying — full summary at Step 9.

---

### Step 4: Generate Benchmarks (per audience, in parallel)

Generate `benchmark.md` for EACH audience.

**4.1 Read template**

Read **UX Benchmark Template** from Files Index (read once, use for all audiences).

**4.2 For each audience, in parallel**

Launch one `ux-researcher` subagent per audience using the `Agent` tool with `subagent_type: "ux-researcher"`. All subagents run in parallel (single message with multiple Agent tool calls).

Each subagent must:

1. Use `WebSearch` to research 2-4 direct competitors and 1-3 indirect references relevant to its assigned audience
2. Cite sources for every reference
3. If a specific aspect cannot be verified, declare it explicitly in "Limitaciones del Benchmark"
4. Follow template structure
5. Save to **ux_audiences_folder**/`{{audience-name}}/benchmark.md`

**Honesty rules** (from agent):
- If web search returns nothing useful, write "No se encontró información suficiente sobre [aspecto]"
- Never fabricate UI details

---

### Step 5: Generate Research Contexts (per audience, in parallel)

Generate `research-context.md` for EACH audience. **Requires the benchmark for that audience to exist.**

**5.1 Read template**

Read **UX Research Context Template** from Files Index.

**5.2 For each audience, in parallel**

Launch one `ux-researcher` subagent per audience using the `Agent` tool with `subagent_type: "ux-researcher"`. All subagents run in parallel (single message with multiple Agent tool calls).

Each subagent must:

1. Read its `benchmark.md` (just saved in Step 4)
2. Read PRD sections relevant to this audience
3. Apply the firm rules strictly:
   - **Rule 1**: One generic persona, no fictional names
   - **Rule 5**: Trace every JTBD/pain/gain/hypothesis to PRD/benchmark/input-cliente. Drop items without traceability.
   - **Rule 6**: Functional vocabulary. No banned words.
   - **Rule 7**: Maximums are ceilings (3 JTBD, 3 pains, 3 gains, 5 hypotheses). Document fewer if base info is limited.
4. For each behavioral hypothesis, label both state (`hipótesis` default) and strength (`inferida-PRD` / `inferida-benchmark` / `por-analogía`)
5. ALWAYS include "Lo que NO sabemos" section (mandatory, minimum 3 questions)
6. Set frontmatter `status: hipótesis-preliminar`
7. Save to **ux_audiences_folder**/`{{audience-name}}/research-context.md`

---

### Step 6: Generate Product Maps (per surface, in parallel)

Generate `product-map.md` for EACH surface.

**6.1 Read template**

Read **UX Product Map Template** from Files Index.

**6.2 For each surface, in parallel**

Launch one `ux-researcher` subagent per surface using the `Agent` tool with `subagent_type: "ux-researcher"`. All subagents run in parallel (single message with multiple Agent tool calls).

Each subagent must:

1. Identify which audiences use this surface (from the matrix in product-overview.md)
2. Read the research-contexts of those audiences
3. Read PRD feature groups and capabilities relevant to this surface
4. Apply rules:
   - Default to MINIMUM screens
   - Every screen traces to PRD reference (C-XX, U-XX, or "sugerencia fuera de PRD")
   - Decisional tone, no decorative language
   - Follow template structure
   - Include "Inventario de Overlays" section for drawers/modals/bottom-sheets (if any)
5. Generate at least 3 open questions with A/B impact
6. Save to **ux_surfaces_folder**/`{{surface-name}}/product-map.md`

---

### Step 7: Generate User Flows (per surface, in parallel)

Generate `user-flows.md` for EACH surface. Requires product-map.md of the surface to exist.

**7.1 Read template**

Read **UX User Flows Template** from Files Index.

**7.2 For each surface, in parallel**

Launch one `ux-researcher` subagent per surface using the `Agent` tool with `subagent_type: "ux-researcher"`. All subagents run in parallel (single message with multiple Agent tool calls).

Each subagent must:

1. Read the surface's `product-map.md` (just saved)
2. Read research-contexts of audiences using this surface
3. Identify 3-5 critical flows (NOT all flows — only the ones that define the product's value for this surface)
4. For each flow, document:
   - JTBD it solves (linked to research-context)
   - Audience executing it
   - Trigger
   - Happy path
   - Alternative paths
   - Errors and recovery (mandatory)
   - Final state
   - Success criteria
5. EXCLUDE cross-surface flows (those go in Step 8)
6. Save to **ux_surfaces_folder**/`{{surface-name}}/user-flows.md`

---

### Step 8: Generate `cross-surface-flows.md`

Generate the global cross-surface flows document.

**8.1 Read template**

Read **UX Cross-Surface Flows Template** from Files Index.

**8.2 Draft based on full surface set**

Read all surface user-flows generated in Step 7. Identify flows where state, notifications, or actions actually cross between surfaces.

**Special case: single-surface product**

If the product has only one surface, write the document with the empty-case section only:

```markdown
## No aplica

Este producto tiene una sola superficie (**{{surface-name}}**). Los flujos viven en `surfaces/{{surface-name}}/user-flows.md`.

Si en el futuro se agrega otra superficie, este documento se completará con los flujos que crucen entre superficies.
```

**For multi-surface products:**

For each cross-surface flow:
- Surfaces involved (with order and role)
- Audiences involved
- Sequence with surface markers `[surface-name]` per step
- Synchronization (real-time / polling / batch / manual + latency)
- Intermediate states (what each audience sees during the flow)

Save to **ux_folder**/`cross-surface-flows.md`.

---

### Step 8.5: Bootstrap Design System structure

After UX docs are generated, bootstrap the Design System scaffold if it doesn't exist yet.

The DS is bootstrapped **per surface**: each surface confirmed in Step 2 gets its own complete DS scaffold under `docs/design-system/{surface}/`. A `docs/design-system/README.md` index at the root lists all surfaces.

**8.5.1 Check if `docs/design-system/` already exists**

```bash
test -d docs/design-system && echo "EXISTS" || echo "MISSING"
```

**If EXISTS:** skip this step entirely. Do NOT overwrite.

**If MISSING:** proceed with 8.5.2.

**8.5.2 Copy the root index**

```bash
mkdir -p docs/design-system
cp -r .claude/skills/product-ux-generate/assets/design-system-bootstrap-root/* docs/design-system/
```

**8.5.3 Copy per-surface scaffold for each confirmed surface**

For each `{{surface-name}}` confirmed in Step 2:

```bash
mkdir -p docs/design-system/{{surface-name}}
cp -r .claude/skills/product-ux-generate/assets/design-system-bootstrap-per-surface/* docs/design-system/{{surface-name}}/
```

After copying, replace the `{{SURFACE}}` placeholder in each surface's `README.md` with the actual surface name:

```bash
sed -i "s/{{SURFACE}}/{{surface-name}}/g" docs/design-system/{{surface-name}}/README.md
```

**8.5.4 Populate the root `README.md` surfaces list**

The root `docs/design-system/README.md` ships with a placeholder bullet for the surfaces list. Replace that bullet with one line per surface, linking to its README:

```markdown
- [`{{surface-name}}`](./{{surface-name}}/README.md) — versión inicial 0.1.0
```

Locate the comment block and the placeholder bullet (`- (se completa al bootstrappear...)`) and replace with the generated list. One bullet per surface, alphabetical order.

**8.5.5 Replace `{{DATE}}` placeholders with today's date**

```bash
TODAY=$(date +%Y-%m-%d)
find docs/design-system -name '*.md' -exec sed -i "s/{{DATE}}/${TODAY}/g" {} +
```

---

### Step 9: UX docs summary

Present the UX documentation summary, then immediately continue to Step 10 without waiting.

```markdown
Documentación UX generada. Generando wireframes mid-fi…

**Estructura UX:**
docs/ux/
├── product-overview.md
├── cross-surface-flows.md
├── audiences/
{{Para cada audiencia:}}
│   └── {{audience-name}}/ benchmark.md · research-context.md
└── surfaces/
{{Para cada superficie:}}
    └── {{surface-name}}/ product-map.md · user-flows.md

{{Si se creó DS:}} docs/design-system/ inicializado con un scaffold por surface ({{N}} surfaces).

Todos los research-contexts en estado `hipótesis-preliminar`. Comenzando wireframes…
```

Continue immediately to Step 10.

---

### Step 10: Generate wireframes per surface

Detect all surfaces under **ux_surfaces_folder** that have both `product-map.md` and `user-flows.md`. Iterate over them in order. For each surface, execute steps 10.1 through 10.5.

#### 10.1 Read surface UX docs

For the current surface:

1. Read **ux_folder**/product-overview.md (cached)
2. Read **ux_surfaces_folder**/{surface}/product-map.md
3. Read **ux_surfaces_folder**/{surface}/user-flows.md
4. Read **ux_audiences_folder**/{audience}/research-context.md for each audience listed in the product-map

#### 10.2 Decide visual style for the surface

- **`accent_color`**: read product-overview.md to see if a brand color is mentioned. If not, default to `#2563eb`.
- **`grid_baseline`**: default 8.
- **`device`**: from product-overview default (mobile unless declared otherwise).

#### 10.3 Infer per-screen definitions

For each screen listed in the product-map's "Inventario de Pantallas":

**Identity:**
- `name`: kebab-case from screen name
- `route`: from product-map
- `device`: surface device
- `audiences`: from product-map (single or co-primary)

**Blocks:** infer from the screen's "Propósito" cell + descriptive notes. For each block decide:
- `type` from the dictionary
- `category` (informative)
- `content` — the **real text** rendered
- `variant` — for buttons (primary/secondary/disabled/...)
- `level` — for headings (h1/h2/h3) and paragraphs (body/caption)
- `kind` — for alerts (error/warning/info/success)
- `icon` — when applicable, name from the Unicode map
- `aspect_ratio` — for images
- `items` — for lists
- `annotation` — inline behavior note when needed
- `hidden_in_states` / `visible_only_in_states` / `state_overrides` — when a block should appear or behave differently per state

**Overlays:** if the product-map has an "Inventario de Overlays" section, include each overlay as a screen object with `"overlay": true`, `"overlay_type"`, and `"triggered_by"`.

**Applicable states:** evaluate each of the 8 fixed states. For each applicable, declare:
- The actual user-facing message
- Which blocks change and HOW (using `state_overrides`, `hidden_in_states`, or `visible_only_in_states`)

**Transitions:** from user-flows.md, extract user-driven and automatic transitions. For each transition:
- `src`, `dst` (matching screen `name`s)
- `srcState` (default unless trigger lives in a non-default state)
- `srcBlock` — the block name that triggers the transition
- Short `trigger` text (4-6 words)
- `automatic` boolean

#### 10.4 Generate per-screen `.md` files

For each screen (including overlays), generate `docs/ux/surfaces/{surface}/screens/{screen-name}.md` following the screen-mid template.

```yaml
fidelity:
  visuals: mid
  content: mid
  interactivity: low
```

All template sections present. `Contenido` filled with real text. `Estados` filled with real messages. `Interacciones` populated. `Specs visuales` empty. `Accesibilidad` partial. `Decisiones y descartes` mandatory.

#### 10.5 Generate Excalidraw (two stages)

**10.5.a Produce canonical `screens.json`**

Write a JSON to `/tmp/wireframes-{surface}-{timestamp}.json` following `scripts/SCHEMA.md`. Include:
- `surface`, `device`, `accent_color`, `grid_baseline`
- `screens[]` with full block/state info from the `.md` (overlays last, with `overlay: true`)
- `transitions[]` with `srcBlock` declared

**10.5.b Render frames + emit coords**

```bash
python3 .claude/skills/product-ux-wireframes/scripts/build_wireframes.py \
  /tmp/wireframes-{surface}-{timestamp}.json \
  docs/ux/surfaces/{surface}/wireframes.excalidraw \
  /tmp/wireframes-{surface}-coords.json
```

**10.5.c Decide arrow layout, write `arrows.json`**

Read `coords.json` and the `transitions` list. For each transition or group of transitions from the same `srcBlock`:

**Group transitions by `(src, srcState, srcBlock)`**:
- N=1: emit individual `arrow` + `circle` + `label`
- N≥2: emit one `group` (fork-style)

For each individual transition (N=1):
1. **Arrow** — anchor `from` to source block right edge: `(block.x + block.width, block.y + block.height/2)`. End at `(frame.x + frame.width + gutter_x - 28 - 16, anchor_y)`. `dashed: true` if automatic.
2. **Circle** — at the arrow's `to` point, `y = arrow_to.y - 14`. `number`: `coords.screen_numbers[transition.dst]` (or `coords.overlay_numbers[transition.dst]` for overlays).
3. **Label** — below the arrow, `width: 88`, font 10, color `#495057`, with the short trigger.

For each group (N≥2):
- `from`: `(block.x + block.width, block.y + block.height/2)`
- `fork_at_x`: `from.x + 50`
- `circle_x`: `frame.x + frame.width + gutter_x - 28 - 16`
- `destinations`: list of `{number, label}` per transition
- `dashed`: `true` if ALL transitions are automatic; `false` otherwise

**Anti-collision:**
- Sort blocks top-down. Ensure consecutive arrows from different blocks have ≥36px vertical separation. If not, push the lower one down.
- If a group's last destination would push outside the frame, drop the lowest-priority destination (it stays in the `.md` only).

Write `arrows.json` to `/tmp/wireframes-{surface}-arrows.json`.

**10.5.d Append arrows**

```bash
python3 .claude/skills/product-ux-wireframes/scripts/add_arrows.py \
  docs/ux/surfaces/{surface}/wireframes.excalidraw \
  /tmp/wireframes-{surface}-arrows.json
```

**Do NOT** read the generated `.excalidraw` into context — it's 1000+ elements.

---

### Step 11: Wireframes summary — wait for feedback

After all surfaces are processed:

```markdown
Wireframes mid-fi generados.

**{surface-1}:**
- {N} pantallas: {pantalla-1}, {pantalla-2}, ...
- {M} estados representados
- Accent color: {color hex}
- Archivos:
  - `docs/ux/surfaces/{surface-1}/screens/*.md` ({N} archivos)
  - `docs/ux/surfaces/{surface-1}/wireframes.excalidraw`

**{surface-2}:** …

Para abrir el `.excalidraw`:
1. Ir a https://excalidraw.com
2. Menu → Open → seleccionar el archivo

**Revisá los wireframes y decime si está correcto o querés cambios.**
```

**WAIT for user response.**

**If the user requests changes:**

1. Identify scope — ¿qué pantalla(s)/superficie(s) afecta?
2. Edit the relevant screen `.md` files (the `.md` is the source of truth)
3. For each affected surface, run all four sub-steps again (10.5.a → 10.5.d)
4. Notify and wait again:

```markdown
Cambios aplicados:
- {Cambio 1}
- {Cambio 2}

Archivos modificados:
- {paths}

**Revisá los cambios y decime si ahora está correcto o querés ajustar algo más.**
```

**Repeat until the user confirms.**

---

## Output

Files saved on completion:

**UX documentation** (under **ux_folder**):
- `docs/ux/product-overview.md`
- `docs/ux/audiences/{audience}/benchmark.md` (one per audience)
- `docs/ux/audiences/{audience}/research-context.md` (one per audience)
- `docs/ux/surfaces/{surface}/product-map.md` (one per surface)
- `docs/ux/surfaces/{surface}/user-flows.md` (one per surface)
- `docs/ux/cross-surface-flows.md`

**Wireframes** (under **ux_surfaces_folder**):
- `docs/ux/surfaces/{surface}/screens/{screen-name}.md` — Per screen at mid-fi:
  - Frontmatter with `fidelity: visuals: mid, content: mid, interactivity: low` and `accent_color`
  - Identidad, Entrada/Salida, Estructura (with variant + visibility columns)
  - Contenido with REAL microcopy per block
  - Estados with REAL user-facing messages
  - Interacciones populated
  - Specs visuales: "Pendiente — high-fi"
  - Accesibilidad: partial
  - Decisiones y descartes (mandatory)
- `docs/ux/surfaces/{surface}/wireframes.excalidraw` — One per surface:
  - Title + legend
  - Grid: rows = screens, columns = states
  - Overlays in dedicated section below the main grid
  - Block variants visually distinguishable
  - Icons rendered as Unicode glyphs
  - Annotations as inline gray notes
  - Arrows (numbered destinations, fork-style for multi-destination)

**Design System scaffold** (under `docs/design-system/`, only on first run):
- `docs/design-system/README.md` — root index linking to each surface's DS
- One folder per surface (`docs/design-system/{surface}/`) with its complete scaffold:
  - README.md, CHANGELOG.md, governance.md (versioning is independent per surface)
  - foundations/ (color, typography, spacing, grid, iconography, motion, elevation, voice-tone)
  - tokens/ (reference, semantic, component)
  - components/ (empty — to fill via `/product-design-system-update`)
  - patterns/ (empty — to fill)
  - guidelines/ (accessibility, i18n, content)

All documents:
- Frontmatter with metadata
- Language matches PRD
- Status indicating draft / hipótesis-preliminar
- Traceability to PRD / benchmark / input-cliente

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
