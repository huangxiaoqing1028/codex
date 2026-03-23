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
IOS_SOURCE_EXTS = {".m", ".mm", ".c", ".cc", ".cpp", ".cxx"}


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
    text = bytes(payload, "utf-8").decode("unicode_escape")
    return text.encode("utf-8")


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
    run([opt, *strategy.passes, str(paths.ir_path), "-S", "-o", str(paths.transformed_ir_path)])
    run([clang, *cflags, str(paths.transformed_ir_path), "-O2", "-o", str(paths.output)])


def build_with_llvm_auto(clang_cmd: Sequence[str], paths: BuildPaths, strategy: Strategy) -> None:
    flags: list[str] = ["-O2"]
    if strategy.flatten:
        flags += ["-mllvm", "-fla"]
    if strategy.bogus:
        flags += ["-mllvm", "-bcf"]
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


def obfuscate_ios_project_sources(project_dir: Path, out_dir: Path, seed: int) -> dict:
    if not project_dir.is_dir():
        raise RuntimeError(f"Not a directory: {project_dir}")

    changed_files: list[str] = []
    scanned = 0
    for src in project_dir.rglob("*"):
        if not src.is_file():
            continue
        rel = src.relative_to(project_dir)
        dst = out_dir / rel
        dst.parent.mkdir(parents=True, exist_ok=True)

        if should_obfuscate_source(rel):
            scanned += 1
            text = src.read_text(encoding="utf-8", errors="ignore")
            transformed = obfuscate_strings(text, seed)
            dst.write_text(transformed, encoding="utf-8")
            changed_files.append(str(rel))
        else:
            shutil.copy2(src, dst)

    return {
        "mode": "ios_project_sources",
        "project_dir": str(project_dir),
        "output_dir": str(out_dir),
        "seed": seed,
        "obfuscated_file_count": len(changed_files),
        "scanned_source_count": scanned,
        "obfuscated_files": changed_files,
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


def build_ios_project(project_out: Path, args: argparse.Namespace, build_workdir: Path) -> dict:
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

    result: dict = {
        "container": {"flag": container_flag, "path": str(container_path)},
        "scheme": args.scheme,
        "configuration": configuration,
        "sdk": sdk,
        "derived_data": str(derived_data),
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
    parser.add_argument("--project-mode", action="store_true", help="Obfuscate whole iOS project sources into a copied directory")
    parser.add_argument("--project-out", type=Path, help="Output directory for project-mode; default: <project>_obf")

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
    passes = choose_pipeline(rng, args.aggressive)

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

    project_out = args.project_out or args.input.with_name(f"{args.input.name}_obf")
    project_out.mkdir(parents=True, exist_ok=True)

    manifest = obfuscate_ios_project_sources(args.input, project_out, seed)
    build_workdir = args.workdir or (project_out / ".obf_build")
    build_workdir.mkdir(parents=True, exist_ok=True)

    build_manifest = build_ios_project(project_out, args, build_workdir)
    manifest["auto_build"] = build_manifest

    manifest_path = build_workdir / "obfuscation_manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    print(f"[+] obfuscated project source copy: {project_out}")
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
