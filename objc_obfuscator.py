#!/usr/bin/env python3
"""
商业稳定版 Objective-C 源码混淆脚本

特性：
1) 仅处理主工程源码，默认跳过 Pods / 第三方目录
2) 支持类名、方法名、属性名、成员变量名混淆
3) 支持 xib / storyboard / pbxproj 同步
4) 支持字符串引用同步替换
5) 支持白名单 / 黑名单 / 风险跳过
6) 支持 mapping 输出与 rollback 回滚
7) 支持 dry-run 只扫描不修改
8) stable 固定映射模式
9) variant 扰动映射模式
10) 可接入 archive / ipa 打包流程（CLI + 非交互输出）
"""

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
from typing import Dict, Iterable, List, Set, Tuple


DEFAULT_EXCLUDE_DIRS = {
    "Pods",
    "Carthage",
    "Vendor",
    "Vendors",
    "ThirdParty",
    "Third_Party",
    "build",
    ".git",
}

SOURCE_EXTENSIONS = {".h", ".m", ".mm"}
SYNC_EXTENSIONS = {".h", ".m", ".mm", ".xib", ".storyboard", ".pbxproj", ".strings", ".plist"}

OBF_PREFIX = "OBF_"

RISKY_SELECTORS = {
    "viewDidLoad",
    "dealloc",
    "load",
    "initialize",
    "init",
    "copyWithZone",
    "encodeWithCoder",
    "initWithCoder",
}


@dataclasses.dataclass
class Config:
    project_root: Path
    include_dirs: List[Path]
    exclude_dirs: Set[str]
    mode: str
    seed: str
    dry_run: bool
    skip_risky: bool
    whitelist: Set[str]
    blacklist: Set[str]
    mapping_path: Path
    backup_dir: Path
    apply_strings: bool


@dataclasses.dataclass
class ScanResult:
    classes: Set[str]
    methods: Set[str]
    properties: Set[str]
    ivars: Set[str]

    def all_symbols(self) -> Set[str]:
        return self.classes | self.methods | self.properties | self.ivars


CLASS_PATTERN = re.compile(r"@interface\s+([A-Za-z_][A-Za-z0-9_]*)|@implementation\s+([A-Za-z_][A-Za-z0-9_]*)")
PROPERTY_PATTERN = re.compile(r"@property\s*\([^\)]*\)\s*[^;]*\b([A-Za-z_][A-Za-z0-9_]*)\s*;")
IVAR_PATTERN = re.compile(r"\{([^}]*)\}", re.S)
IVAR_ITEM_PATTERN = re.compile(r"\b([A-Za-z_][A-Za-z0-9_]*)\s*;")
METHOD_PATTERN = re.compile(r"^[ \t]*[+-]\s*\([^\)]*\)\s*([A-Za-z_][A-Za-z0-9_]*)(?=\s*[:;{])", re.M)
SELECTOR_PIECE_PATTERN = re.compile(r"^[ \t]*[+-]\s*\([^\)]*\)\s*([A-Za-z_][A-Za-z0-9_]*)(?=\s*:)", re.M)


def load_json(path: Path) -> dict:
    if not path.exists():
        return {}
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def normalize_names(items: Iterable[str]) -> Set[str]:
    return {x.strip() for x in items if isinstance(x, str) and x.strip()}


def build_config(args: argparse.Namespace) -> Config:
    project_root = Path(args.project_root).resolve()
    cfg = load_json(Path(args.config)) if args.config else {}

    include_dirs = [project_root]
    for rel in cfg.get("include_dirs", []):
        include_dirs.append((project_root / rel).resolve())

    exclude_dirs = set(DEFAULT_EXCLUDE_DIRS)
    exclude_dirs.update(normalize_names(cfg.get("exclude_dirs", [])))

    whitelist = normalize_names(cfg.get("whitelist", []))
    blacklist = normalize_names(cfg.get("blacklist", []))

    if args.whitelist_file:
        whitelist.update(normalize_names(Path(args.whitelist_file).read_text(encoding="utf-8").splitlines()))
    if args.blacklist_file:
        blacklist.update(normalize_names(Path(args.blacklist_file).read_text(encoding="utf-8").splitlines()))

    return Config(
        project_root=project_root,
        include_dirs=include_dirs,
        exclude_dirs=exclude_dirs,
        mode=args.mode,
        seed=args.seed,
        dry_run=args.dry_run,
        skip_risky=args.skip_risky,
        whitelist=whitelist,
        blacklist=blacklist,
        mapping_path=Path(args.mapping).resolve(),
        backup_dir=Path(args.backup_dir).resolve(),
        apply_strings=not args.disable_strings,
    )


def should_skip_file(path: Path, cfg: Config) -> bool:
    parts = set(path.parts)
    if parts & cfg.exclude_dirs:
        return True
    return not any(path.suffix == ext for ext in SYNC_EXTENSIONS)


def iter_project_files(cfg: Config) -> Iterable[Path]:
    visited = set()
    for include_dir in cfg.include_dirs:
        if not include_dir.exists():
            continue
        for p in include_dir.rglob("*"):
            if not p.is_file():
                continue
            rp = p.resolve()
            if rp in visited:
                continue
            visited.add(rp)
            rel = rp.relative_to(cfg.project_root)
            if should_skip_file(rel, cfg):
                continue
            yield rp


def scan_symbols(files: List[Path]) -> ScanResult:
    classes: Set[str] = set()
    methods: Set[str] = set()
    properties: Set[str] = set()
    ivars: Set[str] = set()

    for f in files:
        if f.suffix not in SOURCE_EXTENSIONS:
            continue
        content = f.read_text(encoding="utf-8", errors="ignore")

        for a, b in CLASS_PATTERN.findall(content):
            classes.add(a or b)

        for m in PROPERTY_PATTERN.findall(content):
            properties.add(m)

        for m in METHOD_PATTERN.findall(content):
            methods.add(m)

        for m in SELECTOR_PIECE_PATTERN.findall(content):
            methods.add(m)

        for blk in IVAR_PATTERN.findall(content):
            for name in IVAR_ITEM_PATTERN.findall(blk):
                if len(name) > 2:
                    ivars.add(name)

    return ScanResult(classes=classes, methods=methods, properties=properties, ivars=ivars)


def is_system_like(name: str) -> bool:
    prefixes = ("NS", "UI", "CA", "CF", "AV", "WK", "MTL", "OS", "GK", "SK")
    return name.startswith(prefixes)


def eligible(name: str, cfg: Config) -> bool:
    if name in cfg.blacklist:
        return False
    if cfg.whitelist and name not in cfg.whitelist:
        return False
    if is_system_like(name):
        return False
    if cfg.skip_risky and name in RISKY_SELECTORS:
        return False
    return True


def stable_name(name: str, seed: str) -> str:
    digest = hashlib.sha1(f"{seed}:{name}".encode("utf-8")).hexdigest()[:12]
    return f"{OBF_PREFIX}{digest}"


def variant_name(name: str, seed: str, rng: random.Random) -> str:
    alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    suffix = "".join(rng.choice(alphabet) for _ in range(10))
    digest = hashlib.md5(f"{seed}:{name}".encode("utf-8")).hexdigest()[:4]
    return f"{OBF_PREFIX}{digest}{suffix}"


def build_mapping(scan: ScanResult, cfg: Config) -> Dict[str, Dict[str, str]]:
    rng = random.Random(f"{cfg.seed}:{datetime.now(timezone.utc).isoformat()}")

    mapping: Dict[str, Dict[str, str]] = {
        "class": {},
        "method": {},
        "property": {},
        "ivar": {},
    }

    buckets = {
        "class": sorted(scan.classes),
        "method": sorted(scan.methods),
        "property": sorted(scan.properties),
        "ivar": sorted(scan.ivars),
    }

    used: Set[str] = set()
    for typ, names in buckets.items():
        for n in names:
            if not eligible(n, cfg):
                continue
            candidate = stable_name(n, cfg.seed) if cfg.mode == "stable" else variant_name(n, cfg.seed, rng)
            while candidate in used:
                candidate += "X"
            used.add(candidate)
            mapping[typ][n] = candidate

    return mapping


def compile_replace_patterns(mapping: Dict[str, Dict[str, str]]) -> List[Tuple[re.Pattern, str]]:
    flat = {}
    for mp in mapping.values():
        flat.update(mp)

    ordered = sorted(flat.items(), key=lambda kv: len(kv[0]), reverse=True)
    patterns: List[Tuple[re.Pattern, str]] = []
    for old, new in ordered:
        p = re.compile(rf"(?<![A-Za-z0-9_]){re.escape(old)}(?![A-Za-z0-9_])")
        patterns.append((p, new))
    return patterns


def rewrite_content(content: str, patterns: List[Tuple[re.Pattern, str]]) -> str:
    out = content
    for p, repl in patterns:
        out = p.sub(repl, out)
    return out


def ensure_backup(path: Path, cfg: Config) -> Path:
    rel = path.resolve().relative_to(cfg.project_root)
    bk = cfg.backup_dir / rel
    bk.parent.mkdir(parents=True, exist_ok=True)
    if not bk.exists():
        shutil.copy2(path, bk)
    return bk


def apply_mapping(files: List[Path], mapping: Dict[str, Dict[str, str]], cfg: Config) -> Tuple[int, int]:
    patterns = compile_replace_patterns(mapping)
    changed = 0
    scanned = 0
    for f in files:
        scanned += 1
        content = f.read_text(encoding="utf-8", errors="ignore")
        new_content = rewrite_content(content, patterns)
        if new_content == content:
            continue
        changed += 1
        if not cfg.dry_run:
            ensure_backup(f, cfg)
            f.write_text(new_content, encoding="utf-8")
    return scanned, changed


def rollback(mapping_path: Path) -> int:
    info = load_json(mapping_path)
    backup_dir = Path(info.get("backup_dir", ""))
    project_root = Path(info.get("project_root", ""))
    if not backup_dir.exists() or not project_root.exists():
        raise RuntimeError("mapping 中缺少有效 backup_dir 或 project_root，无法回滚")

    restored = 0
    for f in backup_dir.rglob("*"):
        if not f.is_file():
            continue
        rel = f.relative_to(backup_dir)
        dst = project_root / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(f, dst)
        restored += 1
    return restored


def write_mapping(mapping: Dict[str, Dict[str, str]], cfg: Config, files: List[Path], scanned: ScanResult, changed: int) -> None:
    data = {
        "version": 1,
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "project_root": str(cfg.project_root),
        "mode": cfg.mode,
        "seed": cfg.seed,
        "dry_run": cfg.dry_run,
        "skip_risky": cfg.skip_risky,
        "backup_dir": str(cfg.backup_dir),
        "statistics": {
            "files_total": len(files),
            "symbols_scanned": {
                "classes": len(scanned.classes),
                "methods": len(scanned.methods),
                "properties": len(scanned.properties),
                "ivars": len(scanned.ivars),
            },
            "symbols_mapped": {k: len(v) for k, v in mapping.items()},
            "files_changed": changed,
        },
        "mapping": mapping,
    }
    cfg.mapping_path.parent.mkdir(parents=True, exist_ok=True)
    cfg.mapping_path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Objective-C 混淆脚本（工程级）")
    parser.add_argument("--project-root", default=".", help="工程根目录")
    parser.add_argument("--config", help="JSON 配置文件")
    parser.add_argument("--mode", choices=["stable", "variant"], default="stable", help="映射模式")
    parser.add_argument("--seed", default="commercial-seed", help="混淆种子")
    parser.add_argument("--mapping", default="obfuscation/mapping.json", help="mapping 输出路径")
    parser.add_argument("--backup-dir", default="obfuscation/backup", help="回滚备份目录")
    parser.add_argument("--dry-run", action="store_true", help="只扫描不写入")
    parser.add_argument("--skip-risky", action="store_true", help="跳过高风险方法")
    parser.add_argument("--whitelist-file", help="白名单文件（每行一个标识符）")
    parser.add_argument("--blacklist-file", help="黑名单文件（每行一个标识符）")
    parser.add_argument("--disable-strings", action="store_true", help="禁用字符串文件替换")
    parser.add_argument("--rollback", action="store_true", help="按 mapping 执行回滚")
    args = parser.parse_args()

    if args.rollback:
        restored = rollback(Path(args.mapping).resolve())
        print(f"[rollback] restored files: {restored}")
        return 0

    cfg = build_config(args)
    files = list(iter_project_files(cfg))

    if not cfg.apply_strings:
        files = [f for f in files if f.suffix != ".strings"]

    scan = scan_symbols(files)
    mapping = build_mapping(scan, cfg)
    scanned, changed = apply_mapping(files, mapping, cfg)
    write_mapping(mapping, cfg, files, scan, changed)

    print("[summary]")
    print(f"  mode: {cfg.mode}")
    print(f"  dry_run: {cfg.dry_run}")
    print(f"  scanned_files: {scanned}")
    print(f"  changed_files: {changed}")
    print(f"  mapped_symbols: {sum(len(v) for v in mapping.values())}")
    print(f"  mapping: {cfg.mapping_path}")
    if not cfg.dry_run:
        print(f"  backup: {cfg.backup_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
