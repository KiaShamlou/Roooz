#ifndef ROOZ_H
#define ROOZ_H
#include <stdint.h>
#include <stddef.h>
#if defined(_WIN32) && defined(ROOZ_SHARED)
# if defined(ROOZ_BUILD)
#  define RC_API __declspec(dllexport)
# else
#  define RC_API __declspec(dllimport)
# endif
#elif defined(__GNUC__) || defined(__clang__)
# define RC_API __attribute__((visibility("default")))
#else
# define RC_API
#endif
#ifdef __cplusplus
extern "C" {
#endif

/* ABI v1. Civil dates, not timestamps. Monday=1 ... Sunday=7. */
#define RC_INVALID_DAY INT32_MIN
enum rc_calendar { RC_GREGORIAN=0, RC_JALALI=1, RC_ISLAMIC_CIVIL=2, RC_JULIAN=3 };
enum rc_field { RC_YEAR=0, RC_MONTH=1, RC_DAY=2, RC_WEEKDAY=3, RC_MONTH_LENGTH=4, RC_DAY_OF_YEAR=5 };
enum rc_status { RC_OK=0, RC_INVALID=1, RC_REVERSED=2, RC_OUT_OF_BOUNDS=3,
    RC_TOO_SHORT=4, RC_TOO_LONG=5, RC_DISABLED=6, RC_BUFFER_SMALL=7, RC_PATTERN=8 };
enum rc_overflow { RC_CLAMP=0, RC_REJECT=1 };
enum rc_digits { RC_LATIN=0, RC_PERSIAN=1, RC_ARABIC=2 };
enum rc_mode { RC_SINGLE=0, RC_RANGE=1 };
typedef struct { int32_t start, end; } rc_selection;
typedef struct {
    int32_t min_day, max_day, min_length, max_length;
    uint32_t disabled_weekdays; /* bit 0 = Monday, bit 6 = Sunday */
    const int32_t *blocked_days;
    size_t blocked_count;
} rc_rules;
/* All strings are UTF-8; names must contain exactly 12/7 entries. */
typedef struct { const char *months[12]; const char *weekdays[7]; } rc_locale;

RC_API int32_t rc_abi_version(void);
RC_API const char *rc_status_message(int32_t status);
RC_API int32_t rc_days_in_month(int32_t calendar, int32_t year, int32_t month);
RC_API int32_t rc_to_day(int32_t calendar, int32_t year, int32_t month, int32_t day);
/* Returns RC_INVALID_DAY on invalid input. weekday is independent of calendar. */
RC_API int32_t rc_get_field(int32_t calendar, int32_t epoch_day, int32_t field);
RC_API int32_t rc_add_days(int32_t calendar, int32_t epoch_day, int32_t amount);
RC_API int32_t rc_add_months(int32_t calendar, int32_t epoch_day, int32_t amount, int32_t overflow);
/* A grid starts here; render 42 consecutive days, hiding invalid edge cells. */
RC_API int32_t rc_grid_start(int32_t calendar, int32_t year, int32_t month, int32_t first_weekday);
RC_API int32_t rc_validate_range(int32_t start, int32_t end, const rc_rules *rules);
/* A failed selection leaves *out unchanged. A range's first tap sets end=INVALID. */
RC_API int32_t rc_select(int32_t mode, rc_selection current, int32_t tapped,
    const rc_rules *rules, rc_selection *out);
/* Locale 0=en, 1=fa, 2=ar. NULL for unsupported calendar/locale. */
RC_API const rc_locale *rc_builtin_locale(int32_t calendar, int32_t locale);
/* Tokens: %Y %m %d %B %A %u %j %%. Caller owns output; no hidden allocations.
   Small-buffer failure writes an empty string, never a truncated UTF-8 value. */
RC_API int32_t rc_format(int32_t calendar, int32_t epoch_day, const char *pattern,
    const rc_locale *locale, int32_t digits, char *out, size_t capacity);
/* Strict numeric-only parsing: exactly one each of %Y, %m, %d; literal separators.
   Accepts ASCII, Persian and Arabic-Indic digits; rejects trailing input. */
RC_API int32_t rc_parse(int32_t calendar, const char *text, const char *pattern);
/* Allocation helpers for FFI clients; memory must be returned to rc_free. */
RC_API void *rc_alloc(size_t size);
RC_API void rc_free(void *memory);

#ifdef __cplusplus
}
#endif
#endif
