# Verification record

Verified code commit: `289aeeb9b04fbafef6b52b5947619e8f694f062e`.
[Hosted conformance run — all 9 jobs passed](https://github.com/KiaShamlou/Roooz/actions/runs/40096360456).
Subsequent release-documentation/license changes do not alter executable source.

Local host: macOS arm64, Apple Clang 21, Swift 6.3.3, JDK 17,
Kotlin 2.1.10, Dart 3.6.2, Flutter 3.27.4. Date: 2026-10-24.

| Check | Observed result |
|---|---|
| Full C domain | 12,007,879 days / 48,450,071 assertions; passed |
| Official 1405 fixture | All 12 month lengths and 365 weekday positions; passed |
| Independent ICU | 109,573 days × Persian and Islamic civil; passed locally on ICU 78.3 and in CI |
| Pinned reference | 114,372 Jalali month samples; passed |
| ASan + UBSan | Full C test suite; passed |
| C OS matrix | Windows, Linux, macOS: compiled and executed in CI |
| Swift | 8 unit tests, including 6,354 boundary rows; passed locally and CI |
| SwiftUI apps | macOS executable and iOS simulator app compiled locally and CI |
| Kotlin/JNI | Shared 6,354-row corpus and negative/range tests; passed locally and CI |
| Android native package | Release AAR with arm64-v8a, armeabi-v7a, x86_64; built in CI |
| Android Compose demo | Debug app + test APK built; actual UI range/navigation/reset test passed on API 29 x86_64 emulator |
| Dart | Analyzer, VM and AOT executable with shared corpus; passed locally and CI |
| Flutter widgets | Analyzer; 5 library tests + 2 app tests with real FFI; passed locally and CI |
| Flutter bundled engine | Linux integration test in CI; macOS build + native integration test locally; passed |

Local Android and first Flutter macOS build attempts encountered disk exhaustion;
task-owned downloads were cleaned. Android was verified on hosted runners, and
the macOS Flutter build/integration test was rerun successfully. The local macOS
test runner reported a foreground-window warning, but the native test completed.

## Remaining coverage, not claimed as completed

- Physical iOS/Android devices; interactive SwiftUI iOS runtime. An isolated local
  iOS simulator boot stalled in OS data migration; no existing device was erased.
- Flutter target builds on Android, iOS and Windows (native host scaffolds are
  supplied; this is not equivalent to each packaged app being tested there).
- Screen-reader audit across real devices and additional OS/toolchain versions.
- Registry publication and official-calendar certification. The official 1405
  fixture proves only its documented month-length/weekday facts.

Reproduction commands are in the root/demo READMEs and `.github/workflows/ci.yml`.
Private delivery evidence includes logs, original source hashes, modified archive,
diff and a rollback tested on a separate disposable copy. It is not published.
