from __future__ import annotations

import dataclasses
from pathlib import Path
from typing import Dict, List, Set


@dataclasses.dataclass
class ObfConfig:
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


@dataclasses.dataclass
class ObfContext:
    config: ObfConfig
    files_scanned: int = 0
    files_changed: int = 0
    renamed_files: List[Dict[str, str]] = dataclasses.field(default_factory=list)
    mapping: Dict[str, Dict[str, str]] = dataclasses.field(default_factory=dict)
