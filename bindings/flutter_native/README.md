# Rooz native engine bundling

Use this local package alongside `rooz_calendar_flutter`. `openBundledRooz()`
loads the target-native engine compiled by Flutter's FFI plugin build; never copy
a macOS host dylib into another target. See `examples/flutter` for the app.

The C files in `src` are generated, byte-identical copies of the shared engine.
Run `python3 tools/sync_flutter_core.py --check` from the repo root. Update them
only through that script. Each package preserves the MIT and upstream notices.
The package is monorepo-only (`publish_to: none`) until repository URLs and
registry publication metadata are finalized. Apple builds use CocoaPods and
framework loading, Android/Linux/Windows use the generated dynamic library.
