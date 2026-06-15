# Block Dictionary → Library Item Mapping

This file maps each block type from the wireframe-low dictionary (36 types in 5 categories) to the corresponding `libraryItem` index in the bundled `.excalidrawlib` files.

## Source libraries

- **excalidraw-ui** (`excalidraw-ui.excalidrawlib`) — 17 items by Vadim Demedes. UI-focused: buttons, inputs, dialogs.
- **lo-fi-wireframing-kit** (`lo-fi-wireframing-kit.excalidrawlib`) — 23 items by spfr. Wireframe-focused: typography, layouts, full screen templates.

Index is 0-based and refers to position in the `library` array.

## Mapping

### Layout (6)
| Type | Source | Index | Notes |
|------|--------|-------|-------|
| `header` | lo-fi | 13 | "Header" template with title + button |
| `footer` | — | — | **fallback**: rectangle + text "Footer" |
| `sidebar` | lo-fi | 18 | "Side Navigation" template |
| `main` | — | — | **fallback**: invisible container (no element needed) |
| `modal` | excalidraw-ui | 15 | "Dialog" with title, text, cancel/ok buttons |
| `section` | — | — | **fallback**: rectangle with optional label |

### Navigation (5)
| Type | Source | Index | Notes |
|------|--------|-------|-------|
| `nav-bar` | lo-fi | 16 | "Tab Bar" with active/default tabs |
| `tabs` | lo-fi | 16 | Same as nav-bar |
| `link` | — | — | **fallback**: text with underline |
| `breadcrumbs` | lo-fi | 7 | "Breadcrumbs" template |
| `pagination` | — | — | **fallback**: row of small numbered squares |

### Content (10)
| Type | Source | Index | Notes |
|------|--------|-------|-------|
| `heading` | lo-fi | 11 | "Title Text" / "Subtitle Text" |
| `paragraph` | lo-fi | 11 | "Body Text" (same item, includes all three) |
| `image` | lo-fi | 10 | "Images" with X-mark placeholders |
| `icon` | lo-fi | 9 | "Icons" sample sheet |
| `list` | lo-fi | 15 | "Lists" template (Item 1, Item 2, Item 3) |
| `card` | lo-fi | 14 | "Card" template with image + title + body + button |
| `table` | excalidraw-ui | 16 | Table with headers ID/Name/Age |
| `avatar` | excalidraw-ui | 3 | Ellipse + diamond combo |
| `badge` | lo-fi | 6 | "Badges" with default/success/warning variants |
| `chart` | lo-fi | 8 | "Charts" sample (bars + line) |

### Input (9)
| Type | Source | Index | Notes |
|------|--------|-------|-------|
| `text-input` | lo-fi | 1 | "Input Field" with label/message/error states |
| `button` | lo-fi | 0 | "Buttons" with default/primary/danger variants |
| `dropdown` | lo-fi | 2 | "Dropdown" with options |
| `checkbox` | lo-fi | 4 | "Checkboxes" sample |
| `radio` | lo-fi | 4 | Same as checkbox (item includes both) |
| `toggle` | lo-fi | 5 | "Tags / Toggles" |
| `search-bar` | lo-fi | 17 | "Search Bar" with magnifier icon |
| `slider` | — | — | **fallback**: line with circle on it |
| `date-picker` | — | — | **fallback**: text-input + calendar icon |

### Feedback (6)
| Type | Source | Index | Notes |
|------|--------|-------|-------|
| `alert` | lo-fi | 6 | Use badge "warning" variant |
| `toast` | lo-fi | 3 | "Toast / Notification" with icon + text |
| `progress-bar` | — | — | **fallback**: rectangle partially filled |
| `tooltip` | — | — | **fallback**: small rectangle with arrow |
| `empty-state` | — | — | **fallback**: icon centered + text below |
| `loader` | — | — | **fallback**: dashed lines (skeleton) |

## Frame templates (device sizes)

| Device | Source | Index | Dimensions |
|--------|--------|-------|------------|
| Mobile (Phone) | lo-fi | 20 | 267×635 |
| Tablet | lo-fi | 22 | 780×634 |
| Desktop | lo-fi | 21 | 1147×869 |

## Coverage summary

- **Direct match**: 22/36 types (61%)
- **Fallback geometry**: 14/36 types (39%)

Fallbacks are simple primitives (rectangle, text, ellipse, line) the skill generates directly without needing a library item.

## Usage from skill

1. At runtime, parse the relevant `.excalidrawlib` file as JSON.
2. For a given block type, look up the index in this mapping.
3. Clone the elements from `library[index]`, regenerate ids/seeds/versionNonces, translate coordinates to target position inside the frame.
4. For fallback types, generate primitives directly using documented hand-drawn conventions.
