# bootstrap.ps1 — Dùng trên máy Windows mới hoàn toàn
#
# One-liner:
#   irm https://raw.githubusercontent.com/ThangDuc3101/cc-skills/main/bootstrap.ps1 | iex

$ErrorActionPreference = "Stop"

$RepoUrl = "https://github.com/ThangDuc3101/cc-skills.git"
$InstallDir = "$HOME\.cc-skills"

Write-Host "🚀 cc-skills bootstrap (Windows)" -ForegroundColor Cyan
Write-Host ""

# Bước 1 — Kiểm tra deps
foreach ($cmd in @("git", "curl")) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-Host "❌ '$cmd' không tìm thấy. Vui lòng cài đặt trước:" -ForegroundColor Red
        switch ($cmd) {
            "git"  { Write-Host "   https://git-scm.com/downloads" }
            "curl" { Write-Host "   https://curl.se/download.html" }
        }
        exit 1
    }
}

# Kiểm tra kết nối internet
try {
    $null = Invoke-WebRequest -Uri "https://github.com" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
    Write-Host "✅ Kết nối internet — OK" -ForegroundColor Green
} catch {
    Write-Host "❌ Không có kết nối internet" -ForegroundColor Red
    exit 1
}

# Bước 2 — Clone hoặc update
if (Test-Path "$InstallDir\.git") {
    Write-Host "🔄 Repo đã tồn tại — đang update..."
    git -C $InstallDir pull --ff-only
} else {
    Write-Host "📥 Cloning cc-skills về $InstallDir..."
    git clone $RepoUrl $InstallDir
}

# Bước 3 — Thêm function vào PowerShell profile
$ProfileDir = Split-Path $PROFILE -Parent
if (-not (Test-Path $ProfileDir)) {
    New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
}

$FunctionDef = @"

# cc-skills
function cc-setup { & "`$HOME\.cc-skills\setup.ps1" @args }
"@

if (Test-Path $PROFILE) {
    $profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
    if ($profileContent -match "cc-skills") {
        Write-Host "ℹ️  Function cc-setup đã có trong $PROFILE"
    } else {
        Add-Content -Path $PROFILE -Value $FunctionDef
        Write-Host "✅ Đã thêm function vào $PROFILE" -ForegroundColor Green
    }
} else {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    Add-Content -Path $PROFILE -Value $FunctionDef
    Write-Host "✅ Đã tạo profile và thêm function: $PROFILE" -ForegroundColor Green
}

Write-Host ""
Write-Host "✅ Bootstrap hoàn tất!" -ForegroundColor Green
Write-Host ""
Write-Host "Bước tiếp theo:"
Write-Host "  1. Reload profile:  . `$PROFILE"
Write-Host "  2. Vào project:     cd C:\path\to\your-project"
Write-Host "  3. Chạy:            cc-setup --skills markitdown,karpathy-guidelines"
