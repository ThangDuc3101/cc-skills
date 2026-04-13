# Skill: markitdown

## Khi nào nên dùng

Dùng `markitdown` khi cần convert file sang Markdown để đưa vào LLM:
- Đọc nội dung từ PDF, DOCX, PPTX, XLSX, HTML để xử lý bằng AI
- Chuẩn bị dữ liệu cho RAG pipeline
- Trích xuất text từ hình ảnh hoặc audio để phân tích

Output phục vụ LLM, không phải cho người đọc trực tiếp — không cần đẹp, cần đầy đủ thông tin.

## Cài đặt

```bash
pip install 'markitdown[all]'
```

## Cách dùng cơ bản

```python
from markitdown import MarkItDown

md = MarkItDown()
result = md.convert("document.pdf")
print(result.text_content)
```

## Các format được hỗ trợ

- Documents: PDF, DOCX, PPTX, XLSX
- Web: HTML, XML
- Media: hình ảnh (với vision model), audio (với speech-to-text)
- Code: Jupyter notebooks (.ipynb), ZIP archives

## Tích hợp MCP server

Dùng với Claude Desktop qua MCP:

```bash
pip install 'markitdown[all]'
```

Thêm vào `claude_desktop_config.json`:
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
