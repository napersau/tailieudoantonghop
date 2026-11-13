# THIẾT KẾ SƠ ĐỒ HOẠT ĐỘNG (UML ACTIVITY DIAGRAMS)
## HỆ THỐNG QUẢN LÝ PHÒNG KHÁM THÚ Y

> **Tài liệu chuẩn UML 2.5 / RUP phục vụ Thuyết minh & Bảo vệ Đồ án tốt nghiệp**  
> **Phiên bản:** 3.0 (đồng bộ với lược đồ CSDL v3.0 và `THIET_KE_SO_DO_TRANG_THAI_STATE_MACHINE.md` v3.0)  
> **Mục tiêu:** Mô tả chi tiết các luồng công việc (Workflows), sự phân làn trách nhiệm đa tác nhân (Swimlanes / Partitions), các điểm phân tách và đồng bộ song song (Fork & Join Nodes), các điều kiện rẽ nhánh (Decision Nodes) và cơ chế xử lý ngoại lệ trong hệ thống quản lý phòng khám thú y ngoại trú.

---

## MỤC LỤC TỔNG QUAN

1. [Quy chuẩn Ký hiệu & Nguyên tắc Thiết kế UML Activity Diagram](#1-quy-chuẩn-ký-hiệu--nguyên-tắc-thiết-kế-uml-activity-diagram)
2. [AD-01: Chu trình Khám chữa bệnh Ngoại trú Hai pha Tổng thể (End-to-End Clinical Cycle)](#2-ad-01-chu-trình-khám-chữa-bệnh-ngoại-trú-hai-pha-tổng-thể)
3. [AD-02: Quy trình Tiếp đón, Xếp hàng đợi riêng từng Bác sĩ & Gọi số (Patient Reception & Doctor Queues)](#3-ad-02-tiếp-đón-xếp-hàng-đợi-riêng-từng-bác-sĩ--gọi-số)
4. [AD-03: Quy trình Khám Lâm sàng Sơ bộ & Chỉ định Dịch vụ Giai đoạn 1 (Initial Assessment & Ordering)](#4-ad-03-khám-lâm-sàng-sơ-bộ--chỉ-định-dịch-vụ-giai-đoạn-1)
5. [AD-04: Quy trình Thực hiện Cận lâm sàng Song song & Xử lý Ngoại lệ Hàng đợi (Parallel Paraclinical Execution)](#5-ad-04-thực-hiện-cận-lâm-sàng-song-song--xử-lý-ngoại-lệ-hàng-đợi)
6. [AD-05: Quy trình Hội chẩn Kết quả, Chẩn đoán Xác định & Kê đơn Giai đoạn 2 (Post-diagnostic Consultation & Rx)](#6-ad-05-hội-chẩn-kết-quả-chẩn-đoán-xác-định--kê-đơn-giai-đoạn-2)
7. [AD-06: Quy trình Thu tiền Hóa đơn Dịch vụ & Bán thuốc theo Đơn (Billing & Optional Medicine Sale)](#7-ad-06-thu-tiền-hóa-đơn-dịch-vụ--bán-thuốc-theo-đơn-tùy-chọn)
8. [Ma trận Truy vết Nghiệp vụ Tổng hợp (Traceability Matrix)](#8-ma-trận-truy-vết-nghiệp-vụ-tổng-hợp-traceability-matrix)
9. [Phụ lục: Thay đổi so với phiên bản 2.0](#phụ-lục-thay-đổi-so-với-phiên-bản-20)

---

## 1. QUY CHUẨN KÝ HIỆU & NGUYÊN TẮC THIẾT KẾ UML ACTIVITY DIAGRAM

### 1.1. Bảng tra cứu ký hiệu chuẩn UML 2.5 áp dụng trong tài liệu

| Thành phần UML 2.5 | Ký hiệu đồ họa chuẩn | Biểu diễn trên Mermaid | Ý nghĩa nghiệp vụ |
| :--- | :---: | :---: | :--- |
| **Initial Node** | Hình tròn đặc đen `●` | `((Bắt đầu))` | Điểm khởi phát luồng thực thi nghiệp vụ. |
| **Activity Final Node** | Hình tròn có viền ngoài `◉` | `(((Kết thúc)))` | Điểm kết thúc toàn bộ quy trình công việc. |
| **Flow Final Node** | Hình tròn có dấu X `⊗` | `((x))` | Kết thúc một nhánh rẽ phụ mà không hủy toàn bộ luồng. |
| **Action Node** | Hình chữ nhật bo góc | `["Tên hành động"]` | Thao tác đơn vị do một vai trò hoặc hệ thống thực hiện. |
| **Decision / Merge Node** | Hình thoi `<>` | `{"Điều kiện kiểm tra?"}` | Điểm rẽ nhánh có điều kiện canh `[Guard]` hoặc gộp các nhánh rẽ. |
| **Fork Node** | Thanh ngang/dọc đậm | `[[FORK: ...]]` | Phân tách một luồng thực thi thành 2 hay nhiều luồng song song độc lập. |
| **Join Node** | Thanh ngang/dọc đậm | `[[JOIN: ...]]` | Điểm hội tụ, chờ tất cả các luồng song song hoàn tất mới đi tiếp. |
| **Swimlane / Partition** | Cột / Hàng phân cách | `subgraph VaiTrò` | Ranh giới trách nhiệm của từng Actor hoặc Hệ thống. |
| **Object Node / Pin** | Hình chữ nhật vuông | `[Entity: State]` | Trạng thái của thực thể CSDL tại một thời điểm then chốt. |

### 1.2. Danh sách 6 Phân làn trách nhiệm (Swimlanes / Partitions) chuẩn

Hệ thống được thiết kế theo mô hình phân quyền của CSDL (`roles`) và tác nhân tự động:
1. **Chủ thú cưng (Pet Owner):** Người mang thú cưng đến, cung cấp triệu chứng, đưa thú cưng vào các phòng, thanh toán hóa đơn dịch vụ, **tự chọn mua thuốc tại phòng khám hoặc mua ngoài** theo đơn của Bác sĩ.
2. **Lễ tân / Thu ngân (Receptionist / Cashier):** Tiếp đón tại quầy, kiểm tra lịch hẹn, phân công bác sĩ, thu tiền các hóa đơn dịch vụ, và bán thuốc theo đơn khi khách chọn mua (lấy thuốc từ tủ, lập hóa đơn thuốc).
3. **Bác sĩ khám chính (`VETERINARIAN`):** Phụ trách ca khám tại phòng khám cố định: cân đo sinh hiệu và khám lâm sàng sơ bộ (GĐ 1), thực hiện các dịch vụ tại phòng (tiêm, tẩy giun, thủ thuật), chỉ định cận lâm sàng, đọc kết quả tổng hợp (GĐ 2), chẩn đoán xác định và kê đơn thuốc.
4. **Kỹ thuật viên Xét nghiệm (`LAB_TECHNICIAN`):** Phụ trách phòng Xét nghiệm, lấy mẫu máu/bệnh phẩm, nạp máy phân tích, nhập kết quả các chỉ số thuộc gói xét nghiệm.
5. **Kỹ thuật viên / Bác sĩ CĐHA (`IMAGING_TECHNICIAN`):** Phụ trách phòng Chẩn đoán hình ảnh, siêu âm, chụp X-quang, tải ảnh lên hệ thống và đưa ra kết luận hình thái học.
6. **Hệ thống phần mềm (Automated System):** Tính trạng thái bác sĩ thời gian thực, sắp xếp hàng đợi riêng từng Bác sĩ và hàng đợi phòng CLS, thông báo gọi số theo từng dòng (không đổi thứ tự), ghi lịch sử trạng thái và thực hiện giao dịch CSDL an toàn (`@Transactional`).

### 1.3. Quy ước dữ liệu xuyên suốt các sơ đồ
- **Mọi lần đổi trạng thái** của lịch hẹn, đợt khám, chỉ định dịch vụ đều ghi 1 dòng lịch sử tương ứng (`*_status_histories`, `visit_service_detail_histories`). Sơ đồ không vẽ lại bước này ở từng nút.
- **Mỗi dịch vụ được chỉ định có 1 hóa đơn dịch vụ riêng** (`service_invoices`), tạo cùng lúc với chỉ định. Phí khám cũng là một dịch vụ, được tạo tự động khi Bác sĩ bấm "Bắt đầu khám".
- **Đơn thuốc không có trạng thái và không có giá.** Giá thuốc chỉ được chốt khi khách mua tại phòng khám (`medicine_invoice_items`).
- Mã chuyển trạng thái `T01`–`T14` tham chiếu bảng SM-01 trong tài liệu State Machine.

---

## 2. AD-01: CHU TRÌNH KHÁM CHỮA BỆNH NGOẠI TRÚ HAI PHA TỔNG THỂ

### 2.1. Ý nghĩa & Bối cảnh nghiệp vụ
Đây là **sơ đồ hoạt động cốt lõi** của phần mềm, mô tả trọn vẹn chu trình một thú cưng từ khi bước vào phòng khám cho đến khi ra về. Quy trình phản ánh mô hình **Chu kỳ Y tế Bất đồng bộ (Asynchronous Clinical Cycle)**: giải phóng bác sĩ khi bệnh nhân đi làm cận lâm sàng, và khi có kết quả thì đưa ca lên đầu hàng đợi riêng của bác sĩ khám chính.

Điểm khác biệt của phiên bản 3.0 nằm ở cuối quy trình: **ca khám hoàn tất ngay khi khách thanh toán xong các hóa đơn dịch vụ**. Mua thuốc là một **nhánh tùy chọn** sau đó; khách mua ngoài thì chỉ nhận đơn thuốc in và ra về.

### 2.2. Sơ đồ Hoạt động Swimlane (Mermaid Diagram)

```mermaid
flowchart TD
    subgraph LANE_CLIENT["CHỦ THÚ CƯNG (Pet Owner)"]
        CL_START((Bắt đầu))
        CL_BRING["Đưa thú cưng đến sảnh phòng khám"]
        CL_WAIT_1["Chờ tại sảnh tiếp đón"]
        CL_ENTER_CLINIC["Đưa thú cưng vào phòng Bác sĩ"]
        CL_GO_PARACLINIC["Đưa thú cưng sang khu Cận lâm sàng"]
        CL_WAIT_2["Ngồi chờ kết quả tại sảnh"]
        CL_RE_ENTER["Đưa thú cưng vào lại phòng Bác sĩ (GĐ 2)"]
        CL_PAY["Thanh toán các hóa đơn dịch vụ tại quầy"]
        CL_BUY{"Mua thuốc tại\nphòng khám?"}
        CL_PAY_MED["Thanh toán hóa đơn thuốc,\nnhận thuốc & hướng dẫn dùng"]
        CL_OUTSIDE["Nhận đơn thuốc in,\nmua thuốc ở nơi khác"]
        CL_END(((Kết thúc: Thú cưng ra về)))
    end

    subgraph LANE_RECEPTION["LỄ TÂN / THU NGÂN (Receptionist / Cashier)"]
        REC_CHECKIN["Tiếp nhận, sàng lọc cấp cứu ban đầu\n(Tạo Pet Visit)"]
        REC_ASSIGN["Xếp ca vào hàng đợi riêng của một Bác sĩ\n(gợi ý Bác sĩ ít người chờ nhất)"]
        REC_BILLING["Mở danh sách hóa đơn dịch vụ của ca,\nnhập giảm giá (nếu có), xác nhận thu tiền"]
        REC_SELL["Lập hóa đơn thuốc theo đơn,\nlấy thuốc, kiểm tra hạn dùng, dán nhãn"]
    end

    subgraph LANE_DOCTOR["BÁC SĨ KHÁM CHÍNH (Veterinarian)"]
        DOC_CALL_1["Bấm 'Gọi' ở một ca\n(vắng mặt → gọi ca khác)"]
        DOC_START_1["Bấm 'Bắt đầu khám' (GĐ 1)\nCân đo sinh hiệu, khám thực thể"]
        DOC_DECIDE{"Cần chỉ định\nCận lâm sàng?"}
        DOC_ORDER["Chọn dịch vụ Lab / CĐHA,\nbấm 'Chỉ định & Gửi phòng CLS'"]
        DOC_FAST_RX["Chẩn đoán, thực hiện dịch vụ tại phòng\n(tiêm, tẩy giun...), kê đơn nếu cần"]
        DOC_CALL_G2["Bấm 'Gọi' ở ca có KQ (đang đứng đầu),\nbấm 'Bắt đầu GĐ 2' khi thú cưng vào phòng"]
        DOC_CONSULT["Phân tích chỉ số máu, ảnh X-quang,\nchẩn đoán xác định & kê đơn thuốc"]
        DOC_CLOSE["Bấm 'Chốt đợt khám & Khóa bệnh án'"]
    end

    subgraph LANE_LAB["KỸ THUẬT VIÊN LAB (Lab Technician)"]
        LAB_QUEUE["Tiếp nhận chỉ định vào hàng đợi Lab"]
        LAB_EXEC["Lấy mẫu máu, nạp máy phân tích"]
        LAB_INPUT["Nhập kết quả các chỉ số,\nbấm Xác nhận hoàn tất"]
    end

    subgraph LANE_IMAGING["KTV / BÁC SĨ CĐHA (Imaging Technician / Doctor)"]
        IMG_QUEUE["Tiếp nhận chỉ định vào hàng đợi CĐHA"]
        IMG_EXEC["Đưa thú cưng lên bàn chụp X-quang / Siêu âm"]
        IMG_INPUT["Tải ảnh, nhập kết luận hình thái,\nbấm Xác nhận hoàn tất"]
    end

    subgraph LANE_SYSTEM["HỆ THỐNG PHẦN MỀM (Automated System)"]
        SYS_ENQUEUE["pet_visits: WAITING\nqueue_order = thời điểm tiếp nhận"]
        SYS_BUSY_1["pet_visits: IN_PROGRESS (T02)\nTạo dịch vụ khám + hóa đơn dịch vụ PENDING"]
        SYS_FREE_DOC["Tạo visit_service_details + service_invoices (PENDING)\npet_visits: WAITING_RESULTS (T04)\nGiải phóng Bác sĩ"]
        SYS_FORK_CLS[["FORK: Phân tách theo phòng có dịch vụ"]]
        SYS_JOIN_CLS[["JOIN: Mọi dịch vụ CLS đã xong hoặc hủy"]]
        SYS_READY["pet_visits: RESULTS_READY (T06)\nCa lên đầu hàng đợi của Bác sĩ khám chính"]
        SYS_BUSY_2["pet_visits: IN_PROGRESS GĐ 2 (T07)\nMở bệnh án tổng hợp"]
        SYS_LOCK_PAY["Lưu đơn thuốc (nếu có), khóa bệnh án\npet_visits: WAITING_PAYMENT (T05 / T09)"]
        SYS_PAID["@Transactional: service_invoices PAID\nĐủ hóa đơn → pet_visits: COMPLETED (T10)"]
        SYS_TX_SELL["@Transactional: trừ kho có điều kiện,\nghi inventory_transactions (EXPORT_SALE),\nmedicine_invoices: PAID"]
    end

    CL_START --> CL_BRING --> REC_CHECKIN --> SYS_ENQUEUE
    SYS_ENQUEUE --> REC_ASSIGN --> CL_WAIT_1
    REC_ASSIGN --> DOC_CALL_1 --> CL_ENTER_CLINIC
    CL_ENTER_CLINIC --> DOC_START_1 --> SYS_BUSY_1 --> DOC_DECIDE

    DOC_DECIDE -- "[Không cần CLS]" --> DOC_FAST_RX
    DOC_FAST_RX --> DOC_CLOSE

    DOC_DECIDE -- "[Cần xét nghiệm / chụp ảnh]" --> DOC_ORDER
    DOC_ORDER --> SYS_FREE_DOC
    SYS_FREE_DOC --> CL_GO_PARACLINIC
    SYS_FREE_DOC --> SYS_FORK_CLS

    SYS_FORK_CLS -- "[Có dịch vụ LABORATORY]" --> LAB_QUEUE --> LAB_EXEC --> LAB_INPUT --> SYS_JOIN_CLS
    SYS_FORK_CLS -- "[Có dịch vụ IMAGING]" --> IMG_QUEUE --> IMG_EXEC --> IMG_INPUT --> SYS_JOIN_CLS

    SYS_JOIN_CLS --> SYS_READY --> CL_WAIT_2
    SYS_READY --> DOC_CALL_G2
    DOC_CALL_G2 --> SYS_BUSY_2 --> CL_RE_ENTER
    CL_RE_ENTER --> DOC_CONSULT --> DOC_CLOSE

    DOC_CLOSE --> SYS_LOCK_PAY --> REC_BILLING
    REC_BILLING --> CL_PAY --> SYS_PAID
    SYS_PAID --> CL_BUY
    CL_BUY -- "[Không / Không kê đơn]" --> CL_OUTSIDE --> CL_END
    CL_BUY -- "[Có]" --> REC_SELL --> CL_PAY_MED --> SYS_TX_SELL --> CL_END
```

> **Ghi chú:** Nhánh "Không" của nút `CL_BUY` gồm cả trường hợp Bác sĩ không kê đơn (khách ra về ngay). Chi tiết thu tiền và bán thuốc ở AD-06.

---

## 3. AD-02: TIẾP ĐÓN, XẾP HÀNG ĐỢI RIÊNG TỪNG BÁC SĨ & GỌI SỐ

### 3.1. Ý nghĩa & Bối cảnh nghiệp vụ
Biểu diễn quy trình tiếp đón tại sảnh (UC-18, UC-19, UC-20, UC-21), xử lý hai nguồn khách hàng (Khách đặt lịch trước và Khách vãng lai Walk-in), việc Lễ tân **xếp ca vào hàng đợi riêng của từng Bác sĩ** và cách Bác sĩ **gọi theo từng dòng** (khách vắng thì gọi ca khác) trong hàng đợi của mình. Lễ tân không phải chờ Bác sĩ rảnh mới phân ca. Lễ tân **không cân đo sinh hiệu** tại quầy; việc này do Bác sĩ thực hiện trong phòng khám (AD-03).

### 3.2. Sơ đồ Hoạt động Phân làn

```mermaid
flowchart TD
    subgraph LANE_CLIENT["CHỦ THÚ CƯNG"]
        C_ARRIVE((Khách đến phòng khám))
        C_PROVIDE["Cung cấp SĐT / Mã lịch hẹn"]
        C_WAIT["Nhận phiếu số phòng + số thứ tự,\nngồi chờ trước phòng Bác sĩ"]
        C_PRESENT{"Có mặt khi\nđược gọi số?"}
        C_ENTER["Đưa thú cưng vào phòng Bác sĩ"]
    end

    subgraph LANE_RECEPTION["LỄ TÂN (Receptionist)"]
        R_SEARCH["Tìm kiếm khách hàng & thú cưng trên hệ thống"]
        R_DECIDE_NEW{"Khách hàng / Thú cưng\nđã có hồ sơ chưa?"}
        R_CREATE["Tạo hồ sơ Khách hàng & Thú cưng mới (UC-18)"]
        R_CHECK_APPT{"Có lịch hẹn hôm nay\nđã CONFIRMED?"}
        R_UPDATE_APPT["Check-in lịch hẹn"]
        R_WALKIN["Ghi nhận ca vãng lai (EX-02)"]
        R_TRIAGE["Ghi lý do đến khám / triệu chứng ban đầu\nĐánh giá cấp cứu (is_emergency, EX-04)"]
        R_PICK["Xem bảng điều phối, chọn Bác sĩ\n(theo gợi ý hoặc yêu cầu của khách)"]
    end

    subgraph LANE_DOCTOR["BÁC SĨ (Veterinarian)"]
        D_CALL["Không đang khám ca nào,\nbấm 'Gọi' ở một ca\n(hoặc 'Gọi số tiếp theo')"]
        D_SKIP["[EX-10] Gọi 2-3 lần không thấy,\nbấm 'Gọi' ca khác"]
        D_START["Bấm 'Bắt đầu khám' (sang AD-03)"]
    end

    subgraph LANE_SYSTEM["HỆ THỐNG PHẦN MỀM"]
        S_CHECK_OPEN{"Thú cưng đang có\nđợt khám chưa kết thúc?"}
        S_OPEN_ERR["CẢNH BÁO: 'Thú cưng đang có đợt khám mở,\nkhông tạo đợt khám mới'"]
        S_CREATE_VISIT["Tạo pet_visits: WAITING (T01)\nqueue_order = thời điểm tiếp nhận\nNếu có hẹn: phát VisitCheckedInEvent"]
        S_SUGGEST["Hiển thị số người đang chờ của từng Bác sĩ,\ngợi ý Bác sĩ ít người chờ nhất"]
        S_ASSIGN["Gán pet_visits.doctor_id (ca vẫn WAITING)\nCa vào hàng đợi của Bác sĩ theo queue_order\nIn phiếu số phòng + số thứ tự"]
        S_PICK_HEAD["Ca được chọn (mặc định: đầu hàng đợi\nORDER BY is_emergency DESC, queue_order)\nPhát PatientCalledEvent (màn hình sảnh + ứng dụng)\nGhi last_called_at (nhãn Đã gọi HH:mm)\nKhông đổi trạng thái và queue_order"]
        S_SKIP["Ca vắng giữ nguyên vị trí (không đổi queue_order,\nkhông đếm lần vắng); ca cấp cứu giữ ưu tiên.\nKhách quay lại: Bác sĩ bấm 'Gọi lại'"]
    end

    C_ARRIVE --> C_PROVIDE --> R_SEARCH --> R_DECIDE_NEW
    R_DECIDE_NEW -- "[Chưa có]" --> R_CREATE --> R_CHECK_APPT
    R_DECIDE_NEW -- "[Đã có]" --> R_CHECK_APPT

    R_CHECK_APPT -- "[Có hẹn CONFIRMED]" --> R_UPDATE_APPT --> R_TRIAGE
    R_CHECK_APPT -- "[Khách vãng lai]" --> R_WALKIN --> R_TRIAGE

    R_TRIAGE --> S_CHECK_OPEN
    S_CHECK_OPEN -- "[Có]" --> S_OPEN_ERR
    S_CHECK_OPEN -- "[Không]" --> S_CREATE_VISIT --> S_SUGGEST --> R_PICK --> S_ASSIGN --> C_WAIT

    C_WAIT --> D_CALL --> S_PICK_HEAD --> C_PRESENT
    C_PRESENT -- "[Có]" --> C_ENTER --> D_START
    C_PRESENT -- "[Vắng mặt]" --> D_SKIP --> S_SKIP --> D_CALL
```

> **Lưu ý:** Lễ tân xếp ca vào hàng đợi của bất kỳ Bác sĩ nào, kể cả Bác sĩ đang khám; trạng thái Bác sĩ chỉ chặn Bác sĩ gọi số khi đang khám dở (BR-12). Lễ tân có thể chuyển ca chưa bắt đầu khám sang hàng đợi Bác sĩ khác (giữ `queue_order`) hoặc gỡ về danh sách chờ phân công. Khách bỏ về khi đang chờ: Lễ tân hủy ca theo EX-03, ca rời khỏi hàng đợi. Ca vắng giữ nguyên vị trí và ca cấp cứu luôn giữ ưu tiên (từ 13/11/2026 không còn "Đẩy lùi 1 bậc").

---

## 4. AD-03: KHÁM LÂM SÀNG SƠ BỘ & CHỈ ĐỊNH DỊCH VỤ GIAI ĐOẠN 1

### 4.1. Ý nghĩa & Bối cảnh nghiệp vụ
Mô tả nghiệp vụ chuyên môn trong phòng khám tại Giai đoạn 1 (UC-22 & UC-23). Bác sĩ cân đo sinh hiệu, thăm khám thực thể, đưa ra chẩn đoán sơ bộ và rẽ nhánh:
- **Ca khám nhẹ / tiêm phòng / thủ thuật:** Bác sĩ chỉ định và **thực hiện ngay dịch vụ tại phòng** (tiêm vaccine, tẩy giun, tiêm thuốc, thay băng...), kê đơn nếu cần rồi chốt ca.
- **Ca phức tạp:** chỉ định cận lâm sàng, bệnh nhân sang phòng Lab / CĐHA, Bác sĩ được giải phóng để đón ca khác.

Mỗi dịch vụ được chỉ định (kể cả dịch vụ khám tạo tự động lúc bắt đầu) đều sinh **1 hóa đơn dịch vụ `PENDING`** trong cùng giao dịch.

### 4.2. Sơ đồ Hoạt động Phân làn

```mermaid
flowchart TD
    subgraph LANE_DOCTOR["BÁC SĨ THÚ Y (Veterinarian)"]
        D_CLICK_START["Nhấn nút 'Bắt đầu khám' trên giao diện"]
        D_EXAM["Thăm khám lâm sàng & đo sinh hiệu:\n- Cân nặng (weight_at_visit), thân nhiệt (temperature)\n- Nghe tim phổi, kiểm tra niêm mạc, hạch\n- Đọc lại lịch sử bệnh án cũ"]
        D_INPUT_NOTES["Nhập ghi chú lâm sàng & chẩn đoán sơ bộ"]
        D_BRANCH{"Đánh giá tình trạng thú cưng?"}

        D_ROUTINE_DIAG["Xác định chẩn đoán bệnh thông thường / lịch tiêm phòng"]
        D_ORDER_INROOM["Chỉ định dịch vụ tại phòng nếu cần\n(vaccine, tẩy giun, tiêm thuốc, thủ thuật)"]
        D_DO_INROOM["Thực hiện dịch vụ, bấm 'Đã thực hiện'"]
        D_PRESCRIBE_1["Kê đơn thuốc ngoại trú (nếu cần)"]
        D_FINISH_G1["Nhấn 'Chốt đợt khám & Chuyển thanh toán'"]

        D_SELECT_SVC["Chọn dịch vụ cận lâm sàng:\n- Xét nghiệm máu (CBC, Sinh hóa)\n- Chẩn đoán hình ảnh (Siêu âm, X-quang)"]
        D_CONFIRM_ORDER["Nhấn 'Xác nhận chỉ định & Chuyển phòng CLS'"]

        D_CANCEL_EXAM["[T11] Thao tác 'Hủy ca / Chuyển viện cấp cứu'\n(nhập lý do, không thu phí;\nchỉ khi chưa có dịch vụ tại phòng hoàn thành)"]
    end

    subgraph LANE_CLIENT["CHỦ THÚ CƯNG"]
        C_IN_ROOM["Cung cấp biểu hiện bất thường của thú cưng"]
        C_AGREE_ORDER["Đồng ý thực hiện chỉ định & đưa thú cưng ra khu CLS"]
        C_REFUSE["Từ chối khám tiếp / Xin chuyển viện"]
    end

    subgraph LANE_SYSTEM["HỆ THỐNG PHẦN MỀM"]
        S_START_VISIT["pet_visits: IN_PROGRESS (T02), Bác sĩ: BUSY\nTạo dịch vụ khám (IN_PROGRESS)\n+ service_invoices (PENDING, snapshot giá & VAT)"]
        S_INROOM_ORDER["Tạo visit_service_details (PENDING)\n+ service_invoices (PENDING) cho dịch vụ tại phòng"]
        S_INROOM_DONE["Dịch vụ tại phòng: COMPLETED"]
        S_STOCK_WARN["Lưu prescriptions + prescription_items\n(không giá, không trạng thái)\n[EX-13] Chỉ cảnh báo nếu tồn kho không đủ"]
        S_CHECK_DIAG{"Đã nhập chẩn đoán,\ncân nặng, thân nhiệt?"}
        S_DIAG_ERR["[EX-12] Yêu cầu nhập đủ thông tin\ntrước khi chốt ca"]
        S_CLS_ORDER["Tạo visit_service_details (PENDING)\n+ service_invoices (PENDING) cho từng dịch vụ CLS"]
        S_RELEASE_DOC["Dịch vụ khám: COMPLETED\npet_visits: WAITING_RESULTS (T04)\nBác sĩ về AVAILABLE, gọi số tiếp theo\nDịch vụ CLS tự vào hàng đợi Lab / CĐHA"]
        S_TO_PAYMENT["Dịch vụ khám: COMPLETED\nKhóa hồ sơ chuyên môn\npet_visits: WAITING_PAYMENT (T05)\nGiải phóng Bác sĩ"]
        S_CANCEL_VISIT["Mọi dịch vụ của ca → CANCELLED\nHóa đơn dịch vụ tương ứng → CANCELLED\npet_visits: CANCELLED, giải phóng Bác sĩ"]
    end

    D_CLICK_START --> S_START_VISIT --> D_EXAM
    D_EXAM <--> C_IN_ROOM
    D_EXAM --> D_INPUT_NOTES --> D_BRANCH

    D_BRANCH -- "[Khám nhẹ / Tiêm phòng / Thủ thuật]" --> D_ROUTINE_DIAG --> D_ORDER_INROOM
    D_ORDER_INROOM -- "[Có dịch vụ tại phòng]" --> S_INROOM_ORDER --> D_DO_INROOM --> S_INROOM_DONE --> D_PRESCRIBE_1
    D_ORDER_INROOM -- "[Chỉ khám]" --> D_PRESCRIBE_1
    D_PRESCRIBE_1 -- "[Có kê đơn]" --> S_STOCK_WARN --> D_FINISH_G1
    D_PRESCRIBE_1 -- "[Không kê đơn]" --> D_FINISH_G1
    D_FINISH_G1 --> S_CHECK_DIAG
    S_CHECK_DIAG -- "[Thiếu]" --> S_DIAG_ERR --> D_INPUT_NOTES
    S_CHECK_DIAG -- "[Đủ]" --> S_TO_PAYMENT

    D_BRANCH -- "[Nghi ngờ bệnh lý, cần CLS]" --> D_SELECT_SVC --> C_AGREE_ORDER
    C_AGREE_ORDER --> D_CONFIRM_ORDER --> S_CLS_ORDER --> S_RELEASE_DOC

    C_IN_ROOM -- "[Khách từ chối]" --> C_REFUSE --> D_CANCEL_EXAM --> S_CANCEL_VISIT
```

> **Ghi chú:** Nếu khách từ chối nhưng phòng khám vẫn thu phí khám (Bác sĩ đã khám xong), **hoặc đã thực hiện dịch vụ tại phòng** (hóa đơn của dịch vụ đó phải được thu), Bác sĩ dùng luồng chốt ca bình thường (T05) với chẩn đoán "chuyển viện" thay vì hủy ca. Guard cân nặng / thân nhiệt cũng áp dụng cho nút "Xác nhận chỉ định CLS" (T04).

---

## 5. AD-04: THỰC HIỆN CẬN LÂM SÀNG SONG SONG & XỬ LÝ NGOẠI LỆ HÀNG ĐỢI

### 5.1. Ý nghĩa & Bối cảnh nghiệp vụ
Mô tả tiến trình thực hiện song song tại 2 phòng độc lập: **Phòng Xét nghiệm (Lab)** và **Phòng Chẩn đoán hình ảnh (CĐHA)** (UC-25 & UC-26). Nhánh của phòng nào chỉ chạy khi ca có dịch vụ thuộc phòng đó. Dịch vụ **tự vào hàng đợi** phòng tương ứng ngay khi Bác sĩ chỉ định. Sơ đồ đặc tả Fork / Join, cơ chế "Gọi" theo từng dòng (các dịch vụ cùng đợt khám, cùng phòng gộp thành một ca) và các ngoại lệ: Khách vắng mặt khi gọi số → gọi ca khác, ca vắng giữ nguyên vị trí (EX-06; khách quay lại thì "Gọi lại" – EX-07), Khách xin hủy 1 dịch vụ (EX-08), CĐHA gọi số đúng lúc thú cưng đang lấy máu (EX-09).

**Dữ liệu cho huy hiệu EX-09:** sau khi lấy mẫu, KTV Lab bấm *"Đã lấy mẫu"*; hệ thống ghi `action = SAMPLE_COLLECTED` vào `visit_service_detail_histories`. Huy hiệu *"Đang lấy máu bên phòng Lab"* chỉ hiện khi dịch vụ Lab của ca đang `IN_PROGRESS` **và** `action` mới nhất là `START_PROCESSING` (chưa lấy mẫu xong). Khi máy đang chạy (`SAMPLE_COLLECTED`), thú cưng đã tự do nên CĐHA gọi bình thường.

### 5.2. Sơ đồ Hoạt động Phân làn

```mermaid
flowchart TD
    FORK_START((Bác sĩ gửi chỉ định)) --> SYS_FORK[["FORK: Phân luồng theo phòng có dịch vụ"]]

    subgraph LANE_LAB["PHÒNG XÉT NGHIỆM (Lab Room)"]
        L_QUEUE["Hàng đợi Xét nghiệm (PENDING)\ncấp cứu trước, rồi queue_order\n(dịch vụ cùng đợt khám gộp một ca)"]
        L_CALL["KTV bấm 'Gọi' ở một ca\n(hoặc 'Gọi số tiếp theo' gọi ca đứng đầu)"]
        L_DECIDE_PRESENT{"Khách có mặt\nsau 2-3 lần gọi?"}
        L_POSTPONE["[EX-06] Bấm 'Gọi' ca khác\n(ca vắng giữ nguyên vị trí, không ghi lịch sử;\nmỗi lần gọi ghi last_called_at)"]
        L_START["Bấm 'Bắt đầu làm' (IN_PROGRESS, START_PROCESSING)\nLấy mẫu máu"]
        L_SAMPLED["Bấm 'Đã lấy mẫu' (SAMPLE_COLLECTED)\nThú cưng rời phòng Lab"]
        L_MACHINE["Máy huyết học / sinh hóa phân tích tự động"]
        L_INPUT_DATA["Nhập giá trị từng chỉ số thuộc gói\n(service_lab_test_items)"]
        L_CANCEL_ONE["[EX-08] Khách xin hủy xét nghiệm"]
    end

    subgraph LANE_IMAGING["PHÒNG CHẨN ĐOÁN HÌNH ẢNH (Imaging Room)"]
        I_QUEUE["Hàng đợi CĐHA (PENDING)\ncấp cứu trước, rồi queue_order\n(dịch vụ cùng đợt khám gộp một ca)"]
        I_CALL["KTV / Bác sĩ CĐHA bấm 'Gọi' ở một ca\n(hoặc 'Gọi số tiếp theo')"]
        I_AT_LAB{"Thú cưng đang\nlấy mẫu ở phòng Lab?"}
        I_DECIDE_PRESENT{"Khách có mặt\nsau 2-3 lần gọi?"}
        I_POSTPONE["[EX-06 / EX-09] Bấm 'Gọi' ca khác\n(ca vắng giữ nguyên vị trí, không ghi lịch sử)"]
        I_CAPTURE["Bấm 'Bắt đầu làm' (IN_PROGRESS)\nSiêu âm bụng / Chụp X-quang"]
        I_UPLOAD["Tải tệp ảnh lên hệ thống & nhập mô tả, kết luận"]
        I_CANCEL_ONE["[EX-08] Khách xin hủy siêu âm / X-quang"]
    end

    subgraph LANE_SYSTEM["HỆ THỐNG PHẦN MỀM"]
        S_BADGE["Hiện huy hiệu '[Đang lấy máu bên phòng Lab]'\n(Lab IN_PROGRESS và action mới nhất = START_PROCESSING)"]
        S_SAVE_LAB["Lưu lab_test_results\n(snapshot min/max theo loài từ lab_test_reference_ranges)\nvisit_service_details: COMPLETED\nMàu LOW / NORMAL / HIGH tính khi hiển thị, không lưu"]
        S_SAVE_IMG["Lưu imaging_results & imaging_attachments\nvisit_service_details: COMPLETED"]
        S_CANCEL_SVC["[EX-08] visit_service_details: CANCELLED\n+ service_invoices tương ứng: CANCELLED\n(cùng một giao dịch)"]
        SYS_JOIN[["JOIN: Kiểm tra tất cả dịch vụ CLS của ca"]]
        S_EVAL_ALL{"Còn dịch vụ CLS nào\nở PENDING hoặc IN_PROGRESS?"}
        S_TRIGGER_READY["pet_visits: RESULTS_READY (T06)\nCa lên đầu hàng đợi của Bác sĩ khám chính\nHiện thông báo trên màn hình Bác sĩ"]
    end

    SYS_FORK -- "[Có dịch vụ LABORATORY]" --> L_QUEUE --> L_CALL --> L_DECIDE_PRESENT
    L_DECIDE_PRESENT -- "[Vắng mặt]" --> L_POSTPONE --> L_CALL
    L_DECIDE_PRESENT -- "[Có mặt]" --> L_START
    L_START --> L_SAMPLED --> L_MACHINE --> L_INPUT_DATA --> S_SAVE_LAB --> SYS_JOIN
    L_QUEUE -- "[Khách xin hủy]" --> L_CANCEL_ONE --> S_CANCEL_SVC --> SYS_JOIN

    SYS_FORK -- "[Có dịch vụ IMAGING]" --> I_QUEUE --> I_CALL --> I_AT_LAB
    I_AT_LAB -- "[Có]" --> S_BADGE --> I_POSTPONE
    I_AT_LAB -- "[Không]" --> I_DECIDE_PRESENT
    I_DECIDE_PRESENT -- "[Vắng mặt]" --> I_POSTPONE
    I_POSTPONE --> I_CALL
    I_DECIDE_PRESENT -- "[Có mặt]" --> I_CAPTURE
    I_CAPTURE --> I_UPLOAD --> S_SAVE_IMG --> SYS_JOIN
    I_QUEUE -- "[Khách xin hủy]" --> I_CANCEL_ONE --> S_CANCEL_SVC

    SYS_JOIN --> S_EVAL_ALL
    S_EVAL_ALL -- "[Vẫn còn dịch vụ chưa xong]" --> S_WAIT((Tiếp tục chờ phòng còn lại))
    S_EVAL_ALL -- "[Tất cả đã xong hoặc hủy]" --> S_TRIGGER_READY --> READY_END(((Chuyển sang GĐ 2)))
```

> **Khách bỏ về giữa chừng:** nếu khách rời phòng khám khi CLS chưa xong, Lễ tân thực hiện *"Đóng ca / Khách bỏ về"* (T12, EX-11): dịch vụ CLS còn `PENDING` bị hủy (kèm hóa đơn), hóa đơn của dịch vụ đã làm giữ `PENDING` làm công nợ, đợt khám chuyển `COMPLETED`. Thao tác chỉ được phép khi không có dịch vụ nào đang `IN_PROGRESS`.

---

## 6. AD-05: HỘI CHẨN KẾT QUẢ, CHẨN ĐOÁN XÁC ĐỊNH & KÊ ĐƠN GIAI ĐOẠN 2

### 6.1. Ý nghĩa & Bối cảnh nghiệp vụ
Mô tả quy trình Bác sĩ đón lại bệnh nhân sau khi có kết quả cận lâm sàng (UC-30, UC-31, UC-33). Ca có kết quả đã tự lên đầu hàng đợi của Bác sĩ (T06). Bác sĩ hội chẩn, chẩn đoán xác định, có thể thực hiện thêm dịch vụ tại phòng, kê đơn thuốc điện tử và khóa bệnh án.

Hai điểm cần lưu ý:
- **Gọi số trước, đổi trạng thái sau (EX-10):** "Gọi" (hoặc "Gọi số tiếp theo") chỉ phát thông báo, ca vẫn `RESULTS_READY` và thứ tự không đổi; thú cưng vào phòng thì Bác sĩ mới bấm "Bắt đầu Giai đoạn 2" (T07). Gọi 2–3 lần không vào thì Bác sĩ bấm "Gọi" ca khác: ca vắng giữ nguyên vị trí (vẫn đứng đầu hàng đợi), khách quay lại thì "Gọi lại".
- **Kê đơn không bị chặn bởi tồn kho (EX-13):** vì khách được mua thuốc ngoài, hệ thống chỉ cảnh báo khi số lượng kê vượt tồn kho; Bác sĩ quyết định giữ nguyên hay đổi thuốc.

### 6.2. Sơ đồ Hoạt động Phân làn

```mermaid
flowchart TD
    subgraph LANE_DOCTOR["BÁC SĨ KHÁM CHÍNH (Veterinarian)"]
        D_FINISH_PREV["Bác sĩ rời ca trước (chỉ định CLS / chốt ca)"]
        D_SEE_POPUP["Bấm 'Gọi' ở ca có KQ\n(đứng đầu hàng đợi)"]
        D_DECIDE_PATIENT{"Khách có vào phòng\nsau 2-3 lần thông báo?"}

        D_HOLD_G2["[EX-10] Bấm 'Gọi' ca khác"]
        D_START_G2["Bấm 'Bắt đầu Giai đoạn 2'"]

        D_ANALYZE["Phân tích kết quả tổng hợp:\n- Đối chiếu chỉ số bất thường (đỏ / vàng)\n- Đọc ảnh X-quang, siêu âm\n- Kết hợp triệu chứng lâm sàng ở GĐ 1"]
        D_INPUT_DIAG["Nhập chẩn đoán xác định & phác đồ điều trị"]
        D_INROOM_G2["Chỉ định & thực hiện dịch vụ tại phòng nếu cần\n(tiêm thuốc, truyền dịch, thủ thuật)"]
        D_SELECT_MED["Chọn thuốc từ danh mục:\nnhập số lượng, liều dùng, số ngày"]
        D_STOCK_CHOICE{"Giữ nguyên thuốc\nđã kê?"}
        D_ADJUST_MED["Đổi thuốc thay thế / giảm số lượng"]
        D_SAVE_RX["Bấm 'Lưu đơn thuốc điện tử'"]
        D_EXPLAIN["Giải thích bệnh & hướng dẫn dùng thuốc cho chủ nuôi\n(thông báo có thể mua tại phòng khám hoặc mua ngoài)"]
        D_CLOSE_VISIT["Bấm 'Chốt đợt khám / Chuyển thanh toán'"]
    end

    subgraph LANE_RECEPTION["LỄ TÂN"]
        R_CONFIRM_LEFT["Liên hệ khách, xác nhận bỏ về\nhoặc hết ngày làm việc"]
        R_ABANDON["[EX-11] Thao tác 'Đóng ca / Khách bỏ về'"]
    end

    subgraph LANE_SYSTEM["HỆ THỐNG PHẦN MỀM"]
        S_CALL_SPEAKER["PatientCalledEvent: 'Mời thú cưng [Tên] vào lại phòng [Số]'\n(ca vẫn RESULTS_READY)"]
        S_START_G2["pet_visits: IN_PROGRESS GĐ 2 (T07)\nBác sĩ: BUSY, mở bệnh án tổng hợp"]
        S_RELEASE_EX10["Ca giữ RESULTS_READY và giữ nguyên vị trí\n(không đổi queue_order); Bác sĩ gọi ca khác"]
        S_CHECK_BACK{"Khách quay lại?"}
        S_CLOSE_DEBT["pet_visits: COMPLETED (T08, khóa)\nKhông tạo hóa đơn mới: hóa đơn dịch vụ đã làm\ngiữ PENDING làm công nợ\nKết quả CLS lưu vĩnh viễn vào bệnh án"]
        S_CHECK_STOCK{"Số lượng kê <=\nmedicines.stock_quantity?"}
        S_STOCK_WARN["[EX-13] Cảnh báo: 'Kho hiện không đủ,\nkhách có thể phải mua ngoài'"]
        S_SAVE_RX["Tạo prescriptions + prescription_items\n(không giá, không trạng thái)"]
        S_CHECK_DIAG{"Đã nhập chẩn đoán và\nhoàn tất dịch vụ tại phòng?"}
        S_DIAG_ERR["[EX-12] Yêu cầu nhập chẩn đoán /\nhoàn tất hoặc hủy dịch vụ tại phòng"]
        S_FINAL_LOCK["1. Khóa toàn bộ hồ sơ bệnh án chuyên môn\n2. pet_visits: WAITING_PAYMENT (T09)\n   (ghi pet_visit_status_histories)\n3. Bác sĩ về AVAILABLE, gọi số tiếp theo\n4. Đẩy sang màn hình Thu ngân"]
    end

    D_FINISH_PREV --> D_SEE_POPUP --> S_CALL_SPEAKER --> D_DECIDE_PATIENT

    D_DECIDE_PATIENT -- "[Khách vắng mặt]" --> D_HOLD_G2 --> S_RELEASE_EX10 --> S_CHECK_BACK
    S_CHECK_BACK -- "[Có, Bác sĩ gọi lại]" --> D_SEE_POPUP
    S_CHECK_BACK -- "[Không quay lại]" --> R_CONFIRM_LEFT --> R_ABANDON --> S_CLOSE_DEBT --> END_DEBT(((Đóng ca, ghi công nợ)))

    D_DECIDE_PATIENT -- "[Khách có mặt]" --> D_START_G2 --> S_START_G2 --> D_ANALYZE --> D_INPUT_DIAG --> D_INROOM_G2 --> D_SELECT_MED --> S_CHECK_STOCK

    S_CHECK_STOCK -- "[Không đủ]" --> S_STOCK_WARN --> D_STOCK_CHOICE
    D_STOCK_CHOICE -- "[Đổi thuốc]" --> D_ADJUST_MED --> D_SELECT_MED
    D_STOCK_CHOICE -- "[Giữ nguyên, khách mua ngoài]" --> D_SAVE_RX
    S_CHECK_STOCK -- "[Đủ]" --> D_SAVE_RX
    D_SAVE_RX --> S_SAVE_RX --> D_EXPLAIN --> D_CLOSE_VISIT --> S_CHECK_DIAG
    S_CHECK_DIAG -- "[Chưa]" --> S_DIAG_ERR --> D_INPUT_DIAG
    S_CHECK_DIAG -- "[Đủ]" --> S_FINAL_LOCK --> END_PAY(((Chuyển sang Thu ngân)))
```

> Không kê đơn thuốc cũng là trường hợp hợp lệ: Bác sĩ bỏ qua bước chọn thuốc và chốt ca trực tiếp.

---

## 7. AD-06: THU TIỀN HÓA ĐƠN DỊCH VỤ & BÁN THUỐC THEO ĐƠN (TÙY CHỌN)

### 7.1. Ý nghĩa & Bối cảnh nghiệp vụ
Mô tả quy trình tài chính và bán thuốc tại quầy (UC-34, UC-35, UC-36). Quy trình chia làm **2 phần độc lập**:

| Phần | Thực thể | Service | Kết quả |
| :--- | :--- | :--- | :--- |
| **A. Thu tiền hóa đơn dịch vụ** (bắt buộc) | `service_invoices` | `clinical-service` | Hóa đơn cuối cùng `PAID` thì đợt khám `COMPLETED` **trong cùng giao dịch cục bộ** (T10). |
| **B. Bán thuốc theo đơn** (tùy chọn) | `medicine_invoices`, `medicine_invoice_items`, `inventory_transactions` | `billing-pharmacy-service` | Chuyển `PAID` và trừ kho trong **cùng một giao dịch**; không ảnh hưởng trạng thái đợt khám. |

Phần B chỉ diễn ra khi Bác sĩ có kê đơn **và** khách chọn mua tại phòng khám. Khách có thể mua một phần đơn. Số tiền của mỗi hóa đơn không lưu thành cột mà tính từ VIEW `v_service_invoice_amounts` / `v_medicine_invoice_amounts`.

### 7.2. Sơ đồ Hoạt động Phân làn

```mermaid
flowchart TD
    subgraph LANE_CLIENT["CHỦ THÚ CƯNG (Pet Owner)"]
        C_TO_CASHIER["Đến quầy thu ngân sau khi Bác sĩ chốt ca"]
        C_CHECK_BILL["Kiểm tra bảng kê các hóa đơn dịch vụ"]
        C_MAKE_PAYMENT["Thanh toán bên ngoài quầy\n(tiền mặt hoặc chuyển khoản)"]
        C_DECIDE_BUY{"Mua thuốc tại\nphòng khám?"}
        C_CHOOSE_ITEMS["Chọn thuốc & số lượng muốn mua\n(được mua một phần đơn)"]
        C_PAY_MED["Thanh toán tiền thuốc"]
        C_RECEIVE["Nhận thuốc, phiếu hướng dẫn & ra về"]
        C_OUTSIDE["Nhận đơn thuốc in, ra về mua ngoài"]
    end

    subgraph LANE_RECEPTION["LỄ TÂN / THU NGÂN (Receptionist / Cashier)"]
        R_OPEN_BILL["Mở màn hình chờ thanh toán, chọn ca khám"]
        R_APPLY_DISCOUNT{"Khách có ưu đãi\ncho dịch vụ nào?"}
        R_INPUT_DISCOUNT["Nhập discount_amount cho từng hóa đơn dịch vụ"]
        R_VERIFY_PAY["Kiểm tra đã nhận đủ tiền"]
        R_CONFIRM_PAY["Bấm 'Xác nhận thanh toán' các hóa đơn dịch vụ (UC-35)"]
        R_HAS_RX{"Ca có đơn thuốc?"}
        R_CREATE_MINV["Bấm 'Bán thuốc theo đơn', nhập thuốc & số lượng"]
        R_MED_DISCOUNT["Nhập giảm giá hóa đơn thuốc (nếu có)"]
        R_FETCH_MED["Mở tủ thuốc, lấy đúng loại & số lượng,\nkiểm tra hạn dùng, dán nhãn liều dùng"]
        R_CONFIRM_SALE["Bấm 'Xác nhận thanh toán & xuất thuốc' (UC-36)"]
        R_CANCEL_MINV["Hủy hóa đơn thuốc (khách mua ngoài,\nhủy là kết thúc)"]
        R_EDIT_MINV["Sửa hóa đơn thuốc đang PENDING:\ngiảm số lượng / bỏ thuốc thiếu"]
    end

    subgraph LANE_SYSTEM["HỆ THỐNG PHẦN MỀM"]
        S_LIST_INV["Liệt kê service_invoices PENDING của ca\nkèm số tiền từ v_service_invoice_amounts"]
        S_CHECK_DISCOUNT{"discount_amount <=\nquantity × unit_price × (1 + vat_rate)?"}
        S_DISCOUNT_ERR["[EX-14] CẢNH BÁO: 'Tiền giảm giá không được\nvượt quá số tiền của hóa đơn'"]
        S_PAID_SVC["@Transactional (clinical-service):\n1. service_invoices: PAID, paid_at, cashier_id\n2. Mọi hóa đơn dịch vụ đã PAID / CANCELLED\n   → pet_visits: COMPLETED (T10) + ghi lịch sử\n3. COMMIT"]
        S_PRINT_SVC["In phiếu thu dịch vụ"]
        S_NEW_MINV["Kiểm tra prescription_id chưa có hóa đơn thuốc (EX-16)\nTạo medicine_invoices (PENDING)\n+ medicine_invoice_items (quantity <= số lượng kê,\nsnapshot unit_price, vat_rate)"]
        S_CHECK_MED_DISCOUNT{"discount_amount <=\ntổng tiền thuốc?"}
        S_TRANSACTION_START["Bắt đầu giao dịch @Transactional\n(billing-pharmacy-service)"]
        S_CHECK_REAL_STOCK{"Mọi câu UPDATE ... WHERE\nstock_quantity >= qty đều thành công?"}
        S_ROLLBACK["[EX-15] ROLLBACK GIAO DỊCH!\nKhông trừ kho, hóa đơn thuốc giữ PENDING\nCảnh báo: 'Thuốc [Tên] vừa không đủ tồn kho'"]
        S_COMMIT["1. Trừ medicines.stock_quantity\n2. Ghi inventory_transactions (EXPORT_SALE, quantity âm)\n3. medicine_invoices: PAID, paid_at, cashier_id\n4. COMMIT"]
        S_PRINT_MED["In hóa đơn thuốc & phiếu hướng dẫn dùng thuốc"]
        S_MINV_CANCELLED["medicine_invoices: CANCELLED\nTồn kho không biến động"]
    end

    C_TO_CASHIER --> R_OPEN_BILL --> S_LIST_INV --> R_APPLY_DISCOUNT

    R_APPLY_DISCOUNT -- "[Có]" --> R_INPUT_DISCOUNT --> S_CHECK_DISCOUNT
    S_CHECK_DISCOUNT -- "[Không hợp lệ]" --> S_DISCOUNT_ERR --> R_INPUT_DISCOUNT
    S_CHECK_DISCOUNT -- "[Hợp lệ]" --> C_CHECK_BILL
    R_APPLY_DISCOUNT -- "[Không]" --> C_CHECK_BILL

    C_CHECK_BILL --> C_MAKE_PAYMENT --> R_VERIFY_PAY --> R_CONFIRM_PAY --> S_PAID_SVC --> S_PRINT_SVC --> R_HAS_RX

    R_HAS_RX -- "[Không kê đơn]" --> END_NO_RX(((Hoàn tất ca khám)))
    R_HAS_RX -- "[Có]" --> C_DECIDE_BUY
    C_DECIDE_BUY -- "[Mua ngoài]" --> C_OUTSIDE --> END_OUTSIDE(((Hoàn tất ca khám)))
    C_DECIDE_BUY -- "[Mua tại phòng khám]" --> C_CHOOSE_ITEMS --> R_CREATE_MINV --> S_NEW_MINV --> R_MED_DISCOUNT --> S_CHECK_MED_DISCOUNT
    S_CHECK_MED_DISCOUNT -- "[Không hợp lệ (EX-14)]" --> R_MED_DISCOUNT
    S_CHECK_MED_DISCOUNT -- "[Hợp lệ]" --> R_FETCH_MED --> C_PAY_MED --> R_CONFIRM_SALE --> S_TRANSACTION_START --> S_CHECK_REAL_STOCK

    S_CHECK_REAL_STOCK -- "[Thiếu kho (Race Condition)]" --> S_ROLLBACK
    S_ROLLBACK -- "[Khách giảm số lượng / bỏ thuốc thiếu]" --> R_EDIT_MINV --> S_CHECK_MED_DISCOUNT
    S_ROLLBACK -- "[Khách chuyển sang mua ngoài]" --> R_CANCEL_MINV --> S_MINV_CANCELLED --> C_OUTSIDE
    S_CHECK_REAL_STOCK -- "[Đủ kho]" --> S_COMMIT --> S_PRINT_MED --> C_RECEIVE --> CLIENT_END(((Hoàn tất mua thuốc)))
```

> **Sửa hóa đơn thuốc thay vì lập lại:** mỗi đơn thuốc chỉ có một hóa đơn thuốc (`prescription_id UNIQUE`), nên sau EX-15 Thu ngân sửa chính hóa đơn đang `PENDING` (`PUT /api/v1/billing/medicine-invoices/{id}/items`), các dòng còn lại giữ nguyên snapshot giá. Hóa đơn đã hủy không lập lại được: khách mua ngoài theo đơn in.

> **Vì sao EX-15 không còn gây rắc rối hoàn tiền:** tiền thuốc và tiền dịch vụ nằm ở hai hóa đơn tách biệt. Khi giao dịch bán thuốc rollback, chưa có hóa đơn thuốc nào ở trạng thái `PAID`, nên hệ thống không ghi nhận khoản thu nào cần hoàn; Thu ngân chỉ trả lại khách số tiền thuốc vừa nhận (hoặc thu theo số lượng mới). Đợt khám đã `COMPLETED` từ Phần A và không bị ảnh hưởng.

> **Thu công nợ (EX-11):** với đợt khám đã `COMPLETED` do khách bỏ về, ở lần đến sau Thu ngân mở lại danh sách hóa đơn dịch vụ còn `PENDING` của ca cũ và thu theo Phần A; trạng thái đợt khám giữ nguyên `COMPLETED`.

---

## 8. MA TRẬN TRUY VẾT NGHIỆP VỤ TỔNG HỢP (TRACEABILITY MATRIX)

Ma trận dưới đây thể hiện sự liên kết giữa các Sơ đồ Hoạt động với Ca sử dụng (Use Cases), Sơ đồ Trạng thái (State Machines v3.0) và Danh mục Ngoại lệ:

| Mã Activity Diagram | Tên Quy trình nghiệp vụ | Use Case liên quan | State Machine & Thực thể CSDL | Mã Ngoại lệ xử lý |
| :---: | :--- | :---: | :---: | :---: |
| **AD-01** | Chu trình Khám Ngoại trú Hai pha Tổng thể | UC-19, 22, 23, 25, 26, 30, 31, 34, 35, 36 | `pet_visits` (SM-01)<br>`doctor_serving_status` (SM-02)<br>`service_invoices` (SM-05)<br>`medicine_invoices` (SM-06) | EX-03, EX-06, EX-08, EX-10, EX-15 |
| **AD-02** | Tiếp đón, Xếp hàng đợi riêng từng Bác sĩ & Gọi số | UC-14, 16, 17, 18, 19, 20, 21 | `appointments` (SM-04)<br>`pet_visits` (T01)<br>`doctor_serving_status` (SM-02) | EX-01, EX-02, EX-03, EX-04, EX-05, EX-10 |
| **AD-03** | Khám Lâm sàng Sơ bộ & Chỉ định Dịch vụ Giai đoạn 1 | UC-22, UC-23 | `pet_visits` (T02, T04, T05, T11)<br>`visit_service_details` (SM-03)<br>`service_invoices` (SM-05)<br>`prescriptions` | EX-12, EX-13 |
| **AD-04** | Thực hiện Cận lâm sàng Song song & Hàng đợi | UC-25, UC-26 | `visit_service_details` (SM-03)<br>`service_invoices` (SM-05)<br>`pet_visits` (T06, T12) | EX-06, EX-07, EX-08, EX-09, EX-11 |
| **AD-05** | Hội chẩn Kết quả, Chẩn đoán & Kê đơn Giai đoạn 2 | UC-30, UC-31, UC-33 | `pet_visits` (T07, T08, T09)<br>`doctor_serving_status` (SM-02)<br>`prescriptions` | EX-10, EX-11, EX-12, EX-13 |
| **AD-06** | Thu tiền Hóa đơn Dịch vụ & Bán thuốc theo Đơn | UC-34, UC-35, UC-36 | `service_invoices` (SM-05)<br>`pet_visits` (T10)<br>`medicine_invoices` (SM-06)<br>`inventory_transactions` | EX-11, EX-14, EX-15, EX-16 |

---

## PHỤ LỤC: THAY ĐỔI SO VỚI PHIÊN BẢN 2.0

| Vị trí | Bản 2.0 | Bản 3.0 | Lý do |
| :--- | :--- | :--- | :--- |
| AD-01 phần cuối | Thu viện phí → `PAID` mở khóa xuất thuốc → trừ kho → `COMPLETED` | Thu hóa đơn dịch vụ → `COMPLETED`; mua thuốc là nhánh tùy chọn, thu tiền thuốc và trừ kho là cùng một bước | Mỗi dịch vụ có hóa đơn riêng; khách được mua thuốc ngoài |
| AD-01, AD-03 | Không có dịch vụ tại phòng | Thêm nhánh dịch vụ thực hiện tại phòng (tiêm, tẩy giun, thủ thuật) | Bản cũ chỉ có Lab / CĐHA |
| AD-02 | Phân công xong vẫn tính Bác sĩ `AVAILABLE` | Gán `doctor_id` → Bác sĩ `BUSY` ngay; thêm kiểm tra thú cưng đang có đợt khám mở | Chống phân công trùng |
| AD-03 | `started_at = NOW()`; snapshot `unit_price` vào `visit_service_details` | Ghi lịch sử; tạo `visit_service_details` + `service_invoices` (`PENDING`) | Cột đã bỏ; giá chuyển sang hóa đơn dịch vụ |
| AD-03 | Hủy ca gắn nhãn EX-03 | Gắn T11 (hủy không thu phí) | EX-03 là khách bỏ về ở sảnh |
| AD-04 | Huy hiệu EX-09 không có dữ liệu phân biệt | Thêm thao tác "Đã lấy mẫu" (`action = SAMPLE_COLLECTED`) | Phân biệt "đang lấy máu" với "máy đang chạy" |
| AD-04 | Hủy dịch vụ: "hóa đơn tự loại trừ" | Hủy dịch vụ và hóa đơn của dịch vụ đó trong cùng giao dịch | Hóa đơn tách theo dịch vụ |
| AD-05 | `prescriptions (PRESCRIBED)`, snapshot giá vào `prescription_items`; `closed_at` | Đơn thuốc không giá, không trạng thái; ghi lịch sử | Bỏ `PrescriptionStatus` và cột giá trùng |
| AD-05 | Kê vượt tồn kho bị chặn | Chỉ cảnh báo (EX-13), Bác sĩ được giữ nguyên | Khách có thể mua ngoài |
| AD-05 | Tạm hoãn khi chưa gọi; "Đóng ca" tạo hóa đơn nợ | Gọi trước rồi mới hoãn (T13); "Đóng ca" giữ hóa đơn dịch vụ sẵn có làm công nợ (T08) | Khớp công thức trạng thái Bác sĩ; hóa đơn đã sinh lúc chỉ định |
| AD-06 | `invoices`, `completed_at`, `EXPORT_PRESCRIPTION`, `prescriptions: DISPENSED` | `service_invoices`, `medicine_invoices`, `EXPORT_SALE`; lịch sử trạng thái | Đồng bộ lược đồ v3.0 |
| AD-06 EX-15 | Rollback sau khi đã thu viện phí, "báo Bác sĩ đổi thuốc" | Rollback chỉ ảnh hưởng hóa đơn thuốc; khách giảm số lượng hoặc mua ngoài | Đơn thuốc đã khóa; không còn vấn đề hoàn tiền |
| Ma trận truy vết | `invoices` (SM-05), `prescriptions` (SM-06) | `service_invoices` (SM-05), `medicine_invoices` (SM-06) | SM-06 đổi thành hóa đơn thuốc |
| AD-02 (rà soát 10/11) | "Nếu có hẹn: appointments → CHECKED_IN" trong cùng nút tạo đợt khám | Ghi rõ qua `VisitCheckedInEvent` | Khớp Kiến trúc mục 5.3 |
| AD-03 (rà soát 10/11) | Hủy ca T11 không có điều kiện về dịch vụ tại phòng | Chỉ khi chưa có dịch vụ tại phòng hoàn thành | Đồng bộ guard T11 |
| AD-06 (rà soát 10/11) | Sau EX-15 quay lại "Lập hóa đơn thuốc" (bị `prescription_id UNIQUE` chặn) | Nút "Sửa hóa đơn thuốc đang PENDING" | Luồng thực hiện được |
| AD-01, AD-02 (rà soát 11/11) | Xếp vào hàng đợi sảnh chung; "Phân công Bác sĩ đang AVAILABLE"; cảnh báo Khóa ưu tiên / Bác sĩ bận | Lễ tân xếp ca vào hàng đợi riêng của Bác sĩ (gợi ý Bác sĩ ít người chờ), không chặn khi Bác sĩ bận; thêm nhánh Bác sĩ "Gọi số tiếp theo" / "Đẩy lùi 1 bậc" | Lễ tân không phải chờ Bác sĩ rảnh |
| AD-04 (rà soát 11/11) | "Tạm hoãn" (POSTPONED) rồi "Có mặt" (RECALL, ghim ưu tiên kế tiếp) | "Gọi số tiếp theo"; vắng mặt → "Đẩy lùi 1 bậc" (SKIPPED), quay lại gọi người kế tiếp | Cùng cơ chế với hàng đợi Bác sĩ |
| AD-05 (rà soát 11/11) | Hộp thoại "Mời vào phòng" chuyển ngay `IN_PROGRESS`; tạm hoãn T13 về tab đã hoãn, Recall | "Gọi số tiếp theo" (ca có KQ đứng đầu), thú cưng vào phòng mới bấm "Bắt đầu GĐ 2" (T07); vắng → "Đẩy lùi 1 bậc"; bỏ T13 | Gọi số trước, đổi trạng thái sau |
| AD-02, AD-04, AD-05 (cập nhật 13/11) | "Đẩy lùi 1 bậc" (`skip_count + 1`, `action = SKIPPED`, xếp sau người kế tiếp); mỗi dịch vụ CLS một dòng hàng đợi | "Gọi" ở ca bất kỳ; ca vắng giữ nguyên vị trí, khách quay lại thì "Gọi lại"; dịch vụ cùng đợt khám, cùng phòng gộp một ca | Đẩy lùi 1 bậc làm hai ca đầu hàng đổi chỗ mãi mãi và làm ca cấp cứu mất ưu tiên; gọi theo từng dòng giống thực tế |
| AD-02, AD-04 (rà soát 13/11) | Gọi chỉ phát thông báo | Gọi ghi `last_called_at` để đánh dấu ca "Đã gọi HH:mm"; vẫn không đổi trạng thái / thứ tự | Lưu lại thú cưng đã từng được gọi |
