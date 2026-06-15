# Excalidraw Wireframe Generator Scripts (mid-fi)

Two-stage pipeline for generating mid-fi wireframes. Stage 1 is fully deterministic (frames + blocks + variants + states). Stage 2 is agent-driven (arrows + labels + destination circles), because per-transition layout decisions need contextual judgment.

Mid-fi vs low-fi extensions:
- Block variants (button: primary/secondary/disabled; input: default/focused/error)
- Real content (microcopy, headings, error messages declared in screens.json)
- Icons by name with Unicode mapping (search → 🔍, check → ✓, etc.)
- Surface-level accent color (applied to primary buttons, focused inputs, links)
- Annotations as inline gray notes below blocks
- Heading hierarchy (h1/h2/h3)

## Files

| File | Responsibility |
|------|----------------|
| `excalidraw_lib.py` | Primitives, block builders for the 36-type dictionary, output writer |
| `build_wireframes.py` | Stage 1: reads `screens.json` → emits `.excalidraw` (no arrows) + `coords.json` |
| `add_arrows.py` | Stage 2: reads `arrows.json` → appends elements to existing `.excalidraw` |
| `SCHEMA.md` | Full schemas for `screens.json`, `coords.json`, `arrows.json` |

## Architecture

```
docs/ux/surfaces/{surface}/screens/*.md   (human-readable, free-format)
docs/ux/surfaces/{surface}/user-flows.md
                ↓
        [agent: Claude reads & interprets]
                ↓
        /tmp/wireframes-{surface}-{ts}.json   (canonical screens.json)
                ↓
        [build_wireframes.py: deterministic frames + blocks]
                ↓
docs/ux/surfaces/{surface}/wireframes.excalidraw   (no arrows yet)
        +
        /tmp/wireframes-{surface}-coords.json   (frame/block positions)
                ↓
        [agent: reads coords.json + transitions, decides arrow layout]
                ↓
        /tmp/wireframes-{surface}-arrows.json
                ↓
        [add_arrows.py: appends elements]
                ↓
docs/ux/surfaces/{surface}/wireframes.excalidraw   (final, with arrows)
```

## Why two stages

Frames and blocks have a deterministic layout: a header is always at the top, blocks cascade vertically inside the frame, gutters are fixed. A script does this perfectly.

Arrows are different. Each transition needs:
- A specific Y position anchored to the block that triggers it
- A label width that fits in the gutter without invading neighboring frames or circles
- Anti-collision when multiple arrows share a similar Y
- Trigger text shortening when the source description is too long
- Sometimes prioritization (skip rendering corner cases that clutter the canvas)

These decisions are contextual. The agent has full canvas context (via `coords.json`) and can pick values per transition. The script just appends what the agent decides.

## Usage

### Stage 1 — build canvas

```bash
python3 build_wireframes.py <screens_json> <output_excalidraw> <output_coords_json>
```

Example:
```bash
python3 build_wireframes.py \
  /tmp/wireframes-web-11.json \
  docs/ux/surfaces/web-11/wireframes.excalidraw \
  /tmp/wireframes-web-11-coords.json
```

### Stage 2 — add arrows

```bash
python3 add_arrows.py <excalidraw_path> <arrows_json>
```

Example:
```bash
python3 add_arrows.py \
  docs/ux/surfaces/web-11/wireframes.excalidraw \
  /tmp/wireframes-web-11-arrows.json
```

The `add_arrows.py` script appends to the existing file in place.

## Layout rules (script-side, fixed)

- **Rows** = screens (vertical), order = order in `screens` array
- **Columns** = applicable states (horizontal), `default` always at column 0
- **Frame size**: `400×800` if `device` is `mobile`, `1200×800` if `desktop`
- **Gutters**: 140px between states, 120px between screens
- **Title + legend** above the grid (negative `y` coordinate)
- **Row label**: `{N} · {displayName}` to the left of each row, where `N` is the screen's number

## Suggested layout rules (agent-side, for arrows)

These are guidelines, not enforcement. The agent applies judgment:

1. **Anchor arrows to the source block** — read the block's `(x, y, width, height)` from `coords.json` and position the arrow start at `(block.x + block.width, block.y + block.height/2)`.
2. **Arrow length** — typically `gutter_x - circle_size - 2*padding ≈ 90px`. End at `frame_x + frame_w + gutter_x - 28 - 16` for the standard gutter.
3. **Destination circle** — diameter 28, positioned right after the arrow tip, with `~16px` padding before the next frame.
4. **Trigger label** — small font (10px), placed BELOW the arrow, with `width` constrained to `gutter_x - circle_size - padding ≈ 88px`. Truncate the trigger text if needed (4-6 words max).
5. **Anti-collision** — when multiple transitions share the same source block, stack them vertically with ~32-40px offset. Drop transitions that don't fit gracefully — they remain documented in the screen `.md`.
6. **Solid vs dashed** — solid for user-driven, dashed for `automatic: true`.
7. **Numbers in circles** — use `screen_numbers[dst]` to keep the circle synced with the row label.

## State conventions (script-side, automatic)

The script applies these overrides when rendering non-default state frames:

| State | Effect |
|-------|--------|
| `default` | Full layout from blocks |
| `loading` | Replaces content with loader skeleton |
| `empty` | Same blocks, primary action disabled |
| `error de validación` | Inserts red alert after header |
| `error de sistema` / `sin conexión` | Red alert "Sin conexión" after header |
| `success` | Blue info alert "✓ Acción confirmada" |
| `not found` | Replaces content with empty-state |
| `terminal` / `readonly` | Blue info alert "Inmutable · readonly" |
| `permiso denegado` | Replaces content with "Acceso denegado" empty-state |

## Failure mode

Both scripts fail hard on schema violations (exit code 1, message to stderr).

`build_wireframes.py`:
- Missing required top-level key (`surface`, `device`, `screens`)
- `screens` or `states` empty
- Block missing `name` or `type`
- `device` invalid

`add_arrows.py`:
- Missing target file or arrows JSON
- Element entry missing required keys (`from`/`to`, `text`, `number`)

Unknown block types in `screens.json` do **not** fail — they render as `[type] {name}` so the issue is visible without breaking the build.

## Extending

- **Add a new block type** — add a builder in `excalidraw_lib.py`, register in `render_block()` dispatch, add to `BLOCK_TYPES`, update the dictionary in SKILL.md.
- **Change frame sizes / gutters** — edit constants at top of `excalidraw_lib.py`.
- **Customize state overrides** — edit `state_overrides()` in `build_wireframes.py`.
- **Schema changes** — update validators and document in `SCHEMA.md`.
