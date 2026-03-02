# tgui

## Introduction

tgui is a robust user interface framework of /tg/station.

tgui is very different from most UIs you will encounter in BYOND programming.
It is heavily reliant on Javascript and web technologies as opposed to DM.
It uses **Inferno** (a fast React-compatible library) for rendering and
**Vite** as the build system.

## Browser Target

BYOND 516 uses **WebView2** (Microsoft Edge / Chromium, version 109+)
instead of the old Internet Explorer control. This means:

- Full ES2020+ JavaScript support
- All modern CSS features (flexbox, grid, etc.) work reliably
- No IE polyfills or `-ms-` CSS prefixes are needed
- Babel targets Edge 109 (`babel.config.js`), Vite build targets ES2020

See [BYOND 516 Migration Notes](docs/byond-516-migration-notes.md) for a
detailed overview of what changed.

## Learn tgui

People come to tgui from different backgrounds and with different
learning styles. Whether you prefer a more theoretical or a practical
approach, we hope you’ll find this section helpful.

### Practical Tutorial

If you are completely new to frontend and prefer to **learn by doing**,
start with our [practical tutorial](docs/tutorial-and-examples.md).

### Guides

This project uses **Inferno** - a very fast UI rendering engine with a similar
API to React. Take your time to read these guides:

- [React guide](https://react.dev/learn) - Inferno uses the same JSX syntax
and component model as React.
- [Inferno documentation](https://infernojs.org/docs/guides/components) -
highlights differences with React.

## Pre-requisites

You will need these programs to start developing in tgui:

- [Node v20+](https://nodejs.org/en/download/)
- [Git Bash](https://git-scm.com/downloads)
  or [MSys2](https://www.msys2.org/) (optional)

Yarn 4.12.0 is bundled with the project (via the `packageManager` field
in `package.json` and `.yarn/releases/`). You do **not** need to install
Yarn globally.

**DO NOT install Chocolatey if Node installer asks you to!**

## Usage

**For Git Bash, MSys2, WSL, Linux or macOS users:**

Change your directory to `tgui`.

Run `bin/tgui --install-git-hooks` to install merge drivers which will
assist you in conflict resolution when rebasing your branches. Only has
to be done once.

Run `bin/tgui` with any of the options listed below.

**For Windows CMD or PowerShell users:**

If you haven't opened the console already, you can do that by holding
Shift and right clicking on the `tgui` folder, then pressing
either `Open command window here` or `Open PowerShell window here`.

Run `.\bin\tgui.bat` with any of the options listed below.

> The `.bat` file internally calls `tgui_.ps1` via
> `powershell.exe -ExecutionPolicy Bypass`. You can also invoke the
> PowerShell script directly:
> `powershell.exe -NoLogo -ExecutionPolicy Bypass -File .\bin\tgui_.ps1`

**Available commands:**

- `bin/tgui` - Build the project in production mode.
- `bin/tgui --dev` - Start development watchers for `tgui` and `tgui-panel`.
- `bin/tgui --lint` - Show problems with the code.
- `bin/tgui --fix` - Auto-fix problems with the code.
- `bin/tgui --test` - Run tests.
- `bin/tgui --analyze` - Build both bundles with source maps for manual analysis.
- `bin/tgui --lint-harder` - Run stricter lint rules.
- `bin/tgui --clean` - Clean up project repo.
- `bin/tgui [vite options]` - Build the project with custom Vite
options.

**Quick start:**

You can double-click these batch files to achieve the same thing:

- `bin\tgui.bat` - Build the project in production mode.
- `bin\tgui-dev-server.bat` - Launch development watchers (Vite watch mode).

> Remember to always run a full build before submitting a PR. It creates
> a compressed javascript bundle which is then referenced from DM code.
> We prefer to keep it version controlled, so that people could build the
> game just by using Dream Maker.

## Troubleshooting

**Development watcher is crashing**

Make sure path to your working directory does not contain spaces or special
unicode characters. If so, move codebase to a location which does not contain
spaces or unicode characters.

This is a known issue with Yarn Berry, and fix is going to happen someday.

**Build tooling errors out with some cryptic messages!**

The build toolchain stores cache on disk, and stale cache can cause
hard-to-read failures after dependency or config updates.

To fix this kind of problem, run `bin/tgui --clean` and try again.

## Developer Tools

When developing with `bin/tgui --dev`, you can use the in-app debugging
features listed below.

**Kitchen Sink.**
Press `F12` to open the KitchenSink interface. This interface is a
playground to test various tgui components.

**Layout Debugger.**
Press `F11` to toggle the *layout debugger*. It will show outlines of
all tgui elements, which makes it easy to understand how everything comes
together, and can reveal certain layout bugs which are not normally visible.

## Project Structure

- `/packages` - Each folder here represents a self-contained Node module.
- `/packages/common` - Helper functions
- `/packages/tgui/index.js` - Application entry point.
- `/packages/tgui/components` - Basic UI building blocks.
- `/packages/tgui/interfaces` - Actual in-game interfaces.
Interface takes data via the `state` prop and outputs an html-like stucture,
which you can build using existing UI components.
- `/packages/tgui/layouts` - Root level UI components, that affect the final
look and feel of the browser window. They usually hold various window
elements, like the titlebar and resize handlers, and control the UI theme.
- `/packages/tgui/routes.js` - This is where tgui decides which interface to
pull and render.
- `/packages/tgui/styles/main.scss` - CSS entry point.
- `/packages/tgui/styles/functions.scss` - Useful SASS functions.
Stuff like `lighten`, `darken`, `luminance` are defined here.
- `/packages/tgui/styles/atomic` - Atomic CSS classes.
These are very simple, tiny, reusable CSS classes which you can use and
combine to change appearance of your elements. Keep them small.
- `/packages/tgui/styles/components` - CSS classes which are used
in UI components. These stylesheets closely follow the
[BEM](https://en.bem.info/methodology/) methodology.
- `/packages/tgui/styles/interfaces` - Custom stylesheets for your interfaces.
Add stylesheets here if you really need a fine control over your UI styles.
- `/packages/tgui/styles/layouts` - Layout-related styles.
- `/packages/tgui/styles/themes` - Contains all the various themes you can
use in tgui. Each theme must be imported from the relevant entrypoint.

## Component Reference

See: [Component Reference](docs/component-reference.md).

## License

Source code is covered by /tg/station's parent license - **AGPL-3.0**
(see the main [README](../README.md)), unless otherwise indicated.

Some files are annotated with a copyright header, which explicitly states
the copyright holder and license of the file. Most of the core tgui
source code is available under the **MIT** license.

The Authors retain all copyright to their respective work here submitted.
