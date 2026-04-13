#!/usr/bin/env bash
# verify_setup.sh — Verify kết quả sau khi inject
#
# Sử dụng: verify_setup.sh --skills <skill1,skill2,...> [--target <path/to/CLAUDE.md>]

set -uo pipefail

TARGET="CLAUDE.md"
SKILLS_LIST=""
FAIL=0

# Keyword đặc trưng cho từng skill (thêm skill mới vào đây)
declare -A SKILL_KEYWORDS=(
    ["markitdown"]="markitdown"
    ["karpathy-guidelines"]="Minimum code"
)

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --skills) SKILLS_LIST="$2"; shift 2 ;;
        --target) TARGET="$2"; shift 2 ;;
        *) echo "❌ Tham số không hợp lệ: $1"; exit 1 ;;
    esac
done

if [ -z "$SKILLS_LIST" ]; then
    echo "❌ Thiếu --skills"
    exit 1
fi

echo ""
echo "🔍 Đang verify kết quả..."
echo ""

# Lớp 1 — Kiểm tra file tồn tại
if [ -f "$TARGET" ]; then
    printf "✅ %-30s — OK\n" "$TARGET"
else
    printf "❌ %-30s — MISSING\n" "$TARGET"
    echo ""
    echo "⚠️  File $TARGET không tồn tại. Không thể tiếp tục verify."
    exit 1
fi

# Lớp 2 — Kiểm tra marker
BEGIN_OK=0
END_OK=0

if grep -q "# ── CC-SKILLS BEGIN" "$TARGET" 2>/dev/null; then
    BEGIN_OK=1
fi
if grep -q "# ── CC-SKILLS END" "$TARGET" 2>/dev/null; then
    END_OK=1
fi

if [ "$BEGIN_OK" -eq 1 ] && [ "$END_OK" -eq 1 ]; then
    # Kiểm tra thứ tự BEGIN trước END
    BEGIN_LINE=$(grep -n "# ── CC-SKILLS BEGIN" "$TARGET" | head -1 | cut -d: -f1)
    END_LINE=$(grep -n "# ── CC-SKILLS END" "$TARGET" | head -1 | cut -d: -f1)
    if [ "$BEGIN_LINE" -lt "$END_LINE" ]; then
        printf "✅ %-30s — OK\n" "Marker CC-SKILLS"
    else
        printf "❌ %-30s — WRONG ORDER\n" "Marker CC-SKILLS"
        FAIL=1
    fi
else
    printf "❌ %-30s — MISSING\n" "Marker CC-SKILLS"
    FAIL=1
fi

# Lớp 3 — Kiểm tra nội dung từng skill
IFS=',' read -ra SKILL_ARRAY <<< "$SKILLS_LIST"
for skill in "${SKILL_ARRAY[@]}"; do
    skill="$(echo "$skill" | tr -d '[:space:]')"
    keyword="${SKILL_KEYWORDS[$skill]:-}"

    if [ -z "$keyword" ]; then
        printf "⚠️  %-30s — Không có keyword để verify (khai báo trong skills/README.md)\n" "Skill: $skill"
        continue
    fi

    if grep -q "$keyword" "$TARGET" 2>/dev/null; then
        printf "✅ %-30s — OK\n" "Skill: $skill"
    else
        printf "❌ %-30s — MISSING\n" "Skill: $skill"
        FAIL=1
    fi
done

# Backup info
if [ -f "${TARGET}.bak" ]; then
    echo "📁 Backup lưu tại: ${TARGET}.bak"
fi

echo ""

if [ "$FAIL" -ne 0 ]; then
    echo "⚠️  Inject có thể bị lỗi. Kiểm tra ${TARGET}.bak để restore:"
    echo "   cp ${TARGET}.bak ${TARGET}"
    exit 1
fi

echo "🚀 Chạy 'claude' để bắt đầu phiên làm việc"
exit 0
