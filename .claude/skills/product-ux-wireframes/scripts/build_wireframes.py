"""Build wireframes-low.excalidraw for a surface, from a canonical screens.json.

Usage:
    python3 build_wireframes.py <screens_json> <output_excalidraw> <output_coords_json>

Generates the wireframe canvas (frames + blocks + states) WITHOUT transitions/arrows.
Arrows are added in a second pass by `add_arrows.py`, after the agent decides
positions per-transition based on the emitted coords.json.

The coords.json contains:
- `frames`: position and size of each frame (per screen × state)
- `blocks`: position of each block within each frame
- `screen_numbers`: 1..N numeric label for each screen
- `display_names`: pretty names per screen
- `frame_w`, `frame_h`, `gutter_x`, `gutter_y`: layout constants
- `transitions`: list copied from screens.json so the agent has full context

Layout:
    - Rows = screens (vertical), columns = applicable states (horizontal)
    - Default state always at column 0
    - Title + legend above the grid

Fails hard on schema violations.
"""
import datetime
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from excalidraw_lib import (  # noqa: E402
    FRAME_W_MOBILE, FRAME_H_MOBILE, FRAME_W_DESKTOP, FRAME_H_DESKTOP,
    GUTTER_X, GUTTER_Y, ROW_LABEL_X, TITLE_Y, LEGEND_Y, ROW_START_Y, COL_START_X,
    STROKE, PLACEHOLDER, ERROR, INFO, DISABLED,
    rectangle, ellipse, line, text, frame, arrow,
    header, footer, alert_block, loader_block, empty_state_block,
    render_block, write_excalidraw,
)


def fail(msg):
    print(f"[build_wireframes] ERROR: {msg}", file=sys.stderr)
    sys.exit(1)


def validate(data):
    if not isinstance(data, dict):
        fail("Root must be an object")
    for k in ("surface", "device", "screens"):
        if k not in data:
            fail(f"Missing required key: {k}")
    if data["device"] not in ("mobile", "desktop", "tablet"):
        fail(f"Invalid device: {data['device']} (must be mobile/desktop/tablet)")
    if not isinstance(data["screens"], list) or not data["screens"]:
        fail("'screens' must be a non-empty list")
    for i, scr in enumerate(data["screens"]):
        ctx = f"screens[{i}]"
        for k in ("name", "displayName", "blocks", "states"):
            if k not in scr:
                fail(f"{ctx}: missing required key '{k}'")
        if not isinstance(scr["blocks"], list):
            fail(f"{ctx}: 'blocks' must be a list")
        for j, b in enumerate(scr["blocks"]):
            for bk in ("name", "type"):
                if bk not in b:
                    fail(f"{ctx}.blocks[{j}]: missing required key '{bk}'")
        if not isinstance(scr["states"], list) or not scr["states"]:
            fail(f"{ctx}: 'states' must be a non-empty list")
        for j, st in enumerate(scr["states"]):
            for sk in ("name", "applies"):
                if sk not in st:
                    fail(f"{ctx}.states[{j}]: missing required key '{sk}'")
            if not isinstance(st["applies"], bool):
                fail(f"{ctx}.states[{j}].applies must be boolean")


def state_overrides(items, state, fx, fy, frame_w, frame_h, header_items):
    state_lower = state.lower()
    if state_lower == "loading":
        return header_items + loader_block(fx, fy + 90, frame_w) + footer(fx, fy, frame_w, frame_h)
    if state_lower in ("not found", "permiso denegado", "permiso/acceso denegado"):
        msg_heading = "No encontrado" if state_lower == "not found" else "Acceso denegado"
        msg_para = ("El recurso no existe o el link es inválido"
                    if state_lower == "not found"
                    else "No tenés permisos para ver esta pantalla")
        return header_items + empty_state_block(fx, fy + 90, msg_heading, msg_para, frame_w) \
               + footer(fx, fy, frame_w, frame_h)
    if state_lower in ("error de validación", "error de validacion"):
        items = list(items)
        items[len(header_items):len(header_items)] = alert_block(fx, fy + 70, "Error de validación", frame_w, color=ERROR)
        return items
    if state_lower in ("error de sistema", "error de sistema / sin conexión", "sin conexión"):
        items = list(items)
        items[len(header_items):len(header_items)] = alert_block(fx, fy + 70, "Sin conexión · reintentando…", frame_w, color=ERROR)
        return items
    if state_lower in ("estado terminal", "readonly", "estado terminal / readonly", "terminal"):
        items = list(items)
        items[len(header_items):len(header_items)] = alert_block(fx, fy + 70, "Inmutable · readonly", frame_w, color=INFO)
        return items
    if state_lower == "empty":
        out = []
        replaced_one = False
        for it in items:
            if (not replaced_one and it.get("type") == "rectangle"
                    and it.get("roundness") and it.get("strokeColor") == STROKE):
                it = dict(it)
                it["strokeColor"] = DISABLED
                replaced_one = True
            out.append(it)
        return out
    if state_lower == "success":
        items = list(items)
        items[len(header_items):len(header_items)] = alert_block(fx, fy + 70, "✓ Acción confirmada", frame_w, color=INFO)
        return items
    return items


def block_opts(b, accent_color):
    """Extract render_block opts from a block dict in screens.json.

    Recognized fields from the block: variant, state, level, kind, icon,
    value, error_msg, aspect_ratio, items, options, labels, active, annotation,
    on, checked, selected, lines, items_count, fill, h, w, size, name (for icon block).
    """
    opts = {"accent_color": accent_color}
    for key in (
        "variant", "state", "level", "kind", "icon",
        "value", "error_msg", "aspect_ratio", "items", "options", "labels",
        "active", "annotation", "on", "checked", "selected",
        "lines", "items_count", "fill", "h", "w", "size", "name",
    ):
        if key in b:
            opts[key] = b[key]
    return opts


def render_screen(screen, fx, fy, fid, state, frame_w, frame_h, accent_color=None):
    """Render one screen at given (fx, fy) for a given state.

    Returns (items, block_dims) where block_dims[block_name] is a dict
    with x, y, width, height of the block (absolute canvas coords).
    """
    items = []
    block_dims = {}

    header_block = next((b for b in screen["blocks"] if b["type"] == "header"), None)
    h_label = (header_block.get("content") or header_block.get("name")) if header_block else screen["displayName"]
    h_icon = header_block.get("icon") if header_block else None
    h, ynext = header(fx, fy, frame_w, label=h_label, icon=h_icon)
    header_items = h
    items += h
    if header_block:
        block_dims[header_block["name"]] = {
            "x": fx + 10, "y": fy + 10, "width": frame_w - 20, "height": 50,
        }

    y = ynext + 20
    state_lower = state.lower()
    for b in screen["blocks"]:
        if b["type"] in ("header", "footer"):
            continue
        hidden = b.get("hidden_in_states", [])
        if state_lower in [s.lower() for s in hidden]:
            continue
        visible_only = b.get("visible_only_in_states", [])
        if visible_only and state_lower not in [s.lower() for s in visible_only]:
            continue
        overrides = b.get("state_overrides", {})
        effective_b = {**b, **overrides.get(state, {})}
        # also try lowercase state name for robustness
        if state not in overrides:
            for k in overrides:
                if k.lower() == state_lower:
                    effective_b = {**b, **overrides[k]}
                    break
        block_top = y
        opts = block_opts(effective_b, accent_color)
        block_items, h_used = render_block(
            effective_b["type"], fx, y, frame_w, frame_h,
            content=effective_b.get("content") or effective_b["name"],
            **opts,
        )
        items += block_items
        block_dims[b["name"]] = {
            "x": fx + 20, "y": block_top, "width": frame_w - 40, "height": max(20, h_used - 10),
        }
        y += h_used
        if y > fy + frame_h - 80:
            break

    items += footer(fx, fy, frame_w, frame_h)

    if state.lower() != "default":
        items = state_overrides(items, state, fx, fy, frame_w, frame_h, header_items)

    return items, block_dims


def build(json_path, output_path, coords_path):
    if not os.path.exists(json_path):
        fail(f"Input JSON not found: {json_path}")

    with open(json_path, encoding="utf-8") as f:
        data = json.load(f)

    validate(data)

    surface = data["surface"]
    device = data["device"].lower()
    screens = data["screens"]
    transitions = data.get("transitions", [])
    accent_color = data.get("accent_color")  # mid-fi: surface-level accent

    if device == "desktop":
        frame_w, frame_h = FRAME_W_DESKTOP, FRAME_H_DESKTOP
    else:
        frame_w, frame_h = FRAME_W_MOBILE, FRAME_H_MOBILE

    elements = []
    today = datetime.date.today().isoformat()

    # Title + legend
    elements.append(text(0, TITLE_Y, f"Wireframes Mid-Fi · {surface} · {today}", fontSize=32, w=900))
    legend_box = rectangle(0, LEGEND_Y, 600, 100, strokeColor="#495057", strokeWidth=1, roughness=0)
    elements.append(legend_box)
    elements.append(text(16, LEGEND_Y + 12, "Leyenda", fontSize=18, w=120))
    elements.append(line([[0, 0], [60, 0]], x=24, y=LEGEND_Y + 50))
    elements.append(text(100, LEGEND_Y + 42, "transición user-driven (click, input, gesto)", fontSize=14, w=500))
    elements.append(line([[0, 0], [60, 0]], x=24, y=LEGEND_Y + 78, strokeStyle="dashed"))
    elements.append(text(100, LEGEND_Y + 70, "transición automática (post-acción, timeout, redirect)", fontSize=14, w=500))

    # Frame index for coords export
    coords_frames = {}
    coords_blocks = {}
    normal_screens = [s for s in screens if not s.get("overlay")]
    overlay_screens = [s for s in screens if s.get("overlay")]
    display_names = {scr["name"]: scr["displayName"] for scr in screens}
    screen_numbers = {scr["name"]: i + 1 for i, scr in enumerate(normal_screens)}
    # overlays get O-prefixed numbers
    overlay_numbers = {scr["name"]: f"O-{i + 1:02d}" for i, scr in enumerate(overlay_screens)}

    def render_one_screen(scr, row_fy, col_start_x, label_x, num_label):
        ordered_states = []
        for st in scr["states"]:
            if not st["applies"]:
                continue
            if st["name"].lower() == "default":
                ordered_states.insert(0, st)
            else:
                ordered_states.append(st)

        elements.append(text(label_x, row_fy + frame_h / 2,
                             num_label, fontSize=18, w=240))

        for col, st in enumerate(ordered_states):
            fx = col_start_x + col * (frame_w + GUTTER_X)
            fr = frame(fx, row_fy, frame_w, frame_h, f"{scr['displayName']} - {st['name']}")
            elements.append(fr)

            content, block_dims = render_screen(scr, fx, row_fy, fr["id"], st["name"], frame_w, frame_h, accent_color=accent_color)
            for it in content:
                it["frameId"] = fr["id"]
            elements.extend(content)

            frame_key = f"{scr['name']}__{st['name']}"
            coords_frames[frame_key] = {
                "screen": scr["name"], "state": st["name"],
                "x": fx, "y": row_fy, "width": frame_w, "height": frame_h,
                "frameId": fr["id"],
                "overlay": scr.get("overlay", False),
                "overlay_type": scr.get("overlay_type"),
                "triggered_by": scr.get("triggered_by"),
            }
            if st["name"].lower() == "default":
                coords_blocks[scr["name"]] = block_dims

    # --- Render normal screens in row grid ---
    for row, scr in enumerate(normal_screens):
        fy = ROW_START_Y + row * (frame_h + GUTTER_Y)
        num = screen_numbers[scr["name"]]
        render_one_screen(scr, fy, COL_START_X, ROW_LABEL_X, f"{num} · {scr['displayName']}")

    # --- Render overlays in a separate section below the main grid ---
    if overlay_screens:
        overlay_section_y = ROW_START_Y + len(normal_screens) * (frame_h + GUTTER_Y) + GUTTER_Y * 2
        elements.append(text(ROW_LABEL_X, overlay_section_y - 60,
                             "Overlays (drawers · modals · bottom-sheets)", fontSize=20, w=700))
        elements.append(line([[0, 0], [700, 0]], x=ROW_LABEL_X, y=overlay_section_y - 30, strokeStyle="dashed"))
        for row, scr in enumerate(overlay_screens):
            ov_type = scr.get("overlay_type", "overlay")
            triggered = scr.get("triggered_by", "")
            num_label = f"{overlay_numbers[scr['name']]} [{ov_type}] · {scr['displayName']}"
            if triggered and triggered in screen_numbers:
                num_label += f" → desde pantalla {screen_numbers[triggered]}"
            fy = overlay_section_y + row * (frame_h + GUTTER_Y)
            render_one_screen(scr, fy, COL_START_X, ROW_LABEL_X, num_label)

    write_excalidraw(elements, output_path)

    coords = {
        "surface": surface,
        "device": device,
        "accent_color": accent_color,
        "grid_baseline": data.get("grid_baseline", 8),
        "frame_w": frame_w,
        "frame_h": frame_h,
        "gutter_x": GUTTER_X,
        "gutter_y": GUTTER_Y,
        "row_start_y": ROW_START_Y,
        "col_start_x": COL_START_X,
        "screen_numbers": screen_numbers,
        "overlay_numbers": overlay_numbers,
        "display_names": display_names,
        "frames": coords_frames,
        "blocks": coords_blocks,
        "transitions": transitions,
    }
    with open(coords_path, "w", encoding="utf-8") as f:
        json.dump(coords, f, indent=2, ensure_ascii=False)

    print(f"Wrote {output_path} with {len(elements)} elements.")
    print(f"Wrote {coords_path} ({len(coords_frames)} frames, {len(coords_blocks)} screens with block coords).")
    return output_path


if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: build_wireframes.py <screens_json> <output_excalidraw> <output_coords_json>", file=sys.stderr)
        sys.exit(1)
    build(sys.argv[1], sys.argv[2], sys.argv[3])
