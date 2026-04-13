# cc-skills

Repo chứa các "skills" (hướng dẫn hành vi) cho Claude Code.  
Đầu mỗi phiên làm việc, chạy một lệnh để tự động inject skills vào `CLAUDE.md` của project hiện tại.

## Mục đích

- Standardize behavior của Claude Code qua các project
- Không cần copy-paste tay vào CLAUDE.md mỗi lần
- Dễ mở rộng: thêm skill mới là thêm một thư mục

## Quick start

### Máy mới (lần đầu tiên)

**Linux/macOS:**
```bash
curl -fsSL https://raw.githubusercontent.com/ThangDuc3101/cc-skills/main/bootstrap.sh | bash
source ~/.zshrc   # hoặc ~/.bashrc
```

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/ThangDuc3101/cc-skills/main/bootstrap.ps1 | iex
. $PROFILE
```

### Hàng ngày

```bash
cd /path/to/your-project
cc-setup --skills markitdown,karpathy-guidelines
```

### Máy đã có repo (không cần bootstrap lại)

```bash
# Clone thủ công
git clone https://github.com/ThangDuc3101/cc-skills.git ~/.cc-skills

# Thêm alias
echo 'alias cc-setup="$HOME/.cc-skills/setup.sh"' >> ~/.zshrc
source ~/.zshrc
```

## Tham số

```bash
cc-setup --skills <skill1,skill2,...> [--mode <new|append|detect>]
```

| Tham số | Mô tả |
|---------|-------|
| `--skills` | Danh sách skills, phân cách bằng dấu phẩy |
| `--mode new` | Tạo CLAUDE.md từ template (project mới tinh) |
| `--mode append` | Inject vào CLAUDE.md có sẵn |
| `--mode detect` | Tự động phát hiện — **mặc định** |

## Skills hiện có

| Skill | Mô tả |
|-------|-------|
| `markitdown` | Khi người dùng đưa file PDF/DOCX/PPTX/XLSX, dùng markitdown để đọc — không từ chối |
| `karpathy-guidelines` | Behavioral rules tránh các lỗi phổ biến của LLM khi coding |

## Thêm skill mới

Xem hướng dẫn chi tiết tại [skills/README.md](skills/README.md).

Tóm tắt:
1. Tạo thư mục `skills/<ten-skill>/`
2. Viết `skills/<ten-skill>/SKILL.md`
3. Thêm keyword vào `scripts/verify_setup.sh`

## Cấu trúc repo

```
cc-skills/
├── bootstrap.sh / bootstrap.ps1   ← One-liner cho máy mới
├── setup.sh / setup.ps1           ← Script chính dùng hàng ngày
├── scripts/
│   ├── check_deps.sh
│   ├── detect_claude_md.sh
│   ├── backup_claude_md.sh
│   ├── append_skills.sh
│   └── verify_setup.sh
├── skills/
│   ├── markitdown/SKILL.md
│   ├── karpathy-guidelines/SKILL.md
│   └── README.md
└── templates/
    ├── CLAUDE.md.template
    ├── skills_section.template
    └── .gitignore.template
```

## Đóng góp

Tạo PR với skill mới. Yêu cầu: thư mục kebab-case, có SKILL.md, có keyword trong verify_setup.sh.
