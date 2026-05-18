# SVG Viewer

> Lightweight desktop SVG viewer with animation support
> Tauri v2 + Vue 3 + TypeScript — built on the `md-viewer` architecture, styled with the ii Design Language.

---

## Features

- **Recursive folder scanning** for `.svg` files
- **Full animation support** — SMIL (`<animate>`, `<animateMotion>`, `<animateTransform>`, `<set>`), CSS keyframes, and inline JavaScript
- **Pan & zoom** with cursor-anchored wheel zoom and click-drag pan
- **Animation controls** — play/pause and restart for SMIL, CSS, and JS animations
- **Background toggle** — checkerboard / white / black / transparent
- **SVG metadata badge** — viewBox, intrinsic size, animation type indicators
- **Source code panel** — XML view with `highlight.js` syntax highlighting and one-click copy
- **File association** — double-click `.svg` files to open in this app
- **Single instance** — opening additional `.svg` files focuses the running window
- **Reopen last folder** — remembers your last working directory

---

## Tech Stack

| Layer | Tool |
|---|---|
| Desktop | Tauri v2 |
| Frontend | Vue 3 + Composition API + TypeScript (strict) |
| Build | Vite 6 |
| Highlight | highlight.js (XML) |
| Backend | Rust 2021 (`walkdir`, `serde`, `tauri-plugin-dialog`, `tauri-plugin-single-instance`) |

---

## Project Structure

```
SVGviewer/
├── src/                              # Vue frontend
│   ├── App.vue                       # Landing ↔ Browser switching
│   ├── main.ts
│   ├── env.d.ts
│   ├── types/index.ts                # SvgFileEntry, SvgInfo, BackgroundMode, ViewState
│   ├── composables/
│   │   └── useFileSystem.ts          # Tauri command wrappers + localStorage
│   ├── components/
│   │   ├── LandingPage.vue           # Folder picker + reopen-last
│   │   ├── FileBrowser.vue           # Layout + global keyboard shortcuts
│   │   ├── Sidebar.vue               # File list + debounced search
│   │   ├── ContentView.vue           # Header + viewport host
│   │   ├── SvgViewport.vue           # CORE — SVG injection, pan/zoom, animation
│   │   ├── ViewerToolbar.vue         # Floating glass toolbar
│   │   ├── SvgInfoBadge.vue          # Floating metadata chip
│   │   └── SvgSourceView.vue         # Right-side XML source panel
│   └── styles/
│       ├── tokens.css                # ii Design Language tokens
│       ├── utilities.css             # .ii-card, .btn, .status-dot, scrollbar, ...
│       └── global.css                # Reset + font smoothing
├── src-tauri/
│   ├── src/
│   │   ├── lib.rs                    # 3 commands + single-instance handler
│   │   └── main.rs
│   ├── Cargo.toml
│   ├── tauri.conf.json               # productName, file associations (.svg)
│   ├── capabilities/default.json
│   ├── nsis/hooks.nsi                # Tauri #9803 workaround for Windows file assoc
│   └── icons/
├── test-svgs/                        # Sample files for QA
├── index.html
├── package.json
├── tsconfig.json
├── tsconfig.node.json
└── vite.config.ts
```

---

## Tauri Commands (Rust)

| Command | Signature | Purpose |
|---|---|---|
| `scan_svg_files` | `(dir_path: String) -> Vec<SvgFileEntry>` | Recursive `.svg` scan, sorted by relative path |
| `read_text_file` | `(file_path: String) -> String` | UTF-8 lossy read |
| `get_launch_file` | `() -> Option<String>` | Returns CLI-arg `.svg` path (file association) |

Single-instance plugin forwards subsequent `.svg` arguments via the `open-file` event.

---

## Getting Started

### Prerequisites

- Node.js 18+
- Rust 1.77+
- Tauri v2 prerequisites (`tauri` CLI, Windows: WebView2 Runtime, NSIS for installers)

### Development

```bash
npm install
npm run tauri dev
```

The Vite dev server runs on `http://localhost:1420`, and Tauri opens a native window pointing at it.

### Build

```bash
npm run tauri build
```

Outputs to `src-tauri/target/release/bundle/` (NSIS installer + MSI on Windows).

---

## Keyboard Shortcuts

### App-level (FileBrowser)

| Key | Action |
|---|---|
| `Alt+↑` / `Alt+↓` | Previous / next file |
| `Ctrl+K` or `/` | Focus search |
| `Escape` | Clear search & blur |

### Viewport-level (SvgViewport)

| Key | Action |
|---|---|
| `+` / `=` | Zoom in |
| `-` / `_` | Zoom out |
| `0` | Actual size (100%) |
| `f` | Fit to screen |
| `r` | Reset transform |
| `Space` | Play / pause animations |
| `Shift+R` | Restart animations |
| `b` | Cycle background |
| `s` | Toggle source panel |

Double-click the viewport also triggers fit-to-screen.

---

## Visual Design Language

This app follows the [ii Design Language](../../visual-style-docs/) (R11 monochrome):

- **Palette**: black / white / grays only; status dots (green / yellow / red / idle) are the sole color exception
- **Radius**: 4 / 10 / 12 / pill
- **Borders**: 0.5px subpixel
- **Fonts**: Inter (sans), Space Grotesk (mono)
- **Spacing**: 4px increments via `--gap-*`
- **Transitions**: `--t-fast` (0.15s) / `--t-base` (0.2s)

Tokens live in `src/styles/tokens.css`. Utility classes (`.ii-card`, `.btn`, `.status-dot`, `.label-micro`, `.glass-box`) in `src/styles/utilities.css`.

---

## Security Note

For maximum fidelity with interactive SVGs, this viewer **executes scripts and event handlers embedded in SVG files** (rebuilding `<script>` elements after DOM adoption so they fire). This is required to render JS-driven animations.

Only open SVGs from sources you trust. The viewer runs inside the Tauri WebView with no Tauri-IPC bridge exposed to the SVG document, so the blast radius is limited to standard browser script capabilities (DOM manipulation, network requests to allowed origins). If you need a strict sanitization mode, edit `injectSvg()` in `src/components/SvgViewport.vue` to strip `<script>` and `on*` attributes before adoption.

---

## Test Fixtures

`test-svgs/` contains sample files covering:

| File | What it tests |
|---|---|
| `static-shapes.svg` | Basic static rendering, viewBox |
| `smil-bouncing.svg` | SMIL `<animate>` on `cx` |
| `smil-motion-path.svg` | SMIL `<animateMotion>` with `<mpath>` |
| `css-spinner.svg` | CSS `@keyframes` rotation |
| `js-interactive.svg` | `<script>` execution + click events |
| `mixed-anim.svg` | SMIL + CSS + JS in one file |
| `no-viewbox.svg` | `width`/`height` only, viewBox synthesis |

Open the `test-svgs/` folder in the app to verify all paths.

---

## License

MIT
