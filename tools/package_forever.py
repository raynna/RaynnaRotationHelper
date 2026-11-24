"""Build a player-only Forever ZIP; optionally install those exact files."""
import argparse
from pathlib import Path
import re
import shutil
import zipfile

parser = argparse.ArgumentParser()
parser.add_argument('--output', type=Path, default=Path('dist'))
parser.add_argument('--install', type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
toc = root / 'RaynnaRotationHelper.toc'
version = re.search(r'^## Version: (.+)$', toc.read_text(), re.M).group(1).strip()
files = [toc, root / 'FOREVER.md', root / 'SOURCES.md', root / 'LICENSE']
files += [root / line.strip().replace('\\', '/') for line in toc.read_text().splitlines()
          if line.strip() and not line.startswith('#')]
assert all(p.is_file() for p in files)
args.output.mkdir(parents=True, exist_ok=True)
output = args.output / f'RaynnaRotationHelper-{version}.zip'
with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as archive:
    for path in files:
        archive.write(path, 'RaynnaRotationHelper/' + path.relative_to(root).as_posix())
with zipfile.ZipFile(output) as archive:
    assert archive.testzip() is None
    for path in files:
        assert archive.read('RaynnaRotationHelper/' + path.relative_to(root).as_posix()) == path.read_bytes()
if args.install:
    for path in files:
        destination = args.install / 'RaynnaRotationHelper' / path.relative_to(root)
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, destination)
        assert destination.read_bytes() == path.read_bytes()
print(f'{output.resolve()} ({len(files)} verified files)')
