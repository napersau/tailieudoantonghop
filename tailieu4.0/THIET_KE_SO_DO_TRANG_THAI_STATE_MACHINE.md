# THIẾT KẾ SƠ ĐỒ TRẠNG THÁI (STATE MACHINE DIAGRAMS)
## HỆ THỐNG QUẢN LÝ PHÒNG KHÁM THÚ Y

> **Tài liệu chuẩn UML / RUP phục vụ Báo cáo & Bảo vệ Đồ án tốt nghiệp**  
> **Phiên bản:** 3.0 (đồng bộ với lược đồ CSDL v3.0 – `schema_init.sql`)  
> **Cập nhật 11/11/2026 – Hàng đợi riêng theo phòng:** SM-02 rút còn 2 trạng thái hiển thị (bỏ `AVAILABLE_PRIORITY_CALLBACK` / Khóa ưu tiên, trạng thái Bác sĩ không còn chặn phân công); T02, T06, T07 sửa theo hàng đợi phòng; **bỏ T13**; thêm mục 2.4 "Thao tác trên hàng đợi" (phân công, gọi số, lùi 1 bậc); SM-03 bỏ trạng thái con `POSTPONED` / `NEXT_IN_LINE`.  
> **Mục tiêu:** Mô tả chi tiết không gian trạng thái, sự kiện kích hoạt (Trigger Events), điều kiện canh (Guard Conditions) và hành động chuyển đổi (State Transitions) của các thực thể nghiệp vụ cốt lõi và thực thể hỗ trợ trong hệ thống; kèm theo sơ đồ điều phối đồng bộ liên thực thể (Cross-Entity State Orchestration).

---

## MỤC LỤC TỔNG QUAN

1. [Sơ đồ Điều phối Đồng bộ Trạng thái Đa thực thể (Cross-Entity State Orchestration)](#1-sơ-đồ-điều-phối-đồng-bộ-trạng-thái-đa-thực-thể)
2. [State Machine 1: Đợt khám bệnh (Pet Visit)](#2-state-machine-1-đợt-khám-bệnh-pet-visit) – gồm mục 2.4 Thao tác trên hàng đợi
3. [State Machine 2: Trạng thái phục vụ tức thời của Bác sĩ (Doctor Serving Status)](#3-state-machine-2-trạng-thái-phục-vụ-tức-thời-của-bác-sĩ-doctor-serving-status)
4. [State Machine 3: Chi tiết Chỉ định Dịch vụ (Visit Service Detail)](#4-state-machine-3-chi-tiết-chỉ-định-dịch-vụ-visit-service-detail)
5. [State Machine 4: Lịch hẹn khám (Appointment)](#5-state-machine-4-lịch-hẹn-khám-appointment)
6. [State Machine 5: Hóa đơn Dịch vụ (Service Invoice)](#6-state-machine-5-hóa-đơn-dịch-vụ-service-invoice)
7. [State Machine 6: Hóa đơn Thuốc (Medicine Invoice)](#7-state-machine-6-hóa-đơn-thuốc-medicine-invoice)
8. [Tổng kết tính nhất quán toàn hệ thống](#tổng-kết-tính-nhất-quán-toàn-hệ-thống)
9. [Phụ lục: Thay đổi so với phiên bản 2.0](#phụ-lục-thay-đổi-so-với-phiên-bản-20)

### Quy ước chung áp dụng cho mọi State Machine
- **Mọi lần đổi trạng thái đều ghi 1 dòng lịch sử** trong cùng giao dịch: `appointment_status_histories`, `pet_visit_status_histories`, `visit_service_detail_histories`. Người thao tác ghi vào `changed_by_user_id` (`NULL` = hệ thống tự chuyển), lý do hủy / ghi chú ghi vào `notes` (hoặc `reason`).
- **Thời điểm bắt đầu khám, chốt ca, hoàn tất, hủy** không lưu thành cột riêng trên `pet_visits` mà lấy từ `created_at` của dòng lịch sử tương ứng.
- **Không có trạng thái đơn thuốc.** Bảng `prescriptions` chỉ là chỉ định chuyên môn; khách được quyền mua thuốc tại phòng khám hoặc mua ngoài. Việc mua thuốc thể hiện qua vòng đời của `medicine_invoices` (SM-06).
- **Nhóm dịch vụ** (theo `services.category`):
  - *Dịch vụ cận lâm sàng (CLS):* `LABORATORY` → hàng đợi Phòng Xét nghiệm; `IMAGING` → hàng đợi Phòng CĐHA.
  - *Dịch vụ thực hiện tại phòng khám:* `EXAMINATION`, `VACCINATION`, `DEWORMING`, `EXTERNAL_PARASITE`, `INJECTION_INFUSION`, `PROCEDURE`, `SURGERY` – do Bác sĩ khám chính thực hiện, không đi qua hàng đợi CLS.
- **Phí khám là một dịch vụ.** Khi Bác sĩ bấm "Bắt đầu khám", hệ thống tự tạo 1 dòng chỉ định dịch vụ khám (`EXAMINATION`, mặc định "Khám tổng quát") kèm hóa đơn dịch vụ. Nhờ vậy mọi ca khám đã vào phòng đều có ít nhất 1 hóa đơn dịch vụ.
- **Hàng đợi riêng theo phòng (cập nhật 11/11):** không có hàng đợi chung. Mỗi Bác sĩ (phòng khám cố định) có một hàng đợi gồm các ca `WAITING` đã gán `doctor_id` và các ca `RESULTS_READY` của Bác sĩ đó; phòng Xét nghiệm và phòng CĐHA mỗi phòng có một hàng đợi gồm các dịch vụ CLS `PENDING` thuộc nhóm tương ứng. Thứ tự trong hàng đợi lưu ở cột `queue_position`; các thao tác phân công, gọi số, lùi 1 bậc **không làm đổi trạng thái** và được mô tả ở mục 2.4.

---

## 1. SƠ ĐỒ ĐIỀU PHỐI ĐỒNG BỘ TRẠNG THÁI ĐA THỰC THỂ

Trong thực tế vận hành phòng khám thú y, các thực thể dữ liệu không biến đổi độc lập mà có sự ràng buộc, đồng bộ và kích hoạt lẫn nhau theo mô hình **Sự kiện - Ràng buộc (Event-Driven State Machine)**. Điểm cốt lõi của phiên bản 3.0:
- **Hóa đơn dịch vụ sinh ra cùng lúc với chỉ định dịch vụ** (không đợi chốt ca), hủy dịch vụ thì hủy luôn hóa đơn của dịch vụ đó.
- **Ca khám hoàn tất khi mọi hóa đơn dịch vụ đã `PAID` hoặc `CANCELLED`**. Việc mua thuốc là tùy chọn, nằm ngoài điều kiện hoàn tất ca.
- **Trạng thái Bác sĩ chỉ để hiển thị (cập nhật 11/11).** Lễ tân phân công ca vào hàng đợi phòng Bác sĩ bất kể Bác sĩ đang khám hay rảnh; Bác sĩ chỉ chuyển `BUSY` khi thật sự bắt đầu khám một ca.

```mermaid
stateDiagram-v2
    direction TB

    state "LỊCH HẸN (appointments)" as Appt {
        state "CONFIRMED" as A_CONF
        state "CHECKED_IN" as A_IN
        A_CONF --> A_IN : Khách đến quầy
    }

    state "ĐỢT KHÁM (pet_visits)" as Visit {
        state "WAITING" as V_W
        state "IN_PROGRESS (GĐ 1)" as V_IP1
        state "WAITING_RESULTS" as V_WR
        state "RESULTS_READY" as V_RR
        state "IN_PROGRESS (GĐ 2)" as V_IP2
        state "WAITING_PAYMENT" as V_WP
        state "COMPLETED" as V_C
        V_W --> V_IP1 : Bác sĩ bắt đầu khám
        V_IP1 --> V_WR : Gửi chỉ định CLS
        V_IP1 --> V_WP : Chốt ca không cần CLS
        V_WR --> V_RR : Đủ kết quả
        V_RR --> V_IP2 : Gọi số, tiếp tục khám GĐ 2
        V_IP2 --> V_WP : Chốt chuyên môn
        V_WP --> V_C : Đủ hóa đơn dịch vụ
    }

    state "BÁC SĨ (computed, chỉ hiển thị)" as Doc {
        state "AVAILABLE - Rảnh" as D_AV
        state "BUSY - Đang khám" as D_BUSY
        D_AV --> D_BUSY : Bắt đầu khám ca đầu hàng
        D_BUSY --> D_AV : Gửi CLS / Chốt ca / Hủy ca
    }

    state "CHỈ ĐỊNH DỊCH VỤ (visit_service_details)" as Svc {
        state "PENDING" as S_P
        state "IN_PROGRESS" as S_IP
        state "COMPLETED" as S_C
        state "CANCELLED" as S_X
        S_P --> S_IP : Bắt đầu thực hiện
        S_IP --> S_C : Lưu kết quả
        S_P --> S_X : Khách hủy (EX-08)
    }

    state "HÓA ĐƠN DỊCH VỤ (service_invoices)" as SInv {
        state "PENDING" as SI_P
        state "PAID" as SI_PAID
        state "CANCELLED" as SI_X
        SI_P --> SI_PAID : Thu ngân xác nhận
        SI_P --> SI_X : Dịch vụ bị hủy
    }

    state "HÓA ĐƠN THUỐC – TÙY CHỌN (medicine_invoices)" as MInv {
        state "PENDING" as MI_P
        state "PAID" as MI_PAID
        state "CANCELLED" as MI_X
        MI_P --> MI_PAID : Thu tiền + trừ kho
        MI_P --> MI_X : Khách mua ngoài
    }

    %% Sự kiện đồng bộ liên thực thể
    A_IN --> V_W : Tạo đợt khám mới
    V_W --> D_BUSY : Bác sĩ gọi số và bắt đầu khám (T02)
    V_IP1 --> S_P : Chỉ định dịch vụ
    S_P --> SI_P : Tạo hóa đơn cùng giao dịch
    S_X --> SI_X : Hủy hóa đơn cùng giao dịch
    V_WR --> D_AV : Giải phóng Bác sĩ
    S_C --> V_RR : Mọi dịch vụ CLS đã xong hoặc hủy
    V_RR --> D_BUSY : Gọi số và tiếp tục khám GĐ 2 (T07)
    SI_PAID --> V_C : Mọi hóa đơn PAID hoặc CANCELLED
    V_WP --> MI_P : Khách chọn mua thuốc tại phòng khám
```

> **Đọc sơ đồ:** các mũi tên trong từng khối là vòng đời của thực thể; các mũi tên nối giữa hai khối là quan hệ kích hoạt (sự kiện ở thực thể nguồn gây ra chuyển trạng thái ở thực thể đích). Hóa đơn thuốc được nối từ `WAITING_PAYMENT` nhưng cũng có thể lập khi ca đã `COMPLETED`; không có mũi tên nào từ hóa đơn thuốc quay về đợt khám. Việc Lễ tân phân công ca vào hàng đợi phòng **không** có mũi tên tới khối Bác sĩ, vì phân công không làm đổi trạng thái Bác sĩ.

---

## 2. STATE MACHINE 1: ĐỢT KHÁM BỆNH (PET VISIT)

### 2.1. Ý nghĩa & Vai trò nghiệp vụ
Bảng `pet_visits` là **thực thể trung tâm (Core Aggregate Root)** của toàn bộ phần mềm. Vòng đời của một đợt khám được thiết kế theo mô hình **Chu kỳ Y tế Bất đồng bộ (Asynchronous Clinical Cycle)** để tối ưu hóa công suất phòng khám và loại bỏ điểm nghẽn thời gian thực.

Hai giai đoạn của `IN_PROGRESS` không phải là 2 giá trị enum khác nhau. Hệ thống phân biệt bằng lịch sử: ca đã từng đi qua `WAITING_RESULTS` thì đang ở **Giai đoạn 2**, ngược lại là **Giai đoạn 1**.

### 2.2. Sơ đồ Trạng thái (Mermaid State Machine)

```mermaid
stateDiagram-v2
    [*] --> WAITING : T01 Lễ tân check-in (Walk-in hoặc từ Lịch hẹn)

    WAITING --> WAITING : Phân công / Lùi 1 bậc (không đổi trạng thái, mục 2.4)
    WAITING --> GIAI_DOAN_1 : T02 Bác sĩ gọi số ca đầu hàng đợi phòng mình, bấm "Bắt đầu khám"
    WAITING --> CANCELLED : T03 Khách bỏ về khi đang chờ trong hàng đợi phòng (EX-03)

    state IN_PROGRESS {
        GIAI_DOAN_1 : GIAI ĐOẠN 1 - Khám lâm sàng sơ bộ
        GIAI_DOAN_2 : GIAI ĐOẠN 2 - Hội chẩn kết quả CLS
    }

    GIAI_DOAN_1 --> WAITING_RESULTS : T04 Gửi chỉ định cận lâm sàng
    GIAI_DOAN_1 --> WAITING_PAYMENT : T05 Chốt ca không cần cận lâm sàng
    GIAI_DOAN_1 --> CANCELLED : T11 Khách từ chối khám / Chuyển viện (miễn phí)

    WAITING_RESULTS --> RESULTS_READY : T06 Mọi dịch vụ CLS đã xong hoặc hủy
    WAITING_RESULTS --> COMPLETED : T12 Khách bỏ về giữa chừng (EX-11, ghi công nợ)

    RESULTS_READY --> RESULTS_READY : Lùi 1 bậc khi vắng mặt (không đổi trạng thái)
    RESULTS_READY --> GIAI_DOAN_2 : T07 Bác sĩ gọi số, thú cưng vào phòng, bấm "Tiếp tục khám GĐ 2"
    RESULTS_READY --> COMPLETED : T08 Khách bỏ về hẳn (EX-11, ghi công nợ)

    GIAI_DOAN_2 --> WAITING_PAYMENT : T09 Bác sĩ chốt chuyên môn

    WAITING_PAYMENT --> COMPLETED : T10 Mọi hóa đơn dịch vụ đã PAID hoặc CANCELLED
    WAITING_PAYMENT --> IN_PROGRESS : T14 Mở lại hồ sơ để hiệu chỉnh

    COMPLETED --> [*]
    CANCELLED --> [*]
```

### 2.3. Bảng Ma trận Chuyển đổi Trạng thái (State Transition Table)

Mọi dòng dưới đây đều kèm hành động chung: **ghi 1 dòng `pet_visit_status_histories` (`from_status`, `to_status`, `changed_by_user_id`, `notes`) trong cùng giao dịch**. Cột "Hành động" chỉ liệt kê phần phát sinh thêm.

| STT | Trạng thái nguồn | Sự kiện kích hoạt (Trigger) | Điều kiện canh (Guard Condition) | Hành động CSDL & Tác động hệ thống | Trạng thái đích |
| :---: | :--- | :--- | :--- | :--- | :--- |
| **T01** | `[*] (None)` | Lễ tân tiếp đón khách tại quầy (UC-19) | Hồ sơ thú cưng hợp lệ; thú cưng không có đợt khám nào khác đang mở (khác `COMPLETED`, `CANCELLED`); nếu đến từ lịch hẹn thì lịch phải `CONFIRMED` và đúng ngày. **Không yêu cầu cân nặng, thân nhiệt** (Bác sĩ đo trong phòng khám). | Tạo `pet_visits` (`checked_in_at = NOW()`, `receptionist_id`, `appointment_id` nếu có, `is_emergency`). Nếu từ lịch hẹn: phát sự kiện để `appointment-service` chuyển lịch sang `CHECKED_IN`. Ca vào danh sách "Chờ phân công" (`doctor_id = NULL`); Lễ tân phân công ngay sau đó để đưa ca vào hàng đợi phòng Bác sĩ (mục 2.4). | `WAITING` |
| **T02** | `WAITING` | Bác sĩ "Gọi số kế tiếp", thú cưng vào phòng, Bác sĩ bấm *"Bắt đầu khám"* (UC-22) | Ca nằm trong hàng đợi phòng của Bác sĩ đang thao tác (`pet_visits.doctor_id` = Bác sĩ); Bác sĩ không có ca nào khác đang `IN_PROGRESS` (BR-12). **Không** yêu cầu ca là ca duy nhất được gán cho Bác sĩ. | Tự tạo 1 `visit_service_details` cho dịch vụ khám (`EXAMINATION`, `status = IN_PROGRESS`) và 1 `service_invoices` (`PENDING`, snapshot `unit_price`, `vat_rate`). Ca rời hàng đợi phòng (hàng đợi chỉ gồm `WAITING` / `RESULTS_READY`). Bác sĩ chuyển `BUSY`. Mở Bệnh án điện tử. | `IN_PROGRESS` (GĐ 1) |
| **T03** | `WAITING` | Lễ tân hủy ca khám (EX-03) | Khách xin về hoặc chờ quá lâu bỏ về; bắt buộc nhập lý do. | Lý do ghi vào `notes` của dòng lịch sử. Ca rời hàng đợi phòng Bác sĩ (hoặc danh sách "Chờ phân công"), các ca phía sau tự tiến lên. Trạng thái Bác sĩ không bị ảnh hưởng. | `CANCELLED` |
| **T04** | `IN_PROGRESS` (GĐ 1) | Bác sĩ xác nhận chỉ định cận lâm sàng (UC-23) | Có ít nhất 1 dịch vụ `LABORATORY` hoặc `IMAGING` được chỉ định; đã nhập `weight_at_visit`, `temperature` (> 0); các dịch vụ thực hiện tại phòng đã chỉ định trong GĐ 1 đều `COMPLETED` hoặc `CANCELLED`. | Với mỗi dịch vụ CLS: tạo `visit_service_details` (`PENDING`) + `service_invoices` (`PENDING`, snapshot giá & thuế). Dịch vụ khám chuyển `COMPLETED`. **Tự động** đưa từng dịch vụ CLS vào hàng đợi phòng Xét nghiệm / CĐHA tương ứng (đặt `visit_service_details.queue_position`: ca cấp cứu sau các ca cấp cứu đang chờ, ca thường cuối hàng). Bác sĩ về `AVAILABLE` và gọi ca kế tiếp trong hàng đợi phòng mình. | `WAITING_RESULTS` |
| **T05** | `IN_PROGRESS` (GĐ 1) | Bác sĩ chốt ca khám thông thường / tiêm phòng (UC-30_33) | Không có dịch vụ CLS; đã nhập `diagnosis` (EX-12), `weight_at_visit`, `temperature`; mọi dịch vụ thực hiện tại phòng đều `COMPLETED` hoặc `CANCELLED`. | Dịch vụ khám chuyển `COMPLETED`. Lưu đơn thuốc nếu có (`prescriptions` + `prescription_items`, không có giá, không có trạng thái). Khóa hồ sơ chuyên môn. Bác sĩ được giải phóng. | `WAITING_PAYMENT` |
| **T06** | `WAITING_RESULTS` | Phòng Lab / CĐHA lưu kết quả hoặc khách hủy dịch vụ CLS (UC-25_26, EX-08) | Không còn dịch vụ CLS nào của ca ở `PENDING` hoặc `IN_PROGRESS`. | Hệ thống tự chuyển (`changed_by_user_id = NULL`). Đặt lại `pet_visits.queue_position` để **chèn ca vào hàng đợi phòng Bác sĩ phụ trách** ngay sau các ca cấp cứu và các ca `RESULTS_READY` đang chờ, trước các ca `WAITING` thường (BR-34). Thông báo lên màn hình Bác sĩ. Không thay đổi trạng thái Bác sĩ, không khóa phân công. | `RESULTS_READY` |
| **T07** | `RESULTS_READY` | Bác sĩ "Gọi số kế tiếp" (ca có kết quả ở đầu hàng), thú cưng vào phòng, Bác sĩ bấm *"Tiếp tục khám (GĐ 2)"* (UC-30) | `pet_visits.doctor_id` = Bác sĩ đang thao tác; Bác sĩ không có ca nào khác đang `IN_PROGRESS` (BR-12). | Việc gọi số chỉ phát thông báo trên màn hình sảnh và ứng dụng chủ nuôi, không đổi trạng thái. Khi bấm "Tiếp tục khám": ca rời hàng đợi phòng, Bác sĩ chuyển `BUSY`, mở giao diện Giai đoạn 2. Khách vắng mặt khi được gọi thì lùi 1 bậc (mục 2.4), ca giữ `RESULTS_READY`. | `IN_PROGRESS` (GĐ 2) |
| **T08** | `RESULTS_READY` | Thao tác *"Đóng ca / Khách bỏ về"* (EX-11) | Lễ tân đã liên hệ xác nhận khách bỏ về, hoặc đã hết ngày làm việc. | **Không tạo hóa đơn mới.** Các hóa đơn của dịch vụ đã thực hiện (khám, CLS đã `COMPLETED`) giữ `PENDING` làm công nợ, thu ở lần sau. Khóa bệnh án, lưu kết quả vĩnh viễn. | `COMPLETED` (Khóa) |
| **T09** | `IN_PROGRESS` (GĐ 2) | Bác sĩ chốt đợt khám & kê đơn (UC-30_33) | Đã nhập `diagnosis` (EX-12); mọi dịch vụ thực hiện tại phòng đã chỉ định trong GĐ 2 đều `COMPLETED` hoặc `CANCELLED`. | Lưu đơn thuốc nếu có. Khóa bệnh án. Bác sĩ được giải phóng. Ca hiển thị trên màn hình Thu ngân. | `WAITING_PAYMENT` |
| **T10** | `WAITING_PAYMENT` | Thu ngân xác nhận thanh toán hóa đơn dịch vụ (UC-35) | Sau lần xác nhận này, **mọi `service_invoices` của ca đều `PAID` hoặc `CANCELLED`**. Không xét hóa đơn thuốc. | Thực hiện trong cùng giao dịch cục bộ của `clinical-service` với việc chuyển hóa đơn sang `PAID` (hệ thống ghi lịch sử, `changed_by_user_id` = thu ngân). Giải phóng ca khỏi màn hình Thu ngân. | `COMPLETED` |
| **T11** | `IN_PROGRESS` (GĐ 1) | Khách từ chối khám tiếp / Chuyển viện cấp cứu | Bắt buộc nhập lý do. Áp dụng khi phòng khám **không thu phí** và **chưa có dịch vụ tại phòng nào `COMPLETED`**; nếu có thu phí khám hoặc đã thực hiện dịch vụ tại phòng, Bác sĩ chốt ca bình thường theo T05 với chẩn đoán "chuyển viện". | Mọi dịch vụ của ca (dịch vụ khám `IN_PROGRESS`, dịch vụ tại phòng `PENDING`) → `CANCELLED`, kéo theo hóa đơn dịch vụ → `CANCELLED`, nên ca hủy không còn hóa đơn `PENDING`. Bác sĩ được giải phóng. | `CANCELLED` |
| **T12** | `WAITING_RESULTS` | Thao tác *"Đóng ca / Khách bỏ về"* khi CLS chưa làm xong (EX-11) | Không có dịch vụ CLS nào đang `IN_PROGRESS` (KTV phải hoàn tất hoặc hủy dịch vụ đang làm trước). | Dịch vụ CLS còn `PENDING` → `CANCELLED` (hóa đơn tương ứng → `CANCELLED`). Hóa đơn của dịch vụ đã làm (khám, CLS đã `COMPLETED`) giữ `PENDING` làm công nợ. Khóa bệnh án. | `COMPLETED` (Khóa) |
| **T13** | *(Đã bỏ từ 11/11/2026)* | – | – | Trước đây: Bác sĩ "Mời vào phòng" làm ca chuyển `IN_PROGRESS`, khách vắng thì "Tạm hoãn" về `RESULTS_READY`. Nay gọi số không đổi trạng thái, ca chỉ chuyển `IN_PROGRESS` khi thú cưng đã vào phòng (T07); khách vắng mặt xử lý bằng **lùi 1 bậc** (mục 2.4, EX-10). Giữ số hiệu T13 để không đánh số lại T14. | – |
| **T14** | `WAITING_PAYMENT` | Bác sĩ phụ trách (hoặc `ADMIN`) bấm *"Mở lại hồ sơ"* | Ca chưa `COMPLETED`; Bác sĩ không đang `BUSY` với ca khác; bắt buộc nhập lý do. Nếu đơn thuốc đã có hóa đơn thuốc chưa hủy (`PENDING` hoặc `PAID`) thì không được sửa đơn thuốc. | Lý do ghi vào `notes`. Hóa đơn dịch vụ đã `PAID` giữ nguyên; dịch vụ bị bỏ thì hủy theo SM-03 (hóa đơn đi theo); dịch vụ thêm mới sinh hóa đơn mới. Sau khi sửa, Bác sĩ chốt lại theo T05 / T09. | `IN_PROGRESS` (giữ nguyên giai đoạn trước đó) |

### 2.4. Thao tác trên hàng đợi phòng khám (không đổi trạng thái) – cập nhật 11/11/2026

Phân công, chuyển phòng, gọi số và lùi 1 bậc chỉ thay đổi **vị trí** của ca trong hàng đợi phòng, không làm đổi `pet_visits.status`. Mỗi Bác sĩ có một hàng đợi riêng gồm các ca `WAITING` có `doctor_id` = Bác sĩ đó và các ca `RESULTS_READY` của Bác sĩ đó, sắp theo `queue_position` tăng dần. Hàng đợi phòng Xét nghiệm và phòng CĐHA dùng cùng cơ chế trên `visit_service_details` (mục 4).

**Dữ liệu cần bổ sung** (chưa có trong `schema_init.sql` v3.0, cần cập nhật lược đồ và ERD):

| Cột / chỉ mục | Kiểu | Ý nghĩa |
| :--- | :--- | :--- |
| `pet_visits.queue_position` | `DECIMAL(20,6) NULL` | Vị trí trong hàng đợi phòng Bác sĩ; có giá trị từ lúc phân công. Dùng số thập phân để chèn ca vào giữa hai ca kề nhau (lấy trung bình cộng) mà không phải đánh số lại cả hàng. |
| `visit_service_details.queue_position` | `DECIMAL(20,6) NULL` | Vị trí trong hàng đợi phòng Xét nghiệm / CĐHA; `NULL` với dịch vụ khám và dịch vụ thực hiện tại phòng. |
| `pet_visit_status_histories.action` | `VARCHAR(50) NULL` | Loại thao tác khi không đổi trạng thái: `ASSIGNED`, `REASSIGNED`, `SKIPPED`, `MOVED_TO_END`; `NULL` với các dòng chuyển trạng thái thông thường. Bảng `visit_service_detail_histories` đã có cột `action`. |
| `idx_visits_doctor_queue (doctor_id, status, queue_position)` | Chỉ mục | Thay cho `idx_visits_queue (status, is_emergency, checked_in_at)` của hàng đợi chung cũ. |
| `idx_vsd_queue (status, queue_position)` | Chỉ mục | Đọc hàng đợi phòng CLS theo thứ tự. |

**Vị trí chèn vào hàng đợi (BR-34):**
1. Ca thường mới phân công: cuối hàng (`queue_position` = lớn nhất của hàng + 1).
2. Ca cấp cứu: ngay trước ca đầu tiên **không** phải cấp cứu trong hàng.
3. Ca vừa có kết quả (T06): ngay trước ca `WAITING` thường đầu tiên trong hàng (tức là sau mọi ca cấp cứu và mọi ca `RESULTS_READY` đang chờ).

**Bảng thao tác:**

| Thao tác | Người thực hiện | Điều kiện | Tác động CSDL (một giao dịch) | Trạng thái ca |
| :--- | :--- | :--- | :--- | :--- |
| **Phân công Bác sĩ** (UC-21) | Lễ tân | Ca `WAITING`, `doctor_id IS NULL`; Bác sĩ `ACTIVE`, phòng không tạm ngưng. **Không xét trạng thái SM-02 của Bác sĩ.** | Gán `doctor_id`; đặt `queue_position` theo quy tắc chèn 1 hoặc 2; ghi `pet_visit_status_histories` (`from_status = to_status = 'WAITING'`, `action = 'ASSIGNED'`, `changed_by_user_id` = Lễ tân). | Giữ `WAITING` |
| **Đổi Bác sĩ / chuyển phòng** (UC-21 Luồng 5a) | Lễ tân | Ca `WAITING`, chưa bắt đầu khám (khóa lạc quan `version` chặn xung đột với T02). | Đổi `doctor_id`; đặt `queue_position` trong hàng đợi mới theo `checked_in_at` so với các ca `WAITING` thường ở đó (khách không mất lượt); ghi `action = 'REASSIGNED'`, `notes` = Bác sĩ cũ → Bác sĩ mới. | Giữ `WAITING` |
| **Gọi số kế tiếp** | Bác sĩ | Bác sĩ không có ca `IN_PROGRESS` (BR-12). | Chọn ca có `queue_position` nhỏ nhất trong hàng đợi phòng mình; phát `PatientCalledEvent` (màn hình sảnh, ứng dụng chủ nuôi). Không ghi CSDL. | Giữ nguyên |
| **Không có mặt – Lùi 1 bậc** (EX-06, EX-10) | Bác sĩ | Ca vừa được gọi, chưa vào phòng; số lần lùi trong lượt chờ hiện tại < 2. | Khóa ca và ca liền sau (`SELECT ... FOR UPDATE`), **hoán đổi `queue_position`** của hai ca; ghi `action = 'SKIPPED'` (`from_status = to_status`); tự gọi ca kế tiếp. Không có ca phía sau thì giữ nguyên vị trí, vẫn ghi `SKIPPED`. | Giữ `WAITING` / `RESULTS_READY` |
| **Đưa xuống cuối hàng** (EX-07) | Hệ thống | Người phụ trách bấm "Lùi 1 bậc" khi ca đã có 2 lần `SKIPPED` trong lượt chờ (đây là lần thứ 3). | `queue_position` = lớn nhất của hàng + 1; ghi `action = 'MOVED_TO_END'`; thông báo Lễ tân liên hệ khách. Lượt chờ mới bắt đầu. | Giữ nguyên |
| **Bật cờ cấp cứu cho ca đang chờ** (EX-04) | Lễ tân / Bác sĩ | Ca `WAITING`. | `is_emergency = TRUE`; đặt lại `queue_position` theo quy tắc chèn 2. | Giữ `WAITING` |

**Lượt chờ** của một ca bắt đầu từ dòng lịch sử gần nhất thuộc một trong các loại: `ASSIGNED`, `REASSIGNED`, `MOVED_TO_END`, hoặc chuyển trạng thái vào `RESULTS_READY` (T06). Số lần đã lùi = số dòng `action = 'SKIPPED'` sau mốc đó; đây là giá trị tính được nên không lưu cột riêng.

```sql
-- Hàng đợi phòng của Bác sĩ :doctor_id (màn hình Bác sĩ, bảng điều phối, màn hình sảnh)
SELECT v.id, v.visit_code, v.status, v.is_emergency, v.queue_position
FROM pet_visits v
WHERE v.doctor_id = :doctor_id
  AND v.status IN ('WAITING', 'RESULTS_READY')
ORDER BY v.queue_position;

-- Lùi 1 bậc ca :visit_id (trong một giao dịch)
SELECT id, queue_position FROM pet_visits WHERE id = :visit_id FOR UPDATE;
SELECT id, queue_position FROM pet_visits
WHERE doctor_id = :doctor_id
  AND status IN ('WAITING', 'RESULTS_READY')
  AND queue_position > :current_position
ORDER BY queue_position
LIMIT 1
FOR UPDATE;
-- Hoán đổi queue_position của hai dòng, ghi pet_visit_status_histories (action = 'SKIPPED')
```

---

## 3. STATE MACHINE 2: TRẠNG THÁI PHỤC VỤ TỨC THỜI CỦA BÁC SĨ (DOCTOR SERVING STATUS)

### 3.1. Ý nghĩa & Vai trò nghiệp vụ
Hệ thống **không sử dụng cột trạng thái tĩnh trong CSDL** để quản lý bác sĩ, nhằm tránh rủi ro sai lệch dữ liệu (Desynchronization) khi có sự cố mạng. Trạng thái phục vụ của Bác sĩ được **tính toán động theo thời gian thực (Computed State)** từ các ca khám mà Bác sĩ đó đang phụ trách (`pet_visits.doctor_id`).

Từ bản cập nhật 11/11/2026, trạng thái này **chỉ dùng để hiển thị** (bảng điều phối của Lễ tân, màn hình sảnh) và làm điều kiện cho T02, T07, T14 (một Bác sĩ chỉ khám một ca tại một thời điểm, BR-12). Trạng thái Bác sĩ **không chặn việc phân công**: Lễ tân đưa ca vào hàng đợi phòng của Bác sĩ bất kể Bác sĩ đang khám hay rảnh (BR-11).

Hai trạng thái:
- `BUSY` (Đang khám): Bác sĩ đang có một ca `IN_PROGRESS`.
- `AVAILABLE` (Rảnh): Bác sĩ không có ca `IN_PROGRESS`; hàng đợi phòng vẫn có thể có ca chờ. Bảng điều phối hiển thị kèm **số ca đang chờ** của từng phòng.

### 3.2. Sơ đồ Trạng thái (Mermaid State Machine)

```mermaid
stateDiagram-v2
    [*] --> AVAILABLE : Bắt đầu ca trực

    AVAILABLE --> BUSY : Bắt đầu khám ca đầu hàng (T02)
    AVAILABLE --> BUSY : Tiếp tục khám GĐ 2 ca có kết quả (T07)
    AVAILABLE --> BUSY : Mở lại hồ sơ (T14)

    BUSY --> AVAILABLE : Gửi chỉ định CLS (T04)
    BUSY --> AVAILABLE : Chốt ca (T05 / T09)
    BUSY --> AVAILABLE : Hủy ca / Chuyển viện (T11)
```

> **Không làm đổi trạng thái Bác sĩ:** Lễ tân phân công hoặc chuyển ca vào phòng, ca có kết quả quay lại hàng đợi (T06), gọi số, lùi 1 bậc, ca chờ bị hủy (T03). Đây là các thay đổi trên hàng đợi phòng (mục 2.4).

### 3.3. Quy tắc Suy diễn Trạng thái (Inference Logic)

```sql
-- Trạng thái và số ca chờ của Bác sĩ :doctor_id tại thời điểm t
SELECT
    CASE WHEN SUM(v.status = 'IN_PROGRESS') > 0 THEN 'BUSY' ELSE 'AVAILABLE' END
        AS computed_doctor_status,
    SUM(v.status IN ('WAITING', 'RESULTS_READY')) AS waiting_count
FROM pet_visits v
WHERE v.doctor_id = :doctor_id
  AND v.status IN ('WAITING', 'IN_PROGRESS', 'RESULTS_READY');
```

**Vì sao bỏ Khóa ưu tiên (`AVAILABLE_PRIORITY_CALLBACK`):** khóa chỉ cần khi cả phòng khám dùng một hàng đợi chung và mỗi Bác sĩ chỉ nhận một ca một lúc; khi đó phải chặn Lễ tân để ca có kết quả không bị ca mới chiếm lượt. Với hàng đợi riêng theo phòng, ca có kết quả được chèn lên trước các ca mới ngay trong hàng đợi của Bác sĩ (T06), nên ưu tiên được bảo đảm bằng vị trí mà không cần khóa.

Index hỗ trợ: `idx_visits_doctor_status (doctor_id, status)`.

**Kiểm chứng công thức** (chạy thử trên dữ liệu mẫu):

| Tình huống của Bác sĩ | Trạng thái | Số ca chờ | Lễ tân phân thêm ca được? |
| :--- | :--- | :---: | :---: |
| Chưa có ca nào | `AVAILABLE` | 0 | Có |
| Đã được phân công 3 ca, chưa gọi ca nào | `AVAILABLE` | 3 | Có |
| Đang khám 1 ca, còn 2 ca chờ | `BUSY` | 2 | Có |
| Đang khám ca khác, 1 ca của mình vừa có kết quả | `BUSY` | +1 (ca có kết quả đứng đầu hàng) | Có |
| Vừa gửi chỉ định CLS | `AVAILABLE` | Không đổi | Có |
| Gọi ca có kết quả nhưng khách vắng, đã lùi 1 bậc | `AVAILABLE` (gọi ngay ca kế) | Không đổi | Có |

### 3.4. Bảng Chi tiết Chuyển đổi Trạng thái Bác sĩ

| Trạng thái nguồn | Sự kiện kích hoạt | Cơ chế nghiệp vụ & Ràng buộc bảo vệ | Trạng thái đích |
| :--- | :--- | :--- | :--- |
| `AVAILABLE` | Bác sĩ bấm "Bắt đầu khám" ca đầu hàng (T02), "Tiếp tục khám GĐ 2" ca có kết quả (T07) hoặc "Mở lại hồ sơ" (T14) | Chỉ được khi Bác sĩ không có ca `IN_PROGRESS` khác (BR-12); kiểm tra trong cùng giao dịch với việc chuyển trạng thái đợt khám. | `BUSY` |
| `BUSY` | Bác sĩ gửi chỉ định CLS (T04), chốt ca (T05 / T09) hoặc hủy ca / chuyển viện (T11) | Ca đang khám rời `IN_PROGRESS`; Bác sĩ gọi ca kế tiếp trong hàng đợi phòng mình. Không phải chờ máy chạy kết quả. | `AVAILABLE` |

---

## 4. STATE MACHINE 3: CHI TIẾT CHỈ ĐỊNH DỊCH VỤ (VISIT SERVICE DETAIL)

### 4.1. Ý nghĩa & Vai trò nghiệp vụ
Bảng `visit_service_details` quản lý tiến độ thực hiện của từng dịch vụ được chỉ định cho một đợt khám. Mỗi dòng chỉ định luôn đi kèm **đúng 1 hóa đơn dịch vụ** (`service_invoices`, quan hệ 1–1), tạo trong cùng giao dịch. Bất biến: **dịch vụ `CANCELLED` ⇔ hóa đơn `CANCELLED`**.

Có 3 cách một dịch vụ đi qua vòng đời:

| Nhóm | Danh mục (`services.category`) | Người thực hiện | Đặc điểm |
| :--- | :--- | :--- | :--- |
| **Dịch vụ khám** | `EXAMINATION` | Bác sĩ khám chính | Hệ thống tự tạo ở T02 với `status = IN_PROGRESS`; chuyển `COMPLETED` khi kết thúc GĐ 1 (T04 / T05); bị hủy ở T11. |
| **Dịch vụ tại phòng khám** | `VACCINATION`, `DEWORMING`, `EXTERNAL_PARASITE`, `INJECTION_INFUSION`, `PROCEDURE`, `SURGERY` | Bác sĩ khám chính | Không vào hàng đợi CLS. Bác sĩ chỉ định rồi thực hiện ngay trong phòng, bấm *"Đã thực hiện"* (hệ thống ghi lần lượt `START_PROCESSING`, `COMPLETED`). Phải xong hoặc hủy trước khi Bác sĩ rời giai đoạn khám. |
| **Dịch vụ cận lâm sàng** | `LABORATORY`, `IMAGING` | KTV Xét nghiệm / KTV – Bác sĩ CĐHA | **Tự động** vào hàng đợi riêng của phòng tương ứng ngay khi chỉ định (đặt `queue_position`), có các trạng thái con bên dưới. |

**Trạng thái con không lưu thành cột** mà suy ra từ `action` của dòng `visit_service_detail_histories` mới nhất:

| Trạng thái chính | Trạng thái con | `action` mới nhất | Ý nghĩa |
| :--- | :--- | :--- | :--- |
| `PENDING` | `QUEUED` | `ORDERED`, `SKIPPED` hoặc `MOVED_TO_END` | Chờ gọi số trong hàng đợi phòng theo `queue_position` (ca cấp cứu lên đầu, còn lại theo thứ tự chỉ định, có thể đã đổi do lùi 1 bậc – EX-06, EX-07). Ca vẫn ở trong hàng đợi, không có tab riêng. |
| `IN_PROGRESS` (Lab) | `SAMPLING` | `START_PROCESSING` | Thú cưng đang ở phòng Lab để lấy mẫu. |
| `IN_PROGRESS` (Lab) | `ANALYZING` | `SAMPLE_COLLECTED` | Đã lấy mẫu xong, thú cưng được tự do; máy đang phân tích. |

> Giá trị `SAMPLE_COLLECTED` được bổ sung vào danh sách `action` (cột `VARCHAR(50)`, không cần đổi cấu trúc bảng). Nhờ nó, phòng CĐHA biết chính xác thú cưng có **đang ở phòng Lab** hay không (EX-09): chỉ hiện huy hiệu *"Đang lấy máu bên phòng Lab"* khi ca có dịch vụ `LABORATORY` ở trạng thái con `SAMPLING`. Khi KTV / Bác sĩ CĐHA bấm "Gọi số kế tiếp", hệ thống **tự bỏ qua** ca này (giữ nguyên vị trí, không ghi `SKIPPED`) và gọi ca liền sau; phòng Lab cũng bỏ qua ca đang chụp ở phòng CĐHA.

> **Cập nhật 11/11:** các giá trị `action` `POSTPONED` và `RECALL` (tab "Ca tạm hoãn", ghim "Ưu tiên kế tiếp") không còn dùng; thay bằng `SKIPPED` (lùi 1 bậc) và `MOVED_TO_END` (đưa xuống cuối hàng ở lần lùi thứ 3) như hàng đợi phòng khám (mục 2.4).

### 4.2. Sơ đồ Trạng thái (Mermaid State Machine) – Dịch vụ cận lâm sàng

```mermaid
stateDiagram-v2
    [*] --> PENDING : Bác sĩ chỉ định (tạo kèm hóa đơn PENDING)

    state PENDING {
        [*] --> QUEUED : Tự vào hàng đợi phòng Lab / CĐHA
        QUEUED --> QUEUED : Vắng mặt khi gọi - Lùi 1 bậc (EX-06) / lần 3 xuống cuối hàng (EX-07)
    }

    QUEUED --> IN_PROGRESS : KTV gọi số, thú cưng vào phòng, bấm "Bắt đầu làm"

    state IN_PROGRESS {
        [*] --> SAMPLING : Lab - đang lấy mẫu
        SAMPLING --> ANALYZING : KTV bấm "Đã lấy mẫu"
    }

    PENDING --> CANCELLED : Khách xin hủy dịch vụ (EX-08) - hóa đơn CANCELLED
    IN_PROGRESS --> COMPLETED : Nhập đủ kết quả và bấm Xác nhận lưu
    IN_PROGRESS --> CANCELLED : Thiết bị sự cố / Không lấy được mẫu - hóa đơn CANCELLED

    COMPLETED --> [*]
    CANCELLED --> [*]
```

> Với dịch vụ CĐHA, `IN_PROGRESS` không có trạng thái con (thú cưng ở phòng máy suốt quá trình chụp / siêu âm).

### 4.3. Bảng Ma trận Chuyển đổi Trạng thái Dịch vụ

Mọi dòng đều ghi 1 dòng `visit_service_detail_histories` (`from_status`, `to_status`, `action`, `changed_by_user_id`, `reason`).

| Trạng thái nguồn | Sự kiện kích hoạt | Điều kiện / Nghiệp vụ | Tác động CSDL & Hóa đơn | Trạng thái đích |
| :--- | :--- | :--- | :--- | :--- |
| `[*] (None)` | Bác sĩ chỉ định dịch vụ (T04, hoặc dịch vụ tại phòng trong GĐ 1 / GĐ 2) | Dịch vụ đang `is_active = TRUE` trong `services` | Tạo `visit_service_details` (`PENDING`, `action = ORDERED`) **và** `service_invoices` (`PENDING`, snapshot `unit_price = services.price`, `vat_rate = services.vat_rate`) trong cùng giao dịch. Với dịch vụ CLS: đặt `queue_position` để **tự đưa vào hàng đợi phòng** Xét nghiệm / CĐHA (ca cấp cứu trước ca không cấp cứu đầu tiên, ca thường cuối hàng). | `PENDING` |
| `[*] (None)` | Bác sĩ bấm *"Bắt đầu khám"* (T02) | Tự động, chỉ áp dụng cho dịch vụ khám | Tạo dòng dịch vụ khám với `status = IN_PROGRESS` và hóa đơn `PENDING`. | `IN_PROGRESS` |
| `PENDING` (`QUEUED`) | KTV bấm "Không có mặt – Lùi 1 bậc" (EX-06) | Đã gọi số, thông báo lặp lại tối đa 3 lần khách không vào; số lần lùi trong lượt chờ < 2 | Hoán đổi `queue_position` với dịch vụ liền sau trong hàng đợi cùng phòng (khóa 2 dòng); giữ `status = PENDING`, ghi `action = SKIPPED`. Tự gọi ca kế tiếp. | `PENDING` (`QUEUED`) |
| `PENDING` (`QUEUED`) | Lùi lần thứ 3 trong lượt chờ (EX-07) | Đã có 2 dòng `SKIPPED` trong lượt chờ | `queue_position` = lớn nhất của hàng + 1; ghi `action = MOVED_TO_END`; báo Lễ tân liên hệ khách. Khách quay lại thì chờ đến lượt bình thường. | `PENDING` (`QUEUED`) |
| `PENDING` | KTV bấm *"Bắt đầu làm"* | Thú cưng đã vào phòng lấy mẫu / lên bàn chụp (sau khi được gọi số) | `status = IN_PROGRESS`, `action = START_PROCESSING`. Dịch vụ rời hàng đợi phòng. | `IN_PROGRESS` |
| `IN_PROGRESS` (Lab, `SAMPLING`) | KTV bấm *"Đã lấy mẫu"* | Mẫu đã nạp máy | Giữ `status = IN_PROGRESS`, `action = SAMPLE_COLLECTED`. Thú cưng có thể sang phòng CĐHA. | `IN_PROGRESS` (`ANALYZING`) |
| `PENDING` | Khách xin hủy dịch vụ (EX-08) hoặc Bác sĩ bỏ chỉ định khi mở lại hồ sơ (T14) | Hóa đơn của dịch vụ chưa `PAID`; bắt buộc nhập lý do | `status = CANCELLED`, `action = CANCELLED`; hóa đơn tương ứng → `CANCELLED` trong cùng giao dịch. Nếu đây là dịch vụ CLS cuối cùng còn dở, kích hoạt T06 cho đợt khám. | `CANCELLED` |
| `IN_PROGRESS` | Lưu kết quả chuyên môn (UC-25_26) hoặc Bác sĩ bấm *"Đã thực hiện"* | Lab: nhập đủ các chỉ số thuộc gói (`service_lab_test_items`); CĐHA: có kết luận và tệp ảnh | `status = COMPLETED`. Lưu `lab_test_results` (kèm snapshot `min/max`) hoặc `imaging_results` + `imaging_attachments`. Hóa đơn giữ `PENDING`. Kiểm tra điều kiện T06. | `COMPLETED` |
| `IN_PROGRESS` | Thiết bị gặp sự cố / Không lấy được mẫu | Bắt buộc nhập lý do | `status = CANCELLED`; hóa đơn → `CANCELLED`. Kiểm tra điều kiện T06. | `CANCELLED` |

---

## 5. STATE MACHINE 4: LỊCH HẸN KHÁM (APPOINTMENT)

### 5.1. Ý nghĩa & Vai trò nghiệp vụ
Bảng `appointments` quản lý vòng đời của yêu cầu đặt lịch hẹn trước của chủ nuôi (qua Cổng trực tuyến hoặc đặt tại quầy / điện thoại). Hệ thống duy trì liên kết lỏng (Loose Coupling) giữa Lịch hẹn (`appointment-service`) và Ca khám thực tế (`clinical-service`) qua khóa ngoại logic `pet_visits.appointment_id`. Mỗi lần đổi trạng thái đều ghi 1 dòng `appointment_status_histories`; người duyệt / người hủy ghi ở `changed_by_user_id`, lý do ghi ở `notes`.

### 5.2. Sơ đồ Trạng thái (Mermaid State Machine)

```mermaid
stateDiagram-v2
    [*] --> PENDING : Chủ nuôi gửi yêu cầu đặt lịch Online (UC-14)
    [*] --> CONFIRMED : Lễ tân đặt lịch tại quầy / điện thoại (UC-16)

    PENDING --> CONFIRMED : Lễ tân xác nhận và duyệt lịch hẹn (UC-17)
    PENDING --> CANCELLED : Lễ tân từ chối (hết chỗ, trùng giờ)
    PENDING --> CANCELLED : Chủ nuôi tự hủy yêu cầu (UC-15)

    CONFIRMED --> CHECKED_IN : Khách đến quầy tiếp đón (UC-19) - tạo Pet Visit
    CONFIRMED --> CANCELLED : Khách báo hủy trước giờ khám
    CONFIRMED --> NO_SHOW : Quá 30 phút so với giờ hẹn không đến (EX-01)

    CHECKED_IN --> [*]
    CANCELLED --> [*]
    NO_SHOW --> [*]
```

### 5.3. Bảng Ma trận Chuyển đổi Trạng thái Lịch hẹn

| Trạng thái nguồn | Sự kiện kích hoạt | Điều kiện canh (Guard) | Tác động hệ thống & CSDL | Trạng thái đích |
| :--- | :--- | :--- | :--- | :--- |
| `[*] (None)` | Khách đặt lịch qua Portal (UC-14) | Khung giờ còn chỗ: số lịch `PENDING` / `CONFIRMED` / `CHECKED_IN` có cùng `appointment_date` + `start_time` < sức chứa khung giờ (= số Bác sĩ đang hoạt động × 2). Đếm bằng index `idx_appointments_slot`. | Tạo `appointments` (`status = PENDING`, `booking_channel = ONLINE`). Tạm giữ chỗ. Ghi lịch sử (`from_status = NULL`). | `PENDING` |
| `[*] (None)` | Lễ tân tạo lịch tại quầy / điện thoại (UC-16) | Thông tin khách hàng và thú cưng hợp lệ; khung giờ còn chỗ | Tạo bản ghi `status = CONFIRMED`, `booking_channel = PHONE` hoặc `WALK_IN`. | `CONFIRMED` |
| `PENDING` | Lễ tân duyệt lịch hẹn (UC-17) | Lễ tân xác thực thành công | `status = CONFIRMED`; `changed_by_user_id` = Lễ tân duyệt. Gửi thông báo xác nhận đến Portal. | `CONFIRMED` |
| `PENDING` | Lễ tân từ chối hoặc khách tự hủy (UC-15) | Bắt buộc nhập lý do | `status = CANCELLED`; lý do ghi vào `notes`. Giải phóng chỗ của khung giờ. | `CANCELLED` |
| `CONFIRMED` | Khách báo hủy hẹn trước giờ khám | Bắt buộc nhập lý do | `status = CANCELLED`; lý do ghi vào `notes`. Giải phóng chỗ. | `CANCELLED` |
| `CONFIRMED` | Khách đến phòng khám tiếp nhận (UC-19) | Khách có mặt tại quầy đúng `appointment_date` | `clinical-service` tạo `pet_visits` (`WAITING`) với `appointment_id` = lịch này (T01) trong giao dịch của mình, sau commit phát `VisitCheckedInEvent`; `appointment-service` nhận sự kiện rồi chuyển `status = CHECKED_IN` và ghi lịch sử trong giao dịch riêng (nhất quán sau, vài trăm mili giây). | `CHECKED_IN` |
| `CONFIRMED` | Tác vụ định kỳ quét vắng mặt (EX-01) | Thời điểm hiện tại > `appointment_date` + `start_time` + 30 phút | `status = NO_SHOW`; dòng lịch sử có `changed_by_user_id = NULL` (hệ thống). Hủy giữ chỗ, nhường lượt cho khách vãng lai. | `NO_SHOW` |

---

## 6. STATE MACHINE 5: HÓA ĐƠN DỊCH VỤ (SERVICE INVOICE)

### 6.1. Ý nghĩa & Vai trò nghiệp vụ
Bảng `service_invoices` (thuộc `clinical-service`) lưu **hóa đơn riêng cho từng dịch vụ** được chỉ định (`visit_service_detail_id UNIQUE`, quan hệ 1–1). Một đợt khám có bao nhiêu dịch vụ thì có bấy nhiêu hóa đơn dịch vụ. Hóa đơn được tạo **ngay lúc chỉ định**, không đợi chốt ca, và không lưu tổng tiền: số tiền phải trả tính bằng `quantity × unit_price × (1 + vat_rate) − discount_amount` (VIEW `v_service_invoice_amounts`).

Vì hóa đơn dịch vụ và đợt khám nằm chung một CSDL, việc thu tiền hóa đơn cuối cùng và chuyển đợt khám sang `COMPLETED` (T10) diễn ra trong **một giao dịch cục bộ**, không cần sự kiện bất đồng bộ.

### 6.2. Sơ đồ Trạng thái (Mermaid State Machine)

```mermaid
stateDiagram-v2
    [*] --> PENDING : Bác sĩ chỉ định dịch vụ (cùng giao dịch tạo visit_service_details)

    PENDING --> PAID : Khách thanh toán, Thu ngân bấm "Xác nhận thanh toán" (UC-35)
    PENDING --> CANCELLED : Dịch vụ tương ứng bị hủy (EX-08, T11, T12, T14)

    PAID --> [*] : Nếu là hóa đơn cuối của ca thì ca chuyển COMPLETED (T10)
    CANCELLED --> [*]
```

### 6.3. Bảng Ma trận Chuyển đổi Trạng thái Hóa đơn Dịch vụ

| Trạng thái nguồn | Sự kiện kích hoạt | Điều kiện canh (Guard) | Tác động hệ thống & CSDL | Trạng thái đích |
| :--- | :--- | :--- | :--- | :--- |
| `[*] (None)` | Tạo dòng `visit_service_details` (T02, T04, dịch vụ tại phòng) | Luôn đi cùng dòng chỉ định | Sinh mã `invoice_code` duy nhất (`SINV-YYYY-XXXX`). Snapshot `unit_price`, `vat_rate` từ `services`. `discount_amount = 0`. | `PENDING` |
| `PENDING` | Thu ngân bấm *"Xác nhận thanh toán"* (UC-35) | Đợt khám đang `WAITING_PAYMENT` (hoặc đã `COMPLETED` với công nợ theo EX-11); `discount_amount` ≤ số tiền trước giảm của chính hóa đơn này (EX-14); đã nhận đủ tiền; `version` khớp (khóa lạc quan, chống thu trùng). | `payment_status = PAID`, `paid_at = NOW()`, `cashier_id = :id`. Kiểm tra T10 cho đợt khám trong cùng giao dịch. In phiếu thu. | `PAID` |
| `PENDING` | Dịch vụ tương ứng chuyển `CANCELLED` (SM-03) | Không có thao tác hủy hóa đơn độc lập: muốn bỏ một khoản tiền thì hủy dịch vụ (sai sót sau chốt ca → mở lại hồ sơ theo T14) | `payment_status = CANCELLED` trong cùng giao dịch với dịch vụ. Không tính vào doanh thu. | `CANCELLED` |

> `PAID` là trạng thái cuối. Hoàn tiền dịch vụ đã thu nằm ngoài phạm vi đồ án; vì vậy SM-03 không cho hủy dịch vụ có hóa đơn đã `PAID`.

---

## 7. STATE MACHINE 6: HÓA ĐƠN THUỐC (MEDICINE INVOICE)

### 7.1. Ý nghĩa & Vai trò nghiệp vụ
Từ v3.0, **đơn thuốc (`prescriptions`) không còn trạng thái**: Bác sĩ kê đơn là chỉ định chuyên môn, khách hàng **được quyền mua tại phòng khám hoặc mua ngoài**. Bảng `medicine_invoices` (thuộc `billing-pharmacy-service`) chỉ phát sinh khi khách chọn mua thuốc tại phòng khám:
- Tối đa **1 hóa đơn thuốc cho 1 đơn thuốc** (`prescription_id UNIQUE`) → chống bán trùng (thay cho EX-16 cũ).
- Khách có thể mua **một phần** đơn thuốc: `medicine_invoice_items.quantity` ≤ `prescription_items.quantity`.
- **Thu tiền và trừ kho diễn ra trong cùng một giao dịch.** Thiếu kho (EX-15) thì rollback toàn bộ, không phát sinh khoản đã thu cần hoàn.
- Trạng thái đợt khám **không phụ thuộc** hóa đơn thuốc.

### 7.2. Sơ đồ Trạng thái (Mermaid State Machine)

```mermaid
stateDiagram-v2
    [*] --> PENDING : Khách chọn mua thuốc, Thu ngân chọn thuốc và số lượng

    PENDING --> PENDING : Sửa dòng hóa đơn (bỏ thuốc / giảm số lượng), kể cả sau EX-15
    PENDING --> PAID : Thu ngân "Xác nhận thanh toán & xuất thuốc" - trừ kho cùng giao dịch
    PENDING --> CANCELLED : Khách đổi ý, mua ngoài (kết thúc)

    PAID --> [*]
    CANCELLED --> [*]
```

### 7.3. Bảng Ma trận Chuyển đổi Trạng thái Hóa đơn Thuốc

| Trạng thái nguồn | Sự kiện kích hoạt | Điều kiện canh (Guard) | Tác động hệ thống & CSDL | Trạng thái đích |
| :--- | :--- | :--- | :--- | :--- |
| `[*] (None)` | Thu ngân bấm *"Bán thuốc theo đơn"* sau khi khách đồng ý mua | Đợt khám đã `WAITING_PAYMENT` hoặc `COMPLETED` (đơn thuốc đã khóa); đơn thuốc chưa có hóa đơn thuốc (`prescription_id UNIQUE`); mỗi dòng mua có `quantity` ≤ số lượng kê. | Tạo `medicine_invoices` (`PENDING`, mã `MINV-YYYY-XXXX`) và các `medicine_invoice_items` (snapshot `unit_price = medicines.sale_price`, `vat_rate = medicines.vat_rate`). | `PENDING` |
| `PENDING` | Thu ngân bấm *"Xác nhận thanh toán & xuất thuốc"* (UC-35, UC-36) | `discount_amount` ≤ tổng tiền thuốc trước giảm (EX-14); đã lấy thuốc và kiểm tra hạn dùng; `version` khớp. | Giao dịch `@Transactional`: với mỗi dòng `UPDATE medicines SET stock_quantity = stock_quantity - :qty WHERE id = :id AND stock_quantity >= :qty`; ghi `inventory_transactions` (`EXPORT_SALE`, `quantity = -:qty`, `medicine_invoice_id`); cập nhật `payment_status = PAID`, `paid_at`, `cashier_id`. | `PAID` |
| `PENDING` | Như dòng trên nhưng có câu `UPDATE` ảnh hưởng 0 dòng (EX-15) | Tồn kho thực tế không đủ tại thời điểm xác nhận | **Rollback toàn bộ**: không trừ kho, không ghi nhật ký, hóa đơn giữ `PENDING`. Thu ngân báo khách: giảm số lượng / bỏ thuốc thiếu (dòng "Sửa hóa đơn thuốc" bên dưới) hoặc hủy để mua ngoài. | `PENDING` |
| `PENDING` | Thu ngân bấm *"Sửa hóa đơn thuốc"* (`PUT /api/v1/billing/medicine-invoices/{id}/items`) | Hóa đơn đang `PENDING`, `version` khớp; mỗi dòng còn lại có `quantity` ≤ số lượng kê; còn ít nhất 1 dòng; `discount_amount` ≤ tổng tiền thuốc mới (EX-14). | Cập nhật / xóa `medicine_invoice_items`; các dòng giữ nguyên snapshot `unit_price`, `vat_rate` đã chốt. Không đụng tồn kho. | `PENDING` |
| `PENDING` | Khách đổi ý không mua | Hóa đơn chưa `PAID` | `payment_status = CANCELLED`. Tồn kho không biến động. Vì `prescription_id UNIQUE`, đơn thuốc này không lập thêm hóa đơn thuốc khác: hủy là kết thúc, khách mua ngoài theo đơn in. | `CANCELLED` |
| `PAID` | Cố tình xác nhận lại hoặc lập hóa đơn thứ hai (EX-16) | – | Bị chặn: hóa đơn không còn `PENDING` (và `version` đã tăng); lập hóa đơn mới vi phạm `prescription_id UNIQUE`. | (giữ `PAID`) |

---

## TỔNG KẾT TÍNH NHẤT QUÁN TOÀN HỆ THỐNG

| Mã | Thực thể CSDL | Service | Cột trạng thái | Số trạng thái | Enum tham chiếu (`DANH_SACH_KIEU_ENUM_HE_THONG.md` v3.0) |
| :--- | :--- | :--- | :--- | :---: | :--- |
| **SM-01** | `pet_visits` | clinical | `status` | 7 | #6 `VisitStatus` |
| **SM-02** | *Computed Doctor* (không lưu, chỉ hiển thị) | clinical | `doctor_serving_status` (tính toán) | 2 | – (xem `THIET_KE_CO_SO_DU_LIEU_ERD.md`, mục Giá trị tính toán) |
| **SM-03** | `visit_service_details` | clinical | `status` | 4 (+3 trạng thái con suy ra từ lịch sử) | #8 `ServiceDetailStatus` |
| **SM-04** | `appointments` | appointment | `status` | 5 | #5 `AppointmentStatus` |
| **SM-05** | `service_invoices` | clinical | `payment_status` | 3 | #9 `PaymentStatus` |
| **SM-06** | `medicine_invoices` | billing-pharmacy | `payment_status` | 3 | #9 `PaymentStatus` |

Tài liệu liên quan (cùng thư mục): [DAC_TA_USE_CASE_CORE.md](DAC_TA_USE_CASE_CORE.md) · [THIET_KE_CO_SO_DU_LIEU_ERD.md](THIET_KE_CO_SO_DU_LIEU_ERD.md) · [DANH_SACH_KIEU_ENUM_HE_THONG.md](DANH_SACH_KIEU_ENUM_HE_THONG.md) · [TONG_HOP_NGOAI_LE_VA_XU_LY_HE_THONG.md](TONG_HOP_NGOAI_LE_VA_XU_LY_HE_THONG.md)

---

## PHỤ LỤC: THAY ĐỔI SO VỚI PHIÊN BẢN 2.0

| Vị trí | Bản 2.0 | Bản 3.0 | Lý do |
| :--- | :--- | :--- | :--- |
| Sơ đồ điều phối | `PAID → DISPENSED → COMPLETED` | Mọi hóa đơn dịch vụ `PAID` / `CANCELLED` → `COMPLETED`; hóa đơn thuốc là nhánh tùy chọn | Khách được mua thuốc ngoài; hóa đơn tách theo dịch vụ |
| SM-01 bảng chuyển trạng thái | Ghi `started_at`, `closed_at`, `completed_at`, `cancel_reason` | Ghi 1 dòng `pet_visit_status_histories` | Các cột này đã bỏ khỏi `pet_visits` (dữ liệu trùng với lịch sử) |
| SM-01 T01 | Guard "cân nặng, nhiệt độ > 0" | Bỏ; Bác sĩ nhập ở GĐ 1 (guard T04 / T05) | Cân đo do Bác sĩ thực hiện trong phòng khám |
| SM-01 T02 | – | Tự tạo dịch vụ khám + hóa đơn | Phí khám là dịch vụ; đảm bảo mọi ca có hóa đơn |
| SM-01 T08 | Tạo hóa đơn mới để ghi nợ | Giữ các hóa đơn dịch vụ đã có ở `PENDING` | Hóa đơn đã sinh lúc chỉ định |
| SM-01 T10 | Hóa đơn `PAID` **và** đơn thuốc `DISPENSED` | Mọi `service_invoices` `PAID` / `CANCELLED` | Thuốc không còn ràng buộc hoàn tất ca |
| SM-01 | `WAITING_RESULTS → CANCELLED` (mất doanh thu dịch vụ đã làm) | Thay bằng T12 `WAITING_RESULTS → COMPLETED` (ghi công nợ) | Không thất thoát tiền dịch vụ đã thực hiện |
| SM-01 | – | Thêm T13 (tạm hoãn EX-10) và T14 (mở lại hồ sơ) | Bản cũ nhắc tới nhưng thiếu chuyển trạng thái |
| SM-01 T11 | Gắn nhãn EX-03 ở sơ đồ hoạt động | Không gắn EX-03 (EX-03 là khách bỏ về ở sảnh) | Sai mã ngoại lệ |
| SM-02 công thức | Chỉ đếm `IN_PROGRESS` / `RESULTS_READY` | Đếm cả ca `WAITING` đã gán; loại ca đã hoãn khỏi Khóa ưu tiên | Chống phân công trùng; hết mâu thuẫn với EX-10 |
| SM-02 sơ đồ | `PRIORITY → AVAILABLE` bằng "Tạm hoãn" | Gọi trước (`→ BUSY`), vắng thì hoãn (`→ AVAILABLE`); thêm `AVAILABLE → PRIORITY` | Khớp công thức SQL và EX-10 |
| SM-03 | Snapshot `unit_price` vào `visit_service_details` | Tạo `service_invoices` kèm snapshot giá & thuế | `unit_price` chuyển sang hóa đơn dịch vụ |
| SM-03 | Chỉ mô tả dịch vụ Lab / CĐHA | Thêm dịch vụ khám và dịch vụ tại phòng (tiêm, thủ thuật) | Bản cũ bỏ sót |
| SM-03 | – | Trạng thái con suy ra từ `action`; thêm `SAMPLE_COLLECTED` | Phân biệt "đang lấy máu" với "máy đang chạy" cho EX-09 |
| SM-04 | `appointment_time`, `current_booked < max_capacity` | `appointment_date + start_time`; đếm lịch cùng khung giờ | Tên cột thực tế; CSDL không có cột sức chứa |
| SM-05 | 1 hóa đơn gộp / ca (`visit_id UNIQUE`), tạo lúc chốt ca | 1 hóa đơn / dịch vụ, tạo lúc chỉ định; hủy dịch vụ → hủy hóa đơn | Góp ý của GVHD |
| SM-06 | Vòng đời đơn thuốc `PRESCRIBED → DISPENSED / CANCELLED` | Vòng đời hóa đơn thuốc `PENDING → PAID (trừ kho) / CANCELLED` | Bỏ `PrescriptionStatus`; mua thuốc là tùy chọn |
| Bảng tổng kết | Enum #13, #12, #9 | Enum #8, #9 (theo danh sách v3.0) | Đánh số lại enum |
| SM-01 T11 (rà soát 10/11) | Hủy ca kể cả khi đã có dịch vụ tại phòng `COMPLETED` | Chỉ hủy khi chưa có dịch vụ tại phòng `COMPLETED`; ngược lại chốt ca T05 | Tránh hóa đơn `PENDING` treo ở ca `CANCELLED` |
| SM-01 T14 (rà soát 10/11) | Chỉ chặn sửa đơn khi hóa đơn thuốc `PAID` | Chặn khi có hóa đơn thuốc `PENDING` hoặc `PAID` | Tránh hóa đơn thuốc vượt số lượng kê |
| SM-04 (rà soát 10/11) | `CONFIRMED → CHECKED_IN` như cùng thao tác tạo đợt khám | Qua `VisitCheckedInEvent`, giao dịch riêng của `appointment-service` | Khớp Kiến trúc mục 5.3 |
| SM-06 (rà soát 10/11) | Tự chuyển `PENDING → PENDING` "sửa số lượng" không có thao tác cụ thể | Thêm thao tác "Sửa hóa đơn thuốc" (API, guard, tác động); hủy là kết thúc | EX-15 thực hiện được |
| SM-02 (rà soát 10/11) | Không có thao tác đổi / gỡ phân công | `BUSY → AVAILABLE` khi Lễ tân đổi Bác sĩ hoặc gỡ phân công ca `WAITING` | Khách tạm ra ngoài không khóa Bác sĩ |
| Quy ước chung, mục 2.4 (cập nhật 11/11) | Một hàng đợi sảnh chung, sắp theo `is_emergency`, `checked_in_at` | Mỗi Bác sĩ, phòng Xét nghiệm, phòng CĐHA có hàng đợi riêng sắp theo `queue_position`; thêm mục 2.4 mô tả phân công, chuyển phòng, gọi số, lùi 1 bậc, đưa xuống cuối hàng; cần bổ sung `queue_position`, `pet_visit_status_histories.action` và chỉ mục mới vào lược đồ | Phòng khám nhiều Bác sĩ cần mỗi phòng một hàng đợi; Lễ tân không phải chờ Bác sĩ rảnh |
| Sơ đồ điều phối (cập nhật 11/11) | Khối Bác sĩ 3 trạng thái; "Lễ tân gán doctor_id" làm Bác sĩ `BUSY`; "Bật Khóa ưu tiên" | Khối Bác sĩ 2 trạng thái chỉ hiển thị; Bác sĩ `BUSY` khi bắt đầu khám (T02 / T07) | Phân công không đổi trạng thái Bác sĩ |
| SM-01 T01, T02, T03, T04, T06, T07 (cập nhật 11/11) | T02 "Bác sĩ được phân công"; T04 "đẩy phiếu chỉ định"; T06 bật `AVAILABLE_PRIORITY_CALLBACK`; T07 "Mời vào phòng" chuyển ngay `IN_PROGRESS`, guard "không có ca `WAITING` đã gán" | T02 / T07: gọi số rồi mới bắt đầu / tiếp tục khám, guard chỉ xét ca `IN_PROGRESS`; T04 tự đưa dịch vụ CLS vào hàng đợi phòng; T06 chèn ca vào hàng đợi phòng Bác sĩ ở vị trí ưu tiên | Gọi số không đổi trạng thái; ưu tiên bằng vị trí |
| SM-01 T13 (cập nhật 11/11) | `IN_PROGRESS (GĐ 2) → RESULTS_READY` khi tạm hoãn; tab "Đã hoãn"; dấu hiệu `from_status = IN_PROGRESS` | **Bỏ**; khách vắng mặt thì lùi 1 bậc, ca giữ `RESULTS_READY` | Ca chưa vào phòng thì chưa `IN_PROGRESS` |
| SM-02 (cập nhật 11/11) | 3 trạng thái `AVAILABLE` / `BUSY` / `AVAILABLE_PRIORITY_CALLBACK`; `BUSY` gồm ca `WAITING` đã gán; chặn phân công | 2 trạng thái: `BUSY` = có ca `IN_PROGRESS`, `AVAILABLE` = không; chỉ hiển thị kèm số ca chờ, không chặn phân công | Bỏ điều kiện "Sẵn sàng" và Khóa ưu tiên (BR-11) |
| SM-03 (cập nhật 11/11) | Trạng thái con `POSTPONED`, `NEXT_IN_LINE` (`action` `POSTPONED`, `RECALL`) | Chỉ còn `QUEUED` (vắng mặt thì `SKIPPED` / `MOVED_TO_END`), `SAMPLING`, `ANALYZING`; dịch vụ CLS tự vào hàng đợi phòng; gọi số tự bỏ qua ca đang ở phòng khác | Cơ chế vắng mặt thống nhất với phòng khám |
