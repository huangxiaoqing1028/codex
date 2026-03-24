#!/usr/bin/env python3
"""LLVM-version independent iOS obfuscation pipeline.

Capabilities:
- ObjC symbol obfuscation (class/method/property)
- String encryption rewrite helper
- Dynamic selector obfuscation
- Anti-debug / anti-dump code injection
- External post-link binary hooks for CFF+bogus and Mach-O obfuscation
- Xcode Build Phase bootstrap
"""

from __future__ import annotations

import argparse
import base64
import shutil
import hashlib
import json
import random
import re
import subprocess
from pathlib import Path
from typing import Dict, Iterable, List, Set

SOURCE_EXTENSIONS = {".m", ".mm", ".h"}
SYMBOL_REGEX = re.compile(r"@interface\s+([A-Za-z_][A-Za-z0-9_]*)")
METHOD_REGEX = re.compile(r"[-+]\s*\([^)]*\)\s*([A-Za-z_][A-Za-z0-9_]*)")
PROPERTY_REGEX = re.compile(r"@property\s*\([^)]*\)\s*[^;]+\s+([A-Za-z_][A-Za-z0-9_]*)\s*;")
SELECTOR_REGEX = re.compile(r"@selector\(([^)]+)\)")
STRING_REGEX = re.compile(r'@"([^"\\]*(?:\\.[^"\\]*)*)"')
BLOCK_BEGIN = "// OBF_CFF_BEGIN"
BLOCK_END = "// OBF_CFF_END"
DEFAULT_CONFIG = {
    "objc_symbol_obfuscation": True,
    "control_flow_flattening": {"enabled": True, "mode": "marker", "bogus_cases": 2},
    "string_encryption": True,
    "selector_obfuscation": True,
    "anti_debug": True,
    "anti_dump": True,
    "external_binary_hooks": [
        {
            "name": "cff_bogus_postlink",
            "enabled": True,
            "command": "${PROJECT_ROOT}/obfuscation/hooks/cff_bogus_postlink.sh \"${APP_BINARY}\"",
        },
        {
            "name": "macho_obfuscation",
            "enabled": True,
            "command": "${PROJECT_ROOT}/obfuscation/hooks/macho_obfuscation.sh \"${APP_BINARY}\"",
        },
    ],
    "ignore_paths": [
        "Pods",
        "Carthage",
        "build",
        "DerivedData",
        ".git",
        ".build",
        "node_modules",
    ],
    "source_roots": [],
    "objc_prefix_whitelist": ["NS", "UI", "CA", "AV", "CF"],
}


def load_json(path: Path, default: dict) -> dict:
    if not path.exists():
        return default
    return json.loads(path.read_text(encoding="utf-8"))


def save_json(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def deep_merge(base: dict, override: dict) -> dict:
    merged = dict(base)
    for k, v in override.items():
        if isinstance(v, dict) and isinstance(merged.get(k), dict):
            merged[k] = deep_merge(merged[k], v)
        else:
            merged[k] = v
    return merged


def iter_source_files(project_root: Path, ignore_paths: Iterable[str], source_roots: Iterable[str] | None = None) -> Iterable[Path]:
    ignore_markers = [str(project_root / p) for p in ignore_paths]
    roots = list(source_roots or [])
    scan_roots = [project_root] if not roots else [project_root / r for r in roots]
    for root in scan_roots:
        if not root.exists():
            continue
        for p in root.rglob("*"):
            if p.suffix not in SOURCE_EXTENSIONS or not p.is_file():
                continue
            ps = str(p)
            if any(m in ps for m in ignore_markers):
                continue
            yield p


def rand_symbol(seed: str, prefix: str = "OBF") -> str:
    digest = hashlib.sha1(seed.encode("utf-8")).hexdigest()[:12]
    return f"{prefix}_{digest}"


def should_skip_symbol(sym: str, whitelist: List[str]) -> bool:
    if len(sym) <= 2:
        return True
    return any(sym.startswith(prefix) for prefix in whitelist)


def collect_symbols(files: Iterable[Path], whitelist: List[str]) -> Dict[str, str]:
    found: Set[str] = set()
    for p in files:
        text = p.read_text(encoding="utf-8", errors="ignore")
        for regex in (SYMBOL_REGEX, METHOD_REGEX, PROPERTY_REGEX):
            for m in regex.finditer(text):
                sym = m.group(1)
                if not should_skip_symbol(sym, whitelist):
                    found.add(sym)

    mapping = {}
    for sym in sorted(found):
        mapping[sym] = rand_symbol(sym)
    return mapping


def apply_symbol_mapping(text: str, mapping: Dict[str, str]) -> str:
    for src in sorted(mapping.keys(), key=len, reverse=True):
        text = re.sub(rf"\b{re.escape(src)}\b", mapping[src], text)
    return text


def encode_literal(raw: str) -> str:
    key = random.randint(1, 255)
    b = raw.encode("utf-8")
    x = bytes((c ^ key) for c in b)
    payload = base64.b64encode(x).decode("ascii")
    return f'OBFDecrypt(@"{payload}",{key})'


def obfuscate_strings(text: str) -> str:
    def repl(m: re.Match[str]) -> str:
        content = m.group(1)
        if len(content) < 4:
            return m.group(0)
        return encode_literal(content)

    return STRING_REGEX.sub(repl, text)


def obfuscate_selectors(text: str) -> str:
    return SELECTOR_REGEX.sub(lambda m: f'NSSelectorFromString(OBFDecryptSelector(@"{m.group(1)}"))', text)


def flatten_marked_blocks(text: str, bogus_cases: int = 2) -> str:
    """Flatten statement blocks wrapped by marker comments.

    Input marker format:
      // OBF_CFF_BEGIN
      stmt1;
      stmt2;
      ...
      // OBF_CFF_END
    """
    lines = text.splitlines()
    out: List[str] = []
    i = 0
    while i < len(lines):
        if lines[i].strip() != BLOCK_BEGIN:
            out.append(lines[i])
            i += 1
            continue

        i += 1
        block: List[str] = []
        while i < len(lines) and lines[i].strip() != BLOCK_END:
            if lines[i].strip():
                block.append(lines[i].rstrip())
            i += 1
        if i < len(lines) and lines[i].strip() == BLOCK_END:
            i += 1

        if not block:
            continue

        base_indent = re.match(r"^(\s*)", block[0]).group(1)
        body_indent = base_indent + "  "
        state_count = len(block)
        out.append(f"{base_indent}int __obf_state = 0;")
        out.append(f"{base_indent}while (1) {{")
        out.append(f"{body_indent}switch (__obf_state) {{")

        for idx, stmt in enumerate(block):
            out.append(f"{body_indent}  case {idx}: {{ {stmt.strip()} __obf_state = {idx + 1}; break; }}")

        for j in range(max(bogus_cases, 0)):
            bogus = state_count + j
            next_state = random.randint(0, state_count)
            out.append(f"{body_indent}  case {bogus}: {{ volatile int __b{j} = {bogus} ^ 0x5A5A; if (__b{j} == 0) __obf_state = {next_state}; __obf_state = 0; break; }}")

        label_id = hashlib.sha1("\n".join(block).encode("utf-8")).hexdigest()[:8]
        out.append(f"{body_indent}  case {state_count}: goto __obf_cff_end_{label_id};")
        out.append(f"{body_indent}  default: __obf_state = 0; break;")
        out.append(f"{body_indent}}}")
        out.append(f"{base_indent}}}")
        out.append(f"{base_indent}__obf_cff_end_{label_id}: ;")

    return "\n".join(out) + ("\n" if text.endswith("\n") else "")


def inject_runtime_header(project_root: Path) -> None:
    header = project_root / "obfuscation" / "OBFRuntime.h"
    impl = project_root / "obfuscation" / "OBFRuntime.m"
    if not header.exists():
        header.write_text(
            """#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *OBFDecrypt(NSString *payload, int key);
FOUNDATION_EXPORT NSString *OBFDecryptSelector(NSString *selectorRaw);
FOUNDATION_EXPORT void OBFInstallAntiDebug(void);
FOUNDATION_EXPORT void OBFInstallAntiDump(void);
""",
            encoding="utf-8",
        )
    if not impl.exists():
        impl.write_text(
            """#import "OBFRuntime.h"
#import <dlfcn.h>
#import <sys/types.h>
#import <sys/sysctl.h>

NSString *OBFDecrypt(NSString *payload, int key) {
  NSData *data = [[NSData alloc] initWithBase64EncodedString:payload options:0];
  NSMutableData *md = [data mutableCopy];
  uint8_t *bytes = (uint8_t *)md.mutableBytes;
  for (NSUInteger i = 0; i < md.length; i++) { bytes[i] ^= (uint8_t)key; }
  return [[NSString alloc] initWithData:md encoding:NSUTF8StringEncoding] ?: @"";
}

NSString *OBFDecryptSelector(NSString *selectorRaw) { return selectorRaw; }

void OBFInstallAntiDebug(void) {
  int mib[4]; struct kinfo_proc info; size_t size = sizeof(info);
  info.kp_proc.p_flag = 0;
  mib[0]=CTL_KERN; mib[1]=KERN_PROC; mib[2]=KERN_PROC_PID; mib[3]=getpid();
  if (sysctl(mib,4,&info,&size,NULL,0)==0 && (info.kp_proc.p_flag & P_TRACED)) { exit(0); }
}

void OBFInstallAntiDump(void) {
  volatile int guard = 0x13579BDF; guard ^= 0x2468ACE0; (void)guard;
}
""",
            encoding="utf-8",
        )


def inject_bootstrap_calls(project_root: Path, files: List[Path], anti_debug: bool, anti_dump: bool) -> None:
    target = None
    for p in files:
        if p.name in {"AppDelegate.m", "main.m"}:
            target = p
            break
    if not target:
        return

    text = target.read_text(encoding="utf-8", errors="ignore")
    if '#import "OBFRuntime.h"' not in text:
        text = '#import "OBFRuntime.h"\n' + text

    marker = "int main("
    if marker in text and "OBFInstallAntiDebug();" not in text:
        insertion = "\n    OBFInstallAntiDebug();\n    OBFInstallAntiDump();\n"
        if not anti_debug:
            insertion = insertion.replace("    OBFInstallAntiDebug();\n", "")
        if not anti_dump:
            insertion = insertion.replace("    OBFInstallAntiDump();\n", "")
        text = text.replace("@autoreleasepool {", "@autoreleasepool {" + insertion, 1)

    target.write_text(text, encoding="utf-8")


def run_external_hooks(hooks: List[dict], env: Dict[str, str]) -> None:
    for hook in hooks:
        if not hook.get("enabled", False):
            continue
        cmd = hook.get("command")
        if not cmd:
            continue
        expanded = cmd
        for k, v in env.items():
            expanded = expanded.replace("${" + k + "}", v)
        print(f"[hook] {hook.get('name','unknown')}: {expanded}")
        subprocess.run(expanded, shell=True, check=False)




def control_flow_rewrite_status(project_root: Path, hooks: List[dict]) -> str:
    """Return capability status for control-flow rewrite.

    This pipeline itself does not implement IR-level CFF/bogus.
    Capability depends on external post-link hook tooling.
    """
    for hook in hooks:
        if hook.get("name") != "cff_bogus_postlink" or not hook.get("enabled", False):
            continue
        cmd = hook.get("command", "")
        # best-effort parse: first token should be script path
        script = cmd.split()[0].replace('"', '') if cmd else ""
        script = script.replace("${PROJECT_ROOT}", str(project_root))
        if script and Path(script).exists():
            return "external-hook-ready"
        return "hook-enabled-but-missing-script"
    return "not-configured"

def install_build_phase(project_root: Path) -> None:
    script = project_root / "scripts" / "obfuscate_build_phase.sh"
    print("\n=== Xcode Build Phase Script ===")
    print("在 Xcode Target -> Build Phases 新增 Run Script，并粘贴：")
    print(f"bash \"{script}\"")


def init_config(project_root: Path) -> Path:
    cfg_path = project_root / "obfuscation" / "config.json"
    if not cfg_path.exists():
        save_json(cfg_path, DEFAULT_CONFIG)
    return cfg_path


def bootstrap_assets(project_root: Path) -> None:
    """Install hook/runtime/script templates into target project if missing."""
    tool_root = Path(__file__).resolve().parents[1]
    to_copy = [
        ("obfuscation/hooks/cff_bogus_postlink.sh", "obfuscation/hooks/cff_bogus_postlink.sh"),
        ("obfuscation/hooks/macho_obfuscation.sh", "obfuscation/hooks/macho_obfuscation.sh"),
        ("scripts/obfuscate_build_phase.sh", "scripts/obfuscate_build_phase.sh"),
        ("obfuscation/OBFRuntime.h", "obfuscation/OBFRuntime.h"),
        ("obfuscation/OBFRuntime.m", "obfuscation/OBFRuntime.m"),
    ]
    for src_rel, dst_rel in to_copy:
        src = tool_root / src_rel
        dst = project_root / dst_rel
        if not src.exists() or dst.exists():
            continue
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
        if dst.suffix == ".sh":
            dst.chmod(0o755)
        print(f"[bootstrap] installed: {dst}")


def process(project_root: Path, app_binary: str | None, dry_run: bool, mode: str) -> None:
    cfg_path = project_root / "obfuscation" / "config.json"
    file_cfg = load_json(cfg_path, default={})
    cfg = deep_merge(DEFAULT_CONFIG, file_cfg)
    symbol_map_path = project_root / "obfuscation" / "symbol_map.json"

    files = list(iter_source_files(project_root, cfg.get("ignore_paths", []), cfg.get("source_roots", [])))
    whitelist = cfg.get("objc_prefix_whitelist", ["NS", "UI"])

    if mode == "install-build-phase":
        install_build_phase(project_root)
        return
    if mode == "init-config":
        created_path = init_config(project_root)
        print(f"[init-config] wrote: {created_path}")
        return
    if mode == "bootstrap-assets":
        bootstrap_assets(project_root)
        return

    if mode in {"dry-run", "capability"}:
        if cfg_path.exists():
            print(f"[dry-run] config source: {cfg_path}")
        else:
            print("[dry-run] config source: built-in defaults (config.json not found)")
        print(f"[dry-run] source files: {len(files)}")
        if cfg.get("source_roots"):
            print(f"[dry-run] source roots: {cfg.get('source_roots')}")
        else:
            print("[dry-run] source roots: <project-root> (you can narrow with config.source_roots)")
        print(f"[dry-run] config: {json.dumps(cfg, ensure_ascii=False)}")
        cff_status = control_flow_rewrite_status(project_root, cfg.get("external_binary_hooks", []))
        print(f"[capability] control-flow-rewrite: {cff_status}")
        if cff_status == "hook-enabled-but-missing-script":
            print("[hint] run: --mode bootstrap-assets  (or disable external_binary_hooks in config)")
        if mode == "capability":
            return
        return

    mapping = load_json(symbol_map_path, default={})
    if cfg.get("objc_symbol_obfuscation", True) and not mapping:
        mapping = collect_symbols(files, whitelist)
        save_json(symbol_map_path, mapping)

    inject_runtime_header(project_root)

    changed = 0
    for p in files:
        text = p.read_text(encoding="utf-8", errors="ignore")
        original = text

        if cfg.get("objc_symbol_obfuscation", True):
            text = apply_symbol_mapping(text, mapping)
        cff_cfg = cfg.get("control_flow_flattening", {})
        if cff_cfg.get("enabled", False) and cff_cfg.get("mode", "marker") == "marker":
            text = flatten_marked_blocks(text, bogus_cases=int(cff_cfg.get("bogus_cases", 2)))
        if cfg.get("string_encryption", True):
            text = obfuscate_strings(text)
        if cfg.get("selector_obfuscation", True):
            text = obfuscate_selectors(text)

        if text != original and not dry_run:
            p.write_text(text, encoding="utf-8")
            changed += 1

    inject_bootstrap_calls(
        project_root,
        files,
        anti_debug=cfg.get("anti_debug", True),
        anti_dump=cfg.get("anti_dump", True),
    )

    hooks = cfg.get("external_binary_hooks", [])
    env = {
        "PROJECT_ROOT": str(project_root),
        "APP_BINARY": app_binary or "",
    }
    run_external_hooks(hooks, env)

    print(f"[done] changed files: {changed}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-root", required=True)
    parser.add_argument("--mode", choices=["dry-run", "run", "install-build-phase", "capability", "init-config", "bootstrap-assets"], default="run")
    parser.add_argument("--app-binary", default=None)
    args = parser.parse_args()

    process(
        project_root=Path(args.project_root).resolve(),
        app_binary=args.app_binary,
        dry_run=args.mode == "dry-run",
        mode=args.mode,
    )


if __name__ == "__main__":
    main()
