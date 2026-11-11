# TỔNG HỢP CÁC TRƯỜNG HỢP NGOẠI LỆ VÀ CƠ CHẾ XỬ LÝ HỆ THỐNG
## HỆ THỐNG QUẢN LÝ PHÒNG KHÁM THÚ Y

> **Tài liệu phục vụ Báo cáo & Giải trình Đồ án tốt nghiệp Công nghệ Thông tin**  
> **Phiên bản:** 3.0 (đồng bộ với lược đồ CSDL v3.0, State Machine v3.0, Activity v3.0 và Đặc tả Use Case v3.0)  
> **Cập nhật 11/11/2026 – Hàng đợi riêng theo phòng:** viết lại EX-03, EX-04, EX-05, EX-06, EX-07, EX-09, EX-10 theo cơ chế mỗi phòng một hàng đợi, phân công không phụ thuộc trạng thái Bác sĩ và **lùi 1 bậc** khi khách vắng mặt (BR-11, BR-34 trong `DAC_TA_USE_CASE_CORE.md`).  
> **Mục tiêu:** Liệt kê toàn diện các tình huống biên (Edge Cases), lỗi phát sinh và ngoại lệ nghiệp vụ (Business Exceptions) trong thực tế vận hành phòng khám thú y, cùng cơ chế điều phối và biến động trạng thái dữ liệu (Database State Transitions) chi tiết.

### Quy ước chung
- **Mọi lần đổi trạng thái** của lịch hẹn, đợt khám, chỉ định dịch vụ đều ghi 1 dòng lịch sử trong cùng giao dịch (`appointment_status_histories`, `pet_visit_status_histories`, `visit_service_detail_histories`). Lý do hủy và ghi chú nằm ở cột `notes` / `reason` của dòng lịch sử; thời điểm nằm ở `created_at` của dòng lịch sử. Bảng `pet_visits` **không còn** các cột `cancel_reason`, `started_at`, `closed_at`, `completed_at`.
- **Hóa đơn:** mỗi dịch vụ được chỉ định có 1 hóa đơn dịch vụ (`service_invoices`) tạo cùng lúc với chỉ định; thuốc có hóa đơn thuốc (`medicine_invoices`) chỉ khi khách mua tại phòng khám. Không lưu tổng tiền; số tiền tính qua VIEW `v_service_invoice_amounts`, `v_medicine_invoice_amounts`.
- **Thông báo cho chủ nuôi** được gửi qua ứng dụng / Cổng thông tin (`notification-service`). Hệ thống không tích hợp nhà cung cấp SMS.
- Mã chuyển trạng thái `T01`–`T14` tham chiếu bảng SM-01 trong `THIET_KE_SO_DO_TRANG_THAI_STATE_MACHINE.md` (T13 đã bỏ từ 11/11).
- **Hàng đợi (cập nhật 11/11):** mỗi Bác sĩ (phòng khám cố định), phòng Xét nghiệm và phòng CĐHA có **một hàng đợi riêng**, không có hàng đợi chung. Thứ tự trong hàng đợi lưu ở `queue_position` (`pet_visits` cho hàng đợi phòng khám, `visit_service_details` cho hàng đợi phòng CLS). **Lùi 1 bậc** = hoán đổi `queue_position` với ca liền sau trong cùng hàng đợi, không đổi trạng thái; ghi 1 dòng lịch sử `action = 'SKIPPED'`. Số lần lùi được đếm từ lịch sử, không lưu cột riêng. Chi tiết ở mục 2.4 của tài liệu State Machine. *(Các cột `queue_position` và `pet_visit_status_histories.action` cần bổ sung vào `schema_init.sql` và ERD.)*

---

## MỤC LỤC TỔNG QUAN

1. [Bảng Ma trận Tổng hợp các Ngoại lệ Hệ thống](#1-bảng-ma-trận-tổng-hợp-các-ngoại-lệ-hệ-thống)
2. [Phân hệ 1: Đặt lịch hẹn & Hàng đợi Tiếp đón (Booking & Reception)](#2-phân-hệ-1-đặt-lịch-hẹn--hàng-đợi-tiếp-đón)
3. [Phân hệ 2: Khám lâm sàng & Điều phối Bác sĩ (Clinical Phase 1 & Dispatching)](#3-phân-hệ-2-khám-lâm-sàng--điều-phối-bác-sĩ)
4. [Phân hệ 3: Cận lâm sàng, Gọi số & Vắng mặt – Lùi 1 bậc (áp dụng mọi hàng đợi)](#4-phân-hệ-3-cận-lâm-sàng-gọi-số--vắng-mặt--lùi-1-bậc)
5. [Phân hệ 4: Hội chẩn Giai đoạn 2, Hàng đợi Tái khám & Kê đơn (Clinical Phase 2)](#5-phân-hệ-4-hội-chẩn-giai-đoạn-2-hàng-đợi-tái-khám--kê-đơn)
6. [Phân hệ 5: Thanh toán Hóa đơn & Bán thuốc theo Đơn (Billing & Pharmacy)](#6-phân-hệ-5-thanh-toán-hóa-đơn--bán-thuốc-theo-đơn)
7. [Phụ lục: Thay đổi so với phiên bản 2.0](#phụ-lục-thay-đổi-so-với-phiên-bản-20)

---

## 1. BẢNG MA TRẬN TỔNG HỢP CÁC NGOẠI LỆ HỆ THỐNG

| Mã NL | Tên tình huống ngoại lệ | Phân hệ phát sinh | Bảng & Cột CSDL biến động | Trạng thái Trước $\rightarrow$ Sau | Giải pháp xử lý nghiệp vụ |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **EX-01** | Khách đặt hẹn không đến đúng giờ | Đặt lịch hẹn | `appointments.status`<br>`appointment_status_histories` | `CONFIRMED` $\rightarrow$ `NO_SHOW` | Quá `start_time` + 30 phút, tác vụ định kỳ tự đánh dấu vắng mặt, giải phóng chỗ cho khách tại sảnh. |
| **EX-02** | Khách vãng lai (Walk-in) không đặt lịch | Tiếp đón | `pet_visits.appointment_id`<br>`pet_visits.status` | `NULL`<br>`[Tạo mới]` $\rightarrow$ `WAITING` | Lễ tân tiếp nhận linh hoạt, tạo tài khoản/hồ sơ tức thì, rồi phân công Bác sĩ để đưa ca vào hàng đợi phòng khám của Bác sĩ đó. |
| **EX-03** | Khách bỏ về khi đang chờ trong hàng đợi phòng khám | Tiếp đón | `pet_visits.status`<br>`pet_visit_status_histories.notes` | `WAITING` $\rightarrow$ `CANCELLED` | Lễ tân hủy ca, ca rời hàng đợi của phòng Bác sĩ (hoặc danh sách "Chờ phân công"), các ca phía sau tự tiến lên; lý do ghi vào `notes` của dòng lịch sử. |
| **EX-04** | Ca cấp cứu khẩn cấp chen ngang hàng đợi | Tiếp đón / Khám / CLS | `pet_visits.is_emergency`<br>`pet_visits.queue_position`<br>`visit_service_details.queue_position` | `FALSE` $\rightarrow$ `TRUE` | Ca được chèn lên đầu hàng đợi của phòng mà nó vào (sau các ca cấp cứu đang chờ), viền đỏ cảnh báo. |
| **EX-05** | Ca có kết quả CLS quay lại phòng Bác sĩ đang có nhiều ca chờ | Điều phối | `pet_visits.status`<br>`pet_visits.queue_position` | `WAITING_RESULTS` $\rightarrow$ `RESULTS_READY` (T06) | Hệ thống tự chèn ca vào hàng đợi phòng Bác sĩ ngay sau các ca cấp cứu và các ca có kết quả trước đó. **Không khóa phân công**: Lễ tân vẫn phân ca mới, ca mới đứng sau. |
| **EX-06** | Khách vắng mặt khi được gọi vào phòng (phòng khám, Xét nghiệm, CĐHA) | Khám / Cận lâm sàng | `pet_visits.queue_position` hoặc `visit_service_details.queue_position`<br>`*_histories.action = 'SKIPPED'` | Giữ nguyên trạng thái (`WAITING` / `RESULTS_READY` / `PENDING`) | Gọi tối đa 3 lần không vào $\rightarrow$ người phụ trách phòng bấm **"Không có mặt – Lùi 1 bậc"**: ca đổi chỗ với ca liền sau, hệ thống gọi ca kế tiếp, thông báo qua ứng dụng. |
| **EX-07** | Khách vắng mặt đến lần lùi thứ 3 / quay lại sau khi bị đưa xuống cuối hàng | Khám / Cận lâm sàng | `queue_position`<br>`*_histories.action = 'MOVED_TO_END'` | Giữ nguyên trạng thái | Lần lùi thứ 3 trong một lượt chờ $\rightarrow$ đưa ca xuống cuối hàng đợi phòng, báo Lễ tân liên hệ khách. Khách quay lại thì chờ đến lượt bình thường; không quay lại thì hủy (EX-03) hoặc đóng ca (EX-11). |
| **EX-08** | Khách xin hủy 1 trong các dịch vụ cận lâm sàng | Cận lâm sàng | `visit_service_details.status`<br>`service_invoices.payment_status`<br>`pet_visits.status` | `PENDING` $\rightarrow$ `CANCELLED`<br>`PENDING` $\rightarrow$ `CANCELLED`<br>`WAITING_RESULTS` $\rightarrow$ `RESULTS_READY` | Hủy dịch vụ **và hóa đơn của dịch vụ đó** trong cùng giao dịch; nếu các dịch vụ còn lại đã xong thì ca chuyển sang có kết quả. |
| **EX-09** | CĐHA gọi số đúng lúc thú cưng đang lấy máu | Điều phối liên phòng | `visit_service_detail_histories.action` (dòng Lab: `START_PROCESSING` / `SAMPLE_COLLECTED`) | Dịch vụ CĐHA giữ `PENDING`, giữ nguyên `queue_position` | Hiện huy hiệu `[Đang lấy máu bên phòng Lab]`; khi bấm "Gọi số kế tiếp", hệ thống **tự bỏ qua** ca này (không tính là vắng mặt) và gọi ca liền sau. |
| **EX-10** | Bác sĩ gọi ca có kết quả (GĐ 2) nhưng khách chưa vào phòng | Tái khám GĐ 2 | `pet_visits.queue_position`<br>`pet_visit_status_histories.action = 'SKIPPED'` | Giữ nguyên `RESULTS_READY` | Bác sĩ bấm **"Không có mặt – Lùi 1 bậc"** như EX-06. Gọi số không đổi trạng thái ca nên không còn chuyển `IN_PROGRESS` → `RESULTS_READY` (T13 đã bỏ), không ảnh hưởng việc phân công. |
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
  - Lễ tân phân công Bác sĩ ngay sau đó (UC-21) để đưa ca vào hàng đợi phòng khám của Bác sĩ được chọn; trước khi phân công, ca nằm trong danh sách "Chờ phân công".
- **Biến động CSDL:**
  - Bảng `pet_visits`: `appointment_id = NULL`, `status = 'WAITING'`, `checked_in_at = CURRENT_TIMESTAMP`, `receptionist_id` = Lễ tân tiếp đón.
  - Bảng `pet_visit_status_histories`: Ghi 01 dòng (`from_status = NULL`, `to_status = 'WAITING'`).

### EX-03: Khách hàng tự ý bỏ về khi đang chờ trong hàng đợi phòng khám
- **Bối cảnh thực tế:** Khách đã được tiếp nhận và đang chờ trong hàng đợi phòng của Bác sĩ (hoặc chưa kịp phân công), nhưng chờ lâu hoặc có việc bận đột xuất nên xin về trước khi vào phòng khám. Trường hợp ca bị lùi đến lần thứ 3 (EX-07) mà Lễ tân liên hệ, khách xác nhận không quay lại cũng xử lý như vậy.
- **Cơ chế xử lý nghiệp vụ:** Lễ tân bấm nút *"Hủy tiếp nhận"* trên ca trong hàng đợi phòng (hoặc trong danh sách "Chờ phân công"), chọn hoặc nhập lý do hủy (bắt buộc).
- **Biến động CSDL:**
  - Bảng `pet_visits`: Cột `status` chuyển từ `'WAITING'` sang `'CANCELLED'`.
  - Bảng `pet_visit_status_histories`: Ghi 01 dòng (`from_status = 'WAITING'`, `to_status = 'CANCELLED'`, `changed_by_user_id` = Lễ tân, `notes = 'Khách bận việc gia đình xin về'`).
  - Ca rời hàng đợi của phòng Bác sĩ vì hàng đợi chỉ gồm các ca `WAITING` / `RESULTS_READY`; các ca phía sau tự tiến lên một vị trí, không phải cập nhật `queue_position` của ca khác.
  - Trạng thái Bác sĩ không bị ảnh hưởng (phân công không làm Bác sĩ "bận", xem SM-02).
  - Chưa có chỉ định dịch vụ nên không phát sinh hóa đơn.

### EX-04: Ca bệnh cấp cứu khẩn cấp chen ngang hàng đợi (Emergency Preemption)
- **Bối cảnh thực tế:** Thú cưng bị sốc phản vệ, tai nạn giao thông, co giật hoặc khó thở tím tái cần được cấp cứu ngay lập tức.
- **Cơ chế xử lý nghiệp vụ:**
  - Lễ tân tích chọn ô **"Ca cấp cứu khẩn cấp"** lúc tiếp nhận (hoặc Bác sĩ bật cờ khẩn cấp cho ca đang chờ trong hàng đợi phòng mình).
  - Ca xuất hiện đầu danh sách "Chờ phân công" kèm cảnh báo đỏ; Lễ tân phân công ngay cho Bác sĩ đang rảnh hoặc có ít ca chờ nhất.
  - Khi vào bất kỳ hàng đợi nào (phòng khám, phòng Xét nghiệm, phòng CĐHA), ca được **chèn lên đầu hàng đợi của phòng đó, đứng sau các ca cấp cứu đang chờ** (cấp cứu trước – trước), kèm viền đỏ nhấp nháy cảnh báo. Ca cấp cứu không chen vào hàng đợi của phòng khác.
- **Biến động CSDL:**
  - Bảng `pet_visits`: Cột `is_emergency = TRUE`.
  - Hàng đợi phòng khám: `pet_visits.queue_position` = giá trị nằm giữa ca cấp cứu cuối cùng đang chờ và ca không cấp cứu đầu tiên của hàng đợi phòng đó (nếu chưa có ca cấp cứu nào thì nhỏ hơn ca đầu hàng).
  - Hàng đợi phòng CLS: các dòng `visit_service_details` của ca được đặt `queue_position` theo cùng quy tắc trong hàng đợi phòng Xét nghiệm / CĐHA.
  - Hiển thị hàng đợi chỉ cần `ORDER BY queue_position` trên chỉ mục `(doctor_id, status, queue_position)`; không còn dùng `ORDER BY is_emergency DESC, checked_in_at ASC` trên hàng đợi chung.

---

## 3. PHÂN HỆ 2: KHÁM LÂM SÀNG & ĐIỀU PHỐI BÁC SĨ

### EX-05: Ca có kết quả cận lâm sàng quay lại phòng Bác sĩ đang có nhiều ca chờ
- **Bối cảnh thực tế:** Bác sĩ A đang khám ca khác và hàng đợi phòng A còn 3 ca mới đang chờ. Một ca của Bác sĩ A đi xét nghiệm 20 phút trước vừa có đủ kết quả (`RESULTS_READY`). Khách của ca này đã chờ lâu, cần được đọc kết quả trước các ca mới.
- **Cơ chế xử lý nghiệp vụ (ưu tiên trong hàng đợi phòng, thay cho Khóa ưu tiên):**
  - Khi ca chuyển `RESULTS_READY` (T06), hệ thống **tự chèn ca vào hàng đợi phòng của Bác sĩ A** ngay sau các ca cấp cứu và các ca có kết quả trước đó, trước mọi ca mới chưa khám. Màn hình Bác sĩ hiện thông báo "Có kết quả: [Tên Pet]".
  - Khi xong ca đang khám, Bác sĩ A bấm "Gọi số kế tiếp" và ca có kết quả được gọi trước.
  - **Lễ tân không bị chặn:** vẫn phân ca mới vào phòng A bình thường; ca mới đứng cuối hàng nên không thể chiếm lượt của ca có kết quả. Nhờ vậy không còn trạng thái `AVAILABLE_PRIORITY_CALLBACK` và không còn nút phân công bị vô hiệu hóa.
- **Biến động CSDL:**
  - Bảng `pet_visits`: `status` chuyển `'WAITING_RESULTS'` → `'RESULTS_READY'`; `queue_position` được đặt lại theo vị trí ưu tiên nói trên (cùng giao dịch T06).
  - Bảng `pet_visit_status_histories`: Ghi 01 dòng (`changed_by_user_id = NULL` – hệ thống tự chuyển).

---

## 4. PHÂN HỆ 3: CẬN LÂM SÀNG, GỌI SỐ & VẮNG MẶT – LÙI 1 BẬC

### EX-06: Khách hàng vắng mặt khi được gọi vào phòng (phòng khám, Xét nghiệm, CĐHA) – Lùi 1 bậc
- **Bối cảnh thực tế:** Đến lượt khám / xét nghiệm / siêu âm, hệ thống hiển thị thông báo gọi số nhưng chủ nuôi đưa thú cưng ra ngoài đi dạo hoặc đi vệ sinh.
- **Cơ chế xử lý nghiệp vụ (áp dụng chung cho mọi hàng đợi):**
  - Người phụ trách phòng (Bác sĩ, KTV Xét nghiệm, KTV / Bác sĩ CĐHA) bấm *"Gọi số kế tiếp"*: hệ thống gọi ca đầu hàng trên màn hình sảnh và ứng dụng của chủ nuôi. Việc gọi số **không đổi trạng thái** ca / dịch vụ.
  - Thông báo được lặp lại tối đa 3 lần (mỗi lần cách 60 giây). Nếu thú cưng vẫn chưa vào, người phụ trách phòng bấm **"Không có mặt – Lùi 1 bậc"**:
    - Ca **đổi chỗ với ca liền sau** trong hàng đợi của phòng; ca vẫn nằm trong hàng đợi, không bị chuyển sang tab riêng.
    - Trạng thái giữ nguyên (`WAITING` hoặc `RESULTS_READY` với hàng đợi phòng khám; `PENDING` với hàng đợi phòng CLS); chưa hao phí vật tư, hóa đơn dịch vụ giữ nguyên.
    - Hệ thống tự gọi ca kế tiếp $\rightarrow$ **Phòng không bị treo.**
    - Gửi **thông báo trên ứng dụng / Cổng thông tin** cho chủ nuôi biết lượt đã lùi 1 bậc (hệ thống không dùng SMS).
  - Nếu không có ca nào phía sau, ca giữ nguyên vị trí và được gọi lại ở lần "Gọi số kế tiếp" sau.
- **Biến động CSDL (trong một giao dịch, khóa 2 dòng liên quan để hai người không lùi cùng lúc):**
  - Hàng đợi phòng khám: hoán đổi `pet_visits.queue_position` của ca vắng mặt với ca liền sau cùng `doctor_id`; ghi 01 dòng `pet_visit_status_histories` (`from_status = to_status` = trạng thái hiện tại, `action = 'SKIPPED'`, `changed_by_user_id` = Bác sĩ).
  - Hàng đợi phòng CLS: hoán đổi `visit_service_details.queue_position` với dòng liền sau trong hàng đợi cùng phòng; ghi 01 dòng `visit_service_detail_histories` (`from_status = to_status = 'PENDING'`, `action = 'SKIPPED'`, `changed_by_user_id` = KTV).
  - Số lần đã lùi trong lượt chờ hiện tại = số dòng `action = 'SKIPPED'` kể từ lần ca vào hàng đợi gần nhất (phân công, T06, chỉ định CLS hoặc bị đưa xuống cuối hàng); không lưu cột đếm riêng.

### EX-07: Khách vắng mặt đến lần lùi thứ 3 và khi khách quay lại
- **Bối cảnh thực tế:** Khách ra ngoài lâu; mỗi lần đến lượt lại vắng, ca cứ bị lùi 1 bậc nhưng vẫn quanh quẩn ở đầu hàng.
- **Cơ chế xử lý nghiệp vụ:**
  - Khi người phụ trách phòng bấm "Không có mặt – Lùi 1 bậc" lần thứ 3 trong cùng một lượt chờ, hệ thống **đưa ca xuống cuối hàng đợi của phòng** (thay vì lùi 1 bậc) và gửi cảnh báo cho Lễ tân: *"Ca [Tên Pet] đã vắng mặt 3 lần tại phòng [Số phòng], vui lòng liên hệ khách"*. Số 3 là tham số cấu hình được.
  - Lượt chờ mới bắt đầu tính từ vị trí cuối hàng (số lần lùi về 0).
  - **Khách quay lại:** khách báo Lễ tân hoặc bấm "Tôi đã có mặt" trên ứng dụng; ca hiển thị nhãn "Đã có mặt" và **chờ đến lượt bình thường** theo vị trí hiện tại (không ghim ưu tiên, không có thao tác "Gọi lại" riêng).
  - **Khách không quay lại:** Lễ tân hủy ca nếu chưa khám (EX-03) hoặc đóng ca ghi công nợ nếu đã có dịch vụ được thực hiện (EX-11).
- **Biến động CSDL:**
  - `queue_position` của ca = lớn hơn ca cuối cùng của hàng đợi phòng đó.
  - Ghi 01 dòng lịch sử với `action = 'MOVED_TO_END'` (`pet_visit_status_histories` hoặc `visit_service_detail_histories`), trạng thái giữ nguyên.

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
  - Khi Bác sĩ CĐHA bấm *"Gọi số kế tiếp"*, hệ thống **tự bỏ qua** ca đang có huy hiệu vàng và gọi ca liền sau. Ca bị bỏ qua **giữ nguyên vị trí**, không tính là vắng mặt, không ghi `SKIPPED`.
  - Khi KTV Lab bấm "Đã lấy mẫu", ca này lại đủ điều kiện và được gọi ở lần "Gọi số kế tiếp" sau theo đúng vị trí của nó.
  - Quy tắc đối xứng: phòng Xét nghiệm tự bỏ qua ca đang được chụp / siêu âm ở phòng CĐHA (dịch vụ CĐHA của cùng ca đang `IN_PROGRESS`).
- **Biến động CSDL:**
  - Bảng `visit_service_details` (dòng CĐHA): Giữ nguyên `'PENDING'` và `queue_position`.
  - Không ghi dòng lịch sử nào cho việc bỏ qua (điều kiện bỏ qua được tính từ dữ liệu dòng Lab tại thời điểm gọi số).
  - Giá trị `SAMPLE_COLLECTED` là giá trị của cột `action` (`VARCHAR(50)`), không thay đổi cấu trúc bảng.

---

## 5. PHÂN HỆ 4: HỘI CHẨN GIAI ĐOẠN 2, HÀNG ĐỢI TÁI KHÁM & KÊ ĐƠN

### EX-10: Bác sĩ khám chính gọi ca có kết quả nhưng khách chưa vào phòng ngay
- **Bối cảnh thực tế:** Ca khám đã có đủ kết quả (`RESULTS_READY`) và đang đứng đầu hàng đợi phòng Bác sĩ. Bác sĩ bấm *"Gọi số kế tiếp"* nhưng khách bận ra ngoài nghe điện thoại.
- **Cơ chế xử lý nghiệp vụ:**
  - Gọi số **không đổi trạng thái**: ca vẫn `RESULTS_READY` cho đến khi thú cưng vào phòng và Bác sĩ bấm *"Tiếp tục khám (GĐ 2)"* (T07).
  - Thông báo gọi tối đa 3 lần không vào, Bác sĩ bấm **"Không có mặt – Lùi 1 bậc"** (như EX-06): ca đổi chỗ với ca liền sau trong hàng đợi phòng, hệ thống gọi ca kế tiếp. Đến lần thứ 3 thì đưa xuống cuối hàng (EX-07).
  - Khi đến lượt lại, ca được gọi bình thường. Không còn tab *"Ca chờ tái khám / Đã hoãn"* và thao tác *"Gọi lại"* (Recall).
  - **Không còn tác động lên phân công:** Bác sĩ không bị "khóa" hay "giải phóng" vì ca vắng mặt; Lễ tân phân ca mới vào phòng bất cứ lúc nào (BR-11).
- **Biến động CSDL:**
  - Bảng `pet_visits`: `status` giữ `'RESULTS_READY'`; `queue_position` hoán đổi với ca liền sau.
  - Bảng `pet_visit_status_histories`: Ghi 01 dòng `action = 'SKIPPED'` (`from_status = to_status = 'RESULTS_READY'`, `changed_by_user_id` = Bác sĩ).
  - Chuyển trạng thái T13 (`IN_PROGRESS → RESULTS_READY`) và dấu hiệu "đã hoãn" `from_status = IN_PROGRESS` **không còn dùng**.

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
| Quy ước chung (cập nhật 11/11) | Hàng đợi sảnh chung; T01–T14 | Mỗi phòng một hàng đợi, thứ tự theo `queue_position`; lùi 1 bậc ghi `action = 'SKIPPED'`; T13 đã bỏ | Hàng đợi riêng theo phòng (BR-11, BR-34) |
| EX-02, EX-03 (cập nhật 11/11) | Xếp vào hàng đợi sảnh; hủy ca "rút khỏi hàng đợi chung", Bác sĩ đã gán tự được giải phóng | Phân công ngay vào hàng đợi phòng Bác sĩ; hủy ca thì ca rời hàng đợi phòng, các ca sau tự tiến lên; phân công không làm Bác sĩ "bận" nên không có gì để giải phóng | Không còn hàng đợi chung |
| EX-04 (cập nhật 11/11) | Nhảy lên vị trí số 1 "của tất cả hàng đợi"; `ORDER BY is_emergency DESC, checked_in_at` | Chèn đầu hàng đợi của phòng mà ca vào (sau các ca cấp cứu khác); sắp theo `queue_position` | Mỗi phòng một hàng đợi; thứ tự có thể đổi do lùi 1 bậc nên không suy ra được từ `checked_in_at` |
| EX-05 (cập nhật 11/11) | Khóa ưu tiên: chặn phân công khi Bác sĩ có ca vừa có kết quả (`AVAILABLE_PRIORITY_CALLBACK`) | Ca có kết quả tự chèn vào hàng đợi phòng Bác sĩ ngay sau ca cấp cứu; không chặn phân công | Ưu tiên bằng vị trí trong hàng đợi thay cho khóa |
| EX-06, EX-07 (cập nhật 11/11) | Chỉ cho phòng CLS: "Tạm hoãn" sang tab riêng (`POSTPONED`), quay lại thì ghim "Ưu tiên kế tiếp" (`RECALL`) | Áp dụng cho mọi phòng: "Lùi 1 bậc" (`SKIPPED`) đổi chỗ với ca liền sau; lần thứ 3 đưa xuống cuối hàng (`MOVED_TO_END`) và báo Lễ tân; khách quay lại chờ đến lượt | Thống nhất một cơ chế vắng mặt cho phòng khám và phòng CLS |
| EX-09 (cập nhật 11/11) | Bác sĩ CĐHA bấm "Tạm hoãn" rồi "Gọi lại" | Hệ thống tự bỏ qua ca đang ở phòng Lab khi gọi số, ca giữ nguyên vị trí | Thú cưng bận ở phòng khác không phải lỗi vắng mặt của khách |
| EX-10 (cập nhật 11/11) | Gọi → `IN_PROGRESS`, hoãn → `RESULTS_READY` (T13); Bác sĩ `BUSY` → `AVAILABLE`; dấu hiệu "đã hoãn" `from_status = IN_PROGRESS` | Gọi số không đổi trạng thái; vắng mặt thì lùi 1 bậc, ca giữ `RESULTS_READY`; bỏ T13 | Đơn giản hóa; không còn ràng buộc với phân công |
