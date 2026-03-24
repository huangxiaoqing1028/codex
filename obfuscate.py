#!/usr/bin/env python3
"""LLVM obfuscation automation script.

Capabilities
- String literal obfuscation (XOR runtime decode)
- Randomized LLVM `opt` pass pipeline for single-file builds
- Optional LLVM obfuscation flags (flatten / bogus control flow)
- iOS mode: single-file compile or whole-project obfuscate + auto build APP/IPA
"""

from __future__ import annotations

import argparse
import hashlib
import json
import random
import re
import shutil
import subprocess
import sys
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import List, Sequence

STRING_RE = re.compile(r'"(?:\\.|[^"\\])*"')
IOS_SOURCE_EXTS = {".m", ".mm", ".c", ".cc", ".cpp", ".cxx", ".swift"}
THIRD_PARTY_DIRS = {"Pods", "Carthage"}
MAX_PLUGIN_PASSES = [
    "obf-flatten",
    "obf-bogus",
    "obf-split-merge",
    "obf-arith-sub",
    "obf-indirect-dispatch",
    "obf-call-indirect",
]


@dataclass
class BuildPaths:
    workdir: Path
    transformed_src: Path
    ir_path: Path
    transformed_ir_path: Path
    output: Path
    manifest: Path


@dataclass
class Strategy:
    seed: int
    flatten: bool
    bogus: bool
    llvm_auto: bool
    aggressive: bool
    platform: str
    target: str | None
    passes: List[str]
    pipeline_id: str
    backend: str
    custom_opt_passes: List[str]
    split_count: int
    dispatcher_mode: bool
    state_perturb: bool
    indirect_dispatch: bool
    pass_plugin: str | None
    plugin_passes: List[str]


def run(cmd: Sequence[str]) -> None:
    print("[+]", " ".join(cmd))
    subprocess.run(cmd, check=True)


def run_probe(cmd: Sequence[str], stdin_data: str = "") -> bool:
    try:
        subprocess.run(
            cmd,
            check=True,
            input=stdin_data,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        return True
    except subprocess.CalledProcessError:
        return False


def find_tool(name: str) -> str:
    path = shutil.which(name)
    if not path:
        raise RuntimeError(f"Required tool not found: {name}")
    return path


def decode_escaped(payload: str) -> bytes:
    """Decode common C-style escapes, while safely preserving invalid escapes."""

    out = bytearray()
    i = 0
    n = len(payload)

    simple = {
        "n": "\n",
        "r": "\r",
        "t": "\t",
        "\\": "\\",
        "'": "'",
        '"': '"',
        "0": "\x00",
        "a": "\a",
        "b": "\b",
        "f": "\f",
        "v": "\v",
    }

    while i < n:
        ch = payload[i]
        if ch != "\\":
            out.extend(ch.encode("utf-8"))
            i += 1
            continue

        if i + 1 >= n:
            out.extend(b"\\")
            break

        esc = payload[i + 1]
        if esc in simple:
            out.extend(simple[esc].encode("utf-8"))
            i += 2
            continue

        # Hex escape: \xNN (1-2 hex chars supported here)
        if esc == "x":
            j = i + 2
            hex_digits = []
            while j < n and len(hex_digits) < 2 and payload[j] in "0123456789abcdefABCDEF":
                hex_digits.append(payload[j])
                j += 1
            if hex_digits:
                out.append(int("".join(hex_digits), 16))
                i = j
                continue
            out.extend(b"\\x")
            i += 2
            continue

        # Unicode escapes: \uXXXX / \UXXXXXXXX (invalid forms are preserved)
        if esc in {"u", "U"}:
            need = 4 if esc == "u" else 8
            seq = payload[i + 2 : i + 2 + need]
            if len(seq) == need and all(c in "0123456789abcdefABCDEF" for c in seq):
                out.extend(chr(int(seq, 16)).encode("utf-8"))
                i += 2 + need
                continue
            out.extend(("\\" + esc).encode("utf-8"))
            i += 2
            continue

        # Octal escape: \123 (up to 3 octal digits)
        if esc in "01234567":
            j = i + 1
            oct_digits = []
            while j < n and len(oct_digits) < 3 and payload[j] in "01234567":
                oct_digits.append(payload[j])
                j += 1
            out.append(int("".join(oct_digits), 8) & 0xFF)
            i = j
            continue

        # Unknown escape, keep as-is to avoid decode crashes.
        out.extend(("\\" + esc).encode("utf-8"))
        i += 2

    return bytes(out)


def obfuscate_strings(source: str, seed: int) -> str:
    rng = random.Random(seed)
    counter = 0

    def repl(match: re.Match[str]) -> str:
        nonlocal counter
        literal = match.group(0)
        raw = decode_escaped(literal[1:-1])
        if not raw:
            return literal

        key = rng.randint(1, 255)
        data = [b ^ key for b in raw + b"\x00"]
        token = f"__obf_{counter}"
        counter += 1

        arr = ",".join(str(x) for x in data)
        return (
            "({"
            f"unsigned char {token}[]={{ {arr} }};"
            f"for(size_t i=0;i<sizeof({token})-1;++i){token}[i]^={key};"
            f"(char*){token};"
            "})"
        )

    return STRING_RE.sub(repl, source)


def choose_pipeline(rng: random.Random, aggressive: bool) -> List[str]:
    base = ["-mem2reg", "-instcombine", "-reassociate"]
    pool = [
        "-gvn",
        "-sroa",
        "-adce",
        "-simplifycfg",
        "-loop-rotate",
        "-loop-unroll",
        "-jump-threading",
        "-tailcallelim",
        "-dse",
    ]
    pick = 6 if aggressive else 4
    chosen = rng.sample(pool, k=pick)
    if aggressive:
        chosen.extend(["-inline", "-globalopt"])
    return base + chosen


def enrich_pipeline(
    base_passes: List[str],
    custom_opt_passes: Sequence[str],
    dispatcher_mode: bool,
    state_perturb: bool,
    indirect_dispatch: bool,
) -> List[str]:
    passes = list(base_passes)
    if dispatcher_mode:
        passes.extend(["-simplifycfg", "-loop-rotate"])
    if state_perturb:
        passes.append("-reassociate")
    if indirect_dispatch:
        passes.append("-jump-threading")
    passes.extend(custom_opt_passes)
    return passes


def pipeline_hash(passes: Sequence[str]) -> str:
    return hashlib.sha256(" ".join(passes).encode("utf-8")).hexdigest()[:16]


def resolve_build_paths(input_file: Path, output: Path | None, workdir: Path | None) -> BuildPaths:
    wd = workdir or (input_file.parent / ".obf_build")
    wd.mkdir(parents=True, exist_ok=True)
    out = output or (input_file.parent / f"{input_file.stem}.obf")
    stem = input_file.stem
    return BuildPaths(
        workdir=wd,
        transformed_src=wd / f"{stem}.obf.c",
        ir_path=wd / f"{stem}.ll",
        transformed_ir_path=wd / f"{stem}.opt.ll",
        output=out,
        manifest=wd / "obfuscation_manifest.json",
    )


def probe_llvm_obf_support(clang_cmd: Sequence[str], flatten: bool, bogus: bool) -> bool:
    if not (flatten or bogus):
        return False

    flags: list[str] = []
    if flatten:
        flags += ["-mllvm", "-fla"]
    if bogus:
        flags += ["-mllvm", "-bcf"]

    cmd = list(clang_cmd) + flags + ["-x", "c", "-", "-o", "/tmp/obf_probe_bin"]
    return run_probe(cmd, stdin_data="int main(){return 0;}")


def build_with_opt(clang: str, opt: str, paths: BuildPaths, strategy: Strategy, cflags: Sequence[str]) -> None:
    run([clang, *cflags, "-S", "-emit-llvm", "-O0", str(paths.transformed_src), "-o", str(paths.ir_path)])
    if strategy.pass_plugin and strategy.plugin_passes:
        plugin_pipeline = ",".join(strategy.plugin_passes)
        run(
            [
                opt,
                "-load-pass-plugin",
                strategy.pass_plugin,
                "-passes",
                plugin_pipeline,
                str(paths.ir_path),
                "-S",
                "-o",
                str(paths.transformed_ir_path),
            ]
        )
    else:
        run([opt, *strategy.passes, str(paths.ir_path), "-S", "-o", str(paths.transformed_ir_path)])
    run([clang, *cflags, str(paths.transformed_ir_path), "-O2", "-o", str(paths.output)])


def build_with_llvm_auto(clang_cmd: Sequence[str], paths: BuildPaths, strategy: Strategy) -> None:
    flags: list[str] = ["-O2"]
    if strategy.flatten:
        flags += ["-mllvm", "-fla"]
    if strategy.bogus:
        flags += ["-mllvm", "-bcf"]
    if strategy.split_count > 0:
        flags += ["-mllvm", "-split", "-mllvm", f"-split_num={strategy.split_count}"]
    if strategy.dispatcher_mode:
        flags += ["-mllvm", "-fla"]
    if strategy.indirect_dispatch:
        flags += ["-mllvm", "-sub"]
    run([*clang_cmd, *flags, str(paths.transformed_src), "-o", str(paths.output)])


def create_clang_cmd(platform: str, target: str | None) -> list[str]:
    if platform == "ios":
        xcrun = find_tool("xcrun")
        cmd = [xcrun, "--sdk", "iphoneos", "clang"]
        if target:
            cmd += ["-target", target]
        return cmd

    clang = find_tool("clang")
    cmd = [clang]
    if target:
        cmd += ["-target", target]
    return cmd


def should_obfuscate_source(path: Path) -> bool:
    if path.suffix.lower() not in IOS_SOURCE_EXTS:
        return False
    if any(part in {"Pods", "Carthage", "build", ".git", ".obf_build"} for part in path.parts):
        return False
    return True


def load_whitelist(path: Path | None) -> list[str]:
    if not path:
        return []
    rules: list[str] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        rules.append(line)
    return rules


def is_whitelisted(rel_path: Path, whitelist_rules: Sequence[str]) -> bool:
    p = str(rel_path)
    return any(rule in p for rule in whitelist_rules)


def _make_writable(path: Path) -> None:
    """Best-effort: ensure an existing path is writable for overwrite/removal."""
    try:
        mode = path.stat().st_mode
        path.chmod(mode | 0o200)
    except OSError:
        # Ignore permission tweaking failures; caller may still succeed via remove/rename.
        pass


def copy_file_force(src: Path, dst: Path) -> None:
    """Copy file while handling stale read-only outputs from previous runs."""
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dst.exists():
        _make_writable(dst)
        try:
            dst.unlink()
        except IsADirectoryError:
            shutil.rmtree(dst, ignore_errors=True)
        except OSError:
            # Fall back to copy2 overwrite path for unusual files.
            pass
    shutil.copy2(src, dst)


def write_text_force(dst: Path, text: str, encoding: str = "utf-8") -> None:
    """Write text even if destination is read-only from earlier copy operations."""
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dst.exists():
        _make_writable(dst)
    with open(dst, "w", encoding=encoding, errors="ignore", newline="") as f:
        f.write(text)


def obfuscate_ios_project_sources(
    project_dir: Path,
    out_dir: Path,
    seed: int,
    objc_runtime_whitelist: Sequence[str],
) -> dict:
    if not project_dir.is_dir():
        raise RuntimeError(f"Not a directory: {project_dir}")

    changed_files: list[str] = []
    scanned = 0
    swift_files = 0
    skipped_by_whitelist: list[str] = []
    skipped_third_party_files = 0
    for src in project_dir.rglob("*"):
        if not src.is_file():
            continue
        rel = src.relative_to(project_dir)
        if out_dir in src.parents:
            # Skip output tree if user places project-out under input project directory.
            continue
        if any(part in THIRD_PARTY_DIRS for part in rel.parts):
            # Filter third-party dependency trees (Pods/Carthage) in project mode.
            skipped_third_party_files += 1
            continue
        dst = out_dir / rel

        if should_obfuscate_source(rel):
            if is_whitelisted(rel, objc_runtime_whitelist):
                copy_file_force(src, dst)
                skipped_by_whitelist.append(str(rel))
                continue
            scanned += 1
            if rel.suffix.lower() == ".swift":
                # Swift mixed project support: preserve source, do not mutate Swift strings here.
                swift_files += 1
                copy_file_force(src, dst)
            else:
                text = src.read_text(encoding="utf-8", errors="ignore")
                transformed = obfuscate_strings(text, seed)
                write_text_force(dst, transformed, encoding="utf-8")
                changed_files.append(str(rel))
        else:
            copy_file_force(src, dst)

    return {
        "mode": "ios_project_sources",
        "project_dir": str(project_dir),
        "output_dir": str(out_dir),
        "seed": seed,
        "obfuscated_file_count": len(changed_files),
        "scanned_source_count": scanned,
        "obfuscated_files": changed_files,
        "swift_passthrough_count": swift_files,
        "whitelist_skipped_files": skipped_by_whitelist,
        "third_party_filtered_dirs": sorted(THIRD_PARTY_DIRS),
        "third_party_filtered_file_count": skipped_third_party_files,
    }


def summarize_ios_project_sources_for_inplace_build(
    project_dir: Path,
    objc_runtime_whitelist: Sequence[str],
) -> dict:
    scanned = 0
    swift_files = 0
    skipped_by_whitelist: list[str] = []
    skipped_third_party_files = 0
    eligible_files: list[str] = []
    for src in project_dir.rglob("*"):
        if not src.is_file():
            continue
        rel = src.relative_to(project_dir)
        if any(part in THIRD_PARTY_DIRS for part in rel.parts):
            skipped_third_party_files += 1
            continue
        if should_obfuscate_source(rel):
            if is_whitelisted(rel, objc_runtime_whitelist):
                skipped_by_whitelist.append(str(rel))
                continue
            scanned += 1
            if rel.suffix.lower() == ".swift":
                swift_files += 1
            eligible_files.append(str(rel))
    return {
        "scanned_source_count": scanned,
        "swift_passthrough_count": swift_files,
        "whitelist_skipped_files": skipped_by_whitelist,
        "third_party_filtered_dirs": sorted(THIRD_PARTY_DIRS),
        "third_party_filtered_file_count": skipped_third_party_files,
        "plugin_candidate_file_count": len(eligible_files),
        "plugin_candidate_files_sample": eligible_files[:200],
    }


def _resolve_container_path(project_out: Path, value: str) -> Path:
    raw = Path(value)
    if raw.is_absolute():
        return raw
    return project_out / raw


def _auto_find_container(project_out: Path) -> tuple[str, Path]:
    workspaces = sorted(project_out.rglob("*.xcworkspace"))
    if workspaces:
        return ("-workspace", workspaces[0])

    projects = sorted(project_out.rglob("*.xcodeproj"))
    if projects:
        return ("-project", projects[0])

    raise RuntimeError("No .xcworkspace or .xcodeproj found in obfuscated project output")


def build_ios_project(
    project_out: Path,
    args: argparse.Namespace,
    build_workdir: Path,
    plugin_path: str | None = None,
) -> dict:
    if args.build_target == "none":
        return {"build_target": "none", "note": "Skipped compile stage; generated obfuscated project copy only."}

    xcrun = find_tool("xcrun")

    if args.workspace:
        container_flag, container_path = "-workspace", _resolve_container_path(project_out, args.workspace)
    elif args.project:
        container_flag, container_path = "-project", _resolve_container_path(project_out, args.project)
    else:
        container_flag, container_path = _auto_find_container(project_out)

    if not container_path.exists():
        raise RuntimeError(f"Xcode container not found: {container_path}")

    if args.build_target in {"app", "ipa"} and not args.scheme:
        raise RuntimeError("Auto-build APP/IPA requires --scheme")

    configuration = args.configuration
    sdk = args.sdk
    derived_data = build_workdir / "DerivedData"
    archive_path = Path(args.archive_path) if args.archive_path else (build_workdir / "ObfuscatedApp.xcarchive")
    export_path = Path(args.export_path) if args.export_path else (build_workdir / "Export")

    common = [
        xcrun,
        "xcodebuild",
        container_flag,
        str(container_path),
        "-scheme",
        args.scheme or "",
        "-configuration",
        configuration,
        "-derivedDataPath",
        str(derived_data),
        "-sdk",
        sdk,
    ]

    if plugin_path and args.xcode_global_pass_plugin:
        # Unsafe/global injection: affects all workspace targets (including Pods).
        common.extend(
            [
                f"OTHER_CFLAGS=$(inherited) -fpass-plugin={plugin_path}",
                f"OTHER_CPLUSPLUSFLAGS=$(inherited) -fpass-plugin={plugin_path}",
            ]
        )

    if args.ui_guard_define:
        common.extend(
            [
                "OTHER_CFLAGS=$(inherited) -DOBF_UI_GUARD=1",
                "OTHER_CPLUSPLUSFLAGS=$(inherited) -DOBF_UI_GUARD=1",
                "OTHER_SWIFT_FLAGS=$(inherited) -D OBF_UI_GUARD",
            ]
        )

    if args.macho_order_file:
        order_file = Path(args.macho_order_file)
        if not order_file.is_absolute():
            order_file = project_out / order_file
        common.append(f"OTHER_LDFLAGS=$(inherited) -Wl,-order_file,{order_file}")

    result: dict = {
        "container": {"flag": container_flag, "path": str(container_path)},
        "scheme": args.scheme,
        "configuration": configuration,
        "sdk": sdk,
        "derived_data": str(derived_data),
        "xcode_pass_plugin": plugin_path,
        "xcode_global_pass_plugin": bool(args.xcode_global_pass_plugin),
        "ui_guard_define": bool(args.ui_guard_define),
        "macho_order_file": args.macho_order_file,
    }

    if args.build_target == "app":
        run([*common, "clean", "build"])
        result["build_target"] = "app"
        result["note"] = "App built in DerivedData/Build/Products; sign/export according to your provisioning settings."
        return result

    if args.build_target == "ipa":
        if not args.export_options_plist:
            raise RuntimeError("Building IPA requires --export-options-plist")
        export_options = Path(args.export_options_plist)
        run([*common, "archive", "-archivePath", str(archive_path)])
        run(
            [
                xcrun,
                "xcodebuild",
                "-exportArchive",
                "-archivePath",
                str(archive_path),
                "-exportPath",
                str(export_path),
                "-exportOptionsPlist",
                str(export_options),
            ]
        )
        result["build_target"] = "ipa"
        result["archive_path"] = str(archive_path)
        result["export_path"] = str(export_path)
        result["export_options_plist"] = str(export_options)
        return result

    result["build_target"] = "none"
    return result


def run_external_security_module(module_cmd: str, project_out: Path) -> None:
    """Run user-provided hardening module as an independent integration point.

    Note: this hook is intentionally generic and does not embed anti-analysis payloads.
    """
    cmd = [module_cmd, str(project_out)]
    run(cmd)


def run_external_ui_guard_module(module_cmd: str, project_out: Path) -> None:
    """Run user-provided UI hardening module (e.g., screenshot/screen-record overlays)."""
    cmd = [module_cmd, str(project_out)]
    run(cmd)


def detect_default_plugin() -> str | None:
    base = Path(__file__).resolve().parent / "llvm_passes" / "build"
    candidates = [
        base / "ObfPassPlugin.dylib",
        base / "libObfPassPlugin.dylib",
        base / "ObfPassPlugin.so",
        base / "libObfPassPlugin.so",
    ]
    for p in candidates:
        if p.exists():
            return str(p)
    return None


def parse_args(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="LLVM obfuscation automation script")
    parser.add_argument("input", type=Path, help="Input C/C++ source file OR iOS project directory")
    parser.add_argument("-o", "--output", type=Path, help="Output binary path")
    parser.add_argument("--workdir", type=Path, help="Workdir path")
    parser.add_argument("--seed", type=int, help="Random seed")
    parser.add_argument("--aggressive", action="store_true", help="Use heavier random pass strategy")
    parser.add_argument("--flatten", action="store_true", help="Enable control-flow flattening (-mllvm -fla)")
    parser.add_argument("--bogus", action="store_true", help="Enable bogus control-flow insertion (-mllvm -bcf)")
    parser.add_argument("--llvm-auto", action="store_true", help="Auto-detect and apply LLVM obfuscation flags")
    parser.add_argument("--platform", choices=["native", "ios"], default="native", help="Build platform")
    parser.add_argument("--target", help="Target triple, e.g. arm64-apple-ios13.0")
    parser.add_argument("--custom-opt-pass", action="append", default=[], help="Append custom opt pass flag(s), repeatable")
    parser.add_argument("--pass-plugin", help="Path to new-PM LLVM pass plugin (.so/.dylib)")
    parser.add_argument("--plugin-pass", action="append", default=[], help="Plugin pipeline pass name, repeatable (e.g. obf-flatten)")
    parser.add_argument("--no-default-plugin", action="store_true", help="Disable auto-loading repository custom pass plugin")
    parser.add_argument("--no-max-strength", action="store_true", help="Disable default maximum-strength plugin pass stack")
    parser.add_argument("--split-count", type=int, default=0, help="Basic-block split count hint recorded in manifest")
    parser.add_argument("--dispatcher-mode", action="store_true", help="Enable dispatcher-driven flatten strategy hints")
    parser.add_argument("--state-perturb", action="store_true", help="Enable state-variable perturbation strategy hints")
    parser.add_argument("--indirect-dispatch", action="store_true", help="Enable indirect dispatch strategy hints")
    parser.add_argument("--project-mode", action="store_true", help="Enable iOS project workflow")
    parser.add_argument("--copy-project", action="store_true", help="Copy+rewrite project sources into --project-out before build (disabled by default)")
    parser.add_argument("--project-out", type=Path, help="Output directory when --copy-project is enabled; default: <project>_obf")
    parser.add_argument("--objc-whitelist-file", type=Path, help="Objective-C runtime keypoint whitelist (one path fragment per line)")
    parser.add_argument("--security-module", help="External hardening module command (independent integration point)")
    parser.add_argument("--ui-guard-module", help="External UI guard module command (screen-capture/screenshot hardening hook)")
    parser.add_argument("--ui-guard-define", action="store_true", help="Inject OBF_UI_GUARD compile define into xcodebuild flags")
    parser.add_argument("--macho-order-file", help="Mach-O order file for linker reordering (xcodebuild OTHER_LDFLAGS)")
    parser.add_argument(
        "--xcode-global-pass-plugin",
        action="store_true",
        help="(Unsafe) Inject pass plugin globally via OTHER_CFLAGS/OTHER_CPLUSPLUSFLAGS; affects Pods targets too",
    )

    # project auto-build options
    parser.add_argument("--build-target", choices=["none", "app", "ipa"], default="none", help="In project-mode, auto build APP or IPA")
    parser.add_argument("--workspace", help="Workspace path (absolute or relative to --project-out)")
    parser.add_argument("--project", help="Project path (absolute or relative to --project-out)")
    parser.add_argument("--scheme", help="Xcode scheme for auto-build")
    parser.add_argument("--configuration", default="Release", help="Build configuration (default: Release)")
    parser.add_argument("--sdk", default="iphoneos", help="Xcode SDK (default: iphoneos)")
    parser.add_argument("--archive-path", help="Archive output path for IPA")
    parser.add_argument("--export-path", help="Export output path for IPA")
    parser.add_argument("--export-options-plist", help="exportOptions.plist path for IPA export")

    return parser.parse_args(argv)


def single_file_flow(args: argparse.Namespace, seed: int) -> dict:
    rng = random.Random(seed)
    paths = resolve_build_paths(args.input, args.output, args.workdir)
    source = args.input.read_text(encoding="utf-8")
    paths.transformed_src.write_text(obfuscate_strings(source, seed), encoding="utf-8")

    clang_cmd = create_clang_cmd(args.platform, args.target)
    flatten = bool(args.flatten)
    bogus = bool(args.bogus)
    base_passes = choose_pipeline(rng, args.aggressive)
    passes = enrich_pipeline(
        base_passes,
        custom_opt_passes=args.custom_opt_pass,
        dispatcher_mode=bool(args.dispatcher_mode),
        state_perturb=bool(args.state_perturb),
        indirect_dispatch=bool(args.indirect_dispatch),
    )

    selected_plugin = args.pass_plugin
    if not selected_plugin and not args.no_default_plugin:
        selected_plugin = detect_default_plugin()

    plugin_passes = list(args.plugin_pass)
    if selected_plugin and not plugin_passes:
        if not args.no_max_strength:
            plugin_passes = list(MAX_PLUGIN_PASSES)
        else:
            if args.dispatcher_mode or args.flatten:
                plugin_passes.append("obf-flatten")
            if args.bogus:
                plugin_passes.append("obf-bogus")
            if args.indirect_dispatch:
                plugin_passes.append("obf-indirect-dispatch")
            if args.state_perturb:
                plugin_passes.append("obf-call-indirect")

    strategy = Strategy(
        seed=seed,
        flatten=flatten,
        bogus=bogus,
        llvm_auto=bool(args.llvm_auto),
        aggressive=bool(args.aggressive),
        platform=args.platform,
        target=args.target,
        passes=passes,
        pipeline_id=pipeline_hash(passes),
        backend="opt",
        custom_opt_passes=list(args.custom_opt_pass),
        split_count=max(0, args.split_count),
        dispatcher_mode=bool(args.dispatcher_mode),
        state_perturb=bool(args.state_perturb),
        indirect_dispatch=bool(args.indirect_dispatch),
        pass_plugin=selected_plugin,
        plugin_passes=plugin_passes,
    )

    if args.llvm_auto and probe_llvm_obf_support(clang_cmd, flatten, bogus):
        strategy.backend = "llvm_auto"
        build_with_llvm_auto(clang_cmd, paths, strategy)
    else:
        opt = find_tool("opt")
        cflags: list[str] = []
        if args.target:
            cflags += ["-target", args.target]
        clang = find_tool("clang")
        build_with_opt(clang, opt, paths, strategy, cflags)

    manifest = {
        "mode": "single_file",
        "input": str(args.input),
        "output": str(paths.output),
        "workdir": str(paths.workdir),
        "strategy": asdict(strategy),
    }
    paths.manifest.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    print(f"[+] output: {paths.output}")
    print(f"[+] manifest: {paths.manifest}")
    return manifest


def project_flow(args: argparse.Namespace, seed: int) -> dict:
    if args.platform != "ios":
        raise RuntimeError("--project-mode currently targets iOS projects; use --platform ios")
    if args.input.is_file():
        raise RuntimeError("--project-mode expects a project directory as input")

    whitelist = load_whitelist(args.objc_whitelist_file)
    if args.copy_project:
        project_out = args.project_out or args.input.with_name(f"{args.input.name}_obf")
        project_out.mkdir(parents=True, exist_ok=True)
        manifest = obfuscate_ios_project_sources(args.input, project_out, seed, whitelist)
        manifest["project_copy_enabled"] = True
    else:
        project_out = args.input
        summary = summarize_ios_project_sources_for_inplace_build(args.input, whitelist)
        manifest = {
            "mode": "ios_project_inplace_build",
            "project_dir": str(args.input),
            "output_dir": str(project_out),
            "seed": seed,
            "project_copy_enabled": False,
            "inplace_source_rewrite_enabled": False,
            "obfuscated_file_count": 0,
            "scanned_source_count": summary["scanned_source_count"],
            "obfuscated_files": [],
            "swift_passthrough_count": summary["swift_passthrough_count"],
            "whitelist_skipped_files": summary["whitelist_skipped_files"],
            "third_party_filtered_dirs": summary["third_party_filtered_dirs"],
            "third_party_filtered_file_count": summary["third_party_filtered_file_count"],
            "plugin_candidate_file_count": summary["plugin_candidate_file_count"],
            "plugin_candidate_files_sample": summary["plugin_candidate_files_sample"],
            "note": "Skipped project copy/rewrites; building directly in original project tree.",
        }
        if args.project_out:
            manifest["project_out_ignored"] = str(args.project_out)

    build_workdir = args.workdir or (project_out / ".obf_build")
    build_workdir.mkdir(parents=True, exist_ok=True)

    if args.security_module:
        run_external_security_module(args.security_module, project_out)
        manifest["security_module"] = args.security_module
    if args.ui_guard_module:
        run_external_ui_guard_module(args.ui_guard_module, project_out)
        manifest["ui_guard_module"] = args.ui_guard_module

    selected_plugin = args.pass_plugin
    if not selected_plugin and not args.no_default_plugin:
        selected_plugin = detect_default_plugin()
    manifest["selected_pass_plugin"] = selected_plugin
    if not args.copy_project:
        manifest["obfuscated_file_count"] = manifest["plugin_candidate_file_count"] if selected_plugin else 0

    build_manifest = build_ios_project(project_out, args, build_workdir, plugin_path=selected_plugin)
    manifest["auto_build"] = build_manifest

    manifest_path = build_workdir / "obfuscation_manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    if args.copy_project:
        print(f"[+] obfuscated project source copy: {project_out}")
    else:
        print(f"[+] in-place project build root: {project_out}")
    print(f"[+] auto build target: {args.build_target}")
    print(f"[+] manifest: {manifest_path}")
    return manifest


def main(argv: Sequence[str]) -> int:
    args = parse_args(argv)
    seed = args.seed if args.seed is not None else random.SystemRandom().randint(1, 2**31 - 1)

    if args.project_mode:
        project_flow(args, seed)
        return 0

    if args.input.is_dir():
        raise RuntimeError("Directory input requires --project-mode")

    single_file_flow(args, seed)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except subprocess.CalledProcessError as exc:
        print(f"[!] command failed ({exc.returncode})", file=sys.stderr)
        raise SystemExit(exc.returncode)
    except Exception as exc:  # pylint: disable=broad-except
        print(f"[!] {exc}", file=sys.stderr)
        raise SystemExit(1)
