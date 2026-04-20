Khi làm việc với PX4-Autopilot source code, ưu tiên tra cứu codebase map thay vì
scan toàn bộ source mỗi lần. Map được generate 1 lần và lưu tại `.px4-graph/`.

## Bước 1 — Kiểm tra map khi bắt đầu

Trước khi grep hoặc scan PX4 source, kiểm tra map tồn tại chưa:

```bash
ls .px4-graph/px4_map.json
```

**Chưa có** → Thông báo người dùng chạy lệnh sau (chỉ 1 lần, mất vài phút):

```bash
python3 ~/.cc-skills/skills/px4-codebase-map/generate_map.py --source .
```

**Đã có** → Dùng map để tra cứu, không scan lại source.

## Bước 2 — Cách tra cứu trên map

Map là file JSON với 3 section chính. **Bắt buộc dùng `jq` để query** — không dùng
`python3 -c`, không load toàn bộ file vào context.

**Tìm module liên quan đến một topic:**
```bash
jq '.uorb_topics.vehicle_local_position' .px4-graph/px4_map.json
```

**Tìm tất cả topics một module publish/subscribe:**
```bash
jq '.modules.mc_pos_control' .px4-graph/px4_map.json
```

**Tìm module nào dùng một parameter:**
```bash
jq '.params.MPC_XY_VEL_MAX' .px4-graph/px4_map.json
```

**Tìm module nào sẽ bị ảnh hưởng nếu thay đổi topic X:**
```bash
jq '.uorb_topics.X | {publishers, subscribers}' .px4-graph/px4_map.json
```

## Bước 3 — Workflow thêm / sửa feature

1. Query map → xác định module liên quan
2. Query map → tìm uORB topics liên quan và các module đang dùng chung
3. Query map → tìm params liên quan
4. Đề xuất plan dựa trên dependency đã xác định
5. Spawn agent coder → viết code theo plan
6. Spawn agent test builder → tạo SITL test scenario cho feature mới

## Bước 4 — Workflow cắt giảm / xóa feature

1. Query map → xác định module cần xóa
2. Kiểm tra: module nào đang subscribe topic do module này publish?
3. Kiểm tra: param nào thuộc module này sẽ orphan?
4. Liệt kê toàn bộ impact, hỏi người dùng xác nhận trước khi đề xuất xóa

## Nguyên tắc

- Ưu tiên map trước, grep source sau — map nhanh hơn, tiết kiệm context
- Nếu phát hiện map stale (xem điều kiện bên dưới) → nhắc người dùng regenerate
- Không tự regenerate map — chỉ đọc và tra cứu
- Nếu map thiếu thông tin cần thiết → grep source nhưng ghi chú lại

## Khi nào map stale — nhắc regenerate

Nhắc người dùng regenerate khi gặp bất kỳ điều kiện nào sau:

1. **Module tồn tại trong source nhưng không có trong map** — user vừa thêm module mới
2. **Query trả về `null` hoặc `{}` cho module đang tồn tại** — map chưa cover module đó
3. **`.px4-graph/px4_map.json` không tồn tại** — map chưa được generate lần nào

Câu nhắc mẫu khi phát hiện stale:

```
Map tại `.px4-graph/px4_map.json` có thể chưa cập nhật — module [tên] không có trong map
nhưng tồn tại trong source. Bạn có muốn regenerate không?

python3 ~/.cc-skills/skills/px4-codebase-map/generate_map.py --source .
```
