#!/usr/bin/env python3
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from obfuscator.config_loader import build_config
from obfuscator.engine import rollback, run, validate
from obfuscator.logging_utils import setup_logger


def normalize_argv(argv: list[str]) -> list[str]:
    """
    容错处理：
    用户常把 `--mapping/xxx` 写成连在一起的形式，这里自动拆分成
    `--mapping /xxx`，避免 argparse 直接报错。
    """
    normalized: list[str] = []
    split_flags = ("--mapping", "--backup-dir", "--project-root", "--output-root", "--config")
    for token in argv:
        # 过滤复制命令时混入的空白参数（含全角/不可见空格）
        if not token or not token.strip():
            continue
        matched = False
        for flag in split_flags:
            prefix = f"{flag}/"
            if token.startswith(prefix):
                normalized.append(flag)
                normalized.append("/" + token[len(prefix) :])
                matched = True
                break
        if not matched:
            normalized.append(token)
    return normalized


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Objective-C 主工程可控混淆工具")
    p.add_argument("--project-root", default=".", help="原工程根目录")
    p.add_argument("--config", help="JSON 配置文件")
    p.add_argument("--action", choices=["dry-run", "obfuscate", "validate", "rollback"], default="dry-run")
    p.add_argument("--mode", choices=["stable", "variant"], default="stable")
    p.add_argument("--seed", default="release-seed")
    p.add_argument("--name-style", choices=["hex", "camel"], default="hex")
    p.add_argument("--in-place", action="store_true", help="直接修改 project-root（默认否）")
    p.add_argument("--output-root", help="非 in-place 模式下输出目录")
    p.add_argument("--mapping", default="obfuscation/mapping.json")
    p.add_argument("--backup-dir", default="obfuscation/backup")
    p.add_argument("--disable-risky-skip", action="store_true")
    p.add_argument("--disable-file-rename", action="store_true")
    p.add_argument("--disable-strings", action="store_true")
    p.add_argument("--whitelist-file")
    p.add_argument("--blacklist-file")
    p.add_argument("--reuse-mapping", action="store_true", help="复用已有 mapping 作为 cache")
    p.add_argument("--obfuscate-protocol", action="store_true", help="是否混淆 protocol 名")

    # 高级联动改名
    p.add_argument("--source-target")
    p.add_argument("--rename-target")
    p.add_argument("--source-project")
    p.add_argument("--rename-project")
    p.add_argument("--source-scheme")
    p.add_argument("--rename-scheme")

    p.add_argument("--verbose", action="store_true")
    return p


def preflight_check(cfg) -> None:
    if not cfg.project_root.exists():
        raise FileNotFoundError(
            f"project-root 不存在: {cfg.project_root}。请确认路径是否正确，且包含目标 iOS 工程源码目录。"
        )
    if not cfg.project_root.is_dir():
        raise NotADirectoryError(f"project-root 不是目录: {cfg.project_root}")
    if cfg.output_root == cfg.project_root and not cfg.in_place:
        raise ValueError("output-root 与 project-root 相同会覆盖原工程。请改用 --in-place 或指定其它输出目录。")


def main() -> int:
    args = build_parser().parse_args(normalize_argv(sys.argv[1:]))
    logger = setup_logger(args.verbose)
    try:
        cfg = build_config(args)
        if cfg.action in {"dry-run", "obfuscate"}:
            preflight_check(cfg)

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
        reports_dir = (getattr(cfg, "artifacts_dir", cfg.mapping_path.parent) / "reports").resolve()
        logger.info("  reports: %s", reports_dir)
        return 0
    except Exception as e:
        logger.error("[error] %s", e)
        return 2


if __name__ == "__main__":
    sys.exit(main())
