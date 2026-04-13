#!/usr/bin/env bash
# check_deps.sh — Kiểm tra môi trường trước khi chạy bất cứ thứ gì

set -euo pipefail

MISSING=0

check_command() {
    local cmd="$1"
    local install_hint="$2"
    if ! command -v "$cmd" &>/dev/null; then
        echo "❌ '$cmd' không tìm thấy. $install_hint"
        MISSING=1
    else
        echo "✅ $cmd — OK"
    fi
}

check_internet() {
    if ping -c 1 -W 2 github.com &>/dev/null 2>&1 || \
       curl -s --max-time 3 https://github.com -o /dev/null 2>/dev/null; then
        echo "✅ Kết nối internet — OK"
    else
        echo "❌ Không có kết nối internet (không ping được github.com)"
        MISSING=1
    fi
}

echo "🔍 Kiểm tra môi trường..."

check_command "git" "Cài git: https://git-scm.com/downloads"
check_command "curl" "Cài curl: https://curl.se/download.html"
check_internet

if [ "$MISSING" -ne 0 ]; then
    echo ""
    echo "⚠️  Một hoặc nhiều dependency còn thiếu. Vui lòng cài đặt trước khi tiếp tục."
    exit 1
fi

echo ""
echo "✅ Môi trường sẵn sàng."
