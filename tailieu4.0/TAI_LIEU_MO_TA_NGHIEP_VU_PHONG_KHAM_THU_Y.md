# TÀI LIỆU MÔ TẢ NGHIỆP VỤ HỆ THỐNG QUẢN LÝ PHÒNG KHÁM THÚ Y

> **Tài liệu nền tảng phục vụ xây dựng biểu đồ Use Case, Đặc tả Use Case và Thiết kế CSDL (ERD).**  
> **Phiên bản:** 3.0 (đồng bộ lược đồ CSDL v3.0: mỗi dịch vụ có hóa đơn riêng, mua thuốc tại phòng khám là tùy chọn; khớp State Machine, Activity, Use Case, Ngoại lệ và FR/NFR v3.0). Danh sách thay đổi ở Phụ lục cuối tài liệu.

---

## 0. Các định hướng nghiệp vụ cốt lõi (Cập nhật mới)

- **Quy trình đặt lịch:** Chủ nuôi **chỉ đặt ngày + khung giờ + nhu cầu khám**, tuyệt đối **không chọn bác sĩ**.
- **Tiếp đón:** Khi khách đến phòng khám, lịch hẹn chuyển trạng thái thành `CHECKED_IN` và chuyển tiếp thành Đợt khám (`Pet Visit`).
- **Phân công ca khám:** **Mỗi bác sĩ có một hàng đợi riêng.** Lễ tân xếp ca vào hàng đợi của bác sĩ ngay khi tiếp nhận, dựa trên số người đang chờ của từng bác sĩ (hệ thống gợi ý bác sĩ ít người chờ nhất), không phải chờ bác sĩ rảnh. Bác sĩ tự gọi số tiếp theo trong hàng đợi của mình. Hệ thống giả định tất cả bác sĩ đều đi làm đầy đủ, không quản lý ca kíp và không quản lý nghỉ phép.
- **Phòng khám:** Mỗi bác sĩ được gán một **số phòng khám cố định** (quản lý trực tiếp qua thuộc tính `room_number` trong thông tin tài khoản bác sĩ, không tạo bảng phòng khám riêng).
- **Vai trò chuyên môn:** Phân định rõ ràng giữa Bác sĩ khám lâm sàng chính (`VETERINARIAN`), Kỹ thuật viên/Bác sĩ xét nghiệm (`LAB_TECHNICIAN`), và Kỹ thuật viên/Bác sĩ chẩn đoán hình ảnh (`IMAGING_TECHNICIAN`), giúp chuẩn hóa chuyên môn và quản lý phòng ban hiệu quả.
- **Mô hình tài khoản CSDL:** Sử dụng mô hình tập trung **`users` + `roles`**, không phân mảnh thành các bảng tài khoản riêng lẻ (`veterinarians`, `receptionists`, ...).

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

> **Đặt lịch → Tiếp đón → Xếp vào hàng đợi riêng của bác sĩ → Bác sĩ gọi số → Khám → Chỉ định → Kết quả → Chẩn đoán → Kê đơn → Thanh toán hóa đơn dịch vụ → Hoàn tất** *(→ Mua thuốc theo đơn tại phòng khám nếu khách chọn; khách có thể mua thuốc ở nơi khác).*

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
- **Quản lý tài khoản & nhân sự:** Tạo, kích hoạt, khóa tài khoản nhân viên (Bác sĩ, Lễ tân, Kỹ thuật viên Xét nghiệm, Kỹ thuật viên CĐHA); phân công số phòng làm việc cố định cho Bác sĩ và Kỹ thuật viên.
- **Cấu hình danh mục chuyên môn:** Quản lý danh mục dịch vụ kỹ thuật (`services`), danh mục thuốc & tủ thuốc (`medicines`), quản lý chỉ số xét nghiệm (`lab_test_items`) và thiết lập khoảng tham chiếu sinh lý chuẩn theo loài (`lab_test_reference_ranges`).
- **Giám sát kho dược:** Quản lý nhập/xuất kho, theo dõi số lượng tồn kho khả dụng và nhận cảnh báo khi thuốc chạm ngưỡng tối thiểu (`min_stock_alert`).
- **Báo cáo & Thống kê:** Xem báo cáo doanh thu theo thời gian, theo dịch vụ (từ hóa đơn dịch vụ), theo thuốc (từ hóa đơn thuốc); theo dõi công nợ và hiệu suất khám bệnh của các phòng khám.

> **Lưu ý:** Quản trị viên **không trực tiếp tham gia quy trình khám chữa bệnh** hay can thiệp vào chuyên môn của đợt khám.

---

### 3.2. Nhóm Bác sĩ thú y (VETERINARIAN)

Bác sĩ thú y là nhân sự trực tiếp chịu trách nhiệm về chuyên môn y tế trong toàn bộ quá trình khám chữa bệnh cho thú cưng.

**Đặc điểm nghiệp vụ và phân quyền:**
- **Cùng vai trò nghiệp vụ:** Tất cả các bác sĩ trong hệ thống đều có chung vai trò `VETERINARIAN` và cùng tập quyền hạn chuyên môn, không phân chia bác sĩ trưởng hay bác sĩ thường, không chia chuyên khoa trong phạm vi đồ án.
- **Phòng khám cố định:** Mỗi Bác sĩ được cấu hình làm việc tại một **số phòng khám cố định** (quản lý trực tiếp qua thuộc tính `room_number` trong thông tin tài khoản `users`, ví dụ: Bác sĩ A gắn với Phòng P01, Bác sĩ B gắn với Phòng P02). Khi Lễ tân phân công ca khám cho bác sĩ, bệnh nhân tự động được hướng dẫn vào đúng số phòng cố định này mà không cần bảng phòng khám riêng.
- **Phạm vi công việc:**
  - Khám lâm sàng sơ bộ (Giai đoạn 1): Tiếp nhận ca từ hàng đợi, đo sinh hiệu, thăm khám, tra cứu tiền sử bệnh án.
  - Ra chỉ định dịch vụ kỹ thuật: Chỉ định xét nghiệm máu, siêu âm, chụp X-quang (chuyển tới hàng đợi chuyên biệt của phòng Xét nghiệm và phòng CĐHA).
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

Lễ tân là nhân sự điều phối toàn bộ hoạt động tiếp đón, vận hành hàng đợi, thu tiền các hóa đơn dịch vụ và bán thuốc theo đơn tại quầy (khi khách chọn mua).

**Phạm vi công việc và quyền hạn:**
- **Tiếp đón & Quản lý khách hàng:** Tra cứu thông tin chủ nuôi, tạo mới hồ sơ khách hàng (hệ thống tự động cấp tài khoản), khởi tạo và cập nhật hồ sơ thú cưng.
- **Quản lý lịch hẹn:** Tiếp nhận và duyệt các yêu cầu đặt lịch trực tuyến (`PENDING` $\rightarrow$ `CONFIRMED` hoặc `CANCELLED`); tạo lịch hẹn mới qua điện thoại hoặc đặt trước trực tiếp tại quầy; thực hiện đổi ngày/khung giờ hẹn cho khách.
- **Tiếp nhận tại quầy (Check-in):** Thực hiện check-in cho khách có lịch hẹn hoặc tiếp nhận khách vãng lai (Walk-in), ghi lý do đến khám, đánh giá nhanh dấu hiệu cấp cứu (**Lễ tân không cân, không đo thân nhiệt**; việc này do Bác sĩ thực hiện trong phòng khám), chuyển đổi Lịch hẹn thành Đợt khám (`Pet Visit`) ở trạng thái chờ khám (`WAITING`).
- **Điều phối hàng đợi & Phân công phòng khám:** Giám sát danh sách chờ phân công và hàng đợi riêng của từng Bác sĩ, xử lý ưu tiên ca cấp cứu, xếp ca vào hàng đợi Bác sĩ (theo gợi ý Bác sĩ ít người chờ nhất) và chuyển ca giữa các hàng đợi khi cần.
- **Thanh toán & Bán thuốc:** Mở bảng kê các hóa đơn dịch vụ của ca (mỗi dịch vụ một hóa đơn, đã được hệ thống lập sẵn từ lúc Bác sĩ chỉ định), áp dụng giảm giá trên từng hóa đơn, xác nhận thanh toán sau khi khách trả tiền ngoài quầy (tiền mặt hoặc chuyển khoản; hệ thống không lưu phương thức thanh toán). Nếu khách chọn mua thuốc theo đơn tại phòng khám: lập hóa đơn thuốc, lấy thuốc, xác nhận thanh toán (trừ tồn kho tự động trong cùng một giao dịch an toàn) và in phiếu hướng dẫn dùng thuốc; nếu khách mua ngoài thì in đơn thuốc trao cho khách.

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
- Lễ tân phân công bệnh nhân bằng cách **xếp vào hàng đợi riêng của từng bác sĩ** ngay khi tiếp nhận, cân bằng theo số người đang chờ; không phụ thuộc bác sĩ đang rảnh hay đang bận.

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
- **Tiếp nhận theo thứ tự có mặt (FCFS):** Khách đến quầy check-in trước có `queue_order` nhỏ hơn nên đứng trước trong hàng đợi.
- **Chia đều vào hàng đợi riêng của từng Bác sĩ:** Với $N_{\text{active}}$ Bác sĩ và $2 \times N_{\text{active}}$ khách mỗi khung giờ, Lễ tân xếp mỗi Bác sĩ khoảng 2 khách (hệ thống gợi ý Bác sĩ ít người chờ nhất). Khách thứ 2 của mỗi Bác sĩ chờ 5 – 10 phút trước phòng và được gọi ngay khi Bác sĩ chuyển khách thứ nhất sang phòng cận lâm sàng.
- **Thứ tự trong mỗi hàng đợi Bác sĩ:** Ca cấp cứu khẩn cấp (`is_emergency = true`) đứng đầu; ca có kết quả cận lâm sàng quay lại (`RESULTS_READY`) tự lên đầu, ngay sau ca cấp cứu; ca thông thường xếp theo thời gian check-in, có tính các lần bị "Đẩy lùi 1 bậc" (mục 9).

**Thuật toán kiểm tra trạng thái khung giờ trên giao diện:**
Khi khách hàng chọn một ngày trên lịch, hệ thống thực hiện các bước tính toán:
1. **Bước 1:** Xác định sức chứa tối đa của một khung giờ tại thời điểm hiện tại:
   ```sql
   SELECT COUNT(*) * 2 AS max_capacity
   FROM users u
   JOIN roles r ON u.role_id = r.id
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
                                                                                       │
                                                                                       ▼
                                                                             Đưa vào HÀNG ĐỢI KHÁM
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
   - Gán `queue_order` = thời điểm tiếp nhận; nếu Lễ tân chọn Bác sĩ (hệ thống gợi ý Bác sĩ ít người chờ nhất) thì ca vào **hàng đợi riêng của Bác sĩ đó**, chưa chọn thì ca nằm trong **danh sách chờ phân công**.
7. **Sau khi giao dịch trên commit**, `clinical-service` phát sự kiện `VisitCheckedInEvent`; `appointment-service` nhận sự kiện, chuyển lịch hẹn sang `CHECKED_IN` và ghi 1 dòng lịch sử (`CONFIRMED` → `CHECKED_IN`) trong giao dịch riêng của mình. Hai CSDL khác nhau nên không ghi chung một giao dịch; độ trễ chỉ vài trăm mili giây và lịch vẫn được tính là chiếm chỗ của khung giờ.

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
   - Trạng thái ca khám là `WAITING` (Chờ khám) và được xếp vào hàng đợi Bác sĩ (hoặc danh sách chờ phân công) như mục 8.1.

### 8.3. Luồng tiếp nhận khẩn cấp (Emergency Priority Case)
- Áp dụng khi thú cưng gặp tình trạng nguy kịch: Tai nạn giao thông, co giật, khó thở dữ dội, ngộ độc, xuất huyết ồ ạt.
- Lễ tân bấm chọn nút **"Tiếp nhận Cấp cứu"**:
  - Hệ thống gắn cờ ưu tiên đặc biệt (`is_emergency = TRUE`, nhãn nổi bật đỏ).
  - Lễ tân xếp ngay ca vào hàng đợi của một Bác sĩ (ưu tiên Bác sĩ sắp khám xong); ca đứng **đầu hàng đợi** đó, vượt qua mọi ca thông thường, và được gọi ngay khi Bác sĩ khám xong ca hiện tại.

### 8.4. Quy tắc ưu tiên trong hàng đợi
Danh sách chờ phân công và hàng đợi của từng Bác sĩ đều sắp xếp theo cùng một quy tắc:
1. **Ưu tiên tuyệt đối:** Ca cấp cứu khẩn cấp (`is_emergency = TRUE`) chưa bị đẩy lùi lần nào luôn đứng đầu.
2. **Ca có kết quả cận lâm sàng quay lại (chỉ ở hàng đợi Bác sĩ):** khi ca chuyển `RESULTS_READY`, hệ thống đặt `queue_order` nhỏ hơn mọi ca trong hàng đợi của Bác sĩ khám chính, nên ca đứng ngay sau ca cấp cứu.
3. **Thứ tự tiếp nhận:** Các ca còn lại (có lịch hẹn hoặc vãng lai) theo `queue_order`, khởi tạo bằng thời điểm check-in (đến trước phục vụ trước) và thay đổi khi bị "Đẩy lùi 1 bậc".

Truy vấn: `ORDER BY (is_emergency AND skip_count = 0) DESC, queue_order ASC`, dùng chỉ mục `idx_visits_queue (doctor_id, status, is_emergency, queue_order)`.

> **Vì sao không có tầng "khách có hẹn đúng giờ":** lịch hẹn chỉ dùng để giữ chỗ và cân bằng số khách mỗi khung giờ (mục 5.3); khi khách đã đến quầy, thứ tự check-in phản ánh đúng thứ tự đến. Ngoài ra giờ hẹn nằm ở CSDL của `appointment-service`, còn hàng đợi nằm ở `clinical-service`; tầng "đúng giờ hẹn" sẽ cần truy vấn liên service cho mỗi lần tải hàng đợi.

---

## 9. Hàng đợi khám

Hệ thống có **bốn loại hàng đợi**, tất cả dùng chung cơ chế "Gọi số tiếp theo" và "Đẩy lùi 1 bậc":

| Hàng đợi | Ai xếp ca vào | Ai gọi số | Gồm những ca nào |
| :--- | :--- | :--- | :--- |
| **Danh sách chờ phân công** | Hệ thống, khi Lễ tân tiếp nhận mà chưa chọn Bác sĩ | (không gọi) – Lễ tân xếp vào hàng đợi Bác sĩ | `WAITING`, `doctor_id IS NULL` |
| **Hàng đợi riêng của từng Bác sĩ** | Lễ tân (lúc tiếp nhận hoặc từ danh sách chờ); hệ thống tự đưa ca có kết quả CLS về | Bác sĩ | `WAITING` và `RESULTS_READY` có `doctor_id` của Bác sĩ đó |
| **Hàng đợi phòng Xét nghiệm** | Hệ thống, tự động khi Bác sĩ chỉ định xét nghiệm | KTV Xét nghiệm | Dịch vụ `LABORATORY` đang `PENDING` |
| **Hàng đợi phòng CĐHA** | Hệ thống, tự động khi Bác sĩ chỉ định siêu âm / X-quang | KTV / Bác sĩ CĐHA | Dịch vụ `IMAGING` đang `PENDING` |

**Gọi số tiếp theo:** người phụ trách hàng đợi (khi không đang làm dở ca nào) bấm *"Gọi số tiếp theo"*; hệ thống chọn ca đứng đầu, hiển thị số thứ tự và số phòng trên màn hình sảnh và gửi thông báo đến ứng dụng của chủ nuôi. Ca chưa đổi trạng thái cho tới khi thú cưng vào phòng và người phụ trách bấm "Bắt đầu khám" / "Bắt đầu Giai đoạn 2" / "Bắt đầu thực hiện".

**Đẩy lùi 1 bậc:** gọi 2–3 lần không thấy, người phụ trách bấm *"Đẩy lùi 1 bậc"*: ca được xếp ra **ngay sau người kế tiếp**, người kế tiếp lên đầu và được gọi ngay. Ví dụ hàng đợi Bác sĩ A là `[Milo, Lu, Na]`: gọi Milo không thấy → đẩy lùi → `[Lu, Milo, Na]`, Bác sĩ gọi Lu. Không giới hạn số lần bị lùi, hệ thống chỉ hiển thị số lần (`skip_count`). Ca cấp cứu đã bị lùi được xếp như ca thường. Nếu phía sau không còn ai, ca giữ nguyên vị trí. Khách quay lại chỉ cần chờ tới lượt, không cần báo lại. Về dữ liệu: `queue_order` của ca bị lùi = trung bình cộng `queue_order` của ca ngay sau và ca sau nữa (không có ca sau nữa thì = ca ngay sau + 1; nếu người kế tiếp là ca cấp cứu chưa bị lùi thì = `queue_order` của ca thường đầu tiên − 1).

---

## 10. Phân công bác sĩ

**Khách không chọn bác sĩ.** Lễ tân là người phân công, bằng cách **xếp ca vào hàng đợi riêng của một bác sĩ**. Việc này làm được bất cứ lúc nào, kể cả khi bác sĩ đang khám, nên Lễ tân không phải chờ bác sĩ rảnh.

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

Khi ca chưa bắt đầu khám, Lễ tân có thể **chuyển ca sang hàng đợi bác sĩ khác** (ca giữ thứ tự theo thời điểm tiếp nhận) hoặc **gỡ phân công** (ca về danh sách chờ phân công), ví dụ khi một bác sĩ quá đông hoặc nghỉ đột xuất. Ca có kết quả cận lâm sàng luôn thuộc bác sĩ khám chính.

---

## 11. Nguyên tắc phân công & Ưu tiên ca có kết quả

Bảng điều phối hiển thị cho mỗi Bác sĩ:

```text
Bác sĩ
Số phòng cố định
Trạng thái (AVAILABLE / BUSY)
Số người đang chờ và danh sách theo số thứ tự (ca có kết quả, ca cấp cứu, số lần bị đẩy lùi)
```

**Bảo vệ ca đã làm cận lâm sàng:** khi một ca vừa đủ kết quả xét nghiệm / CĐHA, hệ thống tự đưa ca lên **đầu hàng đợi của Bác sĩ khám chính** (chỉ sau ca cấp cứu). Lễ tân vẫn xếp ca mới vào hàng đợi Bác sĩ này bình thường, nhưng ca mới đứng sau; Bác sĩ khám xong ca hiện tại sẽ gọi ca có kết quả trước. Khách đã chờ xét nghiệm 15 – 30 phút không bị khách mới chen lượt, mà Lễ tân cũng không bị khóa thao tác.

> Bản trước dùng "Khóa ưu tiên" (Priority Lock): chặn Lễ tân phân ca mới khi Bác sĩ có ca vừa có kết quả. Cơ chế đó cần thiết khi mỗi Bác sĩ chỉ nhận 1 ca từ hàng đợi chung; với hàng đợi riêng, việc đặt ca có kết quả lên đầu hàng là đủ.

---

## 12. Trạng thái bác sĩ

Trạng thái phục vụ tức thời của Bác sĩ được hệ thống tự động nhận diện theo thời gian thực, gồm 2 trạng thái:

```text
AVAILABLE
BUSY
```

- **`BUSY` (Đang khám):** Bác sĩ đang khám một ca (`IN_PROGRESS`, Giai đoạn 1 hoặc 2). Bác sĩ không được gọi thêm số khi đang khám.
- **`AVAILABLE` (Sẵn sàng):** Bác sĩ không khám ca nào và được bấm "Gọi số tiếp theo".

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
- Thời gian tiếp nhận.
- Thứ tự trong hàng đợi (`queue_order`) và số lần bị đẩy lùi 1 bậc (`skip_count`).
- Thời gian bắt đầu khám, chốt ca, hoàn tất, lý do hủy (lấy từ lịch sử trạng thái `pet_visit_status_histories`, không lưu thành cột riêng).
- Cân nặng.
- Thân nhiệt.
- Triệu chứng ban đầu.
- Chẩn đoán.
- Hướng điều trị.
- Lời dặn.
- Trạng thái.

---

## 15. Trạng thái Visit (Vòng đời Đợt khám - Chu kỳ Bất đồng bộ)

Quy trình khám chữa bệnh tại phòng khám thú y **không phải là một màn hình nhập liệu CRUD tuyến tính đơn giản**, mà là một **quy trình y tế bất đồng bộ (Asynchronous Multi-stage Workflow)** chia làm 2 giai đoạn nếu có phát sinh dịch vụ cận lâm sàng:

```text
                 ┌─────────┐
                 │ WAITING │ (Trong hàng đợi riêng của Bác sĩ)
                 └────┬────┘
                      │ Bác sĩ gọi số, thú cưng vào phòng, bấm "Bắt đầu khám"
                      ↓
               ┌─────────────┐
        ┌───── │ IN_PROGRESS │ (Giai đoạn 1: Khám lâm sàng & Ra chỉ định)
        │      └──────┬──────┘
        │             │ 
        │ (Nếu có chỉ │ Bác sĩ gửi phiếu chỉ định Cận lâm sàng
        │  định Lab / │ Thú cưng sang phòng XN / Siêu âm
        │  CĐHA)      ↓ (Bác sĩ tạm giải phóng về AVAILABLE để khám ca khác)
        │      ┌─────────────────┐
        │      │ WAITING_RESULTS │ (Chờ máy chạy XN / Chụp chiếu 15-45 phút)
        │      └────────┬────────┘
        │               │ Phòng Cận lâm sàng nhập xong kết quả
        │               ↓
        │      ┌─────────────────┐
        │      │  RESULTS_READY  │ (Đã có đủ KQ - Lên đầu hàng đợi Bác sĩ)
        │      └────────┬────────┘
        │               │ Bác sĩ gọi số, thú cưng vào phòng, bấm "Bắt đầu GĐ 2"
        │               ↓
        │      ┌─────────────┐
        └────> │ IN_PROGRESS │ (Giai đoạn 2: Đọc KQ, Chẩn đoán xác định & Kê đơn)
               └──────┬──────┘
                      │ Bác sĩ chốt chuyên môn & kê đơn
                      ↓
             ┌──────────────────┐
             │ WAITING_PAYMENT  │ (Thu ngân thu tiền các hóa đơn dịch vụ)
             └────────┬─────────┘
                      │ Mọi hóa đơn dịch vụ đã PAID hoặc CANCELLED
                      ↓  (không phụ thuộc việc mua thuốc)
                ┌───────────┐
                │ COMPLETED │ (Hoàn tất, lưu bệnh án vĩnh viễn)
                └───────────┘

Nhánh rẽ khác:
- IN_PROGRESS (GĐ 1) ───(Không cần cận lâm sàng: khám thường / tiêm phòng / thủ thuật, chốt ca)──→ WAITING_PAYMENT
- WAITING_PAYMENT    ───(Bác sĩ phụ trách / Admin mở lại hồ sơ để sửa sai sót, có lý do)──────→ IN_PROGRESS

Nhánh hủy / kết thúc đặc biệt:
- WAITING            ───(Khách bỏ về / lỗi tiếp nhận – EX-03)──────────────────────────────────→ CANCELLED
- IN_PROGRESS (GĐ 1) ───(Khách từ chối khám / Chuyển viện, không thu phí)─────────────────────→ CANCELLED
- WAITING_RESULTS    ───(Khách bỏ về giữa chừng – EX-11: hủy dịch vụ chưa làm, giữ công nợ)───→ COMPLETED
- RESULTS_READY      ───(Khách bỏ về không quay lại đọc KQ – EX-11, giữ công nợ)──────────────→ COMPLETED
```

> **Gọi số không thấy khách** (cả `WAITING` và `RESULTS_READY`) không phải là bước chuyển trạng thái: Bác sĩ "Đẩy lùi 1 bậc" (mục 9, EX-10), ca giữ nguyên trạng thái và đứng sau người kế tiếp.

> **Ghi chú:** Bản 2.0 cho `WAITING_RESULTS → CANCELLED` khi khách bỏ về. Từ v3.0 chuyển thành `COMPLETED` kèm công nợ, vì các dịch vụ đã thực hiện (phí khám, xét nghiệm đã có kết quả) vẫn phải thu tiền; `CANCELLED` chỉ dùng khi ca bị hủy không thu phí.

---

## 16. WAITING – Chờ khám ban đầu

Sau khi tiếp nhận tại quầy (từ lịch hẹn hoặc khách vãng lai):
- `Visit.status = WAITING`
- Ca khám nằm trong hàng đợi riêng của Bác sĩ được xếp (hoặc trong danh sách chờ phân công nếu Lễ tân chưa chọn Bác sĩ), có số thứ tự hiển thị trên màn hình sảnh.
- Thú cưng và chủ nuôi ngồi chờ trước phòng Bác sĩ. Chưa phát sinh hoạt động chuyên môn.

---

## 17. IN_PROGRESS (Giai đoạn 1) – Khám lâm sàng & Quyết định chỉ định

- Bác sĩ (không đang khám ca nào) bấm **"Gọi số tiếp theo"**; hệ thống gọi ca đứng đầu hàng đợi của Bác sĩ. Gọi 2–3 lần không thấy thì Bác sĩ "Đẩy lùi 1 bậc" và gọi người kế tiếp (mục 9).
- Thú cưng vào phòng khám cố định của Bác sĩ. Bác sĩ bấm **"Bắt đầu khám"** -> `Visit.status = IN_PROGRESS`. Bác sĩ chuyển sang trạng thái bận (`BUSY`). Hệ thống **tự động tạo chỉ định dịch vụ khám** (nhóm `EXAMINATION`, mặc định "Khám tổng quát") **kèm 1 hóa đơn dịch vụ `PENDING`** – phí khám cũng là một dịch vụ có hóa đơn riêng.
- Bác sĩ tiến hành **Khám lâm sàng & Đo sinh hiệu**:
  - Hỏi bệnh sử, triệu chứng phát sinh.
  - Đặt thú cưng lên bàn cân (`weight_at_visit`) và dùng nhiệt kế đo thân nhiệt (`temperature`), ghi nhận vào bệnh án.
  - Nghe tim phổi, nắn bụng, kiểm tra niêm mạc, hạch bạch huyết.
  - Ghi nhận nhận định lâm sàng ban đầu.
- **Rẽ nhánh nghiệp vụ:**
  - **Trường hợp 1 (Khám thông thường / Tiêm phòng / Tẩy giun / Thủ thuật):** Không cần cận lâm sàng -> Bác sĩ chỉ định các dịch vụ thực hiện tại phòng nếu cần (mỗi dịch vụ sinh 1 hóa đơn dịch vụ `PENDING`), thực hiện và đánh dấu "Đã thực hiện", kết luận chẩn đoán, kê đơn thuốc mang về (nếu có) và bấm Chốt ca -> Chuyển thẳng sang `WAITING_PAYMENT`.
  - **Trường hợp 2 (Cần xét nghiệm máu / Siêu âm / X-quang):** Bác sĩ lập phiếu chỉ định dịch vụ cận lâm sàng; mỗi dịch vụ được chỉ định sinh 1 hóa đơn dịch vụ `PENDING` (chốt đơn giá, thuế suất tại thời điểm này). Khi xác nhận gửi chỉ định (yêu cầu đã nhập cân nặng, thân nhiệt), dịch vụ khám của GĐ 1 được ghi nhận hoàn thành và ca khám chuyển sang trạng thái `WAITING_RESULTS`. Bác sĩ trở về `AVAILABLE` và gọi số tiếp theo trong hàng đợi của mình, tránh tình trạng tắc nghẽn phòng khám trong 15-45 phút chờ kết quả.

---

## 17.1. WAITING_RESULTS – Chờ kết quả cận lâm sàng & Quản lý 2 Hàng đợi chuyên môn độc lập

Khi Bác sĩ xác nhận gửi chỉ định, ca khám chuyển sang trạng thái `WAITING_RESULTS`. Các dịch vụ kỹ thuật **tự động vào 2 Hàng đợi Cận lâm sàng độc lập** tương ứng với 2 phòng chuyên môn riêng biệt (không cần ai xếp), theo thứ tự: ca cấp cứu chưa bị lùi trước, còn lại theo thời điểm chỉ định (`queue_order`).

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
- **Ưu tiên 1 (Tuyệt đối):** Các ca gắn cờ **Cấp cứu khẩn cấp (`is_emergency = TRUE`)** tự động nhảy lên vị trí đầu tiên của hàng đợi kèm viền đỏ nhấp nháy trên màn hình. Kỹ thuật viên / Bác sĩ CĐHA bắt buộc phải tiếp nhận lấy mẫu hoặc chụp chiếu ngay lập tức.
- **Ưu tiên 2:** Các ca thông thường được xếp theo **thứ tự thời gian Bác sĩ nhấn xác nhận gửi chỉ định (FIFO - Đến trước làm trước)**.

### 3. Quy trình điều phối tối ưu khi chỉ định đồng thời 2 dịch vụ (Quy trình song song)
Khi một ca bệnh được chỉ định đồng thời cả Xét nghiệm máu và Siêu âm/X-quang, ca bệnh xuất hiện đồng thời trên cả 2 hàng đợi ở trạng thái `PENDING`:
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
- **Đẩy lùi 1 bậc, không làm nghẽn phòng máy:** Nếu đến lượt ca này trong hàng đợi CĐHA nhưng thú cưng chưa sang (đang lấy máu bên Lab), Bác sĩ CĐHA bấm nút **"Đẩy lùi 1 bậc"**:
  - Dòng dịch vụ CĐHA **giữ nguyên là `PENDING`** (chưa thực hiện, không tốn vật tư).
  - Dịch vụ được xếp ra ngay sau người kế tiếp trong hàng đợi CĐHA, và hệ thống **lập tức gọi người kế tiếp** vào phòng siêu âm $\rightarrow$ **Phòng CĐHA không bao giờ bị treo!**
  - Thú cưng lấy máu xong sẽ được gọi ở lượt sau (thường chỉ sau 1 người); khi vào phòng, Bác sĩ CĐHA bấm *"Bắt đầu chụp"* $\rightarrow$ Dịch vụ CĐHA chuyển sang `IN_PROGRESS`.

### 5. Vòng đời chuyển trạng thái của dịch vụ cận lâm sàng (`visit_service_details.status`)
1. **`PENDING` (Chờ thực hiện):** Bác sĩ lâm sàng vừa gửi chỉ định, dịch vụ xuất hiện trong hàng đợi của phòng chuyên môn.
2. **Khi nhân viên bấm gọi số vào phòng:** Dịch vụ **VẪN GIỮ NGUYÊN `PENDING`** vì thú cưng chưa bước chân vào phòng, chưa phát sinh hao phí vật tư y tế.
3. **`IN_PROGRESS` (Đang thực hiện):** Thú cưng đã vào phòng, nhân viên bấm *"Bắt đầu thực hiện"* (lấy máu nạp máy hoặc bắt đầu quét siêu âm).
4. **`COMPLETED` (Đã hoàn tất):** Nhân viên nhập đầy đủ các chỉ số đo đạc hoặc tải tệp ảnh chẩn đoán lên và nhấn nút **"Lưu & Xác nhận kết quả"**.
5. **`CANCELLED` (Đã hủy):** Chỉ định bị hủy bỏ do chủ nuôi từ chối thực hiện hoặc Bác sĩ đổi hướng xử lý. **Hóa đơn dịch vụ tương ứng chuyển `CANCELLED` trong cùng giao dịch** (không cho hủy dịch vụ có hóa đơn đã `PAID`).

> Khi bị "Đẩy lùi 1 bậc", dịch vụ vẫn `PENDING` và vẫn ở trong hàng đợi; hệ thống tăng `skip_count`, đổi `queue_order` và ghi lịch sử `action = 'SKIPPED'`.

### 6. Cơ chế xử lý khách vắng mặt khi gọi số (Đẩy lùi 1 bậc)
Khi gọi số vào phòng mà khách không có mặt (khách ra ngoài, cho thú cưng đi dạo, nghe điện thoại):
1. **Gọi 2–3 lần:** Hệ thống hiển thị thông báo gọi số trên màn hình sảnh và gửi thông báo đến ứng dụng của chủ nuôi, mỗi lần cách nhau khoảng 60 giây.
2. **Đẩy lùi 1 bậc:** Khách vẫn chưa vào, nhân viên bấm nút **"Đẩy lùi 1 bậc"**:
   - Trạng thái dịch vụ `visit_service_details.status` **GIỮ NGUYÊN LÀ `PENDING`**.
   - Dịch vụ được xếp ra **ngay sau người kế tiếp** trong hàng đợi của phòng (không bị rút khỏi hàng đợi); người kế tiếp lên đầu và được gọi ngay $\rightarrow$ Không làm chậm trễ các bệnh nhân phía sau.
   - Không giới hạn số lần bị lùi; màn hình hiển thị số lần (`skip_count`). Ca cấp cứu đã bị lùi được xếp như ca thường.
   - Hệ thống gửi thông báo đến ứng dụng / Portal của chủ nuôi (không tích hợp SMS): *"Lượt gọi của bé [Tên Pet] đã qua do bạn vắng mặt. Bé được xếp lùi 1 lượt, vui lòng chờ gọi số tiếp theo."*
3. **Khi khách quay lại:** Không cần báo Lễ tân hay bấm gì thêm; khách chờ tới lượt mới và được gọi như bình thường.
4. **Xử lý cuối ngày (Khách bỏ về hẳn):** Nếu khách bị lùi nhiều lần và Lễ tân liên hệ điện thoại xác nhận không quay lại $\rightarrow$ Thực hiện thao tác **"Đóng ca / Khách bỏ về"** (chỉ khi không còn dịch vụ đang `IN_PROGRESS`): Các dịch vụ chưa làm chuyển `CANCELLED` kèm hóa đơn của chúng; hóa đơn của các dịch vụ đã làm (khám, xét nghiệm đã có kết quả) giữ `PENDING` làm công nợ; ca khám chuyển `COMPLETED` và kết quả được lưu vào bệnh án.

### 7. Xử lý ngoại lệ: Khách xin hủy 1 trong 2 dịch vụ giữa chừng
- **Kịch bản:** Thú cưng đã làm xong Xét nghiệm máu (`COMPLETED`), nhưng khi sang phòng CĐHA thì thú cưng quá giãy giụa hoặc chủ nuôi đổi ý xin hủy không siêu âm nữa.
- **Xử lý:** Bác sĩ CĐHA chọn thao tác **"Hủy dịch vụ"** kèm lý do $\rightarrow$ Dịch vụ Siêu âm chuyển sang `CANCELLED`.
- **Kích hoạt ca khám:** Hệ thống kiểm tra: Tất cả các dịch vụ cận lâm sàng của ca khám này đều đã đạt `COMPLETED` hoặc `CANCELLED` $\rightarrow$ Tự động chuyển ca khám sang `pet_visits.status = 'RESULTS_READY'` để trả về cho Bác sĩ khám chính đọc kết quả xét nghiệm máu đã làm.
- **Hóa đơn:** Trong cùng giao dịch hủy, hóa đơn dịch vụ của Siêu âm chuyển `CANCELLED`; hóa đơn của Xét nghiệm máu giữ `PENDING`. Khách chỉ trả tiền các dịch vụ không bị hủy.

> **Cơ chế kích hoạt tự động sang cấp độ Đợt khám (`pet_visits`):**  
> Mỗi khi một dịch vụ chuyển sang `COMPLETED` hoặc `CANCELLED`, hệ thống tự động kiểm tra: Nếu **không còn dịch vụ nào ở trạng thái `PENDING` hoặc `IN_PROGRESS`**, hệ thống tự động cập nhật `pet_visits.status = 'RESULTS_READY'`, đưa ca lên đầu hàng đợi của Bác sĩ khám chính (sau ca cấp cứu) và thông báo cho Bác sĩ.

---

## 17.2. RESULTS_READY – Đã có kết quả cận lâm sàng & Quy trình xử lý hàng đợi tái khám

Khi nhân sự phòng Lab / CĐHA nhập đầy đủ kết quả đo đạc (WBC, RBC, HGB...) hoặc tải ảnh chụp siêu âm/X-quang và bấm **"Xác nhận hoàn tất kết quả"**:
- Hệ thống tự động chuyển trạng thái ca khám sang `RESULTS_READY`.
- Quy trình điều phối tái khám diễn ra qua **3 bước**:

### Bước 1: Ca lên đầu hàng đợi của Bác sĩ khám chính
- Hệ thống đặt `queue_order` của ca nhỏ hơn mọi ca trong hàng đợi của Bác sĩ khám chính và `skip_count = 0`, nên ca đứng **đầu hàng đợi**, chỉ sau ca cấp cứu. Nhiều ca cùng có kết quả thì ca nào có kết quả sau đứng trước một chút; Bác sĩ vẫn thấy toàn bộ trong danh sách.
- **Trên màn hình Bác sĩ:** Huy hiệu thông báo nhẹ (Notification Badge): *"Ca khám [Mã Visit - Tên Pet] đã có kết quả cận lâm sàng"*, không ngắt quãng ca đang khám.
- **Trên màn hình phòng chờ / Ứng dụng của chủ nuôi:** *"Bé [Tên Pet] đã có đầy đủ kết quả cận lâm sàng. Bác sĩ [Tên Bác sĩ] sẽ mời bạn và bé vào phòng ngay sau ca đang khám. Xin vui lòng chờ tại sảnh."*
- Lễ tân **không bị khóa**: vẫn xếp ca mới vào hàng đợi Bác sĩ này; ca mới đứng sau ca có kết quả.

### Bước 2: Bác sĩ gọi số tiếp theo
- Khám xong ca hiện tại (chốt ca hoặc gửi đi xét nghiệm), Bác sĩ bấm **"Gọi số tiếp theo"**. Hệ thống gọi ca đứng đầu hàng đợi (ca có kết quả):
  - Màn hình sảnh và ứng dụng của chủ nuôi: *"Mời thú cưng [Tên Pet] của chủ nuôi [Tên Khách] vào lại phòng khám [Số phòng] gặp Bác sĩ [Tên Bác sĩ]"*.
  - Ca vẫn `RESULTS_READY` cho tới khi thú cưng vào phòng.

### Bước 3: Thú cưng vào phòng, Bác sĩ bấm "Bắt đầu Giai đoạn 2"
- Ca khám chuyển sang trạng thái `IN_PROGRESS` (Giai đoạn 2), Bác sĩ chuyển sang `BUSY`, màn hình mở Bệnh án tổng hợp.

> **Xử lý tình huống khách chưa vào phòng ngay:**  
> - **Khi khách vắng mặt lúc gọi số:** Gọi 2–3 lần không thấy, Bác sĩ bấm **"Đẩy lùi 1 bậc"** (EX-10): ca giữ `RESULTS_READY`, xếp ra ngay sau người kế tiếp trong hàng đợi, Bác sĩ gọi ngay người kế tiếp. Không giới hạn số lần, hiển thị số lần bị lùi.  
> - **Khi khách quay lại phòng khám:** Khách chờ tới lượt; Bác sĩ gọi đến thì tiếp tục Bước 3.  
> - **Trường hợp khách bỏ về hẳn (không quay lại đọc kết quả):** Sau khi Lễ tân liên hệ điện thoại xác nhận khách đã bỏ về hoặc đến hết ngày làm việc, Lễ tân hoặc Bác sĩ chọn thao tác **"Đóng ca / Khách bỏ về"**:  
>   + Hệ thống khóa hồ sơ chuyên môn, lưu trữ vĩnh viễn các kết quả xét nghiệm/CĐHA đã thực hiện vào Lịch sử bệnh án của thú cưng.  
>   + Ca chuyển `COMPLETED` và rời khỏi hàng đợi. **Không lập hóa đơn mới**: hóa đơn của các dịch vụ đã thực hiện đã có sẵn từ lúc chỉ định và tiếp tục giữ `PENDING` làm công nợ, thu ở lần khách đến sau (đảm bảo không thất thoát doanh thu của phòng khám).

---

## 17.3. IN_PROGRESS (Giai đoạn 2) – Đọc kết quả, Chẩn đoán xác định & Kê đơn

- Bệnh nhân bước vào phòng khám. Màn hình Bác sĩ tự động mở giao diện Bệnh án tổng hợp:
  - Xem bảng chỉ số máu đã được hệ thống tự động so sánh với khoảng tham chiếu chuẩn theo loài (chỉ rõ chỉ số nào `LOW`, `NORMAL`, `HIGH`).
  - Xem hình ảnh siêu âm / X-quang và kết luận hình thái học.
- Bác sĩ tổng hợp với triệu chứng lâm sàng ban đầu để đưa ra:
  - **Chẩn đoán xác định** (`diagnosis`).
  - **Phác đồ điều trị** (`treatment_plan`).
  - **Thực hiện thêm dịch vụ tại phòng** nếu cần (tiêm thuốc, truyền dịch, thủ thuật – mỗi dịch vụ sinh 1 hóa đơn dịch vụ).
  - **Kê đơn thuốc điện tử** (`prescriptions` – hiển thị tồn kho để tham khảo, chỉ cảnh báo nếu không đủ vì khách có thể mua ngoài).
- Bác sĩ thực hiện thao tác **Chốt đợt khám** -> `Visit.status = WAITING_PAYMENT`. Hồ sơ chuyên môn của ca bệnh được khóa lại.
- **Sau khi chốt ca:** Bác sĩ trở về `AVAILABLE` và bấm "Gọi số tiếp theo" để gọi người đứng đầu hàng đợi của mình (ca có kết quả khác, ca cấp cứu hoặc ca mới).

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

Dòng chỉ định chỉ chứa thông tin chuyên môn (dịch vụ, số lượng, trạng thái thực hiện); thông tin tiền nằm ở hóa đơn dịch vụ.

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
  1. Điều dưỡng/Kỹ thuật viên lấy mẫu máu/bệnh phẩm từ thú cưng.
  2. Mẫu được nạp vào máy chạy tự động (mất từ 15 – 30 phút).
  3. Nhân sự phòng Lab mở màn hình *"Chỉ định chờ thực hiện"*, hệ thống hiển thị các chỉ số thuộc gói xét nghiệm (`service_lab_test_items`); nhân sự nhập giá trị đo thực tế (`WBC`, `RBC`, `HGB`, `PLT`, `Glucose`...).
- **Đặc thù nghiệp vụ:**
  - Hệ thống **tự động đối chiếu theo loài (`species_id`: Chó khác Mèo)** để hiển thị đánh giá: `LOW` (Thấp), `NORMAL` (Bình thường), `HIGH` (Cao). Nhãn này được tính khi hiển thị, không lưu cột riêng.
  - Snapshot khoảng tham chiếu (`min_value_snapshot`, `max_value_snapshot`) vào kết quả để bảo toàn lịch sử y khoa.

---

### Quy trình 2: Nhóm Chẩn đoán hình ảnh (`IMAGING` - Siêu âm, X-quang)
- **Không gian & Thiết bị:** Phòng tối máy siêu âm màu hoặc phòng chì chụp X-quang kỹ thuật số chống bức xạ.
- **Tiến hành:**
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
  - Không đi qua hàng đợi cận lâm sàng; Bác sĩ khám chính tự thực hiện ngay trong phòng.
  - **Tính tiền trọn gói:** Giá dịch vụ đã bao gồm vaccine / thuốc / vật tư dùng ngay tại chỗ (xem mục 21). Mỗi dịch vụ có 1 hóa đơn dịch vụ.

---

## 21. Quy tắc tách biệt chi phí Dịch vụ và Thuốc

Hệ thống quản lý hai dòng doanh thu bằng **hai loại hóa đơn độc lập**:

| Loại chi phí | Gồm những gì | Chứng từ | Khách có bắt buộc trả tại phòng khám? |
| :--- | :--- | :--- | :--- |
| **Dịch vụ** | Phí khám, cận lâm sàng, dịch vụ thực hiện tại phòng (tiêm phòng, tẩy giun, tiêm thuốc, truyền dịch, thủ thuật…) **kể cả thuốc / vaccine / vật tư dùng ngay tại chỗ** | Hóa đơn dịch vụ (`service_invoices`), mỗi dịch vụ một hóa đơn | Có – điều kiện để đợt khám hoàn tất |
| **Thuốc mang về** | Thuốc trong đơn thuốc Bác sĩ kê để khách dùng tại nhà | Hóa đơn thuốc (`medicine_invoices`), tối đa một hóa đơn cho một đơn thuốc | Không – khách được mua tại phòng khám hoặc mua ngoài |

```text
- Tiêm vaccine:
  └── Dịch vụ "Tiêm vaccine 7 bệnh" (giá trọn gói gồm khám sàng lọc + lọ vaccine) ──→ Hóa đơn dịch vụ

- Truyền dịch:
  └── Dịch vụ "Truyền dịch" (gồm công đặt catheter + chai dịch + dây truyền)       ──→ Hóa đơn dịch vụ

- Tẩy giun tại phòng:
  └── Dịch vụ "Tẩy giun" (gồm viên thuốc cho uống tại chỗ)                        ──→ Hóa đơn dịch vụ

- Thuốc kháng sinh uống 7 ngày tại nhà:
  └── Đơn thuốc ──(khách chọn mua tại phòng khám)──→ Hóa đơn thuốc + trừ tồn kho
                └─(khách chọn mua ngoài)───────────→ In đơn thuốc, không phát sinh hóa đơn
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
- **Snapshot Đơn giá dịch vụ:** Đơn giá và thuế suất dịch vụ được chụp vào **hóa đơn dịch vụ** (`service_invoices.unit_price`, `vat_rate`) tại thời điểm Bác sĩ chỉ định.
- **Snapshot Đơn giá thuốc:** Đơn giá và thuế suất thuốc được chụp vào **chi tiết hóa đơn thuốc** (`medicine_invoice_items.unit_price`, `vat_rate`) tại thời điểm Thu ngân lập hóa đơn thuốc. Đơn thuốc của Bác sĩ không chứa giá.

---

## 24. Chẩn đoán cuối cùng

Sau khi có đủ kết quả:

```text
Khám + Xét nghiệm + CĐHA + Theo dõi ───→ Chẩn đoán
```

Bác sĩ cập nhật:

- Chẩn đoán xác định.
- Hướng điều trị.
- Lời dặn.
- Kế hoạch theo dõi nếu cần.

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
prescriptions
       │
       ↓
prescription_items
       │
       ↓
medicines
```

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

**Giá thuốc** được chốt khi khách mua tại phòng khám (lúc Thu ngân lập hóa đơn thuốc):

```text
Medicine:              sale_price = 50.000, vat_rate = 0.05
Medicine Invoice Item: unit_price = 50.000, vat_rate = 0.05
```

Sau này nếu giá thay đổi:

```text
Medicine: sale_price = 60.000
```

Hóa đơn thuốc cũ vẫn giữ nguyên `unit_price = 50.000`.

**Giá dịch vụ** được chốt khi Bác sĩ chỉ định, vào hóa đơn dịch vụ:

```text
Service:         price = 200.000, vat_rate = 0.00
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
- **Kết quả:** `WAITING_PAYMENT → IN_PROGRESS`. Hóa đơn dịch vụ đã thanh toán giữ nguyên; dịch vụ bị bỏ thì hủy kèm hóa đơn của nó; dịch vụ thêm mới được lập hóa đơn mới. Nếu đơn thuốc đã có hóa đơn thuốc chưa hủy (`PENDING` hoặc `PAID`) thì không được sửa đơn thuốc. Bác sĩ sửa xong chốt lại.

---

## 28. Tính tiền theo hóa đơn

Hệ thống **không lưu tổng tiền** ở bất kỳ bảng nào; mọi số tiền đều được tính từ dữ liệu gốc (đảm bảo chuẩn hóa, không có thuộc tính dẫn xuất):

```text
Tiền 1 hóa đơn dịch vụ = số lượng × đơn giá × (1 + thuế suất) − giảm giá của hóa đơn đó
Tiền 1 hóa đơn thuốc   = Σ (số lượng × đơn giá × (1 + thuế suất)) các thuốc khách mua − giảm giá của hóa đơn đó

Tiền khách cần trả cho đợt khám = Σ tiền các hóa đơn dịch vụ đang chờ thanh toán
Tiền thuốc (nếu khách mua tại phòng khám) = tiền hóa đơn thuốc, thanh toán riêng
```

Số liệu được tính qua 2 VIEW: `v_service_invoice_amounts` và `v_medicine_invoice_amounts`.

Ví dụ một ca khám có xét nghiệm và siêu âm, khách mua thuốc tại phòng khám:

```text
HÓA ĐƠN DỊCH VỤ (mỗi dịch vụ một hóa đơn)
SINV-2026-0101  Khám tổng quát     1 × 100.000 × (1 + 0%)            = 100.000
SINV-2026-0102  Xét nghiệm CBC     1 × 250.000 × (1 + 0%) − 30.000   = 220.000
SINV-2026-0103  Siêu âm bụng       1 × 200.000 × (1 + 0%)            = 200.000
--------------------------------------------------------------------------------
Cần thu dịch vụ                                                         520.000

HÓA ĐƠN THUỐC (tùy chọn)
MINV-2026-0045  Amoxicillin 250mg 10 viên × 8.000 × (1 + 5%)          =  84.000
--------------------------------------------------------------------------------
Cần thu tiền thuốc                                                       84.000
```

Nếu khách mua thuốc ngoài, khách chỉ trả 520.000 và nhận đơn thuốc in.

---

## 29. Hóa đơn

Từ v3.0, hệ thống có **hai loại hóa đơn**, không còn hóa đơn gộp một ca một hóa đơn:

```text
Visit
 └── (1 : N) Visit Service Detail ── (1 : 1) ── Service Invoice      (bắt buộc, tạo lúc chỉ định)
 └── (1 : 0..1) Prescription ── (1 : 0..1) ── Medicine Invoice      (tùy chọn, tạo khi khách mua)
                                                 └── (1 : N) Medicine Invoice Items
```

**Hóa đơn dịch vụ (`service_invoices`, thuộc `clinical-service`) lưu:**
- Mã hóa đơn (`invoice_code`, ví dụ `SINV-YYYY-XXXX`).
- Dòng chỉ định dịch vụ tương ứng (1–1).
- Đơn giá và thuế suất snapshot lúc chỉ định.
- Giảm giá.
- Trạng thái thanh toán (`PENDING`, `PAID`, `CANCELLED`).
- Thu ngân xác nhận và thời điểm thanh toán.

**Hóa đơn thuốc (`medicine_invoices` + `medicine_invoice_items`, thuộc `billing-pharmacy-service`) lưu:**
- Mã hóa đơn (`MINV-YYYY-XXXX`), đơn thuốc tương ứng (tối đa 1 hóa đơn / đơn thuốc).
- Từng thuốc khách mua: số lượng (≤ số lượng kê), đơn giá và thuế suất snapshot lúc lập hóa đơn.
- Giảm giá, trạng thái thanh toán, thu ngân, thời điểm thanh toán.

**Không lưu:** tổng tiền dịch vụ, tổng tiền thuốc, tổng phải thanh toán (tính được, xem mục 28) và **phương thức thanh toán** (khách trả ngoài quầy, hệ thống không tích hợp VietQR / máy POS trong phạm vi đồ án).

**Lợi ích của hóa đơn riêng cho từng dịch vụ:**
- Hủy một dịch vụ chỉ cần hủy đúng hóa đơn của dịch vụ đó.
- Doanh thu theo dịch vụ / nhóm dịch vụ truy xuất trực tiếp bằng một truy vấn trên hóa đơn đã thanh toán.
- Khách bỏ về giữa chừng thì các hóa đơn của dịch vụ đã làm sẵn có để ghi công nợ.

---

## 30. Thanh toán hóa đơn dịch vụ

Khách hàng thanh toán bên ngoài quầy (trả tiền mặt hoặc tự chuyển khoản ngân hàng riêng). Lễ tân / Thu ngân thực hiện:

1. Mở màn hình chờ thanh toán, chọn đợt khám (`WAITING_PAYMENT`, hoặc đợt khám đã `COMPLETED` còn công nợ).
2. Hệ thống hiển thị bảng kê các hóa đơn dịch vụ của ca và tổng số tiền cần thu (tính từ các hóa đơn `PENDING`; hóa đơn đã hủy hiển thị mờ, không tính tiền).
3. Nếu có ưu đãi, nhập giảm giá trên từng hóa đơn (giảm giá không vượt số tiền của chính hóa đơn đó – EX-14).
4. Khách hàng thanh toán tiền bên ngoài quầy.
5. Sau khi nhận đủ tiền, Thu ngân nhấn **"Xác nhận thanh toán"** (không chọn phương thức thanh toán).
6. Trong một giao dịch, hệ thống chuyển các hóa đơn sang `PAID`, ghi `paid_at`, `cashier_id`. Nếu **mọi hóa đơn dịch vụ của ca đều `PAID` hoặc `CANCELLED`**, đợt khám chuyển `COMPLETED` ngay trong giao dịch đó.
7. In phiếu thu. Nếu ca có đơn thuốc, hệ thống hỏi khách có muốn mua thuốc tại phòng khám không (mục 31).

---

## 31. Bán thuốc theo đơn (tùy chọn)

Khách hàng **không bắt buộc** mua thuốc tại phòng khám.

```text
Đơn thuốc ──┬── Khách mua ngoài ──→ In đơn thuốc, kết thúc (không hóa đơn, không trừ kho)
            └── Khách mua tại phòng khám
                   │
                   ↓
            Chọn thuốc & số lượng (được mua một phần, ≤ số lượng kê)
                   ↓
            Lập hóa đơn thuốc (PENDING, chốt đơn giá & thuế suất)
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
- **Không bán âm kho:** trừ kho bằng `UPDATE ... WHERE stock_quantity >= :qty`; nếu thiếu (do quầy khác vừa bán), toàn bộ giao dịch bị hoàn tác, hóa đơn giữ `PENDING`; Thu ngân sửa chính hóa đơn đó (giảm số lượng / bỏ thuốc thiếu) rồi xác nhận lại, hoặc hủy để khách mua ngoài (EX-15). Vì chưa có khoản nào được ghi nhận đã thu, không phát sinh hoàn tiền.
- **Không bán trùng:** mỗi đơn thuốc chỉ có tối đa một hóa đơn thuốc (`prescription_id UNIQUE`, kể cả hóa đơn đã hủy); muốn đổi số lượng thì sửa hóa đơn đang `PENDING`; hóa đơn đã `PAID` không xác nhận lại được (EX-16).
- **Không ảnh hưởng đợt khám:** bán thuốc không làm thay đổi trạng thái đợt khám.

---

## 32. Hoàn tất Visit

Đợt khám hoàn tất khi **mọi hóa đơn dịch vụ đã `PAID` hoặc `CANCELLED`**:

```text
WAITING_PAYMENT ───→ COMPLETED
```

- Việc khách có mua thuốc hay không **không** là điều kiện hoàn tất.
- Ngoại lệ (EX-11): khi khách bỏ về giữa chừng hoặc không quay lại đọc kết quả, Lễ tân "Đóng ca / Khách bỏ về" → đợt khám `COMPLETED` dù còn hóa đơn dịch vụ `PENDING`; các hóa đơn này là công nợ, được thu ở lần đến sau.

Visit trở thành một phần của lịch sử bệnh án. Thời điểm hoàn tất lấy từ lịch sử trạng thái.

---

## 33. Hủy Visit

Hủy chỉ dùng khi ca **không thu phí**:

```text
WAITING → CANCELLED                      (khách bỏ về khi chờ ở sảnh – EX-03)
hoặc
IN_PROGRESS (Giai đoạn 1) → CANCELLED    (khách từ chối khám / chuyển viện cấp cứu, phòng khám không thu phí)
```

Hủy ở Giai đoạn 1 chỉ được phép khi **chưa có dịch vụ tại phòng nào hoàn thành**; khi đó mọi dịch vụ của ca (kể cả dịch vụ khám) bị hủy kèm hóa đơn dịch vụ tương ứng, nên ca hủy không để lại hóa đơn chờ thu. Nếu phòng khám vẫn thu phí khám, hoặc đã thực hiện dịch vụ tại phòng, Bác sĩ chốt ca bình thường với chẩn đoán "chuyển viện" thay vì hủy. Khách bỏ về khi đã làm cận lâm sàng **không** dùng hủy mà dùng "Đóng ca / Khách bỏ về" (mục 32).

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
- **Nhận thông báo:** Xác nhận lịch, gọi số vào phòng, bị lùi 1 lượt khi vắng mặt (qua ứng dụng / Portal, không qua SMS).

---

## 37. Quản lý danh mục thuốc

Administrator quản lý thông tin thuốc:

- Mã thuốc (`code`).
- Tên thuốc (`name`).
- Hoạt chất (`active_ingredient`).
- Dạng bào chế (`dosage_form`).
- Đơn vị tính (`unit`).
- Giá bán lẻ (`sale_price`).
- Thuế suất VAT (`vat_rate`).
- Số lượng tồn kho (`stock_quantity`) – chỉ thay đổi qua giao dịch kho hoặc bán thuốc, không sửa tay trên form danh mục.
- Mức tồn tối thiểu cảnh báo (`min_stock_alert`).
- Trạng thái kinh doanh (`is_active`).

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

`medicines.stock_quantity` được lưu sẵn (phi chuẩn hóa có chủ đích) để trừ kho nguyên tử và chống bán âm kho; mỗi giao dịch kho cập nhật cột này trong cùng giao dịch, đảm bảo bất biến `stock_quantity = SUM(inventory_transactions.quantity)`.

Khi `stock_quantity <= min_stock_alert`, hệ thống phát cảnh báo tồn kho thấp.

---

## 39. Quản lý danh mục dịch vụ

Administrator có thể:

- Thêm dịch vụ.
- Sửa dịch vụ.
- Ngừng sử dụng dịch vụ (`is_active = FALSE`).
- Thiết lập bảng giá (`price`) và thuế suất (`vat_rate`). Giá mới chỉ áp dụng cho chỉ định mới; hóa đơn đã lập giữ giá cũ.
- Phân loại nhóm dịch vụ (`category`).
- Với dịch vụ xét nghiệm: cấu hình gói gồm những chỉ số nào (`service_lab_test_items`).

> Không xóa cứng dịch vụ đã từng phát sinh trong lịch sử khám để bảo toàn tính toàn vẹn dữ liệu.

---

## 40. Báo cáo và thống kê

Administrator có thể xem:

- **Doanh thu dịch vụ:** Tổng tiền các hóa đơn dịch vụ đã `PAID` theo ngày / tháng / năm (theo `paid_at`), theo dịch vụ, theo nhóm dịch vụ.
- **Doanh thu thuốc:** Tổng tiền các hóa đơn thuốc đã `PAID`, theo thuốc.
- **Công nợ:** Các hóa đơn dịch vụ còn `PENDING` của những đợt khám đã `COMPLETED` (khách bỏ về).
- **Hoạt động khám:** Số lượt khám, số ca hoàn tất, số ca hủy, số ca No-show.
- **Dịch vụ:** Dịch vụ dùng nhiều nhất, tỷ lệ dịch vụ bị hủy.
- **Thuốc:** Thuốc bán chạy, thuốc sắp hết hàng, tỷ lệ khách mua thuốc tại phòng khám.
- **Bác sĩ:** Thống kê số ca khám, số ca hoàn thành (không phân quyền theo thống kê).

Hóa đơn `CANCELLED` không tính vào doanh thu. Số tiền tính qua `v_service_invoice_amounts`, `v_medicine_invoice_amounts`. Vì hai loại hóa đơn nằm ở hai service khác nhau, báo cáo tổng gọi API của từng service rồi cộng ở tầng ứng dụng.

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
- **BR-09:** Visit sau khi tiếp nhận ở trạng thái `WAITING`, vào danh sách chờ phân công (hoặc thẳng hàng đợi của Bác sĩ được chọn khi check-in); mọi hàng đợi sắp xếp 2 tầng: cấp cứu chưa bị đẩy lùi trước, còn lại theo `queue_order` (thời điểm check-in).
- **BR-10:** Lễ tân chịu trách nhiệm phân công bác sĩ phụ trách.
- **BR-11:** Mỗi bác sĩ có một hàng đợi riêng. Lễ tân được xếp ca `WAITING` vào hàng đợi của bất kỳ bác sĩ đang làm việc nào, bất cứ lúc nào, không phụ thuộc bác sĩ đang rảnh hay đang khám; hệ thống gợi ý bác sĩ có ít người chờ nhất. Ca vừa có kết quả cận lâm sàng tự lên đầu hàng đợi của bác sĩ khám chính (sau ca cấp cứu).
- **BR-12:** Một bác sĩ chỉ khám một ca tại một thời điểm (không có đồng thời 2 ca `IN_PROGRESS`); bác sĩ chỉ được "Gọi số tiếp theo" khi không có ca đang khám.
- **BR-13:** Bác sĩ khám tại số phòng cố định đã được gán sẵn trong tài khoản.

### Nhóm Visit
- **BR-14:** Visit có thể sinh ra từ Appointment (`CHECKED_IN`) hoặc tạo trực tiếp từ Walk-in.
- **BR-15:** Một Visit gắn liền với duy nhất một thú cưng.
- **BR-16:** Một Visit có một bác sĩ phụ trách chính sau khi phân công.
- **BR-17:** Một Visit có thể bao gồm nhiều chỉ định dịch vụ (phí khám cũng là một dịch vụ, được tạo tự động khi bắt đầu khám).
- **BR-18:** Một Visit có tối đa một Prescription (đơn thuốc); đơn thuốc không chứa giá và không có trạng thái cấp phát.
- **BR-19:** Mỗi dịch vụ được chỉ định có đúng một hóa đơn dịch vụ riêng; một Visit có thể có nhiều hóa đơn dịch vụ. Hệ thống không lưu tổng tiền hóa đơn.

### Nhóm chuyên môn
- **BR-20:** Phân quyền ghi dữ liệu chuyên môn nghiêm ngặt theo vai trò: `VETERINARIAN` (khám lâm sàng, ra chỉ định, thực hiện dịch vụ tại phòng, chẩn đoán xác định, kê đơn), `LAB_TECHNICIAN` (nhập kết quả xét nghiệm), `IMAGING_TECHNICIAN` (tải tệp ảnh và nhập kết luận chẩn đoán hình ảnh).
- **BR-21:** Chi phí dịch vụ (gồm cả thuốc / vật tư dùng ngay tại phòng) và chi phí thuốc mang về được ghi trên hai loại hóa đơn độc lập: hóa đơn dịch vụ và hóa đơn thuốc.
- **BR-22:** Mỗi dịch vụ kỹ thuật có thể sinh ra các bản ghi kết quả chi tiết riêng (xét nghiệm, chẩn đoán hình ảnh).
- **BR-23:** Khoảng tham chiếu xét nghiệm phải phụ thuộc theo loài (`Species`).
- **BR-24:** Khoảng tham chiếu (min, max) phải được snapshot vào kết quả tại thời điểm thực hiện; nhãn đánh giá được tính khi hiển thị.

### Nhóm tài chính & Thanh toán
- **BR-25:** Đơn giá và thuế suất dịch vụ được snapshot vào hóa đơn dịch vụ tại thời điểm bác sĩ chỉ định.
- **BR-26:** Đơn giá và thuế suất thuốc được snapshot vào hóa đơn thuốc tại thời điểm thu ngân lập hóa đơn thuốc (không phải lúc kê đơn).
- **BR-27:** Hóa đơn dịch vụ được lập tự động lúc chỉ định; thu ngân chỉ xác nhận thanh toán khi Visit đã được bác sĩ chốt chuyên môn (`WAITING_PAYMENT`) hoặc khi thu công nợ của Visit đã đóng.
- **BR-28:** Visit chuyển sang `COMPLETED` khi mọi hóa đơn dịch vụ đều `PAID` hoặc `CANCELLED`; việc mua thuốc không ảnh hưởng. Ngoại lệ: khi khách bỏ về (EX-11), Visit được đóng sang `COMPLETED` và các hóa đơn dịch vụ còn `PENDING` giữ làm công nợ.
- **BR-33:** Khi một dịch vụ được chỉ định bị hủy, hóa đơn dịch vụ tương ứng chuyển `CANCELLED` trong cùng giao dịch; không có thao tác hủy hóa đơn dịch vụ riêng lẻ và không được hủy dịch vụ có hóa đơn đã thanh toán.
- **BR-34:** Ở hàng đợi bác sĩ, phòng Xét nghiệm và phòng CĐHA, người phụ trách bấm "Gọi số tiếp theo" để gọi người đứng đầu; gọi không thấy thì bấm "Đẩy lùi 1 bậc": người đó được xếp ra ngay sau người kế tiếp và người kế tiếp được gọi. Không giới hạn số lần bị lùi, hệ thống chỉ hiển thị số lần; ca cấp cứu đã bị lùi được xếp như ca thường.

### Nhóm kho dược
- **BR-29:** Thuốc chỉ bị trừ tồn kho khi hóa đơn thuốc được xác nhận thanh toán; chuyển `PAID`, trừ kho và ghi nhật ký `EXPORT_SALE` diễn ra trong cùng một giao dịch.
- **BR-30:** Không được bán (xuất kho) vượt quá số lượng tồn kho tại thời điểm xác nhận; khi kê đơn, số lượng vượt tồn kho chỉ bị cảnh báo.
- **BR-31:** Mỗi đơn thuốc có tối đa một hóa đơn thuốc; hóa đơn thuốc đã thanh toán không được xác nhận lại, nên một đơn thuốc không bị trừ kho nhiều hơn một lần.
- **BR-32:** Khách hàng được tự chọn mua thuốc tại phòng khám hoặc mua ngoài theo đơn in; được mua một phần đơn với số lượng mỗi thuốc không vượt số lượng kê.

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
                 │ WAITING │ (Nằm trong hàng đợi riêng của Bác sĩ)
                 └────┬────┘
                      │ Bác sĩ gọi số, bấm "Bắt đầu khám"
                      ↓  (tự tạo dịch vụ khám + hóa đơn dịch vụ)
               ┌──────────────────┐
               │ IN_PROGRESS (GĐ1)│──────────────────────────────┐
               └────────┬─────────┘                              │ Không cần CLS
                        │ Gửi chỉ định CLS (tạo hóa đơn dịch vụ)  │ (chốt ca)
                        ↓                                        │
               ┌─────────────────┐                               │
               │ WAITING_RESULTS │                               │
               └────────┬────────┘                               │
                        │ Mọi dịch vụ CLS xong hoặc hủy           │
                        ↓                                        │
               ┌─────────────────┐                               │
               │  RESULTS_READY  │ (lên đầu hàng đợi Bác sĩ)     │
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
                      │ Mọi hóa đơn dịch vụ PAID / CANCELLED
                      ↓
                ┌───────────┐
                │ COMPLETED │ (Lưu trữ vào lịch sử bệnh án)
                └───────────┘

Gọi số không thấy khách (WAITING / RESULTS_READY): "Đẩy lùi 1 bậc", không đổi trạng thái (EX-10).

Nhánh hủy / đóng ca đặc biệt:
- WAITING            ───(Khách bỏ về / lỗi tạo)─────────────────────→ CANCELLED
- IN_PROGRESS (GĐ1)  ───(Khách từ chối khám / Chuyển viện, miễn phí)─→ CANCELLED
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
                  TẠO VISIT
                       │
                       ↓
                    WAITING
                       │
                       ↓
     LỄ TÂN XẾP VÀO HÀNG ĐỢI RIÊNG CỦA BÁC SĨ
          (gợi ý bác sĩ ít người chờ nhất)
                       │
             ┌─────────┼─────────┐
             ↓         ↓         ↓
       Hàng đợi BS A  BS B     BS C
           P01       P02       P03
                       │
                       ↓
     BÁC SĨ GỌI SỐ TIẾP THEO (vắng → Đẩy lùi 1 bậc)
                       │
                       ↓
                 IN_PROGRESS
                       │
             ┌─────────┼─────────┐
             │         │         │
             ↓         ↓         ↓
           Khám      Xét nghiệm  CĐHA
             │         │         │
             │         ↓         ↓
             │       Results   Results
             │         │         │
             └─────────┼─────────┘
                       ↓
                   Chẩn đoán
                       ↓
                    Kê đơn
                       ↓
              CHỐT ĐỢT KHÁM
                       ↓
                WAITING_PAYMENT
                       ↓
        THU TIỀN CÁC HÓA ĐƠN DỊCH VỤ
     (mỗi dịch vụ một hóa đơn, lập sẵn lúc chỉ định)
                       ↓
                   COMPLETED ─────→ LỊCH SỬ BỆNH ÁN
                       │
             ┌─────────┴──────────┐
             ↓                    ↓
     Khách mua thuốc        Khách mua ngoài /
     tại phòng khám         không kê đơn
             ↓                    ↓
     HÓA ĐƠN THUỐC           In đơn thuốc,
     + TRỪ TỒN KHO             ra về
   (cùng một giao dịch)
```


---

## 44. Mô hình dữ liệu khái niệm (Conceptual Data Model)

### 44.1. Cấu trúc tài khoản người dùng
Không chia thành các bảng tài khoản phân mảnh, sử dụng mô hình xác thực tập trung:
- `users`: Thông tin định danh, tài khoản, mật khẩu, trạng thái.
- `roles`: Bảng vai trò (`ADMIN`, `VETERINARIAN`, `RECEPTIONIST`, `LAB_TECHNICIAN`, `IMAGING_TECHNICIAN`, `PET_OWNER`).

### 44.2. Các thực thể chính trong hệ thống (25 bảng, 4 CSDL logic – lược đồ v3.0)

```text
AUTH-SERVICE (pet_clinic_auth_db)
1. ROLES
2. USERS
3. REFRESH_TOKENS

APPOINTMENT-SERVICE (pet_clinic_appointment_db)
4. APPOINTMENTS
5. APPOINTMENT_STATUS_HISTORIES

CLINICAL-SERVICE (pet_clinic_clinical_db)
6. SPECIES
7. PETS
8. SERVICES
9. LAB_TEST_ITEMS
10. SERVICE_LAB_TEST_ITEMS          (gói xét nghiệm gồm những chỉ số nào)
11. LAB_TEST_REFERENCE_RANGES
12. PET_VISITS
13. PET_VISIT_STATUS_HISTORIES
14. VISIT_SERVICE_DETAILS
15. VISIT_SERVICE_DETAIL_HISTORIES
16. LAB_TEST_RESULTS
17. IMAGING_RESULTS
18. IMAGING_ATTACHMENTS
19. SERVICE_INVOICES                (hóa đơn riêng cho từng dịch vụ)

BILLING-PHARMACY-SERVICE (pet_clinic_billing_pharmacy_db)
20. MEDICINES
21. PRESCRIPTIONS
22. PRESCRIPTION_ITEMS
23. MEDICINE_INVOICES               (hóa đơn thuốc – tùy chọn)
24. MEDICINE_INVOICE_ITEMS
25. INVENTORY_TRANSACTIONS
```

*(Bản 2.0 có `INVOICES` và `INVOICE_ITEMS` – hóa đơn gộp một ca một hóa đơn – nay đã thay bằng `SERVICE_INVOICES`, `MEDICINE_INVOICES`, `MEDICINE_INVOICE_ITEMS`.)*

### 44.3. Trục dữ liệu chính (Core Data Backbone)

```text
APPOINTMENTS ─── (1 : N) ─── APPOINTMENT_STATUS_HISTORIES

PET_OWNER (USER)
    ↓ (1 : N)
PET
    ↓ (1 : N)
PET_VISIT ─── (1 : N) ─── PET_VISIT_STATUS_HISTORIES
    ├── (1 : N) ─── VISIT_SERVICE_DETAILS ─── (1 : N) ─── VISIT_SERVICE_DETAIL_HISTORIES
    │                     ├── (1 : 1) ─── SERVICE_INVOICES
    │                     ├── (1 : N) ─── LAB_TEST_RESULTS
    │                     └── (1 : 0..1) ─ IMAGING_RESULTS ─── (1 : N) ─── IMAGING_ATTACHMENTS
    │
    └── (1 : 0..1) ─ PRESCRIPTION
                          ├── (1 : N) ─── PRESCRIPTION_ITEMS ─── (N : 1) ─── MEDICINES
                          │                                                    └── (1 : N) ─── INVENTORY_TRANSACTIONS
                          └── (1 : 0..1) ─ MEDICINE_INVOICE
                                                └── (1 : N) ─── MEDICINE_INVOICE_ITEMS ─── (N : 1) ─── PRESCRIPTION_ITEMS
```

### 44.4. Phân rã nghiệp vụ theo vai trò người dùng

```text
USER
 │
 ├── ADMIN
 │      ├── Quản lý nhân sự, gán phòng làm việc cố định
 │      ├── Cấu hình danh mục Dịch vụ, Thuốc, Xét nghiệm, Tham chiếu
 │      ├── Nhập kho & cân chỉnh kho
 │      └── Xem thống kê, báo cáo doanh thu, công nợ & vận hành
 │
 ├── RECEPTIONIST
 │      ├── Tiếp nhận đặt lịch, check-in
 │      ├── Xếp ca vào hàng đợi riêng của từng Bác sĩ
 │      ├── Thu tiền các hóa đơn dịch vụ, thu công nợ
 │      └── Bán thuốc theo đơn khi khách chọn mua (lập hóa đơn thuốc, xuất thuốc)
 │
 ├── VETERINARIAN
 │      ├── Khám lâm sàng, cân đo sinh hiệu & ghi nhận triệu chứng ban đầu
 │      ├── Chỉ định dịch vụ cận lâm sàng (Lab, CĐHA) & thực hiện dịch vụ tại phòng
 │      ├── Kết luận chẩn đoán xác định & kê đơn thuốc mang về
 │      └── Chốt đợt khám (và mở lại hồ sơ khi cần sửa sai sót)
 │
 ├── LAB_TECHNICIAN
 │      ├── Tiếp nhận chỉ định xét nghiệm & lấy mẫu bệnh phẩm
 │      ├── Vận hành máy xét nghiệm tự động
 │      └── Nhập chỉ số đo lường & xác nhận kết quả
 │
 ├── IMAGING_TECHNICIAN
 │      ├── Tiếp nhận chỉ định CĐHA (X-quang, Siêu âm)
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

| Vị trí | Bản 2.0 | Bản 3.0 | Lý do |
| :--- | :--- | :--- | :--- |
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
