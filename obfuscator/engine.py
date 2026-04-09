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
SYNC_EXTENSIONS = {".h", ".m", ".mm", ".pch", ".xib", ".storyboard", ".pbxproj", ".strings", ".plist", ".xcscheme", ".swift"}
OBF_PREFIX = "OBF_"

HIGH_RISK_NAMES = {
    "AppDelegate", "SceneDelegate", "main", "load", "initialize", "dealloc", "viewDidLoad",
    "copyWithZone", "encodeWithCoder", "initWithCoder",
}
SYSTEM_OVERRIDE_HINTS = {"viewDidLoad", "viewWillAppear", "viewDidAppear", "layoutSubviews", "prepareForSegue"}

CLASS_PATTERN = re.compile(r"@interface\s+([A-Za-z_][A-Za-z0-9_]*)|@implementation\s+([A-Za-z_][A-Za-z0-9_]*)")
PROPERTY_PATTERN = re.compile(r"@property\s*\([^\)]*\)\s*[^;]*\b([A-Za-z_][A-Za-z0-9_]*)\s*;")
IVAR_BLOCK_PATTERN = re.compile(r"\{([^}]*)\}", re.S)
IVAR_ITEM_PATTERN = re.compile(r"\b([A-Za-z_][A-Za-z0-9_]*)\s*;")
METHOD_PATTERN = re.compile(r"^[ \t]*[+-]\s*\([^\)]*\)\s*([A-Za-z_][A-Za-z0-9_]*)(?=\s*[:;{])", re.M)
SELECTOR_HEAD_PATTERN = re.compile(r"^[ \t]*[+-]\s*\([^\)]*\)\s*([A-Za-z_][A-Za-z0-9_]*)(?=\s*:)", re.M)
CATEGORY_PATTERN = re.compile(r"@interface\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(([^)]*)\)")
PROTOCOL_PATTERN = re.compile(r"@protocol\s+([A-Za-z_][A-Za-z0-9_]*)")

RISK_PATTERNS = {
    "kvc": [r"setValue:\s*forKey:", r"valueForKey:", r"valueForKeyPath:"],
    "kvo": [r"addObserver:\s*forKeyPath:", r"observeValueForKeyPath:"],
    "nscoding": [r"encodeWithCoder", r"initWithCoder", r"NSCoding", r"NSSecureCoding"],
    "runtime_reflection": [r"objc_msgSend", r"NSClassFromString", r"NSSelectorFromString", r"performSelector:"],
    "selector_string": [r"@selector\(", r"NSStringFromSelector", r"NSSelectorFromString"],
    "router_path_mapping": [r"router", r"route", r"URLPattern", r"openURL"],
    "model_json_mapping": [r"mj_", r"yy_model", r"JSONModel", r"modelCustomPropertyMapper"],
    "db_field_mapping": [r"sqlite", r"FMDB", r"db_", r"column"],
    "coredata_property": [r"NSManagedObject", r"@dynamic", r"CoreData"],
    "third_party_callback": [r"AFNetworking", r"MASConstraint", r"SDWebImage", r"completion:\s*\^"],
}


def _is_system_like(name: str) -> bool:
    return name.startswith(("NS", "UI", "CA", "CF", "AV", "WK", "MTL", "OS", "GK", "SK"))


def _stable(symbol: str, seed: str, prefix: str) -> str:
    return f"{prefix}{hashlib.sha1(f'{seed}:{symbol}'.encode()).hexdigest()[:12]}"


def _variant(symbol: str, seed: str, rng: random.Random, prefix: str) -> str:
    digest = hashlib.md5(f"{seed}:{symbol}".encode()).hexdigest()[:4]
    pool = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    suffix = "".join(rng.choice(pool) for _ in range(10))
    return f"{prefix}{digest}{suffix}"


def _camel(seed: str, symbol: str, prefix: str) -> str:
    digest = hashlib.sha1(f"{seed}:{symbol}".encode()).hexdigest()
    chunks = [digest[i : i + 3] for i in range(0, 12, 3)]
    return prefix + "".join(c.capitalize() for c in chunks)


def _load_mapping_cache(cfg: ObfConfig) -> Dict[str, Dict[str, str]]:
    if not getattr(cfg, "reuse_mapping", False):
        return {}
    if not cfg.mapping_path.exists():
        return {}
    data = json.loads(cfg.mapping_path.read_text(encoding="utf-8"))
    mapping = data.get("mapping", {})
    return mapping if isinstance(mapping, dict) else {}


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
            if rel.suffix not in SYNC_EXTENSIONS and rel.name != "project.pbxproj" and rel.name != "Podfile":
                continue
            files.append(rp)
    return files


def scan_symbols(files: Sequence[Path], cfg: ObfConfig) -> Tuple[ScanResult, dict]:
    classes: Set[str] = set()
    methods: Set[str] = set()
    properties: Set[str] = set()
    ivars: Set[str] = set()
    category_methods: Set[str] = set()
    protocols: Set[str] = set()

    risk_hits: Dict[str, Set[str]] = {k: set() for k in RISK_PATTERNS}
    override_hits: Set[str] = set()

    for f in files:
        text = f.read_text(encoding="utf-8", errors="ignore")
        for typ, patterns in RISK_PATTERNS.items():
            for pat in patterns:
                if re.search(pat, text):
                    risk_hits[typ].add(str(f.relative_to(cfg.workspace_root)))

        if f.suffix not in SOURCE_EXTENSIONS:
            continue

        for a, b in CLASS_PATTERN.findall(text):
            classes.add(a or b)
        properties.update(PROPERTY_PATTERN.findall(text))
        m = set(METHOD_PATTERN.findall(text)) | set(SELECTOR_HEAD_PATTERN.findall(text))
        methods.update(m)
        override_hits.update({name for name in m if name in SYSTEM_OVERRIDE_HINTS})

        for blk in IVAR_BLOCK_PATTERN.findall(text):
            ivars.update({name for name in IVAR_ITEM_PATTERN.findall(blk) if len(name) > 2})

        if CATEGORY_PATTERN.search(text):
            category_methods.update(m)
        protocols.update(PROTOCOL_PATTERN.findall(text))

    meta = {
        "category_methods": sorted(category_methods),
        "protocols": sorted(protocols),
        "risk_hits": {k: sorted(v) for k, v in risk_hits.items()},
        "system_override_methods": sorted(override_hits),
    }
    return ScanResult(classes=classes, methods=methods, properties=properties, ivars=ivars), meta


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


def _pick_name(symbol: str, cfg: ObfConfig, rng: random.Random, prefix: str) -> str:
    style = getattr(cfg, "name_style", "hex")
    if cfg.mode == "stable":
        if style == "camel":
            return _camel(cfg.seed, symbol, prefix)
        return _stable(symbol, cfg.seed, prefix)
    if style == "camel":
        return _camel(cfg.seed + "_v", symbol + str(rng.randint(1, 99999)), prefix)
    return _variant(symbol, cfg.seed, rng, prefix)


def build_mapping(scan: ScanResult, meta: dict, cfg: ObfConfig) -> Dict[str, Dict[str, str]]:
    groups = {
        "class": sorted(scan.classes),
        "method": sorted(scan.methods),
        "property": sorted(scan.properties),
        "ivar": sorted(scan.ivars),
        "protocol": sorted(meta.get("protocols", [])) if getattr(cfg, "obfuscate_protocol", False) else [],
    }

    # category 方法：可选白名单策略
    category_allow = set(getattr(cfg, "category_method_whitelist", []))
    if category_allow:
        groups["method"] = sorted(set(groups["method"]) & category_allow | (set(groups["method"]) - set(meta.get("category_methods", []))))

    prefixes = {
        "class": f"{OBF_PREFIX}C_",
        "method": f"{OBF_PREFIX}M_",
        "property": f"{OBF_PREFIX}P_",
        "ivar": f"{OBF_PREFIX}I_",
        "protocol": f"{OBF_PREFIX}R_",
    }

    rng = random.Random(cfg.seed)
    keywords = {"id", "self", "super", "class", "return", "if", "else", "for", "while"}

    mapping: Dict[str, Dict[str, str]] = {k: {} for k in groups}
    used: Set[str] = set()

    cache = _load_mapping_cache(cfg)

    for typ, names in groups.items():
        cached_block = cache.get(typ, {}) if isinstance(cache.get(typ, {}), dict) else {}
        for name in names:
            if not _eligible(name, cfg):
                continue
            if name in cached_block:
                candidate = cached_block[name]
            else:
                candidate = _pick_name(name, cfg, rng, prefixes[typ])
            while candidate in used or candidate in keywords:
                candidate += "X"
            mapping[typ][name] = candidate
            used.add(candidate)

    return mapping


def _compile_patterns(mapping: Dict[str, Dict[str, str]]) -> List[Tuple[re.Pattern, str]]:
    flat: Dict[str, str] = {}
    for block in mapping.values():
        if isinstance(block, dict):
            flat.update(block)
    return [
        (re.compile(rf"(?<![A-Za-z0-9_]){re.escape(old)}(?![A-Za-z0-9_])"), new)
        for old, new in sorted(flat.items(), key=lambda x: len(x[0]), reverse=True)
    ]


def _rewrite(text: str, patterns: Sequence[Tuple[re.Pattern, str]]) -> str:
    out = text
    for p, repl in patterns:
        out = p.sub(repl, out)
    return out


def _replace_word_boundary(text: str, old: str, new: str) -> str:
    if not old:
        return text
    return re.sub(rf"(?<![A-Za-z0-9_]){re.escape(old)}(?![A-Za-z0-9_])", new, text)


def _replace_pbxproj_structured(text: str, cfg: ObfConfig) -> str:
    """
    对 project.pbxproj 做结构化的安全替换，避免全局盲替换：
    1) 仅替换带边界的标识符
    2) 仅替换常见 name/path/productName/PRODUCT_NAME/value 语义位
    """
    out = text
    rename_pairs = [
        (getattr(cfg, "source_target", ""), getattr(cfg, "rename_target", None)),
        (getattr(cfg, "source_project", ""), getattr(cfg, "rename_project", None)),
        (getattr(cfg, "source_scheme", ""), getattr(cfg, "rename_scheme", None)),
    ]

    for old, new in rename_pairs:
        if not old or not new:
            continue
        # 1) 通用边界替换（控制误伤）
        out = _replace_word_boundary(out, old, new)
        # 2) 结构化字段替换
        out = re.sub(rf"(name\s*=\s*){re.escape(old)}(\s*;)", rf"\1{new}\2", out)
        out = re.sub(rf"(path\s*=\s*){re.escape(old)}(\s*;)", rf"\1{new}\2", out)
        out = re.sub(rf"(productName\s*=\s*){re.escape(old)}(\s*;)", rf"\1{new}\2", out)
        out = re.sub(rf"(PRODUCT_NAME\s*=\s*){re.escape(old)}(\s*;)", rf"\1{new}\2", out)
        out = re.sub(rf"(\"?){re.escape(old)}(\\.xcodeproj\"?)", rf"\1{new}\2", out)
        out = re.sub(rf"(\"?){re.escape(old)}(\\.xcworkspace\"?)", rf"\1{new}\2", out)
        out = re.sub(rf"(\"?){re.escape(old)}(\\.xcscheme\"?)", rf"\1{new}\2", out)
        out = re.sub(rf"(\"?){re.escape(old)}(\\.app\"?)", rf"\1{new}\2", out)
        out = re.sub(rf"(INFOPLIST_FILE\\s*=\\s*[^;]*?){re.escape(old)}([^;]*;)", rf"\1{new}\2", out)
    return out


def _replace_podfile_structured(text: str, cfg: ObfConfig) -> str:
    """
    对 Podfile 做语义化替换：
    - target 'X'
    - project 'X'
    - workspace 'X'
    - scheme => 'X' / :scheme => 'X'
    """
    out = text
    if getattr(cfg, "source_target", "") and getattr(cfg, "rename_target", None):
        src = re.escape(cfg.source_target)
        dst = cfg.rename_target
        out = re.sub(rf"(target\s+['\"])({src})(['\"])", rf"\1{dst}\3", out)

    if getattr(cfg, "source_project", "") and getattr(cfg, "rename_project", None):
        src = re.escape(cfg.source_project)
        dst = cfg.rename_project
        out = re.sub(rf"(project\s+['\"])([^'\"]*?){src}([^'\"]*?['\"])", rf"\1\2{dst}\3", out)
        out = re.sub(rf"(workspace\s+['\"])([^'\"]*?){src}([^'\"]*?['\"])", rf"\1\2{dst}\3", out)

    if getattr(cfg, "source_scheme", "") and getattr(cfg, "rename_scheme", None):
        src = re.escape(cfg.source_scheme)
        dst = cfg.rename_scheme
        out = re.sub(rf"(scheme\s*=>\s*['\"])({src})(['\"])", rf"\1{dst}\3", out)
        out = re.sub(rf"(:scheme\s*=>\s*['\"])({src})(['\"])", rf"\1{dst}\3", out)
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

    resource_whitelist = set(getattr(cfg, "resource_whitelist", []))

    for f in files:
        if not cfg.apply_strings and f.suffix == ".strings":
            continue
        if resource_whitelist and f.suffix in {".xib", ".storyboard"} and f.stem not in resource_whitelist:
            continue

        scanned += 1
        old = f.read_text(encoding="utf-8", errors="ignore")
        new = _rewrite(old, patterns)

        # 对 pbxproj / Podfile 使用结构化替换，避免误伤
        if f.name == "project.pbxproj":
            new = _replace_pbxproj_structured(new, cfg)
        elif f.name == "Podfile":
            new = _replace_podfile_structured(new, cfg)
        else:
            if getattr(cfg, "rename_target", None) and getattr(cfg, "source_target", ""):
                new = _replace_word_boundary(new, cfg.source_target, cfg.rename_target)
            if getattr(cfg, "rename_project", None) and getattr(cfg, "source_project", ""):
                new = _replace_word_boundary(new, cfg.source_project, cfg.rename_project)
            if getattr(cfg, "rename_scheme", None) and getattr(cfg, "source_scheme", ""):
                new = _replace_word_boundary(new, cfg.source_scheme, cfg.rename_scheme)

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

    system_storyboards = set(getattr(cfg, "system_storyboards", ["Main", "LaunchScreen"]))
    pairs: List[Tuple[Path, Path]] = []
    for f in files:
        if f.suffix not in {".h", ".m", ".mm", ".xib", ".storyboard"}:
            continue
        if f.suffix == ".storyboard" and f.stem in system_storyboards:
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


def sync_renamed_references(files: Sequence[Path], renamed_files: List[Dict[str, str]], cfg: ObfConfig) -> int:
    """
    文件名重命名后，二次同步引用（尤其是 project.pbxproj / Podfile / storyboard）。
    """
    if not renamed_files:
        return 0
    changed = 0
    replace_pairs: List[Tuple[str, str]] = []
    for item in renamed_files:
        old_rel = item["from"]
        new_rel = item["to"]
        replace_pairs.append((old_rel, new_rel))
        replace_pairs.append((Path(old_rel).name, Path(new_rel).name))
        replace_pairs.append((Path(old_rel).stem, Path(new_rel).stem))

    # 长串优先替换
    replace_pairs = sorted(set(replace_pairs), key=lambda x: len(x[0]), reverse=True)

    for f in files:
        if not f.exists() or f.suffix not in SYNC_EXTENSIONS and f.name not in {"project.pbxproj", "Podfile"}:
            continue
        old = f.read_text(encoding="utf-8", errors="ignore")
        new = old
        for old_s, new_s in replace_pairs:
            if old_s:
                new = _replace_word_boundary(new, old_s, new_s)
                new = new.replace(old_s, new_s)
        if new != old:
            changed += 1
            if not cfg.dry_run:
                _backup(f, cfg)
                f.write_text(new, encoding="utf-8")
    return changed


def _risk_report(meta: dict, cfg: ObfConfig) -> dict:
    risk_hits = meta.get("risk_hits", {})
    unresolved = []
    for typ, files in risk_hits.items():
        if files:
            unresolved.append({"type": typ, "count": len(files), "files": files})

    return {
        "high_risk_hits": sorted([n for n in meta.get("system_override_methods", []) if n in HIGH_RISK_NAMES]),
        "system_override_methods": meta.get("system_override_methods", []),
        "risk_hits": risk_hits,
        "skip_risky_enabled": cfg.skip_risky,
        "notes": ["KVC/KVO/Runtime 仅做静态命中，需人工复核"],
        "unresolved": unresolved,
    }


def _scan_report(scan: ScanResult, meta: dict, files_total: int) -> dict:
    return {
        "files_total": files_total,
        "symbols": {
            "classes": len(scan.classes),
            "methods": len(scan.methods),
            "properties": len(scan.properties),
            "ivars": len(scan.ivars),
            "protocols": len(meta.get("protocols", [])),
            "category_methods": len(meta.get("category_methods", [])),
        },
    }


def _replace_report(mapping: Dict[str, Dict[str, str]], changed: int, renamed: int) -> dict:
    return {
        "mapped_counts": {k: len(v) for k, v in mapping.items() if isinstance(v, dict)},
        "files_changed": changed,
        "files_renamed": renamed,
    }


def write_reports(ctx: ObfContext, scan: ScanResult, meta: dict) -> None:
    base = (getattr(ctx.config, "artifacts_dir", ctx.config.mapping_path.parent) / "reports").resolve()
    base.mkdir(parents=True, exist_ok=True)

    scan_report = _scan_report(scan, meta, ctx.files_scanned)
    risk_report = _risk_report(meta, ctx.config)
    replace_report = _replace_report(ctx.mapping, ctx.files_changed, len(ctx.renamed_files))

    # 目前冲突由命名阶段解决，保留结构化输出
    conflict_report = {"conflicts": [], "status": "ok"}

    unresolved_items = risk_report.get("unresolved", [])
    unresolved_report = {
        "unresolved": unresolved_items,
        "by_type": {item["type"]: item["count"] for item in unresolved_items},
        "status": "manual_review_required" if unresolved_items else "ok",
    }

    (base / "scan_report.json").write_text(json.dumps(scan_report, ensure_ascii=False, indent=2), encoding="utf-8")
    (base / "risk_report.json").write_text(json.dumps(risk_report, ensure_ascii=False, indent=2), encoding="utf-8")
    (base / "replace_report.json").write_text(json.dumps(replace_report, ensure_ascii=False, indent=2), encoding="utf-8")
    (base / "conflict_report.json").write_text(json.dumps(conflict_report, ensure_ascii=False, indent=2), encoding="utf-8")
    (base / "unresolved_report.json").write_text(json.dumps(unresolved_report, ensure_ascii=False, indent=2), encoding="utf-8")


def write_mapping(ctx: ObfContext, meta: dict) -> None:
    cfg = ctx.config
    data = {
        "version": 4,
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "action": cfg.action,
        "mode": cfg.mode,
        "seed": cfg.seed,
        "name_style": getattr(cfg, "name_style", "hex"),
        "project_root": str(cfg.project_root),
        "workspace_root": str(cfg.workspace_root),
        "in_place": cfg.in_place,
        "backup_dir": str(cfg.backup_dir),
        "files_total": ctx.files_scanned,
        "files_changed": ctx.files_changed,
        "renamed_files": ctx.renamed_files,
        "meta": meta,
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
    for k in ["version", "workspace_root", "backup_dir", "mapping", "mode", "seed", "meta"]:
        if k not in info:
            errs.append(f"missing key: {k}")

    if info.get("mode") not in {"stable", "variant"}:
        errs.append("mode must be stable|variant")

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
    scan, meta = scan_symbols(files, cfg)
    mapping = build_mapping(scan, meta, cfg)
    scanned, changed = apply_mapping(files, mapping, cfg)
    renamed = rename_files(files, mapping.get("class", {}), cfg)
    ref_sync_changed = sync_renamed_references(files, renamed, cfg)

    ctx = ObfContext(config=cfg)
    ctx.files_scanned = scanned
    ctx.files_changed = changed + len(renamed) + ref_sync_changed
    ctx.mapping = mapping
    ctx.renamed_files = renamed

    write_mapping(ctx, meta)
    write_reports(ctx, scan, meta)
    return ctx
