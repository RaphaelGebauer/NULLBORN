"""Generate in a temporary tree, then compare; never write into the checked project."""
from pathlib import Path
import argparse
import json
import re
import shutil
import subprocess
import sys
import tempfile

KINDS = ('weapons', 'passives', 'enemies', 'characters', 'waves', 'evolutions', 'runes', 'stages', 'mutations')
DATA_SCRIPTS = ('definition', 'weapon_definition', 'passive_definition', 'enemy_definition', 'character_definition', 'wave_definition', 'evolution_definition', 'rune_definition', 'stage_definition')

def check(root: Path) -> list[str]:
    ids = json.loads((root / 'tools/catalog_ids.json').read_text())
    id_errors = []
    for kind in KINDS:
        actual = []
        for path in sorted((root / 'resources' / kind).glob('*.tres')):
            match = re.search(r'^id = "([^"]+)"', path.read_text(), re.M)
            if not match or match.group(1) != path.stem:
                id_errors.append(f'Invalid ID/filename: {path.relative_to(root)}')
            if match:
                actual.append(match.group(1))
        if sorted(actual) != ids.get(kind):
            id_errors.append(f'Stable catalog IDs changed: {kind}; review migrations and the ID baseline explicitly')
    if id_errors:
        return id_errors
    with tempfile.TemporaryDirectory(prefix='nullborn-generation-') as directory:
        stage = Path(directory)
        (stage / 'tools').mkdir()
        # Mutation generation needs its output directory and the historical input brief.
        (stage / 'resources/mutations').mkdir(parents=True)
        shutil.copyfile(root / 'NULLBORN_CODEX_ERWEITERUNG_PHASE_E.md', stage / 'NULLBORN_CODEX_ERWEITERUNG_PHASE_E.md')
        for name in ('generate_data.py', 'generate_mutations.py'):
            shutil.copyfile(root / 'tools' / name, stage / 'tools' / name)
            subprocess.run([sys.executable, str(stage / 'tools' / name)], check=True, capture_output=True, text=True, timeout=30)
        generated = {p.relative_to(stage) for p in (stage / 'resources').rglob('*.tres')}
        generated.update(p.relative_to(stage) for p in (stage / 'scripts').rglob('*.gd'))
        expected = {p.relative_to(root) for kind in KINDS for p in (root / 'resources' / kind).glob('*.tres')}
        expected.update(Path('scripts/data') / (name + '.gd') for name in DATA_SCRIPTS)
        errors = [f'Missing generated file: {p}' for p in sorted(expected - generated)]
        errors += [f'Unexpected generated file: {p}' for p in sorted(generated - expected)]
        for p in sorted(generated & expected):
            if (stage / p).read_bytes() != (root / p).read_bytes():
                errors.append(f'Definition drift (IDs/values/text/script): {p}')
        return errors

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    try:
        errors = check(args.root.resolve())
    except (OSError, subprocess.SubprocessError) as error:
        print(f'FAIL staged generation: {error}', file=sys.stderr)
        return 1
    for error in errors:
        print('FAIL ' + error, file=sys.stderr)
    if errors:
        return 1
    print('PASS staged generators: exact catalog file set and byte-identical definitions/scripts; project untouched')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
