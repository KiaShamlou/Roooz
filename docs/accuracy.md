# Calendar accuracy contract

Rooz promises deterministic behavior for the **named algorithms below**, not
unbounded astronomical accuracy or official calendar certification.

| ID | Calendar | Full supported years | Definition |
|---|---|---|---|
| 0 | Gregorian | 1–9999 | Proleptic Gregorian; no historical cutover |
| 1 | Jalali | 1–3177 | Borkowski break-year algorithm, compatible with jalaali-js 1.2.8 |
| 2 | Islamic civil | 1–9999 AH | Tabular 30-year cycle; Friday epoch, Julian 622-07-16 / Gregorian 622-07-19 |
| 3 | Julian | 1–9999 | Proleptic Julian; divisible-by-four leap years |

All supported years include their complete final month. Out-of-range conversions
fail rather than extrapolate. There is no BCE/year-zero API. Days begin at civil
midnight; this library does not model religious sunset boundaries or leap seconds.

## Why not a short Persian leap formula?

A naive repeating 33-year rule or 2820-year cycle is not interchangeable with the
chosen Jalali algorithm. In particular, leap-year behavior around Nowruz is a
regression target. The core retains the break-year calculation and attribution
from the pinned upstream source rather than inventing a new approximation.

Primary references:

- [Borkowski, The Persian calendar for 3000 years](https://www.astro.uni.torun.pl/~kb/Papers/EMP/PersianC-EMP.htm)
- [jalaali-js v1.2.8 source](https://github.com/jalaali/jalaali-js/blob/v1.2.8/index.js)
- [ICU calendar definitions](https://unicode-org.github.io/icu/userguide/datetime/calendar/)
- [ICU PersianCalendar discussion](https://unicode-org.github.io/icu-docs/apidoc/dev/icu4j/com/ibm/icu/util/PersianCalendar.html)

These are algorithmic references, not a claim that this package has been approved
by Iran's calendar authority. The official 1405 year-at-a-glance is now an independently sourced fixture for
month lengths and weekday placement only; that limited check is not certification.

## Independent comparison and an actual disagreement

The normal independent oracle compares every day from **1800-01-01 through
2099-12-31** against Node's ICU `persian` and `islamic-civil` calendars in UTC.
That is 109,573 days per calendar; the local ICU 78.3 run had no mismatches.

The extended diagnostic did **not** pass over the whole previously expected
1800–2255 period. On Node 26.5.0 / ICU 78.3 it found 732 Jalali mismatching days:

| Gregorian interval, inclusive | Days | First ICU value | First Rooz/Borkowski value |
|---|---:|---|---|
| 2124-03-20 … 2125-03-20 | 366 | 1503-01-01 | 1502-12-30 |
| 2223-03-21 … 2224-03-20 | 366 | 1602-01-01 | 1601-12-30 |

The implementation was **not** patched to silently imitate this ICU version.
Its explicit Borkowski contract is tested separately against the pinned source.
ICU agreement outside the ordinary test interval is not claimed. Repeat the audit
after upgrading Node/ICU; behavior belongs to a specific algorithm and version.

```sh
make all
python3 tools/audit_icu.py /absolute/path/to/librooz.dylib
```

## What each test proves

1. **12,007,879 exhaustive dates:** adjacency, legal month lengths and round-trip
   fields over all four calendars' supported domains. This catches inconsistent
   conversion, but a consistently wrong algorithm could still pass.
2. **Independent ICU comparison:** current-era agreement with a separate
   implementation, not a universal proof or astronomical certification.
3. **114,372 pinned-reference samples:** first, middle and last day of every Jalali
   month, 1–3177. This checks port compatibility, not an independent theory of the calendar.
4. **Known anchors and negative cases:** Nowruz 1403/1404/1405, Gregorian century
   rules, Islamic epoch, Julian cutover correspondence, invalid dates and limits.
5. **Selection/format tests:** UTF-8, custom names, strict parser, short buffers,
   reverse taps, blocked interiors, bounds, overflow and atomic rejection.
6. **Sanitizers and byte-string tests:** exercise memory/undefined-behavior paths.
   These are useful checks, not a formal proof that no memory bug exists.

## Civil time versus instants

Store booking days as `calendar + epochDay` (or Gregorian ISO civil dates), not an
arbitrary midnight timestamp. Adding a day is integer arithmetic, never adding
24 hours to a local timestamp across DST. Swift's instant conversion requires an
explicit `TimeZone`; other bindings require the host to choose its civil date
projection explicitly. Holiday feeds, historical eras, astronomical observation,
Umm al-Qura and local moon-sighting calendars are not inferred from a locale.

## Cross-language boundary regressions

`tests/fixtures/jalali-boundaries.tsv` contains the first and last day of all
3,177 supported years. Kotlin/JNI, Swift/C and Dart/FFI each check 6,354 rows in
both directions, localized parse round-trips and invalid Esfand overflow. The
corpus is generated from the pinned reference, not from Rooz. CI regenerates it
and compares exact bytes. It includes the far-future ICU disagreement years;
we preserve the declared algorithm instead of silently changing leap-year rules.

## Official 1405 fixture (independent of the algorithm)

Source: University of Tehran Calendar Center, [1405 at a glance](https://calendar.ut.ac.ir/documents/2139738/7092644/abstract-1405.pdf),
page 1, retrieved 2026-10-24. PDF SHA256:
`218cfa5b22f712f8f08d07dbd579f93e2972a34d773b08766d93ae5e8ed0b8cc`.

After rendering the PDF, all twelve panels were visually checked. Only factual
month lengths and first weekdays were transcribed into `tests/fixtures/official_1405.h`.
Tests verify all 365 weekday positions and reject each month's overflow date.
The PDF itself is not redistributed. This fixture does **not** validate holidays,
lunar dates, Gregorian correspondences, other official years or future revisions.
