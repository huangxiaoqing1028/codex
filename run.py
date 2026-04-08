#!/usr/bin/env python3
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from obfuscator.config_loader import build_config
from obfuscator.engine import rollback, run, validate
from obfuscator.logging_utils import setup_logger


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Objective-C 主工程可控混淆工具")
    p.add_argument("--project-root", default=".", help="原工程根目录")
    p.add_argument("--config", help="JSON 配置文件")
    p.add_argument("--action", choices=["dry-run", "obfuscate", "validate", "rollback"], default="dry-run")
    p.add_argument("--mode", choices=["stable", "variant"], default="stable")
    p.add_argument("--seed", default="release-seed")
    p.add_argument("--in-place", action="store_true", help="直接修改 project-root（默认否）")
    p.add_argument("--output-root", help="非 in-place 模式下输出目录")
    p.add_argument("--mapping", default="obfuscation/mapping.json")
    p.add_argument("--backup-dir", default="obfuscation/backup")
    p.add_argument("--disable-risky-skip", action="store_true")
    p.add_argument("--disable-file-rename", action="store_true")
    p.add_argument("--disable-strings", action="store_true")
    p.add_argument("--whitelist-file")
    p.add_argument("--blacklist-file")
    p.add_argument("--verbose", action="store_true")
    return p


def main() -> int:
    args = build_parser().parse_args()
    logger = setup_logger(args.verbose)
    cfg = build_config(args)

    if cfg.action == "validate":
        ok, errs = validate(Path(cfg.mapping_path))
        if ok:
            logger.info("[validate] mapping is valid")
            return 0
        logger.error("[validate] mapping is invalid")
        for err in errs:
            logger.error("  - %s", err)
        return 2

    if cfg.action == "rollback":
        restored = rollback(Path(cfg.mapping_path))
        logger.info("[rollback] restored files: %s", restored)
        return 0

    ctx = run(cfg)
    logger.info("[summary]")
    logger.info("  action: %s", cfg.action)
    logger.info("  mode: %s", cfg.mode)
    logger.info("  workspace: %s", cfg.workspace_root)
    logger.info("  dry_run: %s", cfg.dry_run)
    logger.info("  scanned_files: %s", ctx.files_scanned)
    logger.info("  changed_files: %s", ctx.files_changed)
    logger.info("  renamed_files: %s", len(ctx.renamed_files))
    logger.info("  mapping: %s", cfg.mapping_path)
    logger.info("  reports: %s", cfg.mapping_path.parent)
    return 0


if __name__ == "__main__":
    sys.exit(main())
