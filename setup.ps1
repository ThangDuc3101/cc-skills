# setup.ps1 — Script chính cho Windows, dùng hàng ngày khi bắt đầu một project
#
# Cú pháp:
#   cc-setup --skills <skill1,skill2,...> [--mode <new|append|detect>]
#
# Ví dụ:
#   cc-setup --skills markitdown,karpathy-guidelines
#   cc-setup --skills markitdown --mode new

param(
    [string]$skills = "",
    [string]$mode = "detect",
    [string]$target = "CLAUDE.md"
)

$ErrorActionPreference = "Stop"

$ScriptDir   = Split-Path $MyInvocation.MyCommand.Path -Parent
$SkillsDir   = Join-Path $ScriptDir "skills"
$TemplateDir = Join-Path $ScriptDir "templates"

function Check-Deps {
    $missing = $false
    foreach ($cmd in @("git", "curl")) {
        if (Get-Command $cmd -ErrorAction SilentlyContinue) {
            Write-Host "✅ $cmd — OK" -ForegroundColor Green
        } else {
            Write-Host "❌ '$cmd' không tìm thấy." -ForegroundColor Red
            $missing = $true
        }
    }
    try {
        $null = Invoke-WebRequest -Uri "https://github.com" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
        Write-Host "✅ Kết nối internet — OK" -ForegroundColor Green
    } catch {
        Write-Host "❌ Không có kết nối internet" -ForegroundColor Red
        $missing = $true
    }
    if ($missing) { Write-Host "⚠️  Thiếu dependency." -ForegroundColor Yellow; exit 1 }
}

function Detect-ClaudeMd($targetFile) {
    # Return codes (Unix convention: 0 = success/found):
    #   0 — có file, đã có section CC-SKILLS
    #   1 — có file, chưa có section CC-SKILLS
    #   2 — không có file CLAUDE.md
    if (-not (Test-Path $targetFile)) { return 2 }
    $content = Get-Content $targetFile -Raw -ErrorAction SilentlyContinue
    if ($content -match [regex]::Escape("# ── CC-SKILLS BEGIN")) { return 0 }
    return 1
}

function Backup-ClaudeMd($targetFile) {
    if (Test-Path $targetFile) {
        Copy-Item $targetFile "$targetFile.bak" -Force
        Write-Host "📦 Backup lưu tại: $targetFile.bak" -ForegroundColor Cyan
    }
}

function Build-SkillsContent($skillsList) {
    $content = ""
    foreach ($skill in $skillsList) {
        $skill = $skill.Trim()
        $skillFile = Join-Path $SkillsDir "$skill\SKILL.md"
        if (-not (Test-Path $skillFile)) {
            Write-Host "❌ Không tìm thấy skill: $skill ($skillFile)" -ForegroundColor Red
            exit 1
        }
        $content += "`n## Skill: $skill`n`n"
        $content += (Get-Content $skillFile -Raw)
        $content += "`n"
    }
    return $content
}

function Inject-Skills($targetFile, $skillsContent) {
    $beginMarker = "# ── CC-SKILLS BEGIN (auto-generated, do not edit manually) ──"
    $endMarker   = "# ── CC-SKILLS END ──"
    $block = "`n$beginMarker`n$skillsContent`n$endMarker`n"

    if (Test-Path $targetFile) {
        $fileContent = Get-Content $targetFile -Raw
        if ($fileContent -match [regex]::Escape("# ── CC-SKILLS BEGIN")) {
            # Xóa section cũ
            $pattern = "(?s)# ── CC-SKILLS BEGIN.*?# ── CC-SKILLS END ──\r?\n?"
            $fileContent = [regex]::Replace($fileContent, $pattern, "")
            Set-Content -Path $targetFile -Value $fileContent -NoNewline
            Write-Host "🔄 Đã xóa section CC-SKILLS cũ." -ForegroundColor Yellow
        }
    }

    Add-Content -Path $targetFile -Value $block
    Write-Host "✅ Đã inject skills vào $targetFile" -ForegroundColor Green
}

function Verify-Setup($targetFile, $skillsList) {
    $keywords = @{
        "markitdown"           = "markitdown"
        "karpathy-guidelines"  = "Minimum code"
    }

    Write-Host ""
    Write-Host "🔍 Đang verify kết quả..."
    Write-Host ""
    $fail = $false

    # Lớp 1
    if (Test-Path $targetFile) {
        Write-Host ("✅ {0,-30} — OK" -f $targetFile) -ForegroundColor Green
    } else {
        Write-Host ("❌ {0,-30} — MISSING" -f $targetFile) -ForegroundColor Red
        exit 1
    }

    # Lớp 2
    $content = Get-Content $targetFile -Raw
    $hasBegin = $content -match [regex]::Escape("# ── CC-SKILLS BEGIN")
    $hasEnd   = $content -match [regex]::Escape("# ── CC-SKILLS END")
    if ($hasBegin -and $hasEnd) {
        Write-Host ("✅ {0,-30} — OK" -f "Marker CC-SKILLS") -ForegroundColor Green
    } else {
        Write-Host ("❌ {0,-30} — MISSING" -f "Marker CC-SKILLS") -ForegroundColor Red
        $fail = $true
    }

    # Lớp 3
    foreach ($skill in $skillsList) {
        $skill = $skill.Trim()
        $keyword = $keywords[$skill]
        if (-not $keyword) {
            Write-Host ("⚠️  {0,-30} — Không có keyword" -f "Skill: $skill") -ForegroundColor Yellow
            continue
        }
        if ($content -match [regex]::Escape($keyword)) {
            Write-Host ("✅ {0,-30} — OK" -f "Skill: $skill") -ForegroundColor Green
        } else {
            Write-Host ("❌ {0,-30} — MISSING" -f "Skill: $skill") -ForegroundColor Red
            $fail = $true
        }
    }

    if (Test-Path "$targetFile.bak") {
        Write-Host "📁 Backup lưu tại: $targetFile.bak" -ForegroundColor Cyan
    }

    Write-Host ""
    if ($fail) {
        Write-Host "⚠️  Inject có thể bị lỗi. Restore bằng lệnh:" -ForegroundColor Yellow
        Write-Host "   Copy-Item $targetFile.bak $targetFile -Force"
        exit 1
    }
    Write-Host "🚀 Chạy 'claude' để bắt đầu phiên làm việc" -ForegroundColor Cyan
}

# ── Main ──

if (-not $skills) {
    Write-Host "❌ Thiếu -skills. Ví dụ: cc-setup -skills markitdown,karpathy-guidelines" -ForegroundColor Red
    exit 1
}

$skillsList = $skills -split ","

Write-Host "🚀 cc-setup — Skills: $skills | Mode: $mode"
Write-Host ""

Check-Deps
Write-Host ""

# Detect mode
if ($mode -eq "detect") {
    $detectCode = Detect-ClaudeMd $target
    switch ($detectCode) {
        0 { $mode = "update" }
        1 { $mode = "append" }
        2 { $mode = "new" }
    }
}

Write-Host "📋 Mode: $mode"
Write-Host ""

$skillsContent = Build-SkillsContent $skillsList

switch ($mode) {
    "new" {
        Write-Host "📄 Tạo $target từ template..."
        $template = Join-Path $TemplateDir "CLAUDE.md.template"
        Copy-Item $template $target -Force
        Inject-Skills $target $skillsContent
    }
    "append" {
        Backup-ClaudeMd $target
        Inject-Skills $target $skillsContent
    }
    "update" {
        Write-Host "⚠️  $target đã có section CC-SKILLS." -ForegroundColor Yellow
        $choice = Read-Host "Chọn hành động: [u]pdate / [s]kip / [a]bort"
        switch ($choice.ToLower()) {
            { $_ -in "u","update" } {
                Backup-ClaudeMd $target
                Inject-Skills $target $skillsContent
            }
            { $_ -in "s","skip" }  { Write-Host "⏭️  Bỏ qua."; exit 0 }
            { $_ -in "a","abort" } { Write-Host "🛑 Đã hủy."; exit 1 }
            default { Write-Host "❌ Lựa chọn không hợp lệ."; exit 1 }
        }
    }
    default {
        Write-Host "❌ Mode không hợp lệ: $mode" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Verify-Setup $target $skillsList
