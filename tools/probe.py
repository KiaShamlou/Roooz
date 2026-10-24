#!/usr/bin/env python3
"""Small repeatable baseline/modified/rollback probe, with an explicit source root."""
import pathlib
import subprocess
import sys
import tempfile

root = pathlib.Path(sys.argv[1]).resolve()
source = root / 'core/src/rooz.c'
if not source.is_file():
    print('CALENDAR_ENGINE_MISSING')
    raise SystemExit(3)
with tempfile.TemporaryDirectory(prefix='rooz-probe-') as folder:
    exe = pathlib.Path(folder) / 'probe'
    harness = pathlib.Path(folder) / 'probe.c'
    harness.write_text('''#include "rooz.h"
#include <stdio.h>
int main(void) {
  int day = rc_to_day(RC_JALALI, 1403, 1, 1);
  if (day != rc_to_day(RC_GREGORIAN, 2024, 3, 20)) return 1;
  if (rc_to_day(RC_JALALI, 1400, 12, 30) != RC_INVALID_DAY) return 2;
  puts("JALALI_1403_01_01=GREGORIAN_2024_03_20; INVALID_DATE_REJECTED");
  return 0;
}
''')
    subprocess.run(['cc', '-std=c99', '-I' + str(root/'core/include'), str(source), str(harness), '-o', str(exe)], check=True)
    raise SystemExit(subprocess.run([str(exe)]).returncode)
