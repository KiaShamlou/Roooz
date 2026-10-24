# Architecture

```text
Compose / SwiftUI / Flutter / custom UI
                  |
Kotlin/JNI     Swift/C module     Dart/FFI      other FFI consumers
                  |
             C ABI v1 — core/include/rooz.h
                  |
   civil epoch days · calendar conversion · formatting · selection reducer
```

The epoch day is an integer count from Gregorian 1970-01-01, not a timestamp.
The four calendar systems are projections of that same day. UI state and business
rules do not change conversion logic. One native engine means bindings cannot
quietly choose different platform-specific Persian algorithms.

## Invariants

- Years are positive; there is no year zero or BCE mode in this release.
- Dates validate on construction. `INT32_MIN` is the C invalid-day sentinel.
- The 1-based weekday is ISO: Monday=1 through Sunday=7, regardless of locale.
- Calendar identity participates in wrapper equality. Compare `epochDay` for
  calendar-independent equality/order. Serialize `{calendar, epochDay}` explicitly.
- `addMonths` clamps by default; `reject` reports a missing day instead.
- A date range is **inclusive**. Length is `end - start + 1`; booking nights are
  `end - start` and belong in the host's policy hook.
- An incomplete range has a start but no end. A rejected second tap preserves it.
- Reverse taps normalize to an ascending range; direct range validation rejects
  reversed input. Every interior blocked date is considered, not only endpoints.
- Minimum length applies to completed ranges, not the initial anchor or single mode.
- First weekday belongs to layout, not the calendar arithmetic. Grid padding may
  fall outside a supported year and is represented as an empty cell in wrappers.

## Extension points

**UI:** supply day content/builders, event badges keyed by epoch day, header,
navigation, selected-state styling, fonts, semantics labels and layout direction.
These views do not own selection state. A custom week/agenda/year view can consume
the same immutable dates and reducer.

**Logic:** set bounds, blocked dates, weekday mask, range length, overflow policy,
selection mode and week start. Wrapper `validator` callbacks can reject a candidate
before state changes. When implementing a callback, inspect the entire interval if
your rule concerns interior dates. Run asynchronous availability checks in the host
and commit a candidate only after validation against the latest data.

**Language/format:** the C API accepts custom UTF-8 month/weekday names. Built-in
wrapper locale presets are English, Persian and Arabic. UI labels accept host
formatters, so any app locale can supply its own text. The pattern syntax is Rooz's
small explicit subset, **not** ICU, Java DateTimeFormatter or strftime in full.

**Calendars:** a new algorithm currently requires a source-level core extension,
new enum/ABI review and conformance fixtures. Runtime calendar plug-ins, lunisolar
leap-month support, recurrence and astronomical observations are future work.

## Memory and concurrency

Conversion does not allocate. `rc_format` uses a caller buffer and erases it on
failure rather than returning truncated text. `rc_alloc` / `rc_free` keep FFI
allocation and deallocation in the same native runtime, including Windows.
Borrowed locale/rules pointers must live for the duration of a call. No callbacks
cross the C ABI. The core is reentrant; mutable UI selection is host-owned.
