Quy trình test bắt buộc trên SITL (Software In The Loop) với Gazebo Classic
trước khi flash lên Pixhawk 6X. Không đề xuất flash hardware khi chưa qua SITL.

## 1. Build và chạy SITL

```bash
# Build SITL với Gazebo Classic (quadrotor mặc định)
make px4_sitl gazebo

# Các vehicle thường dùng
make px4_sitl gazebo_iris          # quadrotor iris
make px4_sitl gazebo_typhoon_h480  # hexarotor với camera
make px4_sitl gazebo_plane         # fixed-wing

# Chạy headless (không GUI, dùng khi chỉ cần test logic)
HEADLESS=1 make px4_sitl gazebo
```

## 2. Kết nối công cụ vào SITL

| Công cụ | Kết nối |
|---------|---------|
| QGroundControl | Tự động detect UDP 14550 |
| MAVSDK Python | `udp://:14540` |
| MAVProxy | `--master udp:127.0.0.1:14540` |

## 3. Quy trình test bắt buộc

Mỗi lần sửa code, phải đi qua đủ các bước sau theo thứ tự:

1. **Build SITL thành công** — không có compile error hay warning nghiêm trọng
2. **QGC kết nối được** — vehicle xuất hiện trên map, không có error message
3. **Arm và takeoff cơ bản** — vehicle bay lên được, không crash ngay
4. **Test feature cụ thể** — verify đúng behavior của feature vừa thay đổi
5. **Kiểm tra log** — download ulog, xem không có unexpected error

```bash
# Download ulog sau khi test
# Trong QGC: Analyze Tools → Log Download
# Hoặc dùng script
python3 Tools/upload_log.py
```

## 4. Xem output và debug

```bash
# Trong PX4 shell (khi SITL đang chạy)
listener vehicle_local_position     # xem topic realtime
listener vehicle_status
param show MPC_XY_VEL_MAX           # kiểm tra param

# Module log
dmesg
```

## 5. Kết nối MAVSDK Python vào SITL

```python
# Connection string cho SITL
system = System()
await system.connect(system_address="udp://:14540")
```

Khác với hardware (serial) — phải đổi connection string khi chuyển sang Pixhawk 6X thật.

## 6. Giới hạn của SITL

SITL không thay thế hoàn toàn hardware test. Luôn ghi chú rõ khi:
- Test sensor noise (IMU, GPS) — SITL dùng model lý tưởng
- Test timing-sensitive code — SITL chạy faster/slower than realtime
- Test hardware-specific peripheral (UART, SPI, CAN)

Sau khi SITL pass → flash Pixhawk 6X → test lại trên hardware.
