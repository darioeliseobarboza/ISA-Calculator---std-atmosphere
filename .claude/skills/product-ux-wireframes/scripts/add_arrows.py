"""Add arrows, labels, destination circles, and arrow groups to an existing .excalidraw.

Usage:
    python3 add_arrows.py <excalidraw_path> <arrows_json_path>

Modifies the .excalidraw file in place by appending elements built from
arrows.json. The agent (Claude) produces arrows.json after reading coords.json
and deciding individual positions per transition.

See SCHEMA.md for the full schema. Top-level keys (all optional):
- arrows: individual arrows with single destination
- labels: free-floating text labels
- circles: numbered destination circles
- groups: arrow groups (one source, N destinations) — renders a fork:
  trunk line → fork point → branch arrows to each destination circle

Fails hard on missing files or invalid JSON shape.
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from excalidraw_lib import (  # noqa: E402
    STROKE, ellipse, line, text, arrow, write_excalidraw,
)


def fail(msg):
    print(f"[add_arrows] ERROR: {msg}", file=sys.stderr)
    sys.exit(1)


def add(excalidraw_path, arrows_path):
    if not os.path.exists(excalidraw_path):
        fail(f"Excalidraw file not found: {excalidraw_path}")
    if not os.path.exists(arrows_path):
        fail(f"Arrows JSON not found: {arrows_path}")

    with open(excalidraw_path, encoding="utf-8") as f:
        doc = json.load(f)
    with open(arrows_path, encoding="utf-8") as f:
        arrows_data = json.load(f)

    elements = doc.get("elements", [])
    added = 0

    for a in arrows_data.get("arrows", []):
        if "from" not in a or "to" not in a:
            fail("arrow entry missing 'from' or 'to'")
        p1 = (a["from"]["x"], a["from"]["y"])
        p2 = (a["to"]["x"], a["to"]["y"])
        elements.append(arrow(
            p1, p2,
            dashed=a.get("dashed", False),
            color=a.get("color", STROKE),
        ))
        added += 1

    for lbl in arrows_data.get("labels", []):
        if "x" not in lbl or "y" not in lbl or "text" not in lbl:
            fail("label entry missing 'x', 'y', or 'text'")
        elements.append(text(
            lbl["x"], lbl["y"], lbl["text"],
            fontSize=lbl.get("fontSize", 10),
            color=lbl.get("color", "#495057"),
            w=lbl.get("width", max(40, int(lbl.get("fontSize", 10) * 0.6 * len(lbl["text"])))),
            h=lbl.get("height"),
            align=lbl.get("align", "left"),
        ))
        added += 1

    for c in arrows_data.get("circles", []):
        if "x" not in c or "y" not in c or "number" not in c:
            fail("circle entry missing 'x', 'y', or 'number'")
        size = c.get("size", 28)
        elements.append(ellipse(c["x"], c["y"], size, size,
                                strokeColor=c.get("color", STROKE)))
        digit_str = str(c["number"])
        elements.append(text(
            c["x"], c["y"] + (size - 18) / 2,
            digit_str, fontSize=c.get("fontSize", 14),
            color=c.get("color", STROKE),
            w=size, h=18, align="center",
        ))
        added += 2

    # Groups: fork-style arrow with one source and N destinations
    for g in arrows_data.get("groups", []):
        if "from" not in g or "destinations" not in g or "fork_at_x" not in g:
            fail("group entry missing 'from', 'destinations', or 'fork_at_x'")
        destinations = g["destinations"]
        if not destinations:
            fail("group 'destinations' must be non-empty")

        from_x = g["from"]["x"]
        from_y = g["from"]["y"]
        fork_x = g["fork_at_x"]
        circle_size = g.get("circle_size", 28)
        circle_x = g.get("circle_x", fork_x + 36)
        stack_offset = g.get("stack_offset", 36)
        dashed = g.get("dashed", False)
        color = g.get("color", STROKE)
        label_font = g.get("label_font_size", 10)
        label_color = g.get("label_color", "#495057")
        label_offset_x = g.get("label_offset_x", circle_size + 6)
        label_width = g.get("label_width", 120)

        n = len(destinations)
        # Y positions for destinations: centered around from_y, stack_offset apart
        ys = [from_y + (i - (n - 1) / 2) * stack_offset for i in range(n)]

        # Trunk: line from (from_x, from_y) to (fork_x, from_y) — no arrowhead
        trunk = line(
            [[0, 0], [fork_x - from_x, 0]],
            x=from_x, y=from_y,
            strokeColor=color,
            strokeStyle=("dashed" if dashed else "solid"),
        )
        elements.append(trunk)
        added += 1

        # Branches: arrow from (fork_x, from_y) to (circle_x, dest_y)
        for i, dest in enumerate(destinations):
            dy = ys[i]
            elements.append(arrow(
                (fork_x, from_y),
                (circle_x, dy),
                dashed=dashed,
                color=color,
            ))
            added += 1

            # Circle at (circle_x, dy - circle_size/2)
            cy = dy - circle_size / 2
            elements.append(ellipse(circle_x, cy, circle_size, circle_size, strokeColor=color))
            digit_str = str(dest["number"])
            elements.append(text(
                circle_x, cy + (circle_size - 18) / 2,
                digit_str, fontSize=14, color=color,
                w=circle_size, h=18, align="center",
            ))
            added += 2

            # Label to the right of the circle
            if dest.get("label"):
                elements.append(text(
                    circle_x + label_offset_x, cy + (circle_size - 14) / 2,
                    dest["label"], fontSize=label_font, color=label_color,
                    w=label_width, h=14,
                ))
                added += 1

    doc["elements"] = elements
    write_excalidraw(elements, excalidraw_path)
    print(f"Added {added} elements to {excalidraw_path}.")
    return excalidraw_path


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: add_arrows.py <excalidraw_path> <arrows_json_path>", file=sys.stderr)
        sys.exit(1)
    add(sys.argv[1], sys.argv[2])
