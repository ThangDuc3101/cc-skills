Quy tắc làm việc với PX4-Autopilot source code (C++). Áp dụng khi thêm, sửa,
hoặc nghiên cứu bất kỳ module nào trong PX4.

## 1. Đọc map trước khi đọc source

Nếu `.px4-graph/px4_map.json` tồn tại, query map để xác định module và dependency
trước khi mở file source. Chỉ đọc source khi map không đủ thông tin.

## 2. uORB — publish/subscribe đúng cách

**uORB Pub/Sub — pattern bắt buộc:**

```cpp
// ✅ ĐÚNG
class MyModule : public ModuleBase<MyModule>, public ModuleParams {
    // Khai báo BÊN NGOÀI vòng lặp — khởi tạo 1 lần
    uORB::Subscription _status_sub{ORB_ID(vehicle_status)};
    uORB::Publication<my_msg_s> _my_pub{ORB_ID(my_msg)};

    void Run() override {  // đây là vòng lặp
        vehicle_status_s status{};
        if (_status_sub.update(&status)) {  // trong loop
            // xử lý
        }
    }
};
```

❌ SAI: khai báo `uORB::Subscription` bên trong `Run()` — tạo object mới mỗi iteration.

## 3. Logging — không dùng printf

| Dùng | Thay cho |
|------|----------|
| `PX4_INFO("msg")` | `printf`, `std::cout` |
| `PX4_WARN("msg")` | warning prints |
| `PX4_ERR("msg")` | error prints |
| `PX4_DEBUG("msg")` | debug prints (chỉ bật khi cần) |

## 4. Parameters — không hardcode giá trị tunable

- Khai báo: `PARAM_DEFINE_FLOAT(PARAM_NAME, default_value)` trong file `.cpp` của module
- Đọc: `param_get(param_find("PARAM_NAME"), &value)` — cache handle, không gọi `param_find()` trong loop
- Không hardcode các giá trị như gain, threshold, timeout — phải qua param system

## 5. Cấu trúc module chuẩn

Mỗi module mới phải có đủ 3 thành phần:

```cpp
// 1. Entry point
int module_name_main(int argc, char *argv[]);

// 2. Task spawn
static int task_spawn(int argc, char *argv[]);

// 3. Usage
static int print_usage(const char *reason = nullptr);
```

Kế thừa `ModuleBase<T>` và `ModuleParams` nếu module dùng parameters.

## 6. Build target cho Pixhawk 6X

```bash
# Build firmware
make px4_fmu-v6x_default

# Upload (khi Pixhawk 6X đã kết nối)
make px4_fmu-v6x_default upload
```

Không dùng target `px4_fmu-v5x` hay generic target khi làm việc với Pixhawk 6X.

## 7. Giới hạn phạm vi thay đổi

PX4 có nhiều module phụ thuộc nhau qua uORB. Khi sửa một module:
- Chỉ thay đổi đúng file được yêu cầu
- Nếu phát hiện bug ở module khác — báo cáo, không tự sửa
- Nếu thay đổi interface của topic trong `msg/` — kiểm tra tất cả subscriber trên map
