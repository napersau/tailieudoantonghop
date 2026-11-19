# TÀI LIỆU QUY CHUẨN CÁC TẬP GIÁ TRỊ CỐ ĐỊNH (BẢNG DANH MỤC & ENUM)
## HỆ THỐNG QUẢN LÝ PHÒNG KHÁM THÚ Y

> **Phiên bản:** 4.0 – Đồng bộ lược đồ CSDL v4.0 (`schema_init.sql`, 52 bảng), cập nhật 18/11/2026 theo nhận xét #3 của GVHD ("ENUM cứng nhắc, thêm giá trị phải ALTER TABLE").  
> **Thay đổi chính:** lược đồ **không còn cột kiểu `ENUM` của MySQL**. Tập giá trị người dùng có thể mở rộng chuyển thành **4 bảng danh mục**; tập giá trị gắn với logic chương trình lưu **`VARCHAR`** và được kiểm tra bằng **18 enum Java**; 1 enum chỉ dùng ở tầng ứng dụng.  
> **Mục đích:** chuẩn hóa cách lưu trong MySQL 8.0, cách khai báo ở Backend (Java 21 / Spring Boot) và hiển thị ở Frontend React.

---

## A. NGUYÊN TẮC CHỌN CÁCH LƯU

| Câu hỏi | Trả lời "Có" | Trả lời "Không" |
| :--- | :--- | :--- |
| Quản trị viên có cần thêm / ngừng / đổi tên giá trị khi hệ thống đang chạy, và giá trị có thuộc tính đi kèm (tên hiển thị, chính sách, thứ tự)? | **Bảng danh mục** (`SMALLINT id` + `code` duy nhất + `is_active`) | Xét câu dưới |
| Mỗi giá trị có quy tắc xử lý riêng trong code (máy trạng thái, chuyển tiếp hợp lệ)? | **`VARCHAR(20/30)` + enum Java** (`@Enumerated(EnumType.STRING)`) | `VARCHAR` + enum Java |

**Vì sao không dùng ENUM của MySQL nữa:**
- Thêm hoặc đổi thứ tự giá trị phải `ALTER TABLE`, có thể khóa bảng lớn và phải đồng bộ với code.
- ENUM lưu số thứ tự bên trong; sắp xếp, so sánh theo vị trí chứ không theo chữ, dễ gây nhầm.
- Với `VARCHAR`, trạng thái mới chỉ cần thêm hằng vào enum Java rồi triển khai lại; dữ liệu cũ không bị ảnh hưởng. Hibernate từ chối giá trị lạ khi đọc, Bean Validation (`@NotNull`) và kiểu enum ở DTO chặn giá trị sai khi ghi.
- Danh sách trạng thái vẫn được ghi ở chú thích cột trong `schema_init.sql` và ở tài liệu này để người đọc CSDL biết giá trị hợp lệ.

---

## B. BẢNG DANH MỤC (LOOKUP TABLES)

| STT | Bảng | CSDL | Cột tham chiếu | Dữ liệu khởi tạo (`code`) |
| :---: | :--- | :--- | :--- | :--- |
| **L1** | `roles` | auth | `user_roles.role_id` | `ADMIN`, `VETERINARIAN`, `RECEPTIONIST`, `LAB_TECHNICIAN`, `IMAGING_TECHNICIAN`, `PET_OWNER` |
| **L2** | `service_categories` | clinical | `services.category_id` | `EXAMINATION`, `VACCINATION`, `DEWORMING`, `EXTERNAL_PARASITE`, `INJECTION_INFUSION`, `LABORATORY`, `IMAGING`, `SURGERY`, `PROCEDURE` |
| **L3** | `species` | clinical | `pets.species_id`, `lab_test_reference_ranges.species_id` | `DOG`, `CAT` |
| **L4** | `medicine_categories` | billing-pharmacy | `medicines.category_id` | `ANTIBIOTIC`, `VACCINE`, `ANTIPARASITIC`, `SUPPLEMENT` |

### L1. `roles` – Vai trò người dùng
- **Cấu trúc:** `id SMALLINT`, `code VARCHAR(30) UNIQUE`, `name`, `description`, `is_system`, `is_active`. Một tài khoản có nhiều vai trò qua bảng nối `user_roles`.
- **Ý nghĩa 6 vai trò hệ thống (`is_system = TRUE`, không cho xóa):**
  - `ADMIN`: Quản trị viên (cấu hình danh mục, bảng giá, quản lý người dùng, xem báo cáo).
  - `VETERINARIAN`: Bác sĩ thú y khám chính (khám lâm sàng, chỉ định cận lâm sàng, chẩn đoán, kê đơn). Bắt buộc có `veterinarian_profiles`.
  - `RECEPTIONIST`: Lễ tân / Thu ngân (tiếp đón, phân công Bác sĩ, thu phí khám / phí cận lâm sàng để phát phiếu xếp hàng, thu tiền khi chốt ca, bán thuốc).
  - `LAB_TECHNICIAN`: Bác sĩ / KTV Xét nghiệm (nhận mẫu, nhập kết quả).
  - `IMAGING_TECHNICIAN`: Bác sĩ / KTV Chẩn đoán hình ảnh (siêu âm, X-quang, tải ảnh, kết luận).
  - `PET_OWNER`: Chủ thú cưng (đặt lịch, xem bệnh án, đơn thuốc). Có `pet_owner_profiles`.
- **Ở code:** quyền truy cập vẫn kiểm tra theo `code` (`@PreAuthorize("hasRole('VETERINARIAN')")`), khai báo hằng trong `RoleCodes` thay vì enum. Thêm vai trò mới (ví dụ `NURSE`) = INSERT vào `roles` + cấu hình quyền cho vai trò đó; không đổi lược đồ.

### L2. `service_categories` – Nhóm dịch vụ
- **Cấu trúc:** `id SMALLINT`, `code`, `name`, `queue_type` (`DOCTOR` / `LABORATORY` / `IMAGING` / `NULL`), `requires_prepayment`, `display_order`, `is_active`.
- **Dữ liệu khởi tạo:**

| `code` | Tên | `queue_type` | `requires_prepayment` | Ý nghĩa |
| :--- | :--- | :---: | :---: | :--- |
| `EXAMINATION` | Khám bệnh | `DOCTOR` | TRUE | Hóa đơn tạo lúc check-in; nộp phí xong mới có phiếu vào hàng đợi Bác sĩ |
| `VACCINATION` | Tiêm phòng | NULL | FALSE | Làm ngay tại phòng Bác sĩ, thu khi chốt ca |
| `DEWORMING` | Tẩy giun | NULL | FALSE | Như trên |
| `EXTERNAL_PARASITE` | Trị ký sinh trùng ngoài da | NULL | FALSE | Như trên |
| `INJECTION_INFUSION` | Tiêm, truyền dịch | NULL | FALSE | Như trên |
| `LABORATORY` | Xét nghiệm | `LABORATORY` | TRUE | Nộp tiền xong mới có phiếu vào hàng đợi phòng Xét nghiệm; chỉ số của gói ở `service_lab_test_items` |
| `IMAGING` | Chẩn đoán hình ảnh | `IMAGING` | TRUE | Nộp tiền xong mới có phiếu vào hàng đợi phòng CĐHA |
| `SURGERY` | Phẫu thuật | NULL | FALSE | Làm tại phòng, thu khi chốt ca |
| `PROCEDURE` | Thủ thuật | NULL | FALSE | Như trên |

- **Ghi chú:** chính sách thu trước và loại hàng đợi là thuộc tính của nhóm, nên đổi chính sách chỉ cần sửa một dòng danh mục. Doanh thu theo nhóm lấy từ `v_service_invoice_amounts.category_code` (clinical) hoặc `daily_revenue_summaries` (reporting).

### L3. `species` – Loài thú cưng
- Dùng cho hồ sơ thú cưng và khoảng tham chiếu xét nghiệm theo loài. Thêm loài mới (thỏ, chim...) = INSERT + khai báo khoảng tham chiếu.

### L4. `medicine_categories` – Nhóm thuốc
- Phục vụ lọc danh mục thuốc khi kê đơn và báo cáo doanh thu thuốc theo nhóm.

---

## C. ENUM JAVA LƯU DẠNG VARCHAR (18 ENUM)

| STT | Enum Java | Bảng & cột (`VARCHAR`) | Giá trị hợp lệ |
| :---: | :--- | :--- | :--- |
| **1** | `UserStatus` | `users.status` | `ACTIVE`, `LOCKED`, `INACTIVE` |
| **2** | `Gender` | `user_profiles.gender` | `MALE`, `FEMALE`, `OTHER` |
| **3** | `EmploymentType` | `staff_profiles.employment_type` | `FULL_TIME`, `PART_TIME` |
| **4** | `RegisteredChannel` | `pet_owner_profiles.registered_channel` | `ONLINE`, `AT_CLINIC` |
| **5** | `ContactChannel` | `pet_owner_profiles.preferred_contact` | `PHONE`, `EMAIL`, `APP` |
| **6** | `PetGender` | `pets.gender` | `MALE`, `FEMALE`, `UNKNOWN` |
| **7** | `BookingChannel` | `appointments.booking_channel` | `ONLINE`, `PHONE`, `WALK_IN` |
| **8** | `AppointmentStatus` | `appointments.status`; `appointment_status_histories.from_status`, `to_status` | `PENDING`, `CONFIRMED`, `CHECKED_IN`, `CANCELLED`, `NO_SHOW` |
| **9** | `VisitStatus` | `pet_visits.status`; `pet_visit_status_histories.from_status`, `to_status`; `visit_facts.current_status` | `WAITING`, `IN_PROGRESS`, `WAITING_RESULTS`, `RESULTS_READY`, `WAITING_PAYMENT`, `COMPLETED`, `CANCELLED` |
| **10** | `ServiceDetailStatus` | `visit_service_details.status`; `visit_service_detail_histories.from_status`, `to_status` | `PENDING`, `IN_PROGRESS`, `COMPLETED`, `CANCELLED` |
| **11** | `ServiceDetailAction` | `visit_service_detail_histories.action` | `ORDERED`, `START_PROCESSING`, `SAMPLE_COLLECTED`, `COMPLETED`, `CANCELLED` |
| **12** | `PaymentStatus` | `service_invoices.payment_status`; `medicine_invoices.payment_status` | `PENDING`, `PAID`, `CANCELLED`, `REFUNDED` (`REFUNDED` chỉ ở `service_invoices`) |
| **13** | `QueueType` | `service_categories.queue_type`; `queue_ticket_histories.queue_type`; Redis `ticket:{id}.queueType` | `DOCTOR`, `LABORATORY`, `IMAGING` |
| **14** | `TicketStatus` | Redis `ticket:{id}.status` (`WAITING`, `IN_SERVICE`); `queue_ticket_histories.final_status` (`DONE`, `CANCELLED`) | `WAITING`, `IN_SERVICE`, `DONE`, `CANCELLED` |
| **15** | `InventoryTransactionType` | `inventory_transactions.transaction_type` | `IMPORT`, `EXPORT_SALE`, `ADJUSTMENT` |
| **16** | `OutboxStatus` | `outbox_events.status` (4 CSDL) | `PENDING`, `PUBLISHED`, `FAILED` |
| **17** | `RevenueType` | `revenue_facts.revenue_type`; `daily_revenue_summaries.revenue_type` | `SERVICE`, `MEDICINE` |
| **18** | `RevenueEntryType` | `revenue_facts.entry_type` | `SALE`, `REFUND` |

**Enum chỉ dùng ở tầng ứng dụng (không có cột):** `LabEvaluation` (`LOW`, `NORMAL`, `HIGH`) – Mục 19.

---

## D. CHI TIẾT TỪNG ENUM

### 1. `UserStatus` – Trạng thái tài khoản
- `ACTIVE`: đang hoạt động. Số Bác sĩ `ACTIVE` dùng để tính sức chứa khung giờ (`Capacity = N_active × 2`).
- `LOCKED`: bị khóa (sai mật khẩu nhiều lần, vi phạm). Khi chuyển sang `LOCKED`, `auth-service` phát `UserStatusChangedEvent`; `clinical-service` chuyển các ca `WAITING` của Bác sĩ đó về danh sách chờ phân công.
- `INACTIVE`: ngừng sử dụng (nhân viên nghỉ việc). Đây là **xóa mềm**: tài khoản không bao giờ bị xóa cứng, nên mọi khóa ngoại logic cũ (`doctor_id`, `cashier_id`...) vẫn tra được và hiển thị "Đã khóa".

### 2. `Gender` – Giới tính người dùng
- `MALE`, `FEMALE`, `OTHER`; cột cho phép `NULL` (không bắt buộc khai).

### 3. `EmploymentType` – Hình thức làm việc
- `FULL_TIME`: toàn thời gian; `PART_TIME`: bán thời gian.

### 4. `RegisteredChannel` – Nguồn tạo hồ sơ khách hàng
- `ONLINE`: khách tự đăng ký trên Portal; `AT_CLINIC`: Lễ tân tạo khi tiếp đón khách vãng lai.

### 5. `ContactChannel` – Kênh liên hệ ưu tiên
- `PHONE`, `EMAIL`, `APP` (thông báo trong ứng dụng). Hệ thống không gửi SMS.

### 6. `PetGender` – Giới tính thú cưng
- `MALE`: đực; `FEMALE`: cái; `UNKNOWN`: chưa xác định.

### 7. `BookingChannel` – Kênh đặt lịch
- `ONLINE`: khách tự đặt (lịch tạo ở `PENDING`).
- `PHONE`: Lễ tân tạo khi khách gọi điện (lịch tạo ở `CONFIRMED`).
- `WALK_IN`: khách đến quầy đặt cho ngày khác (lịch tạo ở `CONFIRMED`).

### 8. `AppointmentStatus` – Trạng thái lịch hẹn
- `PENDING`: chờ Lễ tân xác nhận.
- `CONFIRMED`: đã xác nhận, giữ khung giờ.
- `CHECKED_IN`: khách đã đến, đợt khám đã được tạo (chuyển khi nhận `VisitCheckedInEvent`).
- `CANCELLED`: bị hủy; lý do ở `appointment_status_histories.notes`.
- `NO_SHOW`: quá `start_time + 30 phút` không đến.

### 9. `VisitStatus` – Vòng đời đợt khám
- `WAITING`: đã tiếp đón, chờ khám pha 1. Gồm **chờ nộp phí khám** (chưa có phiếu) hoặc **đã có phiếu `DOCTOR`** trên Redis (hàng đợi của Bác sĩ được chọn hoặc `UNASSIGNED`).
- `IN_PROGRESS`: Bác sĩ đang khám (pha 1 sơ bộ hoặc pha 2 kết luận). Bác sĩ ghi `medical_records`, `vital_signs`.
- `WAITING_RESULTS`: đã chỉ định cận lâm sàng; khách nộp tiền XN / CĐHA rồi mới có phiếu phòng.
- `RESULTS_READY`: đủ kết quả; hệ thống phát phiếu `DOCTOR` ưu tiên `priority = 1`.
- `WAITING_PAYMENT`: Bác sĩ đã chốt ca, khóa hồ sơ khám và đơn thuốc (phát `PrescriptionCreatedEvent`); chờ thu hóa đơn dịch vụ còn `PENDING`.
- `COMPLETED`: mọi hóa đơn dịch vụ đã `PAID` / `CANCELLED` / `REFUNDED` (hoặc đóng ca có công nợ theo EX-11). Việc mua thuốc không ảnh hưởng trạng thái này.
- `CANCELLED`: ca bị hủy; lý do ở `pet_visit_status_histories.notes`; phí khám đã thu không hoàn.
- **Ghi chú:** thời điểm bắt đầu khám / chốt ca / hoàn tất lấy từ `pet_visit_status_histories`.

### 10. `ServiceDetailStatus` – Trạng thái chỉ định dịch vụ
- `PENDING`: đã chỉ định, chưa làm. Với XN / CĐHA gồm **chờ nộp tiền** và **đã có phiếu phòng** (dịch vụ cùng đợt khám, cùng phòng gộp một phiếu trên Redis).
- `IN_PROGRESS`: KTV đã tiếp nhận / lấy mẫu.
- `COMPLETED`: đã nhập đủ kết quả hoặc tải ảnh và xác nhận.
- `CANCELLED`: bị hủy; hóa đơn: chưa thu → `CANCELLED`; đã thu mà khách tự hủy → giữ `PAID`; đã thu mà phòng khám không làm được → `REFUNDED`.

### 11. `ServiceDetailAction` – Thao tác trên chỉ định (Audit Trail)
- `ORDERED`, `START_PROCESSING`, `SAMPLE_COLLECTED`, `COMPLETED`, `CANCELLED`. "Gọi" / "Gọi lại" không ghi lịch sử vì không đổi trạng thái.

### 12. `PaymentStatus` – Trạng thái thanh toán hóa đơn
- `PENDING`: chờ thu. Hóa đơn phí khám tạo lúc check-in; hóa đơn dịch vụ khác tạo khi chỉ định. **Hóa đơn thuốc ở `PENDING` là hóa đơn nháp** do `billing-pharmacy-service` tự tạo khi nhận `PrescriptionCreatedEvent`; Thu ngân sửa số lượng theo khách mua rồi thu.
- `PAID`: đã thu (`cashier_id`, `paid_at`). Phí khám / XN / CĐHA chuyển `PAID` → phát `ServiceInvoicePaidEvent` qua outbox → phiếu xếp hàng được phát trên Redis. Hóa đơn thuốc chuyển `PAID` cùng giao dịch với trừ kho.
- `CANCELLED`: hủy hóa đơn chưa thu (dịch vụ bị hủy, khách mua thuốc bên ngoài).
- `REFUNDED` (chỉ `service_invoices`): hoàn tiền vì phòng khám không thực hiện được dịch vụ XN / CĐHA đã thu. Phí khám không hoàn. Phát `ServiceInvoiceRefundedEvent` để reporting ghi dòng doanh thu âm.

### 13. `QueueType` – Loại hàng đợi
- `DOCTOR`: hàng đợi phòng Bác sĩ (theo từng Bác sĩ, hoặc `UNASSIGNED`). Phát khi thu xong phí khám (`priority 0`), khi tiếp đón ca cấp cứu (`priority 2`), khi đủ kết quả CLS (`priority 1`).
- `LABORATORY`: hàng đợi phòng Xét nghiệm. `IMAGING`: hàng đợi phòng CĐHA.
- Lưu ở `service_categories.queue_type` (nhóm nào vào hàng đợi nào), ở phiếu trên Redis và ở `queue_ticket_histories`.

### 14. `TicketStatus` – Trạng thái phiếu xếp hàng
- `WAITING` (Redis): đang chờ gọi; thứ tự theo `score` của Sorted Set (ưu tiên cao trước, đến trước phục vụ trước). "Gọi" / "Gọi lại" chỉ tăng `calledCount`, cập nhật `lastCalledAt`.
- `IN_SERVICE` (Redis): đã bấm "Bắt đầu"; mỗi Bác sĩ tối đa 1 phiếu `IN_SERVICE` (kiểm tra trong Lua script).
- `DONE` (MySQL, `queue_ticket_histories.final_status`): đã phục vụ xong; phiếu bị xóa khỏi Redis.
- `CANCELLED` (MySQL): phiếu bị hủy (khách bỏ về, hủy hết dịch vụ của phiếu, hủy ca).
- Vòng đời ở SM-07 (`THIET_KE_SO_DO_TRANG_THAI_STATE_MACHINE.md`).

### 15. `InventoryTransactionType` – Loại biến động kho
- `IMPORT`: nhập kho (`quantity > 0`, có `unit_cost`).
- `EXPORT_SALE`: xuất khi bán theo hóa đơn thuốc đã thu (`quantity < 0`, bắt buộc `medicine_invoice_id`).
- `ADJUSTMENT`: cân chỉnh sau kiểm kê (`quantity` âm hoặc dương).
- Tồn sau giao dịch tính bằng tổng lũy kế, không lưu.

### 16. `OutboxStatus` – Trạng thái dòng outbox
- `PENDING`: vừa ghi cùng giao dịch nghiệp vụ, chờ `OutboxRelay` gửi.
- `PUBLISHED`: RabbitMQ đã xác nhận nhận (publisher confirm). Dòng `PUBLISHED` quá 7 ngày được xóa định kỳ.
- `FAILED`: gửi lỗi quá 10 lần; hiện ở màn hình quản trị để xử lý thủ công (gửi lại = đặt về `PENDING`).

### 17. `RevenueType` – Loại doanh thu (reporting)
- `SERVICE`: từ hóa đơn dịch vụ; `MEDICINE`: từ hóa đơn thuốc.

### 18. `RevenueEntryType` – Loại dòng doanh thu (reporting)
- `SALE`: đã thu (số tiền dương); `REFUND`: hoàn tiền (số tiền âm), để tổng doanh thu theo ngày luôn bằng tổng các dòng.

### 19. `LabEvaluation` – Đánh giá chỉ số xét nghiệm (chỉ ở tầng ứng dụng)
- **Không có cột trong CSDL**, tính khi hiển thị từ `lab_test_results.result_value` so với `min_value_snapshot` / `max_value_snapshot`.
- `LOW` (dưới ngưỡng, vàng), `NORMAL` (trong ngưỡng, xanh), `HIGH` (trên ngưỡng, đỏ).
- Lý do không lưu: thuộc tính dẫn xuất; KTV sửa giá trị đo mà quên sửa nhãn sẽ gây mâu thuẫn.

---

## E. ĐỐI CHIẾU VỚI PHIÊN BẢN 3.0

| v3.0 (ENUM MySQL) | v4.0 | Ghi chú |
| :--- | :--- | :--- |
| #1 `RoleCode` – `roles.code ENUM` | Bảng danh mục **L1** `roles` (`code VARCHAR(30)`) | Nhận xét #3; thêm `user_roles` (nhiều vai trò / tài khoản) |
| #2 `UserStatus` | #1 `UserStatus` (`VARCHAR`) | Ý nghĩa `INACTIVE` = xóa mềm |
| #3 `PetGender` | #6 `PetGender` | |
| #4 `BookingChannel` | #7 `BookingChannel` | |
| #5 `AppointmentStatus` | #8 `AppointmentStatus` | |
| #6 `VisitStatus` | #9 `VisitStatus` | Thêm cột dùng `visit_facts.current_status` |
| #7 `ServiceCategory` – `services.category ENUM` | Bảng danh mục **L2** `service_categories` | Nhận xét #3; `requires_prepayment` chuyển từ `services` về nhóm, thêm `queue_type` |
| #8 `ServiceDetailStatus` | #10 `ServiceDetailStatus` | |
| (cột `action` VARCHAR, chưa có enum) | #11 `ServiceDetailAction` | Chuẩn hóa thành enum Java |
| #9 `PaymentStatus` | #12 `PaymentStatus` | `PENDING` của hóa đơn thuốc = nháp tự tạo |
| #10 `InventoryTransactionType` | #15 | |
| #11 `QueueType` – `queue_tickets.queue_type` | #13 `QueueType` | Bảng `queue_tickets` bỏ; giá trị nằm ở Redis, `queue_ticket_histories`, `service_categories` |
| #12 `TicketStatus` – `queue_tickets.status` | #14 `TicketStatus` | `WAITING`, `IN_SERVICE` chỉ có trên Redis |
| – | #2 `Gender`, #3 `EmploymentType`, #4 `RegisteredChannel`, #5 `ContactChannel` | Thêm cùng các bảng hồ sơ người dùng (nhận xét về tách user) |
| – | #16 `OutboxStatus` | Thêm cùng Transactional Outbox (nhận xét #2) |
| – | #17 `RevenueType`, #18 `RevenueEntryType` | Thêm cùng `reporting-service` (nhận xét #1) |
| – | Bảng danh mục **L3** `species`, **L4** `medicine_categories` | `species` đã là bảng từ trước; `medicine_categories` thêm mới |
| `LabEvaluation` (Mục 13, chỉ ứng dụng) | Mục 19 (chỉ ứng dụng) | |

> Các tài liệu khác nhắc "12 enum" được cập nhật thành "4 bảng danh mục + 18 enum Java (VARCHAR)".

### Lịch sử trước v4.0 (tóm tắt)
- **v3.0 (10/11/2026):** bỏ `PrescriptionStatus`, `InvoiceItemType`; `LabEvaluation` chuyển thành enum chỉ ở ứng dụng.
- **13/11/2026:** bỏ giá trị `SKIPPED` của cột `action`.
- **16–17/11/2026:** thêm `QueueType`, `TicketStatus`; `PaymentStatus` thêm `REFUNDED`.
