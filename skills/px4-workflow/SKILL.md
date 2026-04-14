Orchestration flow cho mọi tác vụ thêm, sửa, hoặc cắt giảm feature trong
PX4-Autopilot. Skill này định nghĩa thứ tự các bước và các checkpoint bắt buộc
phải hỏi người dùng trước khi tiếp tục.

## Khi nào áp dụng

Áp dụng skill này khi người dùng yêu cầu:
- Thêm feature mới vào PX4
- Sửa / điều chỉnh feature có sẵn
- Cắt giảm hoặc xóa feature / module

---

## Phase 1 — Phân tích và lập plan

### 1.1 Query codebase map

Mở `.px4-graph/px4_map.json` và tra cứu:

```bash
# Tìm module liên quan đến feature
jq '.modules | to_entries[] | select(.value.path | contains("keyword"))' .px4-graph/px4_map.json

# Tìm uORB topics liên quan
jq '.uorb_topics.TOPIC_NAME' .px4-graph/px4_map.json

# Tìm ai sẽ bị ảnh hưởng nếu thay đổi topic
jq '.uorb_topics | to_entries[] | select(.value.subscribers | contains(["MODULE"]))' .px4-graph/px4_map.json

# Tìm params liên quan
jq '.params | to_entries[] | select(.key | startswith("PREFIX"))' .px4-graph/px4_map.json
```

Nếu `.px4-graph/px4_map.json` chưa tồn tại → dừng lại, nhắc người dùng generate map trước:
```bash
python3 ~/.cc-skills/skills/px4-codebase-map/generate_map.py --source .
```

### 1.2 Đọc source các module liên quan

Sau khi xác định module từ map, đọc các file liên quan để hiểu implementation hiện tại.
Không đề xuất thay đổi khi chưa đọc code.

### 1.3 Trình bày plan — DỪNG VÀ HỎI NGƯỜI DÙNG

Trình bày plan theo cấu trúc sau, sau đó **dừng lại chờ xác nhận**:

```
## Plan: [tên feature]

**Modules cần thay đổi:**
- module_a: [mô tả thay đổi cụ thể]
- module_b: [mô tả thay đổi cụ thể]

**uORB topics bị ảnh hưởng:**
- topic_x: [publisher thay đổi / subscriber cần update]

**Parameters cần thêm/sửa/xóa:**
- PARAM_NAME: [mô tả]

**Modules khác có thể bị ảnh hưởng (cần verify):**
- module_c: subscribe topic_x — cần kiểm tra compatibility

**Rủi ro:**
- [liệt kê nếu có]

Bạn có muốn tiến hành không?
```

**KHÔNG implement bất cứ thứ gì trước khi người dùng xác nhận.**

---

## Phase 2 — Implementation (sau khi người dùng đồng ý)

Spawn 2 agents chạy **song song**:

**Agent 1 — Coder** (dùng skill `px4-dev`):
- Implement code changes theo plan đã được duyệt
- Tuân thủ PX4 conventions: uORB, logging, params, module structure
- Build check: `make px4_fmu-v6x_default` phải pass không có error

**Agent 2 — Test Builder** (dùng skill `px4-sitl`):
- Viết SITL test scenario cho feature mới
- Định nghĩa: điều kiện khởi động, các bước test, tiêu chí pass/fail
- Chuẩn bị MAVSDK script test nếu cần

Chờ **cả 2 agents hoàn thành** trước khi chuyển sang Phase 3.

---

## Phase 3 — SITL Validation (có báo cáo từng lần)

Thư mục log: `.px4-graph/sitl-logs/` — tạo nếu chưa có.
Mỗi lần chạy test được đánh số tăng dần: `log1.txt`, `log2.txt`, ...

### 3.1 Chạy SITL

```bash
make px4_sitl gazebo
```

### 3.2 Chạy test scenario

Thực thi test scenario từ Agent 2. Kết nối MAVSDK nếu cần:
```bash
# SITL connection
udp://:14540
```

### 3.3 Ghi log sau mỗi lần chạy

Sau khi kết thúc mỗi lần test, ghi file log theo template:

```
# SITL Test — Lần [N]
Thời gian: [timestamp]

## Kết quả
Pass: X/5
Fail: Y/5

## Chi tiết từng test case
- [test 1]: PASS / FAIL — [mô tả ngắn]
- [test 2]: PASS / FAIL — [mô tả ngắn]
...

## Nguyên nhân dự kiến (nếu có fail)
- [phân tích cụ thể từ console output / ulog]

## So với lần trước (từ lần 2 trở đi)
- Đã sửa: [liệt kê thay đổi so với lần N-1]
- Nguyên nhân đã thu hẹp được: [còn lại những gì chưa rõ]

## Hướng xử lý tiếp theo (nếu chưa pass hết)
- [đề xuất cụ thể]
```

### 3.4 Sau mỗi lần fail — DỪNG VÀ HỎI NGƯỜI DÙNG

Sau khi ghi log, thông báo tóm tắt và hỏi:

```
Lần [N]: [X/5 pass]. Log ghi tại .px4-graph/sitl-logs/log[N].txt

Nguyên nhân dự kiến: [tóm tắt 1-2 dòng]
Hướng xử lý đề xuất: [tóm tắt 1-2 dòng]

Bạn có chỉ đạo gì thêm không, hay để tiếp tục sửa và test lại?
```

**Chờ phản hồi của người dùng.** Nếu người dùng có chỉ đạo mới → ưu tiên theo chỉ đạo đó.
Nếu người dùng nói "tiếp tục" → Agent Coder fix theo hướng đề xuất → chạy lại test → ghi log tiếp.

### 3.5 Khi tất cả test pass (5/5)

Ghi log lần cuối:

```
# SITL Test — Lần [N] — HOÀN THÀNH
Thời gian: [timestamp]

## Kết quả
Pass: 5/5 — TẤT CẢ PASS

## Tóm tắt quá trình
- Tổng số lần chạy: [N]
- Vấn đề đã giải quyết: [liệt kê]
```

Không ghi thêm log nào sau đây. Chuyển sang Phase 4.

---

## Phase 4 — Deploy lên hardware thật

### 4.1 DỪNG VÀ HỎI NGƯỜI DÙNG

Sau khi SITL pass, hỏi:

```
SITL đã pass. Bạn có muốn thử trên Pixhawk 6X và Jetson Orin Nano thật không?
Lưu ý: đảm bảo môi trường bay an toàn trước khi thử.
```

**KHÔNG tiến hành nếu người dùng chưa xác nhận.**

### 4.2 Flash Pixhawk 6X — chạy TRƯỚC (Agent px4-dev)

```bash
make px4_fmu-v6x_default upload
```

Chờ flash hoàn tất và Pixhawk reboot thành công. Verify QGC kết nối được.

### 4.3 Deploy lên Jetson — chạy SAU (Agent jetson-companion)

Chỉ chạy sau khi Pixhawk 6X đã flash xong và verify OK:

```bash
# SSH vào Jetson
ssh user@jetson-ip

# Deploy MAVSDK script
rsync -av ./drone-scripts/ user@jetson-ip:~/drone-scripts/

# Đổi connection string sang serial
serial:///dev/ttyTHS1:57600

# Restart service
sudo systemctl restart drone-controller

# Verify
journalctl -u drone-controller -f
```

---

## Quy tắc tổng quát

- **3 checkpoint bắt buộc hỏi người dùng**: sau Phase 1 (plan), sau mỗi lần fail Phase 3, trước Phase 4 (hardware)
- **Không skip SITL**: dù thay đổi nhỏ đến đâu cũng phải qua SITL trước
- **Log mỗi lần test**: luôn ghi `.px4-graph/sitl-logs/log[N].txt` dù pass hay fail
- **Không tự loop kín Phase 3**: mỗi lần fail phải báo cáo và chờ phản hồi người dùng
- **Thứ tự Phase 4 không đổi**: px4-dev flash trước, jetson-companion sau
- **Nếu hardware fail**: quay lại Phase 3, không tự ý sửa code trên hardware
