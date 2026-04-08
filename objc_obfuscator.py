#!/usr/bin/env python3
"""Objective-C 主工程可控混淆工具（保守优先、可回滚）。"""

from __future__ import annotations

import argparse
import dataclasses
import hashlib
import json
import random
import re
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, Iterable, List, Sequence, Set, Tuple

SOURCE_EXTENSIONS = {".h", ".m", ".mm"}
SYNC_EXTENSIONS = {".h", ".m", ".mm", ".xib", ".storyboard", ".pbxproj", ".strings", ".plist"}
OBF_PREFIX = "OBF_"

DEFAULT_EXCLUDE_DIRS = {
    "Pods",
    "Carthage",
    "ThirdParty",
    "Third_Party",
    "Vendor",
    "Vendors",
    "build",
    ".git",
    ".svn",
}

HIGH_RISK_NAMES = {
    "AppDelegate",
    "SceneDelegate",
    "main",
    "load",
    "initialize",
    "dealloc",
    "viewDidLoad",
    "copyWithZone",
    "encodeWithCoder",
    "initWithCoder",
}

CLASS_PATTERN = re.compile(r"@interface\s+([A-Za-z_][A-Za-z0-9_]*)|@implementation\s+([A-Za-z_][A-Za-z0-9_]*)")
PROPERTY_PATTERN = re.compile(r"@property\s*\([^\)]*\)\s*[^;]*\b([A-Za-z_][A-Za-z0-9_]*)\s*;")
IVAR_BLOCK_PATTERN = re.compile(r"\{([^}]*)\}", re.S)
IVAR_ITEM_PATTERN = re.compile(r"\b([A-Za-z_][A-Za-z0-9_]*)\s*;")
METHOD_PATTERN = re.compile(r"^[ \t]*[+-]\s*\([^\)]*\)\s*([A-Za-z_][A-Za-z0-9_]*)(?=\s*[:;{])", re.M)
SELECTOR_HEAD_PATTERN = re.compile(r"^[ \t]*[+-]\s*\([^\)]*\)\s*([A-Za-z_][A-Za-z0-9_]*)(?=\s*:)", re.M)


@dataclasses.dataclass
class Config:
    project_root: Path
    workspace_root: Path
    include_dirs: List[Path]
    exclude_dirs: Set[str]
    whitelist: Set[str]
    blacklist: Set[str]
    skip_risky: bool
    apply_strings: bool
    rename_files: bool
    mode: str
    seed: str
    action: str
    dry_run: bool
    in_place: bool
    output_root: Path
    mapping_path: Path
    backup_dir: Path


@dataclasses.dataclass
class ScanResult:
    classes: Set[str]
    methods: Set[str]
    properties: Set[str]
    ivars: Set[str]


def load_json(path: Path) -> dict:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def normalize_names(items: Iterable[str]) -> Set[str]:
    return {x.strip() for x in items if isinstance(x, str) and x.strip()}


def is_system_like(name: str) -> bool:
    return name.startswith(("NS", "UI", "CA", "CF", "AV", "WK", "MTL", "OS", "GK", "SK"))


def stable_name(symbol: str, seed: str) -> str:
    digest = hashlib.sha1(f"{seed}:{symbol}".encode("utf-8")).hexdigest()[:12]
    return f"{OBF_PREFIX}{digest}"


def variant_name(symbol: str, seed: str, rng: random.Random) -> str:
    digest = hashlib.md5(f"{seed}:{symbol}".encode("utf-8")).hexdigest()[:4]
    pool = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    suffix = "".join(rng.choice(pool) for _ in range(10))
    return f"{OBF_PREFIX}{digest}{suffix}"


def build_config(args: argparse.Namespace) -> Config:
    cfg_file = load_json(Path(args.config).resolve()) if args.config else {}
    project_root = Path(args.project_root).resolve()

    in_place = args.in_place
    output_root = Path(args.output_root).resolve() if args.output_root else project_root.parent / f"{project_root.name}_obfuscated"
    workspace_root = project_root if in_place else output_root

    include_dirs: List[Path] = [workspace_root]
    for rel in cfg_file.get("include_dirs", []):
        include_dirs.append((workspace_root / rel).resolve())

    exclude_dirs = set(DEFAULT_EXCLUDE_DIRS)
    exclude_dirs.update(normalize_names(cfg_file.get("exclude_dirs", [])))

    whitelist = normalize_names(cfg_file.get("whitelist", []))
    blacklist = normalize_names(cfg_file.get("blacklist", []))

    if args.whitelist_file:
        whitelist.update(normalize_names(Path(args.whitelist_file).read_text(encoding="utf-8").splitlines()))
    if args.blacklist_file:
        blacklist.update(normalize_names(Path(args.blacklist_file).read_text(encoding="utf-8").splitlines()))

    action = args.action
    dry_run = action == "dry-run"

    return Config(
        project_root=project_root,
        workspace_root=workspace_root,
        include_dirs=include_dirs,
        exclude_dirs=exclude_dirs,
        whitelist=whitelist,
        blacklist=blacklist,
        skip_risky=not args.disable_risky_skip,
        apply_strings=not args.disable_strings,
        rename_files=not args.disable_file_rename,
        mode=args.mode,
        seed=args.seed,
        action=action,
        dry_run=dry_run,
        in_place=in_place,
        output_root=output_root,
        mapping_path=Path(args.mapping).resolve(),
        backup_dir=Path(args.backup_dir).resolve(),
    )


def prepare_workspace(cfg: Config) -> None:
    if cfg.in_place or cfg.dry_run or cfg.action in {"validate", "rollback"}:
        return
    if cfg.output_root.exists():
        shutil.rmtree(cfg.output_root)
    shutil.copytree(cfg.project_root, cfg.output_root, dirs_exist_ok=False)


def should_skip(path: Path, cfg: Config) -> bool:
    if set(path.parts) & cfg.exclude_dirs:
        return True
    return path.suffix not in SYNC_EXTENSIONS


def iter_files(cfg: Config) -> List[Path]:
    out: List[Path] = []
    seen: Set[Path] = set()
    for inc in cfg.include_dirs:
        if not inc.exists():
            continue
        for p in inc.rglob("*"):
            if not p.is_file():
                continue
            rp = p.resolve()
            if rp in seen:
                continue
            seen.add(rp)
            rel = rp.relative_to(cfg.workspace_root)
            if should_skip(rel, cfg):
                continue
            out.append(rp)
    return out


def scan_symbols(files: Sequence[Path]) -> ScanResult:
    classes: Set[str] = set()
    methods: Set[str] = set()
    properties: Set[str] = set()
    ivars: Set[str] = set()
    for f in files:
        if f.suffix not in SOURCE_EXTENSIONS:
            continue
        text = f.read_text(encoding="utf-8", errors="ignore")
        for a, b in CLASS_PATTERN.findall(text):
            classes.add(a or b)
        properties.update(PROPERTY_PATTERN.findall(text))
        methods.update(METHOD_PATTERN.findall(text))
        methods.update(SELECTOR_HEAD_PATTERN.findall(text))
        for blk in IVAR_BLOCK_PATTERN.findall(text):
            for item in IVAR_ITEM_PATTERN.findall(blk):
                if len(item) > 2:
                    ivars.add(item)
    return ScanResult(classes=classes, methods=methods, properties=properties, ivars=ivars)


def eligible(name: str, cfg: Config) -> bool:
    if name in cfg.blacklist:
        return False
    if cfg.whitelist and name not in cfg.whitelist:
        return False
    if is_system_like(name):
        return False
    if cfg.skip_risky and name in HIGH_RISK_NAMES:
        return False
    return True


def build_mapping(scan: ScanResult, cfg: Config) -> Dict[str, Dict[str, str]]:
    rng = random.Random(f"{cfg.seed}:{datetime.now(timezone.utc).isoformat()}")
    groups = {
        "class": sorted(scan.classes),
        "method": sorted(scan.methods),
        "property": sorted(scan.properties),
        "ivar": sorted(scan.ivars),
    }
    mapping: Dict[str, Dict[str, str]] = {k: {} for k in groups}
    used: Set[str] = set()
    for typ, symbols in groups.items():
        for sym in symbols:
            if not eligible(sym, cfg):
                continue
            cand = stable_name(sym, cfg.seed) if cfg.mode == "stable" else variant_name(sym, cfg.seed, rng)
            while cand in used:
                cand += "X"
            mapping[typ][sym] = cand
            used.add(cand)
    return mapping


def compile_patterns(mapping: Dict[str, Dict[str, str]]) -> List[Tuple[re.Pattern, str]]:
    flat: Dict[str, str] = {}
    for block in mapping.values():
        flat.update(block)
    out: List[Tuple[re.Pattern, str]] = []
    for old, new in sorted(flat.items(), key=lambda x: len(x[0]), reverse=True):
        out.append((re.compile(rf"(?<![A-Za-z0-9_]){re.escape(old)}(?![A-Za-z0-9_])"), new))
    return out


def rewrite_text(text: str, patterns: Sequence[Tuple[re.Pattern, str]]) -> str:
    out = text
    for p, repl in patterns:
        out = p.sub(repl, out)
    return out


def ensure_backup(file_path: Path, cfg: Config) -> None:
    rel = file_path.relative_to(cfg.workspace_root)
    bk = cfg.backup_dir / rel
    bk.parent.mkdir(parents=True, exist_ok=True)
    if not bk.exists():
        shutil.copy2(file_path, bk)


def apply_symbol_mapping(files: Sequence[Path], mapping: Dict[str, Dict[str, str]], cfg: Config) -> Tuple[int, int]:
    pats = compile_patterns(mapping)
    scanned = 0
    changed = 0
    for p in files:
        if not cfg.apply_strings and p.suffix == ".strings":
            continue
        scanned += 1
        old = p.read_text(encoding="utf-8", errors="ignore")
        new = rewrite_text(old, pats)
        if new == old:
            continue
        changed += 1
        if not cfg.dry_run:
            ensure_backup(p, cfg)
            p.write_text(new, encoding="utf-8")
    return scanned, changed


def rename_files(files: Sequence[Path], class_mapping: Dict[str, str], cfg: Config) -> List[Tuple[str, str]]:
    if not cfg.rename_files:
        return []
    rename_pairs: List[Tuple[Path, Path]] = []
    for p in files:
        if p.suffix not in SOURCE_EXTENSIONS:
            continue
        stem = p.stem
        if stem in class_mapping:
            dst = p.with_name(class_mapping[stem] + p.suffix)
            if dst != p:
                rename_pairs.append((p, dst))

    # 防止路径冲突：按路径长度倒序 rename
    rename_pairs.sort(key=lambda pair: len(str(pair[0])), reverse=True)
    result: List[Tuple[str, str]] = []
    for src, dst in rename_pairs:
        if not src.exists():
            continue
        if dst.exists():
            continue
        if not cfg.dry_run:
            ensure_backup(src, cfg)
            src.rename(dst)
        result.append((str(src.relative_to(cfg.workspace_root)), str(dst.relative_to(cfg.workspace_root))))
    return result


def write_mapping(cfg: Config, mapping: Dict[str, Dict[str, str]], renamed_files: List[Tuple[str, str]], files_total: int, files_changed: int) -> None:
    data = {
        "version": 2,
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "action": cfg.action,
        "mode": cfg.mode,
        "seed": cfg.seed,
        "project_root": str(cfg.project_root),
        "workspace_root": str(cfg.workspace_root),
        "in_place": cfg.in_place,
        "backup_dir": str(cfg.backup_dir),
        "files_total": files_total,
        "files_changed": files_changed,
        "renamed_files": [{"from": a, "to": b} for a, b in renamed_files],
        "mapping": mapping,
    }
    cfg.mapping_path.parent.mkdir(parents=True, exist_ok=True)
    cfg.mapping_path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")


def rollback(mapping_path: Path) -> int:
    info = load_json(mapping_path)
    workspace_root = Path(info.get("workspace_root", ""))
    backup_dir = Path(info.get("backup_dir", ""))
    if not workspace_root.exists() or not backup_dir.exists():
        raise RuntimeError("mapping 中 workspace_root/backup_dir 无效，无法回滚")
    restored = 0
    for bk in backup_dir.rglob("*"):
        if not bk.is_file():
            continue
        rel = bk.relative_to(backup_dir)
        dst = workspace_root / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(bk, dst)
        restored += 1
    return restored


def validate(mapping_path: Path) -> Tuple[bool, List[str]]:
    info = load_json(mapping_path)
    errs: List[str] = []
    required = ["version", "workspace_root", "backup_dir", "mapping", "mode", "seed"]
    for k in required:
        if k not in info:
            errs.append(f"missing key: {k}")
    if info.get("mode") not in {"stable", "variant"}:
        errs.append("mode must be stable or variant")

    mapping = info.get("mapping", {})
    if not isinstance(mapping, dict):
        errs.append("mapping must be dict")
    else:
        flat_vals: List[str] = []
        for k in ("class", "method", "property", "ivar"):
            block = mapping.get(k, {})
            if not isinstance(block, dict):
                errs.append(f"mapping.{k} must be dict")
                continue
            flat_vals.extend(block.values())
        if len(flat_vals) != len(set(flat_vals)):
            errs.append("mapped names must be unique")

    return (len(errs) == 0, errs)


def run_obfuscation(cfg: Config) -> int:
    prepare_workspace(cfg)
    files = iter_files(cfg)
    scan = scan_symbols(files)
    mapping = build_mapping(scan, cfg)
    scanned, changed = apply_symbol_mapping(files, mapping, cfg)

    # 文件名混淆后，pbxproj/xib/storyboard 通过前面的文本替换已经完成引用同步
    renamed_files = rename_files(files, mapping["class"], cfg)

    write_mapping(cfg, mapping, renamed_files, scanned, changed + len(renamed_files))
    print("[summary]")
    print(f"  action: {cfg.action}")
    print(f"  mode: {cfg.mode}")
    print(f"  workspace: {cfg.workspace_root}")
    print(f"  dry_run: {cfg.dry_run}")
    print(f"  scanned_files: {scanned}")
    print(f"  changed_files: {changed}")
    print(f"  renamed_files: {len(renamed_files)}")
    print(f"  mapping: {cfg.mapping_path}")
    if not cfg.dry_run:
        print(f"  backup: {cfg.backup_dir}")
    return 0


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Objective-C 主工程可控混淆工具")
    p.add_argument("--project-root", default=".", help="原工程根目录")
    p.add_argument("--config", help="JSON 配置文件")
    p.add_argument("--action", choices=["dry-run", "obfuscate", "validate", "rollback"], default="dry-run")
    p.add_argument("--mode", choices=["stable", "variant"], default="stable")
    p.add_argument("--seed", default="release-seed")
    p.add_argument("--in-place", action="store_true", help="直接修改 project-root（默认否，默认复制到 output-root）")
    p.add_argument("--output-root", help="非 in-place 模式下的输出工程目录")
    p.add_argument("--mapping", default="obfuscation/mapping.json")
    p.add_argument("--backup-dir", default="obfuscation/backup")
    p.add_argument("--disable-risky-skip", action="store_true", help="关闭高风险默认跳过")
    p.add_argument("--disable-file-rename", action="store_true", help="关闭文件名混淆")
    p.add_argument("--disable-strings", action="store_true")
    p.add_argument("--whitelist-file")
    p.add_argument("--blacklist-file")
    return p


def main() -> int:
    args = build_parser().parse_args()
    cfg = build_config(args)

    if cfg.action == "validate":
        ok, errs = validate(cfg.mapping_path)
        if ok:
            print("[validate] mapping is valid")
            return 0
        print("[validate] mapping is invalid")
        for err in errs:
            print(f"  - {err}")
        return 2

    if cfg.action == "rollback":
        restored = rollback(cfg.mapping_path)
        print(f"[rollback] restored files: {restored}")
        return 0

    return run_obfuscation(cfg)


if __name__ == "__main__":
    sys.exit(main())
