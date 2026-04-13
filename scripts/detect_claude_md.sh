#!/usr/bin/env bash
# detect_claude_md.sh — Kiểm tra trạng thái CLAUDE.md trong thư mục hiện tại
#
# Exit codes (Unix convention: 0 = success/found):
#   0 — có file, đã có section CC-SKILLS
#   1 — có file, chưa có section CC-SKILLS
#   2 — không có file CLAUDE.md

TARGET="${1:-CLAUDE.md}"

if [ ! -f "$TARGET" ]; then
    echo "ℹ️  Không tìm thấy $TARGET"
    exit 2
fi

if grep -q "# ── CC-SKILLS BEGIN" "$TARGET" 2>/dev/null; then
    echo "ℹ️  $TARGET đã có section CC-SKILLS"
    exit 0
else
    echo "ℹ️  $TARGET tồn tại nhưng chưa có section CC-SKILLS"
    exit 1
fi
