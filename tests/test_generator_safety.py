"""Real isolated generator checks; no production catalog is rewritten."""
import importlib.util
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('check_generated', ROOT / 'tools/check_generated.py')
checker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(checker)

class GeneratorSafety(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='nullborn-generator-test-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / 'tools').mkdir()
        for name in ['generate_data.py', 'generate_mutations.py', 'catalog_ids.json']:
            shutil.copyfile(ROOT / 'tools' / name, self.root / 'tools' / name)
        shutil.copyfile(ROOT / 'NULLBORN_CODEX_ERWEITERUNG_PHASE_E.md', self.root / 'NULLBORN_CODEX_ERWEITERUNG_PHASE_E.md')
        for kind in checker.KINDS:
            shutil.copytree(ROOT / 'resources' / kind, self.root / 'resources' / kind)
        for name in checker.DATA_SCRIPTS:
            target = self.root / 'scripts/data' / (name + '.gd')
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / 'scripts/data' / target.name, target)

    def test_clean_and_read_only(self):
        before = {p.relative_to(self.root): p.read_bytes() for p in self.root.rglob('*') if p.is_file()}
        self.assertEqual(checker.check(self.root), [])
        self.assertEqual(before, {p.relative_to(self.root): p.read_bytes() for p in self.root.rglob('*') if p.is_file()})

    def test_numeric_drift(self):
        p = self.root / 'resources/weapons/arcane_needle.tres'
        p.write_text(p.read_text().replace('"damage": 13', '"damage": 14'))
        self.assertTrue(any('Definition drift' in x for x in checker.check(self.root)))

    def test_changed_id(self):
        p = self.root / 'resources/weapons/arcane_needle.tres'
        p.write_text(p.read_text().replace('id = "arcane_needle"', 'id = "renamed_needle"'))
        self.assertTrue(any('ID' in x for x in checker.check(self.root)))

    def test_missing_definition(self):
        (self.root / 'resources/weapons/arcane_needle.tres').unlink()
        self.assertTrue(any('IDs changed' in x for x in checker.check(self.root)))

    def test_extra_stale_definition(self):
        p = self.root / 'resources/mutations/stale_mutation.tres'
        p.write_text('id = "stale_mutation"\n')
        self.assertTrue(any('IDs changed' in x for x in checker.check(self.root)))

    def test_generated_script_drift(self):
        (self.root / 'scripts/data/weapon_definition.gd').write_text('extends Node\n')
        self.assertTrue(any('weapon_definition.gd' in x for x in checker.check(self.root)))

    def test_failed_generator_is_not_success(self):
        (self.root / 'tools/generate_mutations.py').write_text('raise RuntimeError("simulated generator failure")\n')
        with self.assertRaises(subprocess.CalledProcessError):
            checker.check(self.root)

if __name__ == '__main__':
    unittest.main()
