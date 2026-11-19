# TÀI LIỆU MÔ TẢ NGHIỆP VỤ HỆ THỐNG QUẢN LÝ PHÒNG KHÁM THÚ Y

> **Tài liệu nền tảng phục vụ xây dựng biểu đồ Use Case, Đặc tả Use Case và Thiết kế CSDL (ERD).**  
> **Phiên bản:** 4.0 (đồng bộ lược đồ CSDL v4.0; khớp State Machine, Activity, Use Case, Ngoại lệ và FR/NFR v4.0). Nền tảng v3.0: mỗi dịch vụ có hóa đơn riêng, mua thuốc tại phòng khám là tùy chọn. Danh sách thay đổi ở Phụ lục cuối tài liệu.  
> **Cập nhật 17/11/2026 (góp ý GVHD lần 2):** tách quy trình thanh toán khỏi quy trình khám; khách **nộp tiền trước rồi mới được phát phiếu vào hàng đợi** (phí khám, Xét nghiệm, CĐHA); dịch vụ làm tại phòng thu khi chốt ca.  
> **Cập nhật 18/11/2026 (v4.0 – nhận xét chi tiết của GVHD):** hồ sơ người dùng tách theo loại (nhân sự, Bác sĩ có chứng chỉ hành nghề, khách hàng); **giá dịch vụ và giá thuốc có lịch sử**; thông tin thuốc gồm thành phần, quy cách; đợt khám tách thành **thông tin tiếp đón – sinh hiệu – hồ sơ khám chuyên môn**; **hàng đợi chạy trên Redis** (MySQL chỉ lưu lịch sử phiếu); **đơn thuốc thuộc phân hệ khám**, chốt ca thì quầy thuốc tự có **hóa đơn thuốc nháp**; báo cáo lấy từ phân hệ báo cáo riêng. Chi tiết ở mục 44 và Phụ lục.

---

## 0. Các định hướng nghiệp vụ cốt lõi (Cập nhật mới)

- **Quy trình đặt lịch:** Chủ nuôi **chỉ đặt ngày + khung giờ + nhu cầu khám**, tuyệt đối **không chọn bác sĩ**.
- **Tiếp đón:** Khi khách đến phòng khám, lịch hẹn chuyển trạng thái thành `CHECKED_IN` và chuyển tiếp thành Đợt khám (`Pet Visit`).
- **Phân công ca khám:** **Mỗi bác sĩ có một hàng đợi riêng.** Lễ tân chọn bác sĩ ngay khi tiếp nhận, dựa trên số người đang chờ của từng bác sĩ (hệ thống gợi ý bác sĩ ít người chờ nhất), không phải chờ bác sĩ rảnh. Bác sĩ tự gọi bệnh nhân trong hàng đợi của mình (bấm "Gọi" ở ca bất kỳ hoặc "Gọi số tiếp theo"). Hệ thống giả định tất cả bác sĩ đều đi làm đầy đủ, không quản lý ca kíp và không quản lý nghỉ phép.
- **Thu tiền trước – xếp hàng sau (cập nhật 17/11/2026):** giống bệnh viện, quy trình thanh toán tách khỏi quy trình khám. Khách check-in xong **nộp phí khám lâm sàng** tại quầy thì mới được phát **phiếu số thứ tự** vào hàng đợi bác sĩ. Khi bác sĩ chỉ định, có 3 nhóm dịch vụ: **làm tại phòng** (tiêm vắc-xin, tẩy giun, tiêm thuốc, thủ thuật…) làm ngay, không cần thu trước (thu khi chốt ca); **Xét nghiệm** và **CĐHA** phải nộp tiền trước mới được phát phiếu vào hàng đợi 2 phòng này. Ca cấp cứu khám trước, thu sau. Phí khám đã nộp không hoàn.
- **Tách dữ liệu hay thay đổi khỏi dữ liệu ít thay đổi:** hồ sơ khám chỉ giữ thông tin ổn định; mọi thông tin xếp hàng (số phiếu, thứ tự, số lần gọi, ai đang được phục vụ) là **phiếu xếp hàng trên Redis**, thay đổi tức thời không khóa CSDL; phiếu kết thúc mới được ghi vào lịch sử (`queue_ticket_histories`).
- **Tách đợt khám theo người nhập (v4.0):** Lễ tân nhập thông tin tiếp đón (`pet_visits`); sinh hiệu đo bao nhiêu lần ghi bấy nhiêu dòng (`vital_signs`); Bác sĩ ghi bệnh sử, khám lâm sàng, chẩn đoán sơ bộ / xác định, phác đồ, lời dặn ở hồ sơ khám (`medical_records`).
- **Phòng khám:** Mỗi bác sĩ được gán một **số phòng khám cố định** (thuộc tính `room_number` trong **hồ sơ nhân sự** `staff_profiles`, không tạo bảng phòng khám riêng).
- **Vai trò chuyên môn:** Phân định rõ ràng giữa Bác sĩ khám lâm sàng chính (`VETERINARIAN`), Kỹ thuật viên/Bác sĩ xét nghiệm (`LAB_TECHNICIAN`), và Kỹ thuật viên/Bác sĩ chẩn đoán hình ảnh (`IMAGING_TECHNICIAN`), giúp chuẩn hóa chuyên môn và quản lý phòng ban hiệu quả.
- **Mô hình tài khoản CSDL (v4.0):** một bảng tài khoản đăng nhập dùng chung **`users`** (một tài khoản có thể nhiều vai trò qua `user_roles`, vai trò là bảng danh mục `roles`); thông tin cá nhân chung ở `user_profiles`; mỗi loại người dùng có **bảng hồ sơ riêng**: `staff_profiles` (mã nhân viên, CCCD, chức danh, bộ phận, phòng, ngày vào làm), `veterinarian_profiles` (số chứng chỉ hành nghề, nơi cấp, học vị, chuyên khoa, năm hành nghề), `pet_owner_profiles` (mã khách hàng, kênh đăng ký, kênh liên hệ).

---

## 1. Tổng quan hệ thống

Hệ thống quản lý phòng khám thú y được xây dựng nhằm hỗ trợ phòng khám quản lý tập trung toàn bộ hoạt động từ **tiếp nhận khách hàng và thú cưng, quản lý lịch hẹn, phân công bác sĩ, khám chữa bệnh, xét nghiệm, chẩn đoán hình ảnh, kê đơn thuốc, thanh toán theo hóa đơn từng dịch vụ, bán thuốc theo đơn (khi khách chọn mua tại phòng khám) cho đến lưu trữ lịch sử bệnh án**.

Hệ thống đồng thời hỗ trợ quản lý hoạt động vận hành của phòng khám như:

- Quản lý tài khoản và phân quyền.
- Quản lý bác sĩ (kèm số phòng khám cố định).
- Quản lý lễ tân.
- Quản lý hàng đợi khám.
- Quản lý lịch hẹn.
- Quản lý danh mục dịch vụ.
- Quản lý danh mục thuốc.
- Quản lý tồn kho.
- Quản lý cấu hình xét nghiệm.
- Quản lý khoảng tham chiếu xét nghiệm theo loài.
- Quản lý thanh toán theo hóa đơn dịch vụ (mỗi dịch vụ một hóa đơn) và hóa đơn thuốc.
- Thống kê doanh thu và hoạt động phòng khám.

Hệ thống được định hướng cho phòng khám thú y quy mô vừa và nhỏ, trong đó quy trình được tổ chức theo nguyên tắc:

> **Đặt lịch → Tiếp đón → Nộp phí khám, nhận phiếu vào hàng đợi riêng của bác sĩ → Bác sĩ gọi số → Khám → Chỉ định → Nộp tiền XN / CĐHA, nhận phiếu phòng → Kết quả → Chẩn đoán → Kê đơn → Thanh toán hóa đơn dịch vụ → Hoàn tất** *(→ Mua thuốc theo đơn tại phòng khám nếu khách chọn; khách có thể mua thuốc ở nơi khác).*

---

## 2. Mục tiêu của hệ thống

### 2.1. Quản lý tập trung thông tin khách hàng

Hệ thống lưu trữ thông tin chủ thú cưng:

- Họ tên.
- Số điện thoại.
- Email.
- Địa chỉ.
- Thông tin tài khoản nếu sử dụng Portal.

Một khách hàng có thể sở hữu nhiều thú cưng.

Ví dụ:

```text
Nguyễn Văn A
│
├── Miu
├── Bông
└── Lucky
```

---

### 2.2. Quản lý hồ sơ thú cưng

Mỗi thú cưng có một hồ sơ riêng.

Thông tin gồm:

- Mã thú cưng.
- Tên.
- Loài.
- Giống.
- Giới tính.
- Ngày sinh / Tuổi.
- Màu lông.
- Cân nặng hiện tại (không lưu trên hồ sơ thú cưng; lấy theo cân nặng Bác sĩ đo ở đợt khám gần nhất).
- Tình trạng triệt sản.
- Đặc điểm nhận dạng.
- Chủ sở hữu.
- Ghi chú.

Hồ sơ thú cưng là cơ sở để xây dựng **lịch sử bệnh án lâu dài**.

---

### 2.3. Quản lý toàn bộ vòng đời một lần khám

Mỗi lần thú cưng đến phòng khám được xem là một **Đợt khám – Pet Visit**.

Một Visit có thể phát sinh:

- Khám lâm sàng.
- Xét nghiệm.
- Chẩn đoán hình ảnh.
- Tiêm phòng.
- Tẩy giun.
- Điều trị.
- Phẫu thuật.
- Thủ thuật.
- Kê đơn thuốc.

Không bắt buộc một Visit phải sử dụng tất cả các nghiệp vụ trên.

---

## 3. Các nhóm người dùng & Phân quyền hệ thống

Hệ thống sử dụng mô hình quản lý người dùng và phân quyền tập trung dựa trên hai bảng:
- `users`: Lưu trữ thông tin tài khoản, thông tin cá nhân, trạng thái hoạt động và số phòng làm việc cố định (nếu là Bác sĩ hoặc Kỹ thuật viên).
- `roles`: Bảng danh mục vai trò cố định (`ADMIN`, `VETERINARIAN`, `RECEPTIONIST`, `LAB_TECHNICIAN`, `IMAGING_TECHNICIAN`, `PET_OWNER`).

Mỗi người dùng trong hệ thống được gán **duy nhất một vai trò (`Role`)**, tương ứng với 6 nhóm người dùng chính sau:

---

### 3.1. Nhóm Quản trị viên (ADMIN)

Quản trị viên chịu trách nhiệm quản lý toàn diện cấu hình và hoạt động vận hành của hệ thống phòng khám.

**Nhiệm vụ và quyền hạn:**
- **Quản lý tài khoản & nhân sự:** Tạo, kích hoạt, khóa, ngừng sử dụng tài khoản nhân viên (không xóa cứng); lập hồ sơ nhân sự (mã nhân viên, CCCD, chức danh, bộ phận, ngày vào làm, người liên hệ khẩn cấp), hồ sơ chuyên môn của Bác sĩ (chứng chỉ hành nghề, học vị, chuyên khoa); gán vai trò (một người có thể nhiều vai trò); phân công số phòng làm việc cố định.
- **Cấu hình danh mục chuyên môn:** Quản lý nhóm dịch vụ (`service_categories`: nhóm nào thu trước, vào hàng đợi nào), dịch vụ (`services`) và **bảng giá dịch vụ có lịch sử** (`service_prices`); danh mục thuốc (`medicines`, thành phần `medicine_ingredients`, quy cách) và **bảng giá thuốc có lịch sử** (`medicine_prices`); chỉ số xét nghiệm (`lab_test_items`) và khoảng tham chiếu theo loài (`lab_test_reference_ranges`).
- **Giám sát kho dược:** Quản lý nhập/xuất kho, theo dõi số lượng tồn kho khả dụng và nhận cảnh báo khi thuốc chạm ngưỡng tối thiểu (`min_stock_alert`).
- **Báo cáo & Thống kê:** Xem báo cáo doanh thu theo thời gian, theo nhóm dịch vụ, theo nhóm thuốc, hiệu suất từng Bác sĩ, thời gian chờ trung bình (phân hệ báo cáo `reporting-service`); theo dõi công nợ.

> **Lưu ý:** Quản trị viên **không trực tiếp tham gia quy trình khám chữa bệnh** hay can thiệp vào chuyên môn của đợt khám.

---

### 3.2. Nhóm Bác sĩ thú y (VETERINARIAN)

Bác sĩ thú y là nhân sự trực tiếp chịu trách nhiệm về chuyên môn y tế trong toàn bộ quá trình khám chữa bệnh cho thú cưng.

**Đặc điểm nghiệp vụ và phân quyền:**
- **Cùng vai trò nghiệp vụ:** Tất cả các bác sĩ trong hệ thống đều có chung vai trò `VETERINARIAN` và cùng tập quyền hạn chuyên môn, không phân chia bác sĩ trưởng hay bác sĩ thường, không chia chuyên khoa trong phạm vi đồ án.
- **Phòng khám cố định:** Mỗi Bác sĩ được cấu hình làm việc tại một **số phòng khám cố định** (thuộc tính `room_number` trong hồ sơ nhân sự `staff_profiles`, ví dụ: Bác sĩ A gắn với Phòng P01, Bác sĩ B gắn với Phòng P02). Khi Lễ tân phân công ca khám cho bác sĩ, bệnh nhân tự động được hướng dẫn vào đúng số phòng cố định này mà không cần bảng phòng khám riêng.
- **Phạm vi công việc:**
  - Khám lâm sàng sơ bộ (Giai đoạn 1): Tiếp nhận ca từ hàng đợi, đo sinh hiệu, thăm khám, tra cứu tiền sử bệnh án.
  - Ra chỉ định dịch vụ kỹ thuật: Chỉ định xét nghiệm máu, siêu âm, chụp X-quang (khách nộp tiền xong được phát phiếu vào hàng đợi chuyên biệt của phòng Xét nghiệm và phòng CĐHA).
  - Chẩn đoán xác định & Kê đơn thuốc (Giai đoạn 2): Tiếp nhận kết quả cận lâm sàng do phòng Xét nghiệm và phòng CĐHA hoàn tất gửi về, phân tích đối chiếu, đưa ra chẩn đoán xác định, lập phác đồ điều trị, kê đơn thuốc điện tử (hệ thống hiển thị tồn kho để tham khảo, chỉ cảnh báo nếu không đủ vì khách có thể mua ngoài) và dặn dò chủ nuôi.
  - Thực hiện dịch vụ tại phòng: tiêm vaccine, tẩy giun, tiêm thuốc, truyền dịch, thủ thuật.
  - Chốt đợt khám: Khóa hồ sơ chuyên môn và chuyển ca khám sang Thu ngân để thu các hóa đơn dịch vụ.

---

### 3.3. Nhóm Kỹ thuật viên / Bác sĩ Xét nghiệm (LAB_TECHNICIAN)

Kỹ thuật viên / Bác sĩ xét nghiệm phụ trách vận hành chuyên môn độc lập tại Phòng Xét nghiệm (Lab Room).

**Phạm vi công việc và quyền hạn:**
- **Theo dõi Hàng đợi xét nghiệm (Lab Queue):** Tiếp nhận danh sách các chỉ định xét nghiệm cận lâm sàng (`category = 'LABORATORY'`: Tổng phân tích tế bào máu CBC, sinh hóa máu, soi phân, test nhanh truyền nhiễm) được chỉ định từ các phòng khám.
- **Tiếp nhận mẫu bệnh phẩm & Thực hiện:** Lấy mẫu máu/bệnh phẩm từ thú cưng, vận hành máy phân tích tự động, cập nhật trạng thái dịch vụ sang `IN_PROGRESS`.
- **Nhập kết quả & Đối soát chỉ số:** Nhập giá trị đo đạc thực tế cho từng chỉ số xét nghiệm (`lab_test_items`); hệ thống tự động lấy khoảng tham chiếu chuẩn theo loài, lưu cố định vào kết quả (`min_value_snapshot`, `max_value_snapshot`) và hiển thị nhãn cảnh báo (`LOW`, `NORMAL`, `HIGH` – tính khi hiển thị, không lưu cột riêng); sau khi lấy mẫu bấm *"Đã lấy mẫu"* để phòng CĐHA biết thú cưng đã rời phòng Lab; nhập ghi chú nhận xét chuyên môn và xác nhận hoàn tất kết quả (`COMPLETED`).

---

### 3.4. Nhóm Kỹ thuật viên / Bác sĩ Chẩn đoán hình ảnh (IMAGING_TECHNICIAN)

Kỹ thuật viên / Bác sĩ chẩn đoán hình ảnh phụ trách vận hành chuyên môn độc lập tại Phòng Chẩn đoán hình ảnh (Imaging Room).

**Phạm vi công việc và quyền hạn:**
- **Theo dõi Hàng đợi CĐHA (Imaging Queue):** Tiếp nhận danh sách các chỉ định Siêu âm, Chụp X-quang (`category = 'IMAGING'`) từ bác sĩ lâm sàng; điều phối tiếp nhận theo cơ chế chống xung đột liên phòng.
- **Thực hiện chụp chiếu / siêu âm:** Chuẩn bị tư thế cho thú cưng, vận hành máy chụp X-quang hoặc máy siêu âm; cập nhật trạng thái dịch vụ sang `IN_PROGRESS`.
- **Tải ảnh & Nhập kết luận hình ảnh học:** Tải các tệp hình ảnh chẩn đoán (JPEG/PNG/DICOM) đính kèm vào hệ thống; ghi nhận mô tả chi tiết tổn thương hình thái và kết luận chẩn đoán hình ảnh; xác nhận hoàn tất (`COMPLETED`).

---

### 3.5. Nhóm Nhân viên Lễ tân / Thu ngân (RECEPTIONIST)

Lễ tân là nhân sự điều phối toàn bộ hoạt động tiếp đón, vận hành hàng đợi, thu phí khám và tiền Xét nghiệm / CĐHA để hệ thống phát phiếu xếp hàng, thu các hóa đơn dịch vụ còn lại và bán thuốc theo đơn tại quầy (khi khách chọn mua).

**Phạm vi công việc và quyền hạn:**
- **Tiếp đón & Quản lý khách hàng:** Tra cứu thông tin chủ nuôi, tạo mới hồ sơ khách hàng (hệ thống tự động cấp tài khoản), khởi tạo và cập nhật hồ sơ thú cưng.
- **Quản lý lịch hẹn:** Tiếp nhận và duyệt các yêu cầu đặt lịch trực tuyến (`PENDING` $\rightarrow$ `CONFIRMED` hoặc `CANCELLED`); tạo lịch hẹn mới qua điện thoại hoặc đặt trước trực tiếp tại quầy; thực hiện đổi ngày/khung giờ hẹn cho khách.
- **Tiếp nhận tại quầy (Check-in):** Thực hiện check-in cho khách có lịch hẹn hoặc tiếp nhận khách vãng lai (Walk-in), ghi lý do đến khám, đánh giá nhanh dấu hiệu cấp cứu (**Lễ tân không cân, không đo thân nhiệt**; việc này do Bác sĩ thực hiện trong phòng khám), chuyển đổi Lịch hẹn thành Đợt khám (`Pet Visit`) ở trạng thái chờ khám (`WAITING`).
- **Điều phối hàng đợi & Phân công phòng khám:** Giám sát danh sách chờ phân công và hàng đợi riêng của từng Bác sĩ, xử lý ưu tiên ca cấp cứu, xếp ca vào hàng đợi Bác sĩ (theo gợi ý Bác sĩ ít người chờ nhất) và chuyển ca giữa các hàng đợi khi cần.
- **Thanh toán & Bán thuốc:** Mở bảng kê các hóa đơn dịch vụ của ca (mỗi dịch vụ một hóa đơn, đã được hệ thống lập sẵn từ lúc Bác sĩ chỉ định), áp dụng giảm giá trên từng hóa đơn, xác nhận thanh toán sau khi khách trả tiền ngoài quầy (tiền mặt hoặc chuyển khoản; hệ thống không lưu phương thức thanh toán). Nếu ca có đơn thuốc, hóa đơn thuốc nháp đã được hệ thống tạo sẵn khi Bác sĩ chốt ca: khách mua tại phòng khám thì sửa số lượng theo khách, lấy thuốc, xác nhận thanh toán (trừ tồn kho tự động trong cùng một giao dịch an toàn) và in phiếu hướng dẫn dùng thuốc; khách mua ngoài thì hủy hóa đơn nháp và in đơn thuốc trao cho khách.

> **Nguyên tắc phân quyền nghiêm ngặt:** Lễ tân **tuyệt đối không được chỉnh sửa các dữ liệu chuyên môn** do Bác sĩ lập (nhận định lâm sàng, kết quả xét nghiệm, kết luận siêu âm, chẩn đoán xác định, đơn thuốc).

---

### 3.6. Nhóm Khách hàng / Chủ thú cưng (PET_OWNER)

Chủ thú cưng là người sử dụng Cổng thông tin khách hàng (Customer Portal) để tương tác trực tuyến với phòng khám.

**Quyền hạn và chức năng trên Portal:**
- **Quản lý hồ sơ thú cưng gia đình:** Xem danh sách các bé thú cưng của mình, đăng ký thêm hồ sơ thú cưng mới hoặc cập nhật thông tin đặc điểm nhận dạng.
- **Đặt lịch hẹn khám trực tuyến:** Chọn thú cưng, chọn ngày và khung giờ 30 phút mong muốn (theo sức chứa tự động tính toán của hệ thống), nhập lý do/triệu chứng ban đầu. **Chủ thú cưng không chọn bác sĩ khi đặt lịch.**
- **Quản lý lịch hẹn cá nhân:** Theo dõi trạng thái lịch hẹn (`PENDING`, `CONFIRMED`, `CHECKED_IN`, `CANCELLED`, `NO_SHOW`); thực hiện đổi khung giờ hoặc tự hủy lịch hẹn trước giờ hẹn tối thiểu 02 tiếng.
- **Tra cứu hồ sơ bệnh án trực tuyến:** Xem lại toàn bộ lịch sử các đợt khám bệnh của thú cưng, bao gồm kết luận chẩn đoán của bác sĩ, kết quả xét nghiệm, hình ảnh siêu âm/X-quang và đơn thuốc chi tiết (có thể dùng để mua thuốc ở nơi khác).

---

## 4. Quy định về thời gian làm việc của bác sĩ

Trong phạm vi hệ thống:

- **Bác sĩ luôn làm việc đầy đủ:** Coi như toàn bộ các bác sĩ đều có mặt và làm việc đầy đủ theo giờ mở cửa của phòng khám.
- **Không quản lý ca kíp và không quản lý nghỉ phép:** Hệ thống lược bỏ hoàn toàn các chức năng chấm công, xếp ca làm việc và đơn xin nghỉ phép để đơn giản hóa vận hành và tập trung vào nghiệp vụ khám chữa bệnh cốt lõi.
- Lễ tân phân công bệnh nhân bằng cách **xếp vào hàng đợi riêng của từng bác sĩ** ngay khi tiếp nhận (phiếu xếp hàng được phát khi khách nộp phí khám), cân bằng theo số người đang chờ; không phụ thuộc bác sĩ đang rảnh hay đang bận.

---

## 5. Nguyên tắc đặt lịch & Cơ chế Khung giờ tiếp nhận (Time Slots & Capacity)

### 5.1. Nguyên tắc cốt lõi: Khách hàng không chọn Bác sĩ
Trong mô hình vận hành mới của phòng khám:
- **Chủ thú cưng chỉ đăng ký:** Thú cưng cần khám, ngày khám, khung giờ mong muốn và lý do khám / triệu chứng ban đầu.
- **Tuyệt đối không chọn bác sĩ khám khi đặt lịch:** Việc phân bổ bác sĩ nào khám ca nào sẽ do nhân viên Lễ tân tại quầy trực tiếp điều phối dựa trên số người đang chờ trong hàng đợi của từng bác sĩ tại cơ sở.
- **Mục đích nghiệp vụ:** 
  - Tránh tình trạng dồn ứ bệnh nhân vào một bác sĩ "ngôi sao" gây quá tải cục bộ, trong khi các bác sĩ khác phải ngồi chờ.
  - Đảm bảo cân bằng tải làm việc giữa các phòng khám trong toàn bộ ngày làm việc.
  - Phù hợp với năng lực chuyên môn đồng đều của đội ngũ bác sĩ (`VETERINARIAN`).

### 5.2. Cấu trúc Khung giờ làm việc chuẩn (Standard Time Slots)
Phòng khám hoạt động trong khung giờ hành chính cố định từ **08:00 đến 17:30** hàng ngày. Một ngày làm việc được chia thành **14 khung giờ tiếp nhận chuẩn (Fixed Time Slots)**, mỗi khung giờ kéo dài **30 phút**:

| Ca làm việc | Khung giờ tiếp nhận | Thời lượng | Mục đích vận hành |
| :--- | :---: | :---: | :--- |
| **Ca sáng** | `08:00 - 08:30` | 30 phút | Tiếp nhận ca sáng sớm, ưu tiên ca lấy mẫu xét nghiệm nhịn ăn |
| *(08:00 - 12:00)* | `08:30 - 09:00` | 30 phút | Tiếp nhận lịch hẹn khám & tái khám |
| | `09:00 - 09:30` | 30 phút | Tiếp nhận lịch hẹn khám & tiêm phòng |
| | `09:30 - 10:00` | 30 phút | Tiếp nhận lịch hẹn khám cao điểm sáng |
| | `10:00 - 10:30` | 30 phút | Tiếp nhận lịch hẹn khám & cận lâm sàng |
| | `10:30 - 11:00` | 30 phút | Tiếp nhận ca khám cuối buổi sáng |
| | `11:00 - 11:30` | 30 phút | Khung giờ dự phòng trả kết quả xét nghiệm ca sáng |
| **Nghỉ trưa** | `12:00 - 13:30` | 90 phút | Bác sĩ hội chẩn, vệ sinh khử trùng phòng khám |
| **Ca chiều** | `13:30 - 14:00` | 30 phút | Tiếp nhận ca đầu giờ chiều |
| *(13:30 - 17:30)* | `14:00 - 14:30` | 30 phút | Tiếp nhận lịch hẹn khám & tiêm phòng |
| | `14:30 - 15:00` | 30 phút | Tiếp nhận lịch hẹn khám cao điểm chiều |
| | `15:00 - 15:30` | 30 phút | Tiếp nhận lịch hẹn khám & siêu âm |
| | `15:30 - 16:00` | 30 phút | Tiếp nhận lịch hẹn khám & tẩy giun |
| | `16:00 - 16:30` | 30 phút | Tiếp nhận lịch hẹn khám muộn |
| | `16:30 - 17:00` | 30 phút | Khung giờ tiếp nhận lịch hẹn cuối cùng trong ngày |

### 5.3. Cơ chế Sức chứa khung giờ tính động theo số Bác sĩ (Dynamic Slot Capacity based on Active Doctors)
Sức chứa tối đa của mỗi khung giờ tiếp nhận không bị cố định cứng mà được **hệ thống tự động tính toán linh hoạt dựa trên tổng số Bác sĩ đang hoạt động (`ACTIVE`) nhân với Hệ số năng lực phục vụ y tế ($k = 2$)**:
$$\text{MAX\_APPOINTMENTS\_PER\_SLOT} = N_{\text{active}} \times k = \text{COUNT}(\text{users where role} = 'VETERINARIAN' \text{ and status} = 'ACTIVE') \times 2$$

Trong đó:
- $N_{\text{active}}$: Số Bác sĩ đang ở trạng thái làm việc bình thường (`ACTIVE`) trong hệ thống.
- $k = 2$: Hệ số điều phối tiếp nhận theo **Chu kỳ Khám 2 Pha Bất đồng bộ (Two-Phase Asynchronous Clinical Cycle)**:
  - Khám lâm sàng sơ bộ Giai đoạn 1 (đo sinh hiệu, sờ nắn, ra chỉ định cận lâm sàng) chỉ mất trung bình **12 – 15 phút/ca**.
  - Sau 15 phút, thú cưng được đưa sang phòng Lab lấy mẫu hoặc phòng CĐHA siêu âm/chụp X-quang. Bác sĩ lập tức rảnh (`AVAILABLE`) để đón tiếp ca thứ 2 trong cùng khung giờ 30 phút.
  - Nhờ vậy, Bác sĩ không bị "thời gian chết" (15 phút chờ kết quả xét nghiệm), đồng thời tạo bộ đệm dự phòng cho tỷ lệ khách bùng lịch (No-Show Buffer 15 – 20%).

**Cơ chế Điều phối & Xếp hàng đợi (Queue Scheduling):**
- **Phục vụ theo thứ tự nộp tiền (FCFS):** Khách nộp phí khám trước đứng trước trong hàng đợi (thứ tự theo thời điểm thu tiền).
- **Chia đều vào hàng đợi riêng của từng Bác sĩ:** Với $N_{\text{active}}$ Bác sĩ và $2 \times N_{\text{active}}$ khách mỗi khung giờ, Lễ tân xếp mỗi Bác sĩ khoảng 2 khách (hệ thống gợi ý Bác sĩ ít người chờ nhất). Khách thứ 2 của mỗi Bác sĩ chờ 5 – 10 phút trước phòng và được gọi ngay khi Bác sĩ chuyển khách thứ nhất sang phòng cận lâm sàng.
- **Thứ tự trong mỗi hàng đợi Bác sĩ:** Phiếu cấp cứu (`priority = 2`) đứng đầu; phiếu của ca có kết quả cận lâm sàng quay lại (`priority = 1`) đứng kế tiếp; còn lại theo thời điểm thu tiền (Redis Sorted Set, `score` = mức ưu tiên + thời điểm).

**Thuật toán kiểm tra trạng thái khung giờ trên giao diện:**
Khi khách hàng chọn một ngày trên lịch, hệ thống thực hiện các bước tính toán:
1. **Bước 1:** Xác định sức chứa tối đa của một khung giờ tại thời điểm hiện tại:
   ```sql
   SELECT COUNT(*) * 2 AS max_capacity
   FROM users u
   JOIN user_roles ur ON ur.user_id = u.id
   JOIN roles r ON r.id = ur.role_id
   WHERE r.code = 'VETERINARIAN' AND u.status = 'ACTIVE';
   ```
   *(Bảng `users` thuộc CSDL của `auth-service`; `appointment-service` lấy số Bác sĩ đang `ACTIVE` qua API nội bộ rồi nhân hệ số 2, không JOIN trực tiếp giữa hai CSDL.)*
2. **Bước 2:** Đếm số lượng lịch hẹn đang chiếm chỗ trong từng khung giờ của ngày đã chọn:
   ```sql
   SELECT start_time, COUNT(*) AS booked_count
   FROM appointments
   WHERE appointment_date = :selected_date
     AND status IN ('PENDING', 'CONFIRMED', 'CHECKED_IN')
   GROUP BY start_time;
   ```
   **Vì sao tính cả `CHECKED_IN`:** khách đã check-in vẫn đang dùng suất của khung giờ đó. Nếu không tính, một khách đến sớm và check-in sẽ "trả lại" chỗ, khung giờ bị đặt vượt sức chứa. Chỉ `CANCELLED` và `NO_SHOW` mới giải phóng chỗ. *(Quy tắc này áp dụng thống nhất cho mọi tài liệu và mã nguồn; tài liệu Lộ trình mã nguồn cần sửa câu truy vấn đếm slot cho khớp.)*
3. **Bước 3:** Đánh giá tính khả dụng và hiển thị:
   - **Trường hợp 1 (Còn chỗ - Available):** `booked_count < max_capacity`
     - Giao diện hiển thị nút chọn khung giờ màu xanh lá, kèm thông tin trực quan: *"Còn [max_capacity - booked_count] chỗ"*.
     - Khách hàng được phép click chọn để tiếp tục luồng đặt lịch.
   - **Trường hợp 2 (Đã kín lịch - Full/Disabled):** `booked_count >= max_capacity`
     - Giao diện làm mờ (disable) nút chọn khung giờ, đổi sang màu xám kèm nhãn *"Đã kín lịch"*.
     - Hệ thống ngăn chặn việc click chọn, hướng dẫn khách chọn khung giờ khác hoặc ngày khác.

---

## 6. Các kênh tiếp nhận đặt lịch & Quy trình xử lý

Hệ thống hỗ trợ 3 kênh tiếp nhận đặt lịch, được quản lý qua thuộc tính `booking_channel`:

```text
               CÁC KÊNH ĐẶT LỊCH HẸN KHÁM
                           │
       ┌───────────────────┼───────────────────┐
       ▼                   ▼                   ▼
 KÊNH 1: ONLINE      KÊNH 2: PHONE       KÊNH 3: WALK_IN
 (Khách tự đặt)    (Lễ tân đặt hộ)    (Đặt trước tại quầy)
       │                   │                   │
       ▼                   ▼                   ▼
Trạng thái: PENDING  Trạng thái: CONFIRMED Trạng thái: CONFIRMED
(Chờ lễ tân duyệt)   (Đã xác nhận ngay)  (Đã xác nhận ngay)
```

### 6.1. Kênh 1: Đặt lịch trực tuyến qua Cổng Portal (`booking_channel = 'ONLINE'`)
- **Đối tượng thực hiện:** Chủ thú cưng tự thao tác trên Cổng thông tin khách hàng (Website/App).
- **Quy trình các bước:**
  1. Chủ nuôi đăng nhập vào tài khoản cá nhân.
  2. Chọn thú cưng từ danh sách thú cưng của gia đình (hoặc bấm *"Thêm mới thú cưng"* nếu chưa có hồ sơ).
  3. Chọn ngày muốn khám (từ ngày hiện tại đến tối đa 30 ngày tới).
  4. Hệ thống tải danh sách 14 khung giờ trong ngày kèm trạng thái Còn chỗ / Hết chỗ.
  5. Chủ nuôi chọn một khung giờ còn chỗ và nhập lý do khám / triệu chứng ban đầu.
  6. Bấm *"Xác nhận đặt lịch"*.
  7. Hệ thống tạo lịch hẹn ở trạng thái **`PENDING` (Chờ xác nhận)** và sinh mã lịch hẹn duy nhất (ví dụ: `APT-20261010-001`).
  8. Hệ thống gửi thông báo cho khách hàng: *"Lịch hẹn đã được ghi nhận. Lễ tân phòng khám sẽ liên hệ xác nhận trong vòng 30 phút."*

### 6.2. Kênh 2: Đặt lịch qua điện thoại (`booking_channel = 'PHONE'`)
- **Đối tượng thực hiện:** Nhân viên Lễ tân trực tổng đài phòng khám.
- **Quy trình các bước:**
  1. Khách hàng gọi điện đến số hotline phòng khám yêu cầu đặt lịch.
  2. Lễ tân mở màn hình *"Tạo lịch hẹn mới"* trên phần mềm quản trị.
  3. Lễ tân nhập Số điện thoại của khách hàng để tra cứu:
     - Nếu khách cũ: Hệ thống hiển thị thông tin chủ nuôi và danh sách thú cưng để chọn.
     - Nếu khách mới: Lễ tân nhập nhanh Họ tên, SĐT, Địa chỉ và Tên thú cưng, Loài (Chó/Mèo).
  4. Lễ tân kiểm tra ngày và khung giờ khách mong muốn trên giao diện lịch làm việc.
  5. Nhập triệu chứng khách mô tả qua điện thoại.
  6. Lễ tân bấm *"Lưu & Xác nhận lịch hẹn"*.
  7. Lịch hẹn được tạo ngay ở trạng thái **`CONFIRMED` (Đã xác nhận)** vì đã được nhân viên phòng khám trực tiếp kiểm tra và trao đổi qua điện thoại.

### 6.3. Kênh 3: Đặt lịch trực tiếp tại quầy cho lần sau (`booking_channel = 'WALK_IN'`)
- **Đối tượng thực hiện:** Nhân viên Lễ tân tại quầy tiếp đón.
- **Hoàn cảnh áp dụng:** Khách hàng đang có mặt tại phòng khám (ví dụ: vừa khám xong, hoặc mua thức ăn/phụ kiện) và muốn hẹn trước lịch tái khám, lịch tiêm phòng mũi tiếp theo cho tuần sau/tháng sau.
- **Quy trình:** Tương tự như Kênh 2, lịch hẹn được tạo trực tiếp tại quầy và chuyển ngay sang trạng thái **`CONFIRMED`**. Lễ tân có thể in ngay phiếu hẹn trao tay cho khách hàng.

---

## 7. Vòng đời, Máy trạng thái và Quy tắc xử lý Lịch hẹn (Appointment Lifecycle)

### 7.1. Sơ đồ chuyển đổi trạng thái (State Transition Diagram)

```text
                     [ Đặt lịch Online ]
                              │
                              ▼
                     ┌─────────────────┐
           ┌─────────┤     PENDING     ├────────┐
           │         └────────┬────────┘        │
(Từ chối / Hủy)               │                 │ (Khách tự hủy)
           │           (Lễ tân duyệt)           │
           │                  │                 │
           ▼                  ▼                 ▼
     ┌───────────┐    ┌─────────────────┐ ┌───────────┐
     │ CANCELLED │    │    CONFIRMED    │ │ CANCELLED │
     └───────────┘    └───────┬─────────┘ └───────────┘
                              │
          ┌───────────────────┼───────────────────┐
          │ (Khách đến quầy)  │ (Quá 30p ko đến)  │ (Báo bận hủy hẹn)
          ▼                   ▼                   ▼
    ┌───────────┐       ┌───────────┐       ┌───────────┐
    │CHECKED_IN │       │  NO_SHOW  │       │ CANCELLED │
    └─────┬─────┘       └───────────┘       └───────────┘
          │
          ▼
   [ Tạo PET VISIT ]
   (Vào Hàng đợi khám)
```

### 7.2. Chi tiết 5 trạng thái nghiệp vụ của Lịch hẹn
1. **`PENDING` (Chờ xác nhận):**
   - Áp dụng riêng cho lịch hẹn đặt qua kênh `ONLINE`.
   - Vẫn **tạm thời chiếm 1 suất sức chứa** trong khung giờ đã chọn để tránh tình trạng khách khác đặt đè lên trong lúc chờ duyệt.
   - Lễ tân có trách nhiệm kiểm tra và xử lý trong vòng 15 – 30 phút.
2. **`CONFIRMED` (Đã xác nhận):**
   - Lịch hẹn đã được Lễ tân kiểm tra hợp lệ và chấp thuận tiếp nhận (hoặc được tạo trực tiếp qua điện thoại / tại quầy).
   - Suất giữ chỗ chính thức được bảo lưu. Khách hàng nhận được thông báo xác nhận thời gian có mặt trên ứng dụng / Portal.
3. **`CHECKED_IN` (Đã đến khám):**
   - Khách hàng đã thực sự đưa thú cưng đến quầy tiếp đón của phòng khám trong ngày hẹn.
   - Đây là điểm mốc then chốt: **Lịch hẹn kết thúc vòng đời đặt chỗ và chuyển tiếp thành Đợt khám (`Pet Visit`)** để bước vào quy trình y tế.
4. **`CANCELLED` (Đã hủy):**
   - Lịch hẹn bị hủy bỏ trước thời điểm khám.
   - **Quy tắc giải phóng:** Ngay khi lịch hẹn bị hủy, hệ thống **hoàn trả ngay lập tức 1 suất sức chứa** cho khung giờ đó để khách hàng khác có thể đặt chỗ.
   - Hệ thống bắt buộc ghi nhận lý do hủy, người thực hiện hủy (Khách hay Lễ tân) và thời điểm hủy vào **1 dòng `appointment_status_histories`** (`notes` = lý do, `changed_by_user_id` = người hủy, `created_at` = thời điểm). Bảng `appointments` không có cột lý do hủy riêng.
5. **`NO_SHOW` (Khách không đến):**
   - Khách có lịch hẹn `CONFIRMED` nhưng không đến phòng khám và không liên hệ báo hủy.
   - Hệ thống đánh dấu trạng thái này để phục vụ thống kê tỷ lệ bùng lịch, cảnh báo nếu khách hàng có lịch sử bùng lịch nhiều lần.

### 7.3. Quy trình xác nhận và từ chối lịch hẹn trực tuyến
- **Xác nhận (`PENDING` $\rightarrow$ `CONFIRMED`):**
  - Lễ tân mở danh sách lịch hẹn chờ duyệt trên phần mềm.
  - Lễ tân gọi điện thoại cho khách hàng để xác nhận lại tình trạng thú cưng, dặn dò các lưu ý chuyên môn (ví dụ: *nếu cần xét nghiệm máu thì dặn nhịn ăn trước 6 tiếng*).
  - Lễ tân bấm nút **"Xác nhận lịch hẹn"**. Hệ thống chuyển trạng thái sang `CONFIRMED` và gửi thông báo xác nhận đến tài khoản của khách.
- **Từ chối / Hủy từ phía phòng khám (`PENDING` $\rightarrow$ `CANCELLED`):**
  - Nếu phòng khám đột xuất có ca phẫu thuật lớn, mất điện, hoặc khách đặt sai nội dung (ví dụ: yêu cầu dịch vụ phòng khám không cung cấp), Lễ tân bấm **"Từ chối lịch hẹn"**.
  - Bắt buộc nhập lý do từ chối (ví dụ: *"Phòng khám bảo trì máy xét nghiệm, xin lỗi quý khách"*).
  - Hệ thống giải phóng slot và gửi thông báo giải thích cho khách hàng.

### 7.4. Quy trình đổi lịch hẹn (Reschedule: Đổi ngày / Đổi khung giờ)
- **Quy tắc đổi lịch:**
  - Khách hàng chỉ được phép đổi lịch trước giờ hẹn **tối thiểu 02 tiếng**.
  - Chỉ được đổi sang khung giờ **còn chỗ** (`booked_count < max_capacity`, với `max_capacity` = số Bác sĩ đang hoạt động × 2 như mục 5.3; không dùng con số cố định).
- **Cơ chế giao dịch hệ thống khi đổi lịch:**
  1. Kiểm tra sức chứa của khung giờ mới. Nếu mới đầy chỗ thì từ chối.
  2. Giảm 1 suất đặt ở khung giờ cũ (giải phóng slot cũ).
  3. Tăng 1 suất đặt ở khung giờ mới (chiếm giữ slot mới).
  4. Cập nhật `appointment_date`, `start_time` trong bản ghi `appointments`. Khung giờ cố định 30 phút nên **không lưu `end_time`** (giờ kết thúc = `start_time` + 30 phút).
  5. Giữ nguyên trạng thái `CONFIRMED` (hoặc `PENDING`) và gửi thông báo cập nhật thời gian mới cho khách hàng.

### 7.5. Quy trình hủy lịch hẹn từ phía Khách hàng
- **Quy tắc tự hủy:**
  - Khách hàng có thể chủ động bấm *"Hủy lịch hẹn"* trên Portal trước giờ hẹn tối thiểu 02 tiếng.
  - Khách hàng chọn lý do hủy (Bận đột xuất, Thú cưng đã ổn, Đổi cơ sở khác...).
  - Hệ thống chuyển `status = 'CANCELLED'`, giải phóng sức chứa của slot và gửi thông báo hủy thành công.
- **Nếu khách báo hủy sát giờ (dưới 2 tiếng):** Khách không thể tự hủy trên Web mà phải gọi điện trực tiếp cho Lễ tân phòng khám để xử lý ngoại lệ.

### 7.6. Quy trình xử lý khách không đến (No-Show Handling)
- **Mốc vắng mặt:** `appointment_date` + `start_time` + **30 phút**. Trước mốc này, Lễ tân có thể gọi điện nhắc khách các lịch `CONFIRMED` chưa check-in.
- **Tự động đánh dấu:** Tác vụ định kỳ của `appointment-service` quét các lịch `CONFIRMED` đã quá mốc mà chưa check-in, chuyển `status = 'NO_SHOW'` và ghi 1 dòng `appointment_status_histories` (`changed_by_user_id = NULL`). Lễ tân cũng có thể bấm **"Đánh dấu vắng mặt (No-Show)"** thủ công sau khi liên hệ không được.
- **Khách đến sau khi đã `NO_SHOW`:** Lịch giữ nguyên `NO_SHOW`; Lễ tân tiếp nhận như khách vãng lai (đợt khám mới với `appointment_id = NULL`).
- Tỷ lệ bùng lịch của chủ nuôi được thống kê từ các lịch hẹn `NO_SHOW` của họ (không cần cột riêng).

---

## 8. Quy trình tiếp đón tại quầy & Chuyển đổi sang Đợt khám (Reception & Check-in)

```text
Khách đến phòng khám
        │
        ├──> [ ĐÃ CÓ LỊCH HẸN ] ──> Tra cứu theo SĐT/Mã ──> Check-in ──┐
        │                                                               │
        ├──> [ KHÁCH VÃNG LAI ] ──> Đón tiếp tại quầy ────> Tạo mới ────┼──> Ghi lý do khám & đánh giá
        │                                                               │    dấu hiệu cấp cứu (không cân đo)
        └──> [ CA CẤP CỨU ] ─────> Bật cờ ƯU TIÊN ────────> Tiếp nhận ─┘               │
                                                                                       ▼
                                                                             Khởi tạo PET VISIT
                                                                          (Trạng thái: WAITING)
                                                                       + hóa đơn PHÍ KHÁM (chờ thu)
                                                                                       │
                                                                                       ▼
                                                                         Khách NỘP PHÍ KHÁM tại quầy
                                                                       (ca cấp cứu: bỏ qua, thu sau)
                                                                                       │
                                                                                       ▼
                                                                        Phát PHIẾU XẾP HÀNG (số thứ tự)
                                                                          vào HÀNG ĐỢI BÁC SĨ
```

### 8.1. Luồng tiếp nhận khách có lịch hẹn (Appointment Check-in)
1. Khách hàng và thú cưng có mặt tại quầy tiếp đón.
2. Lễ tân tra cứu lịch hẹn bằng Số điện thoại hoặc Mã lịch hẹn.
3. Hệ thống hiển thị thông tin lịch hẹn đã xác nhận trong ngày.
4. Lễ tân thực hiện tiếp nhận hành chính và sàng lọc sơ bộ tại quầy:
   - Quan sát, đánh giá nhanh tri giác và dấu hiệu nguy kịch (nếu nguy kịch thì chuyển ngay sang luồng Cấp cứu).
   - Hỏi thăm lý do đến khám / triệu chứng hiện tại, ghi chú bổ sung nếu có thay đổi so với khi đặt lịch.
   - *(Lưu ý: Thao tác đo cân nặng và thân nhiệt sẽ do Bác sĩ trực tiếp thực hiện trong phòng khám lâm sàng).*
5. Lễ tân bấm nút **"Hoàn tất tiếp đón"**.
6. **`clinical-service` xử lý trong một giao dịch an toàn của mình:**
   - Kiểm tra lịch hẹn đang `CONFIRMED`, đúng ngày, đúng thú cưng (chỉ đọc từ `appointment-service`).
   - Khởi tạo Đợt khám mới (`pet_visits`) với trạng thái ban đầu là `WAITING` (Chờ khám).
   - Thiết lập khóa ngoại logic: `pet_visits.appointment_id = appointments.id`.
   - Ghi nhận thời điểm tiếp nhận (`checked_in_at = NOW()`), ID lễ tân tiếp đón và cờ cấp cứu (nếu có); ghi 1 dòng lịch sử cho đợt khám (→ `WAITING`).
   - Từ chối tạo đợt khám nếu thú cưng còn một đợt khám chưa kết thúc (khác `COMPLETED` / `CANCELLED`).
   - Ghi Bác sĩ phụ trách nếu Lễ tân chọn (hệ thống gợi ý Bác sĩ ít người chờ nhất).
   - Tự động tạo **dịch vụ khám** (nhóm `EXAMINATION`, mặc định "Khám tổng quát") kèm **hóa đơn phí khám `PENDING`** (chốt đơn giá, thuế suất từ bảng giá đang hiệu lực).
   - Ghi sự kiện `VisitCheckedInEvent` vào bảng outbox trong cùng giao dịch. Ca hiện ở mục *"Chờ thu phí khám"* trên màn hình Thu ngân, **chưa vào hàng đợi**.
7. **Sau khi giao dịch trên commit**, tiến trình outbox gửi sự kiện `VisitCheckedInEvent` (gửi lại tới khi thành công); `appointment-service` nhận sự kiện, chuyển lịch hẹn sang `CHECKED_IN` và ghi 1 dòng lịch sử (`CONFIRMED` → `CHECKED_IN`) trong giao dịch riêng của mình. Hai CSDL khác nhau nên không ghi chung một giao dịch; độ trễ chỉ vài trăm mili giây và lịch vẫn được tính là chiếm chỗ của khung giờ.

### 8.2. Luồng tiếp nhận khách vãng lai (Walk-in Visit - Không đặt trước)
Không phải tất cả khách hàng đều đặt lịch trước. Phòng khám luôn sẵn sàng phục vụ khách hàng vãng lai:
1. Khách hàng trực tiếp đưa thú cưng đến quầy tiếp đón.
2. Lễ tân chọn chức năng *"Tiếp nhận khách vãng lai"*.
3. Lễ tân tra cứu Số điện thoại:
   - **Khách hàng cũ:** Hệ thống hiển thị hồ sơ chủ nuôi và danh sách thú cưng đã có $\rightarrow$ Lễ tân chọn bé cần khám.
   - **Khách hàng mới:** Lễ tân nhập nhanh Họ tên, Số điện thoại, Địa chỉ và tạo hồ sơ thú cưng (Tên, Loài, Giống, Giới tính). Hệ thống tự động cấp tài khoản cho khách hàng.
4. Lễ tân nhập lý do đến khám / triệu chứng ban đầu (việc đo cân nặng, thân nhiệt sẽ do Bác sĩ thực hiện trong phòng khám).
5. Lễ tân bấm lưu:
   - Hệ thống tạo Đợt khám mới (`pet_visits`) với `appointment_id = NULL`.
   - Trạng thái ca khám là `WAITING` (Chờ khám), kèm hóa đơn phí khám `PENDING` như mục 8.1.
6. Khách nộp phí khám (mục 8.5) để nhận phiếu vào hàng đợi Bác sĩ (hoặc danh sách chờ phân công).

### 8.3. Luồng tiếp nhận khẩn cấp (Emergency Priority Case)
- Áp dụng khi thú cưng gặp tình trạng nguy kịch: Tai nạn giao thông, co giật, khó thở dữ dội, ngộ độc, xuất huyết ồ ạt.
- Lễ tân bấm chọn nút **"Tiếp nhận Cấp cứu"**:
  - Hệ thống gắn cờ ưu tiên đặc biệt (`is_emergency = TRUE`, nhãn nổi bật đỏ).
  - **Khám trước, thu sau:** hệ thống phát ngay phiếu xếp hàng `priority = 2` mà không chờ nộp phí khám; các hóa đơn của ca được thu khi chốt ca.
  - Lễ tân xếp ngay ca vào hàng đợi của một Bác sĩ (ưu tiên Bác sĩ sắp khám xong); phiếu đứng **đầu hàng đợi** đó, vượt qua mọi ca thông thường, và được gọi ngay khi Bác sĩ khám xong ca hiện tại.

### 8.4. Quy tắc ưu tiên trong hàng đợi
Mọi hàng đợi (danh sách chờ phân công, hàng đợi của từng Bác sĩ, phòng Xét nghiệm, phòng CĐHA) đều là danh sách **phiếu xếp hàng** đang `WAITING` trên Redis, sắp theo cùng một quy tắc:
1. **Ưu tiên tuyệt đối:** Phiếu cấp cứu (`priority = 2`) luôn đứng đầu và giữ cảnh báo đỏ.
2. **Ca có kết quả cận lâm sàng quay lại (chỉ ở hàng đợi Bác sĩ):** khi ca chuyển `RESULTS_READY`, hệ thống phát phiếu `priority = 1` (không thu tiền), nên ca đứng ngay sau ca cấp cứu.
3. **Thứ tự nộp tiền:** Các phiếu còn lại (`priority = 0`, có lịch hẹn hoặc vãng lai) theo giờ nộp tiền, không đổi khi gọi / gọi lại / đổi Bác sĩ.

Cài đặt (v4.0): mỗi hàng đợi là một Sorted Set trên Redis, `score = (2 − priority) × 10^13 + thời điểm nộp tiền (ms)`, đọc tăng dần là đúng thứ tự trên. Số in trên phiếu (`ticket_no`) do bộ đếm Redis cấp, đánh lại từ 1 mỗi ngày theo từng loại hàng đợi.

### 8.5. Thu phí khám & Phát phiếu xếp hàng (thanh toán tách khỏi khám)
1. Sau khi tiếp đón, ca hiện ở mục *"Chờ thu phí khám"* của màn hình Thu ngân (Lễ tân kiêm Thu ngân).
2. Khách nộp phí khám (tiền mặt / chuyển khoản ngoài quầy); Thu ngân bấm **"Xác nhận thanh toán"**.
3. Hóa đơn phí khám → `PAID` (giao dịch của `clinical-service`, kèm sự kiện thanh toán ghi vào outbox). Ngay sau đó (thường dưới 1 giây) hệ thống phát **phiếu `DOCTOR`** trên Redis (Bác sĩ đã chọn hoặc danh sách chờ phân công, `priority = 0`, số thứ tự tiếp theo trong ngày, người phát = Thu ngân) và hiển thị / in **số phòng + số thứ tự**. Đã thu tiền thì chắc chắn có phiếu, kể cả khi hệ thống trục trặc ngay sau khi thu.
4. Ca xuất hiện trên màn hình hàng đợi của Bác sĩ (mỗi dòng có nút "Gọi" và "Bắt đầu"). Ca chưa nộp phí khám **không hiện** trên màn hình Bác sĩ.
5. Khách bỏ về trước khi khám (EX-03): phiếu bị hủy; phí khám chưa nộp thì hủy hóa đơn, **đã nộp thì không hoàn**.

> **Vì sao không có tầng "khách có hẹn đúng giờ":** lịch hẹn chỉ dùng để giữ chỗ và cân bằng số khách mỗi khung giờ (mục 5.3); khi khách đã đến quầy, thứ tự check-in phản ánh đúng thứ tự đến. Ngoài ra giờ hẹn nằm ở CSDL của `appointment-service`, còn hàng đợi nằm ở `clinical-service`; tầng "đúng giờ hẹn" sẽ cần truy vấn liên service cho mỗi lần tải hàng đợi.

---

## 9. Hàng đợi khám

Hệ thống có **bốn loại hàng đợi**, đều là danh sách **phiếu xếp hàng** lưu trên **Redis** (thay đổi tức thời, thao tác nguyên tử, không xung đột khi nhiều người bấm cùng lúc), dùng chung cơ chế "Gọi" theo từng dòng (không đổi thứ tự). Phiếu chỉ được phát **sau khi khách nộp tiền** dịch vụ thuộc nhóm thu trước (`service_categories.requires_prepayment = TRUE`), trừ ca cấp cứu và ca có kết quả CLS. Phiếu kết thúc (xong / hủy) được ghi vào lịch sử `queue_ticket_histories` để tra cứu và thống kê thời gian chờ:

| Hàng đợi | Phiếu được phát khi nào | Ai gọi số | Gồm những phiếu nào |
| :--- | :--- | :--- | :--- |
| **Danh sách chờ phân công** | Thu xong phí khám mà Lễ tân chưa chọn Bác sĩ | (không gọi) – Lễ tân xếp vào hàng đợi Bác sĩ | Phiếu `DOCTOR` `WAITING` chưa có Bác sĩ |
| **Hàng đợi riêng của từng Bác sĩ** | Thu xong phí khám (`priority = 0`); ca cấp cứu (`priority = 2`); ca có kết quả CLS (`priority = 1`, không thu tiền) | Bác sĩ | Phiếu `DOCTOR` `WAITING` của Bác sĩ đó |
| **Hàng đợi phòng Xét nghiệm** | Thu xong tiền các dịch vụ `LABORATORY` | KTV Xét nghiệm | Phiếu `LABORATORY` `WAITING` |
| **Hàng đợi phòng CĐHA** | Thu xong tiền các dịch vụ `IMAGING` | KTV / Bác sĩ CĐHA | Phiếu `IMAGING` `WAITING` |

Một ca khám có cận lâm sàng thường có **3 phiếu nối tiếp**: phiếu Bác sĩ lần 1 (sau khi nộp phí khám) → phiếu phòng Xét nghiệm / CĐHA (sau khi nộp tiền CLS) → phiếu Bác sĩ lần 2 (ưu tiên, không thu tiền).

**Gọi:** mỗi phiếu trong hàng đợi có nút *"Gọi"* (và *"Bắt đầu"*). Người phụ trách hàng đợi (khi không đang làm dở ca nào) bấm *"Gọi"* ở một phiếu **bất kỳ** (hoặc *"Gọi số tiếp theo"* để gọi phiếu đứng đầu): hệ thống ghi giờ gọi và tăng số lần gọi trên phiếu (hiển thị "Đã gọi HH:mm"), hiển thị số thứ tự và số phòng trên màn hình sảnh và gửi thông báo đến ứng dụng của chủ nuôi. Gọi **không đổi trạng thái và không đổi thứ tự**: phiếu chỉ chuyển `IN_SERVICE` khi thú cưng vào phòng và người phụ trách bấm "Bắt đầu khám" / "Bắt đầu Giai đoạn 2" / "Bắt đầu".

**Khách vắng / quay lại:** gọi 2–3 lần không thấy, người phụ trách bấm *"Gọi"* ở **phiếu khác** trong danh sách; phiếu vắng giữ nguyên vị trí. Ví dụ hàng đợi Bác sĩ A là `[Milo, Lu, Na]`: gọi Milo không thấy → gọi Lu (hàng đợi vẫn là `[Milo, Lu, Na]`). Khi khách quay lại (Bác sĩ nhận thông báo hoặc khách báo tại quầy), Bác sĩ bấm *"Gọi lại"* ở đúng ca đó. Hệ thống không theo dõi việc khách quay lại, nên không bao giờ xảy ra tình trạng hai ca đầu hàng đổi chỗ cho nhau mãi mãi hay ca cấp cứu bị mất ưu tiên. *(Cập nhật 13/11/2026: thay cho cơ chế "Đẩy lùi 1 bậc" của bản v3.0 đầu; cột `skip_count`, hành động `SKIPPED` và API đẩy lùi đã bị xóa.)*

**Gộp ca ở phòng Xét nghiệm / CĐHA:** các dịch vụ đã nộp tiền của **cùng một đợt khám trong cùng phòng** (ví dụ siêu âm + X-quang) nằm chung **một phiếu**: gọi một lần, "Bắt đầu" cả phiếu; nhập kết quả và hủy vẫn theo từng dịch vụ (mỗi dịch vụ có kết quả và hóa đơn riêng).

---

## 10. Phân công bác sĩ

**Khách không chọn bác sĩ.** Lễ tân là người phân công, bằng cách **chọn bác sĩ cho ca** (lúc tiếp đón hoặc sau khi khách nộp phí khám); phiếu của ca vào hàng đợi riêng của bác sĩ đó. Việc này làm được bất cứ lúc nào, kể cả khi bác sĩ đang khám, nên Lễ tân không phải chờ bác sĩ rảnh.

Lễ tân dựa trên:

- **Số người đang chờ** trong hàng đợi của từng bác sĩ (hệ thống gợi ý bác sĩ ít người chờ nhất).
- Số phòng cố định của bác sĩ.
- Mức độ ưu tiên của ca khám (cấp cứu / thông thường).
- Yêu cầu riêng của khách (nếu có).

Ví dụ bảng điều phối của phòng khám có 3 bác sĩ:

```text
Bác sĩ A – Phòng P01 – Đang khám  – Đang chờ: 2  [Milo, Lu]
Bác sĩ B – Phòng P02 – Sẵn sàng   – Đang chờ: 0  []              ← gợi ý
Bác sĩ C – Phòng P03 – Đang khám  – Đang chờ: 1  [Bông (có kết quả)]
```

Lễ tân xếp ca mới:

```text
Visit #1025  →  Hàng đợi Bác sĩ B  →  Phòng P02, số thứ tự 1
```

Khi ca chưa bắt đầu khám, Lễ tân có thể **chuyển phiếu sang hàng đợi bác sĩ khác** (phiếu giữ nguyên số và giờ phát, nên giữ đúng thứ tự) hoặc **gỡ phân công** (ca về danh sách chờ phân công), ví dụ khi một bác sĩ quá đông hoặc nghỉ đột xuất. Ca có kết quả cận lâm sàng luôn thuộc bác sĩ khám chính.

---

## 11. Nguyên tắc phân công & Ưu tiên ca có kết quả

Bảng điều phối hiển thị cho mỗi Bác sĩ:

```text
Bác sĩ
Số phòng cố định
Trạng thái (AVAILABLE / BUSY)
Số người đang chờ và danh sách theo số thứ tự (ca có kết quả, ca cấp cứu, ca vừa được gọi)
```

**Bảo vệ ca đã làm cận lâm sàng:** khi một ca vừa đủ kết quả xét nghiệm / CĐHA, hệ thống tự phát **phiếu ưu tiên** (`priority = 1`, không thu tiền) vào hàng đợi của Bác sĩ khám chính (chỉ sau ca cấp cứu). Lễ tân vẫn xếp ca mới vào hàng đợi Bác sĩ này bình thường, nhưng ca mới đứng sau; Bác sĩ khám xong ca hiện tại sẽ gọi ca có kết quả trước. Khách đã chờ xét nghiệm 15 – 30 phút không bị khách mới chen lượt, mà Lễ tân cũng không bị khóa thao tác.

> Bản trước dùng "Khóa ưu tiên" (Priority Lock): chặn Lễ tân phân ca mới khi Bác sĩ có ca vừa có kết quả. Cơ chế đó cần thiết khi mỗi Bác sĩ chỉ nhận 1 ca từ hàng đợi chung; với hàng đợi riêng, việc phát phiếu ưu tiên cho ca có kết quả là đủ.

---

## 12. Trạng thái bác sĩ

Trạng thái phục vụ tức thời của Bác sĩ được hệ thống tự động nhận diện theo thời gian thực, gồm 2 trạng thái:

```text
AVAILABLE
BUSY
```

- **`BUSY` (Đang khám):** Bác sĩ đang khám một ca (`IN_PROGRESS`, Giai đoạn 1 hoặc 2; tương đương có phiếu đang `IN_SERVICE`). Bác sĩ không được gọi thêm số khi đang khám.
- **`AVAILABLE` (Sẵn sàng):** Bác sĩ không khám ca nào và được bấm "Gọi".

Trạng thái chỉ để hiển thị và chặn Bác sĩ gọi số khi đang khám; **không dùng để quyết định Lễ tân có được phân công hay không** (Lễ tân luôn xếp được ca vào hàng đợi). *(Công thức SQL ở tài liệu State Machine, mục 3.3.)*

*(Hệ thống không cần trạng thái `OFF` vì mặc định các bác sĩ luôn có mặt làm việc đầy đủ trong phạm vi đồ án).*

---

## 13. Đợt khám – Pet Visit

Visit là **trung tâm của toàn bộ hệ thống y tế**.

Quan hệ:

```text
Pet
 │
 └── 1:N
       │
       ↓
     Visit
```

Một thú cưng có thể khám nhiều lần.

Mỗi lần khám là một Visit độc lập.

---

## 14. Thông tin Visit

Visit lưu:

- Mã Visit.
- Thú cưng.
- Appointment nếu có.
- Bác sĩ được phân công.
- Lễ tân tiếp nhận.
- Phòng khám (suy ra từ số phòng của Bác sĩ, không lưu riêng trên Visit).
- Thời gian tiếp nhận, lý do đến khám (chủ nuôi khai với Lễ tân), cờ cấp cứu.
- Trạng thái.
- Tên Bác sĩ chụp lại (snapshot) để danh sách hiển thị nhanh, không phải hỏi phân hệ tài khoản.
- *(Không lưu thông tin xếp hàng trên Visit: phiếu nằm trên Redis, lịch sử phiếu ở `queue_ticket_histories`; một Visit có thể có nhiều phiếu nối tiếp.)*
- Thời gian bắt đầu khám, chốt ca, hoàn tất, lý do hủy (lấy từ lịch sử trạng thái `pet_visit_status_histories`, không lưu thành cột riêng).

**Từ v4.0, thông tin của một lần khám được tách thành 3 phần theo người nhập và thời điểm nhập:**

| Phần | Bảng | Người nhập | Thời điểm | Nội dung |
| :--- | :--- | :--- | :--- | :--- |
| Hành chính / tiếp đón | `pet_visits` | Lễ tân | Lúc tiếp đón | Thú cưng, lịch hẹn, Bác sĩ phụ trách, Lễ tân, cấp cứu, lý do đến khám, trạng thái |
| Sinh hiệu / tiền trạm | `vital_signs` (nhiều dòng) | Bác sĩ (hoặc nhân viên được giao đo) | Đầu buổi khám, đo lại khi cần | Cân nặng, thân nhiệt, nhịp tim, nhịp thở, điểm thể trạng (BCS), màu niêm mạc, thời gian làm đầy mao mạch |
| Chuyên môn | `medical_records` (1–1) | Bác sĩ | Suốt Giai đoạn 1 và 2, khóa khi chốt ca | Bệnh sử, kết quả khám lâm sàng, chẩn đoán sơ bộ, chẩn đoán xác định, phác đồ điều trị, lời dặn, ngày tái khám |

Tách như vậy để ba người không cùng sửa một dòng dữ liệu, đo sinh hiệu nhiều lần không ghi đè lần trước, và phân quyền theo bảng (Lễ tân không sửa được chẩn đoán).

---

## 15. Trạng thái Visit (Vòng đời Đợt khám - Chu kỳ Bất đồng bộ)

Quy trình khám chữa bệnh tại phòng khám thú y **không phải là một màn hình nhập liệu CRUD tuyến tính đơn giản**, mà là một **quy trình y tế bất đồng bộ (Asynchronous Multi-stage Workflow)** chia làm 2 giai đoạn nếu có phát sinh dịch vụ cận lâm sàng:

```text
                 ┌─────────┐
                 │ WAITING │ (Chờ nộp phí khám → có phiếu trong hàng đợi Bác sĩ)
                 └────┬────┘
                      │ Bác sĩ gọi số theo phiếu, thú cưng vào phòng, bấm "Bắt đầu khám"
                      ↓
               ┌─────────────┐
        ┌───── │ IN_PROGRESS │ (Giai đoạn 1: Khám lâm sàng & Ra chỉ định)
        │      └──────┬──────┘
        │             │ 
        │ (Nếu có chỉ │ Bác sĩ gửi phiếu chỉ định Cận lâm sàng
        │  định Lab / │ Khách nộp tiền XN / CĐHA, nhận phiếu phòng
        │  CĐHA)      ↓ (Bác sĩ tạm giải phóng về AVAILABLE để khám ca khác)
        │      ┌─────────────────┐
        │      │ WAITING_RESULTS │ (Chờ máy chạy XN / Chụp chiếu 15-45 phút)
        │      └────────┬────────┘
        │               │ Phòng Cận lâm sàng nhập xong kết quả
        │               ↓
        │      ┌─────────────────┐
        │      │  RESULTS_READY  │ (Đã có đủ KQ - Phiếu ưu tiên cho Bác sĩ)
        │      └────────┬────────┘
        │               │ Bác sĩ gọi số, thú cưng vào phòng, bấm "Bắt đầu GĐ 2"
        │               ↓
        │      ┌─────────────┐
        └────> │ IN_PROGRESS │ (Giai đoạn 2: Đọc KQ, Chẩn đoán xác định & Kê đơn)
               └──────┬──────┘
                      │ Bác sĩ chốt chuyên môn & kê đơn
                      ↓
             ┌──────────────────┐
             │ WAITING_PAYMENT  │ (Thu ngân thu các hóa đơn còn lại: dịch vụ làm tại phòng)
             └────────┬─────────┘
                      │ Mọi hóa đơn dịch vụ đã PAID / CANCELLED / REFUNDED
                      ↓  (không phụ thuộc việc mua thuốc)
                ┌───────────┐
                │ COMPLETED │ (Hoàn tất, lưu bệnh án vĩnh viễn)
                └───────────┘

Nhánh rẽ khác:
- IN_PROGRESS (GĐ 1) ───(Không cần cận lâm sàng: khám thường / tiêm phòng / thủ thuật, chốt ca)──→ WAITING_PAYMENT
- WAITING_PAYMENT    ───(Bác sĩ phụ trách / Admin mở lại hồ sơ để sửa sai sót, có lý do)──────→ IN_PROGRESS

Nhánh hủy / kết thúc đặc biệt:
- WAITING            ───(Khách bỏ về / lỗi tiếp nhận – EX-03)──────────────────────────────────→ CANCELLED
- IN_PROGRESS (GĐ 1) ───(Khách từ chối khám / Chuyển viện; phí khám đã nộp không hoàn)──────→ CANCELLED
- WAITING_RESULTS    ───(Khách bỏ về giữa chừng – EX-11: hủy dịch vụ chưa làm, giữ công nợ)───→ COMPLETED
- RESULTS_READY      ───(Khách bỏ về không quay lại đọc KQ – EX-11, giữ công nợ)──────────────→ COMPLETED
```

> **Gọi số không thấy khách** (cả `WAITING` và `RESULTS_READY`) không phải là bước chuyển trạng thái: Bác sĩ gọi phiếu khác (mục 9, EX-10), ca giữ nguyên trạng thái, phiếu giữ nguyên vị trí; khách quay lại thì gọi lại.

> **Ghi chú:** Bản 2.0 cho `WAITING_RESULTS → CANCELLED` khi khách bỏ về. Từ v3.0 chuyển thành `COMPLETED` (đã có kết quả lưu bệnh án). Từ 17/11/2026 phí khám, xét nghiệm, CĐHA đã nộp trước nên thường không còn công nợ; chỉ ca cấp cứu (khám trước thu sau) mới có thể để lại công nợ. `CANCELLED` dùng khi ca bị hủy trước khi có kết quả chuyên môn.

---

## 16. WAITING – Chờ khám ban đầu

Sau khi tiếp nhận tại quầy (từ lịch hẹn hoặc khách vãng lai):
- `Visit.status = WAITING`, hóa đơn phí khám đã lập.
- **Chưa nộp phí khám:** ca chỉ hiện ở mục "Chờ thu phí khám" của Thu ngân, chưa có phiếu, chưa hiện trên màn hình Bác sĩ.
- **Đã nộp phí khám:** ca có phiếu xếp hàng trong hàng đợi riêng của Bác sĩ được chọn (hoặc danh sách chờ phân công nếu Lễ tân chưa chọn Bác sĩ), số thứ tự hiển thị trên màn hình sảnh. Thú cưng và chủ nuôi ngồi chờ trước phòng Bác sĩ. Chưa phát sinh hoạt động chuyên môn.

---

## 17. IN_PROGRESS (Giai đoạn 1) – Khám lâm sàng & Quyết định chỉ định

- Bác sĩ (không đang khám ca nào) bấm **"Gọi"** ở một phiếu (hoặc **"Gọi số tiếp theo"** để gọi phiếu đứng đầu hàng đợi của Bác sĩ). Gọi 2–3 lần không thấy thì Bác sĩ gọi phiếu khác, phiếu vắng giữ nguyên vị trí (mục 9).
- Thú cưng vào phòng khám cố định của Bác sĩ. Bác sĩ bấm **"Bắt đầu khám"** -> phiếu `IN_SERVICE`, `Visit.status = IN_PROGRESS`, dịch vụ khám (đã nộp phí lúc tiếp đón) chuyển `IN_PROGRESS`. Bác sĩ chuyển sang trạng thái bận (`BUSY`).
- Bác sĩ tiến hành **Khám lâm sàng & Đo sinh hiệu**:
  - Hỏi bệnh sử, triệu chứng phát sinh.
  - Cân, đo thân nhiệt, nhịp tim, nhịp thở, đánh giá thể trạng, niêm mạc → ghi một lần đo vào `vital_signs` (đo lại thì thêm dòng mới). Bệnh sử và nhận định lâm sàng ghi vào hồ sơ khám `medical_records` (tạo khi bấm "Bắt đầu khám").
  - Nghe tim phổi, nắn bụng, kiểm tra niêm mạc, hạch bạch huyết.
  - Ghi nhận nhận định lâm sàng ban đầu.
- **Rẽ nhánh nghiệp vụ:**
  - **Trường hợp 1 (Khám thông thường / Tiêm phòng / Tẩy giun / Thủ thuật):** Không cần cận lâm sàng -> Bác sĩ chỉ định các dịch vụ thực hiện tại phòng nếu cần (mỗi dịch vụ sinh 1 hóa đơn dịch vụ `PENDING`, **không cần thu trước**), thực hiện ngay và đánh dấu "Đã thực hiện", kết luận chẩn đoán, kê đơn thuốc mang về (nếu có) và bấm Chốt ca -> Chuyển thẳng sang `WAITING_PAYMENT`.
  - **Trường hợp 2 (Cần xét nghiệm máu / Siêu âm / X-quang):** Bác sĩ lập phiếu chỉ định dịch vụ cận lâm sàng; mỗi dịch vụ được chỉ định sinh 1 hóa đơn dịch vụ `PENDING` (chốt đơn giá, thuế suất tại thời điểm này). Khi xác nhận gửi chỉ định (yêu cầu đã nhập cân nặng, thân nhiệt), dịch vụ khám của GĐ 1 được ghi nhận hoàn thành, phiếu Bác sĩ kết thúc (`DONE`) và ca khám chuyển sang trạng thái `WAITING_RESULTS`. Khách được hướng dẫn **ra quầy nộp tiền Xét nghiệm / CĐHA**; thu xong mới được phát phiếu vào hàng đợi phòng (mục 17.1). Bác sĩ trở về `AVAILABLE` và gọi số tiếp theo trong hàng đợi của mình, tránh tình trạng tắc nghẽn phòng khám trong 15-45 phút chờ kết quả.

---

## 17.1. WAITING_RESULTS – Chờ kết quả cận lâm sàng & Quản lý 2 Hàng đợi chuyên môn độc lập

Khi Bác sĩ xác nhận gửi chỉ định, ca khám chuyển sang trạng thái `WAITING_RESULTS`. Dịch vụ kỹ thuật **chưa vào hàng đợi phòng** mà hiện ở mục *"Chờ thu tiền cận lâm sàng"* của Thu ngân. Khách nộp tiền xong, hệ thống **tự phát phiếu vào 2 Hàng đợi Cận lâm sàng độc lập** tương ứng với 2 phòng chuyên môn riêng biệt (không cần ai xếp; dịch vụ cùng phòng gộp một phiếu), theo thứ tự: phiếu cấp cứu trước, còn lại theo giờ phát phiếu (giờ nộp tiền). Khách chỉ nộp tiền một phần thì chỉ phòng có dịch vụ đã nộp được phát phiếu; dịch vụ khách không làm thì hủy kèm hóa đơn chưa thu. Ca cấp cứu được phát phiếu ngay, thu sau.

### 1. Phân tách 2 Phòng chuyên môn & 2 Hàng đợi độc lập
Hệ thống thiết kế theo mô hình phòng khám quy chuẩn:
1. **Phòng Xét nghiệm (Lab Room):**
   - Quản lý **Hàng đợi Phòng Xét nghiệm (Lab Queue)**, chỉ lọc các chỉ định có `category = 'LABORATORY'` (Tổng phân tích tế bào máu CBC, sinh hóa máu, soi phân, test nhanh truyền nhiễm).
   - Nhân sự phụ trách: Kỹ thuật viên / Bác sĩ chuyên trách phòng Lab.
2. **Phòng Chẩn đoán hình ảnh (Imaging Room):**
   - Quản lý **Hàng đợi Chẩn đoán hình ảnh (Imaging Queue)**, chỉ lọc các chỉ định có `category = 'IMAGING'` (Siêu âm ổ bụng, siêu âm tim, chụp X-quang tim phổi / xương khớp).
   - Nhân sự phụ trách: Bác sĩ chuyên trách chẩn đoán hình ảnh.
- **Nguyên tắc vận hành:** Hai phòng hoạt động hoàn toàn độc lập và song song. Hàng đợi của phòng này không bao giờ bị khóa hoặc chờ đợi cứng nhắc bởi phòng kia.

### 2. Thuật toán sắp xếp thứ tự ưu tiên trong từng Hàng đợi
Trong mỗi hàng đợi (Lab Queue & Imaging Queue), hệ thống sắp xếp tự động:
- **Ưu tiên 1 (Tuyệt đối):** Phiếu của ca **Cấp cứu khẩn cấp** (`priority = 2`, phát ngay không chờ nộp tiền) tự động nhảy lên vị trí đầu tiên của hàng đợi kèm viền đỏ nhấp nháy trên màn hình. Kỹ thuật viên / Bác sĩ CĐHA bắt buộc phải tiếp nhận lấy mẫu hoặc chụp chiếu ngay lập tức.
- **Ưu tiên 2:** Các phiếu thông thường được xếp theo **giờ phát phiếu, tức giờ khách nộp tiền (FIFO - Nộp trước làm trước)**.

### 3. Quy trình điều phối tối ưu khi chỉ định đồng thời 2 dịch vụ (Quy trình song song)
Khi một ca bệnh được chỉ định đồng thời cả Xét nghiệm máu và Siêu âm/X-quang và khách đã nộp tiền, hệ thống phát 2 phiếu, ca bệnh xuất hiện đồng thời trên cả 2 hàng đợi (dịch vụ ở trạng thái `PENDING`):
- **Chỉ dẫn lộ trình khuyến nghị (Parallel Flow):** Hệ thống in phiếu chỉ định và gửi thông báo qua ứng dụng hướng dẫn chủ nuôi:
  > **Bước 1:** Ưu tiên đưa thú cưng vào **Phòng Xét nghiệm lấy mẫu máu trước** (thao tác lấy ven chỉ mất 2–3 phút).  
  > **Bước 2:** Kỹ thuật viên nạp mẫu vào máy phân tích tự động (thời gian máy chạy tự động mất 15–20 phút).  
  > **Bước 3:** Trong lúc máy xét nghiệm máu đang tự động phân tích ngầm, chủ nuôi đưa thú cưng sang **Phòng Chẩn đoán hình ảnh để thực hiện Siêu âm hoặc Chụp X-quang** (mất 10–15 phút).  
  > **Bước 4:** Khi siêu âm hoàn tất và tải ảnh lên hệ thống (`COMPLETED`), máy xét nghiệm máu bên phòng Lab cũng vừa in kết quả $\rightarrow$ Kỹ thuật viên Lab nhập chỉ số máu (`COMPLETED`).
- **Lợi ích vận hành:** Hai quy trình diễn ra gần như song song. Tổng thời gian chờ đợi rút ngắn chỉ còn khoảng 20 phút (thay vì 35–45 phút nếu làm tuần tự nối tiếp).

### 4. Cơ chế Điều phối liên phòng & Tránh xung đột gọi số (Cross-room Coordination)
Để giải quyết tình huống phòng CĐHA gọi số đúng lúc thú cưng đang lấy máu bên phòng Xét nghiệm:
- **Huy hiệu trạng thái liên phòng (Cross-room Badge):** Trên màn hình Hàng đợi CĐHA, ca khám hiển thị huy hiệu trực quan:
  - 🟡 `[Đang lấy máu bên phòng Lab]`: Khi KTV Lab đã bấm *"Bắt đầu thực hiện"* (lịch sử dịch vụ ghi `action = START_PROCESSING`) nhưng chưa bấm *"Đã lấy mẫu"*.
  - 🟢 `[Đã lấy máu xong, sẵn sàng chụp]`: Khi KTV Lab đã nạp mẫu vào máy và bấm *"Đã lấy mẫu"* (`action = SAMPLE_COLLECTED`), thú cưng đã rời phòng Lab.
  - Hai thao tác này giúp phân biệt "đang lấy máu" với "máy đang chạy" (cả hai đều là `IN_PROGRESS`), không cần thêm cột trạng thái.
- **Gọi phiếu khác, không làm nghẽn phòng máy:** Nếu đến lượt phiếu này trong hàng đợi CĐHA nhưng thú cưng chưa sang (đang lấy máu bên Lab), Bác sĩ CĐHA bấm **"Gọi"** ở phiếu khác:
  - Dòng dịch vụ CĐHA **giữ nguyên là `PENDING`** (chưa thực hiện, không tốn vật tư), phiếu giữ nguyên vị trí trong hàng đợi.
  - Phòng gọi ngay ca khác vào phòng siêu âm $\rightarrow$ **Phòng CĐHA không bao giờ bị treo!**
  - Thú cưng lấy máu xong sang phòng CĐHA thì Bác sĩ CĐHA bấm *"Gọi lại"* rồi *"Bắt đầu chụp"* $\rightarrow$ Dịch vụ CĐHA chuyển sang `IN_PROGRESS`.

### 5. Vòng đời chuyển trạng thái của dịch vụ cận lâm sàng (`visit_service_details.status`)
1. **`PENDING` (Chờ thực hiện):** Bác sĩ lâm sàng vừa gửi chỉ định. Chưa nộp tiền thì dịch vụ ở mục "Chờ thu tiền cận lâm sàng"; nộp xong thì dịch vụ thuộc một phiếu trong hàng đợi của phòng chuyên môn.
2. **Khi nhân viên bấm gọi số vào phòng:** Dịch vụ **VẪN GIỮ NGUYÊN `PENDING`** vì thú cưng chưa bước chân vào phòng, chưa phát sinh hao phí vật tư y tế.
3. **`IN_PROGRESS` (Đang thực hiện):** Thú cưng đã vào phòng, nhân viên bấm *"Bắt đầu thực hiện"* (lấy máu nạp máy hoặc bắt đầu quét siêu âm).
4. **`COMPLETED` (Đã hoàn tất):** Nhân viên nhập đầy đủ các chỉ số đo đạc hoặc tải tệp ảnh chẩn đoán lên và nhấn nút **"Lưu & Xác nhận kết quả"**.
5. **`CANCELLED` (Đã hủy):** Chỉ định bị hủy bỏ do chủ nuôi từ chối / không nộp tiền, Bác sĩ đổi hướng xử lý hoặc phòng khám không thực hiện được. Hóa đơn dịch vụ tương ứng: chưa thu → `CANCELLED`; đã thu mà khách tự hủy → giữ `PAID` (không hoàn); đã thu mà phòng khám không làm được → `REFUNDED` (hoàn tiền).

> Khi khách vắng, dịch vụ vẫn `PENDING`, phiếu vẫn ở đúng vị trí trong hàng đợi; nhân viên gọi phiếu khác, hệ thống không đổi thứ tự và không ghi lịch sử.

### 6. Cơ chế xử lý khách vắng mặt khi gọi số (Gọi ca khác / Gọi lại)
Khi gọi số vào phòng mà khách không có mặt (khách ra ngoài, cho thú cưng đi dạo, nghe điện thoại):
1. **Gọi 2–3 lần:** Hệ thống hiển thị thông báo gọi số trên màn hình sảnh và gửi thông báo đến ứng dụng của chủ nuôi, mỗi lần cách nhau khoảng 60 giây.
2. **Gọi phiếu khác:** Khách vẫn chưa vào, nhân viên bấm nút **"Gọi"** ở một phiếu khác trong danh sách:
   - Trạng thái dịch vụ `visit_service_details.status` **GIỮ NGUYÊN LÀ `PENDING`**.
   - Phiếu vắng **giữ nguyên vị trí** trong hàng đợi (không bị rút khỏi hàng đợi, không đổi thứ tự, không đếm số lần vắng) $\rightarrow$ Không làm chậm trễ các bệnh nhân phía sau và không xảy ra vòng lặp gọi đi gọi lại hai ca đầu hàng.
   - Hệ thống gửi thông báo đến ứng dụng / Portal của chủ nuôi của ca được gọi (không tích hợp SMS).
3. **Khi khách quay lại:** Nhân viên nhận thông báo hoặc khách báo tại quầy, nhân viên bấm **"Gọi lại"** ở đúng phiếu đó rồi "Bắt đầu" như bình thường. Hệ thống không theo dõi việc khách quay lại.
4. **Xử lý cuối ngày (Khách bỏ về hẳn):** Nếu khách vắng nhiều lần và Lễ tân liên hệ điện thoại xác nhận không quay lại $\rightarrow$ Thực hiện thao tác **"Đóng ca / Khách bỏ về"** (chỉ khi không còn dịch vụ đang `IN_PROGRESS`): Các dịch vụ chưa làm chuyển `CANCELLED` (hóa đơn chưa thu bị hủy theo; **đã nộp thì không hoàn**), phiếu còn chờ bị hủy; hóa đơn của các dịch vụ đã làm mà chưa thu (ca cấp cứu) giữ `PENDING` làm công nợ; ca khám chuyển `COMPLETED` và kết quả được lưu vào bệnh án.

### 7. Xử lý ngoại lệ: Hủy 1 trong 2 dịch vụ giữa chừng
- **Kịch bản:** Thú cưng đã làm xong Xét nghiệm máu (`COMPLETED`), nhưng khi sang phòng CĐHA thì thú cưng quá giãy giụa hoặc chủ nuôi đổi ý xin hủy không siêu âm nữa (hoặc máy siêu âm hỏng).
- **Xử lý:** Bác sĩ CĐHA chọn thao tác **"Hủy dịch vụ"** kèm lý do $\rightarrow$ Dịch vụ Siêu âm chuyển sang `CANCELLED` và rời phiếu.
- **Kích hoạt ca khám:** Hệ thống kiểm tra: Tất cả các dịch vụ cận lâm sàng của ca khám này đều đã đạt `COMPLETED` hoặc `CANCELLED` $\rightarrow$ Tự động chuyển ca khám sang `pet_visits.status = 'RESULTS_READY'` để trả về cho Bác sĩ khám chính đọc kết quả xét nghiệm máu đã làm.
- **Hóa đơn:** Siêu âm đã nộp tiền trước. Khách tự xin hủy → hóa đơn **giữ `PAID`, không hoàn tiền**. Phòng khám không làm được (máy hỏng) → hóa đơn chuyển `REFUNDED`, Thu ngân trả lại tiền. Nếu khách chưa nộp tiền siêu âm (chỉ nộp xét nghiệm) thì hóa đơn siêu âm chuyển `CANCELLED`.

> **Cơ chế kích hoạt tự động sang cấp độ Đợt khám (`pet_visits`):**  
> Mỗi khi một dịch vụ chuyển sang `COMPLETED` hoặc `CANCELLED`, hệ thống tự động kiểm tra: Nếu **không còn dịch vụ nào ở trạng thái `PENDING` hoặc `IN_PROGRESS`**, hệ thống tự động cập nhật `pet_visits.status = 'RESULTS_READY'`, phát phiếu ưu tiên (`priority = 1`, không thu tiền) vào hàng đợi của Bác sĩ khám chính (sau ca cấp cứu) và thông báo cho Bác sĩ.

---

## 17.2. RESULTS_READY – Đã có kết quả cận lâm sàng & Quy trình xử lý hàng đợi tái khám

Khi nhân sự phòng Lab / CĐHA nhập đầy đủ kết quả đo đạc (WBC, RBC, HGB...) hoặc tải ảnh chụp siêu âm/X-quang và bấm **"Xác nhận hoàn tất kết quả"**:
- Hệ thống tự động chuyển trạng thái ca khám sang `RESULTS_READY`.
- Quy trình điều phối tái khám diễn ra qua **3 bước**:

### Bước 1: Phát phiếu ưu tiên cho Bác sĩ khám chính
- Hệ thống phát **phiếu `DOCTOR` mới** cho Bác sĩ khám chính với `priority = 1`, **không thu tiền** (đã thu ở lượt trước), nên ca đứng **đầu hàng đợi**, chỉ sau ca cấp cứu. Nhiều ca cùng có kết quả thì ca có kết quả trước đứng trước (theo giờ phát phiếu).
- **Trên màn hình Bác sĩ:** Huy hiệu thông báo nhẹ (Notification Badge): *"Ca khám [Mã Visit - Tên Pet] đã có kết quả cận lâm sàng"*, không ngắt quãng ca đang khám.
- **Trên màn hình phòng chờ / Ứng dụng của chủ nuôi:** *"Bé [Tên Pet] đã có đầy đủ kết quả cận lâm sàng. Bác sĩ [Tên Bác sĩ] sẽ mời bạn và bé vào phòng ngay sau ca đang khám. Xin vui lòng chờ tại sảnh."*
- Lễ tân **không bị khóa**: vẫn xếp ca mới vào hàng đợi Bác sĩ này; ca mới đứng sau ca có kết quả.

### Bước 2: Bác sĩ gọi số tiếp theo
- Khám xong ca hiện tại (chốt ca hoặc gửi đi xét nghiệm), Bác sĩ bấm **"Gọi số tiếp theo"**. Hệ thống gọi phiếu của ca có kết quả (đang đứng đầu hàng đợi):
  - Màn hình sảnh và ứng dụng của chủ nuôi: *"Mời thú cưng [Tên Pet] của chủ nuôi [Tên Khách] vào lại phòng khám [Số phòng] gặp Bác sĩ [Tên Bác sĩ]"*.
  - Ca vẫn `RESULTS_READY` cho tới khi thú cưng vào phòng.

### Bước 3: Thú cưng vào phòng, Bác sĩ bấm "Bắt đầu Giai đoạn 2"
- Phiếu chuyển `IN_SERVICE`, ca khám chuyển sang trạng thái `IN_PROGRESS` (Giai đoạn 2), Bác sĩ chuyển sang `BUSY`, màn hình mở Bệnh án tổng hợp.

> **Xử lý tình huống khách chưa vào phòng ngay:**  
> - **Khi khách vắng mặt lúc gọi số:** Gọi 2–3 lần không thấy, Bác sĩ bấm **"Gọi"** phiếu khác (EX-10): ca giữ `RESULTS_READY`, phiếu giữ nguyên vị trí (vẫn đứng đầu hàng đợi); khách quay lại thì "Gọi lại".  
> - **Khi khách quay lại phòng khám:** Khách chờ tới lượt; Bác sĩ gọi đến thì tiếp tục Bước 3.  
> - **Trường hợp khách bỏ về hẳn (không quay lại đọc kết quả):** Sau khi Lễ tân liên hệ điện thoại xác nhận khách đã bỏ về hoặc đến hết ngày làm việc, Lễ tân hoặc Bác sĩ chọn thao tác **"Đóng ca / Khách bỏ về"**:  
>   + Hệ thống khóa hồ sơ chuyên môn, lưu trữ vĩnh viễn các kết quả xét nghiệm/CĐHA đã thực hiện vào Lịch sử bệnh án của thú cưng.  
>   + Ca chuyển `COMPLETED`, phiếu bị hủy và ca rời khỏi hàng đợi. **Không lập hóa đơn mới, không hoàn tiền**: phí khám, xét nghiệm, CĐHA đã nộp trước; hóa đơn của dịch vụ đã làm mà chưa thu (ca cấp cứu) giữ `PENDING` làm công nợ, thu ở lần khách đến sau (đảm bảo không thất thoát doanh thu của phòng khám).

---

## 17.3. IN_PROGRESS (Giai đoạn 2) – Đọc kết quả, Chẩn đoán xác định & Kê đơn

- Bệnh nhân bước vào phòng khám. Màn hình Bác sĩ tự động mở giao diện Bệnh án tổng hợp:
  - Xem bảng chỉ số máu đã được hệ thống tự động so sánh với khoảng tham chiếu chuẩn theo loài (chỉ rõ chỉ số nào `LOW`, `NORMAL`, `HIGH`).
  - Xem hình ảnh siêu âm / X-quang và kết luận hình thái học.
- Bác sĩ tổng hợp với triệu chứng lâm sàng ban đầu để đưa ra:
  - **Chẩn đoán xác định** (`medical_records.final_diagnosis`; chẩn đoán sơ bộ của Giai đoạn 1 ở `preliminary_diagnosis`).
  - **Phác đồ điều trị**, lời dặn, ngày tái khám (`medical_records.treatment_plan`, `doctor_advice`, `follow_up_date`).
  - **Thực hiện thêm dịch vụ tại phòng** nếu cần (tiêm thuốc, truyền dịch, thủ thuật – mỗi dịch vụ sinh 1 hóa đơn dịch vụ, làm ngay, thu khi chốt ca).
  - **Kê đơn thuốc điện tử** (`prescriptions` – hiển thị tồn kho để tham khảo, chỉ cảnh báo nếu không đủ vì khách có thể mua ngoài).
- Bác sĩ thực hiện thao tác **Chốt đợt khám** -> phiếu `DONE` (ghi lịch sử phiếu), `Visit.status = WAITING_PAYMENT`. Hồ sơ khám và đơn thuốc được khóa lại; nếu có đơn thuốc, hệ thống phát sự kiện để quầy thuốc tạo hóa đơn thuốc nháp.
- **Sau khi chốt ca:** Bác sĩ trở về `AVAILABLE` và bấm "Gọi" (hoặc "Gọi số tiếp theo") để gọi bệnh nhân trong hàng đợi của mình (ca có kết quả khác, ca cấp cứu hoặc ca mới).

---

---

## 18. Khám lâm sàng chi tiết

Bác sĩ thực hiện thăm khám toàn diện:
- Quan sát tri giác, dáng đi, thể trạng (gầy/béo).
- Khám mắt, mũi, miệng, tai, răng miệng.
- Nghe tim phổi (nhịp tim, âm phổi bất thường).
- Sờ nắn hạch ngoại vi, sờ nắn ổ bụng (kiểm tra khối u, đau bụng).
- Đo các chỉ số sinh hiệu: Thân nhiệt (°C), Cân nặng (kg).
- Ghi nhận triệu chứng lâm sàng vào bệnh án điện tử.

---

## 19. Chỉ định dịch vụ

Bác sĩ quyết định có cần dịch vụ bổ sung hay không.

Ví dụ:

```text
Khám
 ↓
Nghi ngờ bệnh tiêu hóa
 ↓
Chỉ định:
 ├── Xét nghiệm máu
 └── Siêu âm
```

Mỗi dịch vụ được tạo thành một dòng chỉ định **kèm đúng một hóa đơn dịch vụ**, trong cùng một giao dịch:

```text
visit_service_details  ── (1 : 1) ──  service_invoices (PENDING, snapshot unit_price, vat_rate)
```

Dòng chỉ định chỉ chứa thông tin chuyên môn (dịch vụ, số lượng, trạng thái thực hiện); thông tin tiền nằm ở hóa đơn dịch vụ; thông tin xếp hàng (nếu là dịch vụ Xét nghiệm / CĐHA) nằm ở phiếu xếp hàng trên Redis.

**Thời điểm thu tiền** do **nhóm dịch vụ** quyết định (bảng danh mục `service_categories`: cột `requires_prepayment` và loại hàng đợi `queue_type`):

| Nhóm dịch vụ | Thu trước? | Vào hàng đợi khi nào |
| :--- | :---: | :--- |
| Khám lâm sàng (`EXAMINATION`) | Có | Nộp phí khám xong → phiếu hàng đợi Bác sĩ |
| Xét nghiệm (`LABORATORY`), CĐHA (`IMAGING`) | Có | Nộp tiền xong → phiếu hàng đợi phòng XN / CĐHA |
| Làm tại phòng (`VACCINATION`, `DEWORMING`, `EXTERNAL_PARASITE`, `INJECTION_INFUSION`, `PROCEDURE`, `SURGERY`) | Không | Không qua hàng đợi; Bác sĩ làm ngay, thu khi chốt ca |

Chính sách nằm ở dữ liệu danh mục nên đổi được mà không phải sửa quy trình hay sửa cấu trúc bảng (ví dụ sau này muốn thu trước tiền phẫu thuật thì chỉ cần bật cờ cho nhóm `SURGERY`; thêm nhóm dịch vụ mới chỉ cần thêm một dòng danh mục).

---

## 20. Danh mục dịch vụ & Phân tích sự khác biệt về quy trình thực hiện

Hệ thống quản lý các nhóm dịch vụ kỹ thuật:

```text
EXAMINATION          (Khám lâm sàng tổng quát / chuyên sâu)
VACCINATION          (Tiêm phòng vaccine)
DEWORMING            (Tẩy giun sán)
EXTERNAL_PARASITE    (Trị ve, rận, bọ chét)
INJECTION_INFUSION   (Tiêm thuốc, truyền dịch)
LABORATORY           (Xét nghiệm máu, sinh hóa, nước tiểu)
IMAGING              (Siêu âm, Chụp X-quang)
SURGERY              (Phẫu thuật ngoại khoa)
PROCEDURE            (Thủ thuật: cắt chỉ, nẹp xương, rửa vết thương)
```

> **TRẢ LỜI CÂU HỎI NGHIỆP VỤ: "CÁC DỊCH VỤ CÓ TIẾN HÀNH GIỐNG NHAU KHÔNG?"**  
> **Hoàn toàn KHÔNG.** Mỗi nhóm dịch vụ có bản chất y tế, không gian thực hiện, thiết bị chuyên dụng, chu kỳ thời gian và cấu trúc dữ liệu đầu ra hoàn toàn khác nhau. Hệ thống chia thành **3 quy trình dịch vụ chuyên biệt**:

---

### Quy trình 1: Nhóm Cận lâm sàng Xét nghiệm (`LABORATORY`)
- **Không gian & Thiết bị:** Phòng xét nghiệm riêng biệt với máy phân tích huyết học/sinh hóa tự động.
- **Tiến hành:**
  0. Khách nộp tiền xét nghiệm tại quầy, nhận phiếu vào hàng đợi phòng Xét nghiệm.
  1. Điều dưỡng/Kỹ thuật viên gọi số, lấy mẫu máu/bệnh phẩm từ thú cưng.
  2. Mẫu được nạp vào máy chạy tự động (mất từ 15 – 30 phút).
  3. Nhân sự phòng Lab mở màn hình *"Chỉ định chờ thực hiện"*, hệ thống hiển thị các chỉ số thuộc gói xét nghiệm (`service_lab_test_items`); nhân sự nhập giá trị đo thực tế (`WBC`, `RBC`, `HGB`, `PLT`, `Glucose`...).
- **Đặc thù nghiệp vụ:**
  - Hệ thống **tự động đối chiếu theo loài (`species_id`: Chó khác Mèo)** để hiển thị đánh giá: `LOW` (Thấp), `NORMAL` (Bình thường), `HIGH` (Cao). Nhãn này được tính khi hiển thị, không lưu cột riêng.
  - Snapshot khoảng tham chiếu (`min_value_snapshot`, `max_value_snapshot`) vào kết quả để bảo toàn lịch sử y khoa.

---

### Quy trình 2: Nhóm Chẩn đoán hình ảnh (`IMAGING` - Siêu âm, X-quang)
- **Không gian & Thiết bị:** Phòng tối máy siêu âm màu hoặc phòng chì chụp X-quang kỹ thuật số chống bức xạ.
- **Tiến hành:**
  0. Khách nộp tiền siêu âm / X-quang tại quầy, nhận phiếu vào hàng đợi phòng CĐHA.
  1. Thú cưng được đưa vào phòng CĐHA, cố định tư thế (cạo lông vùng bụng nếu siêu âm, đặt lên bàn chụp nếu X-quang).
  2. Bác sĩ/KTV chuyên trách thực hiện quét đầu dò hoặc bấm tia X.
  3. Bác sĩ quan sát hình ảnh, nhập **mô tả tổn thương hình thái học** và **kết luận chẩn đoán hình ảnh**.
  4. Tải các tệp hình ảnh thực tế (JPEG/PNG/DICOM) lên hệ thống, lưu trên Docker Volume `/app/uploads/imaging/` của `clinical-service`.
- **Đặc thù nghiệp vụ:** Đầu ra là hình ảnh trực quan và kết luận giải phẫu, không phải là các chỉ số số học như xét nghiệm.

---

### Quy trình 3: Nhóm Dịch vụ thực hiện tại phòng khám (`VACCINATION`, `DEWORMING`, `EXTERNAL_PARASITE`, `INJECTION_INFUSION`, `PROCEDURE`, `SURGERY`)
- **Không gian & Thiết bị:** Tiến hành ngay tại phòng khám của Bác sĩ.
- **Tiến hành:**
  1. **Khám sàng lọc bắt buộc:** Bác sĩ đo nhiệt độ, kiểm tra thể trạng. Thú cưng phải hoàn toàn khỏe mạnh, không sốt, không tiêu chảy mới được tiêm.
  2. Lấy vaccine/thuốc từ tủ bảo quản lạnh chuyên dụng (2-8°C).
  3. Thực hiện tiêm dưới da/bắp thịt hoặc cho uống thuốc tẩy giun, rồi bấm *"Đã thực hiện"*.
- **Đặc thù nghiệp vụ:**
  - Không đi qua hàng đợi cận lâm sàng; Bác sĩ khám chính tự thực hiện ngay trong phòng, **không cần thu tiền trước** (thu khi chốt ca).
  - **Tính tiền trọn gói:** Giá dịch vụ đã bao gồm vaccine / thuốc / vật tư dùng ngay tại chỗ (xem mục 21). Mỗi dịch vụ có 1 hóa đơn dịch vụ.

---

## 21. Quy tắc tách biệt chi phí Dịch vụ và Thuốc

Hệ thống quản lý hai dòng doanh thu bằng **hai loại hóa đơn độc lập**:

| Loại chi phí | Gồm những gì | Chứng từ | Khách có bắt buộc trả tại phòng khám? |
| :--- | :--- | :--- | :--- |
| **Dịch vụ** | Phí khám, cận lâm sàng, dịch vụ thực hiện tại phòng (tiêm phòng, tẩy giun, tiêm thuốc, truyền dịch, thủ thuật…) **kể cả thuốc / vaccine / vật tư dùng ngay tại chỗ** | Hóa đơn dịch vụ (`service_invoices`), mỗi dịch vụ một hóa đơn | Có – điều kiện để đợt khám hoàn tất |
| **Thuốc mang về** | Thuốc trong đơn thuốc Bác sĩ kê để khách dùng tại nhà | Hóa đơn thuốc (`medicine_invoices`), hệ thống tự tạo **bản nháp** khi Bác sĩ chốt ca, tối đa một hóa đơn cho một đơn thuốc | Không – khách mua tại phòng khám (thu hóa đơn nháp) hoặc mua ngoài (hủy hóa đơn nháp) |

```text
- Tiêm vaccine:
  └── Dịch vụ "Tiêm vaccine 7 bệnh" (giá trọn gói gồm khám sàng lọc + lọ vaccine) ──→ Hóa đơn dịch vụ

- Truyền dịch:
  └── Dịch vụ "Truyền dịch" (gồm công đặt catheter + chai dịch + dây truyền)       ──→ Hóa đơn dịch vụ

- Tẩy giun tại phòng:
  └── Dịch vụ "Tẩy giun" (gồm viên thuốc cho uống tại chỗ)                        ──→ Hóa đơn dịch vụ

- Thuốc kháng sinh uống 7 ngày tại nhà:
  └── Đơn thuốc ──(chốt ca)──→ Hóa đơn thuốc nháp ──(khách mua tại phòng khám)──→ Thu tiền + trừ tồn kho
                                                └─(khách mua ngoài)──────────→ Hủy nháp, in đơn thuốc
```

**Vì sao thuốc dùng tại chỗ tính vào giá dịch vụ:** thuốc đã tiêm / đã cho uống ngay trong phòng không thể "mua ngoài", nên không thể đi theo luồng hóa đơn thuốc tùy chọn. Tính trọn gói giúp mọi khoản bắt buộc đều nằm ở hóa đơn dịch vụ. Lượng vaccine / vật tư tiêu hao tại phòng được Quản trị viên cân chỉnh kho định kỳ bằng giao dịch `ADJUSTMENT` (ghi chú rõ lý do), còn tồn kho thuốc bán theo đơn được trừ tự động khi bán.

Nhờ đó phòng khám có thể quản lý:
- Doanh thu dịch vụ (từ hóa đơn dịch vụ đã thanh toán).
- Doanh thu bán thuốc và tồn kho dược phẩm (từ hóa đơn thuốc và nhật ký kho) một cách độc lập, chính xác.

---

## 22. Xét nghiệm máu & Quy tắc đối chiếu tham chiếu theo loài

Khi chỉ định gói dịch vụ xét nghiệm (ví dụ `CBC - Tổng phân tích tế bào máu`), hệ thống xác định các chỉ số đo đạc thành phần:

```text
CBC
├── WBC  (Bạch cầu)
├── RBC  (Hồng cầu)
├── HGB  (Huyết sắc tố)
├── HCT  (Dung tích hồng cầu)
└── PLT  (Tiểu cầu)
```

### Khoảng tham chiếu sinh lý phụ thuộc theo loài (`Species`)
Khoảng tham chiếu của Chó và Mèo hoàn toàn khác biệt về mặt y khoa:

```text
Chỉ số WBC (Bạch cầu):
├── Chó: Ngưỡng bình thường: 6.00  - 17.00 (10^9/L)
└── Mèo: Ngưỡng bình thường: 5.50  - 19.50 (10^9/L)

Chỉ số PLT (Tiểu cầu):
├── Chó: Ngưỡng bình thường: 200.00 - 500.00 (10^9/L)
└── Mèo: Ngưỡng bình thường: 300.00 - 700.00 (10^9/L)
```

Khi nhập giá trị đo được (ví dụ đo máu Chó có `WBC = 21.0`), hệ thống lưu giá trị đo cùng khoảng tham chiếu snapshot (`min_value_snapshot = 6.00`, `max_value_snapshot = 17.00`). Khi hiển thị, hệ thống so sánh và tô nhãn `HIGH` (đỏ). **Nhãn không được lưu thành cột** (`evaluation` đã bỏ) vì là giá trị dẫn xuất: nếu KTV sửa lại giá trị đo mà nhãn lưu sẵn không được cập nhật, dữ liệu sẽ mâu thuẫn.

---

## 23. Snapshot Reference Range & Snapshot Đơn giá

Nhằm bảo toàn tính pháp lý và lịch sử bệnh án:
- **Snapshot Tham chiếu:** Khi lưu kết quả xét nghiệm, hệ thống sao chép `min_value` và `max_value` của loài tại thời điểm đó vào `lab_test_results.min_value_snapshot` / `max_value_snapshot`. Nếu sau này Quản trị viên điều chỉnh cấu hình tham chiếu, các kết quả cũ vẫn giữ nguyên đánh giá gốc.
- **Bảng giá có lịch sử (v4.0):** giá dịch vụ (`service_prices`) và giá thuốc (`medicine_prices`) lưu thành từng dòng có thời điểm bắt đầu / kết thúc hiệu lực. Đổi giá = đóng dòng đang áp dụng và thêm dòng mới; không sửa, không xóa dòng giá cũ, nên luôn tra được giá ở mọi thời điểm và đặt trước được giá cho ngày sau.
- **Snapshot Đơn giá dịch vụ:** Đơn giá và thuế suất của dòng giá đang hiệu lực được chụp vào **hóa đơn dịch vụ** (`service_invoices.unit_price`, `vat_rate`) tại thời điểm Bác sĩ chỉ định (phí khám: thời điểm tiếp đón).
- **Snapshot Đơn giá thuốc:** Đơn giá và thuế suất của dòng giá thuốc đang hiệu lực được chụp vào **chi tiết hóa đơn thuốc** (`medicine_invoice_items.unit_price`, `vat_rate`); khi Thu ngân xác nhận thu tiền, giá được cập nhật theo dòng giá hiện hành một lần cuối. Đơn thuốc của Bác sĩ không chứa giá.

---

## 24. Chẩn đoán cuối cùng

Sau khi có đủ kết quả:

```text
Khám + Xét nghiệm + CĐHA + Theo dõi ───→ Chẩn đoán
```

Bác sĩ cập nhật trên hồ sơ khám (`medical_records`):

- Chẩn đoán xác định (giữ nguyên chẩn đoán sơ bộ của Giai đoạn 1 để đối chiếu).
- Hướng điều trị.
- Lời dặn.
- Ngày hẹn tái khám / kế hoạch theo dõi nếu cần.

---

## 25. Kê đơn

Một Visit có tối đa một Prescription.

```text
Visit
  │
  └── Prescription
          │
          ├── Medicine A
          ├── Medicine B
          └── Medicine C
```

Cấu trúc CSDL:

```text
clinical-service                         billing-pharmacy-service
prescriptions                            medicines (thông tin, quy cách)
       │                                    ├── medicine_ingredients (thành phần)
       ↓                                    ├── medicine_prices (lịch sử giá)
prescription_items ── medicine_id ───────→  └── medicine_stocks (tồn kho)
   (chụp lại tên thuốc, đơn vị)
```

Từ v4.0, **đơn thuốc thuộc phân hệ khám** (`clinical-service`), cùng nơi với hồ sơ khám: kê đơn là việc chuyên môn của Bác sĩ, sửa được khi đang khám và khóa khi chốt ca. Mỗi dòng đơn trỏ tới thuốc trong danh mục của quầy thuốc và **chụp lại tên thuốc, đơn vị tính** lúc kê, nên bệnh án luôn đọc được kể cả khi thuốc đổi tên hay ngừng kinh doanh. Bác sĩ tìm thuốc qua danh mục của quầy thuốc (thấy thành phần, quy cách, tồn kho tham khảo).

Mỗi `prescription_item` lưu:

- Thuốc (mỗi thuốc chỉ xuất hiện 1 lần trong một đơn).
- Số lượng kê.
- Liều dùng.
- Số lần/ngày.
- Số ngày.
- Hướng dẫn sử dụng.

**Đơn thuốc là chỉ định chuyên môn, không phải chứng từ tiền:** không lưu đơn giá, không có trạng thái cấp phát. Đơn thuốc dành cho **thuốc mang về**; khách được quyền mua tại quầy thuốc phòng khám (mục 31) hoặc mua ở nơi khác theo đơn in / đơn trên Portal. Khi kê, hệ thống hiển thị tồn kho để Bác sĩ tham khảo và chỉ cảnh báo nếu không đủ, không chặn lưu đơn.

---

## 26. Snapshot giá

**Giá thuốc** lấy từ bảng giá có lịch sử và được chốt vào hóa đơn thuốc khi khách mua tại phòng khám:

```text
medicine_prices:  50.000 đ, VAT 5%, hiệu lực 01/01/2026 → (đang áp dụng)
Medicine Invoice Item: unit_price = 50.000, vat_rate = 0.05
```

Ngày 01/12/2026 Quản trị viên đổi giá:

```text
medicine_prices:  50.000 đ, hiệu lực 01/01/2026 → 01/12/2026   (đóng lại, không sửa số tiền)
                  60.000 đ, hiệu lực 01/12/2026 → (đang áp dụng)
```

Hóa đơn thuốc cũ vẫn giữ nguyên `unit_price = 50.000`; báo cáo vẫn biết giá niêm yết của từng giai đoạn.

**Giá dịch vụ** lấy từ `service_prices` đang hiệu lực, chốt khi Bác sĩ chỉ định (phí khám: khi tiếp đón), vào hóa đơn dịch vụ:

```text
service_prices:  200.000 đ, VAT 0%, hiệu lực 01/01/2026 → (đang áp dụng)
Service Invoice: unit_price = 200.000, vat_rate = 0.00
```

---

## 27. Chốt chuyên môn

Khi bác sĩ hoàn thành công việc:

```text
IN_PROGRESS ───→ WAITING_PAYMENT
```

Bác sĩ thực hiện thao tác: **Chốt đợt khám / Chuyển thanh toán**.

Sau khi chốt:

- Không được sửa tùy ý kết quả.
- Không được thêm thuốc.
- Không được thêm dịch vụ.
- Không được sửa chẩn đoán.

Nếu phát hiện sai sót, cần có nghiệp vụ **mở lại Visit** bởi người có thẩm quyền:

- **Người thực hiện:** Bác sĩ phụ trách ca hoặc Quản trị viên.
- **Điều kiện:** Visit đang `WAITING_PAYMENT` (chưa `COMPLETED`); Bác sĩ không đang khám ca khác; bắt buộc nhập lý do (ghi vào lịch sử trạng thái).
- **Kết quả:** `WAITING_PAYMENT → IN_PROGRESS`. Hóa đơn dịch vụ đã thanh toán giữ nguyên; dịch vụ bị bỏ thì hủy kèm hóa đơn của nó; dịch vụ thêm mới được lập hóa đơn mới. Đơn thuốc: hệ thống hỏi quầy thuốc (đọc) trạng thái hóa đơn thuốc của đơn; nếu đã `PAID` thì không được sửa đơn thuốc; nếu còn nháp `PENDING` thì được sửa, khi chốt lại hệ thống phát lại sự kiện đơn thuốc và quầy thuốc **cập nhật lại hóa đơn nháp** theo đơn mới. Bác sĩ sửa xong chốt lại.

---

## 28. Tính tiền theo hóa đơn

Hệ thống **không lưu tổng tiền** ở bất kỳ bảng nào; mọi số tiền đều được tính từ dữ liệu gốc (đảm bảo chuẩn hóa, không có thuộc tính dẫn xuất):

```text
Tiền 1 hóa đơn dịch vụ = số lượng × đơn giá × (1 + thuế suất) − giảm giá của hóa đơn đó
Tiền 1 hóa đơn thuốc   = Σ (số lượng × đơn giá × (1 + thuế suất)) các thuốc khách mua − giảm giá của hóa đơn đó

Tiền khách trả cho đợt khám = Σ tiền các hóa đơn dịch vụ, nộp làm 3 lần: phí khám (trước khi vào hàng đợi Bác sĩ),
                               XN / CĐHA (trước khi vào hàng đợi phòng), dịch vụ làm tại phòng (khi chốt ca)
Tiền thuốc (nếu khách mua tại phòng khám) = tiền hóa đơn thuốc, thanh toán riêng
```

Số liệu được tính qua 2 VIEW: `v_service_invoice_amounts` và `v_medicine_invoice_amounts`.

Ví dụ một ca khám có xét nghiệm và siêu âm, khách mua thuốc tại phòng khám:

```text
HÓA ĐƠN DỊCH VỤ (mỗi dịch vụ một hóa đơn)
Lần 1 – sau tiếp đón (nộp xong mới được phát phiếu vào hàng đợi Bác sĩ):
SINV-2026-0101  Khám tổng quát     1 × 100.000 × (1 + 0%)            = 100.000
Lần 2 – sau khi Bác sĩ chỉ định (nộp xong mới được phát phiếu phòng XN, CĐHA):
SINV-2026-0102  Xét nghiệm CBC     1 × 250.000 × (1 + 0%) − 30.000   = 220.000
SINV-2026-0103  Siêu âm bụng       1 × 200.000 × (1 + 0%)            = 200.000
Lần 3 – khi chốt ca (dịch vụ làm tại phòng, không thu trước):
SINV-2026-0104  Tiêm thuốc         1 ×  80.000 × (1 + 0%)            =  80.000
--------------------------------------------------------------------------------
Tổng dịch vụ của đợt khám                                               600.000

HÓA ĐƠN THUỐC (tùy chọn)
MINV-2026-0045  Amoxicillin 250mg 10 viên × 8.000 × (1 + 5%)          =  84.000
--------------------------------------------------------------------------------
Cần thu tiền thuốc                                                       84.000
```

Nếu khách mua thuốc ngoài, khách chỉ trả 600.000 tiền dịch vụ (đã nộp 520.000 trước khi được phục vụ) và nhận đơn thuốc in.

---

## 29. Hóa đơn

Từ v3.0, hệ thống có **hai loại hóa đơn**, không còn hóa đơn gộp một ca một hóa đơn:

```text
Visit
 └── (1 : N) Visit Service Detail ── (1 : 1) ── Service Invoice      (bắt buộc, tạo lúc chỉ định / tiếp đón)
 └── Phiếu xếp hàng trên Redis (phát khi thu tiền xong) → kết thúc thì ghi Queue Ticket History
 └── (1 : 0..1) Prescription ··(sự kiện chốt ca)··> (0..1) Medicine Invoice   (nháp tự tạo; PAID khi khách mua, CANCELLED khi mua ngoài)
                                                          └── (1 : N) Medicine Invoice Items ── (N : 1) ── Medicines
```

**Hóa đơn dịch vụ (`service_invoices`, thuộc `clinical-service`) lưu:**
- Mã hóa đơn (`invoice_code`, ví dụ `SINV-YYYY-XXXX`).
- Dòng chỉ định dịch vụ tương ứng (1–1).
- Đơn giá và thuế suất snapshot lúc chỉ định.
- Giảm giá.
- Trạng thái thanh toán (`PENDING`, `PAID`, `CANCELLED`, `REFUNDED` – đã hoàn tiền khi phòng khám không thực hiện được dịch vụ đã thu).
- Thu ngân xác nhận và thời điểm thanh toán.

**Hóa đơn thuốc (`medicine_invoices` + `medicine_invoice_items`, thuộc `billing-pharmacy-service`) lưu:**
- Mã hóa đơn (`MINV-YYYY-XXXX`), đơn thuốc tương ứng (tối đa 1 hóa đơn / đơn thuốc – liên kết duy nhất sang phân hệ khám), đợt khám, tên khách / thú cưng / Bác sĩ chụp lại để in hóa đơn.
- Từng thuốc: **trỏ thẳng tới thuốc trong danh mục** (không trỏ tới dòng đơn thuốc), số lượng kê (để đối chiếu), số lượng khách mua (khác số kê được; không vượt tồn kho), đơn giá và thuế suất snapshot.
- Giảm giá, trạng thái thanh toán, thu ngân, thời điểm thanh toán.

**Không lưu:** tổng tiền dịch vụ, tổng tiền thuốc, tổng phải thanh toán (tính được, xem mục 28) và **phương thức thanh toán** (khách trả ngoài quầy, hệ thống không tích hợp VietQR / máy POS trong phạm vi đồ án).

**Lợi ích của hóa đơn riêng cho từng dịch vụ:**
- Hủy một dịch vụ chỉ cần hủy đúng hóa đơn của dịch vụ đó.
- Doanh thu theo dịch vụ / nhóm dịch vụ truy xuất trực tiếp bằng một truy vấn trên hóa đơn đã thanh toán.
- Khách bỏ về giữa chừng thì các hóa đơn của dịch vụ đã làm sẵn có để ghi công nợ.

---

## 30. Thanh toán hóa đơn dịch vụ

Khách hàng thanh toán bên ngoài quầy (trả tiền mặt hoặc tự chuyển khoản ngân hàng riêng). **Quy trình thanh toán tách khỏi quy trình khám**: màn hình Thu ngân có 3 mục, ứng với 3 lần thu tiền của một đợt khám:

| Mục trên màn hình Thu ngân | Thu gì | Kết quả |
| :--- | :--- | :--- |
| **Chờ thu phí khám** | Hóa đơn phí khám (lập lúc tiếp đón) | Phát phiếu hàng đợi Bác sĩ (mục 8.5) |
| **Chờ thu tiền cận lâm sàng** | Hóa đơn Xét nghiệm / CĐHA vừa chỉ định | Phát phiếu hàng đợi phòng XN / CĐHA (mục 17.1) |
| **Chờ thanh toán cuối ca** | Hóa đơn còn lại: dịch vụ làm tại phòng, các khoản của ca cấp cứu; công nợ | Đủ hóa đơn → đợt khám `COMPLETED` |

Các bước thu tiền giống nhau ở cả 3 mục:

1. Mở mục tương ứng, chọn đợt khám (ở mục cuối ca: `WAITING_PAYMENT`, hoặc đợt khám đã `COMPLETED` còn công nợ).
2. Hệ thống hiển thị bảng kê các hóa đơn dịch vụ của ca và tổng số tiền cần thu (tính từ các hóa đơn `PENDING`; hóa đơn đã hủy hiển thị mờ, không tính tiền).
3. Nếu có ưu đãi, nhập giảm giá trên từng hóa đơn (giảm giá không vượt số tiền của chính hóa đơn đó – EX-14).
4. Khách hàng thanh toán tiền bên ngoài quầy.
5. Sau khi nhận đủ tiền, Thu ngân nhấn **"Xác nhận thanh toán"** (không chọn phương thức thanh toán).
6. Trong một giao dịch, hệ thống chuyển các hóa đơn sang `PAID`, ghi `paid_at`, `cashier_id` và ghi sự kiện thanh toán vào outbox; ngay sau đó, với phí khám / Xét nghiệm / CĐHA hệ thống **phát phiếu xếp hàng** trên Redis và hiển thị số thứ tự. Nếu đợt khám đang `WAITING_PAYMENT` và **mọi hóa đơn dịch vụ của ca đều `PAID`, `CANCELLED` hoặc `REFUNDED`**, đợt khám chuyển `COMPLETED` ngay trong giao dịch đó.
7. In phiếu thu.

**Hoàn tiền:** phí khám đã nộp **không hoàn** trong mọi trường hợp; khách tự bỏ về hoặc tự hủy dịch vụ đã nộp cũng không được hoàn. Chỉ khi **phòng khám không thực hiện được** dịch vụ Xét nghiệm / CĐHA đã thu (máy hỏng, không lấy được mẫu, Bác sĩ hủy chỉ định trước khi làm), hóa đơn chuyển `REFUNDED` và Thu ngân trả lại tiền cho khách. Nếu ca có đơn thuốc, màn hình Thu ngân hiện sẵn **hóa đơn thuốc nháp** để hỏi khách có mua tại phòng khám không (mục 31).

---

## 31. Bán thuốc theo đơn (tùy chọn)

Khách hàng **không bắt buộc** mua thuốc tại phòng khám. Từ v4.0, khi Bác sĩ chốt ca, phân hệ khám phát sự kiện "đã có đơn thuốc" và quầy thuốc **tự tạo hóa đơn thuốc nháp** (`PENDING`) đúng theo đơn, giá lấy từ bảng giá hiện hành; Thu ngân không phải nhập lại từng thuốc.

```text
Bác sĩ chốt ca ──→ Hóa đơn thuốc nháp (PENDING, đủ các thuốc trong đơn, số lượng = số kê)
                         │
            ┌────────────┴────────────┐
   Khách mua ngoài            Khách mua tại phòng khám
            │                         │
            ↓                         ↓
   Hủy hóa đơn nháp          Sửa số lượng (nhiều / ít / bằng số kê, ≤ tồn kho) hoặc bỏ dòng
   (CANCELLED), in đơn                ↓
                   ↓
            Lấy thuốc từ tủ, kiểm tra hạn dùng, dán nhãn
                   ↓
            Khách trả tiền → Thu ngân "Xác nhận thanh toán & Xuất thuốc"
                   ↓
            MỘT giao dịch: trừ tồn kho có điều kiện + ghi nhật ký EXPORT_SALE + hóa đơn PAID
```

Ví dụ:

```text
Kho: Amoxicillin = 100 viên
Bác sĩ kê: 14 viên — Khách mua tại phòng khám: 10 viên
Sau khi bán: 90 viên (4 viên còn lại khách tự mua ngoài nếu cần)
```

**Đảm bảo an toàn:**
- **Không bán âm kho:** trừ kho trên bảng tồn kho riêng bằng `UPDATE medicine_stocks ... WHERE quantity_on_hand >= :qty`; nếu thiếu (do quầy khác vừa bán), toàn bộ giao dịch bị hoàn tác, hóa đơn giữ `PENDING`; Thu ngân sửa chính hóa đơn đó (giảm số lượng / bỏ thuốc thiếu) rồi xác nhận lại, hoặc hủy để khách mua ngoài (EX-15). Vì chưa có khoản nào được ghi nhận đã thu, không phát sinh hoàn tiền.
- **Không bán trùng:** mỗi đơn thuốc chỉ có tối đa một hóa đơn thuốc (`prescription_id UNIQUE`, kể cả hóa đơn đã hủy; sự kiện đến 2 lần cũng không tạo hóa đơn thứ hai); muốn đổi số lượng thì sửa hóa đơn đang `PENDING`; hóa đơn đã `PAID` không xác nhận lại được (EX-16).
- **Không ảnh hưởng đợt khám:** bán thuốc không làm thay đổi trạng thái đợt khám.

---

## 32. Hoàn tất Visit

Đợt khám hoàn tất khi **mọi hóa đơn dịch vụ đã `PAID`, `CANCELLED` hoặc `REFUNDED`**:

```text
WAITING_PAYMENT ───→ COMPLETED
```

- Việc khách có mua thuốc hay không **không** là điều kiện hoàn tất.
- Ngoại lệ (EX-11): khi khách bỏ về giữa chừng hoặc không quay lại đọc kết quả, Lễ tân "Đóng ca / Khách bỏ về" → đợt khám `COMPLETED` dù còn hóa đơn dịch vụ `PENDING` (thường chỉ ở ca cấp cứu khám trước thu sau, vì phí khám và tiền XN / CĐHA đã nộp trước); các hóa đơn này là công nợ, được thu ở lần đến sau. Tiền đã nộp không hoàn.

Visit trở thành một phần của lịch sử bệnh án. Thời điểm hoàn tất lấy từ lịch sử trạng thái.

---

## 33. Hủy Visit

Hủy dùng khi ca kết thúc **trước khi có kết quả chuyên môn**:

```text
WAITING → CANCELLED                      (khách bỏ về khi chờ ở sảnh – EX-03)
hoặc
IN_PROGRESS (Giai đoạn 1) → CANCELLED    (khách từ chối khám / chuyển viện cấp cứu)
```

Hủy ca thì phiếu xếp hàng bị hủy, mọi dịch vụ của ca bị hủy, hóa đơn chưa thu bị hủy theo. **Phí khám đã nộp không hoàn** (hóa đơn giữ `PAID`); riêng ca cấp cứu chưa nộp phí khám thì hóa đơn khám được hủy. Hủy ở Giai đoạn 1 chỉ được phép khi **chưa có dịch vụ tại phòng nào hoàn thành**, nên ca hủy không để lại hóa đơn chờ thu. Nếu đã thực hiện dịch vụ tại phòng, Bác sĩ chốt ca bình thường với chẩn đoán "chuyển viện" thay vì hủy. Khách bỏ về khi đã làm cận lâm sàng **không** dùng hủy mà dùng "Đóng ca / Khách bỏ về" (mục 32).

Phải lưu (vào 1 dòng `pet_visit_status_histories`):

- Người thực hiện hủy (`changed_by_user_id`).
- Thời gian (`created_at`).
- Lý do hủy (`notes`, ví dụ: khách yêu cầu, tạo nhầm, chuyển viện cấp cứu, khác...).

---

## 34. Lịch sử bệnh án

Lịch sử bệnh án của thú cưng được hình thành từ toàn bộ các Visit:

```text
PET
 │
 ├── Visit 01 (Diagnosis, Lab, Prescription)
 ├── Visit 02 (Diagnosis, Imaging)
 └── Visit 03 (Diagnosis, Prescription)
```

Bác sĩ có thể tra cứu lịch sử bệnh án trước khi đưa ra chẩn đoán mới.

---

## 35. Tiêm phòng và tẩy giun định kỳ

Khi thực hiện `Vaccination` hoặc `Deworming`, hệ thống ghi nhận:

- Ngày thực hiện.
- Loại vaccine / thuốc.
- Lần thực hiện.
Hệ thống ghi nhận vào lịch sử bệnh án của thú cưng để phục vụ tra cứu sau này.

---

## 36. Portal dành cho chủ thú cưng

Chủ thú cưng có thể:

- **Quản lý thú cưng:** Xem danh sách thú cưng, cập nhật thông tin.
- **Đặt lịch:** Chọn thú cưng, chọn ngày, chọn khung giờ, nhập lý do (**không chọn bác sĩ**).
- **Theo dõi lịch:** Chờ xác nhận, đã xác nhận, đã đến, đã hủy, vắng mặt.
- **Xem bệnh án:** Lịch sử khám, chẩn đoán, xét nghiệm, hình ảnh, đơn thuốc (dùng để mua thuốc ở nơi khác nếu không mua tại phòng khám).
- **Nhận thông báo:** Xác nhận lịch, gọi số vào phòng, gọi lại khi khách quay lại (qua ứng dụng / Portal, không qua SMS).

---

## 37. Quản lý danh mục thuốc

Administrator quản lý thông tin thuốc:

- **Thông tin thuốc** (`medicines`): mã, tên thương mại, nhóm thuốc (bảng danh mục `medicine_categories`), dạng bào chế, hàm lượng, đơn vị bán nhỏ nhất, **quy cách đóng gói** (ví dụ "Hộp 10 vỉ x 10 viên"), nhà sản xuất, nước sản xuất, số đăng ký lưu hành, điều kiện bảo quản, thuốc kê đơn hay không, mức tồn tối thiểu cảnh báo, trạng thái kinh doanh (ngừng kinh doanh = xóa mềm).
- **Thành phần** (`medicine_ingredients`): từng hoạt chất và hàm lượng (ví dụ Amoxicillin 200 mg + Clavulanic acid 50 mg).
- **Giá bán có lịch sử** (`medicine_prices`): giá, thuế suất, thời điểm bắt đầu / kết thúc hiệu lực, lý do điều chỉnh, người lập.
- **Tồn kho hiện tại** (`medicine_stocks`): chỉ thay đổi qua giao dịch kho hoặc bán thuốc, không sửa tay trên form danh mục.

Tách bốn phần vì chúng thay đổi với tần suất khác nhau: thông tin thuốc hầu như không đổi, giá đổi theo đợt, tồn kho đổi sau mỗi lần bán.

*(Mở rộng trong tương lai: Quản lý lô thuốc, hạn sử dụng, nhà cung cấp).*

---

## 38. Quản lý kho

Mọi biến động kho đều được ghi vào nhật ký `inventory_transactions` với số lượng có dấu:

```text
IMPORT       (+)  Nhập thuốc vào kho                          – Quản trị viên
EXPORT_SALE  (−)  Xuất bán theo hóa đơn thuốc đã thanh toán    – tự động khi bán (mục 31)
ADJUSTMENT   (±)  Cân chỉnh sau kiểm kê, hao hụt, hết hạn,
                  vật tư / vaccine dùng tại phòng              – Quản trị viên

Tồn kho hiện tại = Σ quantity của mọi giao dịch kho của thuốc đó
```

`medicine_stocks.quantity_on_hand` được lưu sẵn (phi chuẩn hóa có chủ đích) để trừ kho nguyên tử và chống bán âm kho; mỗi giao dịch kho cập nhật cột này trong cùng giao dịch, đảm bảo bất biến `quantity_on_hand = SUM(inventory_transactions.quantity)`.

Khi `quantity_on_hand <= min_stock_alert`, hệ thống phát cảnh báo tồn kho thấp.

---

## 39. Quản lý danh mục dịch vụ

Administrator có thể:

- Thêm dịch vụ.
- Sửa dịch vụ.
- Ngừng sử dụng dịch vụ (`is_active = FALSE`).
- Thiết lập **bảng giá có lịch sử** (`service_prices`): giá, thuế suất, thời điểm hiệu lực, lý do. Giá mới chỉ áp dụng cho chỉ định từ thời điểm hiệu lực; hóa đơn đã lập giữ giá cũ.
- Phân loại nhóm dịch vụ (bảng danh mục `service_categories`; thêm nhóm mới không phải sửa cấu trúc CSDL).
- Với dịch vụ xét nghiệm: cấu hình gói gồm những chỉ số nào (`service_lab_test_items`).

> Không xóa cứng dịch vụ đã từng phát sinh trong lịch sử khám để bảo toàn tính toàn vẹn dữ liệu.

---

## 40. Báo cáo và thống kê

Administrator có thể xem:

- **Doanh thu dịch vụ:** Tổng tiền các hóa đơn dịch vụ đã `PAID` theo ngày / tháng / năm (theo `paid_at`), theo dịch vụ, theo nhóm dịch vụ (hóa đơn `REFUNDED` không tính).
- **Doanh thu thuốc:** Tổng tiền các hóa đơn thuốc đã `PAID`, theo thuốc.
- **Công nợ:** Các hóa đơn dịch vụ còn `PENDING` của những đợt khám đã `COMPLETED` (khách bỏ về).
- **Hoạt động khám:** Số lượt khám, số ca hoàn tất, số ca hủy, số ca No-show.
- **Dịch vụ:** Dịch vụ dùng nhiều nhất, tỷ lệ dịch vụ bị hủy.
- **Thuốc:** Thuốc bán chạy, thuốc sắp hết hàng, tỷ lệ khách mua thuốc tại phòng khám.
- **Bác sĩ:** Thống kê số ca khám, số ca hoàn thành (không phân quyền theo thống kê).

Hóa đơn `CANCELLED` không tính vào doanh thu; hóa đơn `REFUNDED` ghi một dòng doanh thu âm. Từ v4.0 các báo cáo lấy từ **phân hệ báo cáo** (`reporting-service`): phân hệ này nhận sự kiện thu tiền / hoàn tiền / hoàn tất ca từ các phân hệ khác và ghi sẵn vào bảng phẳng (đã có tên, nhóm, số tiền), nên mỗi báo cáo là một truy vấn, không phải ghép dữ liệu nhiều phân hệ. Thêm: **thời gian chờ trung bình** từng hàng đợi (từ lịch sử phiếu).

---

## 41. Các quy tắc nghiệp vụ cốt lõi (Business Rules)

### Nhóm khách hàng & Thú cưng
- **BR-01:** Một khách hàng có thể sở hữu nhiều thú cưng.
- **BR-02:** Một thú cưng thuộc về một chủ sở hữu chính.
- **BR-03:** Một thú cưng có thể có nhiều Visit trong suốt vòng đời, nhưng tại một thời điểm chỉ có tối đa một Visit chưa kết thúc.

### Nhóm Appointment
- **BR-04:** Khách hàng không được chọn bác sĩ khi đặt lịch.
- **BR-05:** Appointment chỉ xác định thời gian dự kiến và nhu cầu khám.
- **BR-06:** Một Appointment chuyển đổi thành tối đa một Visit.
- **BR-07:** Appointment có thể bị hủy bởi khách hoặc nhân viên kèm lý do (ghi ở lịch sử trạng thái lịch hẹn).
- **BR-08:** Appointment chuyển thành `NO_SHOW` nếu quá `start_time` + 30 phút mà khách chưa check-in.

### Nhóm hàng đợi & Phân công
- **BR-09:** Visit sau khi tiếp nhận ở trạng thái `WAITING` kèm hóa đơn phí khám; khách nộp phí xong mới được phát phiếu vào danh sách chờ phân công (hoặc thẳng hàng đợi của Bác sĩ được chọn); mọi hàng đợi sắp theo phiếu: cấp cứu → ca có kết quả CLS → còn lại theo giờ phát phiếu.
- **BR-10:** Lễ tân chịu trách nhiệm phân công bác sĩ phụ trách.
- **BR-11:** Mỗi bác sĩ có một hàng đợi riêng. Lễ tân được xếp ca `WAITING` vào hàng đợi của bất kỳ bác sĩ đang làm việc nào, bất cứ lúc nào, không phụ thuộc bác sĩ đang rảnh hay đang khám; hệ thống gợi ý bác sĩ có ít người chờ nhất. Ca vừa có kết quả cận lâm sàng được phát phiếu ưu tiên vào hàng đợi của bác sĩ khám chính (sau ca cấp cứu).
- **BR-12:** Một bác sĩ chỉ khám một ca tại một thời điểm (không có đồng thời 2 ca `IN_PROGRESS`); bác sĩ chỉ được "Gọi" khi không có ca đang khám.
- **BR-13:** Bác sĩ khám tại số phòng cố định đã được gán sẵn trong hồ sơ nhân sự. Tài khoản Bác sĩ bắt buộc có hồ sơ chuyên môn (số chứng chỉ hành nghề).

### Nhóm Visit
- **BR-14:** Visit có thể sinh ra từ Appointment (`CHECKED_IN`) hoặc tạo trực tiếp từ Walk-in.
- **BR-15:** Một Visit gắn liền với duy nhất một thú cưng.
- **BR-16:** Một Visit có một bác sĩ phụ trách chính sau khi phân công.
- **BR-17:** Một Visit có thể bao gồm nhiều chỉ định dịch vụ (phí khám cũng là một dịch vụ, được tạo tự động khi tiếp đón).
- **BR-18:** Một Visit có tối đa một Prescription (đơn thuốc, thuộc phân hệ khám); đơn thuốc không chứa giá, không có trạng thái cấp phát, khóa khi chốt ca.
- **BR-19:** Mỗi dịch vụ được chỉ định có đúng một hóa đơn dịch vụ riêng; một Visit có thể có nhiều hóa đơn dịch vụ. Hệ thống không lưu tổng tiền hóa đơn.

### Nhóm chuyên môn
- **BR-20:** Phân quyền ghi dữ liệu chuyên môn nghiêm ngặt theo vai trò: `VETERINARIAN` (khám lâm sàng, ra chỉ định, thực hiện dịch vụ tại phòng, chẩn đoán xác định, kê đơn), `LAB_TECHNICIAN` (nhập kết quả xét nghiệm), `IMAGING_TECHNICIAN` (tải tệp ảnh và nhập kết luận chẩn đoán hình ảnh).
- **BR-21:** Chi phí dịch vụ (gồm cả thuốc / vật tư dùng ngay tại phòng) và chi phí thuốc mang về được ghi trên hai loại hóa đơn độc lập: hóa đơn dịch vụ và hóa đơn thuốc.
- **BR-22:** Mỗi dịch vụ kỹ thuật có thể sinh ra các bản ghi kết quả chi tiết riêng (xét nghiệm, chẩn đoán hình ảnh).
- **BR-23:** Khoảng tham chiếu xét nghiệm phải phụ thuộc theo loài (`Species`).
- **BR-24:** Khoảng tham chiếu (min, max) phải được snapshot vào kết quả tại thời điểm thực hiện; nhãn đánh giá được tính khi hiển thị.

### Nhóm tài chính & Thanh toán
- **BR-25:** Đơn giá và thuế suất dịch vụ lấy từ dòng giá đang hiệu lực của bảng giá dịch vụ và được snapshot vào hóa đơn dịch vụ tại thời điểm bác sĩ chỉ định (phí khám: thời điểm tiếp đón). Dòng giá cũ không được sửa số tiền hay xóa.
- **BR-26:** Đơn giá và thuế suất thuốc lấy từ bảng giá thuốc đang hiệu lực, snapshot vào hóa đơn thuốc nháp và cập nhật lần cuối khi thu tiền (không phải lúc kê đơn).
- **BR-27:** Hóa đơn dịch vụ được lập tự động lúc chỉ định (phí khám: lúc tiếp đón). Dịch vụ thu trước (khám, Xét nghiệm, CĐHA) được thu ngay; dịch vụ làm tại phòng chỉ thu khi Visit đã được bác sĩ chốt chuyên môn (`WAITING_PAYMENT`) hoặc khi thu công nợ của Visit đã đóng.
- **BR-28:** Visit chuyển sang `COMPLETED` khi mọi hóa đơn dịch vụ đều `PAID`, `CANCELLED` hoặc `REFUNDED`; việc mua thuốc không ảnh hưởng. Ngoại lệ: khi khách bỏ về (EX-11), Visit được đóng sang `COMPLETED` và các hóa đơn dịch vụ còn `PENDING` giữ làm công nợ.
- **BR-33:** Khi một dịch vụ được chỉ định bị hủy mà hóa đơn chưa thu, hóa đơn dịch vụ tương ứng chuyển `CANCELLED` trong cùng giao dịch; không có thao tác hủy hóa đơn dịch vụ riêng lẻ. Dịch vụ đã thu bị hủy thì theo BR-36.
- **BR-34:** Ở hàng đợi bác sĩ, phòng Xét nghiệm và phòng CĐHA, mỗi phiếu có nút "Gọi" (chỉ ghi giờ gọi và phát thông báo, không đổi trạng thái và không đổi thứ tự) và "Bắt đầu"; "Gọi số tiếp theo" là phím tắt gọi người đứng đầu. Khách vắng thì gọi ca khác; khách quay lại thì gọi lại (hệ thống không theo dõi việc quay lại). Ca cấp cứu luôn giữ ưu tiên. Ở phòng Xét nghiệm / CĐHA, các dịch vụ của cùng một đợt khám trong cùng phòng nằm chung một phiếu (gọi một lần).
- **BR-35 (Thu tiền trước – xếp hàng sau):** Dịch vụ thuộc nhóm được đánh dấu thu trước trong danh mục nhóm dịch vụ (khám lâm sàng, Xét nghiệm, CĐHA) phải thu tiền xong thì hệ thống mới phát phiếu xếp hàng vào hàng đợi phòng tương ứng (phát ngay sau khi thu, qua sự kiện; đã thu thì chắc chắn có phiếu); dịch vụ làm tại phòng làm ngay, thu khi chốt ca. Ngoại lệ: ca cấp cứu phát phiếu ngay (khám trước thu sau); ca có kết quả CLS phát phiếu ưu tiên không thu thêm.
- **BR-36 (Hoàn tiền):** Phí khám đã nộp không hoàn; khách tự bỏ về / tự hủy dịch vụ đã nộp không được hoàn. Chỉ hoàn (`REFUNDED`) khi phòng khám không thực hiện được dịch vụ Xét nghiệm / CĐHA đã thu.

### Nhóm kho dược
- **BR-29:** Thuốc chỉ bị trừ tồn kho khi hóa đơn thuốc được xác nhận thanh toán; chuyển `PAID`, trừ kho và ghi nhật ký `EXPORT_SALE` diễn ra trong cùng một giao dịch.
- **BR-30:** Không được bán (xuất kho) vượt quá số lượng tồn kho tại thời điểm xác nhận; khi kê đơn, số lượng vượt tồn kho chỉ bị cảnh báo.
- **BR-31:** Mỗi đơn thuốc có tối đa một hóa đơn thuốc (nháp tự tạo khi chốt ca); hóa đơn thuốc đã thanh toán không được xác nhận lại, nên một đơn thuốc không bị trừ kho nhiều hơn một lần.
- **BR-32:** Khách hàng được tự chọn mua thuốc tại phòng khám (thu hóa đơn nháp) hoặc mua ngoài theo đơn in (hủy hóa đơn nháp); được mua nhiều hơn, ít hơn hoặc bằng số lượng kê (số kê chỉ để tham khảo), nhưng không vượt tồn kho hiện tại.


### Nhóm dữ liệu, danh mục & người dùng (bổ sung v4.0)
- **BR-37 (Xóa mềm):** Tài khoản, dịch vụ, thuốc, nhóm, vai trò, thú cưng không bị xóa cứng. Ngừng sử dụng thì không xuất hiện trong lựa chọn mới; dữ liệu cũ tham chiếu tới vẫn hiển thị kèm nhãn "Đã khóa" / "Ngừng sử dụng" thay vì báo lỗi không tìm thấy.
- **BR-38 (Giá có lịch sử):** Tại một thời điểm, mỗi dịch vụ / thuốc có đúng một dòng giá hiệu lực. Đổi giá = đóng dòng đang áp dụng và thêm dòng mới có thời điểm bắt đầu sau thời điểm bắt đầu của dòng đang áp dụng; không sửa số tiền, không xóa dòng giá.
- **BR-39 (Phân công Bác sĩ còn hoạt động):** Chỉ được phân công / chuyển ca cho tài khoản có vai trò Bác sĩ đang `ACTIVE`, kiểm tra ngay tại thời điểm phân công. Khi một Bác sĩ bị khóa hoặc nghỉ việc, các phiếu đang chờ của Bác sĩ đó tự chuyển về danh sách chờ phân công và Lễ tân được thông báo.
- **BR-40 (Hồ sơ khám):** Sinh hiệu đo bao nhiêu lần ghi bấy nhiêu bản ghi (không ghi đè); hồ sơ khám chuyên môn và đơn thuốc chỉ Bác sĩ phụ trách được sửa, khóa khi chốt ca (mở lại theo mục 27).
- **BR-41 (Hồ sơ người dùng):** Mỗi tài khoản có một hồ sơ cá nhân chung; nhân viên có hồ sơ nhân sự; Bác sĩ có thêm hồ sơ chuyên môn với số chứng chỉ hành nghề duy nhất; khách hàng có hồ sơ khách hàng. Một tài khoản có thể giữ nhiều vai trò.

---

## 42. State Machine hoàn chỉnh

*(Bản đặc tả chi tiết với điều kiện canh và hành động CSDL ở tài liệu `THIET_KE_SO_DO_TRANG_THAI_STATE_MACHINE.md`.)*

### 42.1. State Machine: Appointment

```text
                 ┌─────────────┐
                 │   PENDING   │
                 └──────┬──────┘
                        │ (Xác nhận lịch)
                        ↓
                 ┌─────────────┐
                 │  CONFIRMED  │
                 └──────┬──────┘
                        │ (Khách đến phòng khám)
                        ↓
                 ┌─────────────┐
                 │ CHECKED_IN  │ ──────→ Tạo Pet Visit
                 └─────────────┘

Nhánh kết thúc khác:
- PENDING   ───(Khách/Lễ tân hủy)──────────────────────→ CANCELLED
- CONFIRMED ───(Khách/Lễ tân hủy)──────────────────────→ CANCELLED
- CONFIRMED ───(Quá start_time + 30 phút chưa check-in)─→ NO_SHOW
```

---

### 42.2. State Machine: Pet Visit

```text
                 ┌─────────┐
                 │ WAITING │ (Nộp phí khám → phiếu trong hàng đợi riêng của Bác sĩ)
                 └────┬────┘
                      │ Bác sĩ gọi số theo phiếu, bấm "Bắt đầu khám"
                      ↓  (dịch vụ khám đã lập + thu lúc tiếp đón)
               ┌──────────────────┐
               │ IN_PROGRESS (GĐ1)│──────────────────────────────┐
               └────────┬─────────┘                              │ Không cần CLS
                        │ Gửi chỉ định CLS (khách nộp tiền → phiếu phòng) │ (chốt ca)
                        ↓                                        │
               ┌─────────────────┐                               │
               │ WAITING_RESULTS │                               │
               └────────┬────────┘                               │
                        │ Mọi dịch vụ CLS xong hoặc hủy           │
                        ↓                                        │
               ┌─────────────────┐                               │
               │  RESULTS_READY  │ (phiếu ưu tiên cho Bác sĩ)    │
               └────────┬────────┘                               │
                        │ Gọi số, bấm "Bắt đầu GĐ 2"              │
                        ↓                                        │
               ┌──────────────────┐                              │
               │ IN_PROGRESS (GĐ2)│                               │
               └────────┬─────────┘                               │
                        │ Chốt chuyên môn                         │
                        ↓                                        │
             ┌──────────────────┐ ←─────────────────────────────┘
             │ WAITING_PAYMENT  │ ──(Mở lại hồ sơ)──→ IN_PROGRESS
             └────────┬─────────┘
                      │ Mọi hóa đơn dịch vụ PAID / CANCELLED / REFUNDED
                      ↓
                ┌───────────┐
                │ COMPLETED │ (Lưu trữ vào lịch sử bệnh án)
                └───────────┘

Gọi số không thấy khách (WAITING / RESULTS_READY): gọi phiếu khác, không đổi trạng thái và vị trí (EX-10).

Nhánh hủy / đóng ca đặc biệt:
- WAITING            ───(Khách bỏ về / lỗi tạo)─────────────────────→ CANCELLED
- IN_PROGRESS (GĐ1)  ───(Khách từ chối khám / Chuyển viện)──────────→ CANCELLED
- WAITING_RESULTS    ───(Khách bỏ về giữa chừng, ghi công nợ)───────→ COMPLETED
- RESULTS_READY      ───(Khách không quay lại đọc KQ, ghi công nợ)──→ COMPLETED
```

---

## 43. Luồng nghiệp vụ tổng thể (End-to-End Workflow)

```text
                  CHỦ THÚ CƯNG
                       │
             ┌─────────┴─────────┐
             │                   │
        Đặt lịch Online       Walk-in
             │                   │
             ↓                   │
        APPOINTMENT              │
             │                   │
       PENDING/CONFIRMED         │
             │                   │
             ↓                   │
         CHECKED_IN              │
             │                   │
             └─────────┬─────────┘
                       ↓
          TẠO VISIT + HÓA ĐƠN PHÍ KHÁM
                       │
                       ↓
                    WAITING
                       │
                       ↓
     LỄ TÂN CHỌN BÁC SĨ (gợi ý bác sĩ ít người chờ nhất)
                       │
                       ↓
     THU NGÂN THU PHÍ KHÁM ──→ PHÁT PHIẾU XẾP HÀNG
          (ca cấp cứu: phát phiếu ngay, thu sau)
                       │
             ┌─────────┼─────────┐
             ↓         ↓         ↓
       Hàng đợi BS A  BS B     BS C
           P01       P02       P03
                       │
                       ↓
     BÁC SĨ GỌI (vắng → gọi ca khác)
                       │
                       ↓
                 IN_PROGRESS
                       │
             ┌─────────┼─────────┐
             │         │         │
             ↓         ↓         ↓
     Dịch vụ tại   NỘP TIỀN   NỘP TIỀN
     phòng (làm    → phiếu XN → phiếu CĐHA
     ngay, thu sau)    │         │
             │         ↓         ↓
             │       Results   Results
             │         └────┬────┘
             │      PHIẾU ƯU TIÊN về Bác sĩ
             │         │         │
             └─────────┼─────────┘
                       ↓
                   Chẩn đoán
                       ↓
                    Kê đơn
                       ↓
              CHỐT ĐỢT KHÁM ──(sự kiện đơn thuốc)──→ quầy thuốc tạo HÓA ĐƠN THUỐC NHÁP
                       ↓
                WAITING_PAYMENT
                       ↓
   THU CÁC HÓA ĐƠN CÒN LẠI (dịch vụ làm tại phòng)
     (mỗi dịch vụ một hóa đơn, lập sẵn lúc chỉ định)
                       ↓
                   COMPLETED ─────→ LỊCH SỬ BỆNH ÁN
                       │
             ┌─────────┴──────────┐
             ↓                    ↓
     Khách mua thuốc        Khách mua ngoài /
     tại phòng khám         không kê đơn
             ↓                    ↓
   THU HÓA ĐƠN NHÁP        Hủy hóa đơn nháp,
     + TRỪ TỒN KHO          in đơn thuốc, ra về
   (cùng một giao dịch)
```


---

## 44. Mô hình dữ liệu khái niệm (Conceptual Data Model)

### 44.1. Cấu trúc tài khoản người dùng (v4.0)
- `users`: chỉ thông tin đăng nhập (tên đăng nhập, mật khẩu băm, trạng thái `ACTIVE` / `LOCKED` / `INACTIVE`).
- `roles` (bảng danh mục, không còn kiểu ENUM) + `user_roles`: một tài khoản có thể nhiều vai trò.
- `user_profiles`: họ tên, số điện thoại, email, giới tính, ngày sinh, địa chỉ, ảnh đại diện – dùng chung cho mọi người dùng.
- `staff_profiles`: hồ sơ nhân sự (mã nhân viên, CCCD, chức danh, bộ phận, phòng làm việc, hình thức làm việc, ngày vào làm / nghỉ việc, người liên hệ khẩn cấp).
- `veterinarian_profiles`: hồ sơ chuyên môn của Bác sĩ (số chứng chỉ hành nghề, ngày cấp, nơi cấp, hạn, học vị, chuyên khoa, nơi đào tạo, năm bắt đầu hành nghề, giới thiệu).
- `pet_owner_profiles`: hồ sơ khách hàng (mã khách hàng, kênh đăng ký, kênh liên hệ ưu tiên).

### 44.2. Các thực thể chính (52 bảng, 5 CSDL logic + Redis – lược đồ v4.0, 18/11/2026)

```text
AUTH-SERVICE (pet_clinic_auth_db) – 9 bảng
  ROLES, USERS, USER_ROLES, USER_PROFILES, STAFF_PROFILES, VETERINARIAN_PROFILES,
  PET_OWNER_PROFILES, REFRESH_TOKENS, OUTBOX_EVENTS

APPOINTMENT-SERVICE (pet_clinic_appointment_db) – 4 bảng
  APPOINTMENTS, APPOINTMENT_STATUS_HISTORIES, OUTBOX_EVENTS, PROCESSED_EVENTS

CLINICAL-SERVICE (pet_clinic_clinical_db) – 24 bảng
  Danh mục & giá : SPECIES, SERVICE_CATEGORIES, SERVICES, SERVICE_PRICES,
                   LAB_TEST_ITEMS, SERVICE_LAB_TEST_ITEMS, LAB_TEST_REFERENCE_RANGES
  Khám bệnh      : PETS, PET_VISITS (tiếp đón), VITAL_SIGNS (sinh hiệu), MEDICAL_RECORDS (hồ sơ khám),
                   PET_VISIT_STATUS_HISTORIES
  Dịch vụ        : VISIT_SERVICE_DETAILS, VISIT_SERVICE_DETAIL_HISTORIES, LAB_TEST_RESULTS,
                   IMAGING_RESULTS, IMAGING_ATTACHMENTS (lưu file_key), SERVICE_INVOICES
  Đơn thuốc      : PRESCRIPTIONS, PRESCRIPTION_ITEMS
  Hàng đợi       : QUEUE_TICKET_HISTORIES, QUEUE_TICKET_HISTORY_ITEMS (phiếu đang chạy ở Redis)
  Sự kiện        : OUTBOX_EVENTS, PROCESSED_EVENTS

BILLING-PHARMACY-SERVICE (pet_clinic_billing_pharmacy_db) – 10 bảng
  MEDICINE_CATEGORIES, MEDICINES, MEDICINE_INGREDIENTS, MEDICINE_PRICES, MEDICINE_STOCKS,
  MEDICINE_INVOICES (nháp tự tạo từ đơn thuốc), MEDICINE_INVOICE_ITEMS, INVENTORY_TRANSACTIONS,
  OUTBOX_EVENTS, PROCESSED_EVENTS

REPORTING-SERVICE (pet_clinic_reporting_db) – 5 bảng (mô hình đọc cho báo cáo)
  VISIT_FACTS, REVENUE_FACTS, DAILY_REVENUE_SUMMARIES, DOCTOR_DAILY_PERFORMANCES, PROCESSED_EVENTS

REDIS: phiếu xếp hàng đang chờ / đang phục vụ của hàng đợi Bác sĩ, Xét nghiệm, CĐHA
```

*(Chi tiết cột, khóa, quan hệ: `THIET_KE_CO_SO_DU_LIEU_ERD.md` v4.0.)*

### 44.3. Trục dữ liệu chính (Core Data Backbone)

```text
APPOINTMENTS ─── (1 : N) ─── APPOINTMENT_STATUS_HISTORIES

USER ── (1 : 1) USER_PROFILE ── (1 : 0..1) STAFF_PROFILE ── (1 : 0..1) VETERINARIAN_PROFILE
     └─ (1 : 0..1) PET_OWNER_PROFILE
PET_OWNER (USER)
    ↓ (1 : N)
PET
    ↓ (1 : N)
PET_VISIT ─── (1 : N) ─── PET_VISIT_STATUS_HISTORIES
    ├── (1 : N) ─── VITAL_SIGNS
    ├── (1 : 1) ─── MEDICAL_RECORD
    ├── (1 : N) ─── QUEUE_TICKET_HISTORIES ─── (1 : N) ─── QUEUE_TICKET_HISTORY_ITEMS
    ├── (1 : N) ─── VISIT_SERVICE_DETAILS ─── (1 : N) ─── VISIT_SERVICE_DETAIL_HISTORIES
    │                     ├── (1 : 1) ─── SERVICE_INVOICES
    │                     ├── (1 : N) ─── LAB_TEST_RESULTS
    │                     └── (1 : 0..1) ─ IMAGING_RESULTS ─── (1 : N) ─── IMAGING_ATTACHMENTS
    │
    └── (1 : 0..1) ─ PRESCRIPTION ─── (1 : N) ─── PRESCRIPTION_ITEMS ··· medicine_id ···> MEDICINES

SERVICE_CATEGORY ── (1 : N) SERVICE ── (1 : N) SERVICE_PRICES

MEDICINE_CATEGORY ── (1 : N) MEDICINE ── (1 : N) MEDICINE_INGREDIENTS
                                      ├── (1 : N) MEDICINE_PRICES
                                      ├── (1 : 1) MEDICINE_STOCK
                                      └── (1 : N) INVENTORY_TRANSACTIONS

PRESCRIPTION ··· prescription_id ···> MEDICINE_INVOICE ── (1 : N) MEDICINE_INVOICE_ITEMS ── (N : 1) MEDICINES
(··· = khóa ngoại logic giữa 2 phân hệ; không còn liên kết dòng hóa đơn thuốc ↔ dòng đơn thuốc)
```

### 44.4. Phân rã nghiệp vụ theo vai trò người dùng

```text
USER
 │
 ├── ADMIN
 │      ├── Quản lý nhân sự, gán phòng làm việc cố định
 │      ├── Cấu hình danh mục Dịch vụ, Nhóm dịch vụ, Thuốc (thành phần, quy cách), Xét nghiệm, Tham chiếu
 │      ├── Quản lý bảng giá dịch vụ và giá thuốc có lịch sử
 │      ├── Lập hồ sơ nhân sự, hồ sơ chuyên môn Bác sĩ, gán vai trò
 │      ├── Nhập kho & cân chỉnh kho
 │      └── Xem thống kê, báo cáo doanh thu, công nợ & vận hành
 │
 ├── RECEPTIONIST
 │      ├── Tiếp nhận đặt lịch, check-in
 │      ├── Chọn Bác sĩ cho ca (hàng đợi riêng của từng Bác sĩ)
 │      ├── Thu phí khám, tiền XN / CĐHA → hệ thống phát phiếu xếp hàng
 │      ├── Thu các hóa đơn dịch vụ còn lại, thu công nợ, hoàn tiền khi phòng khám không làm được
 │      └── Bán thuốc theo hóa đơn nháp tự tạo khi chốt ca (sửa số lượng, thu tiền, xuất thuốc) hoặc hủy nháp nếu khách mua ngoài
 │
 ├── VETERINARIAN
 │      ├── Khám lâm sàng, ghi sinh hiệu (nhiều lần đo) & hồ sơ khám (bệnh sử, chẩn đoán sơ bộ / xác định)
 │      ├── Chỉ định dịch vụ cận lâm sàng (Lab, CĐHA) & thực hiện dịch vụ tại phòng
 │      ├── Kết luận chẩn đoán xác định & kê đơn thuốc mang về
 │      └── Chốt đợt khám (và mở lại hồ sơ khi cần sửa sai sót)
 │
 ├── LAB_TECHNICIAN
 │      ├── Gọi số theo phiếu (dịch vụ đã nộp tiền) & lấy mẫu bệnh phẩm
 │      ├── Vận hành máy xét nghiệm tự động
 │      └── Nhập chỉ số đo lường & xác nhận kết quả
 │
 ├── IMAGING_TECHNICIAN
 │      ├── Gọi số theo phiếu CĐHA (X-quang, Siêu âm đã nộp tiền)
 │      ├── Thực hiện chụp chiếu / siêu âm & tải tệp ảnh lên hệ thống
 │      └── Nhập mô tả hình ảnh tổn thương & kết luận hình thái học
 │
 └── PET_OWNER
        ├── Quản lý hồ sơ thú cưng gia đình
        ├── Đặt lịch hẹn trực tuyến (không chọn BS)
        └── Tra cứu lịch sử khám bệnh & đơn thuốc (mua tại phòng khám hoặc mua ngoài)
```

---

## PHỤ LỤC: THAY ĐỔI SO VỚI PHIÊN BẢN 2.0

| Vị trí | Bản cũ | Bản mới | Lý do |
| :--- | :--- | :--- | :--- |
| Mục 0, 3.1, 3.2, 5.3, 8.4, 8.5, 9, 14, 17, 19, 21, 23, 25–27, 29–31, 37–40, 41 (BR-13, 18, 25, 26, 31, 32, 35; thêm BR-37 → BR-41), 43, 44 (**v4.0, 18/11/2026**) | `users` chứa họ tên, phòng; phiếu xếp hàng là bảng `queue_tickets` phát trong giao dịch thu tiền; thông tin đợt khám gộp sinh hiệu + chuyên môn; giá nằm trên `services` / `medicines`; `medicines` gồm cả hoạt chất, giá, tồn; đơn thuốc ở billing; hóa đơn thuốc do Thu ngân lập, dòng trỏ `prescription_items`; báo cáo tổng gọi API từng service; 27 bảng | Hồ sơ người dùng tách theo loại, nhiều vai trò; phiếu trên Redis, phát ngay sau thu tiền qua sự kiện, lịch sử phiếu ở MySQL; đợt khám tách `pet_visits` / `vital_signs` / `medical_records`; bảng giá có lịch sử; thuốc tách thông tin / thành phần / giá / tồn; đơn thuốc ở clinical, hóa đơn thuốc nháp tự tạo khi chốt ca, dòng trỏ `medicines`; phân hệ báo cáo riêng; xóa mềm; 52 bảng | Nhận xét chi tiết của GVHD (Notes.pdf + góp ý bổ sung) |
| Mục 1, 43 (luồng tổng thể) | Thanh toán → Xuất thuốc → Hoàn tất | Thanh toán hóa đơn dịch vụ → Hoàn tất; mua thuốc là nhánh tùy chọn | Khách được mua thuốc ngoài (góp ý GVHD) |
| Mục 2.2, 14 | Cân nặng trên hồ sơ thú cưng; Visit lưu phòng, thời gian bắt đầu / kết thúc | Cân nặng lấy từ lần khám gần nhất; phòng suy ra từ Bác sĩ; thời điểm lấy từ lịch sử | Bỏ thuộc tính trùng lặp / dẫn xuất |
| Mục 3.5, 8 (sơ đồ) | Lễ tân cân đo sinh hiệu ban đầu | Lễ tân không cân đo; Bác sĩ đo trong phòng khám | Mâu thuẫn với mục 8.1, 8.2, 17 |
| Mục 3.5, 29 | Thu tiền VietQR / POS; Invoice lưu phương thức thanh toán | Thanh toán ngoài quầy, không lưu phương thức | CSDL không có cột lưu; khớp FR-57 |
| Mục 5.3 | Truy vấn đếm slot không giải thích việc tính `CHECKED_IN`; JOIN `users` trực tiếp | Giữ `CHECKED_IN` trong số chỗ đã chiếm (có giải thích); số Bác sĩ lấy qua API `auth-service` | Thống nhất cách đếm slot; database-per-service |
| Mục 7.2 | Ghi `cancel_reason` | Lý do, người hủy, thời điểm ghi ở `appointment_status_histories` | Cột không tồn tại |
| Mục 7.4 | `booked_count < 3`; cập nhật `end_time` | `booked_count < max_capacity`; không có `end_time` | Sức chứa tính động; khung giờ cố định 30 phút |
| Mục 7.6 | Lễ tân rà soát cuối ca | Tác vụ định kỳ tại `start_time + 30'`; khách đến sau xử lý như vãng lai | Khớp EX-01, FR-17, FR-18 |
| Mục 8.4, 9 | Hàng đợi sảnh 3 tầng (cấp cứu / có hẹn đúng giờ / vãng lai + trễ) | 2 tầng: cấp cứu → còn lại theo thời gian check-in | Khớp FR-21, UC-20, AD-02, chỉ mục `idx_visits_queue` |
| Mục 11, 12 | `BUSY` chỉ khi đang khám; khóa khi có `RESULTS_READY` bất kỳ | `BUSY` gồm ca đã phân công; khóa chỉ với ca vừa có kết quả | Chống phân công trùng; khớp EX-10 |
| Mục 15, 33, 42.2 | `WAITING_RESULTS → CANCELLED`; thiếu nhánh chốt ca GĐ1, tạm hoãn, mở lại | Bỏ về giữa chừng → `COMPLETED` + công nợ; thêm các nhánh còn thiếu | Không mất doanh thu; đồng bộ State Machine v3.0 |
| Mục 17, 19, 20 | Snapshot giá vào chỉ định; không có dịch vụ khám tự động | Phí khám là dịch vụ tạo tự động; mỗi chỉ định có 1 hóa đơn dịch vụ; thêm nhóm dịch vụ tại phòng | Hóa đơn riêng cho từng dịch vụ |
| Mục 17.1 | Huy hiệu EX-09 không có căn cứ dữ liệu; gửi SMS; "chuyển chi phí sang hóa đơn ghi nợ" | Thao tác "Đã lấy mẫu"; thông báo ứng dụng; hóa đơn sẵn có giữ làm công nợ | Khớp EX-06, EX-09, EX-11 |
| Mục 21 | Lọ vaccine / viên thuốc dùng tại chỗ là `Medicine` | Thuốc / vật tư dùng tại chỗ tính trọn gói vào giá dịch vụ; đơn thuốc chỉ cho thuốc mang về | Thuốc đã dùng tại phòng không thể "mua ngoài" |
| Mục 22, 23 | Gán `evaluation = 'HIGH'`; `unit_price` ở chỉ định và đơn thuốc | Nhãn tính khi hiển thị; giá snapshot ở `service_invoices`, `medicine_invoice_items` | Bỏ cột dẫn xuất và cột giá trùng |
| Mục 25, 26 | Đơn thuốc lưu đơn giá; giá thuốc chốt lúc kê | Đơn thuốc không giá, không trạng thái; giá chốt lúc bán | Mua thuốc là tùy chọn |
| Mục 27 | "Mở lại Visit" chưa có quy tắc | Người thực hiện, điều kiện, ảnh hưởng tới hóa đơn | Thiếu chuyển trạng thái |
| Mục 28–32 | 1 hóa đơn / ca; tổng = dịch vụ + thuốc − chiết khấu; xuất thuốc sau thanh toán | Tiền tính theo từng hóa đơn qua VIEW; 2 loại hóa đơn; bán thuốc tùy chọn, thu tiền và trừ kho cùng giao dịch | Lược đồ v3.0 |
| Mục 37–40 | `Status`, `ACTIVE/INACTIVE`; tồn kho = đầu + nhập − xuất; doanh thu chung chung | `is_active`, `vat_rate`; tồn kho = Σ nhật ký kho; doanh thu từ 2 loại hóa đơn, thêm công nợ | Khớp tên cột và lược đồ v3.0 |
| Mục 41 | BR-19, 26–31 theo mô hình 1 hóa đơn / ca | Sửa BR-03, 08, 09, 11, 17–19, 21, 24–31; thêm BR-32, BR-33 | Đồng bộ Đặc tả Use Case v3.0 |
| Mục 42 | Đánh số "48.1", "48.2" | "42.1", "42.2" | Sai số mục |
| Mục 44 | 23 thực thể, có `INVOICES`, `INVOICE_ITEMS` | 25 thực thể theo 4 service | Lược đồ v3.0 |
| Mục 8.1 (rà soát 10/11) | Cập nhật lịch hẹn `CHECKED_IN` và tạo đợt khám "trong cùng một giao dịch" | Đợt khám tạo trong giao dịch của `clinical-service`; lịch hẹn chuyển `CHECKED_IN` qua `VisitCheckedInEvent` | Hai CSDL khác nhau (Kiến trúc mục 5.3) |
| Mục 10 (rà soát 10/11) | Không có đổi / gỡ phân công | Cho đổi Bác sĩ hoặc gỡ phân công khi ca chưa bắt đầu khám | Khách tạm ra ngoài không khóa Bác sĩ |
| Quy trình CĐHA (rà soát 10/11) | Lưu ảnh lên "MinIO/S3" | Docker Volume `/app/uploads/imaging/` | Hệ thống không dùng MinIO |
| Mục 27, 29, 30 (rà soát 10/11) | Hủy ca GĐ 1 không xét dịch vụ tại phòng; EX-15 "khách giảm số lượng" không có thao tác; chặn sửa đơn chỉ khi đã bán | Hủy chỉ khi chưa có dịch vụ tại phòng hoàn thành; sửa hóa đơn thuốc `PENDING`; chặn sửa đơn khi có hóa đơn thuốc chưa hủy | Đồng bộ State Machine và Use Case |
| Mục 40 (rà soát 10/11) | BR-32 nằm trước BR-29 | Xếp lại theo thứ tự số | Trình bày |
| Mục 2, 4, 5.3, 8, 9, 10, 11, 12, 15, 16, 17, 17.1, 17.2, 17.3, 42.2, 41 (rà soát 11/11) | Một hàng đợi chung ở sảnh; Lễ tân chỉ phân công khi bác sĩ rảnh, phân xong bác sĩ thành `BUSY`; Khóa ưu tiên chặn Lễ tân; phòng CLS "Tạm hoãn" sang tab riêng rồi "Recall" ghim "Ưu tiên kế tiếp"; GĐ 2 hoãn ngược `IN_PROGRESS → RESULTS_READY` | Mỗi bác sĩ có hàng đợi riêng, Lễ tân xếp ca ngay khi tiếp nhận (gợi ý bác sĩ ít người chờ); bác sĩ / KTV "Gọi số tiếp theo"; gọi không thấy thì "Đẩy lùi 1 bậc"; ca có kết quả tự lên đầu hàng đợi bác sĩ; trạng thái bác sĩ còn `AVAILABLE` / `BUSY`; sửa BR-11, BR-12, thêm BR-34 | Lễ tân không phải chờ bác sĩ rảnh; một cơ chế hàng đợi cho phòng khám, Xét nghiệm, CĐHA |
| Mục 3, 5.3, 8, 9, 15, 17, BR-09, BR-12, BR-34 (cập nhật 13/11) | "Gọi số tiếp theo" + "Đẩy lùi 1 bậc" (ca vắng xuống ngay sau người kế tiếp, đếm số lần lùi, ca cấp cứu bị lùi mất ưu tiên); mỗi dịch vụ CLS là một dòng hàng đợi | "Gọi" theo từng dòng (không đổi thứ tự), khách vắng thì gọi ca khác, khách quay lại thì gọi lại; ca cấp cứu luôn giữ ưu tiên; dịch vụ cùng đợt khám, cùng phòng gộp thành một ca | Đẩy lùi 1 bậc làm hai ca đầu hàng đổi chỗ mãi mãi (ca thứ 3, 4 không được gọi); gọi theo từng dòng giống thực tế phòng khám |
| Mục bán thuốc, BR-32 (cập nhật 13/11) | Số lượng mua mỗi thuốc không vượt số lượng bác sĩ kê | Số kê chỉ tham khảo; mua nhiều hơn / ít hơn / bằng, không vượt tồn kho; màn hình bán thuốc hiện tồn kho | Khách thực tế có thể cần khác đơn; ràng buộc đúng là tồn kho |
| Mục 0, 1, 3.5, 5.3, 8 (thêm 8.5), 9, 10, 11, 12, 14, 15, 16, 17, 17.1, 17.2, 17.3, 19, 20, 23, 26, 28, 29, 30, 32, 33, 40, 41 (BR-09, 11, 17, 25, 27, 28, 33, 34, thêm BR-35, BR-36), 42.2, 43, 44 (cập nhật 17/11) | Ca vào hàng đợi Bác sĩ ngay khi tiếp đón; phí khám tạo lúc "Bắt đầu khám"; dịch vụ CLS tự vào hàng đợi phòng khi chỉ định; thu tiền một lần khi chốt ca; hàng đợi đọc `queue_order` trên `pet_visits` / `visit_service_details`; không hoàn tiền | Phí khám lập lúc tiếp đón, **nộp xong mới phát phiếu vào hàng đợi Bác sĩ**; dịch vụ làm tại phòng làm ngay, thu khi chốt ca; **Xét nghiệm / CĐHA nộp tiền xong mới phát phiếu phòng**; màn hình Thu ngân 3 mục (3 lần thu tiền); hàng đợi là bảng phiếu xếp hàng `queue_tickets` (+ `queue_ticket_items`), 27 bảng; ca có kết quả nhận phiếu ưu tiên; cấp cứu khám trước thu sau; phí khám không hoàn, chỉ hoàn (`REFUNDED`) khi phòng khám không làm được | Góp ý GVHD: tách quy trình thanh toán khỏi quy trình khám như bệnh viện; tách dữ liệu hay thay đổi (hàng đợi) khỏi dữ liệu ít thay đổi (hồ sơ khám) |
