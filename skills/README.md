# Skills — Hướng dẫn thêm skill mới

## Cấu trúc một skill

Mỗi skill là một thư mục độc lập trong `skills/`:

```
skills/
└── ten-skill/          ← tên dùng kebab-case
    └── SKILL.md        ← nội dung skill
```

## Cấu trúc SKILL.md chuẩn

```markdown
# Skill: ten-skill

## Mục đích / Khi nào dùng
[Mô tả ngắn]

## Nội dung chính
[Hướng dẫn, rules, ví dụ...]
```

## Đặt tên thư mục

- Dùng **kebab-case**: `my-new-skill`, `px4-guidelines`, `cpp-mfc-patterns`
- Không dùng dấu cách, không dùng camelCase

## Khai báo keyword để verify

Sau khi tạo skill, thêm keyword đặc trưng vào `scripts/verify_setup.sh` trong mảng `SKILL_KEYWORDS`:

```bash
declare -A SKILL_KEYWORDS=(
    ["markitdown"]="markitdown"
    ["karpathy-guidelines"]="Minimum code"
    ["ten-skill-moi"]="từ khóa đặc trưng"   # ← thêm dòng này
)
```

Keyword phải là một chuỗi **duy nhất** xuất hiện trong SKILL.md của skill đó, không xuất hiện trong các skill khác.

## Cách gọi skill mới trong setup.sh

```bash
cc-setup --skills markitdown,ten-skill-moi
```

## Ví dụ

Thêm skill `vietnamese-docs`:

1. Tạo thư mục: `skills/vietnamese-docs/`
2. Viết nội dung: `skills/vietnamese-docs/SKILL.md`
3. Thêm vào `verify_setup.sh`: `["vietnamese-docs"]="Viết tài liệu bằng tiếng Việt"`
4. Chạy: `cc-setup --skills vietnamese-docs`

## Skills hiện có

| Skill | Mô tả | Keyword |
|-------|-------|---------|
| `markitdown` | Convert file sang Markdown cho LLM | `markitdown` |
| `karpathy-guidelines` | Behavioral rules tránh lỗi LLM khi coding | `Minimum code` |
