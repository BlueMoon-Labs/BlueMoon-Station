# BYOND 516 Migration Notes

## Overview

BYOND 516 replaces the Internet Explorer (Trident) browser control with
**WebView2** (Microsoft Edge / Chromium, version **109+**). This is the
most significant platform change in tgui's history and affects both the
frontend runtime and build toolchain.

## What was removed

### IE/Trident support (three batch commits)

- IE detection globals (`IS_LTE_IE*`) and legacy `byond.js`
- Polyfill files: `css-om.js`, `dom4.js`, `html5shiv.js`, `ie8.js`, `unfetch`
- `paracode_*` components, layouts, and backend tree
- IE fallback panel path (`HoboPanel`) and IE-gated behavior in panel
  audio/chat/components
- IE-specific CSS: `-ms-` prefixes, IE8 hacks in Box, Flex, Section,
  Window, Button, Knob, Slider, RoundGauge, ByondUi, and related SCSS
- Trident-specific `<meta>` tags from `tgui.html`
- ES5 shims (`Function.bind`, `Array.forEach`, `Array.includes`)
- `tgui-dev-server` package (replaced by `scripts/vite-dev.cjs` Vite
  watch mode)

## Modernized APIs

| Before (IE-era)                  | After (Edge 109+)                       |
|----------------------------------|-----------------------------------------|
| `event.keyCode` (numeric)        | `event.key` / `event.code` (strings)    |
| Custom UUID generator            | `crypto.randomUUID()`                   |
| String query builder             | `URLSearchParams`                       |
| `setImmediate` polyfill          | `queueMicrotask()`                      |
| `str.substr(start, len)`         | `str.slice(start, end)`                 |
| `str.trimRight()`                | `str.trimEnd()`                         |
| `msSaveBlob` (IE file save)      | Standards-based blob URL download       |
| `findDOMfromVNode` (Inferno old) | `findDOMFromVNode` (Inferno 9)          |

Keyboard event constants (in `common/keycodes.js`) now use string values:
- `KEY_LEFT` = `'ArrowLeft'` (was keyCode 37)
- `KEY_ENTER` = `'Enter'` (was keyCode 13)
- `KEY_ESCAPE` = `'Escape'` (was keyCode 27)
- etc.

## DPI handling

WebView2 reports a real `devicePixelRatio` on high-DPI displays (e.g. 1.5
at 150% Windows scaling). The tgui window layer handles this automatically:

- `document.body.style.zoom = 100 / devicePixelRatio + '%'` compensates
  for WebView2's scaled mode, keeping CSS pixel counts consistent
- Window drag/resize operations use physical (BYOND) pixels, converting
  JS API reads via `* devicePixelRatio`
- First-open flicker is eliminated by delaying reveal until geometry is
  applied

**Developers writing normal tgui interfaces do not need to handle DPI.**
The window management layer (`drag.js`, `tgui_window.dm`) does it
automatically.

## Build toolchain changes

| Component        | Before              | After                           |
|------------------|---------------------|---------------------------------|
| Bundler          | Webpack             | Vite 7.x                        |
| Package manager  | Yarn 1              | Yarn 4.12.0 Berry with PnP      |
| TypeScript target| ES3                 | ES2020                           |
| Babel target     | IE 8                | Edge 109                         |
| Node baseline    | v12                 | v20.19+                          |
| Sass functions   | Deprecated built-ins| Modern `color.channel()` etc.    |
| Inferno          | 8.x                | 9.x                              |
| TypeScript       | 4.9                | 5.9                              |
| ESLint           | 8.x                | 9.x                              |
| Jest             | 28.x               | 30.x                             |

## BYOND-to-browser bridge

- Multi-fallback dispatcher instead of raw `window.location` href hacks
- Server-side theme persistence for tgui-panel (browser storage can be
  unreliable in WebView2)
- CHILD element pane switching to fix chat flickering caused by BYOND 516
  automatically resetting element visibility on text send
- 30-second fallback for the statbrowser panel-ready callback to prevent
  clients getting stuck in eternal loading

## New components

- **`PixelArtImage`** — Canvas-based pixel-art renderer with crisp
  nearest-neighbor upscale, auto-scaling to container, DPI-aware.
  See [Component Reference](component-reference.md#pixelartimage).

## Testing

Comprehensive unit test coverage (~2,800 lines) was added alongside the
migration, covering `packages/common`, `packages/tgui`, and
`packages/tgui-panel`. See [Writing Tests](writing-tests.md) for details
on how to write and run tests.

## Debugging with WebView2

The `allow_browser_inspect` verb enables the Edge DevTools panel for
WebView2 windows, useful for inspecting the DOM and debugging at runtime.

## Guidelines for developers

**Do NOT:**

- Add IE11 polyfills or `-ms-` CSS prefixes
- Use deprecated APIs: `keyCode`, `substr`, `trimRight`, `setImmediate`,
  `msSaveBlob`
- Avoid modern JavaScript or CSS features for IE compatibility reasons
- Use `window.event` for keyboard event handling

**Do:**

- Use `event.key` (e.g. `'Enter'`, `'Escape'`) for keyboard handling
- Use modern APIs: `crypto.randomUUID()`, `URLSearchParams`,
  `queueMicrotask()`, `str.slice()`, `str.trimEnd()`
- Use modern CSS freely: flexbox `gap`, `space-evenly`, CSS Grid, etc.
- Target ES2020 features: optional chaining (`?.`), nullish coalescing
  (`??`), `Promise.allSettled()`, etc.
