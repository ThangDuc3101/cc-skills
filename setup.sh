#!/usr/bin/env bash
# setup.sh — Script chính, dùng hàng ngày khi bắt đầu một project
#
# Cú pháp:
#   cc-setup --skills <skill1,skill2,...> [--mode <new|append|detect>]
#
# Ví dụ:
#   cc-setup --skills markitdown,karpathy-guidelines
#   cc-setup --skills markitdown --mode new

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"
TEMPLATES_DIR="$SCRIPT_DIR/templates"
TARGET="CLAUDE.md"
SKILLS_LIST=""
MODE="detect"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --skills) SKILLS_LIST="$2"; shift 2 ;;
        --mode)   MODE="$2"; shift 2 ;;
        --target) TARGET="$2"; shift 2 ;;
        -h|--help)
            echo "Sử dụng: cc-setup --skills <skill1,skill2,...> [--mode <new|append|detect>]"
            echo ""
            echo "  --skills   Danh sách skills, phân cách bằng dấu phẩy"
            echo "  --mode     new | append | detect (mặc định: detect)"
            exit 0
            ;;
        *) echo "❌ Tham số không hợp lệ: $1"; exit 1 ;;
    esac
done

if [ -z "$SKILLS_LIST" ]; then
    echo "❌ Thiếu --skills. Ví dụ: cc-setup --skills markitdown,karpathy-guidelines"
    exit 1
fi

echo "🚀 cc-setup — Skills: $SKILLS_LIST | Mode: $MODE"
echo ""

# Bước 1 — Kiểm tra môi trường
"$SCRIPTS_DIR/check_deps.sh"
echo ""

# Bước 2 — Detect mode nếu cần
if [ "$MODE" = "detect" ]; then
    set +e
    "$SCRIPTS_DIR/detect_claude_md.sh" "$TARGET"
    DETECT_CODE=$?
    set -e

    case $DETECT_CODE in
        0) MODE="new" ;;
        1) MODE="append" ;;
        2) MODE="update" ;;
    esac
fi

echo "📋 Mode: $MODE"
echo ""

# Bước 3 — Thực thi theo mode
case "$MODE" in
    new)
        echo "📄 Tạo $TARGET từ template..."
        TEMPLATE="$TEMPLATES_DIR/CLAUDE.md.template"
        cp "$TEMPLATE" "$TARGET"
        # Inject skills vào placeholder (thay {{SKILLS_CONTENT}} bằng nội dung thực)
        "$SCRIPTS_DIR/append_skills.sh" --skills "$SKILLS_LIST" --target "$TARGET"
        ;;

    append)
        "$SCRIPTS_DIR/backup_claude_md.sh" "$TARGET"
        "$SCRIPTS_DIR/append_skills.sh" --skills "$SKILLS_LIST" --target "$TARGET"
        ;;

    update)
        echo "⚠️  $TARGET đã có section CC-SKILLS."
        echo "Chọn hành động: [u]pdate / [s]kip / [a]bort"
        read -r -p "> " CHOICE
        case "$CHOICE" in
            u|update)
                "$SCRIPTS_DIR/backup_claude_md.sh" "$TARGET"
                "$SCRIPTS_DIR/append_skills.sh" --skills "$SKILLS_LIST" --target "$TARGET"
                ;;
            s|skip)
                echo "⏭️  Bỏ qua inject. Không có thay đổi."
                exit 0
                ;;
            a|abort)
                echo "🛑 Đã hủy."
                exit 1
                ;;
            *)
                echo "❌ Lựa chọn không hợp lệ. Đã hủy."
                exit 1
                ;;
        esac
        ;;

    *)
        echo "❌ Mode không hợp lệ: $MODE (phải là new | append | detect)"
        exit 1
        ;;
esac

echo ""

# Bước cuối bắt buộc — Verify
"$SCRIPTS_DIR/verify_setup.sh" --skills "$SKILLS_LIST" --target "$TARGET"
