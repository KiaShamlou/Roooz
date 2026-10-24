# Contributing

Start with `make test oracle reference sanitize`. Binding changes also need the
corresponding smoke tests and `swift test` / Flutter widget tests. Keep changes small.

## Correctness requirements

1. State which calendar and algorithm the issue concerns. Never silently change the
   meaning of an existing calendar ID. New variants get new IDs and ABI review.
2. Add a minimal regression fixture with a primary reference or independent oracle.
3. Cover both sides of month/year/leap boundaries and all supported endpoints.
4. Keep civil dates free of implicit clocks, time zones and DST arithmetic.
5. Preserve C ABI layout and status values. Bump the ABI version for breaking changes.
6. Never normalize invalid input into a different valid date without an explicit policy.
7. New locales need native-speaker review; digit shaping and text direction are separate.

The C engine has no mutable global state. Wrappers must release every allocation on
both success and exceptions. Rejected range transitions must preserve the anchor.

## Before a release

- Run the OS matrix and on-device Android/iOS smoke tests.
- Verify AAR, Swift Package and Dart native-asset packaging from a clean consumer project.
- Run accessibility, keyboard, high text-scale and RTL UI tests on target platforms.
- Add the actual GitHub repository URL and publish metadata; verify registry name availability.
- Tag only after green CI; do not advertise algorithmic agreement as official certification.
