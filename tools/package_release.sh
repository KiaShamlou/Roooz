#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
# Only committed project files; ignores caches, credentials and unrelated folders.
test -z "$(git status --porcelain --untracked-files=no)" || { echo "Commit tracked changes before packaging" >&2; exit 1; }
mkdir -p dist
git archive --format=tar.gz --prefix=Roooz/ HEAD > dist/Roooz-source.tar.gz
python3 - <<'CHECK'
import hashlib, tarfile
from pathlib import Path
p = Path('dist/Roooz-source.tar.gz')
with tarfile.open(p) as t:
    names = t.getnames()
    assert 'Roooz/core/src/rooz.c' in names
    assert not any('/ios-screen-plugin/' in n or '/.evidence/' in n for n in names)
h = hashlib.sha256(p.read_bytes()).hexdigest()
Path('dist/SHA256SUMS').write_text(h + '  Roooz-source.tar.gz\n')
print(h + '  Roooz-source.tar.gz')
CHECK
