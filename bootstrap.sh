#!/usr/bin/env bash
# bootstrap.sh — Dùng trên máy mới hoàn toàn
#
# One-liner:
#   curl -fsSL https://raw.githubusercontent.com/ThangDuc3101/cc-skills/main/bootstrap.sh | bash

set -euo pipefail

REPO_URL="https://github.com/ThangDuc3101/cc-skills.git"
INSTALL_DIR="$HOME/.cc-skills"

echo "🚀 cc-skills bootstrap"
echo ""

# Bước 1 — Kiểm tra deps cơ bản
for cmd in git curl; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "❌ '$cmd' không tìm thấy. Vui lòng cài đặt trước:"
        case "$cmd" in
            git)  echo "   https://git-scm.com/downloads" ;;
            curl) echo "   https://curl.se/download.html" ;;
        esac
        exit 1
    fi
done

# Bước 2 — Clone hoặc update repo
if [ -d "$INSTALL_DIR/.git" ]; then
    echo "🔄 Repo đã tồn tại — đang update..."
    git -C "$INSTALL_DIR" pull --ff-only
else
    echo "📥 Cloning cc-skills về $INSTALL_DIR..."
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

chmod +x "$INSTALL_DIR/setup.sh"
chmod +x "$INSTALL_DIR/scripts/"*.sh

# Bước 3 — Thêm alias vào shell
add_alias() {
    local rc_file="$1"
    local alias_line='alias cc-setup="$HOME/.cc-skills/setup.sh"'

    if [ -f "$rc_file" ] && grep -q "cc-setup" "$rc_file" 2>/dev/null; then
        echo "ℹ️  Alias cc-setup đã có trong $rc_file"
    else
        echo "" >> "$rc_file"
        echo "# cc-skills" >> "$rc_file"
        echo "$alias_line" >> "$rc_file"
        echo "✅ Đã thêm alias vào $rc_file"
    fi
}

if [ -f "$HOME/.zshrc" ]; then
    add_alias "$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
    add_alias "$HOME/.bashrc"
elif [ -f "$HOME/.bash_profile" ]; then
    add_alias "$HOME/.bash_profile"
else
    echo "⚠️  Không tìm thấy .zshrc / .bashrc / .bash_profile"
    echo "   Thêm thủ công vào shell config của bạn:"
    echo '   alias cc-setup="$HOME/.cc-skills/setup.sh"'
fi

echo ""
echo "✅ Bootstrap hoàn tất!"
echo ""
echo "Bước tiếp theo:"
echo "  1. Reload shell:  source ~/.zshrc  (hoặc .bashrc)"
echo "  2. Vào project:   cd /path/to/your-project"
echo "  3. Chạy:          cc-setup --skills markitdown,karpathy-guidelines"
