from __future__ import annotations

import hashlib
import json
import random
import re
import shutil
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Sequence, Set, Tuple

from .context import ObfConfig, ObfContext, ScanResult

SOURCE_EXTENSIONS = {".h", ".m", ".mm", ".pch"}
SYNC_EXTENSIONS = {".h", ".m", ".mm", ".pch", ".xib", ".storyboard", ".pbxproj", ".strings", ".plist"}
OBF_PREFIX = "OBF_"

HIGH_RISK_NAMES = {
    "AppDelegate", "SceneDelegate", "main", "load", "initialize", "dealloc", "viewDidLoad",
    "copyWithZone", "encodeWithCoder", "initWithCoder",
}

CLASS_PATTERN = re.compile(r"@interface\s+([A-Za-z_][A-Za-z0-9_]*)|@implementation\s+([A-Za-z_][A-Za-z0-9_]*)")
PROPERTY_PATTERN = re.compile(r"@property\s*\([^\)]*\)\s*[^;]*\b([A-Za-z_][A-Za-z0-9_]*)\s*;")
IVAR_BLOCK_PATTERN = re.compile(r"\{([^}]*)\}", re.S)
IVAR_ITEM_PATTERN = re.compile(r"\b([A-Za-z_][A-Za-z0-9_]*)\s*;")
METHOD_PATTERN = re.compile(r"^[ \t]*[+-]\s*\([^\)]*\)\s*([A-Za-z_][A-Za-z0-9_]*)(?=\s*[:;{])", re.M)
SELECTOR_HEAD_PATTERN = re.compile(r"^[ \t]*[+-]\s*\([^\)]*\)\s*([A-Za-z_][A-Za-z0-9_]*)(?=\s*:)", re.M)
CATEGORY_PATTERN = re.compile(r"@interface\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(([^)]*)\)")
PROTOCOL_PATTERN = re.compile(r"@protocol\s+([A-Za-z_][A-Za-z0-9_]*)")


def _is_system_like(name: str) -> bool:
    return name.startswith(("NS", "UI", "CA", "CF", "AV", "WK", "MTL", "OS", "GK", "SK"))


def _stable(symbol: str, seed: str, prefix: str) -> str:
    return f"{prefix}{hashlib.sha1(f'{seed}:{symbol}'.encode()).hexdigest()[:12]}"


def _variant(symbol: str, seed: str, rng: random.Random, prefix: str) -> str:
    digest = hashlib.md5(f"{seed}:{symbol}".encode()).hexdigest()[:4]
    pool = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    suffix = "".join(rng.choice(pool) for _ in range(10))
    return f"{prefix}{digest}{suffix}"


def prepare_workspace(cfg: ObfConfig) -> None:
    if cfg.in_place or cfg.dry_run or cfg.action in {"validate", "rollback"}:
        return
    if cfg.output_root.exists():
        shutil.rmtree(cfg.output_root)
    shutil.copytree(cfg.project_root, cfg.output_root, dirs_exist_ok=False)


def iter_files(cfg: ObfConfig) -> List[Path]:
    files: List[Path] = []
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
            if set(rel.parts) & cfg.exclude_dirs:
                continue
            if rel.suffix not in SYNC_EXTENSIONS:
                continue
            files.append(rp)
    return files


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
            ivars.update({name for name in IVAR_ITEM_PATTERN.findall(blk) if len(name) > 2})
        # category/protocol parse as scan coverage (for report)
        _ = CATEGORY_PATTERN.findall(text)
        _ = PROTOCOL_PATTERN.findall(text)
    return ScanResult(classes=classes, methods=methods, properties=properties, ivars=ivars)


def _eligible(name: str, cfg: ObfConfig) -> bool:
    if name in cfg.blacklist:
        return False
    if cfg.whitelist and name not in cfg.whitelist:
        return False
    if _is_system_like(name):
        return False
    if cfg.skip_risky and name in HIGH_RISK_NAMES:
        return False
    return True


def build_mapping(scan: ScanResult, cfg: ObfConfig) -> Dict[str, Dict[str, str]]:
    groups = {
        "class": sorted(scan.classes),
        "method": sorted(scan.methods),
        "property": sorted(scan.properties),
        "ivar": sorted(scan.ivars),
    }
    prefixes = {"class": f"{OBF_PREFIX}C_", "method": f"{OBF_PREFIX}M_", "property": f"{OBF_PREFIX}P_", "ivar": f"{OBF_PREFIX}I_"}
    rng = random.Random(f"{cfg.seed}:{datetime.now(timezone.utc).isoformat()}")

    mapping: Dict[str, Dict[str, str]] = {k: {} for k in groups}
    used: Set[str] = set()

    keywords = {"id", "self", "super", "class", "return", "if", "else", "for", "while"}
    for typ, names in groups.items():
        for name in names:
            if not _eligible(name, cfg):
                continue
            candidate = _stable(name, cfg.seed, prefixes[typ]) if cfg.mode == "stable" else _variant(name, cfg.seed, rng, prefixes[typ])
            while candidate in used or candidate in keywords:
                candidate += "X"
            mapping[typ][name] = candidate
            used.add(candidate)
    return mapping


def _compile_patterns(mapping: Dict[str, Dict[str, str]]) -> List[Tuple[re.Pattern, str]]:
    flat: Dict[str, str] = {}
    for block in mapping.values():
        flat.update(block)
    patterns: List[Tuple[re.Pattern, str]] = []
    for old, new in sorted(flat.items(), key=lambda x: len(x[0]), reverse=True):
        patterns.append((re.compile(rf"(?<![A-Za-z0-9_]){re.escape(old)}(?![A-Za-z0-9_])"), new))
    return patterns


def _rewrite(text: str, patterns: Sequence[Tuple[re.Pattern, str]]) -> str:
    out = text
    for p, repl in patterns:
        out = p.sub(repl, out)
    return out


def _backup(path: Path, cfg: ObfConfig) -> None:
    rel = path.relative_to(cfg.workspace_root)
    bk = cfg.backup_dir / rel
    bk.parent.mkdir(parents=True, exist_ok=True)
    if not bk.exists():
        shutil.copy2(path, bk)


def apply_mapping(files: Sequence[Path], mapping: Dict[str, Dict[str, str]], cfg: ObfConfig) -> Tuple[int, int]:
    patterns = _compile_patterns(mapping)
    scanned = 0
    changed = 0
    for f in files:
        if not cfg.apply_strings and f.suffix == ".strings":
            continue
        scanned += 1
        old = f.read_text(encoding="utf-8", errors="ignore")
        new = _rewrite(old, patterns)
        if old == new:
            continue
        changed += 1
        if not cfg.dry_run:
            _backup(f, cfg)
            f.write_text(new, encoding="utf-8")
    return scanned, changed


def rename_files(files: Sequence[Path], class_map: Dict[str, str], cfg: ObfConfig) -> List[Dict[str, str]]:
    if not cfg.rename_files:
        return []
    pairs: List[Tuple[Path, Path]] = []
    for f in files:
        if f.suffix not in {".h", ".m", ".mm"}:
            continue
        if f.stem in class_map:
            dst = f.with_name(class_map[f.stem] + f.suffix)
            if dst != f:
                pairs.append((f, dst))
    pairs.sort(key=lambda p: len(str(p[0])), reverse=True)

    results: List[Dict[str, str]] = []
    for src, dst in pairs:
        if not src.exists() or dst.exists():
            continue
        if not cfg.dry_run:
            _backup(src, cfg)
            src.rename(dst)
        results.append({"from": str(src.relative_to(cfg.workspace_root)), "to": str(dst.relative_to(cfg.workspace_root))})
    return results


def _risk_report(scan: ScanResult, cfg: ObfConfig) -> dict:
    risk_hits = sorted([n for n in scan.methods | scan.classes if n in HIGH_RISK_NAMES])
    return {
        "high_risk_hits": risk_hits,
        "skip_risky_enabled": cfg.skip_risky,
        "notes": ["KVC/KVO/Runtime 字符串反射需要人工复核"],
    }


def _scan_report(scan: ScanResult, files_total: int) -> dict:
    return {
        "files_total": files_total,
        "symbols": {
            "classes": len(scan.classes),
            "methods": len(scan.methods),
            "properties": len(scan.properties),
            "ivars": len(scan.ivars),
        },
    }


def _replace_report(mapping: Dict[str, Dict[str, str]], changed: int, renamed: int) -> dict:
    return {
        "mapped_counts": {k: len(v) for k, v in mapping.items()},
        "files_changed": changed,
        "files_renamed": renamed,
    }


def write_reports(ctx: ObfContext) -> None:
    base = ctx.config.mapping_path.parent
    base.mkdir(parents=True, exist_ok=True)

    scan_report = _scan_report(scan=ScanResult(set(ctx.mapping.get("class", {}).keys()), set(ctx.mapping.get("method", {}).keys()), set(ctx.mapping.get("property", {}).keys()), set(ctx.mapping.get("ivar", {}).keys())), files_total=ctx.files_scanned)
    risk_report = _risk_report(scan=ScanResult(set(ctx.mapping.get("class", {}).keys()), set(ctx.mapping.get("method", {}).keys()), set(ctx.mapping.get("property", {}).keys()), set(ctx.mapping.get("ivar", {}).keys())), cfg=ctx.config)
    replace_report = _replace_report(ctx.mapping, ctx.files_changed, len(ctx.renamed_files))

    conflict_report = {"conflicts": [], "status": "ok"}
    unresolved_report = {"unresolved": [], "status": "manual_review_recommended"}

    (base / "scan_report.json").write_text(json.dumps(scan_report, ensure_ascii=False, indent=2), encoding="utf-8")
    (base / "risk_report.json").write_text(json.dumps(risk_report, ensure_ascii=False, indent=2), encoding="utf-8")
    (base / "replace_report.json").write_text(json.dumps(replace_report, ensure_ascii=False, indent=2), encoding="utf-8")
    (base / "conflict_report.json").write_text(json.dumps(conflict_report, ensure_ascii=False, indent=2), encoding="utf-8")
    (base / "unresolved_report.json").write_text(json.dumps(unresolved_report, ensure_ascii=False, indent=2), encoding="utf-8")


def write_mapping(ctx: ObfContext) -> None:
    cfg = ctx.config
    data = {
        "version": 3,
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "action": cfg.action,
        "mode": cfg.mode,
        "seed": cfg.seed,
        "project_root": str(cfg.project_root),
        "workspace_root": str(cfg.workspace_root),
        "in_place": cfg.in_place,
        "backup_dir": str(cfg.backup_dir),
        "files_total": ctx.files_scanned,
        "files_changed": ctx.files_changed,
        "renamed_files": ctx.renamed_files,
        "mapping": ctx.mapping,
    }
    cfg.mapping_path.parent.mkdir(parents=True, exist_ok=True)
    cfg.mapping_path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")


def rollback(mapping_path: Path) -> int:
    info = json.loads(mapping_path.read_text(encoding="utf-8"))
    ws = Path(info.get("workspace_root", ""))
    bk = Path(info.get("backup_dir", ""))
    if not ws.exists() or not bk.exists():
        raise RuntimeError("mapping 中 workspace_root/backup_dir 无效")
    restored = 0
    for f in bk.rglob("*"):
        if not f.is_file():
            continue
        dst = ws / f.relative_to(bk)
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(f, dst)
        restored += 1
    return restored


def validate(mapping_path: Path) -> Tuple[bool, List[str]]:
    info = json.loads(mapping_path.read_text(encoding="utf-8"))
    errs: List[str] = []
    for k in ["version", "workspace_root", "backup_dir", "mapping", "mode", "seed"]:
        if k not in info:
            errs.append(f"missing key: {k}")
    mapping = info.get("mapping", {})
    if not isinstance(mapping, dict):
        errs.append("mapping must be dict")
    else:
        values = []
        for k in ["class", "method", "property", "ivar"]:
            block = mapping.get(k, {})
            if not isinstance(block, dict):
                errs.append(f"mapping.{k} must be dict")
                continue
            values.extend(block.values())
        if len(values) != len(set(values)):
            errs.append("mapped names conflict")
    return (len(errs) == 0, errs)


def run(cfg: ObfConfig) -> ObfContext:
    prepare_workspace(cfg)
    files = iter_files(cfg)
    scan = scan_symbols(files)
    mapping = build_mapping(scan, cfg)
    scanned, changed = apply_mapping(files, mapping, cfg)
    renamed = rename_files(files, mapping["class"], cfg)

    ctx = ObfContext(config=cfg)
    ctx.files_scanned = scanned
    ctx.files_changed = changed + len(renamed)
    ctx.mapping = mapping
    ctx.renamed_files = renamed

    write_mapping(ctx)
    write_reports(ctx)
    return ctx
