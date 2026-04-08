import json
import tempfile
import unittest
from pathlib import Path

from obfuscator.config_loader import build_config
from obfuscator.engine import run, validate, rollback


class _Args:
    def __init__(self, project_root, action="obfuscate"):
        self.project_root = str(project_root)
        self.config = None
        self.action = action
        self.mode = "stable"
        self.seed = "unit-seed"
        self.name_style = "hex"
        self.in_place = True
        self.output_root = None
        self.mapping = str(project_root / "obfuscation" / "mapping.json")
        self.backup_dir = str(project_root / "obfuscation" / "backup")
        self.disable_risky_skip = False
        self.disable_file_rename = False
        self.disable_strings = False
        self.whitelist_file = None
        self.blacklist_file = None
        self.reuse_mapping = False
        self.obfuscate_protocol = True
        self.source_target = None
        self.rename_target = None
        self.source_project = None
        self.rename_project = None
        self.source_scheme = None
        self.rename_scheme = None
        self.verbose = False


class EngineTests(unittest.TestCase):
    def test_obfuscate_validate_rollback(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            (root / "App").mkdir()
            (root / "App" / "Foo.h").write_text("@interface Foo : NSObject\n@property(nonatomic,strong) NSString *name;\n@end\n", encoding="utf-8")
            (root / "App" / "Foo.m").write_text("@implementation Foo\n- (void)bar:(id)x {}\n@end\n", encoding="utf-8")
            (root / "App" / "Main.storyboard").write_text("customClass=\"Foo\"", encoding="utf-8")
            (root / "project.pbxproj").write_text("Foo.m Foo.h", encoding="utf-8")

            cfg = build_config(_Args(root, action="obfuscate"))
            ctx = run(cfg)
            self.assertTrue(ctx.mapping["class"].get("Foo"))

            ok, errs = validate(Path(cfg.mapping_path))
            self.assertTrue(ok, msg=str(errs))

            restored = rollback(Path(cfg.mapping_path))
            self.assertGreaterEqual(restored, 1)

    def test_stable_mapping_is_repeatable(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            (root / "A.h").write_text("@interface Foo: NSObject @end", encoding="utf-8")
            (root / "A.m").write_text("@implementation Foo @end", encoding="utf-8")

            args = _Args(root, action="dry-run")
            cfg1 = build_config(args)
            m1 = run(cfg1).mapping

            cfg2 = build_config(args)
            m2 = run(cfg2).mapping
            self.assertEqual(m1["class"], m2["class"])

    def test_structured_pbxproj_and_podfile_rename(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            (root / "App.h").write_text("@interface Foo: NSObject @end", encoding="utf-8")
            (root / "App.m").write_text("@implementation Foo @end", encoding="utf-8")
            (root / "project.pbxproj").write_text(
                "name = MyApp;\\nPRODUCT_NAME = MyApp;\\npath = MyApp.xcodeproj;\\n",
                encoding="utf-8",
            )
            (root / "Podfile").write_text(
                "target 'MyApp' do\\n  project 'MyApp.xcodeproj'\\n  workspace 'MyApp.xcworkspace'\\nend\\n",
                encoding="utf-8",
            )

            args = _Args(root, action="obfuscate")
            args.source_target = "MyApp"
            args.rename_target = "MyAppA"
            args.source_project = "MyApp"
            args.rename_project = "MyAppA"
            args.source_scheme = "MyApp"
            args.rename_scheme = "MyAppA"

            cfg = build_config(args)
            run(cfg)

            pbx = (root / "project.pbxproj").read_text(encoding="utf-8")
            pod = (root / "Podfile").read_text(encoding="utf-8")
            self.assertIn("MyAppA", pbx)
            self.assertNotIn("name = MyApp;", pbx)
            self.assertIn("target 'MyAppA'", pod)


if __name__ == "__main__":
    unittest.main()
