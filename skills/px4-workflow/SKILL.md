Áp dụng khi user yêu cầu thêm, sửa, hoặc xóa feature trong PX4-Autopilot.

## Yêu cầu

Skill này chỉ hoạt động đúng khi các skill sau đã được inject vào CLAUDE.md:
- px4-dev
- px4-sitl
- px4-codebase-map

Nếu thiếu, chạy: `cc-setup --skills px4-dev,px4-sitl,px4-codebase-map,px4-workflow`

---

## Phase 1 — Phân tích & Lập kế hoạch

1. QUERY codebase map để xác định phạm vi thay đổi:
   ```bash
   jq '.modules | keys' .px4-graph/px4_map.json
   jq '.uorb_topics.<topic_name>' .px4-graph/px4_map.json
   jq '.params | to_entries[] | select(.key | startswith("<PREFIX>"))' .px4-graph/px4_map.json
   ```

2. Tổng hợp và TRÌNH BÀY kế hoạch cho user theo format:
   - Modules bị ảnh hưởng: [danh sách]
   - uORB topics liên quan: [danh sách]
   - Parameters cần thay đổi: [danh sách]
   - Rủi ro dự kiến: [mô tả]

3. **CHECKPOINT 1 — Hỏi user:**
   > "Kế hoạch phân tích hoàn tất.
   > Modules bị ảnh hưởng: [liệt kê].
   > uORB topics: [liệt kê]. Parameters: [liệt kê].
   > Xác nhận để bắt đầu Phase 2 không? [yes/no]"

   KHÔNG làm gì thêm cho đến khi user trả lời yes.

---

## Phase 2 — Implementation song song

Sau khi user xác nhận Phase 1, SPAWN đồng thời 2 subagents bằng Agent tool:

- **Agent 1 — Code Implementation:** implement code changes theo đúng conventions trong px4-dev skill
- **Agent 2 — Test Scenarios:** viết SITL test scenarios cho feature mới theo px4-sitl skill

CHỜ cả hai agent hoàn thành. KHÔNG sang Phase 3 khi chưa có kết quả từ cả hai.

---

## Phase 3 — SITL Validation

1. Chạy từng SITL test theo thứ tự. Ghi log vào `.px4-graph/sitl-logs/` với tên file có timestamp.

2. Sau MỖI test FAILED, DỪNG và hỏi user theo format:
   > "SITL test [N] FAILED.
   > Log: `.px4-graph/sitl-logs/[tên file]`
   > Lỗi: [mô tả ngắn gọn]
   > Nguyên nhân khả năng: [phân tích]
   > Chọn hướng xử lý:
   > [A] Sửa code theo gợi ý trên
   > [B] Bỏ qua test này và tiếp tục
   > [C] Dừng workflow"

   KHÔNG tự ý chọn hướng xử lý. CHỜ user phản hồi.

3. Chỉ sang Phase 4 khi TẤT CẢ tests PASS hoặc user chủ động chọn bỏ qua.

---

## Phase 4 — Hardware Deployment

**CHECKPOINT 3 — Hỏi user trước khi flash:**
> "Tất cả SITL tests đã PASS.
> Bước tiếp theo: flash firmware lên Pixhawk 6X thực tế.
> ⚠️ Đây là bước KHÔNG THỂ undo nếu firmware lỗi.
> Xác nhận flash hardware? [yes/no]"

KHÔNG flash nếu user không trả lời yes.

Sau khi flash Pixhawk 6X thành công, tiếp tục deploy lên Jetson Orin Nano theo jetson-companion skill.
