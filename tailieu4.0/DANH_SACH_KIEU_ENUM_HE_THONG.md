# TÀI LIỆU QUY CHUẨN CÁC KIỂU DỮ LIỆU CỐ ĐỊNH (ENUM TYPES SPECIFICATION)
## HỆ THỐNG QUẢN LÝ PHÒNG KHÁM THÚ Y

> **Phiên bản:** 3.0 – Đồng bộ với lược đồ CSDL v3.0 (`schema_init.sql`, 25 bảng), cập nhật ngày 10/11/2026.  
> **Mục đích:** Tài liệu này tổng hợp toàn bộ các trường dữ liệu có tập giá trị cố định (Domain Constraints / ENUM) trong hệ thống, nhằm chuẩn hóa việc lưu trữ trong Cơ sở dữ liệu MySQL 8.0, lập trình Backend (Java 21 / Spring Boot) và hiển thị giao diện Frontend React.

---

## TỔNG HỢP DANH SÁCH 10 KIỂU ENUM LƯU TRONG CƠ SỞ DỮ LIỆU

| STT | Tên ENUM | Bảng & Cột áp dụng | Danh sách các giá trị hợp lệ |
| :---: | :--- | :--- | :--- |
| **1** | `RoleCode` | `roles.code` | `'ADMIN'`, `'VETERINARIAN'`, `'RECEPTIONIST'`, `'LAB_TECHNICIAN'`, `'IMAGING_TECHNICIAN'`, `'PET_OWNER'` |
| **2** | `UserStatus` | `users.status` | `'ACTIVE'`, `'INACTIVE'`, `'LOCKED'` |
| **3** | `PetGender` | `pets.gender` | `'MALE'`, `'FEMALE'`, `'UNKNOWN'` |
| **4** | `BookingChannel` | `appointments.booking_channel` | `'ONLINE'`, `'PHONE'`, `'WALK_IN'` |
| **5** | `AppointmentStatus` | `appointments.status`; `appointment_status_histories.from_status`, `to_status` | `'PENDING'`, `'CONFIRMED'`, `'CHECKED_IN'`, `'CANCELLED'`, `'NO_SHOW'` |
| **6** | `VisitStatus` | `pet_visits.status`; `pet_visit_status_histories.from_status`, `to_status` | `'WAITING'`, `'IN_PROGRESS'`, `'WAITING_RESULTS'`, `'RESULTS_READY'`, `'WAITING_PAYMENT'`, `'COMPLETED'`, `'CANCELLED'` |
| **7** | `ServiceCategory` | `services.category` | `'EXAMINATION'`, `'VACCINATION'`, `'DEWORMING'`, `'EXTERNAL_PARASITE'`, `'INJECTION_INFUSION'`, `'LABORATORY'`, `'IMAGING'`, `'SURGERY'`, `'PROCEDURE'` |
| **8** | `ServiceDetailStatus` | `visit_service_details.status`; `visit_service_detail_histories.from_status`, `to_status` | `'PENDING'`, `'IN_PROGRESS'`, `'COMPLETED'`, `'CANCELLED'` |
| **9** | `PaymentStatus` | `service_invoices.payment_status`; `medicine_invoices.payment_status` | `'PENDING'`, `'PAID'`, `'CANCELLED'` |
| **10** | `InventoryTransactionType` | `inventory_transactions.transaction_type` | `'IMPORT'`, `'EXPORT_SALE'`, `'ADJUSTMENT'` |

**Enum chỉ dùng ở tầng ứng dụng (không có cột trong CSDL):** `LabEvaluation` (`'LOW'`, `'NORMAL'`, `'HIGH'`) – xem Mục 11.

---

## CHI TIẾT TỪNG KIỂU DỮ LIỆU ENUM

### 1. `RoleCode` - Mã vai trò người dùng
- **Bảng:** `roles` | **Cột:** `code`
- **Cú pháp CSDL:** `ENUM('ADMIN', 'VETERINARIAN', 'RECEPTIONIST', 'LAB_TECHNICIAN', 'IMAGING_TECHNICIAN', 'PET_OWNER') NOT NULL UNIQUE`
- **Ý nghĩa các giá trị:**
  - `'ADMIN'`: Quản trị viên hệ thống (cấu hình danh mục, quản lý người dùng, xem thống kê).
  - `'VETERINARIAN'`: Bác sĩ thú y khám chính (khám lâm sàng, chỉ định cận lâm sàng, chẩn đoán xác định, kê đơn).
  - `'RECEPTIONIST'`: Lễ tân / Thu ngân (tiếp đón, điều phối phân công bác sĩ, thu tiền hóa đơn dịch vụ, bán thuốc theo đơn).
  - `'LAB_TECHNICIAN'`: Bác sĩ / Kỹ thuật viên Xét nghiệm (tiếp nhận mẫu bệnh phẩm, phân tích huyết học/sinh hóa và nhập kết quả).
  - `'IMAGING_TECHNICIAN'`: Bác sĩ / Kỹ thuật viên Chẩn đoán hình ảnh (thực hiện siêu âm, chụp X-quang, tải ảnh và kết luận hình thái).
  - `'PET_OWNER'`: Khách hàng / Chủ thú cưng (đặt lịch trực tuyến, tra cứu hồ sơ bệnh án).

---

### 2. `UserStatus` - Trạng thái tài khoản người dùng
- **Bảng:** `users` | **Cột:** `status`
- **Cú pháp CSDL:** `ENUM('ACTIVE', 'INACTIVE', 'LOCKED') NOT NULL DEFAULT 'ACTIVE'`
- **Ý nghĩa các giá trị:**
  - `'ACTIVE'`: Tài khoản đang hoạt động bình thường.
  - `'INACTIVE'`: Tài khoản chưa kích hoạt hoặc đã ngừng sử dụng (nhân viên đã nghỉ việc).
  - `'LOCKED'`: Tài khoản bị tạm khóa do vi phạm hoặc bảo mật (nhập sai mật khẩu nhiều lần).
- **Ghi chú:** Số Bác sĩ `ACTIVE` được dùng để tính sức chứa khung giờ đặt lịch (`Capacity = N_active × 2`).

---

### 3. `PetGender` - Giới tính thú cưng
- **Bảng:** `pets` | **Cột:** `gender`
- **Cú pháp CSDL:** `ENUM('MALE', 'FEMALE', 'UNKNOWN') NOT NULL DEFAULT 'UNKNOWN'`
- **Ý nghĩa các giá trị:**
  - `'MALE'`: Thú cưng đực.
  - `'FEMALE'`: Thú cưng cái.
  - `'UNKNOWN'`: Chưa xác định rõ giới tính (thú non, chim, bò sát).

---

### 4. `BookingChannel` - Kênh đặt lịch hẹn
- **Bảng:** `appointments` | **Cột:** `booking_channel`
- **Cú pháp CSDL:** `ENUM('ONLINE', 'PHONE', 'WALK_IN') NOT NULL DEFAULT 'ONLINE'`
- **Ý nghĩa các giá trị:**
  - `'ONLINE'`: Khách hàng tự đặt trên Portal / Ứng dụng di động (lịch tạo ra ở trạng thái `PENDING`).
  - `'PHONE'`: Khách hàng gọi điện thoại đến phòng khám và Lễ tân tạo lịch giúp (lịch tạo ra ở trạng thái `CONFIRMED`).
  - `'WALK_IN'`: Khách hàng đến trực tiếp quầy để đặt lịch cho ngày khác (lịch tạo ra ở trạng thái `CONFIRMED`).

---

### 5. `AppointmentStatus` - Trạng thái lịch hẹn khám
- **Bảng & Cột:** `appointments.status`; `appointment_status_histories.from_status`, `appointment_status_histories.to_status`
- **Cú pháp CSDL:** `ENUM('PENDING', 'CONFIRMED', 'CHECKED_IN', 'CANCELLED', 'NO_SHOW') NOT NULL DEFAULT 'PENDING'` (riêng `from_status` cho phép `NULL` khi lịch vừa được tạo)
- **Ý nghĩa các giá trị:**
  - `'PENDING'`: Yêu cầu vừa gửi từ Portal, chờ Lễ tân xác nhận.
  - `'CONFIRMED'`: Lễ tân đã gọi điện xác nhận, giữ khung giờ cho khách.
  - `'CHECKED_IN'`: Khách đã đưa thú cưng đến phòng khám (chuyển tiếp sang tạo `Pet Visit`).
  - `'CANCELLED'`: Lịch bị hủy (bởi khách hoặc do phòng khám từ chối). Lý do hủy ghi ở `appointment_status_histories.notes`.
  - `'NO_SHOW'`: Khách không đến sau quá 30 phút so với giờ bắt đầu khung hẹn (`start_time + 30 phút`) đã xác nhận.

---

### 6. `VisitStatus` - Vòng đời Đợt khám bệnh (Chu kỳ Y tế Bất đồng bộ)
- **Bảng & Cột:** `pet_visits.status`; `pet_visit_status_histories.from_status`, `pet_visit_status_histories.to_status`
- **Cú pháp CSDL:** `ENUM('WAITING', 'IN_PROGRESS', 'WAITING_RESULTS', 'RESULTS_READY', 'WAITING_PAYMENT', 'COMPLETED', 'CANCELLED') NOT NULL DEFAULT 'WAITING'` (riêng `from_status` cho phép `NULL`)
- **Ý nghĩa các giá trị:**
  - `'WAITING'`: Chờ khám Giai đoạn 1. Nếu chưa có `doctor_id` thì nằm trong danh sách chờ phân công; đã có `doctor_id` thì nằm trong **hàng đợi riêng của Bác sĩ đó**, xếp theo `queue_order`.
  - `'IN_PROGRESS'`: Bác sĩ đang trực tiếp khám (Giai đoạn 1 khám sơ bộ, hoặc Giai đoạn 2 kết luận chẩn đoán).
  - `'WAITING_RESULTS'`: Bác sĩ đã ra chỉ định cận lâm sàng, thú cưng đang ở phòng xét nghiệm/CĐHA (Bác sĩ tạm giải phóng để khám ca khác).
  - `'RESULTS_READY'`: Phòng Cận lâm sàng đã nhập đủ kết quả (hoặc khách hủy bớt dịch vụ); ca tự quay về **đầu hàng đợi** của Bác sĩ khám chính (sau ca cấp cứu) để được gọi vào Giai đoạn 2.
  - `'WAITING_PAYMENT'`: Bác sĩ đã chốt chuyên môn và khóa chỉnh sửa, chờ Lễ tân thu tiền các hóa đơn dịch vụ (`service_invoices`) của ca khám.
  - `'COMPLETED'`: Tất cả hóa đơn dịch vụ của ca khám đã `PAID` (hoặc `CANCELLED`), lưu vào lịch sử bệnh án vĩnh viễn. Việc khách mua thuốc tại phòng khám là tùy chọn và không ảnh hưởng tới trạng thái này. Ngoại lệ EX-11: ca đóng khi khách bỏ về, các hóa đơn dịch vụ còn `PENDING` được giữ làm công nợ.
  - `'CANCELLED'`: Ca khám bị hủy bỏ trước hoặc trong khi khám (khách bỏ về, chuyển viện khẩn cấp). Lý do hủy ghi ở `pet_visit_status_histories.notes`.
- **Ghi chú:** Thời điểm bắt đầu khám, chốt ca, hoàn tất và người thao tác được lấy từ `pet_visit_status_histories` (không lưu thành cột riêng trên `pet_visits`).

---

### 7. `ServiceCategory` - Phân nhóm dịch vụ kỹ thuật
- **Bảng:** `services` | **Cột:** `category`
- **Cú pháp CSDL:** `ENUM('EXAMINATION', 'VACCINATION', 'DEWORMING', 'EXTERNAL_PARASITE', 'INJECTION_INFUSION', 'LABORATORY', 'IMAGING', 'SURGERY', 'PROCEDURE') NOT NULL`
- **Ý nghĩa các giá trị:**
  - `'EXAMINATION'`: Khám lâm sàng tổng quát / chuyên sâu.
  - `'VACCINATION'`: Tiêm phòng vaccine (bắt buộc khám sàng lọc trước tiêm).
  - `'DEWORMING'`: Tẩy giun sán đường ruột định kỳ.
  - `'EXTERNAL_PARASITE'`: Trị ký sinh trùng ngoài da (ve, bọ chét, ghẻ).
  - `'INJECTION_INFUSION'`: Công tiêm thuốc điều trị, công truyền dịch.
  - `'LABORATORY'`: Các gói xét nghiệm huyết học, sinh hóa, nước tiểu. Các chỉ số của từng gói được khai báo ở bảng `service_lab_test_items`. Dịch vụ thuộc nhóm này được đưa vào **hàng đợi phòng Xét nghiệm**.
  - `'IMAGING'`: Chẩn đoán hình ảnh: Siêu âm ổ bụng, chụp phim X-quang kỹ thuật số (tải ảnh đính kèm). Dịch vụ thuộc nhóm này được đưa vào **hàng đợi phòng CĐHA**.
  - `'SURGERY'`: Phẫu thuật ngoại khoa (triệt sản, mổ đẻ, mổ u).
  - `'PROCEDURE'`: Thủ thuật điều trị (thay băng, rửa vết thương, cắt chỉ, nẹp xương).
- **Ghi chú:** Doanh thu theo nhóm dịch vụ được thống kê bằng cách nhóm theo cột này qua VIEW `v_service_invoice_amounts`.

---

### 8. `ServiceDetailStatus` - Trạng thái thực hiện chỉ định dịch vụ kỹ thuật
- **Bảng & Cột:** `visit_service_details.status`; `visit_service_detail_histories.from_status`, `visit_service_detail_histories.to_status`
- **Cú pháp CSDL:** `ENUM('PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED') NOT NULL DEFAULT 'PENDING'` (riêng `from_status` cho phép `NULL`)
- **Ý nghĩa các giá trị:**
  - `'PENDING'`: Dịch vụ vừa được Bác sĩ chỉ định, đang chờ phòng chuyên môn (Lab / CĐHA) tiếp nhận và thực hiện. Dịch vụ nằm trong hàng đợi phòng tương ứng, xếp theo cấp cứu rồi `queue_order`. Gọi không thấy khách thì "Đẩy lùi 1 bậc" (EX-06): vẫn giữ `PENDING`, đổi `queue_order` với dịch vụ ngay sau và ghi `action = 'SKIPPED'` trong `visit_service_detail_histories`.
  - `'IN_PROGRESS'`: Kỹ thuật viên đã tiếp nhận thú cưng / lấy mẫu bệnh phẩm, máy đang phân tích tự động hoặc thú cưng đang trong phòng siêu âm/X-quang.
  - `'COMPLETED'`: Kỹ thuật viên / Bác sĩ CĐHA đã nhập đầy đủ kết quả đo đạc hoặc tải tệp ảnh chẩn đoán lên và nhấn xác nhận hoàn tất.
  - `'CANCELLED'`: Chỉ định bị hủy bỏ (chủ nuôi từ chối thực hiện hoặc bác sĩ thay đổi hướng xử lý). Hóa đơn dịch vụ tương ứng (`service_invoices`) chuyển `CANCELLED` trong cùng giao dịch, không tính tiền.

---

### 9. `PaymentStatus` - Trạng thái thanh toán hóa đơn
- **Bảng & Cột:** `service_invoices.payment_status` (hóa đơn từng dịch vụ); `medicine_invoices.payment_status` (hóa đơn thuốc)
- **Cú pháp CSDL:** `ENUM('PENDING', 'PAID', 'CANCELLED') NOT NULL DEFAULT 'PENDING'`
- **Ý nghĩa các giá trị:**
  - `'PENDING'`: Hóa đơn vừa tạo, đang chờ thu tiền. Hóa đơn dịch vụ được tạo ngay khi Bác sĩ chỉ định dịch vụ; hóa đơn thuốc được tạo khi khách chọn mua thuốc tại phòng khám.
  - `'PAID'`: Khách hàng đã thanh toán đủ tiền bên ngoài quầy, Thu ngân đã xác nhận (ghi nhận `cashier_id`, `paid_at`). Với hóa đơn thuốc, việc chuyển `PAID` và trừ tồn kho diễn ra trong cùng một giao dịch.
  - `'CANCELLED'`: Hóa đơn bị hủy bỏ (dịch vụ bị hủy theo EX-08, khách đổi ý không mua thuốc, hoặc sai sót nghiệp vụ).

---

### 10. `InventoryTransactionType` - Loại giao dịch biến động kho dược
- **Bảng:** `inventory_transactions` | **Cột:** `transaction_type`
- **Cú pháp CSDL:** `ENUM('IMPORT', 'EXPORT_SALE', 'ADJUSTMENT') NOT NULL`
- **Ý nghĩa các giá trị:**
  - `'IMPORT'`: Nhập thêm thuốc mới vào kho (`quantity` dương, tăng tồn kho).
  - `'EXPORT_SALE'`: Xuất kho khi bán thuốc theo hóa đơn thuốc đã thanh toán (`quantity` âm, giảm tồn kho). Bắt buộc có `medicine_invoice_id` (kiểm tra ở tầng ứng dụng); với `IMPORT` và `ADJUSTMENT` cột này để `NULL`.
  - `'ADJUSTMENT'`: Cân chỉnh kho sau kiểm kê thực tế phát hiện thừa/thiếu, hao hụt hoặc hết hạn sử dụng (`quantity` dương hoặc âm).
- **Ghi chú:** Tồn kho sau mỗi giao dịch không lưu thành cột, được tính bằng tổng lũy kế `SUM(quantity) OVER (PARTITION BY medicine_id ORDER BY created_at, id)`.

---

### 11. `LabEvaluation` - Đánh giá chỉ số xét nghiệm (chỉ dùng ở tầng ứng dụng)
- **Lưu trữ:** **Không có cột trong CSDL.** Giá trị được tính khi hiển thị từ `lab_test_results.result_value` so với `min_value_snapshot` và `max_value_snapshot`.
- **Khai báo:** Enum Java `LabEvaluation` trong `clinical-service` và kiểu tương ứng ở Frontend.
- **Quy tắc tính & hiển thị:**
  - `'LOW'`: `result_value < min_value_snapshot`. Hiển thị cảnh báo vàng.
  - `'NORMAL'`: `min_value_snapshot <= result_value <= max_value_snapshot`. Hiển thị xanh lá.
  - `'HIGH'`: `result_value > max_value_snapshot`. Hiển thị cảnh báo đỏ nguy hiểm.
- **Lý do không lưu:** Đây là thuộc tính dẫn xuất; nếu lưu, khi Kỹ thuật viên sửa lại giá trị đo mà không cập nhật nhãn thì dữ liệu sẽ mâu thuẫn.

---

## CÁC ENUM ĐÃ LOẠI BỎ SO VỚI PHIÊN BẢN 2.0

| Enum | Lý do loại bỏ | Thay thế bằng |
| :--- | :--- | :--- |
| `PrescriptionStatus` (`PRESCRIBED`, `DISPENSED`, `CANCELLED`) | Đơn thuốc chỉ còn là chỉ định chuyên môn; khách được mua tại phòng khám hoặc mua ngoài. | Việc mua/xuất thuốc thể hiện qua `medicine_invoices.payment_status`. Chống xuất trùng nhờ `medicine_invoices.prescription_id` UNIQUE. |
| `InvoiceItemType` (`SERVICE`, `MEDICINE`) | Bỏ bảng hóa đơn gộp `invoice_items`. | Doanh thu dịch vụ và doanh thu thuốc tách tự nhiên qua 2 bảng `service_invoices` và `medicine_invoices`. |
| `LabEvaluation` (lưu CSDL) | Thuộc tính dẫn xuất. | Chuyển thành enum chỉ dùng ở tầng ứng dụng (Mục 11). |

## BẢNG ĐỐI CHIẾU SỐ THỨ TỰ ENUM (v2.0 → v3.0)

| Enum | Số cũ (v2.0) | Số mới (v3.0) |
| :--- | :---: | :---: |
| `RoleCode`, `UserStatus`, `PetGender`, `BookingChannel`, `AppointmentStatus`, `VisitStatus`, `ServiceCategory` | 1 – 7 | 1 – 7 (giữ nguyên) |
| `ServiceDetailStatus` | 12 | 8 |
| `PaymentStatus` | 11 | 9 |
| `InventoryTransactionType` | 10 | 10 |
| `LabEvaluation` | 8 | 11 (chỉ ở ứng dụng) |
| `PrescriptionStatus` | 9 | Đã loại bỏ |
| `InvoiceItemType` | 13 | Đã loại bỏ |

> Các tài liệu khác có trích dẫn số thứ tự enum (ví dụ bảng tổng kết trong `THIET_KE_SO_DO_TRANG_THAI_STATE_MACHINE.md`) cần cập nhật theo bảng đối chiếu này.

> **Rà soát 11/11:** không đổi số lượng enum. `ServiceDetailStatus` và `VisitStatus` chỉ cập nhật mô tả theo mô hình hàng đợi riêng của từng Bác sĩ và cơ chế "Đẩy lùi 1 bậc"; cột `visit_service_detail_histories.action` (VARCHAR, không phải enum) đổi `POSTPONED` / `RECALL` thành `SKIPPED`.
