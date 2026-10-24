#!/usr/bin/env python3
"""Keep the self-contained FFI package's C sources identical to the core."""
from pathlib import Path
import sys
root = Path(__file__).resolve().parents[1]
pairs = {'core/src/rooz.c': 'rooz_native.c', 'core/src/locales.inc': 'locales.inc', 'core/include/rooz.h': 'rooz.h'}
for source, target in pairs.items():
    dest = root / 'bindings/flutter_native/src' / target
    data = (root / source).read_bytes()
    if '--check' in sys.argv:
        if not dest.exists() or dest.read_bytes() != data:
            raise SystemExit('STALE_NATIVE_COPY: ' + target)
    else:
        dest.write_bytes(data)
print('PASS native source parity')
