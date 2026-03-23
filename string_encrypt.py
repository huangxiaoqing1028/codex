#!/usr/bin/env python3
"""批量将 Objective-C 字符串字面量替换成运行时解密表达式。"""

from __future__ import annotations

import argparse
import os
import random
import re
from pathlib import Path

OBJC_LITERAL_RE = re.compile(r'@"(?:\\.|[^"\\])*"')
IMPORT_RE = re.compile(r'^(#import\s+[^\n]+)$', re.MULTILINE)
DECRYPT_HEADER = '#import "decrypt.h"'
DECRYPT_MACRO = "DECRYPT_OBJC_STRING"
SUPPORTED_EXT = {".m", ".mm", ".c", ".cc", ".cpp"}
SKIP_DIRS = {".git", "build", "DerivedData", "Pods", "Carthage", "vendor"}


def objc_unescape(raw: str) -> str:
    raw = raw.replace(r"\'", "'")
    return bytes(raw, "utf-8").decode("unicode_escape")


def encrypt_literal(literal: str) -> str:
    inner = literal[2:-1]
    plain = objc_unescape(inner).encode("utf-8")
    if len(plain) == 0:
        return '@""'

    key = random.randint(1, 255)
    cipher = [(byte ^ key) for byte in plain]
    byte_list = ", ".join(f"0x{b:02X}" for b in cipher)
    return f"DECRYPT_OBJC_STRING((const unsigned char[]){{{byte_list}}}, {len(cipher)}, 0x{key:02X})"


def ensure_import(content: str) -> str:
    if DECRYPT_HEADER in content:
        return content

    match = IMPORT_RE.search(content)
    if match:
        idx = match.end()
        return content[:idx] + "\n" + DECRYPT_HEADER + content[idx:]

    return DECRYPT_HEADER + "\n" + content


def process_file(path: Path) -> bool:
    source = path.read_text(encoding="utf-8")
    if DECRYPT_MACRO in source and DECRYPT_HEADER in source:
        return False

    changed = False

    def replacer(match: re.Match[str]) -> str:
        nonlocal changed
        changed = True
        return encrypt_literal(match.group(0))

    updated = OBJC_LITERAL_RE.sub(replacer, source)
    if not changed:
        return False

    updated = ensure_import(updated)
    path.write_text(updated, encoding="utf-8")
    return True


def collect_files(root: Path):
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for name in filenames:
            path = Path(dirpath) / name
            if path.suffix in SUPPORTED_EXT:
                yield path


def main() -> int:
    parser = argparse.ArgumentParser(description="iOS Objective-C 字符串加密器")
    parser.add_argument("project_root", type=Path, help="项目根目录")
    parser.add_argument("--seed", type=int, default=None, help="随机种子（可选）")
    args = parser.parse_args()

    if args.seed is not None:
        random.seed(args.seed)

    root = args.project_root.resolve()
    if not root.exists():
        raise SystemExit(f"项目目录不存在: {root}")

    touched = []
    for file_path in collect_files(root):
        if process_file(file_path):
            touched.append(file_path)

    print(f"[string_encrypt] 已处理文件: {len(touched)}")
    for path in touched:
        print(f"  - {path.relative_to(root)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
