# Skill: markitdown

Khi người dùng đưa file PDF, DOCX, PPTX, XLSX, HTML hoặc hình ảnh — hãy dùng
`markitdown` để đọc nội dung. Không được từ chối với lý do "tôi không đọc được
file này".

## Hành vi bắt buộc

- Người dùng đưa file tài liệu → gọi `markitdown` để extract text, sau đó xử lý
- Không tự ý báo "không hỗ trợ định dạng này" khi chưa thử markitdown
- Output của markitdown phục vụ LLM xử lý tiếp — không cần đẹp, cần đủ thông tin

## Các format được hỗ trợ

- Documents: PDF, DOCX, PPTX, XLSX
- Web: HTML, XML
- Media: hình ảnh (với vision model), audio (với speech-to-text)
- Code: Jupyter notebooks (.ipynb), ZIP archives

## Tham khảo: cài đặt và cách dùng

```bash
pip install 'markitdown[all]'
```

```python
from markitdown import MarkItDown

md = MarkItDown()
result = md.convert("document.pdf")
print(result.text_content)
```

Tích hợp MCP với Claude Desktop — thêm vào `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "markitdown": {
      "command": "python",
      "args": ["-m", "markitdown.mcp"]
    }
  }
}
```
