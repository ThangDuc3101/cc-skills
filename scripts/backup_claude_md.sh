#!/usr/bin/env bash
# backup_claude_md.sh — Backup CLAUDE.md trước mọi thao tác modify

set -euo pipefail

TARGET="${1:-CLAUDE.md}"
BACKUP="${TARGET}.bak"

if [ ! -f "$TARGET" ]; then
    echo "ℹ️  Không có $TARGET để backup — bỏ qua."
    exit 0
fi

cp "$TARGET" "$BACKUP"
echo "📦 Backup lưu tại: $BACKUP"
