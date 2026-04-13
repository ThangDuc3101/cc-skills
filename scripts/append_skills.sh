#!/usr/bin/env bash
# append_skills.sh — Inject nội dung skills vào CLAUDE.md một cách an toàn
#
# Sử dụng: append_skills.sh --skills <skill1,skill2,...> [--target <path/to/CLAUDE.md>]

set -euo pipefail

SKILLS_DIR="$(cd "$(dirname "$0")/../skills" && pwd)"
TEMPLATES_DIR="$(cd "$(dirname "$0")/../templates" && pwd)"
TARGET="CLAUDE.md"
SKILLS_LIST=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --skills) SKILLS_LIST="$2"; shift 2 ;;
        --target) TARGET="$2"; shift 2 ;;
        *) echo "❌ Tham số không hợp lệ: $1"; exit 1 ;;
    esac
done

if [ -z "$SKILLS_LIST" ]; then
    echo "❌ Thiếu --skills. Ví dụ: append_skills.sh --skills markitdown,karpathy-guidelines"
    exit 1
fi

# Build skills content
SKILLS_CONTENT=""
IFS=',' read -ra SKILL_ARRAY <<< "$SKILLS_LIST"
for skill in "${SKILL_ARRAY[@]}"; do
    skill="$(echo "$skill" | tr -d '[:space:]')"
    SKILL_FILE="$SKILLS_DIR/$skill/SKILL.md"
    if [ ! -f "$SKILL_FILE" ]; then
        echo "❌ Không tìm thấy skill: $skill (tìm ở $SKILL_FILE)"
        exit 1
    fi
    SKILLS_CONTENT="${SKILLS_CONTENT}
## Skill: $skill

$(cat "$SKILL_FILE")
"
done

BEGIN_MARKER="# ── CC-SKILLS BEGIN (auto-generated, do not edit manually) ──"
END_MARKER="# ── CC-SKILLS END ──"

INJECT_BLOCK="${BEGIN_MARKER}
${SKILLS_CONTENT}
${END_MARKER}"

if [ ! -f "$TARGET" ]; then
    echo "❌ Không tìm thấy $TARGET"
    exit 1
fi

if grep -q "# ── CC-SKILLS BEGIN" "$TARGET" 2>/dev/null; then
    # Xóa section cũ và inject section mới
    # Dùng awk để xóa phần giữa hai marker (inclusive)
    TMPFILE="$(mktemp)"
    awk "
        /^# ── CC-SKILLS BEGIN/ { skip=1 }
        !skip { print }
        /^# ── CC-SKILLS END/ { skip=0 }
    " "$TARGET" > "$TMPFILE"
    mv "$TMPFILE" "$TARGET"
    echo "🔄 Đã xóa section CC-SKILLS cũ."
fi

# Append section mới vào cuối file
printf '\n%s\n' "$INJECT_BLOCK" >> "$TARGET"
echo "✅ Đã inject skills: $SKILLS_LIST vào $TARGET"
