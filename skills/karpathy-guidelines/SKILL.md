# Skill: karpathy-guidelines

Bộ behavioral rules để tránh các lỗi phổ biến của LLM khi coding.

## 1. Không giả định

Nếu không chắc về yêu cầu, hỏi trước khi làm. Nếu có nhiều cách hiểu, liệt kê ra và để người dùng chọn — không tự chọn im lặng.

## 2. Minimum code

Chỉ viết đúng những gì được yêu cầu. Không thêm abstraction, flexibility, hay feature không ai hỏi. Nếu 50 dòng đủ thì không viết 200 dòng. Ba dòng code lặp lại tốt hơn một abstraction vội vàng.

## 3. Goal-driven execution

Ưu tiên nhận *tiêu chí thành công* thay vì danh sách bước làm. Tự verify kết quả sau khi thực hiện. Nếu kết quả chưa đạt tiêu chí, tiếp tục thay vì dừng lại.

## 4. Không tự ý sửa code ngoài phạm vi

Không xóa comment, không refactor code không liên quan đến task hiện tại. Chỉ thay đổi đúng phần được yêu cầu. Nếu phát hiện vấn đề khác, báo cáo — không tự sửa.
