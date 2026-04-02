#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
面向 ObfDemo 的 pass 命中验证脚本。

能力：
1) 调用 xcodebuild clean build，抓取主工程源码编译命令；
2) 对每个源码命令导出 plain / with-pass 两份 IR；
3) 对比 diff 并按特征分组统计命中；
4) 输出 summary.json / summary.txt / feature_summary.txt 等报告。
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shlex
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Tuple


PASS_GROUPS: Dict[str, List[str]] = {
    "string_encryption": [
        r"__obf_decode_all_strings",
        r"obf\.str\.base",
        r"obf\.str\.enc",
        r"obf\.str\.dec",
        r"llvm\.global_ctors",
    ],
    "arith_add_sub": [
        r"obf\.negrhs",
        r"obf\.add2sub",
        r"obf\.sub2add",
        r"sub i32 0,",
        r"sub i64 0,",
    ],
    "mba": [
        r"obf\.mba\.xor",
        r"obf\.mba\.and",
        r"obf\.mba\.carry",
        r"obf\.mba\.add",
        r"obf\.mba\.or",
    ],
    "const_obf": [
        r"obf\.const\.masked",
        r"obf\.const\b",
    ],
    "xor_obf": [
        r"obf\.xor\.and",
        r"obf\.xor\.twiceand",
        r"obf\.xor\.add",
        r"obf\.xor\.alt",
    ],
    "control_flow_non_conservative": [
        r"obf\.callee\.slot",
        r"obf\.callee\b",
        r"obf\.split",
        r"obf\.bogus",
        r"obf\.cond\.zext",
        r"obf\.cond\.flip",
        r"obf\.cond\.opaque",
    ],
}

SOURCE_EXTS = {".m", ".mm", ".c", ".cc", ".cpp", ".cxx"}
DEFAULT_EXCLUDES = [
    "/Pods/",
    "/Carthage/",
    "/SourcePackages/",
    "/DerivedData/",
    "/build/",
    ".build/",
    "Pods.build/",
    "Pods_",
]


@dataclass
class CompileItem:
    source: str
    cmd: str
    raw: str



def run(cmd, *, check=True, capture=False, shell=False, env=None):
    if isinstance(cmd, list):
        print("[RUN]", " ".join(shlex.quote(x) for x in cmd))
    else:
        print("[RUN]", cmd)
    return subprocess.run(cmd, check=check, text=True, capture_output=capture, shell=shell, env=env)



def write_text(path: Path, text: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8", errors="ignore")



def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore")



def sanitize_filename(path_str: str) -> str:
    s = path_str.replace("\\", "/").replace("/", "__").replace(":", "_")
    return re.sub(r"[^a-zA-Z0-9_\-.]+", "_", s)



def pick_container(workspace: Path, project: Path) -> Tuple[List[str], str]:
    if workspace.exists():
        return ["-workspace", str(workspace)], str(workspace)
    if project.exists():
        return ["-project", str(project)], str(project)
    raise FileNotFoundError(f"workspace/project 都不存在: {workspace} | {project}")



def normalize_clang_line(line: str) -> str:
    s = line.strip()
    if "exec:" in s and "[my-clang" in s:
        s = s.split("exec:", 1)[1].strip()
    return s



def is_compile_line(line: str) -> bool:
    s = line.strip()
    return "clang" in s and " -c " in s and " -o " in s



def extract_source(args: List[str]) -> str | None:
    for i, a in enumerate(args):
        if a == "-c" and i + 1 < len(args):
            return args[i + 1]
    return None



def should_skip_source(src: str, includes: List[str], excludes: List[str]) -> bool:
    s = src.replace("\\", "/")
    ext = Path(s).suffix.lower()
    if ext not in SOURCE_EXTS:
        return True
    for kw in excludes:
        if kw in s:
            return True
    if includes:
        return not any(kw in s for kw in includes)
    return False



def collect_compile_items(build_log: str, includes: List[str], excludes: List[str]) -> List[CompileItem]:
    raw_lines = [ln.strip() for ln in build_log.splitlines() if is_compile_line(ln)]
    out: List[CompileItem] = []
    seen = set()

    for raw in raw_lines:
        cmd = normalize_clang_line(raw)
        try:
            args = shlex.split(cmd)
        except ValueError:
            continue
        src = extract_source(args)
        if not src or should_skip_source(src, includes, excludes):
            continue
        if src in seen:
            continue
        seen.add(src)
        out.append(CompileItem(source=src, cmd=cmd, raw=raw))
    return out



def remove_plugin_flag(cmd: str) -> str:
    cmd = re.sub(r"-fpass-plugin=[^\s]+", "", cmd)
    cmd = re.sub(r"\s+", " ", cmd).strip()
    return cmd



def filter_ir_args(args: List[str]) -> List[str]:
    skip_exact = {"-fmodules", "-gmodules", "-MMD", "-MP", "-Winvalid-offsetof"}
    skip_prefix = [
        "-fmodules-cache-path=",
        "-fbuild-session-file=",
        "-fmodules-prune-interval=",
        "-fmodules-prune-after=",
        "-index-store-path",
        "-dependency-info",
    ]
    out: List[str] = []
    i = 0
    while i < len(args):
        a = args[i]
        if a in skip_exact or any(a.startswith(p) for p in skip_prefix):
            i += 1
            continue
        if a in {"-MF", "-MT", "--serialize-diagnostics"}:
            i += 2
            continue
        out.append(a)
        i += 1
    return out



def rewrite_to_ir(cmd: str, out_ir: Path) -> str:
    args = shlex.split(cmd)
    src = None
    out: List[str] = []
    i = 0
    while i < len(args):
        a = args[i]
        if a == "-c" and i + 1 < len(args):
            src = args[i + 1]
            i += 2
            continue
        if a == "-o" and i + 1 < len(args):
            i += 2
            continue
        out.append(a)
        i += 1

    if not src:
        raise RuntimeError(f"无法解析 -c 源文件: {cmd}")

    out = filter_ir_args(out)
    if "-O0" in out and "-disable-O0-optnone" not in out:
        idx = out.index("-O0")
        out[idx + 1:idx + 1] = ["-Xclang", "-disable-O0-optnone"]

    out.extend(["-S", "-emit-llvm", src, "-o", str(out_ir)])
    return " ".join(shlex.quote(x) for x in out)



def hit_group_map(text: str) -> Dict[str, List[str]]:
    hits: Dict[str, List[str]] = {}
    for name, patterns in PASS_GROUPS.items():
        matched = [p for p in patterns if re.search(p, text)]
        if matched:
            hits[name] = matched
    return hits



def analyze_pair(plain_ir: Path, with_ir: Path, diff_text: str) -> Dict:
    plain = read_text(plain_ir)
    obf = read_text(with_ir)
    changed = plain != obf
    with_hits = hit_group_map(obf)
    diff_hits = hit_group_map(diff_text)
    reasons = []
    if changed:
        reasons.append("IR changed")
    if with_hits:
        reasons.append("with-pass hit groups: " + ",".join(with_hits.keys()))
    if diff_hits:
        reasons.append("diff hit groups: " + ",".join(diff_hits.keys()))
    return {
        "changed": changed,
        "with_group_hits": with_hits,
        "diff_group_hits": diff_hits,
        "hit_feature": bool(with_hits or diff_hits),
        "reasons": reasons,
    }



def run_one(item: CompileItem, out_dirs: Dict[str, Path]) -> Dict:
    tag = sanitize_filename(item.source)
    with_ir = out_dirs["with"] / f"{tag}.ll"
    plain_ir = out_dirs["plain"] / f"{tag}.ll"
    diff_file = out_dirs["diff"] / f"{tag}.diff"
    with_cmd_file = out_dirs["cmd"] / f"{tag}.with.sh"
    plain_cmd_file = out_dirs["cmd"] / f"{tag}.plain.sh"

    cmd_with_raw = item.cmd
    cmd_plain_raw = remove_plugin_flag(item.cmd)

    # wrapper 场景：plain 通过环境变量禁用插件
    env_plain_prefix = ""
    first_tok = shlex.split(item.cmd)[0] if item.cmd else ""
    if "my-clang" in Path(first_tok).name:
        env_plain_prefix = "MY_CLANG_DISABLE_PLUGIN=1 "

    cmd_with = rewrite_to_ir(cmd_with_raw, with_ir)
    cmd_plain = env_plain_prefix + rewrite_to_ir(cmd_plain_raw, plain_ir)

    write_text(with_cmd_file, cmd_with + "\n")
    write_text(plain_cmd_file, cmd_plain + "\n")
    os.chmod(with_cmd_file, 0o755)
    os.chmod(plain_cmd_file, 0o755)

    result = {
        "source": item.source,
        "success": False,
        "error": None,
        "with_ir": str(with_ir),
        "plain_ir": str(plain_ir),
        "diff": str(diff_file),
        "with_pass_cmd": cmd_with,
        "plain_cmd": cmd_plain,
        "changed": False,
        "hit_feature": False,
        "with_group_hits": {},
        "diff_group_hits": {},
        "reasons": [],
    }

    try:
        run(cmd_with, shell=True, check=True)
        run(cmd_plain, shell=True, check=True)
        d = run(["diff", "-u", str(plain_ir), str(with_ir)], check=False, capture=True)
        diff_text = d.stdout or ""
        write_text(diff_file, diff_text)
        ana = analyze_pair(plain_ir, with_ir, diff_text)
        result.update({"success": True, **ana})
    except subprocess.CalledProcessError as e:
        result["error"] = f"returncode={e.returncode}"
    except Exception as e:  # noqa: BLE001
        result["error"] = str(e)

    return result



def write_reports(report_dir: Path, cfg: Dict, results: List[Dict]):
    summary_json = report_dir / "summary.json"
    summary_txt = report_dir / "summary.txt"
    feature_txt = report_dir / "feature_summary.txt"
    pass_changed_txt = report_dir / "pass_changed_files.txt"
    pass_hit_txt = report_dir / "pass_hit_files.txt"
    failed_txt = report_dir / "failed_files.txt"
    all_diff_txt = report_dir / "all_diffs.txt"
    markdown_report = report_dir / "report.md"
    threshold_alerts_txt = report_dir / "threshold_alerts.txt"

    total = len(results)
    success = sum(1 for r in results if r["success"])
    changed = [r for r in results if r["success"] and r["changed"]]
    hit = [r for r in results if r["success"] and r["hit_feature"]]
    failed = [r for r in results if not r["success"]]

    counter = {k: 0 for k in PASS_GROUPS.keys()}
    feature_files = {k: [] for k in PASS_GROUPS.keys()}
    for r in results:
        if not r["success"]:
            continue
        g = set(r["with_group_hits"].keys()) | set(r["diff_group_hits"].keys())
        for name in g:
            counter[name] += 1
            feature_files[name].append(r["source"])

    summary = {
        **cfg,
        "total": total,
        "success": success,
        "changed": len(changed),
        "hit_feature": len(hit),
        "failed": len(failed),
        "feature_counter": counter,
        "feature_rate": {k: (counter[k] / success if success else 0.0) for k in counter},
        "results": results,
    }
    write_text(summary_json, json.dumps(summary, ensure_ascii=False, indent=2))

    txt = [
        "=== VERIFY OBFDEMO PASS HIT SUMMARY ===",
        f"workspace   : {cfg['workspace']}",
        f"project     : {cfg['project']}",
        f"scheme      : {cfg['scheme']}",
        f"configuration: {cfg['configuration']}",
        f"sdk         : {cfg['sdk']}",
        f"destination : {cfg['destination']}",
        f"report_dir  : {cfg['report_dir']}",
        "",
        f"total       : {total}",
        f"success     : {success}",
        f"changed     : {len(changed)}",
        f"hit_feature : {len(hit)}",
        f"failed      : {len(failed)}",
        "",
        "=== FEATURE COUNTS ===",
    ]
    txt.extend([f"{k}: {v}" for k, v in counter.items()])
    txt.append("\n=== CHANGED FILES ===")
    txt.extend([r["source"] for r in changed] or ["(none)"])
    txt.append("\n=== HIT FILES ===")
    txt.extend([r["source"] for r in hit] or ["(none)"])
    txt.append("\n=== FAILED FILES ===")
    txt.extend([f"{r['source']} :: {r['error']}" for r in failed] or ["(none)"])
    write_text(summary_txt, "\n".join(txt) + "\n")

    ft = ["=== FEATURE SUMMARY ==="]
    for k in PASS_GROUPS.keys():
        ft.append(f"{k}: {counter[k]}")
        ft.extend([f"  - {src}" for src in feature_files[k]] or ["  (none)"])
        ft.append("")
    write_text(feature_txt, "\n".join(ft))

    write_text(pass_changed_txt, "\n".join(r["source"] for r in changed) + ("\n" if changed else ""))
    write_text(pass_hit_txt, "\n".join(r["source"] for r in hit) + ("\n" if hit else ""))
    write_text(failed_txt, "\n".join(f"{r['source']} :: {r['error']}" for r in failed) + ("\n" if failed else ""))

    chunks = []
    for r in results:
        p = Path(r["diff"])
        if p.exists():
            chunks += ["=" * 100, r["source"], "=" * 100, read_text(p), ""]
    write_text(all_diff_txt, "\n".join(chunks))

    default_threshold = float(cfg.get("threshold_default", 0.0))
    group_thresholds: Dict[str, float] = cfg.get("group_thresholds", {})
    alerts: List[str] = []
    for group, count in counter.items():
        rate = (count / success) if success else 0.0
        threshold = group_thresholds.get(group, default_threshold)
        if threshold > 0 and rate < threshold:
            alerts.append(
                f"{group}: {rate:.1%} < threshold {threshold:.1%} ({count}/{success})"
            )
    write_text(threshold_alerts_txt, "\n".join(alerts) + ("\n" if alerts else ""))

    md: List[str] = []
    md.append("# ObfDemo Pass Hit Report")
    md.append("")
    md.append("## Build Context")
    md.append("")
    md.append(f"- Workspace: `{cfg['workspace']}`")
    md.append(f"- Project: `{cfg['project']}`")
    md.append(f"- Scheme: `{cfg['scheme']}`")
    md.append(f"- Configuration: `{cfg['configuration']}`")
    md.append(f"- SDK: `{cfg['sdk']}`")
    md.append(f"- Destination: `{cfg['destination']}`")
    md.append("")
    md.append("## Summary")
    md.append("")
    md.append("| Metric | Value |")
    md.append("|---|---:|")
    md.append(f"| Total files | {total} |")
    md.append(f"| Success | {success} |")
    md.append(f"| Changed | {len(changed)} |")
    md.append(f"| Hit feature | {len(hit)} |")
    md.append(f"| Failed | {len(failed)} |")
    md.append("")
    md.append("## Feature Hit Rate")
    md.append("")
    md.append("| Feature Group | Hits | Rate | Threshold | Status |")
    md.append("|---|---:|---:|---:|---|")
    for group in PASS_GROUPS.keys():
        count = counter[group]
        rate = (count / success) if success else 0.0
        threshold = group_thresholds.get(group, default_threshold)
        if threshold > 0 and rate < threshold:
            status = "🔴 ALERT"
        else:
            status = "🟢 OK"
        md.append(
            f"| `{group}` | {count}/{success} | {rate:.1%} | {threshold:.1%} | {status} |"
        )
    md.append("")
    if alerts:
        md.append("## Threshold Alerts")
        md.append("")
        for a in alerts:
            md.append(f"- 🔴 {a}")
        md.append("")
    else:
        md.append("## Threshold Alerts")
        md.append("")
        md.append("- 🟢 No alert.")
        md.append("")

    md.append("## Files Changed by Pass")
    md.append("")
    for r in changed[:200]:
        md.append(f"- `{r['source']}`")
    if not changed:
        md.append("- (none)")
    md.append("")

    md.append("## Files Hit Feature Groups")
    md.append("")
    for r in hit[:200]:
        groups = sorted(set(r["with_group_hits"].keys()) | set(r["diff_group_hits"].keys()))
        md.append(f"- `{r['source']}` → {', '.join(groups) if groups else '(none)'}")
    if not hit:
        md.append("- (none)")
    md.append("")
    write_text(markdown_report, "\n".join(md))

    print("\n[OK]", summary_json)
    print("[OK]", summary_txt)
    print("[OK]", feature_txt)
    print("[OK]", pass_changed_txt)
    print("[OK]", pass_hit_txt)
    print("[OK]", failed_txt)
    print("[OK]", all_diff_txt)
    print("[OK]", markdown_report)
    print("[OK]", threshold_alerts_txt)



def main():
    parser = argparse.ArgumentParser(description="Verify ObfDemo pass hit coverage by exporting IR per file.")
    root = Path(__file__).resolve().parents[1]
    parser.add_argument("--workspace", default=str(root / "example/ObfDemo/ObfDemo.xcworkspace"))
    parser.add_argument("--project", default=str(root / "example/ObfDemo/ObfDemo.xcodeproj"))
    parser.add_argument("--scheme", default="ObfDemo")
    parser.add_argument("--configuration", default="Debug")
    parser.add_argument("--sdk", default="iphonesimulator")
    parser.add_argument("--destination", default="generic/platform=iOS Simulator")
    parser.add_argument("--plugin", default=str(root / "build/obf-pass/SimpleObfPass.dylib"))
    parser.add_argument("--report-dir", default=str(root / "verify_xcode_pass_ir_report"))
    parser.add_argument("--include", action="append", default=[])
    parser.add_argument("--exclude", action="append", default=[])
    parser.add_argument(
        "--threshold-default",
        type=float,
        default=0.0,
        help="默认命中率阈值（0~1）。0 表示不告警。",
    )
    parser.add_argument(
        "--group-threshold",
        action="append",
        default=[],
        help="按组设置阈值，格式: group=0.35，可重复传参。",
    )
    args = parser.parse_args()

    workspace = Path(args.workspace)
    project = Path(args.project)
    plugin = Path(args.plugin)
    report_dir = Path(args.report_dir)

    if not plugin.exists():
        raise FileNotFoundError(f"plugin 不存在: {plugin}")

    build_args, selected = pick_container(workspace, project)
    excludes = DEFAULT_EXCLUDES + args.exclude

    if report_dir.exists():
        shutil.rmtree(report_dir)
    out_dirs = {
        "root": report_dir,
        "dd": report_dir / "DerivedData",
        "log": report_dir / "xcodebuild.log",
        "with": report_dir / "ir_with_pass",
        "plain": report_dir / "ir_plain",
        "diff": report_dir / "diffs",
        "cmd": report_dir / "cmds",
    }
    for key in ["root", "with", "plain", "diff", "cmd"]:
        out_dirs[key].mkdir(parents=True, exist_ok=True)

    show_dest_cmd = [
        "xcodebuild", *build_args, "-scheme", args.scheme, "-sdk", args.sdk, "-showdestinations"
    ]
    run(show_dest_cmd, check=False, capture=True)

    xcode_cmd = [
        "xcodebuild",
        *build_args,
        "-scheme", args.scheme,
        "-configuration", args.configuration,
        "-sdk", args.sdk,
        "-destination", args.destination,
        "-derivedDataPath", str(out_dirs["dd"]),
        "clean",
        "build",
    ]
    res = run(xcode_cmd, check=False, capture=True)
    full_log = (res.stdout or "") + "\n" + (res.stderr or "")
    write_text(out_dirs["log"], full_log)
    if res.returncode != 0:
        print(full_log.splitlines()[-120:])
        raise SystemExit(res.returncode)

    items = collect_compile_items(full_log, args.include, excludes)
    if not items:
        raise RuntimeError("没有找到可分析的编译命令，请检查 xcodebuild.log")

    print(f"[INFO] compile items: {len(items)}")
    results = []
    for i, item in enumerate(items, start=1):
        print(f"\n--- [{i}/{len(items)}] {item.source} ---")
        results.append(run_one(item, out_dirs))

    cfg = {
        "workspace": str(workspace),
        "project": str(project),
        "selected_container": selected,
        "scheme": args.scheme,
        "configuration": args.configuration,
        "sdk": args.sdk,
        "destination": args.destination,
        "plugin": str(plugin),
        "report_dir": str(report_dir),
        "threshold_default": args.threshold_default,
        "group_thresholds": {},
    }
    for item in args.group_threshold:
        if "=" not in item:
            raise ValueError(f"--group-threshold 格式错误: {item}")
        group, raw = item.split("=", 1)
        group = group.strip()
        if group not in PASS_GROUPS:
            raise ValueError(f"未知分组: {group}, 可选: {', '.join(PASS_GROUPS.keys())}")
        cfg["group_thresholds"][group] = float(raw.strip())
    write_reports(report_dir, cfg, results)


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as e:
        print(f"[ERR] command failed, returncode={e.returncode}")
        raise SystemExit(e.returncode)
    except Exception as e:  # noqa: BLE001
        print(f"[ERR] {e}")
        raise SystemExit(99)
