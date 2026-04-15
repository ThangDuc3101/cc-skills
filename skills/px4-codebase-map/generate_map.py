#!/usr/bin/env python3
"""
generate_map.py — Tạo codebase map cho PX4-Autopilot
Chạy 1 lần từ thư mục gốc của PX4-Autopilot, lưu vào .px4-graph/px4_map.json

Usage:
    python3 ~/.cc-skills/skills/px4-codebase-map/generate_map.py --source .
    python3 ~/.cc-skills/skills/px4-codebase-map/generate_map.py --source /path/to/PX4-Autopilot
"""

import os
import re
import json
import argparse
from pathlib import Path
from collections import defaultdict

# Thư mục chứa modules trong PX4
MODULE_ROOTS = [
    "src/modules",
    "src/drivers",
    "src/lib",
    "src/systemcmds",
]

# uORB publish patterns — cover cả style cũ (orb_advertise) và modern (Publication{ORB_ID})
PUB_PATTERNS = [
    # Style cũ: orb_advertise(ORB_ID(topic))
    re.compile(r'orb_advertise(?:_multi)?\s*\(\s*ORB_ID\s*\(\s*(\w+)\s*\)'),
    # Modern style: uORB::Publication<type_s> _pub{ORB_ID(topic)} → ưu tiên lấy ORB_ID
    re.compile(r'uORB::Publication(?:Multi|Queued)?\s*<[^>]*>\s*\w+\s*\{[^}]*ORB_ID\s*\(\s*(\w+)\s*\)'),
    # Fallback type-based (strip _s suffix sau khi capture)
    re.compile(r'uORB::Publication\s*<\s*(\w+?_s)\s*>'),
    re.compile(r'uORB::PublicationMulti\s*<\s*(\w+?_s)\s*>'),
    re.compile(r'uORB::PublicationQueued\s*<\s*(\w+?_s)\s*>'),
]

# uORB subscribe patterns — cover cả style cũ và modern constructor {ORB_ID(topic)}
SUB_PATTERNS = [
    # Style cũ: orb_subscribe(ORB_ID(topic))
    re.compile(r'orb_subscribe(?:_multi)?\s*\(\s*ORB_ID\s*\(\s*(\w+)\s*\)'),
    # Modern style: uORB::Subscription _sub{ORB_ID(topic)} (không có <type>)
    re.compile(r'uORB::Subscription(?:CallbackWorkItem|Interval|MultiArray)?\s+\w+\s*\{[^}]*ORB_ID\s*\(\s*(\w+)\s*\)'),
    # Modern style với <type>: uORB::Subscription<type_s> _sub{ORB_ID(topic)}
    re.compile(r'uORB::Subscription(?:CallbackWorkItem|Interval|MultiArray)?\s*<[^>]*>\s*\w+\s*\{[^}]*ORB_ID\s*\(\s*(\w+)\s*\)'),
    # Fallback type-based (strip _s suffix sau khi capture)
    re.compile(r'uORB::Subscription\s*<\s*(\w+?_s)\s*>'),
    re.compile(r'uORB::SubscriptionCallbackWorkItem\s*<\s*(\w+?_s)\s*>'),
    re.compile(r'uORB::SubscriptionInterval\s*<\s*(\w+?_s)\s*>'),
    re.compile(r'uORB::SubscriptionMultiArray\s*<\s*(\w+?_s)\s*>'),
]


def strip_msg_suffix(name: str) -> str:
    """Strip _s suffix từ message type để ra topic name: vehicle_local_position_s → vehicle_local_position."""
    return name[:-2] if name.endswith('_s') else name

# Parameter definition pattern
PARAM_PATTERN = re.compile(r'PARAM_DEFINE_\w+\s*\(\s*(\w+)\s*,')


def find_modules(source_dir: Path) -> dict:
    """Tìm tất cả modules dựa trên CMakeLists.txt trong các thư mục chuẩn của PX4."""
    modules = {}

    for mod_root in MODULE_ROOTS:
        root_path = source_dir / mod_root
        if not root_path.exists():
            continue

        for cmake_file in sorted(root_path.rglob("CMakeLists.txt")):
            mod_path = cmake_file.parent

            # Bỏ qua thư mục gốc của mod_root
            if mod_path == root_path:
                continue

            short_name = mod_path.name
            rel_path = mod_path.relative_to(source_dir).as_posix()

            cpp_files = (
                list(mod_path.glob("*.cpp"))
                + list(mod_path.glob("*.c"))
                + list(mod_path.glob("*.hpp"))
                + list(mod_path.glob("*.h"))
            )

            if not cpp_files:
                continue

            modules[short_name] = {
                "path": rel_path,
                "files": sorted(
                    str(f.relative_to(source_dir)) for f in cpp_files
                ),
                "publishes": [],
                "subscribes": [],
                "params": [],
            }

    return modules


def extract_uorb(source_dir: Path, modules: dict) -> dict:
    """Extract uORB publish/subscribe từ C++ source files."""
    uorb_topics: dict = defaultdict(lambda: {"publishers": [], "subscribers": []})

    for mod_name, mod_info in modules.items():
        mod_path = source_dir / mod_info["path"]

        for cpp_file in list(mod_path.rglob("*.cpp")) + list(mod_path.rglob("*.hpp")):
            try:
                content = cpp_file.read_text(errors="ignore")
            except OSError:
                continue

            for pattern in PUB_PATTERNS:
                for match in pattern.finditer(content):
                    topic = strip_msg_suffix(match.group(1))
                    if topic not in mod_info["publishes"]:
                        mod_info["publishes"].append(topic)
                    if mod_name not in uorb_topics[topic]["publishers"]:
                        uorb_topics[topic]["publishers"].append(mod_name)

            for pattern in SUB_PATTERNS:
                for match in pattern.finditer(content):
                    topic = strip_msg_suffix(match.group(1))
                    if topic not in mod_info["subscribes"]:
                        mod_info["subscribes"].append(topic)
                    if mod_name not in uorb_topics[topic]["subscribers"]:
                        uorb_topics[topic]["subscribers"].append(mod_name)

    return dict(uorb_topics)


def extract_params(source_dir: Path, modules: dict) -> dict:
    """Extract PARAM_DEFINE_* từ source files, map về module chứa nó."""
    all_params: dict = {}

    for mod_name, mod_info in modules.items():
        mod_path = source_dir / mod_info["path"]

        for src_file in (
            list(mod_path.rglob("*.cpp"))
            + list(mod_path.rglob("*.c"))
            + list(mod_path.rglob("*.h"))
        ):
            try:
                content = src_file.read_text(errors="ignore")
            except OSError:
                continue

            for match in PARAM_PATTERN.finditer(content):
                param_name = match.group(1)
                if param_name not in mod_info["params"]:
                    mod_info["params"].append(param_name)
                all_params[param_name] = mod_name

    return all_params


def print_summary(modules: dict, uorb_topics: dict, params: dict) -> None:
    """In summary sau khi generate."""
    total_files = sum(len(m["files"]) for m in modules.values())
    modules_with_pub = sum(1 for m in modules.values() if m["publishes"])
    modules_with_sub = sum(1 for m in modules.values() if m["subscribes"])

    print(f"\n{'─'*45}")
    print(f"  Modules tìm thấy   : {len(modules):>5}")
    print(f"  Files được scan    : {total_files:>5}")
    print(f"  uORB topics        : {len(uorb_topics):>5}")
    print(f"  Modules publish    : {modules_with_pub:>5}")
    print(f"  Modules subscribe  : {modules_with_sub:>5}")
    print(f"  Parameters         : {len(params):>5}")
    print(f"{'─'*45}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate PX4 codebase map cho AI agents",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument(
        "--source",
        required=True,
        metavar="PATH",
        help="Đường dẫn tới thư mục gốc PX4-Autopilot",
    )
    parser.add_argument(
        "--output",
        default=".px4-graph",
        metavar="DIR",
        help="Thư mục lưu output (default: .px4-graph)",
    )
    args = parser.parse_args()

    source_dir = Path(args.source).resolve()
    output_dir = Path(args.output)

    if not (source_dir / "src").exists():
        print(f"Lỗi: Không tìm thấy thư mục 'src/' trong {source_dir}")
        print("Hãy chắc chắn --source trỏ đến thư mục gốc PX4-Autopilot.")
        raise SystemExit(1)

    output_dir.mkdir(parents=True, exist_ok=True)

    print(f"PX4 source : {source_dir}")
    print(f"Output     : {output_dir.resolve()}")
    print()

    print("[1/3] Tìm modules...")
    modules = find_modules(source_dir)
    print(f"      → {len(modules)} modules")

    print("[2/3] Trích xuất uORB pub/sub...")
    uorb_topics = extract_uorb(source_dir, modules)
    print(f"      → {len(uorb_topics)} topics")

    print("[3/3] Trích xuất parameters...")
    params = extract_params(source_dir, modules)
    print(f"      → {len(params)} parameters")

    map_data = {
        "generated_from": str(source_dir),
        "modules": modules,
        "uorb_topics": uorb_topics,
        "params": params,
    }

    output_file = output_dir / "px4_map.json"
    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(map_data, f, indent=2, ensure_ascii=False)

    print_summary(modules, uorb_topics, params)
    print(f"\nMap lưu tại : {output_file}")
    print(f"Kích thước  : {output_file.stat().st_size / 1024:.1f} KB")
    print()
    print("Agents có thể query map bằng jq:")
    print('  jq \'.uorb_topics.vehicle_local_position\' .px4-graph/px4_map.json')
    print('  jq \'.modules.mc_pos_control\' .px4-graph/px4_map.json')
    print('  jq \'.params.MPC_XY_VEL_MAX\' .px4-graph/px4_map.json')


if __name__ == "__main__":
    main()
