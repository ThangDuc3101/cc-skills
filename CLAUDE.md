## Project

cc-skills là skill injection framework — mỗi `SKILL.md` được inject vào `CLAUDE.md` của project để định hướng hành vi của Claude Code. Mục tiêu: agent làm đúng pattern ngay từ đầu mà không cần hướng dẫn lại mỗi session.

## Nguyên tắc cốt lõi khi viết/sửa SKILL.md

Viết skill như **instruction cho LLM**, không phải documentation cho người đọc:

- Dùng imperative voice, 2nd person: "ĐỌC file trước khi sửa" thay vì "Claude should read the file"
- Rõ trigger → action: khi nào làm gì, dùng tool nào, hỏi câu gì
- Thêm ví dụ ❌/✅ cho behavioral rules để LLM nhận pattern

## Invariants

- **Không thêm heading `# Skill: ten-skill`** ở đầu SKILL.md — inject script tự thêm `## Skill: ten-skill` khi build
- **Keyword trong `verify_setup.sh`** phải là chuỗi duy nhất trong SKILL.md đó, không xuất hiện trong skill khác
- **Dependency declaration** — skill phụ thuộc skill khác phải khai báo `## Yêu cầu` ở đầu SKILL.md

## Cấu trúc file quan trọng

```
skills/<ten-skill>/SKILL.md    ← nội dung skill (instruction cho LLM)
skills/README.md               ← bảng skills + dependencies (dành cho developer)
scripts/verify_setup.sh        ← keyword để verify injection thành công
setup.sh / setup.ps1           ← script inject skills vào CLAUDE.md
bootstrap.sh / bootstrap.ps1   ← one-liner cho máy mới
```

## Khi thêm skill mới

1. Tạo `skills/<ten-skill>/SKILL.md` — viết theo imperative voice
2. Thêm keyword vào `scripts/verify_setup.sh`
3. Cập nhật bảng trong `skills/README.md` (gồm cột Dependencies)
4. Nếu skill phụ thuộc skill khác — thêm `## Yêu cầu` ở đầu SKILL.md

## Khi sửa SKILL.md hiện có

Đọc file trước, xác định đúng phần cần sửa, không refactor ngoài scope. Nếu chuyển giọng văn sang imperative, giữ nguyên số lượng rules/steps — chỉ thay đổi cách diễn đạt.
