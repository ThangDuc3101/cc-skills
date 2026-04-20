Áp dụng các rules sau mỗi khi viết hoặc sửa code.

## 1. Đọc trước khi sửa

TRƯỚC KHI sửa bất kỳ file nào, hãy ĐỌC nội dung hiện tại của file đó. Không được edit mù dựa trên tên file hay ký ức từ lần đọc trước.

- ❌ Sai: edit thẳng vào file vì "biết rồi, file này chứa X"
- ✅ Đúng: Read tool → thấy nội dung thực tế → mới edit

## 2. Không assume API hay function signature

TRƯỚC KHI gọi bất kỳ function hoặc API nào, GREP hoặc đọc source để xác nhận tên, parameters, return type. Không được đặt tên hay signature theo đoán mò.

- ❌ Sai: gọi `client.sendMessage(msg)` vì nghe có vẻ đúng
- ✅ Đúng: grep `sendMessage` → thấy signature thực là `client.send(payload, type)` → dùng đúng

## 3. Không giả định yêu cầu

Nếu yêu cầu mơ hồ hoặc có nhiều cách hiểu, DỪNG và HỎI. Liệt kê các cách hiểu, để user chọn. Không được tự chọn im lặng rồi làm.

- ❌ Sai: tự quyết định "refactor" nghĩa là rewrite toàn bộ module
- ✅ Đúng: hỏi "Bạn muốn refactor phần nào? Chỉ function A, hay cả module?"

## 4. Minimum code

Chỉ viết những gì được yêu cầu. KHÔNG thêm abstraction, flexibility, hay feature không ai hỏi. Nếu 50 dòng đủ thì không viết 200 dòng.

- ❌ Sai: thêm interface + factory pattern vì "sau này có thể cần mở rộng"
- ✅ Đúng: 3 dòng lặp lại tốt hơn 1 abstraction vội vàng

## 5. Goal-driven execution

Xác định TIÊU CHÍ THÀNH CÔNG trước khi bắt đầu. Sau khi thực hiện, tự verify kết quả. Nếu chưa đạt tiêu chí, tiếp tục — không dừng giữa chừng.

- ❌ Sai: báo "done" ngay sau khi chạy lệnh mà chưa kiểm tra output
- ✅ Đúng: chạy → kiểm tra output khớp tiêu chí → mới báo hoàn thành

## 6. Không tự ý sửa ngoài phạm vi

Chỉ thay đổi ĐÚNG phần được yêu cầu. Không xóa comment, không refactor code ngoài task. Nếu phát hiện vấn đề khác, BÁO CÁO — không tự sửa.

- ❌ Sai: fix bug trong function X, tiện tay rename variable trong function Y
- ✅ Đúng: fix X xong, note "Phát hiện naming issue ở Y, bạn có muốn sửa không?"
