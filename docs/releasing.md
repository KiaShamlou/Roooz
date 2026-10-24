# Release checklist

Repository: https://github.com/KiaShamlou/Roooz

1. Require the complete `conformance` workflow to pass on the exact commit,
   including Android instrumentation and Flutter bundled-engine integration.
2. Review `docs/accuracy.md`; retain the Borkowski/ICU distinction. Do not market
   all-year official compatibility from the limited cited 1405 weekday/length fixture.
3. Review platform support honestly: simulator build != interactive/device test.
4. Check `python3 tools/sync_flutter_core.py --check`; never edit generated copies.
5. Update versions/changelog together. Inspect MIT and third-party notices.
6. Run `tools/package_release.sh`; inspect `dist/Roooz-source.tar.gz` and its SHA256.
   The archive contains committed source only, not local diagnostics or unrelated apps.
7. Tag a reviewed commit (first release should be `v0.1.0-alpha.1`). Run
   `draft-source-release` manually with that existing tag; it creates a **draft**,
   not a public final release. Inspect downloads and CI before publishing it.
8. Registry publication (pub.dev/Maven/Swift tag policy) is a separate step.
   Local-path Flutter packages intentionally have `publish_to: none`.

The Gradle wrapper pins 8.10.2 with its distribution SHA256. Flutter CI pins
3.27.4 / Dart 3.6.2; updating either requires rerunning UI/ABI/oracle tests.
