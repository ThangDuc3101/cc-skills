Quy tắc viết script Python với thư viện MAVSDK để tự động hóa điều khiển drone.
Áp dụng cho cả môi trường SITL và Pixhawk 6X thật trên Jetson Orin Nano.

## 1. Connection string theo môi trường

```python
# SITL (Gazebo Classic trên dev machine)
await system.connect(system_address="udp://:14540")

# Pixhawk 6X kết nối serial với Jetson Orin Nano
await system.connect(system_address="serial:///dev/ttyTHS1:57600")

# Pixhawk 6X qua UDP (nếu dùng companion computer bridge)
await system.connect(system_address="udp://192.168.1.x:14540")
```

Không hardcode connection string — dùng argument hoặc config file.

## 2. System discovery — bắt buộc trước mọi action

Luôn chờ drone connect và sẵn sàng trước khi gọi bất kỳ action nào:

```python
async def connect_drone(address: str) -> System:
    system = System()
    await system.connect(system_address=address)

    print("Chờ drone kết nối...")
    async for state in system.core.connection_state():
        if state.is_connected:
            print("Drone đã kết nối")
            break

    print("Chờ drone có GPS lock...")
    async for health in system.telemetry.health():
        if health.is_global_position_ok and health.is_home_position_ok:
            print("GPS sẵn sàng")
            break

    return system
```

Không bỏ qua bước này — gọi action khi drone chưa ready sẽ raise exception.

## 3. Error handling — không bỏ qua exception

Mọi MAVSDK action đều có thể raise exception. Phải catch đầy đủ:

```python
from mavsdk.action import ActionError
from mavsdk.mission import MissionError

try:
    await drone.action.arm()
    await drone.action.takeoff()
except ActionError as e:
    print(f"Action thất bại: {e}")
    return
```

Không dùng bare `except:` — phải catch exception cụ thể của MAVSDK.

## 4. Async — không blocking trong coroutine

```python
# SAI — blocking sleep trong coroutine
import time
time.sleep(5)

# ĐÚNG — async sleep
import asyncio
await asyncio.sleep(5)
```

Toàn bộ script MAVSDK phải chạy trong `asyncio.run(main())`.

## 5. Timeout — không dùng giá trị quá ngắn

Hardware thật chậm hơn SITL đáng kể. Khi chờ state change:

```python
# Thêm timeout để tránh chờ vô hạn
import asyncio

async def wait_for_armed(system, timeout=30):
    try:
        async with asyncio.timeout(timeout):
            async for is_armed in system.telemetry.armed():
                if is_armed:
                    return True
    except asyncio.TimeoutError:
        raise RuntimeError(f"Drone không arm được sau {timeout}s")
```

## 6. Mission — upload trước khi chạy

```python
# Đúng thứ tự: upload → start → monitor
await drone.mission.upload_mission(mission_plan)
await drone.action.arm()
await drone.mission.start_mission()

# Monitor tiến độ
async for progress in drone.mission.mission_progress():
    print(f"Mission item: {progress.current}/{progress.total}")
    if progress.current == progress.total:
        break
```

## 7. Kết thúc an toàn

Luôn có landing hoặc RTL trong mọi execution path, kể cả khi có exception:

```python
try:
    await run_mission(drone)
except Exception as e:
    print(f"Lỗi: {e} — kích hoạt RTL")
finally:
    await drone.action.return_to_launch()
```
