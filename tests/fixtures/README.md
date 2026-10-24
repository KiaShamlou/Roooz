# Shared Jalali boundary corpus

6,354 rows: first and last day of **every supported Jalali year 1–3177**.
Columns: epoch day, year, month, day (tab-separated).

Generated using `node tools/jalali_boundaries.cjs` from the MIT-licensed,
pinned **jalaali-js 1.2.8** source, not Rooz. Regenerate and compare byte-for-byte
in CI. Kotlin/JNI, Swift/C and Dart/FFI each read this same corpus, verify both
directions, digit parsing and illegal Esfand dates. This detects binding/port
regressions; it is not an independent astronomical or official annual-calendar
oracle. The independent ICU test remains a separate release check.

Source: https://github.com/jalaali/jalaali-js/blob/v1.2.8/index.js
