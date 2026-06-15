"""Excalidraw mid-fi wireframe library.

Provides primitives, block builders (36-type dictionary with variants),
icon Unicode mapping, layout helpers, and JSON output for mid-fidelity
hand-drawn wireframes. Used by build_wireframes.py.

Mid-fi extensions vs low-fi:
- Block variants (button: primary/secondary/tertiary/disabled; input: default/focused/error)
- Real content (microcopy, headings, error messages — declared in screens.json)
- Icons by name (Unicode mapping with fallback to [icon-name] text)
- Single accent color per surface (applied to primary buttons, focused inputs, etc.)
- Annotations as inline notes below blocks
- Heading hierarchy (h1/h2/h3 with size/weight)

Conventions:
- All primitives return dicts with valid Excalidraw JSON structure.
- All block builders return LISTS of elements (even single-element ones).
- Coordinates are absolute (canvas-space). Block builders take fx/fy/y arguments.
- Hand-drawn style: roughness=1, fontFamily=1 (Virgil), strokeColor #1e1e1e.
"""
import json
import random
import string


# ---- Config / palette ----
FRAME_W_MOBILE = 400
FRAME_H_MOBILE = 800
FRAME_W_DESKTOP = 1200
FRAME_H_DESKTOP = 800
GUTTER_X = 140
GUTTER_Y = 120
ROW_LABEL_X = -260
TITLE_Y = -260
LEGEND_Y = -200
ROW_START_Y = 0
COL_START_X = 0

STROKE = "#1e1e1e"
PLACEHOLDER = "#868e96"
ERROR = "#e03131"
INFO = "#1971c2"
SUCCESS = "#2f9e44"
WARNING = "#f08c00"
DISABLED = "#adb5bd"
TRANSPARENT = "transparent"

# Default accent color (overridden per-surface via screens.json's accent_color)
DEFAULT_ACCENT = "#2563eb"


# ---- Icon name → Unicode mapping ----
# When the agent declares an `icon: <name>` on a block, the script renders the
# corresponding Unicode glyph if known, else falls back to "[name]" as text.
ICON_MAP = {
    "search": "🔍",
    "menu": "☰",
    "close": "✕",
    "x": "✕",
    "check": "✓",
    "checkmark": "✓",
    "plus": "+",
    "minus": "−",
    "arrow-up": "↑",
    "arrow-down": "↓",
    "arrow-left": "←",
    "arrow-right": "→",
    "chevron-down": "▾",
    "chevron-up": "▴",
    "chevron-left": "◂",
    "chevron-right": "▸",
    "home": "⌂",
    "user": "☻",
    "users": "☻☻",
    "settings": "⚙",
    "edit": "✎",
    "trash": "🗑",
    "delete": "🗑",
    "heart": "♥",
    "star": "★",
    "info": "ⓘ",
    "warning": "⚠",
    "error": "⚠",
    "alert": "⚠",
    "success": "✓",
    "more": "⋯",
    "calendar": "📅",
    "clock": "🕐",
    "time": "🕐",
    "image": "🖼",
    "file": "📄",
    "folder": "📁",
    "link": "🔗",
    "share": "↗",
    "download": "⤓",
    "upload": "⤒",
    "refresh": "↻",
    "eye": "👁",
    "eye-off": "🚫",
    "lock": "🔒",
    "unlock": "🔓",
    "filter": "▼",
    "sort": "⇅",
    "play": "▶",
    "pause": "⏸",
    "stop": "■",
    "mail": "✉",
    "phone": "✆",
    "bell": "🔔",
    "notification": "🔔",
    "message": "💬",
    "comment": "💬",
}


def render_icon(name):
    """Map an icon name to its Unicode glyph or fallback to [name] text."""
    if not name:
        return ""
    n = name.lower().strip()
    return ICON_MAP.get(n, f"[{n}]")


# ---- Primitives ----

def nid(n=21):
    """Generate a nanoid-style id (21 url-safe chars)."""
    return "".join(random.choices(string.ascii_letters + string.digits + "-_", k=n))


def base_props():
    return {
        "angle": 0,
        "strokeColor": STROKE,
        "backgroundColor": "transparent",
        "fillStyle": "solid",
        "strokeWidth": 2,
        "strokeStyle": "solid",
        "roughness": 1,
        "opacity": 100,
        "groupIds": [],
        "frameId": None,
        "roundness": None,
        "seed": random.randint(1, 2**31),
        "version": 1,
        "versionNonce": random.randint(1, 2**31),
        "isDeleted": False,
        "boundElements": [],
        "updated": 1,
        "link": None,
        "locked": False,
    }


def rectangle(x, y, w, h, **kw):
    el = base_props()
    el.update({"id": nid(), "type": "rectangle", "x": x, "y": y, "width": w, "height": h})
    el.update(kw)
    return el


def ellipse(x, y, w, h, **kw):
    el = base_props()
    el.update({"id": nid(), "type": "ellipse", "x": x, "y": y, "width": w, "height": h})
    el.update(kw)
    return el


def line(points, x=0, y=0, **kw):
    el = base_props()
    xs = [p[0] for p in points] or [0]
    ys = [p[1] for p in points] or [0]
    el.update({
        "id": nid(),
        "type": "line",
        "x": x, "y": y,
        "width": max(xs) - min(xs),
        "height": max(ys) - min(ys),
        "points": points,
        "lastCommittedPoint": None,
        "startBinding": None,
        "endBinding": None,
        "startArrowhead": None,
        "endArrowhead": None,
    })
    el.update(kw)
    return el


def text(x, y, content, fontSize=14, color=STROKE, w=None, h=None, align="left", **kw):
    if w is None:
        w = max(40, int(fontSize * 0.6 * len(content)))
    if h is None:
        h = int(fontSize * 1.4)
    el = base_props()
    el.update({
        "id": nid(),
        "type": "text",
        "x": x, "y": y, "width": w, "height": h,
        "strokeColor": color,
        "fontSize": fontSize,
        "fontFamily": 1,
        "text": content,
        "originalText": content,
        "textAlign": align,
        "verticalAlign": "top",
        "containerId": None,
        "lineHeight": 1.25,
        "baseline": int(fontSize * 1.05),
    })
    el.update(kw)
    return el


def frame(x, y, w, h, name):
    el = base_props()
    el.update({
        "id": nid(),
        "type": "frame",
        "x": x, "y": y, "width": w, "height": h,
        "name": name,
        "strokeColor": "#bbb",
        "strokeWidth": 1,
        "roughness": 0,
    })
    return el


def arrow(p1, p2, dashed=False, color=STROKE, label=None):
    points = [[0, 0], [p2[0] - p1[0], p2[1] - p1[1]]]
    el = base_props()
    el.update({
        "id": nid(),
        "type": "arrow",
        "x": p1[0], "y": p1[1],
        "width": abs(p2[0] - p1[0]),
        "height": abs(p2[1] - p1[1]),
        "points": points,
        "lastCommittedPoint": None,
        "startBinding": None,
        "endBinding": None,
        "startArrowhead": None,
        "endArrowhead": "arrow",
        "strokeColor": color,
        "strokeStyle": "dashed" if dashed else "solid",
        "roughness": 1,
    })
    return el


# ---- Block builders (return lists, frame-relative coords need fx/fy) ----

def header(fx, fy, frame_w, label="Header", icon=None):
    """Header with optional left icon."""
    items = [rectangle(fx + 10, fy + 10, frame_w - 20, 50)]
    icon_glyph = render_icon(icon) if icon else ""
    text_x = fx + 25
    if icon_glyph:
        items.append(text(text_x, fy + 25, icon_glyph, fontSize=18))
        text_x += 28
    items.append(text(text_x, fy + 25, label, fontSize=18))
    return items, fy + 70


def annotation_block(fx, y, content, frame_w, indent=20):
    """Inline annotation: small italic-feel text below a block describing behavior.

    Renders as small placeholder-color text prefixed with a marker (»).
    """
    if not content:
        return []
    w = frame_w - 2 * indent
    return [text(fx + indent, y, f"» {content}", fontSize=10, color=PLACEHOLDER, w=w)]


def footer(fx, fy, frame_w, frame_h, label="footer"):
    return [
        rectangle(fx + 10, fy + frame_h - 50, frame_w - 20, 40),
        text(fx + 25, fy + frame_h - 40, label, fontSize=12, color=PLACEHOLDER),
    ]


def heading_block(fx, y, content, frame_w, level="h2", indent=20):
    """Heading with hierarchy (h1, h2, h3)."""
    sizes = {"h1": 28, "h2": 22, "h3": 18}
    fontSize = sizes.get(level.lower() if level else "h2", 22)
    return [text(fx + indent, y, content, fontSize=fontSize)]


def paragraph_block(fx, y, frame_w, content="", level="body", lines=2, indent=20):
    """Paragraph with optional real text. If content is given, render it; else lines."""
    w = frame_w - 2 * indent
    if content:
        # Render real text in body or caption size
        fontSize = 14 if level == "body" else 11
        color = STROKE if level == "body" else PLACEHOLDER
        return [text(fx + indent, y, content, fontSize=fontSize, color=color, w=w)]
    items = []
    for i in range(lines):
        ww = w if i < lines - 1 else int(w * 0.7)
        items.append(line([[0, 0], [ww, 0]], x=fx + indent, y=y + i * 16, strokeColor=STROKE))
    return items


def button_block(fx, y, label, frame_w, w=None, indent=20,
                 variant="primary", icon=None, accent_color=None):
    """Button with variants: primary (filled accent), secondary (outline), tertiary (text-only), disabled."""
    if w is None:
        w = frame_w - 2 * indent
    h = 44
    accent = accent_color or DEFAULT_ACCENT
    v = (variant or "primary").lower()

    # Compose label with optional icon prefix
    icon_glyph = render_icon(icon) if icon else ""
    full_label = f"{icon_glyph} {label}".strip() if icon_glyph else label

    if v == "primary":
        return [
            rectangle(fx + indent, y, w, h,
                      strokeColor=accent, backgroundColor=accent,
                      fillStyle="solid", roundness={"type": 3}),
            text(fx + indent + 10, y + 12, full_label, fontSize=16, color="#ffffff",
                 w=w - 20, align="center"),
        ]
    if v == "secondary":
        return [
            rectangle(fx + indent, y, w, h,
                      strokeColor=accent, roundness={"type": 3}),
            text(fx + indent + 10, y + 12, full_label, fontSize=16, color=accent,
                 w=w - 20, align="center"),
        ]
    if v == "tertiary":
        # Link-style: no border, just text in accent color
        return [
            text(fx + indent + 10, y + 12, full_label, fontSize=16, color=accent,
                 w=w - 20, align="center"),
        ]
    if v == "disabled":
        return [
            rectangle(fx + indent, y, w, h,
                      strokeColor=DISABLED, roundness={"type": 3}),
            text(fx + indent + 10, y + 12, full_label, fontSize=16, color=DISABLED,
                 w=w - 20, align="center"),
        ]
    if v == "error":
        return [
            rectangle(fx + indent, y, w, h,
                      strokeColor=ERROR, roundness={"type": 3}),
            text(fx + indent + 10, y + 12, full_label, fontSize=16, color=ERROR,
                 w=w - 20, align="center"),
        ]
    # Fallback: same as secondary
    return [
        rectangle(fx + indent, y, w, h, strokeColor=STROKE, roundness={"type": 3}),
        text(fx + indent + 10, y + 12, full_label, fontSize=16, color=STROKE,
             w=w - 20, align="center"),
    ]


def text_input_block(fx, y, placeholder, frame_w, indent=20, w=None,
                     state="default", value=None, error_msg=None,
                     icon=None, accent_color=None):
    """Text input with states: default, focused (accent border), error (red + msg), disabled."""
    if w is None:
        w = frame_w - 2 * indent
    accent = accent_color or DEFAULT_ACCENT
    s = (state or "default").lower()

    if s == "focused":
        border = accent
    elif s == "error":
        border = ERROR
    elif s == "disabled":
        border = DISABLED
    else:
        border = STROKE

    items = [rectangle(fx + indent, y, w, 44, strokeColor=border, roundness={"type": 3})]

    # Compose icon + content (placeholder or real value)
    icon_glyph = render_icon(icon) if icon else ""
    text_x = fx + indent + 10
    if icon_glyph:
        items.append(text(text_x, y + 13, icon_glyph, fontSize=14, color=PLACEHOLDER))
        text_x += 22

    if value:
        items.append(text(text_x, y + 13, value, fontSize=14, color=STROKE if s != "disabled" else DISABLED))
    elif placeholder:
        items.append(text(text_x, y + 13, placeholder, fontSize=14, color=PLACEHOLDER))

    # Error message below
    if s == "error" and error_msg:
        items.append(text(fx + indent, y + 50, error_msg, fontSize=11, color=ERROR, w=w))

    return items


def section_box(fx, y, h, frame_w, indent=20, label=None, w=None):
    if w is None:
        w = frame_w - 2 * indent
    items = [rectangle(fx + indent, y, w, h)]
    if label:
        items.append(text(fx + indent + 10, y + 8, label, fontSize=12, color=PLACEHOLDER))
    return items


def image_block(fx, y, h, frame_w, indent=20, label="imagen", w=None, aspect_ratio=None):
    """Image placeholder with X marks + descriptive label + optional aspect ratio note."""
    if w is None:
        w = frame_w - 2 * indent
    # Show label centered + aspect ratio in smaller text below
    label_text = label
    if aspect_ratio:
        label_text = f"{label} · {aspect_ratio}"
    return [
        rectangle(fx + indent, y, w, h),
        line([[0, 0], [w, h]], x=fx + indent, y=y),
        line([[0, 0], [w, -h]], x=fx + indent, y=y + h),
        text(fx + indent + 10, y + h / 2 - 8, label_text, fontSize=12, color=PLACEHOLDER, w=w - 20, align="center"),
    ]


def list_block(fx, y, frame_w, items_count=4, indent=20, w=None, items=None):
    """List of items. If `items` (list of dicts) is given, render real text per item.
    Each item dict can have: title (str), subtitle (str), icon (str)."""
    if w is None:
        w = frame_w - 2 * indent
    out = []
    n = len(items) if items else items_count
    for i in range(n):
        yy = y + i * 52
        # Thumbnail or icon
        if items and items[i].get("icon"):
            out.append(rectangle(fx + indent, yy, 40, 40))
            glyph = render_icon(items[i]["icon"])
            out.append(text(fx + indent + 12, yy + 10, glyph, fontSize=16))
        else:
            out.append(rectangle(fx + indent, yy, 40, 40))
        # Title + subtitle (real text or lines)
        if items and items[i].get("title"):
            out.append(text(fx + indent + 50, yy + 6, items[i]["title"], fontSize=14, w=w - 60))
            if items[i].get("subtitle"):
                out.append(text(fx + indent + 50, yy + 24, items[i]["subtitle"], fontSize=11, color=PLACEHOLDER, w=w - 60))
            else:
                out.append(line([[0, 0], [(w - 60) * 0.6, 0]], x=fx + indent + 50, y=yy + 28))
        else:
            out.append(line([[0, 0], [w - 60, 0]], x=fx + indent + 50, y=yy + 10))
            out.append(line([[0, 0], [(w - 60) * 0.6, 0]], x=fx + indent + 50, y=yy + 25))
    return out


def alert_block(fx, y, msg, frame_w, kind="error", color=None, indent=20, w=None, icon=None):
    """Alert with kinds: error (red), warning (orange), info (blue), success (green)."""
    if w is None:
        w = frame_w - 2 * indent
    if color is None:
        kind_lower = (kind or "error").lower()
        color = {
            "error": ERROR,
            "warning": WARNING,
            "info": INFO,
            "success": SUCCESS,
        }.get(kind_lower, ERROR)
    # Default icon by kind if not provided
    if icon is None:
        icon = {"error": "error", "warning": "warning", "info": "info", "success": "check"}.get(
            (kind or "error").lower(), None)
    icon_glyph = render_icon(icon) if icon else ""
    items = [rectangle(fx + indent, y, w, 44, strokeColor=color, roundness={"type": 3})]
    text_x = fx + indent + 10
    if icon_glyph:
        items.append(text(text_x, y + 13, icon_glyph, fontSize=14, color=color))
        text_x += 22
    items.append(text(text_x, y + 13, msg, fontSize=14, color=color, w=w - (text_x - fx - indent) - 10))
    return items


def loader_block(fx, y, frame_w, indent=20, w=None):
    if w is None:
        w = frame_w - 2 * indent
    items = []
    for i in range(3):
        ww = w if i < 2 else int(w * 0.7)
        items.append(line([[0, 0], [ww, 0]], x=fx + indent, y=y + i * 22,
                          strokeColor=PLACEHOLDER, strokeStyle="dashed"))
    items.append(text(fx + indent, y + 70, "Cargando…", fontSize=12, color=PLACEHOLDER))
    return items


def empty_state_block(fx, y, heading, paragraph, frame_w, indent=20, w=None):
    if w is None:
        w = frame_w - 2 * indent
    cx = fx + frame_w / 2
    return [
        ellipse(cx - 30, y, 60, 60),
        text(cx - 5, y + 18, "?", fontSize=24, color=PLACEHOLDER),
        text(fx + indent, y + 80, heading, fontSize=18, color=STROKE, w=w, align="center"),
        text(fx + indent, y + 110, paragraph, fontSize=12, color=PLACEHOLDER, w=w, align="center"),
    ]


def search_bar(fx, y, placeholder, frame_w, indent=20, w=None):
    if w is None:
        w = frame_w - 2 * indent
    return [
        rectangle(fx + indent, y, w, 44, roundness={"type": 3}),
        ellipse(fx + indent + 10, y + 12, 18, 18),
        text(fx + indent + 38, y + 13, placeholder, fontSize=14, color=PLACEHOLDER),
    ]


def badge_block(fx, y, label, w=120, indent=20):
    return [
        rectangle(fx + indent, y, w, 24, roundness={"type": 3}),
        text(fx + indent + 8, y + 5, label, fontSize=12, color=STROKE),
    ]


def progress_bar(fx, y, frame_w, fill=0.6, indent=20, w=None):
    if w is None:
        w = frame_w - 2 * indent
    return [
        rectangle(fx + indent, y, w, 16, roundness={"type": 3}),
        rectangle(fx + indent, y, int(w * fill), 16,
                  backgroundColor=STROKE, fillStyle="solid", roundness={"type": 3}),
    ]


def card_mini(fx, y, frame_w, indent=20, w=None):
    if w is None:
        w = (frame_w - 2 * indent - 10) / 2
    return [
        rectangle(fx + indent, y, w, 100),
        line([[0, 0], [w, 80]], x=fx + indent, y=y + 10),
        line([[0, 0], [w, -80]], x=fx + indent, y=y + 90),
        text(fx + indent + 8, y + 85, "card", fontSize=10, color=PLACEHOLDER),
    ]


def link_block(fx, y, label, indent=20, icon=None, accent_color=None):
    """Link rendered in accent color. Optional icon prefix."""
    accent = accent_color or DEFAULT_ACCENT
    icon_glyph = render_icon(icon) if icon else ""
    full_label = f"{icon_glyph} {label}".strip() if icon_glyph else label
    return [text(fx + indent, y, full_label, fontSize=14, color=accent)]


def nav_bar_block(fx, y, items_labels, frame_w, indent=20):
    """Horizontal nav bar with labels separated."""
    w = frame_w - 2 * indent
    items = [rectangle(fx + indent, y, w, 40)]
    if items_labels:
        slot = w / max(len(items_labels), 1)
        for i, lbl in enumerate(items_labels):
            items.append(text(fx + indent + i * slot + 8, y + 12, lbl, fontSize=14))
    return items


def tabs_block(fx, y, items_labels, frame_w, active=0, indent=20, accent_color=None):
    """Tabs with active tab in accent color + bottom border."""
    accent = accent_color or DEFAULT_ACCENT
    w = frame_w - 2 * indent
    items = []
    if items_labels:
        slot = w / max(len(items_labels), 1)
        for i, lbl in enumerate(items_labels):
            xx = fx + indent + i * slot
            color = accent if i == active else STROKE
            items.append(text(xx + 8, y + 8, lbl, fontSize=14, color=color))
            if i == active:
                items.append(line([[0, 0], [slot - 4, 0]], x=xx + 2, y=y + 32, strokeWidth=3, strokeColor=accent))
    return items


def modal_block(fx, y, frame_w, frame_h, title="Modal", indent=20):
    """Centered modal box with title."""
    w = frame_w - 2 * indent - 40
    h = 240
    mx = fx + (frame_w - w) / 2
    my = y
    return [
        rectangle(mx, my, w, h, strokeWidth=3, roundness={"type": 3}),
        text(mx + 16, my + 16, title, fontSize=18),
        line([[0, 0], [w, 0]], x=mx, y=my + 50, strokeColor=PLACEHOLDER),
    ]


def avatar_block(fx, y, indent=20, size=40):
    return [ellipse(fx + indent, y, size, size)]


def icon_block(fx, y, indent=20, size=24, glyph="●"):
    return [
        rectangle(fx + indent, y, size, size, roundness={"type": 3}),
        text(fx + indent + 4, y + 2, glyph, fontSize=16, color=PLACEHOLDER),
    ]


def toggle_block(fx, y, label="", on=True, indent=20):
    cx = fx + indent
    items = [rectangle(cx, y, 44, 24, roundness={"type": 3})]
    items.append(ellipse(cx + (22 if on else 2), y + 2, 20, 20, backgroundColor=STROKE, fillStyle="solid"))
    if label:
        items.append(text(cx + 56, y + 4, label, fontSize=14))
    return items


def checkbox_block(fx, y, label="", checked=False, indent=20):
    items = [rectangle(fx + indent, y, 20, 20)]
    if checked:
        items.append(text(fx + indent + 4, y + 2, "✓", fontSize=14))
    if label:
        items.append(text(fx + indent + 30, y + 2, label, fontSize=14))
    return items


def radio_block(fx, y, label="", selected=False, indent=20):
    items = [ellipse(fx + indent, y, 20, 20)]
    if selected:
        items.append(ellipse(fx + indent + 5, y + 5, 10, 10, backgroundColor=STROKE, fillStyle="solid"))
    if label:
        items.append(text(fx + indent + 30, y + 2, label, fontSize=14))
    return items


def dropdown_block(fx, y, label, frame_w, indent=20, w=None,
                   state="closed", options=None, accent_color=None):
    """Dropdown with state closed (default) or open (shows options below)."""
    if w is None:
        w = frame_w - 2 * indent
    accent = accent_color or DEFAULT_ACCENT
    s = (state or "closed").lower()
    border = accent if s == "open" else STROKE
    chevron = "▴" if s == "open" else "▾"

    items = [
        rectangle(fx + indent, y, w, 44, strokeColor=border, roundness={"type": 3}),
        text(fx + indent + 10, y + 13, label, fontSize=14, color=STROKE),
        text(fx + indent + w - 24, y + 13, chevron, fontSize=14),
    ]
    if s == "open" and options:
        # Render options dropdown below
        for i, opt in enumerate(options[:6]):  # cap at 6 visible
            row_y = y + 50 + i * 36
            items.append(rectangle(fx + indent, row_y, w, 32, strokeColor=PLACEHOLDER))
            items.append(text(fx + indent + 10, row_y + 8, str(opt), fontSize=14))
    return items


# ---- Output ----

def write_excalidraw(elements, path):
    """Serialize elements to a valid .excalidraw file."""
    doc = {
        "type": "excalidraw",
        "version": 2,
        "source": "https://excalidraw.com",
        "elements": elements,
        "appState": {"gridSize": None, "viewBackgroundColor": "#ffffff"},
        "files": {},
    }
    with open(path, "w", encoding="utf-8") as f:
        json.dump(doc, f, indent=2, ensure_ascii=False)


# ---- Block dispatch (used by build_wireframes.py to render by type) ----

BLOCK_TYPES = {
    "header", "footer", "sidebar", "main", "modal", "section",
    "nav-bar", "tabs", "link", "breadcrumbs", "pagination",
    "heading", "paragraph", "image", "icon", "list", "card", "table", "avatar", "badge", "chart",
    "text-input", "button", "dropdown", "checkbox", "radio", "toggle", "search-bar", "slider", "date-picker",
    "alert", "toast", "progress-bar", "tooltip", "empty-state", "loader",
}


def render_block(block_type, fx, y, frame_w, frame_h, content="", **opts):
    """Render a block by type, returning (items, height_consumed).

    Supported opts (mid-fi):
        variant: primary | secondary | tertiary | disabled | error  (button)
        state: default | focused | error | disabled | open | closed  (input/dropdown)
        level: h1 | h2 | h3 (heading) ; body | caption (paragraph)
        kind: error | warning | info | success (alert)
        icon: <name>  (button, input, header, link, list-item, alert)
        accent_color: hex string  (overrides DEFAULT_ACCENT)
        value: real text content (text-input)
        error_msg: error message below input (text-input state=error)
        aspect_ratio: "4:3", "16:9", etc. (image)
        items: list of {title, subtitle, icon} (list)
        options: list of strings (dropdown state=open)
        labels: list of strings (nav-bar, tabs)
        active: index of active tab (tabs)
        annotation: inline note rendered below the block

    Returns (items, height_consumed). The annotation, if present, adds extra vertical space.
    """
    accent = opts.get("accent_color")
    annotation = opts.get("annotation")

    if block_type == "header":
        items, _ = header(fx, y - 10, frame_w, label=content or "Header", icon=opts.get("icon"))
        h_used = 70
    elif block_type == "footer":
        items, h_used = footer(fx, y, frame_w, frame_h, label=content or "footer"), 0
    elif block_type == "heading":
        items = heading_block(fx, y, content or "Heading", frame_w,
                              level=opts.get("level", "h2"))
        h_used = {"h1": 50, "h2": 40, "h3": 32}.get(opts.get("level", "h2"), 40)
    elif block_type == "paragraph":
        items = paragraph_block(fx, y, frame_w, content=content,
                                level=opts.get("level", "body"),
                                lines=opts.get("lines", 2))
        if content:
            # Single-line real text by default; multi-line if explicit lines opt
            h_used = 24 * max(opts.get("lines", 1), 1) + 8
        else:
            h_used = 16 * opts.get("lines", 2) + 10
    elif block_type == "button":
        items = button_block(fx, y, content or "Button", frame_w,
                             variant=opts.get("variant", "primary"),
                             icon=opts.get("icon"),
                             accent_color=accent)
        h_used = 60
    elif block_type == "text-input":
        items = text_input_block(fx, y, content or "Input", frame_w,
                                 state=opts.get("state", "default"),
                                 value=opts.get("value"),
                                 error_msg=opts.get("error_msg"),
                                 icon=opts.get("icon"),
                                 accent_color=accent)
        # Error state with msg consumes more vertical space
        h_used = 78 if (opts.get("state") == "error" and opts.get("error_msg")) else 60
    elif block_type == "section":
        items = section_box(fx, y, opts.get("h", 50), frame_w, label=content)
        h_used = opts.get("h", 50) + 10
    elif block_type == "image":
        h = opts.get("h", 200)
        items = image_block(fx, y, h, frame_w, label=content or "imagen",
                            aspect_ratio=opts.get("aspect_ratio"))
        h_used = h + 20
    elif block_type == "list":
        items_data = opts.get("items")
        n = len(items_data) if items_data else opts.get("items_count", 3)
        items = list_block(fx, y, frame_w, items_count=n, items=items_data)
        h_used = n * 52 + 10
    elif block_type == "alert":
        items = alert_block(fx, y, content or "Alert", frame_w,
                            kind=opts.get("kind", "error"),
                            icon=opts.get("icon"))
        h_used = 60
    elif block_type == "loader":
        items = loader_block(fx, y, frame_w)
        h_used = 100
    elif block_type == "empty-state":
        items = empty_state_block(fx, y, content or "Empty",
                                  opts.get("paragraph", "Sin datos"), frame_w)
        h_used = 150
    elif block_type == "search-bar":
        items = search_bar(fx, y, content or "Buscar…", frame_w)
        h_used = 60
    elif block_type == "badge":
        items = badge_block(fx, y, content or "badge", w=opts.get("w", 120))
        h_used = 35
    elif block_type == "progress-bar":
        items = progress_bar(fx, y, frame_w, fill=opts.get("fill", 0.6))
        h_used = 30
    elif block_type == "card":
        items = card_mini(fx, y, frame_w)
        h_used = 120
    elif block_type == "link":
        items = link_block(fx, y, content or "link →", icon=opts.get("icon"), accent_color=accent)
        h_used = 30
    elif block_type == "nav-bar":
        labels = opts.get("labels") or [s.strip() for s in (content or "").split("|")]
        items = nav_bar_block(fx, y, labels, frame_w)
        h_used = 50
    elif block_type == "tabs":
        labels = opts.get("labels") or [s.strip() for s in (content or "").split("|")]
        items = tabs_block(fx, y, labels, frame_w, active=opts.get("active", 0), accent_color=accent)
        h_used = 50
    elif block_type == "modal":
        items = modal_block(fx, y, frame_w, frame_h, title=content or "Modal")
        h_used = 260
    elif block_type == "avatar":
        items = avatar_block(fx, y, size=opts.get("size", 40))
        h_used = 50
    elif block_type == "icon":
        glyph = render_icon(opts.get("name") or content) if (opts.get("name") or content) else "●"
        items = icon_block(fx, y, glyph=glyph)
        h_used = 35
    elif block_type == "toggle":
        items = toggle_block(fx, y, label=content, on=opts.get("on", True))
        h_used = 35
    elif block_type == "checkbox":
        items = checkbox_block(fx, y, label=content, checked=opts.get("checked", False))
        h_used = 30
    elif block_type == "radio":
        items = radio_block(fx, y, label=content, selected=opts.get("selected", False))
        h_used = 30
    elif block_type == "dropdown":
        items = dropdown_block(fx, y, content or "Seleccionar…", frame_w,
                               state=opts.get("state", "closed"),
                               options=opts.get("options"),
                               accent_color=accent)
        h_used = 60
        if opts.get("state") == "open" and opts.get("options"):
            h_used += min(len(opts["options"]), 6) * 36
    else:
        # Fallback: section_box with the type name as label
        items = section_box(fx, y, 50, frame_w, label=f"[{block_type}] {content}".strip())
        h_used = 60

    # Append annotation below the block if provided
    if annotation:
        items = list(items) + annotation_block(fx, y + h_used - 4, annotation, frame_w)
        h_used += 18

    return items, h_used
