Quy tắc làm việc với Jetson Orin Nano 8GB trong vai trò companion computer,
kết nối với Pixhawk 6X qua serial, chạy MAVSDK Python scripts.

## 1. Kiểm tra SSH trước mọi bước

Trước khi đề xuất bất kỳ lệnh nào trên Jetson, xác nhận kết nối còn sống:

```bash
ssh user@jetson-ip "echo ok"
```

Nếu SSH fail → dừng lại, không tiếp tục đề xuất deploy steps.

## 2. Serial port — Pixhawk 6X kết nối Jetson

Jetson Orin Nano dùng UART hardware tại `/dev/ttyTHS*` (không phải `/dev/ttyUSB*`):

```bash
# Kiểm tra port có sẵn
ls /dev/ttyTHS*

# Port thường dùng cho Pixhawk
# /dev/ttyTHS1  (UART1)
# /dev/ttyTHS2  (UART2)
```

Yêu cầu permission:
```bash
sudo usermod -aG dialout $USER
# Logout và login lại để có hiệu lực
```

Baud rate mặc định với Pixhawk 6X: `57600` hoặc `921600`.

## 3. Python environment — dùng venv

Không install MAVSDK hoặc bất kỳ package nào vào Python global trên Jetson:

```bash
# Tạo venv (1 lần)
python3 -m venv ~/drone-env

# Activate trước khi install hoặc chạy
source ~/drone-env/bin/activate

# Install MAVSDK
pip install mavsdk
```

Systemd service phải gọi đúng Python từ venv, không dùng `python3` global.

## 4. Systemd service — auto-start khi boot

Template cho MAVSDK script chạy tự động:

```ini
# /etc/systemd/system/drone-controller.service
[Unit]
Description=Drone Controller (MAVSDK)
After=network.target

[Service]
Type=simple
User=<user>
WorkingDirectory=/home/<user>/drone-scripts
ExecStart=/home/<user>/drone-env/bin/python3 main.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
# Kích hoạt service
sudo systemctl daemon-reload
sudo systemctl enable drone-controller
sudo systemctl start drone-controller

# Xem log realtime
journalctl -u drone-controller -f
```

## 5. Deploy script lên Jetson

```bash
# Copy file
scp main.py user@jetson-ip:~/drone-scripts/

# Hoặc sync cả folder
rsync -av --exclude '__pycache__' ./drone-scripts/ user@jetson-ip:~/drone-scripts/

# Restart service sau khi deploy
ssh user@jetson-ip "sudo systemctl restart drone-controller"
```

## 6. Debug trên Jetson

```bash
# Xem log service
journalctl -u drone-controller -f

# Chạy thủ công để debug (deactivate service trước)
sudo systemctl stop drone-controller
source ~/drone-env/bin/activate
python3 main.py

# Kiểm tra serial port có đọc được không
sudo stty -F /dev/ttyTHS1 57600
sudo cat /dev/ttyTHS1 | xxd | head
```

## 7. Resource awareness

Jetson Orin Nano 8GB — MAVSDK flight control scripts nhẹ, không cần GPU:
- Không import torch/tensorflow trong flight control scripts
- Nếu chạy AI task song song (object detection...) — chạy process riêng, không chung process với MAVSDK
- Monitor nhiệt độ khi chạy ngoài trời: `cat /sys/devices/virtual/thermal/thermal_zone*/temp`
