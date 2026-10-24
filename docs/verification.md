# Verification record

Local host: macOS arm64, Apple Clang 21, Swift 6.3.3, JDK 17,
Kotlin 2.1.10, Dart 3.6.2, Flutter 3.27.4. Date: 2026-10-24.

| Check | Evidence/status |
|---|---|
| Full C domain | 12,007,879 days / 48,449,681 assertions; passed |
| Independent ICU | 109,573 days × Persian and Islamic civil; passed on ICU 78.3 |
| Pinned reference | 114,372 Jalali month samples; passed |
| ASan + UBSan | Full C test suite; passed |
| Swift unit tests | 8 tests, including 6,354 boundary rows; passed |
| Kotlin/JNI | Shared 6,354-row corpus + negative/range tests; passed |
| Flutter | Analyzer; 5 widget-library tests + 2 app tests using real FFI; passed |
| SwiftUI iOS app | Simulator SDK, unsigned app build; passed |
| Device UI | No physical-device certification; isolated local simulator boot stalled in OS data migration |

Dart VM/AOT, Android packaging and bundled Flutter integration results are
recorded by the associated [CI run](https://github.com/KiaShamlou/Roooz/actions).
A workflow definition is not evidence that its jobs passed; use the green check
for the exact commit. Core Linux/Windows and Android emulator runs are CI targets.
No official Iranian-calendar certification or universal far-future agreement is claimed.

Reproduce commands are in `README.md`, each demo README and `.github/workflows/ci.yml`.
The private local delivery evidence preserves command output and rollback checks;
it is excluded from the public repository.
