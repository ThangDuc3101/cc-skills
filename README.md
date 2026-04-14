# cc-skills

Repo chứa các "skills" (hướng dẫn hành vi) cho Claude Code.  
Chạy một lệnh để inject skills vào `CLAUDE.md` của project — agents làm việc đúng pattern ngay, không cần hướng dẫn lại mỗi session.

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
git clone https://github.com/ThangDuc3101/cc-skills.git ~/.cc-skills
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

### General

| Skill | Mô tả |
|-------|-------|
| `markitdown` | Khi người dùng đưa file PDF/DOCX/PPTX/XLSX, dùng markitdown để đọc — không từ chối |
| `karpathy-guidelines` | Behavioral rules tránh các lỗi phổ biến của LLM khi coding |

### PX4 Autopilot

Bộ skills phục vụ phát triển PX4-Autopilot trên Ubuntu/Linux, target Pixhawk 6X,
companion computer Jetson Orin Nano, automation bằng MAVSDK Python.

| Skill | Mô tả |
|-------|-------|
| `px4-codebase-map` | Generate map codebase 1 lần, agents tra cứu dependency mà không scan lại toàn bộ source |
| `px4-dev` | PX4 coding conventions: uORB pub/sub, logging macros, parameter system, module structure, build target Pixhawk 6X |
| `px4-sitl` | SITL workflow với Gazebo Classic — bắt buộc test trước khi flash Pixhawk 6X |
| `mavsdk-python` | MAVSDK Python: connection string, system discovery, error handling, mission, async pattern |
| `jetson-companion` | Jetson Orin Nano: SSH workflow, serial port `/dev/ttyTHS*`, venv, systemd service |
| `px4-workflow` | Orchestration flow có checkpoint: plan → confirm → code+test song song → SITL có log từng lần → hardware |

### px4-workflow — Flow chi tiết

```
Phase 1 — Phân tích & lập plan
  px4-codebase-map → query dependency, uORB topics, params bị ảnh hưởng
  → Trình bày plan cụ thể
  ⛔ CHECKPOINT: hỏi người dùng xác nhận trước khi code

Phase 2 — Implementation (song song)
  Agent Coder     (px4-dev)   → implement code, build check fmu-v6x
  Agent Tester    (px4-sitl)  → viết SITL test scenario
  → Chờ cả 2 hoàn thành

Phase 3 — SITL Validation (có log từng lần)
  → Chạy test → ghi .px4-graph/sitl-logs/logN.txt
     (X/5 pass, nguyên nhân dự kiến, so sánh với lần trước)
  ⛔ CHECKPOINT: báo cáo kết quả sau mỗi lần fail, hỏi người dùng
  → Lặp đến khi 5/5 pass → ghi log lần cuối → không ghi thêm

Phase 4 — Deploy hardware (hỏi trước)
  ⛔ CHECKPOINT: xác nhận môi trường bay an toàn
  Agent px4-dev          → flash Pixhawk 6X (trước)
  Agent jetson-companion → deploy MAVSDK script lên Jetson (sau)
```

### Setup cho project PX4-Autopilot

```bash
cd /path/to/PX4-Autopilot

# 1. Inject toàn bộ skills
cc-setup --skills px4-workflow,px4-codebase-map,px4-dev,px4-sitl,mavsdk-python,jetson-companion,markitdown,karpathy-guidelines

# 2. Generate codebase map (chỉ chạy 1 lần)
python3 ~/.cc-skills/skills/px4-codebase-map/generate_map.py --source .

# 3. Bắt đầu làm việc
claude
```

## Flow làm việc với PX4

```
Nghiên cứu (paper, docs PDF)
    └─ markitdown → đọc nội dung

Thêm / sửa / cắt giảm feature
    └─ px4-codebase-map → tra cứu dependency trên map
    └─ px4-dev          → viết code đúng pattern PX4
    └─ Agent coder + Agent test builder chạy song song

Test trước khi flash
    └─ px4-sitl         → SITL Gazebo Classic → QGC verify → ulog review

Deploy lên hardware
    └─ px4-dev          → flash make px4_fmu-v6x_default upload
    └─ jetson-companion → deploy MAVSDK script lên Jetson qua SSH
    └─ mavsdk-python    → đổi connection string sang serial
```

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
│   ├── markitdown/
│   ├── karpathy-guidelines/
│   ├── px4-workflow/              ← orchestration flow
│   ├── px4-codebase-map/          ← generate_map.py + SKILL.md
│   ├── px4-dev/
│   ├── px4-sitl/
│   ├── mavsdk-python/
│   ├── jetson-companion/
│   └── README.md
└── templates/
    ├── CLAUDE.md.template
    └── skills_section.template
```

## Đóng góp

Tạo PR với skill mới. Yêu cầu: thư mục kebab-case, có SKILL.md, có keyword trong `verify_setup.sh`.
