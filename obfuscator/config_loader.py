from __future__ import annotations

import json
from pathlib import Path
from typing import Iterable, Set

from .context import ObfConfig

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


def normalize_names(items: Iterable[str]) -> Set[str]:
    return {x.strip() for x in items if isinstance(x, str) and x.strip()}


def load_json(path: Path) -> dict:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def build_config(args) -> ObfConfig:
    cfg_file = load_json(Path(args.config).resolve()) if args.config else {}
    project_root = Path(args.project_root).resolve()

    in_place = args.in_place
    output_root = Path(args.output_root).resolve() if args.output_root else project_root.parent / f"{project_root.name}_obfuscated"
    workspace_root = project_root if in_place else output_root

    include_dirs = [workspace_root]
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

    return ObfConfig(
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
        dry_run=action == "dry-run",
        in_place=in_place,
        output_root=output_root,
        mapping_path=Path(args.mapping).resolve(),
        backup_dir=Path(args.backup_dir).resolve(),
    )
