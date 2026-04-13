# CC-Skills Repo — Specification for Claude Code

## Tổng quan

Xây dựng một Git repo tên `cc-skills` chứa các "skills" (hướng dẫn hành vi) cho Claude Code (CC).  
Mục tiêu: đầu mỗi phiên làm việc, chạy một script để tự động inject skills vào `CLAUDE.md` của project hiện tại.

---

## Cấu trúc repo cần tạo

```
cc-skills/
│
├── README.md
├── bootstrap.sh                  ← Dùng trên máy mới (one-liner entrypoint)
├── bootstrap.ps1                 ← Tương đương cho Windows
├── setup.sh                      ← Script chính, dùng hàng ngày
├── setup.ps1                     ← Tương đương cho Windows
│
├── scripts/
│   ├── detect_claude_md.sh       ← Kiểm tra CLAUDE.md hiện tại
│   ├── append_skills.sh          ← Inject skills an toàn vào CLAUDE.md
│   ├── backup_claude_md.sh       ← Backup trước khi modify
│   ├── check_deps.sh             ← Kiểm tra git, curl... có sẵn chưa
│   └── verify_setup.sh           ← Verify kết quả sau khi inject
│
├── skills/
│   ├── markitdown/
│   │   └── SKILL.md
│   ├── karpathy-guidelines/
│   │   └── SKILL.md
│   └── README.md                 ← Hướng dẫn cách thêm skill mới
│
└── templates/
    ├── CLAUDE.md.template        ← Template cho project mới
    ├── skills_section.template   ← Template cho phần inject (có marker)
    └── .gitignore.template
```

---

## Chi tiết từng file

### `bootstrap.sh` / `bootstrap.ps1`

**Mục đích:** Dùng trên máy mới hoàn toàn, chạy bằng one-liner không cần file local.

**One-liner để chạy:**
```bash
# Linux/macOS
curl -fsSL https://raw.githubusercontent.com/<USERNAME>/cc-skills/main/bootstrap.sh | bash

# Windows PowerShell
irm https://raw.githubusercontent.com/<USERNAME>/cc-skills/main/bootstrap.ps1 | iex
```

**Logic:**
1. Gọi `check_deps.sh` — nếu thiếu dependency thì in hướng dẫn cài và exit
2. Clone repo về `~/.cc-skills/`
3. Thêm alias vào `~/.bashrc` hoặc `~/.zshrc`:
   ```bash
   alias cc-setup="~/.cc-skills/setup.sh"
   ```
4. In thông báo thành công và hướng dẫn bước tiếp theo

---

### `setup.sh` / `setup.ps1`

**Mục đích:** Script chính, dùng hàng ngày khi bắt đầu một project.

**Cú pháp:**
```bash
cc-setup --skills <skill1,skill2,...> --mode <new|append|detect>
```

**Tham số:**
- `--skills`: danh sách skills cần load, phân cách bằng dấu phẩy  
  Ví dụ: `--skills markitdown,karpathy-guidelines`
- `--mode`:
  - `new` — tạo `CLAUDE.md` từ template (dùng cho project mới tinh)
  - `append` — inject vào `CLAUDE.md` hiện có (dùng khi project đã có file)
  - `detect` *(default)* — tự động phát hiện tình huống và chọn mode phù hợp

**Logic với `--mode detect` (default):**
1. Gọi `check_deps.sh` — kiểm tra môi trường
2. Gọi `detect_claude_md.sh` để kiểm tra trạng thái file
3. Nếu không có `CLAUDE.md` → chạy như `new`
4. Nếu có `CLAUDE.md` nhưng chưa có section CC-SKILLS → chạy như `append`
5. Nếu có `CLAUDE.md` và đã có section CC-SKILLS → hỏi người dùng: update / skip / abort
6. Trước khi modify bất kỳ file nào → luôn gọi `backup_claude_md.sh` trước
7. Gọi `append_skills.sh` để inject nội dung
8. Gọi `verify_setup.sh` để kiểm tra kết quả — đây là bước cuối bắt buộc

---

### `scripts/detect_claude_md.sh`

**Mục đích:** Kiểm tra trạng thái `CLAUDE.md` trong thư mục hiện tại.

**Output (exit code):**
- `0` — không có file
- `1` — có file, chưa có section CC-SKILLS
- `2` — có file, đã có section CC-SKILLS

---

### `scripts/append_skills.sh`

**Mục đích:** Inject nội dung skills vào `CLAUDE.md` một cách an toàn.

**Logic:**
- Nếu đã có section CC-SKILLS (giữa 2 marker) → xóa section cũ, inject section mới
- Nếu chưa có → append vào cuối file

**Marker format** (bất biến, không được thay đổi):
```
# ── CC-SKILLS BEGIN (auto-generated, do not edit manually) ──
[nội dung inject]
# ── CC-SKILLS END ──
```

---

### `scripts/backup_claude_md.sh`

**Mục đích:** Backup `CLAUDE.md` trước mọi thao tác modify.

**Logic:**
- Copy `CLAUDE.md` → `CLAUDE.md.bak` (overwrite nếu đã có)
- In đường dẫn backup ra stdout

---

### `scripts/check_deps.sh`

**Mục đích:** Kiểm tra môi trường trước khi chạy bất cứ thứ gì.

**Kiểm tra:**
- `git` có sẵn không
- `curl` có sẵn không
- Kết nối internet có không (ping github.com)

**Nếu thiếu:** in thông báo rõ ràng từng thứ còn thiếu và hướng dẫn cài, sau đó exit.

---

### `scripts/verify_setup.sh`

**Mục đích:** Verify kết quả sau khi inject, đảm bảo CLAUDE.md được tạo/cập nhật đúng và đầy đủ.

**Nhận tham số:** danh sách skills đã được inject (để biết cần verify những gì).

**3 lớp kiểm tra theo thứ tự:**

**Lớp 1 — Kiểm tra file tồn tại:**
- `CLAUDE.md` có tồn tại trong thư mục hiện tại không?

**Lớp 2 — Kiểm tra marker còn nguyên:**
- Dòng `# ── CC-SKILLS BEGIN` có trong file không?
- Dòng `# ── CC-SKILLS END` có trong file không?
- Hai marker có đúng thứ tự (BEGIN trước END) không?

**Lớp 3 — Kiểm tra nội dung từng skill:**
- Với mỗi skill được chọn, tìm keyword đặc trưng trong file:
  - `markitdown` → tìm keyword `markitdown`
  - `karpathy-guidelines` → tìm keyword `Minimum code`
  - *(skill mới thêm sau cần khai báo keyword tương ứng trong skills/README.md)*

**Output khi thành công:**
```
✅ CLAUDE.md                  — OK
✅ Marker CC-SKILLS           — OK
✅ Skill: markitdown          — OK
✅ Skill: karpathy-guidelines — OK
📁 Backup lưu tại: CLAUDE.md.bak
🚀 Chạy 'claude' để bắt đầu phiên làm việc
```

**Output khi thất bại (ví dụ skill inject thiếu):**
```
✅ CLAUDE.md                  — OK
✅ Marker CC-SKILLS           — OK
❌ Skill: markitdown          — MISSING
⚠️  Inject có thể bị lỗi. Kiểm tra CLAUDE.md.bak để restore.
```

**Nếu có bất kỳ lớp nào fail:** in cảnh báo rõ ràng, hướng dẫn cách restore từ backup, exit với code khác 0.

---

### `skills/markitdown/SKILL.md`

**Mục đích:** Hướng dẫn CC cách sử dụng thư viện `markitdown` của Microsoft.

**Nội dung cần có:**
- Khi nào nên dùng markitdown (convert file sang Markdown để đưa vào LLM)
- Cài đặt: `pip install 'markitdown[all]'`
- Cách dùng cơ bản (4 dòng code)
- Các format được hỗ trợ: PDF, DOCX, PPTX, XLSX, HTML, hình ảnh, audio
- Lưu ý: output phục vụ LLM, không phải cho người đọc trực tiếp
- Tích hợp MCP server nếu cần dùng với Claude Desktop

**Keyword đặc trưng để verify:** `markitdown`

---

### `skills/karpathy-guidelines/SKILL.md`

**Mục đích:** Bộ behavioral rules cho CC, tránh các lỗi phổ biến của LLM khi coding.

**Nội dung cần có (4 nguyên tắc):**

1. **Không giả định** — nếu không chắc, hỏi. Nếu có nhiều cách hiểu, liệt kê ra, không tự chọn im lặng.
2. **Minimum code** — chỉ viết đúng những gì được yêu cầu. Không thêm abstraction, flexibility, hay feature không ai hỏi. Nếu 50 dòng đủ thì không viết 200 dòng.
3. **Goal-driven execution** — ưu tiên nhận *tiêu chí thành công* thay vì danh sách bước làm. Tự verify kết quả.
4. **Không tự ý sửa code ngoài phạm vi** — không xóa comment, không refactor code không liên quan đến task hiện tại.

**Keyword đặc trưng để verify:** `Minimum code`

---

### `templates/CLAUDE.md.template`

**Mục đích:** Template gốc cho project mới, có placeholder để script inject vào.

**Cấu trúc:**
```markdown
# CLAUDE.md — [Project Name]

## Project Context
[Mô tả project — điền thủ công]

## Tech Stack
[Điền thủ công]

# ── CC-SKILLS BEGIN (auto-generated, do not edit manually) ──
{{SKILLS_CONTENT}}
# ── CC-SKILLS END ──
```

---

### `templates/skills_section.template`

**Mục đích:** Template cho phần inject khi append vào file có sẵn (dùng trong `append_skills.sh`).

**Nội dung:**
```
# ── CC-SKILLS BEGIN (auto-generated, do not edit manually) ──
{{SKILLS_CONTENT}}
# ── CC-SKILLS END ──
```

---

### `templates/.gitignore.template`

**Mục đích:** Template `.gitignore` gợi ý cho project.

**Nội dung đáng chú ý:**
```
CLAUDE.md.bak
# Bỏ comment dòng dưới nếu không muốn commit CLAUDE.md vào repo project
# CLAUDE.md
```

---

### `skills/README.md`

**Mục đích:** Hướng dẫn cách tạo skill mới để mở rộng repo sau này.

**Nội dung:**
- Cấu trúc một SKILL.md chuẩn
- Cách đặt tên thư mục skill (dùng kebab-case)
- Cách khai báo keyword đặc trưng để `verify_setup.sh` có thể kiểm tra
- Cách gọi skill mới trong `setup.sh`
- Ví dụ mẫu

---

### `README.md` (root)

**Mục đích:** Tài liệu tổng quan cho toàn bộ repo.

**Nội dung:**
- Mục đích repo
- Quick start (máy mới + máy đã có)
- Danh sách skills hiện có
- Cách đóng góp skill mới

---

## Luồng hoạt động đầy đủ

### Máy mới (lần đầu tiên)
```
1. Chạy one-liner bootstrap
2. bootstrap.sh clone repo về ~/.cc-skills/
3. Alias cc-setup được thêm vào shell
4. Từ đây dùng cc-setup bình thường
```

### Hàng ngày — Project mới tinh
```
mkdir my-project && cd my-project
git init
cc-setup --skills markitdown,karpathy-guidelines
    → check_deps.sh
    → detect: không có CLAUDE.md → mode new
    → backup_claude_md.sh        (bỏ qua vì chưa có file)
    → tạo CLAUDE.md từ template + inject skills
    → verify_setup.sh            ← kiểm tra 3 lớp
    → in summary
→ Bắt đầu claude
```

### Hàng ngày — Project có sẵn, chưa có CLAUDE.md
```
cd existing-project
cc-setup --skills markitdown,karpathy-guidelines
    → check_deps.sh
    → detect: không có CLAUDE.md → mode new
    → tạo CLAUDE.md từ template + inject skills
    → verify_setup.sh            ← kiểm tra 3 lớp
    → in summary
→ Bắt đầu claude
```

### Hàng ngày — Project có sẵn, đã có CLAUDE.md (chưa có CC-SKILLS)
```
cd existing-project
cc-setup --skills markitdown,karpathy-guidelines
    → check_deps.sh
    → detect: có CLAUDE.md, chưa có CC-SKILLS → mode append
    → backup_claude_md.sh        → CLAUDE.md.bak
    → append_skills.sh           → inject section CC-SKILLS vào cuối
    → verify_setup.sh            ← kiểm tra 3 lớp
    → in summary
→ Bắt đầu claude
```

### Hàng ngày — Project đã có CC-SKILLS cũ (update)
```
cd existing-project
cc-setup --skills markitdown,karpathy-guidelines
    → check_deps.sh
    → detect: có CLAUDE.md, đã có CC-SKILLS
    → hỏi người dùng: [u]pdate / [s]kip / [a]bort
    → (nếu chọn update)
    → backup_claude_md.sh        → CLAUDE.md.bak
    → append_skills.sh           → xóa section cũ, inject section mới
    → verify_setup.sh            ← kiểm tra 3 lớp
    → in summary
→ Bắt đầu claude
```

---

## Yêu cầu kỹ thuật

- Shell script tương thích bash 3.2+ (macOS default) và bash 5+ (Linux)
- PowerShell script tương thích PS 5.1+ (Windows built-in) và PS 7+
- Không dùng dependency ngoài `git` và `curl`
- Mọi thao tác ghi file đều phải backup trước
- Script phải idempotent: chạy nhiều lần không gây lỗi hay duplicate
- `verify_setup.sh` phải được gọi như bước cuối bắt buộc trong mọi luồng có modify file
- Nếu `verify_setup.sh` fail → exit code khác 0, in hướng dẫn restore rõ ràng

---

## Ghi chú

- `<USERNAME>` trong one-liner cần được thay bằng GitHub username thực tế sau khi tạo repo
- Skills có thể mở rộng thêm sau: ví dụ `px4-guidelines`, `vietnamese-docs`, `uav-conventions`, `cpp-mfc-patterns`
- Mỗi skill là một thư mục độc lập, không phụ thuộc lẫn nhau
- Mỗi skill mới thêm **bắt buộc** khai báo keyword đặc trưng trong `skills/README.md` để `verify_setup.sh` biết cách kiểm tra