# TÀI LIỆU ĐẶC TẢ USE CASE HỆ THỐNG
## HỆ THỐNG QUẢN LÝ PHÒNG KHÁM THÚ Y

> **Tài liệu chuẩn RUP / IEEE phục vụ Đồ án tốt nghiệp Công nghệ Thông tin**  
> **Phiên bản:** 3.0 (đồng bộ với lược đồ CSDL v3.0, State Machine v3.0 và Activity v3.0: hóa đơn riêng cho từng dịch vụ, mua thuốc tại phòng khám là tùy chọn)  
> **Định dạng:** Chuẩn bảng đặc tả 2 cột (Use Case Specification Table Format) phục vụ đóng tập báo cáo đồ án.  
> **Nguyên tắc kỹ thuật:**  
> - Tập trung 100% vào **Luồng nghiệp vụ** và hành vi tương tác giữa Người dùng và Hệ thống.  
> - Tuyệt đối không đưa các chi tiết cài đặt kỹ thuật cơ sở dữ liệu tầng thấp (tên bảng, tên cột, SQL, hàm thời gian hệ thống hay công thức toán học nội bộ CSDL) vào nội dung Use Case.  
> - Các thao tác cập nhật đa thực thể được mô tả bằng quy trình giao dịch nghiệp vụ an toàn (*atomic business transaction with rollback on failure*).

---

## MỤC LỤC CÁC USE CASE ĐẶC TẢ

### PHẦN I: PHÂN HỆ 3 - TIẾP ĐÓN, ĐẶT LỊCH & HÀNG ĐỢI (BOOKING & QUEUE RECEPTION)
1. [UC-14: Đặt lịch hẹn khám trực tuyến (Online Booking)](#1-uc-14-đặt-lịch-hẹn-khám-trực-tuyến)
2. [UC-15: Quản lý lịch hẹn cá nhân (Manage Personal Appointments)](#2-uc-15-quản-lý-lịch-hẹn-cá-nhân)
3. [UC-16: Đặt lịch hẹn tại quầy / qua điện thoại (Receptionist Appointment Booking)](#3-uc-16-đặt-lịch-hẹn-tại-quầy--qua-điện-thoại)
4. [UC-17: Duyệt xác nhận / Từ chối lịch hẹn trực tuyến (Confirm & Cancel Online Appointment)](#4-uc-17-duyệt-xác-nhận--từ-chối-lịch-hẹn-trực-tuyến)
5. [UC-18: Quản lý hồ sơ Khách hàng & Thú cưng tại quầy (Manage Pet Owners & Pets)](#5-uc-18-quản-lý-hồ-sơ-khách-hàng--thú-cưng-tại-quầy)
6. [UC-19: Tiếp nhận thú cưng tại quầy (Check-in Appointment & Walk-in)](#6-uc-19-tiếp-nhận-thú-cưng-tại-quầy)
7. [UC-20: Giám sát & Điều phối hàng đợi khám bệnh (Queue Monitoring & Priority Handling)](#7-uc-20-giám-sát--điều-phối-hàng-đợi-khám-bệnh)
8. [UC-21: Điều phối & Phân công Bác sĩ phụ trách ca khám (Assign Doctor to Visit)](#8-uc-21-điều-phối--phân-công-bác-sĩ-phụ-trách-ca-khám)

### PHẦN II: LUỒNG CHUYÊN MÔN KHÁM CHỮA BỆNH, CẬN LÂM SÀNG, THANH TOÁN & BÁN THUỐC
9. [UC-22 & UC-23: Khám lâm sàng sơ bộ & Chỉ định dịch vụ - Giai đoạn 1 (Clinical Assessment & Service Ordering)](#9-uc-22--uc-23-khám-lâm-sàng-sơ-bộ--chỉ-định-dịch-vụ-giai-đoạn-1)
10. [UC-25 & UC-26: Tiếp nhận mẫu, Thực hiện Cận lâm sàng & Trả kết quả (Process Lab & Imaging Services)](#10-uc-25--uc-26-tiếp-nhận-mẫu-thực-hiện-cận-lâm-sàng--trả-kết-quả)
11. [UC-30, UC-31 & UC-33: Hội chẩn kết quả, Kê đơn & Chốt đợt khám - Giai đoạn 2 (Final Clinical Diagnosis & Visit Closing)](#11-uc-30-uc-31--uc-33-hội-chẩn-kết-quả-kê-đơn--chốt-đợt-khám-giai-đoạn-2)
12. [UC-34 & UC-35: Thu tiền hóa đơn dịch vụ & Xác nhận thanh toán (Service Invoice Payment)](#12-uc-34--uc-35-thu-tiền-hóa-đơn-dịch-vụ--xác-nhận-thanh-toán)
13. [UC-36: Bán thuốc theo đơn (tùy chọn) & Trừ tồn kho (Sell Prescribed Medicines & Deduct Stock)](#13-uc-36-bán-thuốc-theo-đơn-tùy-chọn--trừ-tồn-kho)
14. [Phụ lục: Thay đổi so với phiên bản 2.0](#phụ-lục-thay-đổi-so-với-phiên-bản-20)

---

## SƠ ĐỒ LUỒNG THỰC THI LIÊN KẾT GIỮA CÁC USE CASE

```text
[ CHỦ THÚ CƯNG ]
      │
      ├──> UC-14: Đặt lịch trực tuyến (Chờ xác nhận)
      │       │
      │       └──> UC-15: Quản lý lịch hẹn cá nhân (Đổi giờ / Tự hủy hẹn)
      │
══════╪═══════════════════════════════════════════════════════════════════════════
[ LỄ TÂN ]
      │
      ├──> UC-16: Đặt lịch qua điện thoại / tại quầy (Xác nhận ngay)
      ├──> UC-17: Duyệt xác nhận / Từ chối lịch hẹn trực tuyến
      ├──> UC-18: Quản lý hồ sơ Khách hàng & Thú cưng
      │
      ├──> UC-19: Tiếp nhận thú cưng (Check-in Appointment & Walk-in)
      │       │
      │       ▼
      ├──> UC-20: Giám sát danh sách chờ phân công & hàng đợi từng Bác sĩ
      │       │
      │       ▼
      └──> UC-21: Xếp ca vào hàng đợi riêng của Bác sĩ (không cần chờ Bác sĩ rảnh)
              │
══════════════╪═══════════════════════════════════════════════════════════════════
[ BÁC SĨ THÚ Y - PHÒNG KHÁM LÂM SÀNG ]
      │
      ▼
   UC-22 & 23: Gọi số trong hàng đợi của mình & Khám lâm sàng sơ bộ (Giai đoạn 1)
      │
      ├─────────────────────────────────────────────┐ (Nếu cần Cận lâm sàng)
      │ (Nếu không cần Cận lâm sàng: Tiêm/Khám nhẹ) │ Ra chỉ định Xét nghiệm/Siêu âm
      │                                             ▼
      │                                    [ Chờ kết quả cận lâm sàng ] 
      │                                (Bác sĩ tạm giải phóng để khám ca khác)
      │                                             │
      │   ══════════════════════════════════════════════════════════════════════
      │   [ KỸ THUẬT VIÊN XÉT NGHIỆM (LAB_TECHNICIAN) & CĐHA (IMAGING_TECHNICIAN) ]
      │         │
      │         ▼
      │      UC-25 & 26: Tiếp nhận mẫu, Chạy xét nghiệm / Chụp CĐHA
      │                  (Nhập kết quả, đối chiếu tham chiếu loài, tải ảnh)
      │         │
      │         ▼
      │      [ Đã có kết quả ] (Ca tự lên đầu hàng đợi của Bác sĩ khám chính)
      │   ══════════════════════════════════════════════════════════════════════
      │                                             │
      │ <───────────────────────────────────────────┘ (Bác sĩ gọi số, bệnh nhân vào phòng)
      ▼
   UC-30, 31 & 33: Hội chẩn kết quả, Chẩn đoán, Kê đơn & Chốt ca (Đang khám - Giai đoạn 2)
      │
      ▼
   [ Chờ thanh toán ]
      │
═════════════════════════════════════════════════════════════════════════════════
[ LỄ TÂN / THU NGÂN ]
      │
      ▼
   UC-34 & 35: Thu tiền các hóa đơn dịch vụ & Xác nhận thanh toán
      │        (Hóa đơn dịch vụ cuối cùng được thanh toán ⇒ Đợt khám "Đã hoàn thành")
      │
      ├──> [ Khách mua thuốc ngoài / Không kê đơn ] ──> Nhận đơn thuốc in, ra về
      │
      └──> [ Khách chọn mua thuốc tại phòng khám ] (Tùy chọn)
              │
              ▼
           UC-36: Bán thuốc theo đơn: Lập hóa đơn thuốc, Thu tiền & Trừ tồn kho
                  trong cùng một giao dịch (Không ảnh hưởng trạng thái đợt khám)
```

> **Lưu ý về hóa đơn (v3.0):** Mỗi dịch vụ được chỉ định (kể cả phí khám) có **một hóa đơn dịch vụ riêng**, được hệ thống lập tự động ngay khi Bác sĩ chỉ định. Thuốc có **hóa đơn thuốc riêng**, chỉ lập khi khách chọn mua tại phòng khám. Hệ thống không lưu tổng tiền mà tính từ đơn giá, số lượng, thuế suất và giảm giá của từng hóa đơn.

---

## PHẦN I: ĐẶC TẢ CÁC USE CASE PHÂN HỆ 3 (TIẾP ĐÓN, ĐẶT LỊCH & HÀNG ĐỢI)

### 1. UC-14: Đặt lịch hẹn khám trực tuyến

| Thuộc tính | Nội dung chi tiết |
| :--- | :--- |
| **Tên Use case** | **UC-14: Đặt lịch hẹn khám trực tuyến (Book Appointment Online)** |
| **Các yêu cầu liên quan** | BR-04, BR-05, REQ-BOOKING-01 |
| **Tác nhân chính** | Khách hàng (Chủ thú cưng) |
| **Tác nhân phụ** | Hệ thống thông báo |
| **Điều kiện tiên quyết** | 1. Khách hàng đã đăng nhập thành công vào Cổng thông tin với vai trò Chủ thú cưng.<br>2. Khách hàng đã có ít nhất một hồ sơ thú cưng được đăng ký trên hệ thống. |
| **Hậu điều kiện** | 1. Hệ thống ghi nhận thông tin lịch hẹn mới ở trạng thái "Chờ xác nhận" (PENDING).<br>2. Khung giờ được tạm giữ 1 suất sức chứa; Khách hàng nhận được mã số lịch hẹn duy nhất và thông báo chờ phòng khám tiếp nhận. |
| **Chuỗi sự kiện chính** | 1. Khách hàng nhấn vào chức năng "Đặt lịch khám mới" trên giao diện Cổng thông tin.<br>2. Giao diện hiển thị biểu mẫu đặt lịch hẹn khám bệnh.<br>3. Khách hàng chọn thú cưng từ danh sách thú cưng của mình; hệ thống hiển thị thông tin nhận diện cơ bản của thú cưng.<br>4. Khách hàng chọn ngày muốn khám bệnh (từ ngày hiện tại trở đi); hệ thống tải và hiển thị danh sách 14 khung giờ tiếp nhận trong ngày kèm trạng thái Còn chỗ / Hết chỗ (Sức chứa tối đa của mỗi khung giờ được **tính tự động theo công thức: $Capacity_{slot} = N_{active} \times 2$, dựa trên số Bác sĩ đang hoạt động nhân hệ số chu kỳ khám sơ bộ 15 phút**).<br>5. Khách hàng chọn khung giờ mong muốn và nhập lý do khám hoặc triệu chứng ban đầu của thú cưng.<br>6. Khách hàng nhấn nút "Xác nhận đặt lịch".<br>7. Hệ thống thực hiện quy trình tiếp nhận đặt lịch trong một giao dịch an toàn:<br>&nbsp;&nbsp;&nbsp;&nbsp;7.1. Kiểm tra tính khả dụng của khung giờ đã chọn (đảm bảo số lịch đã đặt < $max\_capacity$).<br>&nbsp;&nbsp;&nbsp;&nbsp;7.2. Tạo mã số lịch hẹn duy nhất (ví dụ: `APT-20261010-001`).<br>&nbsp;&nbsp;&nbsp;&nbsp;7.3. Ghi nhận lịch hẹn mới ở trạng thái "Chờ xác nhận" qua kênh đặt lịch trực tuyến (`ONLINE`).<br>&nbsp;&nbsp;&nbsp;&nbsp;7.4. Tạm giữ 1 suất sức chứa trong khung giờ đã chọn.<br>&nbsp;&nbsp;&nbsp;&nbsp;7.5. Hiển thị thông báo đặt lịch thành công kèm mã số lịch hẹn và hướng dẫn khách hàng chờ phòng khám liên hệ xác nhận.<br>&nbsp;&nbsp;&nbsp;&nbsp;7.6. Nếu xảy ra lỗi trong quá trình lưu trữ, hệ thống hoàn tác toàn bộ thao tác và thông báo đặt lịch thất bại. |
| **Luồng rẽ nhánh** | **3a. Thú cưng chưa có hồ sơ trên hệ thống:** Tại Bước 3, khách hàng chọn "Thêm mới thú cưng", nhập tên, loài (Chó, Mèo), giống loài, giới tính. Hệ thống lưu hồ sơ thú cưng mới và tự động chọn thú cưng này để tiếp tục luồng đặt lịch.<br>**5a. Thay đổi ngày hoặc khung giờ:** Khách hàng có thể chọn lại ngày hoặc khung giờ khác trước khi bấm xác nhận. |
| **Ngoại lệ** | **5.1. Khung giờ đã hết chỗ tiếp nhận:** Tại Bước 5, nếu khung giờ đã đạt giới hạn tiếp nhận tối đa (số lịch đã đặt bằng $max\_capacity$), hệ thống làm mờ khung giờ đó và thông báo: *"Khung giờ này đã đủ lịch hẹn, vui lòng chọn khung giờ khác"*.<br>**7.1. Lỗi xử lý hệ thống khi lưu trữ:** Tại Bước 7, nếu hệ thống gặp sự cố không thể hoàn tất giao dịch, hệ thống hoàn tác thao tác, thông báo lỗi cho người dùng và giữ nguyên các thông tin khách đã nhập trên biểu mẫu để không phải nhập lại. |

---

### 2. UC-15: Quản lý lịch hẹn cá nhân

| Thuộc tính | Nội dung chi tiết |
| :--- | :--- |
| **Tên Use case** | **UC-15: Quản lý lịch hẹn cá nhân (Manage Personal Appointments)** |
| **Các yêu cầu liên quan** | BR-04, BR-05, REQ-BOOKING-02 |
| **Tác nhân chính** | Khách hàng (Chủ thú cưng) |
| **Điều kiện tiên quyết** | Khách hàng đã đăng nhập thành công vào Cổng thông tin với vai trò Chủ thú cưng. |
| **Hậu điều kiện** | 1. Lịch hẹn được cập nhật thời gian mới (nếu đổi lịch) hoặc chuyển sang trạng thái "Đã hủy" (nếu hủy lịch).<br>2. Suất sức chứa (Slot Capacity) của khung giờ tương ứng được tự động giải phóng hoặc hoán đổi trên hệ thống. |
| **Chuỗi sự kiện chính** | 1. Khách hàng truy cập mục "Lịch hẹn của tôi" trên Cổng thông tin.<br>2. Hệ thống hiển thị danh sách các lịch hẹn đã đặt, phân loại theo trạng thái: "Chờ xác nhận", "Đã xác nhận", "Đã đến khám", "Đã hủy".<br>3. Khách hàng chọn một lịch hẹn đang ở trạng thái "Chờ xác nhận" hoặc "Đã xác nhận" cần thay đổi và nhấn nút "Đổi ngày / Khung giờ".<br>4. Hệ thống kiểm tra điều kiện thời gian: Thời điểm hiện tại phải cách giờ hẹn tối thiểu 02 tiếng.<br>5. Hệ thống hiển thị lịch chọn ngày và danh sách các khung giờ tiếp nhận còn trống trong ngày mới.<br>6. Khách hàng chọn ngày và khung giờ mới còn chỗ, nhập lý do thay đổi và bấm "Xác nhận đổi lịch".<br>7. Hệ thống thực hiện đổi lịch trong một giao dịch an toàn:<br>&nbsp;&nbsp;&nbsp;&nbsp;7.1. Kiểm tra lại sức chứa khả dụng của khung giờ mới.<br>&nbsp;&nbsp;&nbsp;&nbsp;7.2. Hoàn trả 1 suất sức chứa của khung giờ cũ.<br>&nbsp;&nbsp;&nbsp;&nbsp;7.3. Chiếm giữ 1 suất sức chứa của khung giờ mới.<br>&nbsp;&nbsp;&nbsp;&nbsp;7.4. Cập nhật ngày hẹn và khung giờ mới cho lịch hẹn, ghi nhận thời điểm đổi.<br>&nbsp;&nbsp;&nbsp;&nbsp;7.5. Hiển thị thông báo đổi lịch thành công cho khách hàng.<br>&nbsp;&nbsp;&nbsp;&nbsp;7.6. Nếu xảy ra lỗi hoặc khung giờ mới vừa hết chỗ, hệ thống hoàn tác thao tác và thông báo thất bại. |
| **Luồng rẽ nhánh** | **3a. Hủy lịch hẹn:** Tại Bước 3, khách hàng chọn "Hủy lịch hẹn". Hệ thống yêu cầu chọn lý do hủy (Bận việc đột xuất, Thú cưng đã khỏi, Đổi cơ sở khác...). Khách hàng bấm xác nhận; hệ thống cập nhật trạng thái sang "Đã hủy" (CANCELLED), hoàn trả ngay 1 suất sức chứa cho khung giờ đó và gửi thông báo hủy thành công. |
| **Ngoại lệ** | **4.1. Đổi hoặc hủy lịch sát giờ (Dưới 02 tiếng):** Tại Bước 4, nếu thời gian còn lại đến giờ hẹn dưới 2 tiếng, hệ thống chặn lại và thông báo: *"Đã quá thời gian cho phép tự đổi/hủy lịch trên hệ thống (tối thiểu 2 tiếng trước giờ hẹn). Vui lòng liên hệ trực tiếp hotline phòng khám để được hỗ trợ"*.<br>**7.1. Khung giờ mới đã hết chỗ:** Tại Bước 7.1, nếu khung giờ mới vừa bị người khác đặt kín chỗ trong cùng thời điểm, hệ thống từ chối cập nhật và yêu cầu khách chọn khung giờ khác. |

---

### 3. UC-16: Đặt lịch hẹn tại quầy / qua điện thoại

| Thuộc tính | Nội dung chi tiết |
| :--- | :--- |
| **Tên Use case** | **UC-16: Đặt lịch hẹn tại quầy / qua điện thoại (Receptionist Appointment Booking)** |
| **Các yêu cầu liên quan** | BR-04, BR-05, BR-14, REQ-BOOKING-03 |
| **Tác nhân chính** | Lễ tân |
| **Tác nhân phụ** | Khách hàng (Người gọi điện hoặc đang tại quầy) |
| **Điều kiện tiên quyết** | Lễ tân đã đăng nhập vào hệ thống với vai trò Lễ tân. |
| **Hậu điều kiện** | Lịch hẹn mới được ghi nhận trực tiếp ở trạng thái "Đã xác nhận" (CONFIRMED) và chiếm 1 suất sức chứa của khung giờ tương ứng. |
| **Chuỗi sự kiện chính** | 1. Lễ tân tiếp nhận cuộc gọi của khách hàng đến hotline phòng khám yêu cầu đặt lịch hẹn.<br>2. Lễ tân mở màn hình "Đặt lịch hẹn tại cơ sở" trên giao diện quản trị phòng khám.<br>3. Lễ tân nhập Số điện thoại của khách hàng để tra cứu: Hệ thống hiển thị thông tin chủ nuôi và danh sách thú cưng của họ.<br>4. Lễ tân chọn thú cưng cần khám theo yêu cầu của khách.<br>5. Lễ tân hỏi ngày và khung giờ khách muốn đặt; hệ thống hiển thị trực quan các khung giờ còn chỗ trong ngày (Số lịch đã đặt < $max\_capacity = N_{active} \times 2$).<br>6. Lễ tân chọn khung giờ khách đồng ý, nhập lý do khám / triệu chứng khách mô tả qua điện thoại và chọn kênh đặt lịch là "Qua điện thoại".<br>7. Lễ tân nhấn nút "Tạo & Xác nhận lịch hẹn".<br>8. Hệ thống thực hiện lưu lịch hẹn trong một giao dịch an toàn:<br>&nbsp;&nbsp;&nbsp;&nbsp;8.1. Kiểm tra lại sức chứa khả dụng của khung giờ đã chọn.<br>&nbsp;&nbsp;&nbsp;&nbsp;8.2. Tạo mã số lịch hẹn duy nhất.<br>&nbsp;&nbsp;&nbsp;&nbsp;8.3. Ghi nhận lịch hẹn mới ở trạng thái "Đã xác nhận" (CONFIRMED), ghi nhận nhân viên lễ tân tạo lịch và thời điểm tạo.<br>&nbsp;&nbsp;&nbsp;&nbsp;8.4. Chiếm giữ 1 suất sức chứa của khung giờ đó.<br>&nbsp;&nbsp;&nbsp;&nbsp;8.5. Hiển thị thông báo tạo lịch thành công và gửi tin nhắn/thông báo xác nhận đến số điện thoại khách hàng.<br>&nbsp;&nbsp;&nbsp;&nbsp;8.6. Nếu xảy ra lỗi, hệ thống hoàn tác toàn bộ thao tác. |
| **Luồng rẽ nhánh** | **3a. Khách hàng mới chưa có thông tin trên hệ thống:** Tại Bước 3, nếu tra cứu không thấy SĐT, Lễ tân chọn "Tạo nhanh khách hàng & Thú cưng", nhập Họ tên, SĐT, Địa chỉ, Tên thú cưng, Loài (Chó/Mèo). Hệ thống tự động cấp tài khoản và tiếp tục luồng đặt lịch.<br>**6a. Đặt lịch trực tiếp tại quầy cho lần sau:** Khách hàng đang ở phòng khám đặt trước cho buổi tái khám tuần sau, Lễ tân chọn kênh đặt là "Tại quầy". Sau khi hoàn tất ở Bước 8, hệ thống cung cấp tùy chọn in phiếu hẹn trao tay cho khách hàng. |
| **Ngoại lệ** | **5.1. Khung giờ khách yêu cầu đã kín chỗ:** Tại Bước 5, hệ thống làm mờ khung giờ đã đủ số lượng lịch hẹn theo năng lực phục vụ của các bác sĩ; Lễ tân tư vấn khách chọn các khung giờ lân cận còn trống.<br>**8.1. Lỗi hệ thống khi lưu trữ:** Tại Bước 8, nếu lưu trữ thất bại, hệ thống hoàn tác toàn bộ giao dịch và hiển thị thông báo lỗi. |

---

### 4. UC-17: Duyệt xác nhận / Từ chối lịch hẹn trực tuyến

| Thuộc tính | Nội dung chi tiết |
| :--- | :--- |
| **Tên Use case** | **UC-17: Duyệt xác nhận / Từ chối lịch hẹn trực tuyến (Confirm & Cancel Online Appointment)** |
| **Các yêu cầu liên quan** | BR-04, BR-05, REQ-APPT-APPROVAL-01 |
| **Tác nhân chính** | Lễ tân |
| **Tác nhân phụ** | Hệ thống thông báo |
| **Điều kiện tiên quyết** | 1. Lễ tân đã đăng nhập vào hệ thống với vai trò Lễ tân.<br>2. Có ít nhất một lịch hẹn trực tuyến đang ở trạng thái "Chờ xác nhận" (PENDING). |
| **Hậu điều kiện** | 1. Lịch hẹn được chuyển sang trạng thái "Đã xác nhận" (CONFIRMED) hoặc "Đã hủy" (CANCELLED).<br>2. Khách hàng nhận được thông báo kết quả phê duyệt. Nếu từ chối, 1 suất sức chứa của khung giờ được giải phóng. |
| **Chuỗi sự kiện chính** | 1. Lễ tân mở màn hình "Quản lý duyệt lịch hẹn trực tuyến".<br>2. Hệ thống hiển thị danh sách các lịch hẹn đang ở trạng thái "Chờ xác nhận", sắp xếp theo thời gian gửi yêu cầu tăng dần.<br>3. Lễ tân chọn một yêu cầu đặt lịch để xem chi tiết: Tên chủ nuôi, SĐT, Tên thú cưng, Loài, Triệu chứng ban đầu, Ngày và Khung giờ hẹn.<br>4. Lễ tân gọi điện thoại cho khách hàng theo SĐT đăng ký để xác nhận thông tin, hỏi thêm về tình trạng bệnh và dặn dò chuyên môn (nhịn ăn nếu cần làm xét nghiệm).<br>5. Sau khi trao đổi thành công, Lễ tân nhấn nút "Xác nhận lịch hẹn".<br>6. Hệ thống thực hiện cập nhật trong một giao dịch an toàn:<br>&nbsp;&nbsp;&nbsp;&nbsp;6.1. Cập nhật trạng thái lịch hẹn từ "Chờ xác nhận" sang "Đã xác nhận" (CONFIRMED).<br>&nbsp;&nbsp;&nbsp;&nbsp;6.2. Ghi nhận thời điểm duyệt và nhân viên lễ tân thực hiện.<br>&nbsp;&nbsp;&nbsp;&nbsp;6.3. Giữ nguyên 1 suất sức chứa chính thức trong khung giờ đó.<br>&nbsp;&nbsp;&nbsp;&nbsp;6.4. Gửi thông báo phê duyệt thành công đến Cổng thông tin của khách hàng kèm hướng dẫn thời gian có mặt.<br>&nbsp;&nbsp;&nbsp;&nbsp;6.5. Nếu xảy ra lỗi, hoàn tác toàn bộ thao tác. |
| **Luồng rẽ nhánh** | **5a. Từ chối / Hủy lịch hẹn:** Tại Bước 5, nếu phòng khám không thể tiếp nhận (mất điện đột xuất, bảo trì thiết bị, khách đặt sai dịch vụ) hoặc khách báo hủy qua điện thoại, Lễ tân bấm nút "Từ chối lịch hẹn". Lễ tân nhập lý do từ chối (bắt buộc). Hệ thống cập nhật trạng thái sang "Đã hủy" (CANCELLED), giải phóng ngay 1 suất sức chứa của khung giờ đó và gửi thông báo giải thích lý do cho khách hàng. |
| **Ngoại lệ** | **4.1. Không liên lạc được với khách hàng:** Tại Bước 4, nếu gọi nhiều lần khách không nghe máy, Lễ tân chọn "Ghi chú liên hệ thất bại" và giữ trạng thái "Chờ xác nhận" để liên hệ lại sau.<br>**6.1. Lỗi hệ thống khi cập nhật trạng thái:** Nếu quá trình lưu trữ gặp sự cố, hệ thống hoàn tác thao tác, giữ nguyên trạng thái "Chờ xác nhận" và thông báo lỗi. |

---

### 5. UC-18: Quản lý hồ sơ Khách hàng & Thú cưng tại quầy

| Thuộc tính | Nội dung chi tiết |
| :--- | :--- |
| **Tên Use case** | **UC-18: Quản lý hồ sơ Khách hàng & Thú cưng tại quầy (Manage Pet Owners & Pets)** |
| **Các yêu cầu liên quan** | BR-14, BR-15, REQ-CUSTOMER-01 |
| **Tác nhân chính** | Lễ tân |
| **Điều kiện tiên quyết** | Lễ tân đã đăng nhập vào hệ thống với vai trò Lễ tân. |
| **Hậu điều kiện** | Thông tin khách hàng và hồ sơ thú cưng được khởi tạo hoặc cập nhật chính xác trên hệ thống, sẵn sàng cho việc đặt lịch hoặc tiếp nhận khám. |
| **Chuỗi sự kiện chính** | 1. Lễ tân mở màn hình "Quản lý Khách hàng & Thú cưng" tại quầy tiếp đón.<br>2. Lễ tân nhấn nút "Thêm mới Khách hàng".<br>3. Lễ tân nhập thông tin khách hàng: Họ và tên, Số điện thoại (bắt buộc duy nhất), Email, Địa chỉ liên hệ.<br>4. Nhập thông tin thú cưng đầu tiên của khách: Tên thú cưng, Loài (chọn Chó hoặc Mèo), Giống loài, Giới tính, Ngày sinh / Tuổi ước tính, Màu lông, Tình trạng triệt sản, Đặc điểm nhận dạng ban đầu.<br>5. Lễ tân nhấn nút "Lưu hồ sơ".<br>6. Hệ thống thực hiện tạo hồ sơ trong một giao dịch an toàn:<br>&nbsp;&nbsp;&nbsp;&nbsp;6.1. Kiểm tra tính hợp lệ của dữ liệu (SĐT đúng 10 số, không bị trùng lặp trong hệ thống).<br>&nbsp;&nbsp;&nbsp;&nbsp;6.2. Tạo tài khoản người dùng cho khách hàng với vai trò "Chủ thú cưng", mật khẩu khởi tạo mặc định.<br>&nbsp;&nbsp;&nbsp;&nbsp;6.3. Khởi tạo mã thú cưng duy nhất (ví dụ: `PET-202610-008`).<br>&nbsp;&nbsp;&nbsp;&nbsp;6.4. Lưu hồ sơ thú cưng và liên kết với tài khoản chủ nuôi vừa tạo.<br>&nbsp;&nbsp;&nbsp;&nbsp;6.5. Hiển thị thông báo lưu thành công và hiển thị hồ sơ chi tiết.<br>&nbsp;&nbsp;&nbsp;&nbsp;6.6. Nếu xảy ra lỗi, hoàn tác toàn bộ thao tác. |
| **Luồng rẽ nhánh** | **1a. Tra cứu và cập nhật thông tin:** Tại Bước 1, Lễ tân nhập SĐT hoặc Tên khách hàng để tìm kiếm. Hệ thống hiển thị danh sách thú cưng của khách. Lễ tân có thể chọn cập nhật thông tin liên hệ của chủ nuôi, chỉnh sửa thông tin thú cưng hoặc bấm "Thêm thú cưng mới" cho chủ nuôi đã có sẵn trên hệ thống. |
| **Ngoại lệ** | **6.1. Số điện thoại đã tồn tại trên hệ thống:** Tại Bước 6.1, nếu SĐT trùng với khách hàng khác, hệ thống cảnh báo: *"Số điện thoại này đã được đăng ký cho khách hàng [Tên khách hàng cũ]. Vui lòng kiểm tra lại hoặc tra cứu hồ sơ cũ"*.<br>**6.2. Lỗi giao dịch hệ thống:** Nếu lỗi kết nối khi lưu đồng thời khách và thú cưng, hệ thống rollback toàn bộ và thông báo thất bại. |

---

### 6. UC-19: Tiếp nhận thú cưng tại quầy

| Thuộc tính | Nội dung chi tiết |
| :--- | :--- |
| **Tên Use case** | **UC-19: Tiếp nhận thú cưng tại quầy (Check-in Appointment & Walk-in)** |
| **Các yêu cầu liên quan** | BR-06, BR-09, BR-11, BR-14, REQ-CHECKIN-01 |
| **Tác nhân chính** | Lễ tân |
| **Điều kiện tiên quyết** | 1. Lễ tân đã đăng nhập vào hệ thống với vai trò Lễ tân.<br>2. Khách hàng và thú cưng đã có mặt trực tiếp tại quầy tiếp đón của phòng khám. |
| **Hậu điều kiện** | 1. Đợt khám mới được tạo ở trạng thái "Chờ khám" (WAITING), nằm trong hàng đợi của Bác sĩ được chọn hoặc trong danh sách chờ phân công.<br>2. Lịch hẹn tương ứng (nếu có) được liên kết với đợt khám vừa tạo và được hệ thống tự động chuyển sang trạng thái "Đã đến khám" (CHECKED_IN) ngay sau đó (phân hệ Đặt lịch xử lý riêng, chậm hơn vài trăm mili giây). |
| **Chuỗi sự kiện chính** | 1. Lễ tân mở màn hình "Tiếp nhận bệnh nhân" tại quầy tiếp đón. Hệ thống hiển thị danh sách các lịch hẹn đã được xác nhận trong ngày.<br>2. Lễ tân tra cứu lịch hẹn theo Số điện thoại khách hàng hoặc Mã lịch hẹn. Hệ thống trả về thông tin khách hàng, thú cưng và khung giờ hẹn.<br>3. Lễ tân nhấn chọn "Tiếp nhận / Check-in" trên dòng lịch hẹn tương ứng. Hệ thống hiển thị biểu mẫu tiếp nhận đợt khám mới.<br>4. Lễ tân quan sát, đánh giá nhanh tri giác và dấu hiệu nguy kịch của thú cưng (nếu co giật, khó thở dữ dội, tai nạn thì đánh dấu cờ `is_emergency`). Việc đo thân nhiệt, cân nặng sẽ do Bác sĩ thực hiện trực tiếp trong phòng khám.<br>5. Lễ tân xác nhận lý do đến khám / triệu chứng ban đầu với chủ nuôi, bổ sung các ghi chú sơ bộ và chọn Bác sĩ phụ trách (tùy chọn, có thể xếp sau ở UC-21).<br>6. Lễ tân nhấn nút "Hoàn tất tiếp đón".<br>7. Hệ thống thực hiện quy trình tiếp nhận trong một giao dịch an toàn:<br>&nbsp;&nbsp;&nbsp;&nbsp;7.1. Tạo mã số đợt khám duy nhất.<br>&nbsp;&nbsp;&nbsp;&nbsp;7.2. Ghi nhận đợt khám mới ở trạng thái "Chờ khám" cùng thời điểm tiếp nhận và cờ cấp cứu (nếu có).<br>&nbsp;&nbsp;&nbsp;&nbsp;7.3. Liên kết đợt khám với lịch hẹn tương ứng.<br>&nbsp;&nbsp;&nbsp;&nbsp;7.4. Đưa đợt khám vào hàng đợi: nếu Lễ tân đã chọn Bác sĩ ở Bước 5 (hệ thống gợi ý Bác sĩ có ít người chờ nhất) thì ca vào hàng đợi riêng của Bác sĩ đó; nếu chưa chọn thì ca nằm trong danh sách chờ phân công (UC-21).<br>&nbsp;&nbsp;&nbsp;&nbsp;7.5. Nếu xảy ra lỗi trong quá trình xử lý, hệ thống hoàn tác toàn bộ thao tác và thông báo tiếp nhận thất bại.<br>8. Sau khi đợt khám được lưu thành công, hệ thống phát thông báo nội bộ để phân hệ Đặt lịch chuyển lịch hẹn sang "Đã đến khám" và ghi lịch sử trạng thái lịch hẹn (giao dịch riêng của phân hệ Đặt lịch; nếu xử lý lỗi sẽ tự thử lại). |
| **Luồng rẽ nhánh** | **2a. Khách hàng đến trực tiếp không đặt trước (Khách vãng lai):**<br>1. Tại Bước 2, Lễ tân chọn chức năng "Tiếp nhận khách vãng lai".<br>2. Lễ tân tra cứu Số điện thoại khách hàng: Nếu khách cũ, hệ thống tải thông tin; Nếu khách mới, tạo hồ sơ qua UC-18.<br>3. Lễ tân nhập lý do đến khám / triệu chứng ban đầu, đánh dấu cờ cấp cứu nếu cần và bấm lưu.<br>4. Hệ thống tạo đợt khám mới với liên kết lịch hẹn để trống (`appointment_id = NULL`), đặt trạng thái "Chờ khám" và đưa vào hàng đợi như Bước 7.4. |
| **Ngoại lệ** | **4.1. Thông tin khách hàng không hợp lệ:** Tại Bước 2 hoặc Bước 2a, nếu số điện thoại không đúng định dạng hoặc thiếu thông tin bắt buộc, hệ thống cảnh báo và yêu cầu chỉnh sửa lại.<br>**7.0. Thú cưng đang có đợt khám chưa kết thúc:** Tại Bước 7, nếu thú cưng còn một đợt khám chưa "Đã hoàn thành" hoặc "Đã hủy", hệ thống từ chối tạo đợt khám mới và thông báo: *"Thú cưng đang có đợt khám chưa kết thúc, vui lòng kiểm tra lại hàng đợi"*.<br>**7.0b. Lịch hẹn không hợp lệ để check-in:** Tại Bước 7, nếu lịch hẹn không ở trạng thái "Đã xác nhận", không đúng ngày hẹn hoặc không đúng thú cưng, hệ thống từ chối và thông báo; khách đến sau khi lịch đã bị đánh dấu vắng mặt được tiếp nhận như khách vãng lai (Luồng 2a).<br>**7.1. Lỗi hệ thống khi khởi tạo đợt khám:** Tại Bước 7, nếu quá trình ghi nhận đợt khám thất bại, hệ thống hoàn tác toàn bộ thao tác, giữ nguyên trạng thái lịch hẹn cũ và hiển thị thông báo lỗi. |

---

### 7. UC-20: Giám sát & Điều phối hàng đợi khám bệnh

| Thuộc tính | Nội dung chi tiết |
| :--- | :--- |
| **Tên Use case** | **UC-20: Giám sát & Điều phối hàng đợi khám bệnh (Queue Monitoring & Priority Handling)** |
| **Các yêu cầu liên quan** | BR-09, BR-10, BR-11, BR-12, BR-13, REQ-QUEUE-01 |
| **Tác nhân chính** | Lễ tân |
| **Điều kiện tiên quyết** | Lễ tân đã đăng nhập vào hệ thống với vai trò Lễ tân. |
| **Hậu điều kiện** | Lễ tân nhìn thấy đồng thời danh sách ca chờ phân công và **hàng đợi riêng của từng Bác sĩ**, sẵn sàng xếp ca vào hàng đợi phù hợp (UC-21). |
| **Chuỗi sự kiện chính** | 1. Lễ tân mở màn hình "Bảng điều phối hàng đợi khám bệnh".<br>2. Hệ thống hiển thị **danh sách ca chờ phân công**: các đợt khám "Chờ khám" chưa được xếp vào hàng đợi Bác sĩ nào, ca cấp cứu lên đầu, còn lại theo thời gian check-in tăng dần.<br>3. Hệ thống hiển thị song song **một cột hàng đợi cho mỗi Bác sĩ đang làm việc**: Số phòng cố định, Tên Bác sĩ, trạng thái ("Đang khám" hoặc "Sẵn sàng"), số người đang chờ, và danh sách ca theo số thứ tự (STT). Thứ tự trong mỗi hàng đợi: ca cấp cứu chưa bị đẩy lùi lên đầu; tiếp theo là ca vừa có kết quả cận lâm sàng quay lại; còn lại theo thứ tự tiếp nhận, có tính các lần bị đẩy lùi 1 bậc. Ca nào đã bị đẩy lùi hiển thị số lần bị lùi.<br>4. Hệ thống đánh dấu Bác sĩ đang có ít người chờ nhất làm gợi ý cho lần phân công tiếp theo.<br>5. Lễ tân theo dõi thời gian chờ của từng thú cưng và xếp các ca chờ phân công vào hàng đợi Bác sĩ (UC-21), hoặc chuyển ca giữa các hàng đợi khi một Bác sĩ quá đông hoặc nghỉ đột xuất. |
| **Luồng rẽ nhánh** | **2a. Tiếp nhận ca cấp cứu phát sinh đột xuất:** Khi có thú cưng nguy kịch vừa được tiếp nhận tại quầy (UC-19), ca hiển thị đầu danh sách kèm cảnh báo nhấp nháy đỏ; Lễ tân xếp ngay vào hàng đợi một Bác sĩ, ca đứng đầu hàng đợi đó.<br>**4a. Bệnh nhân xin ra ngoài trong lúc chờ:** Ca vẫn giữ nguyên vị trí trong hàng đợi. Nếu đến lượt mà khách chưa quay lại, Bác sĩ "Đẩy lùi 1 bậc" (UC-22_23, Ngoại lệ 2.1); khách quay lại thì chờ đến lượt mới. Nếu khách không quay lại, Lễ tân hủy tiếp nhận (EX-03). |
| **Ngoại lệ** | **2.1. Hàng đợi trống:** Nếu không có ca chờ phân công và mọi hàng đợi Bác sĩ đều trống, hệ thống hiển thị thông báo: *"Hiện không có bệnh nhân nào trong hàng đợi"* và tự động làm mới khi có ca check-in mới.<br>**3.1. Không có Bác sĩ nào đang làm việc:** Hệ thống chỉ hiển thị danh sách ca chờ phân công và thông báo cho Lễ tân chưa có Bác sĩ để xếp hàng đợi. |

---

### 8. UC-21: Điều phối & Phân công Bác sĩ phụ trách ca khám

| Thuộc tính | Nội dung chi tiết |
| :--- | :--- |
| **Tên Use case** | **UC-21: Điều phối & Phân công Bác sĩ phụ trách ca khám (Assign Doctor to Visit)** – xếp ca vào hàng đợi riêng của Bác sĩ |
| **Các yêu cầu liên quan** | BR-10, BR-11, BR-12, BR-13, REQ-DISPATCH-01 |
| **Tác nhân chính** | Lễ tân |
| **Điều kiện tiên quyết** | 1. Đợt khám đang ở trạng thái "Chờ khám" (chưa bắt đầu khám).<br>2. Có ít nhất một Bác sĩ đang làm việc (tài khoản hoạt động). Bác sĩ **không cần đang rảnh**. |
| **Hậu điều kiện** | 1. Đợt khám được gán Bác sĩ phụ trách chính và nằm trong **hàng đợi riêng của Bác sĩ đó** (vẫn ở trạng thái "Chờ khám"), giữ nguyên thứ tự theo thời điểm tiếp nhận; số phòng lấy theo phòng cố định của Bác sĩ, không lưu riêng trên đợt khám.<br>2. Bác sĩ được chỉ định thấy ca mới trong hàng đợi của mình; chủ nuôi nhận số thứ tự và số phòng. |
| **Chuỗi sự kiện chính** | 1. Lễ tân mở màn hình "Điều phối hàng đợi khám bệnh" (UC-20). Hệ thống hiển thị danh sách ca chờ phân công và hàng đợi của từng Bác sĩ kèm số người đang chờ.<br>2. Lễ tân chọn một ca khám (ưu tiên ca cấp cứu, sau đó ca tiếp nhận trước). Bước này có thể làm ngay khi tiếp nhận ở UC-19.<br>3. Lễ tân nhấn nút "Xếp vào hàng đợi Bác sĩ". Hệ thống hiển thị danh sách Bác sĩ đang làm việc, số người đang chờ của từng Bác sĩ và **gợi ý Bác sĩ có ít người chờ nhất**.<br>4. Lễ tân chọn Bác sĩ (theo gợi ý hoặc theo yêu cầu của khách, ví dụ: Bác sĩ Nguyễn Văn A - Phòng khám 101).<br>5. Lễ tân nhấn nút "Xác nhận".<br>6. Hệ thống thực hiện trong một giao dịch an toàn:<br>&nbsp;&nbsp;&nbsp;&nbsp;6.1. Kiểm tra đợt khám vẫn "Chờ khám" và chưa bị người khác cập nhật trong lúc thao tác.<br>&nbsp;&nbsp;&nbsp;&nbsp;6.2. Gán Bác sĩ phụ trách chính vào đợt khám; ca vào hàng đợi của Bác sĩ đó theo thứ tự tiếp nhận.<br>&nbsp;&nbsp;&nbsp;&nbsp;6.3. Màn hình hàng đợi của Bác sĩ được chỉ định tự làm mới và hiện ca mới (không cần thông báo riêng).<br>&nbsp;&nbsp;&nbsp;&nbsp;6.4. In phiếu ghi số phòng và số thứ tự trong hàng đợi, hướng dẫn chủ nuôi chờ trước phòng.<br>&nbsp;&nbsp;&nbsp;&nbsp;6.5. Nếu xảy ra lỗi, hệ thống hoàn tác toàn bộ thao tác và thông báo cho Lễ tân. |
| **Luồng rẽ nhánh** | **2a. Tiếp nhận ca cấp cứu khẩn cấp:** Lễ tân xếp ngay ca cấp cứu vào hàng đợi Bác sĩ phù hợp; ca đứng đầu hàng đợi đó và được gọi ngay khi Bác sĩ khám xong ca hiện tại.<br>**5a. Chuyển ca sang Bác sĩ khác khi chưa bắt đầu khám:** Nếu một Bác sĩ quá đông hoặc gặp sự cố đột xuất, Lễ tân chọn ca và chuyển sang hàng đợi Bác sĩ khác; ca giữ nguyên thứ tự theo thời điểm tiếp nhận ở hàng đợi mới. Ca vừa có kết quả cận lâm sàng luôn thuộc Bác sĩ khám chính, không chuyển.<br>**5b. Khách bỏ về khi đang chờ trong hàng đợi:** Lễ tân hủy đợt khám (kèm lý do, EX-03); ca rời khỏi hàng đợi.<br>**5c. Gỡ khỏi hàng đợi Bác sĩ:** Khi Bác sĩ nghỉ đột xuất và chưa chọn được Bác sĩ thay, Lễ tân chọn *"Gỡ phân công"*: ca trở về danh sách chờ phân công, giữ thứ tự tiếp nhận, để xếp lại sau. |
| **Ngoại lệ** | **6.1. Ca đã được Bác sĩ bắt đầu khám:** Tại Bước 6.1, nếu đợt khám không còn "Chờ khám" (Bác sĩ vừa bắt đầu khám), hệ thống từ chối chuyển và thông báo: *"Ca khám đã bắt đầu, không thể chuyển Bác sĩ"*.<br>**6.2. Bác sĩ được chọn không còn hoạt động:** Nếu tài khoản Bác sĩ vừa bị khóa hoặc không phải Bác sĩ, hệ thống từ chối và yêu cầu chọn Bác sĩ khác. |

---

## PHẦN II: ĐẶC TẢ CÁC USE CASE KHÁM CHỮA BỆNH, CẬN LÂM SÀNG, THANH TOÁN & BÁN THUỐC

### 9. UC-22 & UC-23: Khám lâm sàng sơ bộ & Chỉ định dịch vụ (Giai đoạn 1)

| Thuộc tính | Nội dung chi tiết |
| :--- | :--- |
| **Tên Use case** | **UC-22_23: Khám lâm sàng sơ bộ & Chỉ định dịch vụ - Giai đoạn 1 (Clinical Assessment & Service Ordering)** |
| **Các yêu cầu liên quan** | BR-12, BR-15, BR-19, BR-20, BR-25, BR-27, BR-34, REQ-CLINIC-01 |
| **Tác nhân chính** | Bác sĩ thú y (Bác sĩ khám chính) |
| **Điều kiện tiên quyết** | 1. Bác sĩ đã đăng nhập vào hệ thống với vai trò Bác sĩ thú y.<br>2. Ca khám nằm trong hàng đợi riêng của Bác sĩ này (Lễ tân đã xếp ở UC-19 / UC-21).<br>3. Bác sĩ không có ca nào khác đang khám dở. |
| **Hậu điều kiện** | 1. Thời điểm bắt đầu khám được ghi nhận trong lịch sử trạng thái; cân nặng, thân nhiệt và thông tin thăm khám lâm sàng ban đầu được lưu trữ.<br>2. Dịch vụ khám và mọi dịch vụ được chỉ định đều có **một hóa đơn dịch vụ riêng ở trạng thái "Chờ thanh toán"**, đã chốt cố định đơn giá và thuế suất tại thời điểm chỉ định.<br>3. **Nếu có chỉ định Cận lâm sàng:** Đợt khám chuyển sang trạng thái "Chờ kết quả cận lâm sàng"; Bác sĩ được giải phóng sang trạng thái "Sẵn sàng" để tiếp nhận ca tiếp theo; Phiếu chỉ định được đẩy sang hàng đợi phòng cận lâm sàng.<br>4. **Nếu không cần Cận lâm sàng:** Đợt khám giữ trạng thái "Đang khám" để tiếp tục xử lý và chốt đợt khám ngay trong một lần khám duy nhất. |
| **Chuỗi sự kiện chính** | 1. Bác sĩ mở màn hình hàng đợi của mình (danh sách ca theo số thứ tự) và nhấn "Gọi số tiếp theo". Hệ thống chọn ca đứng đầu hàng đợi, hiển thị số thứ tự và số phòng trên màn hình sảnh và gửi thông báo đến ứng dụng của chủ nuôi; ca vẫn "Chờ khám".<br>2. Bác sĩ nhấn nút "Bắt đầu khám" khi bệnh nhân bước vào phòng. Hệ thống thực hiện trong một giao dịch an toàn: cập nhật trạng thái đợt khám thành "Đang khám" và ghi lịch sử trạng thái (thời điểm bắt đầu khám); **tự động tạo chỉ định dịch vụ khám** (mặc định "Khám tổng quát") **kèm hóa đơn dịch vụ "Chờ thanh toán"** với đơn giá và thuế suất niêm yết hiện tại; chuyển Bác sĩ sang trạng thái "Đang bận" và mở giao diện Bệnh án điện tử.<br>3. Bác sĩ mở mục "Lịch sử bệnh án" để tra cứu tiền sử bệnh, dị ứng, các đợt tiêm phòng và đơn thuốc cũ của thú cưng.<br>4. Bác sĩ tiến hành thăm khám thực thể: Trực tiếp đặt thú cưng lên bàn cân và đo nhiệt độ trực tràng (ghi nhận cân nặng `weight_at_visit` và thân nhiệt `temperature` vào bệnh án), sau đó nghe tim phổi, kiểm tra niêm mạc, hạch bạch huyết và các triệu chứng thực thể.<br>5. Bác sĩ nhập thông tin ghi chú khám lâm sàng và nhận định chẩn đoán sơ bộ ban đầu.<br>6. Bác sĩ nghi ngờ bệnh lý, chuyển sang mục "Chỉ định dịch vụ" và chọn các dịch vụ cận lâm sàng cần làm (ví dụ: Xét nghiệm máu tổng quát, Siêu âm ổ bụng). Hệ thống hiển thị đơn giá niêm yết và thuế suất hiện hành của từng dịch vụ để Bác sĩ tư vấn chi phí cho chủ nuôi.<br>7. Bác sĩ nhấn nút "Xác nhận chỉ định & Chuyển phòng Cận lâm sàng".<br>8. Hệ thống thực hiện lưu chỉ định trong một giao dịch an toàn:<br>&nbsp;&nbsp;&nbsp;&nbsp;8.1. Kiểm tra Bác sĩ đã nhập cân nặng và thân nhiệt của thú cưng.<br>&nbsp;&nbsp;&nbsp;&nbsp;8.2. Lưu danh sách các dịch vụ cận lâm sàng được chỉ định vào đợt khám ở trạng thái "Chờ thực hiện".<br>&nbsp;&nbsp;&nbsp;&nbsp;8.3. **Với mỗi dịch vụ vừa chỉ định, lập một hóa đơn dịch vụ ở trạng thái "Chờ thanh toán"**, chốt cố định đơn giá và thuế suất tại thời điểm này (BR-19, BR-25, BR-27).<br>&nbsp;&nbsp;&nbsp;&nbsp;8.4. Ghi nhận dịch vụ khám của Giai đoạn 1 là "Đã hoàn thành"; cập nhật trạng thái đợt khám thành "Chờ kết quả cận lâm sàng".<br>&nbsp;&nbsp;&nbsp;&nbsp;8.5. Giải phóng trạng thái Bác sĩ về "Sẵn sàng" để có thể nhận ca tiếp theo trong hàng đợi.<br>&nbsp;&nbsp;&nbsp;&nbsp;8.6. Đẩy phiếu chỉ định sang hàng đợi thực hiện của Phòng Xét nghiệm và/hoặc Chẩn đoán hình ảnh (tùy loại dịch vụ được chỉ định).<br>&nbsp;&nbsp;&nbsp;&nbsp;8.7. Thông báo hướng dẫn chủ nuôi đưa thú cưng ra khu vực lấy mẫu / chụp chiếu.<br>&nbsp;&nbsp;&nbsp;&nbsp;8.8. Nếu xảy ra lỗi hệ thống, toàn bộ thao tác (kể cả các hóa đơn dịch vụ vừa lập) được hoàn tác và giữ nguyên trạng thái ca khám. |
| **Luồng rẽ nhánh** | **6a. Ca khám thông thường, tiêm phòng, tẩy giun hoặc thủ thuật (Không cần cận lâm sàng):** Tại Bước 6, Bác sĩ không chỉ định cận lâm sàng. Nếu cần thực hiện dịch vụ ngay tại phòng (tiêm vaccine, tẩy giun, tiêm thuốc, thay băng...), Bác sĩ chọn dịch vụ đó; hệ thống lưu chỉ định và **lập hóa đơn dịch vụ "Chờ thanh toán"** cho từng dịch vụ như Bước 8.3. Bác sĩ thực hiện xong bấm *"Đã thực hiện"* để ghi nhận dịch vụ hoàn thành. Sau đó Bác sĩ tiếp tục ca sử dụng UC-30_31_33 để kê đơn thuốc (nếu cần) và chốt đợt khám ngay trong buổi khám.<br>**6b. Bỏ một dịch vụ tại phòng đã chỉ định:** Nếu chủ nuôi từ chối một dịch vụ chưa thực hiện, Bác sĩ chọn *"Hủy dịch vụ"* kèm lý do; dịch vụ và hóa đơn dịch vụ tương ứng cùng chuyển "Đã hủy" trong một giao dịch (BR-33). |
| **Ngoại lệ** | **2.1. Gọi số nhưng bệnh nhân không có mặt:** Tại Bước 1, nếu đã gọi 2–3 lần mà bệnh nhân không vào phòng, Bác sĩ nhấn *"Đẩy lùi 1 bậc"*. Ca giữ trạng thái "Chờ khám", được xếp ra **ngay sau người kế tiếp** trong hàng đợi và số lần bị lùi tăng thêm 1 (không giới hạn); hệ thống gọi ngay người kế tiếp. Ca cấp cứu đã bị lùi được xếp như ca thường. Nếu phía sau không còn ai, ca giữ nguyên vị trí. Khách quay lại chỉ cần chờ tới lượt. Nếu khách đã bỏ về hẳn, Lễ tân hủy đợt khám (EX-03).<br>**5.1. Khách từ chối khám tiếp hoặc cần chuyển viện cấp cứu (không thu phí):** Bác sĩ chọn *"Hủy ca / Chuyển viện"* và nhập lý do. Thao tác chỉ được phép khi chưa có dịch vụ tại phòng nào "Đã hoàn thành". Hệ thống hủy mọi dịch vụ của ca cùng hóa đơn dịch vụ tương ứng, chuyển đợt khám sang "Đã hủy" và giải phóng Bác sĩ. Nếu phòng khám vẫn thu phí khám, hoặc đã thực hiện dịch vụ tại phòng, Bác sĩ chốt ca bình thường (UC-30_31_33) với chẩn đoán "chuyển viện".<br>**8.1. Chưa nhập cân nặng hoặc thân nhiệt:** Tại Bước 8.1, hệ thống chặn lại và yêu cầu Bác sĩ nhập đủ sinh hiệu trước khi chuyển phòng cận lâm sàng.<br>**8.2. Lỗi hệ thống khi chuyển phiếu chỉ định:** Tại Bước 8, nếu không thể đẩy phiếu chỉ định sang phòng cận lâm sàng, hệ thống hoàn tác toàn bộ giao dịch, giữ nguyên trạng thái "Đang khám" và hiển thị thông báo lỗi. |

---

### 10. UC-25 & UC-26: Tiếp nhận mẫu, Thực hiện Cận lâm sàng & Trả kết quả

| Thuộc tính | Nội dung chi tiết |
| :--- | :--- |
| **Tên Use case** | **UC-25_26: Tiếp nhận mẫu, Thực hiện Cận lâm sàng & Trả kết quả (Process Lab & Imaging Services)** |
| **Các yêu cầu liên quan** | BR-11, BR-21, BR-23, BR-24, BR-33, BR-34, REQ-PARACLINIC-01 |
| **Tác nhân chính** | Kỹ thuật viên Xét nghiệm (`LAB_TECHNICIAN`) / Kỹ thuật viên Chẩn đoán hình ảnh (`IMAGING_TECHNICIAN`) |
| **Điều kiện tiên quyết** | 1. Đợt khám đang ở trạng thái "Chờ kết quả cận lâm sàng".<br>2. Nhân sự phòng Cận lâm sàng tương ứng đã đăng nhập vào hệ thống với vai trò `LAB_TECHNICIAN` (đối với phòng Xét nghiệm) hoặc `IMAGING_TECHNICIAN` (đối với phòng Chẩn đoán hình ảnh). |
| **Hậu điều kiện** | 1. Kết quả xét nghiệm và/hoặc chẩn đoán hình ảnh được ghi nhận đầy đủ, chính xác kèm tệp ảnh và khoảng tham chiếu theo loài.<br>2. Trạng thái đợt khám tự động chuyển thành "Đã có kết quả".<br>3. Bác sĩ khám chính nhận được thông báo kết quả đã sẵn sàng để ưu tiên gọi lại bệnh nhân vào phòng khám. |
| **Chuỗi sự kiện chính** | 1. Nhân viên mở màn hình "Hàng đợi chỉ định Cận lâm sàng" của phòng chuyên môn tương ứng (Hàng đợi Xét nghiệm hoặc Hàng đợi Chẩn đoán hình ảnh). Dịch vụ tự vào hàng đợi phòng ngay khi Bác sĩ chỉ định (không cần ai xếp). Hệ thống sắp xếp danh sách chờ ở trạng thái `PENDING`: ca cấp cứu chưa bị đẩy lùi lên đầu kèm viền đỏ cảnh báo; tiếp theo là các ca theo thứ tự thời gian Bác sĩ gửi chỉ định, có tính các lần bị đẩy lùi 1 bậc.<br>2. Nhân viên bấm nút "Gọi số tiếp theo": hệ thống chọn dịch vụ đứng đầu hàng đợi của phòng, hiển thị thông báo gọi số trên màn hình sảnh và gửi thông báo đến ứng dụng của chủ nuôi. Dịch vụ vẫn ở trạng thái "Chờ thực hiện". Khi thú cưng bước vào phòng, nhân viên bấm nút "Bắt đầu thực hiện", hệ thống cập nhật trạng thái chỉ định dịch vụ sang *Đang thực hiện* và ghi lịch sử thao tác.<br>3. Nhân viên thực hiện thao tác chuyên môn: Kỹ thuật viên Lab lấy ven máu, nạp mẫu vào máy phân tích huyết học tự động rồi bấm **"Đã lấy mẫu"** (hệ thống ghi nhận thú cưng đã rời phòng Lab, phòng CĐHA có thể gọi); hoặc Bác sĩ CĐHA quét siêu âm/chụp X-quang.<br>4. Nhân viên mở biểu mẫu nhập kết quả trên hệ thống:<br>&nbsp;&nbsp;&nbsp;&nbsp;4.1. Đối với xét nghiệm: Hệ thống hiển thị danh sách các chỉ số thuộc gói xét nghiệm đã chỉ định. Khi máy in kết quả, nhân viên nhập giá trị từng chỉ số (WBC, RBC...). Hệ thống tự động lấy khoảng tham chiếu chuẩn của loài tương ứng (Chó/Mèo), lưu cố định cùng kết quả và hiển thị đánh giá: Thấp (vàng), Bình thường (xanh), Cao (đỏ). Đánh giá này được tính khi hiển thị, không lưu riêng.<br>&nbsp;&nbsp;&nbsp;&nbsp;4.2. Đối với chẩn đoán hình ảnh: Nhập mô tả giải phẫu, kết luận hình thái học và tải các tệp hình ảnh thực tế lên hệ thống.<br>5. Nhân viên nhập nhận xét chuyên môn và nhấn "Lưu & Xác nhận kết quả".<br>6. Hệ thống thực hiện cập nhật kết quả trong một giao dịch an toàn:<br>&nbsp;&nbsp;&nbsp;&nbsp;6.1. Lưu trữ kết quả đo đạc xét nghiệm (kèm khoảng tham chiếu cố định) hoặc kết quả mô tả, kết luận và tệp ảnh chẩn đoán hình ảnh.<br>&nbsp;&nbsp;&nbsp;&nbsp;6.2. Cập nhật trạng thái chỉ định dịch vụ này sang *Đã hoàn thành*. Hóa đơn dịch vụ tương ứng giữ trạng thái "Chờ thanh toán".<br>&nbsp;&nbsp;&nbsp;&nbsp;6.3. Kiểm tra: Nếu tất cả dịch vụ cận lâm sàng được chỉ định trong đợt khám này đều đã kết thúc (Đã hoàn thành hoặc Đã hủy) thì tự động chuyển trạng thái đợt khám thành "Đã có kết quả", tự động đưa ca khám lên đầu hàng đợi của Bác sĩ khám chính (chỉ sau ca cấp cứu), hiển thị huy hiệu thông báo nhẹ (Notification Badge) lên màn hình Bác sĩ và gửi thông báo hướng dẫn chủ nuôi tiếp tục ngồi chờ tại sảnh phòng khám.<br>&nbsp;&nbsp;&nbsp;&nbsp;6.4. Nhân viên hoàn tất ca và mời ca tiếp theo trong hàng đợi của phòng mình. Nếu xảy ra sự cố lưu trữ, hệ thống hoàn tác toàn bộ thao tác và thông báo lỗi. |
| **Luồng rẽ nhánh** | **2a. Gọi số nhưng khách chưa vào phòng – Đẩy lùi 1 bậc:** Tại Bước 2, nếu đã thông báo gọi 2–3 lần mà chủ nuôi chưa đưa thú cưng vào, nhân viên bấm *"Đẩy lùi 1 bậc"*. Dịch vụ **giữ nguyên "Chờ thực hiện"** (chưa tốn vật tư), được xếp ra ngay sau người kế tiếp trong hàng đợi của phòng, số lần bị lùi tăng thêm 1 (không giới hạn) và hệ thống ghi lịch sử thao tác "Đẩy lùi". Hệ thống gọi ngay người kế tiếp để không làm treo phòng máy và gửi thông báo đến ứng dụng của chủ nuôi. Khi khách quay lại, khách chờ tới lượt mới (không cần thao tác gì thêm); khi được gọi và thú cưng vào phòng, nhân viên bấm *"Bắt đầu thực hiện"* như bình thường.<br>**4a. Thực hiện dịch vụ Chẩn đoán hình ảnh (Siêu âm hoặc Chụp X-quang):** Thú cưng được đưa vào phòng CĐHA. Bác sĩ chẩn đoán hình ảnh bấm "Bắt đầu chụp/siêu âm" (`IN_PROGRESS`), thực hiện quét/chụp phim, nhập kết quả mô tả, tải tệp ảnh lên và bấm "Lưu & Xác nhận kết quả" (`COMPLETED`).<br>**4b. Điều phối ca khám có chỉ định đồng thời tại cả 2 phòng (Quy trình song song & Huy hiệu liên phòng):**<br>1. Đối với ca khám được chỉ định đồng thời cả Xét nghiệm máu và Siêu âm/X-quang, ca xuất hiện đồng thời trên cả 2 hàng đợi. Hệ thống hướng dẫn chủ nuôi đưa thú cưng vào Phòng Xét nghiệm lấy mẫu máu trước (2–3 phút). Trong lúc máy phân tích huyết học tự động chạy phân tích (15–20 phút), thú cưng được đưa sang phòng CĐHA để thực hiện Siêu âm hoặc Chụp X-quang (10–15 phút), giúp hai quy trình diễn ra song song.<br>2. Trên màn hình CĐHA hiển thị huy hiệu trạng thái liên phòng, dựa trên thao tác gần nhất của KTV Lab: `[Đang lấy máu bên phòng Lab]` (KTV Lab đã bấm "Bắt đầu thực hiện" nhưng chưa bấm "Đã lấy mẫu") hoặc `[Đã lấy máu, sẵn sàng chụp]` (KTV Lab đã bấm "Đã lấy mẫu", máy đang phân tích). Nếu phòng CĐHA đến lượt gọi mà thú cưng chưa sang (đang lấy máu), Bác sĩ CĐHA bấm *"Đẩy lùi 1 bậc"*: dịch vụ CĐHA giữ `PENDING`, xếp ra sau người kế tiếp và phòng gọi ngay người đó, không làm treo phòng máy.<br>**4c. Khách hàng xin hủy 1 trong 2 dịch vụ giữa chừng:** Tại Bước 3 hoặc Bước 4, nếu chủ nuôi xin hủy không siêu âm nữa sau khi đã làm xét nghiệm máu, Bác sĩ CĐHA chọn thao tác *"Hủy dịch vụ"* kèm lý do $\rightarrow$ Trong cùng một giao dịch, dịch vụ Siêu âm chuyển sang "Đã hủy" **và hóa đơn dịch vụ của Siêu âm cũng chuyển "Đã hủy"** (BR-33). Hệ thống kiểm tra tất cả dịch vụ còn lại đều đã hoàn thành $\rightarrow$ Tự động chuyển ca sang "Đã có kết quả" để Bác sĩ khám chính hội chẩn với kết quả xét nghiệm máu đã làm. Khách chỉ phải trả hóa đơn của các dịch vụ không bị hủy.<br>**4d. Khách bỏ về giữa chừng khi cận lâm sàng chưa xong (EX-11):** Khi không còn dịch vụ nào đang thực hiện dở, Lễ tân chọn *"Đóng ca / Khách bỏ về"*. Dịch vụ còn "Chờ thực hiện" bị hủy cùng hóa đơn của chúng; hóa đơn của các dịch vụ đã thực hiện (khám, xét nghiệm đã có kết quả) giữ "Chờ thanh toán" làm công nợ; đợt khám chuyển "Đã hoàn thành" và kết quả được lưu vào bệnh án. |
| **Ngoại lệ** | **4.1. Lỗi tải tệp ảnh chẩn đoán hình ảnh:** Tại Luồng 4a, nếu tệp tải lên vượt quá dung lượng cho phép hoặc sai định dạng ảnh, hệ thống thông báo lỗi cụ thể và yêu cầu chọn lại tệp hợp lệ.<br>**4.2. Không thực hiện được dịch vụ đang làm (thiết bị sự cố, không lấy được mẫu):** Nhân viên chọn *"Hủy dịch vụ"* kèm lý do; dịch vụ và hóa đơn dịch vụ tương ứng cùng chuyển "Đã hủy", sau đó hệ thống kiểm tra lại điều kiện chuyển ca sang "Đã có kết quả" như Bước 6.3.<br>**4.3. Hủy dịch vụ đã được thanh toán:** Nếu hóa đơn của dịch vụ đã ở trạng thái "Đã thanh toán", hệ thống không cho hủy (hoàn tiền nằm ngoài phạm vi hệ thống). |

---

### 11. UC-30, UC-31 & UC-33: Hội chẩn kết quả, Kê đơn & Chốt đợt khám (Giai đoạn 2)

| Thuộc tính | Nội dung chi tiết |
| :--- | :--- |
| **Tên Use case** | **UC-30_31_33: Hội chẩn kết quả, Chẩn đoán xác định, Kê đơn & Chốt đợt khám (Final Clinical Diagnosis & Visit Closing)** |
| **Các yêu cầu liên quan** | BR-12, BR-18, BR-19, BR-30, BR-32, BR-34, REQ-PRESCRIPTION-01 |
| **Tác nhân chính** | Bác sĩ thú y (Bác sĩ khám chính) |
| **Điều kiện tiên quyết** | 1. Đợt khám đang ở trạng thái "Đã có kết quả" (hoặc đang ở trạng thái "Đang khám" nếu là ca bệnh nhẹ không qua cận lâm sàng).<br>2. Bác sĩ khám chính đang làm việc tại phòng khám cố định của mình và không đang khám ca khác. |
| **Hậu điều kiện** | 1. Đợt khám được cập nhật chẩn đoán xác định, phác đồ điều trị và lời dặn dò chủ nuôi.<br>2. Đơn thuốc điện tử (nếu có) được ghi nhận gồm thuốc, số lượng, liều dùng; **đơn thuốc không chứa giá bán và không có trạng thái cấp phát** (giá chỉ được chốt khi khách mua tại phòng khám ở UC-36).<br>3. Đợt khám chuyển sang trạng thái "Chờ thanh toán"; thời điểm chốt ca được ghi trong lịch sử trạng thái.<br>4. Bác sĩ được giải phóng sang trạng thái "Sẵn sàng" để tiếp nhận bệnh nhân tiếp theo.<br>5. Toàn bộ hồ sơ bệnh án chuyên môn bị khóa, không được tự ý sửa đổi. |
| **Chuỗi sự kiện chính** | 1. Khi tất cả dịch vụ cận lâm sàng của một ca hoàn tất, hệ thống chuyển ca sang "Đã có kết quả" và **tự đưa ca lên đầu hàng đợi của Bác sĩ khám chính** (chỉ sau ca cấp cứu), hiển thị huy hiệu "Có kết quả" trên màn hình Bác sĩ. Lễ tân vẫn xếp ca mới vào hàng đợi bình thường; ca có kết quả được gọi trước.<br>2. Khi khám xong ca hiện tại, Bác sĩ nhấn "Gọi số tiếp theo". Hệ thống gọi ca đứng đầu hàng đợi (ca có kết quả) trên màn hình sảnh và gửi thông báo đến ứng dụng của chủ nuôi: *"Mời thú cưng [Tên Pet] vào lại phòng khám [Số phòng] gặp Bác sĩ"*. Khi thú cưng vào phòng, Bác sĩ nhấn "Bắt đầu Giai đoạn 2": hệ thống cập nhật trạng thái đợt khám thành "Đang khám", chuyển trạng thái bác sĩ sang "Đang bận" và mở giao diện tổng hợp toàn bộ kết quả bệnh án.<br>3. Bác sĩ phân tích kết quả: Xem bảng các chỉ số máu (chú ý các chỉ số cảnh báo Cao hoặc Thấp), xem hình ảnh siêu âm/X-quang và kết luận hình thái học.<br>4. Bác sĩ tổng hợp với triệu chứng lâm sàng đã thăm khám ở Giai đoạn 1; nhập Chẩn đoán xác định, Phác đồ điều trị và Lời dặn dò cho chủ nuôi.<br>5. Bác sĩ chuyển sang mục "Kê đơn thuốc" và nhấn "Thêm thuốc vào đơn". Hệ thống hiển thị danh mục thuốc kèm thông tin hoạt chất, đơn vị tính, giá bán tham khảo và số lượng tồn kho hiện tại.<br>6. Bác sĩ tìm kiếm và chọn thuốc cần kê (ví dụ: *Clavamox 250mg*). Nhập số lượng kê, liều dùng, tần suất và số ngày sử dụng. Hệ thống so sánh số lượng kê với tồn kho hiện tại; nếu không đủ chỉ hiển thị cảnh báo (BR-30), Bác sĩ vẫn được giữ nguyên vì khách có quyền mua thuốc ở nơi khác (BR-32).<br>7. Bác sĩ lặp lại Bước 6 cho các loại thuốc khác nếu có, sau đó nhấn nút "Lưu đơn thuốc".<br>8. Bác sĩ giải thích tình trạng bệnh cho chủ nuôi, hướng dẫn dùng thuốc (thông báo khách có thể mua tại quầy thuốc của phòng khám hoặc mua ngoài) và nhấn nút "Chốt đợt khám / Chuyển thanh toán". Hệ thống hiển thị hộp thoại xác nhận: *"Bạn có chắc chắn muốn chốt chuyên môn và chuyển đợt khám sang thanh toán? Sau khi chốt, hồ sơ bệnh án sẽ bị khóa chỉnh sửa."*<br>9. Bác sĩ nhấn "Xác nhận chốt".<br>10. Hệ thống thực hiện chốt đợt khám trong một giao dịch an toàn:<br>&nbsp;&nbsp;&nbsp;&nbsp;10.1. Kiểm tra đã nhập chẩn đoán và mọi dịch vụ thực hiện tại phòng đã "Đã hoàn thành" hoặc "Đã hủy".<br>&nbsp;&nbsp;&nbsp;&nbsp;10.2. Lưu trữ kết luận chẩn đoán xác định, phác đồ điều trị, dặn dò và đơn thuốc điện tử (không kèm giá).<br>&nbsp;&nbsp;&nbsp;&nbsp;10.3. Cập nhật trạng thái đợt khám thành "Chờ thanh toán" và ghi lịch sử trạng thái (thời điểm chốt ca, Bác sĩ thực hiện). Các hóa đơn dịch vụ đã được lập từ lúc chỉ định, không lập thêm hóa đơn ở bước này.<br>&nbsp;&nbsp;&nbsp;&nbsp;10.4. Giải phóng trạng thái Bác sĩ về "Sẵn sàng".<br>&nbsp;&nbsp;&nbsp;&nbsp;10.5. Khóa quyền chỉnh sửa chuyên môn của đợt khám.<br>&nbsp;&nbsp;&nbsp;&nbsp;10.6. Chuyển thông tin đợt khám sang danh sách chờ thanh toán của bộ phận Thu ngân.<br>&nbsp;&nbsp;&nbsp;&nbsp;10.7. Nếu xảy ra lỗi trong quá trình xử lý, hệ thống hoàn tác toàn bộ thao tác để đảm bảo tính nhất quán dữ liệu. |
| **Luồng rẽ nhánh** | **2a. Gọi số nhưng khách chưa vào phòng – Đẩy lùi 1 bậc (EX-10):** Tại Bước 2, nếu đã thông báo 2–3 lần mà chủ nuôi chưa đưa thú cưng vào (ca vẫn "Đã có kết quả", Bác sĩ chưa bấm "Bắt đầu Giai đoạn 2"), Bác sĩ nhấn *"Đẩy lùi 1 bậc"*. Ca được xếp ra ngay sau người kế tiếp trong hàng đợi của Bác sĩ, số lần bị lùi tăng thêm 1 (không giới hạn); hệ thống gọi ngay người kế tiếp. Khi khách quay lại, khách chờ tới lượt; Bác sĩ gọi đến thì tiếp tục Giai đoạn 2 như Bước 2.<br>**4a. Thực hiện thêm dịch vụ tại phòng ở Giai đoạn 2:** Nếu cần tiêm thuốc, truyền dịch hoặc thủ thuật, Bác sĩ chỉ định dịch vụ; hệ thống lập hóa đơn dịch vụ "Chờ thanh toán" cho từng dịch vụ (như UC-22_23 Luồng 6a). Bác sĩ thực hiện xong bấm *"Đã thực hiện"*.<br>**5a. Không kê đơn thuốc:** Bác sĩ bỏ qua Bước 5–7 và chốt ca trực tiếp ở Bước 8.<br>**11a. Mở lại hồ sơ khi đang chờ thanh toán:** Khi phát hiện sai sót sau khi chốt (Thu ngân chuyển yêu cầu ở UC-34_35, Ngoại lệ 5.1), Bác sĩ phụ trách hoặc Quản trị viên chọn *"Mở lại hồ sơ"* và nhập lý do (bắt buộc). Điều kiện: đợt khám chưa "Đã hoàn thành" và Bác sĩ không đang khám ca khác. Hệ thống chuyển đợt khám về "Đang khám" và ghi lịch sử kèm lý do. Hóa đơn đã thanh toán giữ nguyên; dịch vụ bị bỏ thì hủy kèm hóa đơn của nó; dịch vụ thêm mới được lập hóa đơn mới. Nếu đơn thuốc đã có hóa đơn thuốc chưa hủy (đang chờ thanh toán hoặc đã thanh toán) thì không được sửa đơn thuốc. Bác sĩ sửa xong chốt lại từ Bước 8. |
| **Ngoại lệ** | **2.2. Khách hàng bỏ về hẳn không quay lại đọc kết quả (EX-11):** Tại Bước 2 hoặc Luồng 2a, nếu khách tự ý bỏ về và Lễ tân liên hệ điện thoại xác nhận không quay lại (hoặc đã hết ngày làm việc), Lễ tân hoặc Bác sĩ chọn thao tác *"Đóng ca / Khách bỏ về"*. Hệ thống khóa chuyên môn, lưu trữ vĩnh viễn các kết quả cận lâm sàng đã làm vào lịch sử bệnh án và chuyển đợt khám sang "Đã hoàn thành". **Hệ thống không lập hóa đơn mới**: các hóa đơn của dịch vụ đã thực hiện vẫn ở trạng thái "Chờ thanh toán" và được giữ làm công nợ để thu ở lần đến sau (UC-34_35, Luồng 1a).<br>**6.1. Số lượng thuốc kê vượt quá tồn kho hiện tại (EX-13):** Tại Bước 6, hệ thống chỉ cảnh báo: *"Tồn kho hiện tại không đủ số lượng kê. Khách có thể phải mua thuốc này ở nơi khác"*. Bác sĩ chọn giữ nguyên hoặc giảm số lượng / kê thuốc thay thế; hệ thống không chặn việc lưu đơn.<br>**8.1. Chưa nhập chẩn đoán xác định hoặc còn dịch vụ tại phòng chưa xử lý (EX-12):** Tại Bước 8, nếu thông tin chẩn đoán đang để trống hoặc còn dịch vụ tại phòng chưa hoàn thành / chưa hủy, hệ thống chặn lại và thông báo: *"Vui lòng nhập kết luận chẩn đoán và hoàn tất các dịch vụ đã chỉ định trước khi chốt đợt khám"*.<br>**10.1. Lỗi giao dịch khi chốt đợt khám:** Tại Bước 10, nếu hệ thống gặp lỗi kết nối hoặc lưu trữ, hệ thống hoàn tác thao tác, đợt khám vẫn giữ trạng thái "Đang khám" và thông báo để Bác sĩ thử lại. |

---

### 12. UC-34 & UC-35: Thu tiền hóa đơn dịch vụ & Xác nhận thanh toán

| Thuộc tính | Nội dung chi tiết |
| :--- | :--- |
| **Tên Use case** | **UC-34_35: Thu tiền hóa đơn dịch vụ & Xác nhận thanh toán (Service Invoice Payment)** |
| **Các yêu cầu liên quan** | BR-19, BR-21, BR-27, BR-28, BR-33, REQ-BILLING-01 |
| **Tác nhân chính** | Lễ tân / Thu ngân |
| **Tác nhân phụ** | Chủ thú cưng (Người thanh toán) |
| **Điều kiện tiên quyết** | 1. Đợt khám đang ở trạng thái "Chờ thanh toán" (hoặc đã "Đã hoàn thành" nhưng còn hóa đơn dịch vụ chưa thanh toán do khách bỏ về trước đó – EX-11).<br>2. Đợt khám có ít nhất một hóa đơn dịch vụ ở trạng thái "Chờ thanh toán" (các hóa đơn này đã được hệ thống lập tự động lúc Bác sĩ chỉ định dịch vụ).<br>3. Thu ngân đã đăng nhập vào hệ thống với vai trò Lễ tân / Thu ngân. |
| **Hậu điều kiện** | 1. Các hóa đơn dịch vụ được xác nhận chuyển sang trạng thái "Đã thanh toán", ghi nhận thời điểm thu tiền và nhân viên thu ngân.<br>2. Nếu sau lần xác nhận này **mọi hóa đơn dịch vụ của đợt khám đều "Đã thanh toán" hoặc "Đã hủy"**, đợt khám chuyển sang "Đã hoàn thành" trong cùng giao dịch và trở thành một bản ghi hoàn chỉnh trong **Lịch sử bệnh án** của thú cưng (BR-28).<br>3. Việc khách có mua thuốc hay không **không ảnh hưởng** tới trạng thái đợt khám. Nếu đợt khám có đơn thuốc, hệ thống gợi ý chuyển sang UC-36 khi khách chọn mua tại phòng khám. |
| **Chuỗi sự kiện chính** | 1. Thu ngân mở màn hình danh sách chờ thanh toán tại quầy. Hệ thống hiển thị các đợt khám đang ở trạng thái "Chờ thanh toán" (kèm bộ lọc tìm đợt khám còn công nợ).<br>2. Thu ngân chọn ca khám của khách hàng đang có mặt tại quầy. Hệ thống hiển thị **bảng kê các hóa đơn dịch vụ** của ca: mã hóa đơn, tên dịch vụ, số lượng, đơn giá và thuế suất đã chốt lúc chỉ định, giảm giá, số tiền phải trả và trạng thái của từng hóa đơn. Hệ thống tính **tổng số tiền cần thu = tổng số tiền phải trả của các hóa đơn đang "Chờ thanh toán"**; số tiền mỗi hóa đơn được tính từ số lượng × đơn giá × (1 + thuế suất) − giảm giá, không lưu thành số liệu riêng. Hóa đơn "Đã hủy" được hiển thị mờ và không tính tiền.<br>3. Thu ngân kiểm tra các khoản mục chi phí cùng khách hàng. Nếu có chính sách ưu đãi, Thu ngân nhập số tiền giảm giá **trên từng hóa đơn dịch vụ** được ưu đãi; hệ thống tính lại số tiền của hóa đơn đó và tổng số tiền cần thu.<br>4. Khách hàng thực hiện thanh toán bên ngoài quầy (trả tiền mặt hoặc tự chuyển khoản trực tiếp vào tài khoản ngân hàng của phòng khám).<br>5. Sau khi nhận đủ tiền hoặc xác nhận tiền đã về tài khoản, Thu ngân nhấn nút "Xác nhận thanh toán" cho các hóa đơn đang chờ của ca (chưa cần chọn phương thức thanh toán).<br>6. Hệ thống thực hiện xử lý thanh toán trong một giao dịch an toàn:<br>&nbsp;&nbsp;&nbsp;&nbsp;6.1. Kiểm tra từng hóa đơn vẫn đang ở trạng thái "Chờ thanh toán" và chưa bị người khác cập nhật trong lúc thao tác.<br>&nbsp;&nbsp;&nbsp;&nbsp;6.2. Chuyển từng hóa đơn sang "Đã thanh toán", ghi nhận thời điểm thu tiền và nhân viên thu ngân thực hiện.<br>&nbsp;&nbsp;&nbsp;&nbsp;6.3. Kiểm tra toàn bộ hóa đơn dịch vụ của đợt khám: nếu tất cả đều "Đã thanh toán" hoặc "Đã hủy" và đợt khám đang "Chờ thanh toán" thì chuyển đợt khám sang "Đã hoàn thành" và ghi lịch sử trạng thái.<br>&nbsp;&nbsp;&nbsp;&nbsp;6.4. Hiển thị tùy chọn in phiếu thu dịch vụ cho khách hàng.<br>&nbsp;&nbsp;&nbsp;&nbsp;6.5. Nếu xảy ra lỗi trong quá trình ghi nhận, toàn bộ thao tác được hoàn tác và thông báo thanh toán thất bại.<br>7. Nếu đợt khám có đơn thuốc, hệ thống hỏi: *"Khách có muốn mua thuốc theo đơn tại phòng khám không?"*. Chọn "Có" để chuyển sang UC-36; chọn "Không" để in đơn thuốc cho khách mua ngoài. |
| **Luồng rẽ nhánh** | **1a. Thu công nợ của đợt khám đã đóng (EX-11):** Ở lần khách đến sau, Thu ngân tìm đợt khám cũ còn công nợ, thực hiện Bước 2–6 với các hóa đơn dịch vụ còn "Chờ thanh toán". Trạng thái đợt khám giữ nguyên "Đã hoàn thành".<br>**3a. Khách hàng yêu cầu in bảng kê chi phí trước khi thanh toán:** Tại Bước 3, Thu ngân nhấn nút "In phiếu tạm tính". Hệ thống xuất bảng kê các hóa đơn dịch vụ để khách hàng kiểm tra đối chiếu trước khi trả tiền ngoài quầy.<br>**7a. Đợt khám không có đơn thuốc:** Hệ thống bỏ qua Bước 7; khách nhận phiếu thu và ra về. |
| **Ngoại lệ** | **3.1. Số tiền giảm giá vượt quá số tiền của hóa đơn (EX-14):** Tại Bước 3, nếu giảm giá nhập cho một hóa đơn lớn hơn số tiền trước giảm của chính hóa đơn đó, hệ thống chặn lại và cảnh báo: *"Số tiền giảm giá không được vượt quá số tiền của hóa đơn dịch vụ này"*.<br>**5.1. Phát hiện sai sót cần điều chỉnh chuyên môn:** Nếu khách hàng thắc mắc về một chỉ định dịch vụ nhầm lẫn, Thu ngân không được tự ý sửa hoặc hủy hóa đơn, mà chuyển yêu cầu để Bác sĩ phụ trách thực hiện *"Mở lại hồ sơ"* (UC-30_31_33, Luồng 11a). Bác sĩ hủy dịch vụ nhầm (hóa đơn của dịch vụ đó tự chuyển "Đã hủy") rồi chốt lại ca.<br>**6.1. Hóa đơn vừa được người khác xác nhận:** Tại Bước 6.1, nếu một hóa đơn đã chuyển "Đã thanh toán" bởi thao tác khác trong cùng thời điểm, hệ thống từ chối và tải lại bảng kê để tránh thu trùng.<br>**6.2. Lỗi hệ thống khi lưu thanh toán:** Tại Bước 6, nếu hệ thống không thể ghi nhận, giao dịch bị hoàn tác hoàn toàn, các hóa đơn và đợt khám giữ nguyên trạng thái cũ, hệ thống hiển thị thông báo lỗi. |

---

### 13. UC-36: Bán thuốc theo đơn (tùy chọn) & Trừ tồn kho

| Thuộc tính | Nội dung chi tiết |
| :--- | :--- |
| **Tên Use case** | **UC-36: Bán thuốc theo đơn (tùy chọn) & Trừ tồn kho (Sell Prescribed Medicines & Deduct Stock)** |
| **Các yêu cầu liên quan** | BR-21, BR-26, BR-29, BR-30, BR-31, BR-32, REQ-INVENTORY-01 |
| **Tác nhân chính** | Lễ tân / Thu ngân |
| **Tác nhân phụ** | Chủ thú cưng (Người mua thuốc) |
| **Điều kiện tiên quyết** | 1. Đợt khám có đơn thuốc và Bác sĩ đã chốt chuyên môn (đợt khám ở trạng thái "Chờ thanh toán" hoặc "Đã hoàn thành"), nên đơn thuốc không còn bị thay đổi.<br>2. Chủ thú cưng **chọn mua thuốc tại phòng khám** (việc mua là tùy chọn, BR-32).<br>3. Đơn thuốc chưa từng được lập hóa đơn thuốc trước đó (BR-31). |
| **Hậu điều kiện** | 1. Một hóa đơn thuốc được lập cho đơn thuốc, gồm các thuốc và số lượng khách thực mua (có thể ít hơn số lượng kê), với đơn giá và thuế suất chốt tại thời điểm lập (BR-26).<br>2. Hóa đơn thuốc ở trạng thái "Đã thanh toán"; **trong cùng giao dịch**, tồn kho các thuốc đã bán bị trừ tương ứng và lịch sử biến động kho được ghi nhận loại "Xuất bán" (BR-29).<br>3. Trạng thái đợt khám **không thay đổi**. |
| **Chuỗi sự kiện chính** | 1. Từ UC-35 (Bước 7) hoặc từ danh sách đơn thuốc chưa bán, Thu ngân chọn chức năng "Bán thuốc theo đơn". Hệ thống hiển thị chi tiết đơn thuốc: tên thuốc, hoạt chất, số lượng kê, liều dùng, giá bán hiện tại và số lượng tồn kho hiện tại của từng thuốc.<br>2. Thu ngân hỏi khách muốn mua những thuốc nào và số lượng bao nhiêu. Khách có thể mua toàn bộ đơn hoặc chỉ một phần.<br>3. Thu ngân chọn các thuốc khách mua và nhập số lượng (mặc định bằng số lượng kê), rồi nhấn "Lập hóa đơn thuốc".<br>4. Hệ thống kiểm tra số lượng mua của từng thuốc không vượt số lượng kê, lập **hóa đơn thuốc ở trạng thái "Chờ thanh toán"** với mã hóa đơn duy nhất, chốt cố định đơn giá và thuế suất của từng thuốc tại thời điểm này, rồi hiển thị số tiền phải trả (tính từ số lượng × đơn giá × (1 + thuế suất) của các dòng thuốc, trừ giảm giá).<br>5. Nếu có ưu đãi, Thu ngân nhập số tiền giảm giá cho hóa đơn thuốc; hệ thống tính lại số tiền phải trả.<br>6. Thu ngân lấy đúng chủng loại và đủ số lượng thuốc từ tủ thuốc, kiểm tra hạn sử dụng và dán nhãn hướng dẫn liều dùng.<br>7. Khách hàng thanh toán tiền thuốc bên ngoài quầy (tiền mặt hoặc chuyển khoản).<br>8. Thu ngân nhấn nút "Xác nhận thanh toán & Xuất thuốc".<br>9. Hệ thống thực hiện quy trình bán thuốc trong **một giao dịch an toàn**:<br>&nbsp;&nbsp;&nbsp;&nbsp;9.1. Kiểm tra hóa đơn thuốc vẫn đang "Chờ thanh toán" và chưa bị người khác cập nhật.<br>&nbsp;&nbsp;&nbsp;&nbsp;9.2. Với từng thuốc trong hóa đơn, trừ tồn kho theo số lượng bán với điều kiện tồn kho tại đúng thời điểm này vẫn đủ.<br>&nbsp;&nbsp;&nbsp;&nbsp;9.3. Ghi nhận lịch sử biến động kho loại "Xuất bán" cho từng thuốc, liên kết với hóa đơn thuốc.<br>&nbsp;&nbsp;&nbsp;&nbsp;9.4. Chuyển hóa đơn thuốc sang "Đã thanh toán", ghi nhận thời điểm thu tiền và nhân viên thu ngân.<br>&nbsp;&nbsp;&nbsp;&nbsp;9.5. Nếu bất kỳ bước nào thất bại, hệ thống hoàn tác toàn bộ giao dịch (không trừ kho, không ghi lịch sử, hóa đơn giữ "Chờ thanh toán").<br>10. Giao dịch thành công, Thu ngân bàn giao thuốc, dặn dò cách dùng theo chỉ dẫn của Bác sĩ; hệ thống in hóa đơn thuốc và phiếu hướng dẫn dùng thuốc trao tay cho khách hàng. |
| **Luồng rẽ nhánh** | **2a. Khách chọn mua thuốc ở nơi khác:** Tại Bước 2, khách không mua thuốc tại phòng khám. Thu ngân in đơn thuốc trao cho khách; hệ thống không lập hóa đơn thuốc và không thay đổi tồn kho. Use case kết thúc.<br>**2b. Khách chỉ mua một phần đơn:** Tại Bước 3, Thu ngân bỏ chọn các thuốc khách không mua hoặc giảm số lượng; phần còn lại khách tự mua ngoài theo đơn in.<br>**7a. Khách đổi ý trước khi thanh toán:** Nếu khách không mua nữa sau khi hóa đơn thuốc đã được lập, Thu ngân chọn "Hủy hóa đơn thuốc". Hệ thống chuyển hóa đơn sang "Đã hủy", tồn kho không thay đổi; Thu ngân in đơn thuốc cho khách mua ngoài. Hủy là thao tác kết thúc: đơn thuốc này không lập lại hóa đơn thuốc.<br>**9a. Sửa hóa đơn thuốc đang chờ thanh toán:** Khi khách muốn bớt thuốc hoặc sau ngoại lệ 9.1, Thu ngân chọn "Sửa hóa đơn thuốc", giảm số lượng hoặc bỏ dòng thuốc (vẫn ≤ số lượng kê, còn ít nhất 1 dòng). Hệ thống giữ nguyên đơn giá và thuế suất đã chốt của các dòng còn lại, kiểm tra lại giảm giá (EX-14), tính lại số tiền phải trả; sau đó quay lại Bước 6. |
| **Ngoại lệ** | **4.1. Số lượng mua vượt số lượng kê:** Tại Bước 4, hệ thống chặn và thông báo: *"Số lượng mua không được vượt quá số lượng Bác sĩ đã kê"*.<br>**5.1. Giảm giá vượt quá tiền thuốc (EX-14):** Tại Bước 5, nếu giảm giá lớn hơn tổng tiền thuốc trước giảm, hệ thống chặn và yêu cầu nhập lại.<br>**9.1. Tồn kho thực tế không đủ tại thời điểm xác nhận (EX-15):** Tại Bước 9.2, nếu một thuốc vừa bị thiếu (ví dụ: quầy khác vừa bán cùng lúc), hệ thống hoàn tác toàn bộ giao dịch và thông báo: *"Thuốc [Tên thuốc] hiện không đủ tồn kho. Vui lòng giảm số lượng hoặc bỏ thuốc này khỏi hóa đơn"*. Hóa đơn thuốc giữ "Chờ thanh toán"; Thu ngân sửa chính hóa đơn này (Luồng 9a) hoặc hủy hóa đơn để khách mua ngoài (Luồng 7a). Vì chưa có khoản nào được ghi nhận "Đã thanh toán", không phát sinh nghiệp vụ hoàn tiền; Thu ngân chỉ thu theo số tiền mới hoặc trả lại tiền thuốc vừa nhận.<br>**1.1. Đơn thuốc đã có hóa đơn thuốc / đã bán (EX-16):** Tại Bước 1 hoặc Bước 9.1, nếu đơn thuốc đã từng được lập hóa đơn thuốc (kể cả hóa đơn đã hủy), hoặc hóa đơn đã "Đã thanh toán", hệ thống chặn lại và thông báo: *"Đơn thuốc này đã có hóa đơn thuốc"* (BR-31). Muốn đổi số lượng thì sửa hóa đơn đang chờ (Luồng 9a).<br>**9.2. Lỗi giao dịch hệ thống khi trừ kho:** Nếu xảy ra sự cố kỹ thuật trong quá trình ghi nhật ký biến động kho, hệ thống tự động hoàn tác toàn bộ giao dịch, giữ nguyên tồn kho và trạng thái hóa đơn thuốc, đồng thời thông báo thất bại. |

---

## PHẦN III: TỔNG HỢP MA TRẬN TRUY VẾT THỰC THỂ NGHIỆP VỤ (CRUD MATRIX)

| Thực thể nghiệp vụ | UC-14 | UC-15 | UC-16 | UC-17 | UC-18 | UC-19 | UC-20 | UC-21 | UC-22_23 | UC-25_26 | UC-30_31_33 | UC-34_35 | UC-36 |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Người dùng / Khách hàng** | Xem | Xem | Xem, Tạo | Xem | Tạo, Cập nhật | Tạo, Xem | Xem | Xem | Xem | Xem | Xem | Xem | Xem |
| **Hồ sơ thú cưng** | Xem | Xem | Xem, Tạo | Xem | Tạo, Cập nhật | Tạo, Xem | Xem | Xem | Xem | Xem | Xem | Xem | Xem |
| **Lịch hẹn khám** | Tạo | Cập nhật | Tạo | Cập nhật | - | Cập nhật | Xem | Xem | - | - | - | - | - |
| **Đợt khám y tế (Pet Visit)**| - | - | - | - | - | Tạo | Xem | Cập nhật | Cập nhật | Cập nhật | Cập nhật | Cập nhật | Xem |
| **Lịch sử trạng thái (lịch hẹn, đợt khám, dịch vụ)** | Tạo | Tạo | Tạo | Tạo | - | Tạo | - | - | Tạo | Tạo | Tạo | Tạo | - |
| **Danh mục dịch vụ** | - | - | - | - | - | - | - | - | Xem | Xem | Xem | - | - |
| **Chỉ định dịch vụ** | - | - | - | - | - | - | - | - | Tạo, Cập nhật | Cập nhật | Tạo, Cập nhật | Xem | - |
| **Hóa đơn dịch vụ** | - | - | - | - | - | - | - | - | Tạo, Cập nhật | Cập nhật | Tạo, Cập nhật | Xem, Cập nhật | - |
| **Chỉ số xét nghiệm & Tham chiếu**| - | - | - | - | - | - | - | - | - | Xem | - | - | - |
| **Kết quả xét nghiệm & CĐHA**| - | - | - | - | - | - | - | - | - | Tạo, Xem | Xem | - | - |
| **Danh mục thuốc & Tồn kho** | - | - | - | - | - | - | - | - | - | - | Xem | - | Xem, Cập nhật |
| **Đơn thuốc & Chi tiết đơn** | - | - | - | - | - | - | - | - | - | - | Tạo | Xem | Xem |
| **Hóa đơn thuốc & Chi tiết hóa đơn thuốc** | - | - | - | - | - | - | - | - | - | - | - | - | Tạo, Cập nhật |
| **Lịch sử biến động kho** | - | - | - | - | - | - | - | - | - | - | - | - | Tạo |

*(Ghi chú: **Tạo** - Khởi tạo dữ liệu mới, **Xem** - Tra cứu đọc dữ liệu, **Cập nhật** - Cập nhật trạng thái hoặc thông tin, **-** - Không truy cập)*

---

## PHẦN IV: PHỤ LỤC DANH MỤC QUY TẮC NGHIỆP VỤ LIÊN QUAN (BUSINESS RULES INDEX)

| Mã BR | Tên quy tắc nghiệp vụ | Mô tả nghiệp vụ | Áp dụng tại UC |
| :---: | :--- | :--- | :---: |
| **BR-04** | Không chọn bác sĩ khi đặt hẹn | Khách hàng chỉ chọn ngày, khung giờ và triệu chứng ban đầu; không được chỉ định bác sĩ khi đặt lịch online. | UC-14, UC-15, UC-16 |
| **BR-05** | Bản chất lịch hẹn | Lịch hẹn chỉ xác định khung giờ dự kiến tiếp nhận, không thay thế quy trình tiếp nhận lâm sàng thực tế. | UC-14, UC-15, UC-16, UC-17 |
| **BR-06** | Quan hệ lịch hẹn - đợt khám | Một lịch hẹn được chuyển đổi thành tối đa một đợt khám y tế khi khách hàng check-in tại quầy. | UC-19 |
| **BR-09** | Trạng thái sau tiếp nhận | Đợt khám sau khi check-in bắt buộc chuyển sang trạng thái "Chờ khám" và xuất hiện trong danh sách chờ phân công, hoặc ngay trong hàng đợi của Bác sĩ nếu Lễ tân đã chọn Bác sĩ khi check-in. | UC-19, UC-20 |
| **BR-10** | Trách nhiệm điều phối | Nhân viên Lễ tân chịu trách nhiệm điều phối hàng đợi và phân công ca khám cho bác sĩ. | UC-20, UC-21 |
| **BR-11** | Hàng đợi riêng của từng Bác sĩ | Mỗi Bác sĩ có một hàng đợi riêng. Lễ tân được xếp ca "Chờ khám" vào hàng đợi của bất kỳ Bác sĩ đang làm việc nào, bất cứ lúc nào, không phụ thuộc Bác sĩ đang rảnh hay đang khám; hệ thống gợi ý Bác sĩ có ít người chờ nhất. Ca vừa có kết quả cận lâm sàng tự lên đầu hàng đợi của Bác sĩ khám chính (sau ca cấp cứu). | UC-19, UC-20, UC-21, UC-25_26 |
| **BR-12** | Giới hạn ca khám đồng thời | Một Bác sĩ chỉ khám duy nhất một ca bệnh tại một thời điểm (trừ khoảng thời gian chờ kết quả cận lâm sàng); Bác sĩ chỉ được "Gọi số tiếp theo" khi không có ca đang khám. | UC-22_23, UC-30_31_33 |
| **BR-13** | Phòng khám cố định | Mỗi Bác sĩ làm việc tại đúng số phòng khám cố định đã được cấu hình trên hệ thống. | UC-20, UC-21 |
| **BR-14** | Tiếp nhận đa kênh | Hệ thống hỗ trợ đón tiếp đồng thời cả hai luồng: khách đã đặt hẹn trước và khách đến vãng lai. | UC-16, UC-18, UC-19 |
| **BR-15** | Đơn vị đợt khám | Mỗi đợt khám y tế chỉ gắn liền với duy nhất một thú cưng cụ thể. | UC-18, UC-22_23 |
| **BR-18** | Đơn thuốc duy nhất | Mỗi đợt khám y tế có tối đa một đơn thuốc điện tử tương ứng. | UC-30_31_33 |
| **BR-19** | Hóa đơn riêng cho từng dịch vụ | Mỗi dịch vụ được chỉ định trong đợt khám (kể cả phí khám) có đúng một hóa đơn dịch vụ riêng; một đợt khám có thể có nhiều hóa đơn dịch vụ. Hệ thống không lưu tổng tiền hóa đơn mà tính từ số lượng, đơn giá, thuế suất và giảm giá. | UC-22_23, UC-25_26, UC-30_31_33, UC-34_35 |
| **BR-20** | Thẩm quyền chuyên môn | Bác sĩ khám lâm sàng (`VETERINARIAN`) phụ trách khám sơ bộ, chỉ định và kê đơn; Kỹ thuật viên Xét nghiệm (`LAB_TECHNICIAN`) nhập kết quả Lab; Kỹ thuật viên CĐHA (`IMAGING_TECHNICIAN`) tải ảnh và kết luận CĐHA. | UC-22_23, UC-25_26, UC-30_31_33 |
| **BR-21** | Tách biệt chi phí | Chi phí dịch vụ (khám, cận lâm sàng, dịch vụ tại phòng) và chi phí thuốc được ghi trên hai loại hóa đơn độc lập: hóa đơn dịch vụ và hóa đơn thuốc; doanh thu từng loại được thống kê riêng. | UC-25_26, UC-34_35, UC-36 |
| **BR-23** | Tham chiếu phụ thuộc loài | Các chỉ số xét nghiệm bắt buộc phải được đánh giá dựa trên khoảng tham chiếu sinh lý chuẩn riêng của Chó hoặc Mèo. | UC-25_26 |
| **BR-24** | Bất biến khoảng tham chiếu | Khoảng tham chiếu sinh lý được lưu cố định cùng kết quả tại thời điểm xét nghiệm để đảm bảo tính pháp lý lịch sử. | UC-25_26 |
| **BR-25** | Bất biến giá dịch vụ | Đơn giá và thuế suất của dịch vụ được chốt cố định vào hóa đơn dịch vụ theo giá niêm yết tại đúng thời điểm Bác sĩ ra chỉ định. | UC-22_23, UC-30_31_33 |
| **BR-26** | Bất biến giá thuốc | Đơn giá bán và thuế suất của từng loại thuốc được chốt cố định vào hóa đơn thuốc tại đúng thời điểm Thu ngân lập hóa đơn thuốc. Đơn thuốc của Bác sĩ không chứa giá. | UC-36 |
| **BR-27** | Thời điểm lập và thu hóa đơn dịch vụ | Hóa đơn dịch vụ được hệ thống lập tự động ngay khi Bác sĩ chỉ định dịch vụ (trạng thái "Chờ thanh toán"). Thu ngân chỉ được xác nhận thanh toán khi đợt khám đã được Bác sĩ chốt chuyên môn ("Chờ thanh toán") hoặc khi thu công nợ của đợt khám đã đóng. | UC-22_23, UC-34_35 |
| **BR-28** | Điều kiện hoàn thành ca khám | Đợt khám chuyển sang "Đã hoàn thành" khi mọi hóa đơn dịch vụ của đợt khám đều "Đã thanh toán" hoặc "Đã hủy"; việc mua thuốc không ảnh hưởng. Ngoại lệ EX-11: khi khách bỏ về, đợt khám được đóng sang "Đã hoàn thành" và các hóa đơn dịch vụ còn "Chờ thanh toán" được giữ làm công nợ. | UC-34_35, UC-25_26, UC-30_31_33 |
| **BR-29** | Thời điểm trừ kho | Thuốc chỉ bị trừ tồn kho khi hóa đơn thuốc được xác nhận thanh toán; việc chuyển hóa đơn sang "Đã thanh toán", trừ kho và ghi lịch sử "Xuất bán" diễn ra trong cùng một giao dịch. | UC-36 |
| **BR-30** | Giới hạn tồn kho khi bán | Không cho phép bán (xuất kho) vượt quá số lượng tồn kho tại thời điểm xác nhận. Khi kê đơn, số lượng vượt tồn kho chỉ bị cảnh báo vì khách có thể mua ngoài. | UC-30_31_33, UC-36 |
| **BR-31** | Chống bán thuốc lặp lại | Mỗi đơn thuốc có tối đa một hóa đơn thuốc; hóa đơn thuốc đã "Đã thanh toán" không được xác nhận lại, nên thuốc của một đơn không bị trừ kho nhiều hơn một lần. | UC-36 |
| **BR-32** | Quyền mua thuốc của khách hàng | Khách hàng được tự chọn mua thuốc tại phòng khám hoặc mua ngoài theo đơn in; được mua một phần đơn với số lượng mỗi thuốc không vượt số lượng kê. | UC-30_31_33, UC-36 |
| **BR-33** | Hủy dịch vụ kéo theo hủy hóa đơn | Khi một dịch vụ được chỉ định bị hủy, hóa đơn dịch vụ tương ứng chuyển "Đã hủy" trong cùng giao dịch. Không có thao tác hủy hóa đơn dịch vụ riêng lẻ; không được hủy dịch vụ có hóa đơn đã thanh toán. | UC-22_23, UC-25_26, UC-34_35 |
| **BR-34** | Gọi số & Đẩy lùi 1 bậc | Ở hàng đợi Bác sĩ, phòng Xét nghiệm và phòng CĐHA: người thực hiện bấm "Gọi số tiếp theo" để gọi người đứng đầu; gọi không thấy thì bấm "Đẩy lùi 1 bậc", người đó được xếp ra ngay sau người kế tiếp và người kế tiếp được gọi. Không giới hạn số lần bị lùi, hệ thống chỉ hiển thị số lần. Ca cấp cứu đã bị lùi được xếp như ca thường. | UC-22_23, UC-25_26, UC-30_31_33 |

---

## PHẦN V: DANH MỤC TOÀN BỘ CÁC USE CASE CỦA HỆ THỐNG (FULL USE CASE LIST)

Dưới đây là danh mục đầy đủ **39 Ca sử dụng (Use Cases)** của Hệ thống Quản lý Phòng khám Thú y, được phân bổ theo 9 Phân hệ chức năng và các tác nhân nghiệp vụ:

| Mã UC | Tên Ca Sử dụng (Use Case Name) | Tác nhân chính (Primary Actor) | Phân hệ Nghiệp vụ |
| :---: | :--- | :---: | :--- |
| **UC-01** | Quản lý tài khoản người dùng & Phân quyền nội bộ *(Manage User Accounts & Roles)* | Quản trị viên (ADMIN) | Phân hệ 1: Quản trị Hệ thống & Danh mục |
| **UC-02** | Quản lý số phòng làm việc cố định của Bác sĩ / Kỹ thuật viên *(Manage Work Rooms)* | Quản trị viên (ADMIN) | Phân hệ 1: Quản trị Hệ thống & Danh mục |
| **UC-03** | Quản lý danh mục Dịch vụ kỹ thuật *(Manage Services Catalog)* | Quản trị viên (ADMIN) | Phân hệ 1: Quản trị Hệ thống & Danh mục |
| **UC-04** | Quản lý danh mục Thuốc & Tủ thuốc *(Manage Medicines Catalog)* | Quản trị viên (ADMIN) | Phân hệ 1: Quản trị Hệ thống & Danh mục |
| **UC-05** | Quản lý danh mục Chỉ số xét nghiệm *(Manage Lab Test Items)* | Quản trị viên (ADMIN) | Phân hệ 1: Quản trị Hệ thống & Danh mục |
| **UC-06** | Quản lý Khoảng tham chiếu sinh lý theo Loài *(Manage Species Reference Ranges)* | Quản trị viên (ADMIN) | Phân hệ 1: Quản trị Hệ thống & Danh mục |
| **UC-07** | Quản lý danh mục Loài thú cưng *(Manage Species Catalog)* | Quản trị viên (ADMIN) | Phân hệ 1: Quản trị Hệ thống & Danh mục |
| **UC-08** | Báo cáo Thống kê Doanh thu & Hiệu suất phòng khám *(Analytics & Operational Reports)* | Quản trị viên (ADMIN) | Phân hệ 1: Quản trị Hệ thống & Danh mục |
| **UC-09** | Tìm kiếm thông tin Khách hàng đa tiêu chí *(Search Pet Owners)* | Lễ tân (RECEPTIONIST) | Phân hệ 2: Quản lý Khách hàng & Thú cưng |
| **UC-10** | Tạo mới hồ sơ Khách hàng & Cấp tài khoản tự động *(Register Pet Owner)* | Lễ tân (RECEPTIONIST) | Phân hệ 2: Quản lý Khách hàng & Thú cưng |
| **UC-11** | Cập nhật thông tin hồ sơ Khách hàng *(Update Pet Owner Profile)* | Lễ tân / Chủ nuôi | Phân hệ 2: Quản lý Khách hàng & Thú cưng |
| **UC-12** | Đăng ký hồ sơ Thú cưng mới *(Register New Pet)* | Lễ tân / Chủ nuôi | Phân hệ 2: Quản lý Khách hàng & Thú cưng |
| **UC-13** | Cập nhật hồ sơ & Đặc điểm nhận dạng Thú cưng *(Update Pet Profile)* | Lễ tân / Chủ nuôi | Phân hệ 2: Quản lý Khách hàng & Thú cưng |
| **UC-14** | Đặt lịch hẹn khám trực tuyến qua Portal *(Online Appointment Booking)* | Chủ thú cưng (PET_OWNER) | Phân hệ 3: Đặt lịch hẹn khám |
| **UC-15** | Quản lý lịch hẹn cá nhân: Đổi giờ / Hủy hẹn online *(Manage Personal Appointments)* | Chủ thú cưng (PET_OWNER) | Phân hệ 3: Đặt lịch hẹn khám |
| **UC-16** | Đặt lịch hẹn tại quầy / qua điện thoại *(Receptionist Appointment Booking)* | Lễ tân (RECEPTIONIST) | Phân hệ 3: Đặt lịch hẹn khám |
| **UC-17** | Duyệt xác nhận / Từ chối lịch hẹn trực tuyến *(Confirm & Cancel Online Appointments)* | Lễ tân (RECEPTIONIST) | Phân hệ 3: Đặt lịch hẹn khám |
| **UC-18** | Tiếp nhận hồ sơ Khách hàng & Thú cưng tại quầy *(Front-desk Pet & Owner Reception)* | Lễ tân (RECEPTIONIST) | Phân hệ 4: Tiếp đón & Hàng đợi Sảnh |
| **UC-19** | Tiếp nhận thú cưng tại quầy: Check-in & Walk-in *(Check-in Appointment & Walk-in)* | Lễ tân (RECEPTIONIST) | Phân hệ 4: Tiếp đón & Hàng đợi Sảnh |
| **UC-20** | Giám sát danh sách chờ phân công & hàng đợi từng Bác sĩ *(Queue Monitoring & Priority Handling)* | Lễ tân (RECEPTIONIST) | Phân hệ 4: Tiếp đón & Hàng đợi Sảnh |
| **UC-21** | Điều phối & Phân công Bác sĩ: xếp ca vào hàng đợi riêng của Bác sĩ *(Assign Doctor to Visit)* | Lễ tân (RECEPTIONIST) | Phân hệ 4: Tiếp đón & Hàng đợi Sảnh |
| **UC-22** | Bác sĩ tiếp nhận bệnh nhân & Khám lâm sàng sơ bộ *(Clinical Examination - Phase 1)* | Bác sĩ (VETERINARIAN) | Phân hệ 5: Khám Lâm sàng Sơ bộ (GĐ 1) |
| **UC-23** | Chỉ định Dịch vụ Kỹ thuật cận lâm sàng *(Order Paraclinical Services)* | Bác sĩ (VETERINARIAN) | Phân hệ 5: Khám Lâm sàng Sơ bộ (GĐ 1) |
| **UC-24** | Xử lý rẽ nhánh Chốt ca khám thông thường / Tiêm phòng *(Fast-track Non-paraclinical Visit)* | Bác sĩ (VETERINARIAN) | Phân hệ 5: Khám Lâm sàng Sơ bộ (GĐ 1) |
| **UC-25** | Tiếp nhận mẫu, Vận hành máy & Nhập kết quả Xét nghiệm *(Perform Laboratory Tests)* | KTV Xét nghiệm (LAB_TECHNICIAN) | Phân hệ 6: Quản lý & Thực hiện Cận lâm sàng |
| **UC-26** | Chụp X-quang / Siêu âm, Tải ảnh & Kết luận CĐHA *(Perform Imaging Diagnostics)* | KTV CĐHA (IMAGING_TECHNICIAN) | Phân hệ 6: Quản lý & Thực hiện Cận lâm sàng |
| **UC-27** | Đẩy lùi 1 bậc khi khách vắng mặt tại phòng CLS *(Skip Absent Patient in Paraclinic)* | KTV Lab / KTV CĐHA | Phân hệ 6: Quản lý & Thực hiện Cận lâm sàng |
| **UC-28** | Gọi số tiếp theo tại phòng CLS *(Call Next Patient in Paraclinic)* | KTV Lab / KTV CĐHA | Phân hệ 6: Quản lý & Thực hiện Cận lâm sàng |
| **UC-29** | Xử lý khách hàng xin hủy dịch vụ cận lâm sàng giữa chừng *(Cancel Paraclinical Service)* | KTV Lab / KTV CĐHA | Phân hệ 6: Quản lý & Thực hiện Cận lâm sàng |
| **UC-30** | Bác sĩ gọi ca có kết quả (đứng đầu hàng đợi) vào Giai đoạn 2 *(Doctor Callback - Phase 2)* | Bác sĩ (VETERINARIAN) | Phân hệ 7: Hội chẩn Kết quả & Kê đơn (GĐ 2) |
| **UC-31** | Kê đơn thuốc điện tử *(Electronic Prescription)* | Bác sĩ (VETERINARIAN) | Phân hệ 7: Hội chẩn Kết quả & Kê đơn (GĐ 2) |
| **UC-32** | Đẩy lùi 1 bậc khi khách vắng mặt ở Giai đoạn 2 *(Skip Absent Patient - Phase 2)* | Bác sĩ (VETERINARIAN) | Phân hệ 7: Hội chẩn Kết quả & Kê đơn (GĐ 2) |
| **UC-33** | Chốt đợt khám & Khóa hồ sơ bệnh án chuyên môn 1 chiều *(Finalize Visit & Lock Record)* | Bác sĩ (VETERINARIAN) | Phân hệ 7: Hội chẩn Kết quả & Kê đơn (GĐ 2) |
| **UC-34** | Xem bảng kê hóa đơn dịch vụ & Áp dụng giảm giá *(Review Service Invoices & Discount)* | Thu ngân (RECEPTIONIST) | Phân hệ 8: Thanh toán & Bán thuốc |
| **UC-35** | Xác nhận thanh toán hóa đơn dịch vụ *(Confirm Service Invoice Payment)* | Thu ngân (RECEPTIONIST) | Phân hệ 8: Thanh toán & Bán thuốc |
| **UC-36** | Bán thuốc theo đơn (tùy chọn) & Trừ tồn kho an toàn *(Sell Prescribed Medicines & Deduct Stock)* | Lễ tân / Thu ngân | Phân hệ 8: Thanh toán & Bán thuốc |
| **UC-37** | Quản lý Nhập kho thuốc & Cân chỉnh kho dược *(Manage Pharmacy Stock Inflow)* | Quản trị viên (ADMIN) | Phân hệ 8: Thanh toán & Bán thuốc |
| **UC-38** | Tra cứu Lịch sử bệnh án điện tử trọn đời của Thú cưng *(View Lifelong Medical Records)* | Bác sĩ / Lễ tân / Chủ nuôi | Phân hệ 9: Tra cứu Bệnh án & Portal |
| **UC-39** | Xem đơn thuốc & Hướng dẫn sử dụng thuốc điện tử trên Portal (kể cả khi mua thuốc ngoài) *(View Digital Prescriptions)* | Chủ thú cưng (PET_OWNER) | Phân hệ 9: Tra cứu Bệnh án & Portal |

---

## PHỤ LỤC: THAY ĐỔI SO VỚI PHIÊN BẢN 2.0

| Vị trí | Bản 2.0 | Bản 3.0 | Lý do |
| :--- | :--- | :--- | :--- |
| Sơ đồ luồng liên kết | UC-35 (thanh toán) → UC-36 (xuất thuốc) → hoàn thành | UC-35 → hoàn thành; UC-36 là nhánh tùy chọn | Khách được mua thuốc ngoài |
| UC-19 | – | Thêm ngoại lệ thú cưng đang có đợt khám chưa kết thúc | Khớp guard T01 của State Machine |
| UC-20 | Hàng đợi sảnh 3 nhóm (cấp cứu / có hẹn đúng giờ / vãng lai + trễ hẹn) | 2 nhóm: cấp cứu → còn lại theo thời gian check-in | Khớp FR-21, AD-02 và chỉ mục `idx_visits_queue`; giờ hẹn nằm ở CSDL khác nên không dùng làm tầng ưu tiên |
| UC-20, UC-21 | Bác sĩ vẫn "Sẵn sàng" sau khi phân công; gán số phòng vào đợt khám | Bác sĩ "Đang bận" ngay khi được phân công; phòng lấy theo Bác sĩ; ca đã hoãn không bật Khóa ưu tiên | Chống phân công trùng; bỏ cột phòng trùng lặp |
| UC-22_23 | Snapshot đơn giá vào chỉ định dịch vụ | Tự lập dịch vụ khám + hóa đơn khi bắt đầu khám; mỗi dịch vụ chỉ định có hóa đơn dịch vụ "Chờ thanh toán"; thêm dịch vụ tại phòng, hủy ca chuyển viện | Hóa đơn riêng cho từng dịch vụ (góp ý GVHD) |
| UC-25_26 | "Hóa đơn viện phí chỉ tính dịch vụ đã làm" | Hủy dịch vụ ⇒ hủy hóa đơn của dịch vụ đó; thêm thao tác "Đã lấy mẫu"; thêm luồng khách bỏ về giữa chừng | Đồng bộ BR-33, EX-09, EX-11 |
| UC-30_31_33 | Đơn thuốc lưu đơn giá; kê vượt tồn kho bị chặn; "Đóng ca" đẩy chi phí sang hóa đơn mới | Đơn thuốc không giá; chỉ cảnh báo tồn kho; "Đóng ca" giữ hóa đơn dịch vụ sẵn có làm công nợ; tạm hoãn sau khi gọi; thêm mở lại hồ sơ | Đồng bộ State Machine v3.0 (T08, T13, T14) |
| UC-34_35 | Lập 1 hóa đơn gộp, tổng = dịch vụ + thuốc − chiết khấu; mở khóa xuất thuốc | Thu tiền các hóa đơn dịch vụ đã có; giảm giá trên từng hóa đơn; đủ hóa đơn ⇒ đợt khám "Đã hoàn thành"; thu công nợ | Hóa đơn tách theo dịch vụ |
| UC-36 | "Xuất thuốc theo đơn" sau khi hóa đơn đã thanh toán; đổi trạng thái đơn thuốc; hoàn thành ca | "Bán thuốc theo đơn (tùy chọn)": lập hóa đơn thuốc, thu tiền và trừ kho trong cùng giao dịch; không đổi trạng thái đợt khám | Mua thuốc là tùy chọn; bỏ trạng thái đơn thuốc |
| Ma trận CRUD | Một dòng "Hóa đơn viện phí" | Tách "Hóa đơn dịch vụ" và "Hóa đơn thuốc"; thêm dòng "Lịch sử trạng thái" | Đồng bộ lược đồ v3.0 |
| Business Rules | BR-19, 26–31 theo mô hình 1 hóa đơn / ca | Sửa BR-11, 19, 21, 25–31; thêm BR-32, BR-33 | Đồng bộ nghiệp vụ mới |
| Danh mục UC | UC-34–37 thuộc "Viện phí & Xuất thuốc Trừ kho" | Đổi tên UC-34, 35, 36 và phân hệ 8 thành "Thanh toán & Bán thuốc" | Tên khớp nghiệp vụ |
| UC-19 (rà soát 10/11) | Cập nhật lịch hẹn `CHECKED_IN` trong cùng giao dịch tạo đợt khám | Lịch hẹn chuyển `CHECKED_IN` qua thông báo nội bộ sau khi lưu đợt khám; thêm ngoại lệ lịch hẹn không hợp lệ | Hai CSDL khác nhau (Kiến trúc mục 5.3) |
| UC-20, UC-21, UC-22_23 (rà soát 10/11) | "Tạm hoãn lượt ở sảnh, xuống cuối hàng đợi"; "Chuyển trả lễ tân" không có thao tác hệ thống | Ca giữ vị trí theo thời điểm tiếp nhận; thêm "Gỡ phân công" (UC-21 Luồng 5c); hàng đợi phân công hiển thị cấp cứu trước | Mọi thao tác đều có dữ liệu và API tương ứng |
| UC-22_23 Ngoại lệ 5.1 (rà soát 10/11) | Hủy ca không xét dịch vụ tại phòng đã làm | Chỉ hủy khi chưa có dịch vụ tại phòng hoàn thành | Đồng bộ guard T11 |
| UC-30_31_33 Luồng 11a, UC-36 (rà soát 10/11) | Chỉ chặn sửa đơn khi đã bán; sau EX-15 "quay lại Bước 3" | Chặn khi có hóa đơn thuốc chưa hủy; thêm Luồng 9a sửa hóa đơn thuốc; hủy là kết thúc | Khớp `prescription_id UNIQUE` |
| UC-19, UC-20, UC-21 (rà soát 11/11) | Một hàng đợi chung ở sảnh; chỉ phân công cho Bác sĩ "Sẵn sàng thuần túy", phân xong Bác sĩ "Đang bận" nên mỗi Bác sĩ giữ 1 ca | Mỗi Bác sĩ có hàng đợi riêng; Lễ tân xếp ca vào hàng đợi Bác sĩ bất cứ lúc nào (ngay khi tiếp nhận), hệ thống gợi ý Bác sĩ ít người chờ nhất; chuyển ca giữa các hàng đợi | Lễ tân không phải chờ Bác sĩ rảnh mới phân ca |
| UC-22_23, UC-25_26, UC-30_31_33 (rà soát 11/11) | "Báo vắng mặt" chuyển Lễ tân; CLS "Tạm hoãn" sang tab riêng rồi "Recall" ghim ưu tiên kế tiếp; GĐ 2 "Tạm hoãn" đưa ca về tab đã hoãn; Khóa ưu tiên chặn Lễ tân | "Gọi số tiếp theo" ở cả 3 nơi; gọi không thấy thì "Đẩy lùi 1 bậc" (xếp ra sau người kế tiếp, không giới hạn, hiển thị số lần); ca có kết quả tự lên đầu hàng đợi Bác sĩ; bỏ Khóa ưu tiên | Thống nhất một cơ chế hàng đợi cho phòng khám, Xét nghiệm, CĐHA |
| Business Rules, Danh mục UC (rà soát 11/11) | BR-11 "Điều kiện nhận ca mới"; UC-27, 28, 30, 32 theo cơ chế tạm hoãn / Khóa ưu tiên | BR-11 "Hàng đợi riêng của từng Bác sĩ", BR-12 thêm điều kiện gọi số, thêm BR-34 "Gọi số & Đẩy lùi 1 bậc"; đổi tên UC-20, 21, 27, 28, 30, 32 | Đồng bộ mô hình hàng đợi mới |
