#!/usr/bin/env python3
"""Diagnostic, not a pass/fail oracle: expose algorithm differences explicitly."""
import ctypes
import datetime
import json
import subprocess
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
lib = ctypes.CDLL(sys.argv[1])
script = (root / 'tools/intl_oracle.mjs').read_text().replace('Date.UTC(2100, 0, 1)', 'Date.UTC(2256, 0, 1)').replace('2099-12-31', '2255-12-31')
oracle = subprocess.run(['node', '--input-type=module', '-e', script], check=True, capture_output=True, text=True)
differences = []
for line in oracle.stdout.splitlines():
    day, jy, jm, jd, *_ = map(int, line.split())
    actual = lib.rc_to_day(1, jy, jm, jd)
    if actual != day:
        differences.append((day, [jy, jm, jd], [lib.rc_get_field(1, day, i) for i in range(3)]))
def iso(day):
    return (datetime.date(1970, 1, 1) + datetime.timedelta(days=day)).isoformat()
intervals = []
for day, icu, rooz in differences:
    if not intervals or day != intervals[-1]['last_epoch_day'] + 1:
        intervals.append({'first': iso(day), 'last': iso(day), 'last_epoch_day': day, 'days': 1,
                          'first_icu': icu, 'first_rooz': rooz})
    else:
        intervals[-1].update(last=iso(day), last_epoch_day=day, days=intervals[-1]['days'] + 1)
print(json.dumps({'oracle': oracle.stderr.strip(), 'mismatching_days': len(differences), 'intervals': intervals}, indent=2))
