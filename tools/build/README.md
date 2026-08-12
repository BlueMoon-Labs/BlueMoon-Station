# /tg/station build script

This build script is the recommended way to compile the game, including not only the DM code but also the JavaScript and any other dependencies.

- VSCode:
  a) Press `Ctrl+Shift+B` to build.
  b) Press `F5` to build and run with debugger attached.
- Windows:
  a) Double-click `BUILD.bat` in the repository root to build (will wait for a key press before it closes).
  b) Double-click `tools/build/build.bat` to build (will exit as soon as it finishes building).
- Linux:
  a) Run `tools/build/build` from the repository root.

The script will skip build steps whose inputs have not changed since the last run.

## Unit tests

`dm-test` remains the compile-and-run entrypoint. Test compilation and execution
are also exposed separately so repeated focused runs can reuse the test DMB:

```
tools/build/build dm-test-build
tools/build/build dm-test-run
```

Use `--unit-test-profile=hermetic` for the LOWMEMORYMODE-compatible suite and
`--unit-test-profile=full-map` for tests explicitly marked as requiring the
production map. The default `all` profile runs every test on the production map.
Compiled artifacts are separated by profile and define set, and are invalidated
when sources or the local BYOND compiler change.

## Getting list of available targets

You can get a list of all targets that you can build by running the following command:

```
tools/build/build --help
```

## Dependencies

- On Windows, `BUILD.bat` will automatically install a private (vendored) copy of Node.
- On Linux, install Node using your package manager or from <https://nodejs.org/en/download/>.
- On Linux , unless using tgs4 or later you will need to compile rust-g on the server and obtain a .so file, for instructions see https://github.com/tgstation/rust-g

## Why?

We used to include compiled versions of the tgui JavaScript code in the Git repository so that the project could be compiled using BYOND only. These pre-compiled files tended to have merge conflicts for no good reason. Using a build script lets us avoid this problem, while keeping builds convenient for people who are not modifying tgui.

This build script is based on [Juke Build](https://github.com/stylemistake/juke-build) - please follow the link and read the documentation for the project to understand how it works and how to contribute to this build script.
