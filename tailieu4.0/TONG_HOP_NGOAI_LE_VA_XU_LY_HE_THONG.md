# TỔNG HỢP CÁC TRƯỜNG HỢP NGOẠI LỆ VÀ CƠ CHẾ XỬ LÝ HỆ THỐNG
## HỆ THỐNG QUẢN LÝ PHÒNG KHÁM THÚ Y

> **Tài liệu phục vụ Báo cáo & Giải trình Đồ án tốt nghiệp Công nghệ Thông tin**  
> **Phiên bản:** 3.0 (đồng bộ với lược đồ CSDL v3.0, State Machine v3.0, Activity v3.0 và Đặc tả Use Case v3.0)  
> **Mục tiêu:** Liệt kê toàn diện các tình huống biên (Edge Cases), lỗi phát sinh và ngoại lệ nghiệp vụ (Business Exceptions) trong thực tế vận hành phòng khám thú y, cùng cơ chế điều phối và biến động trạng thái dữ liệu (Database State Transitions) chi tiết.

### Quy ước chung
- **Mọi lần đổi trạng thái** của lịch hẹn, đợt khám, chỉ định dịch vụ đều ghi 1 dòng lịch sử trong cùng giao dịch (`appointment_status_histories`, `pet_visit_status_histories`, `visit_service_detail_histories`). Lý do hủy và ghi chú nằm ở cột `notes` / `reason` của dòng lịch sử; thời điểm nằm ở `created_at` của dòng lịch sử. Bảng `pet_visits` **không còn** các cột `cancel_reason`, `started_at`, `closed_at`, `completed_at`.
- **Hóa đơn:** mỗi dịch vụ được chỉ định có 1 hóa đơn dịch vụ (`service_invoices`) tạo cùng lúc với chỉ định; thuốc có hóa đơn thuốc (`medicine_invoices`) chỉ khi khách mua tại phòng khám. Không lưu tổng tiền; số tiền tính qua VIEW `v_service_invoice_amounts`, `v_medicine_invoice_amounts`.
- **Thông báo cho chủ nuôi** được gửi qua ứng dụng / Cổng thông tin (`notification-service`). Hệ thống không tích hợp nhà cung cấp SMS.
- Mã chuyển trạng thái `T01`–`T14` tham chiếu bảng SM-01 trong `THIET_KE_SO_DO_TRANG_THAI_STATE_MACHINE.md`.

---

## MỤC LỤC TỔNG QUAN

1. [Bảng Ma trận Tổng hợp các Ngoại lệ Hệ thống](#1-bảng-ma-trận-tổng-hợp-các-ngoại-lệ-hệ-thống)
2. [Phân hệ 1: Đặt lịch hẹn & Hàng đợi Tiếp đón (Booking & Reception)](#2-phân-hệ-1-đặt-lịch-hẹn--hàng-đợi-tiếp-đón)
3. [Phân hệ 2: Khám lâm sàng & Điều phối Bác sĩ (Clinical Phase 1 & Dispatching)](#3-phân-hệ-2-khám-lâm-sàng--điều-phối-bác-sĩ)
4. [Phân hệ 3: Cận lâm sàng & 2 Hàng đợi Chuyên môn độc lập (Lab & Imaging)](#4-phân-hệ-3-cận-lâm-sàng--2-hàng-đợi-chuyên-môn-độc-lập)
5. [Phân hệ 4: Hội chẩn Giai đoạn 2, Hàng đợi Tái khám & Kê đơn (Clinical Phase 2)](#5-phân-hệ-4-hội-chẩn-giai-đoạn-2-hàng-đợi-tái-khám--kê-đơn)
6. [Phân hệ 5: Thanh toán Hóa đơn & Bán thuốc theo Đơn (Billing & Pharmacy)](#6-phân-hệ-5-thanh-toán-hóa-đơn--bán-thuốc-theo-đơn)
7. [Phụ lục: Thay đổi so với phiên bản 2.0](#phụ-lục-thay-đổi-so-với-phiên-bản-20)

---

## 1. BẢNG MA TRẬN TỔNG HỢP CÁC NGOẠI LỆ HỆ THỐNG

| Mã NL | Tên tình huống ngoại lệ | Phân hệ phát sinh | Bảng & Cột CSDL biến động | Trạng thái Trước $\rightarrow$ Sau | Giải pháp xử lý nghiệp vụ |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **EX-01** | Khách đặt hẹn không đến đúng giờ | Đặt lịch hẹn | `appointments.status`<br>`appointment_status_histories` | `CONFIRMED` $\rightarrow$ `NO_SHOW` | Quá `start_time` + 30 phút, tác vụ định kỳ tự đánh dấu vắng mặt, giải phóng chỗ cho khách tại sảnh. |
| **EX-02** | Khách vãng lai (Walk-in) không đặt lịch | Tiếp đón | `pet_visits.appointment_id`<br>`pet_visits.status`, `queue_order` | `NULL`<br>`[Tạo mới]` $\rightarrow$ `WAITING` | Lễ tân tiếp nhận linh hoạt, tạo tài khoản/hồ sơ tức thì, xếp vào hàng đợi Bác sĩ (hoặc danh sách chờ phân công). |
| **EX-03** | Khách bỏ về khi đang chờ | Tiếp đón | `pet_visits.status`<br>`pet_visit_status_histories.notes` | `WAITING` $\rightarrow$ `CANCELLED` | Lễ tân hủy ca, ca rời khỏi hàng đợi Bác sĩ (hoặc danh sách chờ phân công), lý do ghi vào `notes` của dòng lịch sử. |
| **EX-04** | Ca cấp cứu khẩn cấp chen ngang hàng đợi | Tiếp đón / Khám | `pet_visits.is_emergency` | `FALSE` $\rightarrow$ `TRUE` | Lên đầu danh sách chờ phân công, đầu hàng đợi của Bác sĩ được xếp và đầu hàng đợi phòng CLS, viền đỏ cảnh báo. |
| **EX-05** | Lễ tân xếp ca mới vào hàng đợi Bác sĩ đang có ca vừa có kết quả | Điều phối | `pet_visits.doctor_id`, `queue_order` | Ca mới: `WAITING` (vào hàng đợi)<br>Ca có kết quả: đứng đầu hàng đợi | Không chặn Lễ tân. Ca có kết quả đã được đặt lên đầu hàng đợi (sau ca cấp cứu) nên vẫn được gọi trước ca mới. |
| **EX-06** | Khách vắng mặt khi gọi vào phòng Xét nghiệm / CĐHA | Cận lâm sàng | `visit_service_details.status` (không đổi) | Giữ nguyên `PENDING`; không đổi `queue_order`, không ghi lịch sử | Gọi 2–3 lần không vào $\rightarrow$ KTV bấm "Gọi" ở ca khác; ca vắng giữ nguyên vị trí; khách quay lại thì "Gọi lại". Thông báo qua ứng dụng. |
| **EX-07** | Khách quay lại sau khi vắng mặt ở phòng máy | Cận lâm sàng | `visit_service_details.status` | `PENDING` $\rightarrow$ `IN_PROGRESS` (khi được gọi lại và vào phòng) | KTV bấm "Gọi lại" ở đúng ca đó rồi "Bắt đầu thực hiện"; hệ thống không theo dõi việc khách quay lại. |
| **EX-08** | Khách xin hủy 1 trong các dịch vụ cận lâm sàng | Cận lâm sàng | `visit_service_details.status`<br>`service_invoices.payment_status`<br>`pet_visits.status` | `PENDING` $\rightarrow$ `CANCELLED`<br>`PENDING` $\rightarrow$ `CANCELLED`<br>`WAITING_RESULTS` $\rightarrow$ `RESULTS_READY` | Hủy dịch vụ **và hóa đơn của dịch vụ đó** trong cùng giao dịch; nếu các dịch vụ còn lại đã xong thì ca chuyển sang có kết quả. |
| **EX-09** | CĐHA gọi số đúng lúc thú cưng đang lấy máu | Điều phối liên phòng | `visit_service_detail_histories.action` (dòng Lab: `START_PROCESSING` / `SAMPLE_COLLECTED`) | Dịch vụ CĐHA giữ `PENDING` | Hiện huy hiệu `[Đang lấy máu bên phòng Lab]` khi Lab chưa bấm "Đã lấy mẫu"; Bác sĩ CĐHA "Gọi" ca khác, thú cưng sang thì "Gọi lại". |
| **EX-10** | Bác sĩ gọi số nhưng khách chưa vào phòng (GĐ 1 hoặc GĐ 2) | Khám / Tái khám GĐ 2 | `pet_visits.status` (không đổi) | Giữ nguyên `WAITING` / `RESULTS_READY`; không đổi `queue_order` | Gọi 2–3 lần không vào $\rightarrow$ Bác sĩ bấm "Gọi" ca khác trong hàng đợi; ca vắng giữ nguyên vị trí; khách quay lại thì "Gọi lại". Không có bước chuyển trạng thái (bỏ T13). |
| **EX-11** | Khách bỏ về hẳn không quay lại đọc kết quả | CLS / Hội chẩn GĐ 2 | `pet_visits.status`<br>`visit_service_details.status`<br>`service_invoices.payment_status` | `RESULTS_READY` / `WAITING_RESULTS` $\rightarrow$ `COMPLETED` (T08 / T12)<br>Dịch vụ chưa làm $\rightarrow$ `CANCELLED`<br>Hóa đơn dịch vụ đã làm giữ `PENDING` (công nợ) | "Đóng ca / Khách bỏ về": lưu vĩnh viễn kết quả, **không tạo hóa đơn mới**; hóa đơn dịch vụ còn `PENDING` giữ làm công nợ. |
| **EX-12** | Bấm chốt đợt khám khi chưa nhập đủ thông tin | Kê đơn / Chốt ca | *Validation chặn lại* | Không đổi trạng thái | Yêu cầu nhập `diagnosis` (và cân nặng, thân nhiệt; hoàn tất / hủy dịch vụ tại phòng) trước khi chuyển sang thanh toán. |
| **EX-13** | Số lượng thuốc kê vượt quá tồn kho hiện tại | Kê đơn | *Cảnh báo, không chặn* | Đơn thuốc vẫn được lưu | Cảnh báo kho không đủ; Bác sĩ giữ nguyên (khách mua ngoài) hoặc đổi thuốc. |
| **EX-14** | Nhập tiền giảm giá vượt quá số tiền của hóa đơn | Thanh toán | *Validation chặn lại* (`service_invoices.discount_amount`, `medicine_invoices.discount_amount`) | Không cập nhật giảm giá | Giảm giá nhập trên **từng hóa đơn**, phải ≤ số tiền trước giảm của chính hóa đơn đó. |
| **EX-15** | Tồn kho thực tế bị thiếu tại thời điểm bán thuốc | Bán thuốc | *Database Transaction Rollback* (`medicines`, `inventory_transactions`, `medicine_invoices`) | Hóa đơn thuốc giữ `PENDING` | Rollback toàn bộ; Thu ngân sửa hóa đơn thuốc đang `PENDING` (giảm số lượng / bỏ thuốc thiếu) hoặc hủy để khách mua ngoài. Không phát sinh hoàn tiền. |
| **EX-16** | Cố tình bán / xuất kho lặp lại cho một đơn thuốc | Quầy Thu ngân / Tủ thuốc | `medicine_invoices.prescription_id` (UNIQUE)<br>`medicine_invoices.payment_status`, `version` | Đã `PAID` $\rightarrow$ Chặn lại | Mỗi đơn thuốc chỉ có 1 hóa đơn thuốc (kể cả đã hủy); hóa đơn đã `PAID` không xác nhận lại được. |

---

## 2. PHÂN HỆ 1: ĐẶT LỊCH HẸN & HÀNG ĐỢI TIẾP ĐÓN

### EX-01: Khách hàng đặt lịch hẹn nhưng không đến đúng giờ (No-show)
- **Bối cảnh thực tế:** Khách đặt hẹn khung 09:00, đã được Lễ tân xác nhận (`CONFIRMED`). Tuy nhiên đến 09:30 khách vẫn không có mặt.
- **Cơ chế xử lý nghiệp vụ:**
  - Để tránh chiếm dụng khung giờ của khách hàng khác, hệ thống áp dụng nguyên tắc: **Trễ quá 30 phút so với giờ bắt đầu khung hẹn** được tính là vắng mặt.
  - Tác vụ định kỳ (Scheduled Task) của `appointment-service` quét các lịch `CONFIRMED` có `appointment_date` + `start_time` + 30 phút < thời điểm hiện tại. Lễ tân cũng có thể bấm *"Xác nhận vắng mặt (No-show)"* thủ công sau khi liên hệ không được.
- **Biến động CSDL:**
  - Bảng `appointments`: Cột `status` chuyển từ `'CONFIRMED'` sang `'NO_SHOW'`.
  - Bảng `appointment_status_histories`: Ghi 01 dòng (`from_status = 'CONFIRMED'`, `to_status = 'NO_SHOW'`, `changed_by_user_id = NULL` nếu do tác vụ định kỳ hoặc id Lễ tân nếu bấm thủ công, `notes = 'Tự động đánh dấu vắng mặt do trễ quá 30 phút so với giờ hẹn'`). Thời điểm đánh dấu là `created_at` của dòng này.
  - Khung giờ được giải phóng để tiếp nhận ca vãng lai tại quầy.

### EX-02: Khách vãng lai (Walk-in) đến trực tiếp không qua đặt lịch
- **Bối cảnh thực tế:** Khách bế thú cưng đến thẳng phòng khám do bị bệnh đột ngột.
- **Cơ chế xử lý nghiệp vụ:**
  - Hệ thống áp dụng nguyên tắc **Liên kết lỏng (Loose Coupling)** giữa Lịch hẹn và Ca khám.
  - Lễ tân tra cứu số điện thoại:
    - Nếu là khách mới: Tạo nhanh tài khoản `users` (vai trò `PET_OWNER`) và tạo hồ sơ `pets`.
    - Nếu là khách quen: Chọn thú cưng có sẵn trong danh sách.
  - Hệ thống kiểm tra thú cưng không có đợt khám nào khác đang mở, rồi tạo đợt khám mới mà không cần chọn lịch hẹn.
- **Biến động CSDL:**
  - Bảng `pet_visits`: `appointment_id = NULL`, `status = 'WAITING'`, `checked_in_at = CURRENT_TIMESTAMP`, `queue_order` = thời điểm tiếp nhận (epoch micro giây), `receptionist_id` = Lễ tân tiếp đón, `doctor_id` = Bác sĩ được chọn (hoặc `NULL` nếu chưa xếp).
  - Bảng `pet_visit_status_histories`: Ghi 01 dòng (`from_status = NULL`, `to_status = 'WAITING'`).

### EX-03: Khách hàng tự ý bỏ về khi đang ngồi chờ ở sảnh
- **Bối cảnh thực tế:** Khách đã được tiếp nhận nhưng chờ lâu hoặc có việc bận đột xuất nên xin về trước khi vào phòng khám (kể cả khi đã nằm trong hàng đợi của một Bác sĩ).
- **Cơ chế xử lý nghiệp vụ:** Lễ tân bấm nút *"Hủy tiếp nhận"* trên bảng điều phối, chọn hoặc nhập lý do hủy (bắt buộc).
- **Biến động CSDL:**
  - Bảng `pet_visits`: Cột `status` chuyển từ `'WAITING'` sang `'CANCELLED'`.
  - Bảng `pet_visit_status_histories`: Ghi 01 dòng (`from_status = 'WAITING'`, `to_status = 'CANCELLED'`, `changed_by_user_id` = Lễ tân, `notes = 'Khách bận việc gia đình xin về'`).
  - Ca khám biến mất khỏi hàng đợi của Bác sĩ (hoặc danh sách chờ phân công); những người phía sau tự lên một bậc vì hàng đợi sắp theo `queue_order`.
  - Chưa có chỉ định dịch vụ nên không phát sinh hóa đơn.

### EX-04: Ca bệnh cấp cứu khẩn cấp chen ngang hàng đợi (Emergency Preemption)
- **Bối cảnh thực tế:** Thú cưng bị sốc phản vệ, tai nạn giao thông, co giật hoặc khó thở tím tái cần được cấp cứu ngay lập tức.
- **Cơ chế xử lý nghiệp vụ:**
  - Lễ tân tích chọn ô **"Ca cấp cứu khẩn cấp"** lúc tiếp nhận (hoặc Bác sĩ bật cờ khẩn cấp).
  - Thuật toán sắp xếp tự động đưa ca này lên **đầu** danh sách chờ phân công, đầu hàng đợi của Bác sĩ được xếp và đầu hàng đợi các phòng cận lâm sàng, kèm viền đỏ nhấp nháy cảnh báo. Lễ tân xếp ngay ca vào hàng đợi một Bác sĩ; Bác sĩ khám xong ca hiện tại sẽ gọi ca cấp cứu trước (đứng đầu hàng đợi).
  - Nếu gọi ca cấp cứu mà không thấy, Bác sĩ gọi ca khác; ca cấp cứu **giữ nguyên ưu tiên, vị trí đầu hàng và cảnh báo đỏ** (không còn bị lùi), khách quay lại thì "Gọi lại". *(Từ 13/11/2026; bản trước dùng "Đẩy lùi 1 bậc" nên ca cấp cứu mất ưu tiên ngay sau lần vắng đầu tiên.)*
- **Biến động CSDL:**
  - Bảng `pet_visits`: Cột `is_emergency = TRUE`.
  - Nhờ chỉ mục hỗn hợp `idx_visits_queue (doctor_id, status, is_emergency, queue_order)`, câu lệnh `ORDER BY is_emergency DESC, queue_order ASC` định vị ca này lên đầu hàng đợi của Bác sĩ với chi phí truy vấn $O(\log N)$.

---

## 3. PHÂN HỆ 2: KHÁM LÂM SÀNG & ĐIỀU PHỐI BÁC SĨ

### EX-05: Lễ tân xếp ca mới vào hàng đợi Bác sĩ đang có ca vừa có kết quả
- **Bối cảnh thực tế:** Trong hàng đợi của Bác sĩ A có 1 ca đi xét nghiệm 20 phút trước và vừa có kết quả (`RESULTS_READY`). Cùng lúc Lễ tân tiếp nhận một khách mới và muốn xếp vào hàng đợi Bác sĩ A.
- **Cơ chế xử lý nghiệp vụ (từ rà soát 11/11, thay cho Khóa ưu tiên):**
  - Lễ tân **không bị chặn**: mỗi Bác sĩ có hàng đợi riêng, Lễ tân xếp ca mới vào hàng đợi Bác sĩ A như bình thường (hệ thống vẫn gợi ý Bác sĩ ít người chờ nhất).
  - Khi ca chuyển `RESULTS_READY` (T06), hệ thống đã đặt `queue_order` của ca đó = giá trị nhỏ nhất trong hàng đợi Bác sĩ A − 1, nên ca có kết quả **đứng đầu hàng đợi** (chỉ sau ca cấp cứu). Ca mới xếp vào sau.
  - Khi Bác sĩ A bấm "Gọi số tiếp theo" (hoặc "Gọi" ở ca có kết quả), hệ thống gọi ca có kết quả trước. Khách cũ đã đợi xét nghiệm không bị khách mới chen lượt.
- **Biến động CSDL:**
  - Ca mới: `pet_visits.doctor_id` = Bác sĩ A, giữ `queue_order` theo thời điểm tiếp nhận.
  - Ca có kết quả: `queue_order` đã được đặt lại ở T06; không có bảng nào khác thay đổi.

---

## 4. PHÂN HỆ 3: CẬN LÂM SÀNG & 2 HÀNG ĐỢI CHUYÊN MÔN ĐỘC LẬP

### EX-06: Khách hàng vắng mặt khi gọi vào phòng Xét nghiệm / CĐHA
- **Bối cảnh thực tế:** Đến lượt làm xét nghiệm/siêu âm, hệ thống hiển thị thông báo gọi lượt nhưng chủ nuôi đưa thú cưng ra ngoài đi dạo hoặc đi vệ sinh.
- **Cơ chế xử lý nghiệp vụ (Gọi theo từng dòng — cập nhật 13/11/2026):**
  - Kỹ thuật viên bấm *"Gọi"* ở một ca bất kỳ trong hàng đợi phòng (hoặc *"Gọi số tiếp theo"* để gọi ca đứng đầu): hệ thống kích hoạt thông báo trên màn hình sảnh và ứng dụng của chủ nuôi. Dịch vụ **vẫn giữ `PENDING`**. Các dịch vụ `PENDING` của cùng một đợt khám trong cùng phòng là **một ca**, gọi một lần.
  - Gọi 2–3 lần (mỗi lần cách khoảng 60 giây) không thấy vào, Kỹ thuật viên bấm **"Gọi" ở ca khác**:
    - Dịch vụ của ca vắng **giữ nguyên `PENDING`** (chưa hao phí vật tư y tế); hóa đơn dịch vụ giữ nguyên `PENDING`.
    - Ca vắng **giữ nguyên vị trí**; hệ thống không đổi thứ tự và không đếm số lần vắng $\rightarrow$ **Phòng máy không bị treo** và không có vòng lặp hai ca đầu hàng đổi chỗ cho nhau.
    - Mỗi lần gọi gửi **thông báo trên ứng dụng / Cổng thông tin** cho chủ nuôi của ca được gọi (hệ thống không dùng SMS).
- **Biến động CSDL:**
  - Không có thay đổi dữ liệu hàng đợi: `visit_service_details.status` giữ `'PENDING'`, `queue_order` giữ nguyên, không ghi `visit_service_detail_histories` (chỉ phát `PatientCalledEvent` `action = CALLED` sau commit).
  - *(Cơ chế "Đẩy lùi 1 bậc" của bản v3.0 đầu — `skip_count + 1`, đổi `queue_order`, `action = 'SKIPPED'` — được bỏ vì làm hai ca đầu hàng đổi chỗ mãi mãi; cột `skip_count`, giá trị `SKIPPED` và API `skip` đã bị xóa.)*

### EX-07: Khách hàng quay lại phòng máy sau khi vắng mặt
- **Bối cảnh thực tế:** Khách hàng quay lại sảnh phòng khám sau khi nhận thông báo trên ứng dụng.
- **Cơ chế xử lý nghiệp vụ:**
  - Dịch vụ của khách **vẫn nằm đúng vị trí trong hàng đợi** (không bị lùi), nên khách không cần xếp hàng lại.
  - Kỹ thuật viên nhận thông báo hoặc khách báo tại quầy thì bấm *"Gọi lại"* ở đúng ca đó; khi thú cưng bước vào phòng thì bấm *"Bắt đầu thực hiện"* để chuyển sang `IN_PROGRESS`. Hệ thống không theo dõi việc khách quay lại.
- **Biến động CSDL:**
  - Bảng `visit_service_detail_histories`: Ghi dòng `action = 'START_PROCESSING'` khi bắt đầu làm.
  - Bảng `visit_service_details`: Cột `status` chuyển từ `'PENDING'` sang `'IN_PROGRESS'`.

### EX-08: Khách hàng xin hủy 1 trong các dịch vụ cận lâm sàng giữa chừng
- **Bối cảnh thực tế:** Bác sĩ chỉ định cả Xét nghiệm máu và Siêu âm bụng. Thú cưng đã lấy máu xong và có kết quả (`COMPLETED`), nhưng khi sang phòng CĐHA, thú cưng quá hoảng loạn/hung dữ hoặc chủ nuôi không đủ kinh phí nên xin hủy không siêu âm nữa.
- **Cơ chế xử lý nghiệp vụ:**
  - Bác sĩ CĐHA chọn thao tác *"Hủy dịch vụ"* trên dòng siêu âm, nhập lý do hủy.
  - Điều kiện: hóa đơn của dịch vụ siêu âm chưa `PAID` (hoàn tiền nằm ngoài phạm vi).
  - Trong **cùng một giao dịch**, dịch vụ siêu âm chuyển `CANCELLED` **và hóa đơn dịch vụ của siêu âm chuyển `CANCELLED`**. Hóa đơn của xét nghiệm máu giữ nguyên `PENDING`.
  - Hệ thống kiểm tra: tất cả dịch vụ cận lâm sàng còn lại của ca đều đã `COMPLETED` hoặc `CANCELLED` $\rightarrow$ ca tự động chuyển sang `RESULTS_READY` (T06) để Bác sĩ khám chính hội chẩn dựa trên kết quả xét nghiệm máu.
- **Biến động CSDL:**
  - Bảng `visit_service_details`: Dòng Siêu âm chuyển `status = 'CANCELLED'`.
  - Bảng `visit_service_detail_histories`: Ghi dòng `action = 'CANCELLED'`, `reason` = lý do hủy.
  - Bảng `service_invoices`: Hóa đơn của dòng Siêu âm chuyển `payment_status = 'CANCELLED'`, không tính vào doanh thu.
  - Bảng `pet_visits`: Cột `status` chuyển từ `'WAITING_RESULTS'` sang `'RESULTS_READY'`; ghi 01 dòng `pet_visit_status_histories` (`changed_by_user_id = NULL` – hệ thống tự chuyển).

### EX-09: Phòng Chẩn đoán hình ảnh gọi số đúng lúc thú cưng đang lấy máu bên phòng Lab
- **Bối cảnh thực tế:** Phòng CĐHA vắng khách, đến lượt ca này trong hàng đợi CĐHA nhưng thú cưng đang ở phòng Lab lấy ven.
- **Dữ liệu để phân biệt:** Quy trình Lab có 2 thao tác ghi lịch sử: *"Bắt đầu thực hiện"* (`action = 'START_PROCESSING'`, thú cưng đang ở phòng Lab) và *"Đã lấy mẫu"* (`action = 'SAMPLE_COLLECTED'`, thú cưng đã rời phòng, máy đang phân tích). Nhờ đó hệ thống phân biệt được "đang lấy máu" với "máy đang chạy".
- **Cơ chế xử lý nghiệp vụ:**
  - Khi dịch vụ Lab của cùng ca đang `IN_PROGRESS` **và** `action` mới nhất là `START_PROCESSING`, màn hình CĐHA hiển thị huy hiệu `🟡 [Đang lấy máu bên phòng Lab]`. Khi `action` mới nhất là `SAMPLE_COLLECTED`, huy hiệu đổi thành `🟢 [Đã lấy máu, sẵn sàng chụp]`.
  - Nếu đang lấy máu, Bác sĩ CĐHA bấm *"Gọi"* ở ca khác (EX-06): dịch vụ CĐHA giữ `PENDING` và giữ nguyên vị trí, phòng gọi ngay người khác vào siêu âm.
  - Thú cưng lấy máu xong sang phòng CĐHA thì Bác sĩ CĐHA bấm *"Gọi lại"* rồi *"Bắt đầu thực hiện"*.
- **Biến động CSDL:**
  - Bảng `visit_service_details` (dòng CĐHA): Giữ nguyên `'PENDING'`.
  - Giá trị `SAMPLE_COLLECTED` là giá trị mới của cột `action` (`VARCHAR(50)`), không thay đổi cấu trúc bảng.

---

## 5. PHÂN HỆ 4: HỘI CHẨN GIAI ĐOẠN 2, HÀNG ĐỢI TÁI KHÁM & KÊ ĐƠN

### EX-10: Bác sĩ gọi số nhưng khách chưa vào phòng (Giai đoạn 1 hoặc Giai đoạn 2)
- **Bối cảnh thực tế:** Đến lượt trong hàng đợi của Bác sĩ (ca mới `WAITING` hoặc ca có kết quả `RESULTS_READY`), Bác sĩ bấm *"Gọi"* nhưng khách bận ra ngoài nghe điện thoại.
- **Cơ chế xử lý nghiệp vụ (cập nhật 13/11/2026):**
  - Bác sĩ **gọi số trước, đổi trạng thái sau**: bấm *"Gọi"* (hoặc *"Gọi số tiếp theo"*) chỉ phát thông báo (`PatientCalledEvent`), ca giữ nguyên trạng thái và thứ tự; chỉ khi thú cưng vào phòng Bác sĩ mới bấm *"Bắt đầu khám"* (T02) hoặc *"Bắt đầu Giai đoạn 2"* (T07).
  - Thông báo gọi 2–3 lần không vào, Bác sĩ bấm **"Gọi" ở ca khác** trong hàng đợi:
    - Ca vắng giữ nguyên `WAITING` / `RESULTS_READY` và **giữ nguyên vị trí** (ca có kết quả vẫn đứng đầu; ca cấp cứu vẫn giữ ưu tiên và cảnh báo).
    - Hệ thống không đổi `queue_order`, không đếm số lần vắng; do đó không xảy ra vòng lặp hai ca đầu hàng đổi chỗ cho nhau.
    - Bác sĩ vẫn `AVAILABLE` (chưa khám ai) nên gọi tiếp được ngay; không cần tab "Đã hoãn".
  - Khi khách quay lại (Bác sĩ nhận thông báo hoặc khách báo tại quầy): Bác sĩ bấm *"Gọi lại"* ở đúng ca đó, rồi bắt đầu khám như bình thường.
- **Biến động CSDL:**
  - Không có thay đổi: `pet_visits.status` và `queue_order` giữ nguyên; không ghi `pet_visit_status_histories`. Bước chuyển T13 (hoãn ngược `IN_PROGRESS → RESULTS_READY`) của bản trước được bỏ.
  - *(Cơ chế "Đẩy lùi 1 bậc" của bản v3.0 đầu và cột `skip_count` đã bị xóa.)*

### EX-11: Khách hàng bỏ về hẳn không quay lại đọc kết quả cận lâm sàng
- **Bối cảnh thực tế:** Khách đã làm xét nghiệm và chụp chiếu (hoặc mới làm xong một phần) nhưng tự ý bế thú cưng về nhà; Lễ tân gọi điện xác nhận khách không quay lại, hoặc đã hết ngày làm việc.
- **Cơ chế xử lý nghiệp vụ:**
  - Lễ tân hoặc Bác sĩ chọn thao tác **"Đóng ca / Khách bỏ về"**. Áp dụng khi ca đang `RESULTS_READY` (T08) hoặc `WAITING_RESULTS` (T12; chỉ khi không có dịch vụ nào đang `IN_PROGRESS`).
  - Dịch vụ cận lâm sàng còn `PENDING` (chưa làm) bị hủy cùng hóa đơn của chúng.
  - Khóa chuyên môn đợt khám: các kết quả xét nghiệm/CĐHA đã làm được lưu vĩnh viễn vào Lịch sử bệnh án của thú cưng.
  - **Không tạo hóa đơn mới.** Các hóa đơn của dịch vụ đã thực hiện (phí khám, dịch vụ CLS đã `COMPLETED`) đã được lập từ lúc chỉ định, nay tiếp tục giữ `PENDING` làm **công nợ** của khách, được thu ở lần ghé khám tiếp theo (UC-34_35, Luồng 1a).
- **Biến động CSDL:**
  - Bảng `pet_visits`: Cột `status` chuyển từ `'RESULTS_READY'` (hoặc `'WAITING_RESULTS'`) sang `'COMPLETED'`.
  - Bảng `pet_visit_status_histories`: Ghi 01 dòng, `notes = 'Khách bỏ về, đóng ca ghi công nợ'`. Thời điểm đóng ca là `created_at` của dòng này.
  - Bảng `visit_service_details` / `service_invoices`: dịch vụ chưa làm $\rightarrow$ `CANCELLED` (hóa đơn tương ứng $\rightarrow$ `CANCELLED`); hóa đơn của dịch vụ đã làm giữ `payment_status = 'PENDING'`.
  - Công nợ của khách = tổng số tiền các `service_invoices` còn `PENDING` thuộc những đợt khám đã `COMPLETED` (truy vấn qua `v_service_invoice_amounts`).

### EX-12: Bác sĩ bấm chốt đợt khám khi thông tin bắt buộc đang để trống
- **Bối cảnh thực tế:** Bác sĩ quên nhập kết luận chẩn đoán bệnh (hoặc chưa nhập cân nặng, thân nhiệt; hoặc còn dịch vụ tại phòng chưa đánh dấu thực hiện) mà bấm luôn nút *"Chốt đợt khám / Chuyển thanh toán"*.
- **Cơ chế xử lý nghiệp vụ:** Tầng giao diện và Backend Validation chặn lại: *"Vui lòng nhập kết luận chẩn đoán và hoàn tất các dịch vụ đã chỉ định trước khi chốt đợt khám"*. Cân nặng (`weight_at_visit`) và thân nhiệt (`temperature`) cũng là điều kiện khi Bác sĩ gửi chỉ định cận lâm sàng.
- **Biến động CSDL:** Không thay đổi CSDL; đợt khám giữ nguyên trạng thái `'IN_PROGRESS'`.

### EX-13: Số lượng thuốc kê trong đơn vượt quá tồn kho hiện tại
- **Bối cảnh thực tế:** Bác sĩ kê 10 vỉ thuốc *Clavamox 250mg*, nhưng trong tủ thuốc phòng khám chỉ còn 6 vỉ.
- **Cơ chế xử lý nghiệp vụ:**
  - Hệ thống so sánh số lượng kê với `medicines.stock_quantity` hiện tại.
  - Hiển thị cảnh báo màu vàng: *"Tồn kho hiện tại (6) không đủ số lượng kê (10). Khách có thể phải mua thuốc này ở nơi khác."*
  - **Không chặn lưu đơn**, vì từ v3.0 khách có quyền mua thuốc tại phòng khám hoặc mua ngoài (BR-32). Bác sĩ chọn giữ nguyên số lượng hoặc giảm số lượng / kê thuốc thay thế.
  - Tồn kho chỉ thực sự được kiểm tra chặt (và bị chặn) tại thời điểm bán thuốc (EX-15).
- **Biến động CSDL:** `prescription_items` lưu số lượng Bác sĩ quyết định; không đụng tới tồn kho.

---

## 6. PHÂN HỆ 5: THANH TOÁN HÓA ĐƠN & BÁN THUỐC THEO ĐƠN

### EX-14: Thu ngân nhập số tiền giảm giá lớn hơn số tiền của hóa đơn
- **Bối cảnh thực tế:** Hóa đơn dịch vụ Siêu âm bụng có số tiền 300,000 VNĐ (đã gồm VAT) nhưng Thu ngân gõ nhầm số tiền giảm giá thành 350,000 VNĐ.
- **Cơ chế xử lý nghiệp vụ:**
  - Giảm giá được nhập **trên từng hóa đơn** (từng hóa đơn dịch vụ, hoặc hóa đơn thuốc), không nhập một lần cho cả ca.
  - Điều kiện kiểm tra:
    - Hóa đơn dịch vụ: `discount_amount <= quantity × unit_price × (1 + vat_rate)` của chính hóa đơn đó.
    - Hóa đơn thuốc: `discount_amount <=` tổng `quantity × unit_price × (1 + vat_rate)` của các dòng thuốc trong hóa đơn.
  - Vi phạm thì hệ thống chặn tại giao diện và Backend: *"Số tiền giảm giá không được vượt quá số tiền của hóa đơn này"*. Ngăn chặn hóa đơn âm tiền.
- **Biến động CSDL:** Không cập nhật `discount_amount`; hóa đơn giữ nguyên trạng thái `PENDING`. CSDL có thêm ràng buộc `CHECK (discount_amount >= 0)`.

### EX-15: Tồn kho thực tế bị thiếu hụt tại thời điểm bán thuốc (Race Condition)
- **Bối cảnh thực tế:** Lúc Thu ngân lập hóa đơn thuốc thì thuốc còn 2 lọ. Trong lúc khách đi lấy tiền, một quầy khác đã bán 2 lọ đó cho khách khác. Đến khi Thu ngân bấm *"Xác nhận thanh toán & Xuất thuốc"* thì kho đã hết.
- **Cơ chế xử lý nghiệp vụ (Database Transaction Rollback):**
  - Hệ thống thực thi việc bán thuốc trong **một giao dịch an toàn** (`@Transactional`, `billing-pharmacy-service`). Với mỗi dòng thuốc:
    - `UPDATE medicines SET stock_quantity = stock_quantity - :qty WHERE id = :id AND stock_quantity >= :qty`.
    - Nếu câu lệnh ảnh hưởng 0 dòng $\rightarrow$ thiếu hàng $\rightarrow$ kích hoạt `Rollback` toàn bộ giao dịch.
  - Hiển thị thông báo: *"Thuốc [Tên thuốc] hiện không đủ tồn kho. Vui lòng giảm số lượng hoặc bỏ thuốc này khỏi hóa đơn"*.
  - Thu ngân xử lý theo lựa chọn của khách:
    - **Sửa hóa đơn thuốc đang `PENDING`** (`PUT /api/v1/billing/medicine-invoices/{id}/items`): giảm số lượng hoặc bỏ dòng thuốc thiếu, giữ nguyên snapshot giá của các dòng còn lại, kiểm tra lại giảm giá (EX-14), rồi xác nhận lại. Không lập hóa đơn mới, vì `prescription_id` là `UNIQUE`.
    - Hoặc hủy hóa đơn thuốc để khách mua ngoài theo đơn in. Hủy là thao tác kết thúc: đơn thuốc này không lập lại hóa đơn thuốc.
  - **Không phát sinh hoàn tiền:** hóa đơn thuốc chưa từng ở trạng thái `PAID`, tiền dịch vụ nằm ở hóa đơn khác và đợt khám đã `COMPLETED` độc lập. Thu ngân chỉ thu theo số tiền mới hoặc trả lại khoản tiền thuốc vừa nhận.
- **Biến động CSDL:**
  - Bảng `medicines`: Cột `stock_quantity` giữ nguyên, không bị trừ âm (thêm lớp bảo vệ `CHECK (stock_quantity >= 0)`).
  - Bảng `medicine_invoices`: `payment_status` giữ nguyên `'PENDING'`.
  - Bảng `inventory_transactions`: Không ghi nhận giao dịch `EXPORT_SALE` nào.
  - Đơn thuốc (`prescriptions`) không có trạng thái nên không bị ảnh hưởng.

### EX-16: Cố tình hoặc thao tác nhầm bán / xuất kho lặp lại cho một đơn thuốc
- **Bối cảnh thực tế:** Nhân viên nhấn đúp chuột vào nút *"Xác nhận thanh toán & Xuất thuốc"*, hoặc cố lập thêm một hóa đơn thuốc cho đơn thuốc đã bán 5 phút trước.
- **Cơ chế xử lý nghiệp vụ (Ngăn chặn bán trùng):**
  - **Chặn lập hóa đơn thứ hai:** `medicine_invoices.prescription_id` là `UNIQUE`, nên mỗi đơn thuốc chỉ có tối đa 1 hóa đơn thuốc (kể cả hóa đơn đã hủy). Muốn đổi thuốc / số lượng thì sửa hóa đơn đang `PENDING`, không lập hóa đơn mới. Ứng dụng kiểm tra trước và hiển thị: *"Đơn thuốc này đã có hóa đơn thuốc [Mã] ([Trạng thái])"*; nếu hai yêu cầu đến cùng lúc, ràng buộc `UNIQUE` của CSDL từ chối yêu cầu đến sau.
  - **Chặn xác nhận lại:** việc xác nhận chỉ thực hiện khi hóa đơn đang `PENDING`; hóa đơn đã `PAID` bị từ chối. Cột `version` (khóa lạc quan) đảm bảo khi hai lần bấm gần như đồng thời, chỉ một lần cập nhật thành công.
- **Biến động CSDL:** Không trừ kho lần 2, không ghi thêm `inventory_transactions`; số lượng tồn kho được bảo toàn chính xác.

---

## TỔNG KẾT KIẾN TRÚC TOÀN VẸN DỮ LIỆU
Toàn bộ 16 trường hợp ngoại lệ trên được thiết kế đồng bộ và nhất quán với các tài liệu sau (cùng thư mục đồ án):
1. **Schema CSDL & Chỉ mục:** [schema_init.sql](schema_init.sql)
2. **Từ điển dữ liệu & Quan hệ:** [THIET_KE_CO_SO_DU_LIEU_ERD.md](THIET_KE_CO_SO_DU_LIEU_ERD.md)
3. **Chuẩn hóa Kiểu liệt kê ENUM:** [DANH_SACH_KIEU_ENUM_HE_THONG.md](DANH_SACH_KIEU_ENUM_HE_THONG.md)
4. **Sơ đồ trạng thái & hoạt động:** [THIET_KE_SO_DO_TRANG_THAI_STATE_MACHINE.md](THIET_KE_SO_DO_TRANG_THAI_STATE_MACHINE.md) · [THIET_KE_SO_DO_HOAT_DONG_ACTIVITY.md](THIET_KE_SO_DO_HOAT_DONG_ACTIVITY.md)
5. **Tài liệu Nghiệp vụ tổng thể:** [TAI_LIEU_MO_TA_NGHIEP_VU_PHONG_KHAM_THU_Y.md](TAI_LIEU_MO_TA_NGHIEP_VU_PHONG_KHAM_THU_Y.md)
6. **Đặc tả Chi tiết Use Case:** [DAC_TA_USE_CASE_CORE.md](DAC_TA_USE_CASE_CORE.md)

---

## PHỤ LỤC: THAY ĐỔI SO VỚI PHIÊN BẢN 2.0

| Mã | Bản 2.0 | Bản 3.0 | Lý do |
| :--- | :--- | :--- | :--- |
| EX-01 | `updated_at = NOW()`; quét "cuối khung giờ" | Không có `updated_at`; điều kiện `appointment_date` + `start_time` + 30 phút | Cột không tồn tại trong `appointments`; khớp tên cột thực tế |
| EX-03 | Ghi `cancel_reason` | Lý do ghi vào `pet_visit_status_histories.notes`; Bác sĩ đã gán tự được giải phóng | Bỏ cột `cancel_reason` |
| EX-05 | `COUNT(RESULTS_READY) > 0` | Chỉ tính ca vừa có kết quả (chưa bị hoãn); ca `WAITING` đã gán tính là `BUSY` | Công thức SM-02 v3.0 |
| EX-06 | Gửi "SMS/App" | Chỉ thông báo qua ứng dụng; ghi `action = POSTPONED` | Hệ thống không có nhà cung cấp SMS |
| EX-08 | "Hóa đơn chỉ tính tiền dịch vụ đã làm" | Hủy dịch vụ ⇒ hóa đơn của dịch vụ đó `CANCELLED` cùng giao dịch | Hóa đơn riêng cho từng dịch vụ |
| EX-09 | Không có dữ liệu phân biệt "đang lấy máu" | Thêm thao tác "Đã lấy mẫu" (`action = SAMPLE_COLLECTED`) | Huy hiệu có căn cứ dữ liệu |
| EX-10 | Giữ `RESULTS_READY`, không có nơi lưu "đã hoãn" | Gọi → `IN_PROGRESS`, hoãn → `RESULTS_READY`; dấu hiệu "đã hoãn" là `from_status = IN_PROGRESS` của dòng lịch sử | Hết mâu thuẫn với công thức trạng thái Bác sĩ |
| EX-11 | `closed_at`, `completed_at`; tạo hóa đơn nợ mới trong `invoices` | Ghi lịch sử; giữ các hóa đơn dịch vụ `PENDING` làm công nợ; áp dụng cả khi `WAITING_RESULTS` | Bỏ cột thời điểm; hóa đơn sinh lúc chỉ định; không mất doanh thu |
| EX-12 | Chỉ kiểm tra `diagnosis` | Thêm cân nặng, thân nhiệt và dịch vụ tại phòng | Đồng bộ guard T04 / T05 / T09 |
| EX-13 | Chặn không cho thêm thuốc | Chỉ cảnh báo | Khách được mua thuốc ngoài |
| EX-14 | Giảm giá ≤ tổng viện phí của ca; `invoices` | Giảm giá ≤ số tiền của từng hóa đơn; `service_invoices` / `medicine_invoices` | Bỏ hóa đơn gộp |
| EX-15 | Xuất kho sau khi đã thu viện phí; giữ `PRESCRIBED`; "báo Bác sĩ đổi thuốc" | Xảy ra lúc bán thuốc; hóa đơn thuốc giữ `PENDING`; khách giảm số lượng hoặc mua ngoài | Bỏ trạng thái đơn thuốc; thu tiền và trừ kho cùng giao dịch |
| EX-16 | Dựa vào `prescriptions.status = DISPENSED` | Dựa vào `medicine_invoices.prescription_id UNIQUE` và trạng thái `PAID` + `version` | Bỏ `PrescriptionStatus` |
| Liên kết tài liệu | Đường dẫn tuyệt đối `file:///c:/Users/...` | Đường dẫn tương đối trong thư mục đồ án | Mở được trên máy mọi thành viên / GitHub |
| EX-15, EX-16 (rà soát 10/11) | "Giảm số lượng rồi xác nhận lại" nhưng không có cách sửa hóa đơn; hóa đơn thứ hai bị `UNIQUE` chặn | Sửa dòng hóa đơn thuốc khi `PENDING` qua API riêng; hủy hóa đơn là kết thúc | Luồng xử lý thực hiện được với ràng buộc `prescription_id UNIQUE` |
| EX-02 → EX-07, EX-09, EX-10 (rà soát 11/11) | Hàng đợi sảnh chung; EX-05 Khóa ưu tiên chặn Lễ tân; EX-06 tạm hoãn sang tab riêng; EX-07 Recall ghim "Ưu tiên kế tiếp"; EX-09 tạm hoãn + Recall; EX-10 hoãn ngược `IN_PROGRESS → RESULTS_READY` (T13) | Hàng đợi riêng từng Bác sĩ; EX-05 không chặn, ca có kết quả đã đứng đầu hàng đợi; EX-06, EX-09, EX-10 "Đẩy lùi 1 bậc" (xếp ra sau người kế tiếp, không giới hạn); EX-07 khách quay lại chỉ chờ tới lượt | Lễ tân không phải chờ Bác sĩ rảnh; một cơ chế gọi số cho phòng khám, Xét nghiệm, CĐHA |
| EX-04, EX-05, EX-06, EX-07, EX-09, EX-10 (cập nhật 13/11) | "Đẩy lùi 1 bậc": ca vắng xuống ngay sau người kế tiếp, `skip_count + 1`, ghi `SKIPPED`; ca cấp cứu bị lùi mất ưu tiên; mỗi dịch vụ CLS một dòng hàng đợi | "Gọi" ở ca khác, ca vắng giữ nguyên vị trí; khách quay lại thì "Gọi lại"; ca cấp cứu giữ ưu tiên; dịch vụ cùng đợt khám, cùng phòng gộp một ca | Đẩy lùi 1 bậc làm hai ca đầu hàng đổi chỗ mãi mãi (ca thứ 3, 4 không được gọi) và làm ca cấp cứu mất cảnh báo; gọi theo từng dòng giống thực tế |
