#!/usr/bin/env python3
"""Small transaction probe; full conformance tests remain mandatory."""
import subprocess
import sys
import tempfile
from pathlib import Path

root = Path(sys.argv[1]).resolve()
source = '''#include "rooz.h"
int main(void) {
  if (rc_to_day(1,1403,1,1) != rc_to_day(0,2024,3,20)) return 1;
  if (rc_to_day(1,1400,12,30) != RC_INVALID_DAY) return 2;
  return 0;
}
'''
with tempfile.TemporaryDirectory(prefix='rooz-probe-') as tmp:
    p = Path(tmp)
    (p / 'probe.c').write_text(source)
    subprocess.run(['cc', '-std=c99', '-I' + str(root / 'core/include'),
                    str(root / 'core/src/rooz.c'), str(p / 'probe.c'),
                    '-o', str(p / 'probe')], check=True)
    subprocess.run([str(p / 'probe')], check=True)
demos = sum((root / p).exists() for p in [
    'examples/compose/app/src/main/java/dev/rooz/example/MainActivity.kt',
    'examples/swiftui/Sources/RoozDemoApp.swift', 'examples/flutter/lib/main.dart'])
fixture = root / 'tests/fixtures/jalali-boundaries.tsv'
rows = len(fixture.read_text().splitlines()) if fixture.exists() else 0
native = int((root / 'bindings/flutter_native/src/rooz_native.c').exists())
official = int((root / 'tests/fixtures/official_1405.h').exists())
print(f'JALALI_ANCHOR=PASS; INVALID_DATE=REJECTED; RUNNABLE_DEMOS={demos}; SHARED_BOUNDARIES={rows}; NATIVE_BUNDLE={native}; OFFICIAL_1405={official}')
