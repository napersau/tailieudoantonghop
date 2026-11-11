# LỊCH TRÌNH CHI TIẾT XÂY DỰNG MÃ NGUỒN & HƯỚNG DẪN KIỂM THỬ HỆ THỐNG
## HỆ THỐNG QUẢN LÝ PHÒNG KHÁM THÚ Y (MICROSERVICES ARCHITECTURE)
### NỀN TẢNG: JAVA 21 LTS | SPRING BOOT 4.1.1 | SPRING CLOUD 2025.1.2 | MYSQL 8.0 | REACT VITE
### PHIÊN BẢN 3.0 – đồng bộ lược đồ CSDL v3.0, Kiến trúc v3.0 và Quy chuẩn Backend v3.0

> **Mục đích tài liệu:**  
> - Bản lộ trình hành động (Actionable Implementation Roadmap) chia nhỏ toàn bộ quá trình lập trình thành các nhiệm vụ cụ thể (Tasks) đi kèm hộp kiểm `[ ]` để đánh dấu tiến độ thực tế.  
> - Bao phủ **70 Yêu cầu chức năng (FR-01 → FR-70)**, **8 Yêu cầu phi chức năng (NFR-01 → NFR-08)**, **16 Tình huống ngoại lệ (EX-01 → EX-16)** và **25 bảng Cơ sở dữ liệu** (4 CSDL logic, 25 khóa ngoại nội bộ, 2 VIEW tính tiền). Mã FR trích dẫn theo đúng `YEU_CAU_CHUC_NANG_VA_PHI_CHUC_NANG.md` v3.0.  
> - Cung cấp **hướng dẫn kiểm thử sau từng task** (câu lệnh `curl`, dữ liệu mẫu JSON, mã lỗi kỳ vọng, truy vấn SQL xác minh và kiểm tra sự kiện).
>
> **Quy ước dùng chung:**
> - Tên endpoint, sự kiện RabbitMQ (exchange `clinic.events`) và mã lỗi theo đúng `THIET_KE_KIEN_TRUC_MICROSERVICES.md` (mục 5) và `QUY_CHUAN_THIET_KE_VA_LAP_TRINH_BACKEND_SPRINGBOOT.md` (mục 3.2, 5.1, 9.2).
> - Các lệnh `curl` qua Gateway dùng biến `$TOKEN_<VAI_TRÒ>` lấy từ API đăng nhập (Task 2.2). Endpoint `/internal/**` chỉ gọi trực tiếp cổng service, Gateway chặn tiền tố này.
> - ID trong ví dụ khớp **dữ liệu demo cố định** nạp ở Task 1.2.3.

---

## BẢNG TIẾN ĐỘ TỔNG QUAN THEO CÁC GIAI ĐOẠN (SPRINTS)

```text
┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
│ PHA 1: Khung hạ tầng Maven Multi-Module, Docker, Common-Library, Eureka & Gateway (:8080)       │
├─────────────────────────────────────────────────────────────────────────────────────────────────┤
│ PHA 2: Xác thực JWT phân quyền (auth-service :8081) & Cổng Đặt lịch (appointment-service :8082) │
├─────────────────────────────────────────────────────────────────────────────────────────────────┤
│ PHA 3: Lâm sàng 2 pha, Hàng đợi riêng từng Bác sĩ, CLS song song & Hóa đơn dịch vụ (:8083)       │
├─────────────────────────────────────────────────────────────────────────────────────────────────┤
│ PHA 4: Kê đơn, Bán thuốc theo đơn (tùy chọn) & Trừ kho nguyên tử (billing-pharmacy :8084)       │
├─────────────────────────────────────────────────────────────────────────────────────────────────┤
│ PHA 5: Thông báo Realtime WebSocket (notification-service :8085), Frontend React & Test E2E EX  │
└─────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## GIAI ĐOẠN 1: THIẾT LẬP HẠ TẦNG, MAVEN MULTI-MODULE & THƯ VIỆN LÕI

### Task 1.1: Khởi tạo Cấu trúc Dự án Maven Multi-Module
- **Người thực hiện:** Lưu Minh Hiển & Nguyễn Đức Khởi
- **Mục tiêu:** Tạo kho mã nguồn, thiết lập Parent POM quản lý dependencies tập trung (`Java 21`, `Spring Boot 4.1.1`, `Spring Cloud 2025.1.2`, `MapStruct 1.5.5`, `Lombok`).
- [ ] **1.1.1** Khởi tạo Git repository, cấu hình `.gitignore` chuẩn Java/IntelliJ/Maven và phân nhánh `main`, `develop`.
- [ ] **1.1.2** Tạo tệp `pom.xml` gốc khai báo 8 modules con: `common-library`, `service-registry`, `api-gateway`, `auth-service`, `appointment-service`, `clinical-service`, `billing-pharmacy-service`, `notification-service`.
- [ ] **1.1.3** Khởi tạo khung thư mục `src/main/java` và `src/main/resources` cho từng module.

> **Hướng dẫn Kiểm thử Task 1.1:**
> 1. Mở terminal tại thư mục gốc dự án: `mvn clean compile`
> 2. **Kết quả kỳ vọng:** Build thành công cả 8 modules (`BUILD SUCCESS`). Nếu dùng Spring Cloud cũ hơn 2025.1.2, ứng dụng sẽ báo lỗi `Spring Boot [4.1.x] is not compatible with this Spring Cloud release train` khi khởi động.

---

### Task 1.2: Thiết lập Hạ tầng CSDL MySQL, RabbitMQ & Dữ liệu demo (Docker Compose)
- **Người thực hiện:** Nguyễn Đức Khởi
- **Mục tiêu:** Dựng môi trường CSDL và RabbitMQ bằng Docker, nạp toàn bộ cấu trúc CSDL 25 bảng và dữ liệu demo dùng cho mọi hướng dẫn kiểm thử.
- [ ] **1.2.1** Viết tệp `docker-compose.yml` khởi chạy:
  - MySQL 8.0 Server (Port 3306), cấu hình `utf8mb4_unicode_ci`.
  - Khởi tạo tự động 4 CSDL logic: `pet_clinic_auth_db`, `pet_clinic_appointment_db`, `pet_clinic_clinical_db`, `pet_clinic_billing_pharmacy_db`.
  - RabbitMQ Server với Management Plugin (Port 5672 và 15672).
  - Volume `imaging-uploads` gắn vào `clinical-service` tại `/app/uploads/imaging/`.
- [ ] **1.2.2** Thực thi `schema_init.sql`: **25 bảng**, **25 ràng buộc khóa ngoại nội bộ** (auth 2, appointment 1, clinical 15, billing-pharmacy 7), **2 VIEW** (`v_service_invoice_amounts`, `v_medicine_invoice_amounts`) và dữ liệu danh mục (6 vai trò, 1 admin, 2 loài, 7 dịch vụ, 4 chỉ số xét nghiệm, 4 thuốc, nhập kho đầu kỳ).
- [ ] **1.2.3** Viết `seed_demo_data.sql` (chỉ dùng cho môi trường dev/demo, chạy sau `schema_init.sql`) để có tài khoản và thú cưng mẫu. Bảng ID cố định dùng trong toàn bộ tài liệu:

  | ID | Tài khoản | Vai trò (`role_id`) | Phòng | Ghi chú |
  | :---: | :--- | :--- | :---: | :--- |
  | 1 | `admin` | ADMIN (1) | – | Có sẵn trong `schema_init.sql` |
  | 2 | `bs_tien` | VETERINARIAN (2) | P101 | Bác sĩ Nguyễn Văn Tiến |
  | 3 | `bs_an` | VETERINARIAN (2) | P102 | Bác sĩ Trần Bình An |
  | 4 | `bs_mai` | VETERINARIAN (2) | P103 | Bác sĩ Lê Thị Mai |
  | 5 | `letan_hoa` | RECEPTIONIST (3) | – | Lễ tân / Thu ngân |
  | 6 | `ktv_lab_minh` | LAB_TECHNICIAN (4) | P201 | Phòng Xét nghiệm |
  | 7 | `ktv_cdha_dung` | IMAGING_TECHNICIAN (5) | P202 | Phòng CĐHA |
  | 8 | `khach_lan` | PET_OWNER (6) | – | Chủ của thú cưng #1 "Lu" (Mèo) và #2 "Milo" (Chó) |

  ```sql
  USE pet_clinic_auth_db;
  -- Cùng hash với admin; mật khẩu demo thống nhất. Sinh lại hash BCrypt trước khi demo nếu không đăng nhập được.
  INSERT INTO users (id, role_id, username, password_hash, full_name, phone_number, room_number, status) VALUES
  (2, 2, 'bs_tien',       '<bcrypt>', 'Nguyễn Văn Tiến', '0902000002', 'P101', 'ACTIVE'),
  (3, 2, 'bs_an',         '<bcrypt>', 'Trần Bình An',    '0902000003', 'P102', 'ACTIVE'),
  (4, 2, 'bs_mai',        '<bcrypt>', 'Lê Thị Mai',      '0902000004', 'P103', 'ACTIVE'),
  (5, 3, 'letan_hoa',     '<bcrypt>', 'Phạm Thu Hoa',    '0902000005', NULL,   'ACTIVE'),
  (6, 4, 'ktv_lab_minh',  '<bcrypt>', 'Đỗ Quang Minh',   '0902000006', 'P201', 'ACTIVE'),
  (7, 5, 'ktv_cdha_dung', '<bcrypt>', 'Vũ Tiến Dũng',    '0902000007', 'P202', 'ACTIVE'),
  (8, 6, 'khach_lan',     '<bcrypt>', 'Hoàng Thị Lan',   '0912000008', NULL,   'ACTIVE');

  USE pet_clinic_clinical_db;
  INSERT INTO pets (id, owner_id, species_id, pet_code, name, breed, gender) VALUES
  (1, 8, 2, 'PET-2026-0001', 'Lu',   'Mèo Anh lông ngắn', 'FEMALE'),
  (2, 8, 1, 'PET-2026-0002', 'Milo', 'Poodle',            'MALE');
  ```

> **Hướng dẫn Kiểm thử Task 1.2:**
> 1. Khởi động container: `docker compose up -d`; mở `http://localhost:15672` (tài khoản `guest/guest`).
> 2. Kiểm tra số bảng, khóa ngoại và VIEW:
>    ```sql
>    SELECT table_schema, SUM(table_type = 'BASE TABLE') AS tables, SUM(table_type = 'VIEW') AS views
>    FROM information_schema.tables WHERE table_schema LIKE 'pet_clinic_%' GROUP BY table_schema;
>
>    SELECT COUNT(*) AS fk_count FROM information_schema.referential_constraints
>    WHERE constraint_schema LIKE 'pet_clinic_%';
>    ```
> 3. **Kết quả kỳ vọng:**
>    - `pet_clinic_auth_db`: 3 bảng · `pet_clinic_appointment_db`: 2 bảng · `pet_clinic_clinical_db`: 14 bảng + 1 VIEW · `pet_clinic_billing_pharmacy_db`: 6 bảng + 1 VIEW → **25 bảng, 2 VIEW**.
>    - `fk_count = 25`.
>    - Bất biến kho: `SELECT m.id, m.stock_quantity, SUM(t.quantity) FROM medicines m JOIN inventory_transactions t ON t.medicine_id = m.id GROUP BY m.id;` → hai cột bằng nhau (200, 50, 40, 100).

---

### Task 1.3: Xây dựng Module Dùng chung (`common-library`)
- **Người thực hiện:** Lưu Minh Hiển
- **Mục tiêu:** Cung cấp bộ khung lớp dùng chung cho các microservices, nạp cấu hình servlet bằng Auto-Configuration có điều kiện (Quy chuẩn mục 2.2).
- [ ] **1.3.1** Xây dựng `ApiResponse<T>` (trường `status`, `errorCode`, `message`, `data`, `timestamp`) và `PageResponse<T>` (Quy chuẩn Chương 4).
- [ ] **1.3.2** Xây dựng `ErrorCode` (**39 mã lỗi** dạng chuỗi `SYS_xxxx`, `AUTH_xxxx`, `APPT_xxxx`, `CLIN_xxxx`, `BILL_xxxx`, `PHARM_xxxx`) và `AppException`.
- [ ] **1.3.3** Đặt `GlobalExceptionHandler`, `FeignExceptionHandler`, `CommonSecurityConfig`, `HeaderAuthenticationFilter`, `FeignClientInterceptor`, `CustomFeignErrorDecoder` trong package `com.vetclinic.common.web`; tạo `CommonWebAutoConfiguration` (`@ConditionalOnWebApplication(SERVLET)`) và file `META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports`. Phụ thuộc servlet / security / openfeign khai báo `<optional>true</optional>`.
- [ ] **1.3.4** Định nghĩa **10 Java Enum khớp CSDL** (`RoleCode`, `UserStatus`, `PetGender`, `BookingChannel`, `AppointmentStatus`, `VisitStatus`, `ServiceCategory`, `ServiceDetailStatus`, `PaymentStatus`, `InventoryTransactionType`) + enum tầng ứng dụng `LabEvaluation`; định nghĩa lớp cơ sở `BaseEvent` và 9 lớp sự kiện theo Kiến trúc mục 5.2.

> **Hướng dẫn Kiểm thử Task 1.3:**
> 1. Viết Unit Test `ApiResponseTest.java` kiểm tra `ApiResponse.success(data)` và `ApiResponse.created(message, data)`; `GlobalExceptionHandlerTest` kiểm tra `AppException(ErrorCode.INVOICE_ALREADY_PAID)` trả HTTP 409.
> 2. Chạy: `mvn test -pl common-library`.
> 3. **Kết quả kỳ vọng:** Test passed; JSON thành công có dạng `{ "status": 200, "message": "...", "data": {...}, "timestamp": "..." }` (không có `errorCode`); JSON lỗi có `"errorCode": "BILL_1403"`.

---

### Task 1.4: Triển khai Service Discovery (`service-registry` - Eureka Server :8761)
- **Người thực hiện:** Nguyễn Đức Khởi
- **Mục tiêu:** Cung cấp trung tâm đăng ký và khám phá dịch vụ động trong mạng nội bộ.
- [ ] **1.4.1** Thêm dependency `spring-cloud-starter-netflix-eureka-server`. **Không** thêm `common-library`.
- [ ] **1.4.2** Cấu hình `application.yml` chạy trên port `8761`, tắt `register-with-eureka` và `fetch-registry`.
- [ ] **1.4.3** Gắn `@EnableEurekaServer` tại `ServiceRegistryApplication.java`.

> **Hướng dẫn Kiểm thử Task 1.4:**
> 1. Khởi động `service-registry`, mở `http://localhost:8761`.
> 2. **Kết quả kỳ vọng:** Eureka Dashboard mở thành công, trạng thái `UP`.

---

### Task 1.5: Triển khai Cổng Vào Tập Trung (`api-gateway` :8080)
- **Người thực hiện:** Nguyễn Đức Khởi
- **Mục tiêu:** Cổng vào duy nhất, định tuyến động qua Eureka, xác thực JWT tập trung, CORS (NFR-02, NFR-03).
- [ ] **1.5.1** `api-gateway/pom.xml` dùng `spring-boot-starter-webflux` và `spring-cloud-starter-gateway`.
- [ ] **1.5.2** Định tuyến: `/api/v1/auth/**` → `lb://auth-service`; `/api/v1/appointments/**` → `lb://appointment-service`; `/api/v1/clinical/**`, `/api/v1/pets/**`, `/api/v1/species/**` → `lb://clinical-service`; `/api/v1/pharmacy/**`, `/api/v1/billing/**` → `lb://billing-pharmacy-service`; `/api/v1/notifications/**`, `/ws/**` → `lb://notification-service`.
- [ ] **1.5.3** Viết `JwtAuthenticationFilter` (Quy chuẩn 10.1): xóa `X-User-*` từ client; route công khai (`/api/v1/auth/login`, `/refresh`, `/register`, `/api/v1/appointments/slots`) cho qua; route khác thiếu / sai / hết hạn token → **401 `SYS_1002`**; token hợp lệ → gắn `X-User-Id`, `X-User-Role` (vai trò **không có** tiền tố `ROLE_`); chặn `/internal/**` → 403.
- [ ] **1.5.4** Cấu hình CORS cho Frontend `http://localhost:5173`.

> **Hướng dẫn Kiểm thử Task 1.5:**
> 1. Gọi route cần đăng nhập mà không có token:
>    ```bash
>    curl -i http://localhost:8080/api/v1/clinical/pet-visits/queue
>    ```
>    **Kỳ vọng:** `401`, `"errorCode": "SYS_1002"` (không phải 403 – để Axios tự gọi refresh).
> 2. Gọi endpoint nội bộ qua Gateway: `curl -i http://localhost:8080/internal/users/2` → **Kỳ vọng:** `403`.
> 3. Giả mạo header: `curl -i -H "X-User-Role: ADMIN" http://localhost:8080/api/v1/auth/users` (không token) → **Kỳ vọng:** `401`, header giả bị xóa.

---

## GIAI ĐOẠN 2: PHÂN HỆ XÁC THỰC, PHÂN QUYỀN & CỔNG ĐẶT LỊCH HẸN

### Task 2.1: Cấu hình Tầng Dữ liệu `auth-service` (:8081)
- **Người thực hiện:** Nguyễn Đức Khởi
- **Mục tiêu:** Kết nối `pet_clinic_auth_db`, thiết lập Entities và Repositories.
- [ ] **2.1.1** Khai báo kết nối MySQL trong `application.yml`, `ddl-auto: validate`.
- [ ] **2.1.2** Tạo Entities `Role`, `User`, `RefreshToken` ánh xạ đúng cột trong `schema_init.sql`.
- [ ] **2.1.3** Tạo `UserRepository`, `RoleRepository`, `RefreshTokenRepository`.

> **Hướng dẫn Kiểm thử Task 2.1:**
> 1. Chạy `UserRepositoryTest`: `userRepository.findByUsername("bs_tien")`.
> 2. **Kết quả kỳ vọng:** Tải được bản ghi id = 2, `roomNumber = P101`; không lỗi `SchemaManagementException`.

---

### Task 2.2: Đăng nhập, Đăng ký Khách hàng & Cấp phát JWT
- **Người thực hiện:** Nguyễn Đức Khởi (Phụ trách FR-09, NFR-02)
- **Mục tiêu:** Mã hóa BCrypt, xác thực đăng nhập, cấp Access Token (30 phút) + Refresh Token (7 ngày).
- [ ] **2.2.1** `AuthService.login()`: kiểm tra username / password, trạng thái `ACTIVE` (tài khoản `LOCKED` / `INACTIVE` bị từ chối).
- [ ] **2.2.2** Tạo Access Token chứa claims: `userId`, `username`, `role` (**mã vai trò không tiền tố**, ví dụ `VETERINARIAN`), `fullName`, `roomNumber`.
- [ ] **2.2.3** Lưu Refresh Token (UUID v4) vào `refresh_tokens`.
- [ ] **2.2.4** API Đăng ký Khách hàng (`POST /api/v1/auth/register`) tự gán vai trò `PET_OWNER`; số điện thoại trùng → `AUTH_1102`.

> **Hướng dẫn Kiểm thử Task 2.2:**
> 1. Đăng nhập tài khoản Bác sĩ demo và lưu token:
>    ```bash
>    curl -X POST http://localhost:8080/api/v1/auth/login \
>      -H "Content-Type: application/json" \
>      -d '{"username": "bs_tien", "password": "<mật khẩu demo>"}'
>    ```
> 2. **Kết quả kỳ vọng:** `200 OK`, body có `accessToken` và `refreshToken`; giải mã JWT thấy `"role": "VETERINARIAN"` (không có `ROLE_`).
> 3. Kiểm tra DB: `SELECT * FROM pet_clinic_auth_db.refresh_tokens WHERE user_id = 2;` → có 1 bản ghi `revoked = 0`.
> 4. Sai mật khẩu → `401`, mã lỗi `AUTH_1103 (INVALID_CREDENTIALS)`.
> 5. Lặp lại để lấy `$TOKEN_VET` (bs_tien), `$TOKEN_REC` (letan_hoa), `$TOKEN_LAB` (ktv_lab_minh), `$TOKEN_IMG` (ktv_cdha_dung), `$TOKEN_OWNER` (khach_lan), `$TOKEN_ADMIN` (admin).

---

### Task 2.3: Cơ chế Xoay vòng Refresh Token (Token Rotation) & Đăng xuất
- **Người thực hiện:** Nguyễn Đức Khởi (Phụ trách NFR-02)
- **Mục tiêu:** Chống đánh cắp Refresh Token bằng Rotation và xử lý Đăng xuất an toàn.
- [ ] **2.3.1** `RefreshTokenService.refresh()`: token tồn tại, chưa hết hạn, `revoked = 0`; cấp cặp mới, đánh dấu token cũ `revoked = 1`.
- [ ] **2.3.2** Phát hiện tái sử dụng token đã thu hồi: thu hồi toàn bộ token của `user_id` đó.
- [ ] **2.3.3** API Đăng xuất (`POST /api/v1/auth/logout`): đánh dấu token hiện tại `revoked = 1`.

> **Hướng dẫn Kiểm thử Task 2.3:**
> 1. Gọi refresh:
>    ```bash
>    curl -X POST http://localhost:8080/api/v1/auth/refresh \
>      -H "Content-Type: application/json" -d '{"refreshToken": "<token_vừa_nhận>"}'
>    ```
>    **Kỳ vọng:** nhận cặp Access Token & Refresh Token mới.
> 2. Gửi lại chính `refreshToken` cũ: **Kỳ vọng:** `401`, mã lỗi `AUTH_1105 (REFRESH_TOKEN_REVOKED)`; trong DB toàn bộ token của user chuyển `revoked = 1`.

---

### Task 2.4: Quản lý Nhân sự, Phòng làm việc & API nội bộ cho Feign
- **Người thực hiện:** Nguyễn Đức Khởi (Phụ trách FR-01, FR-02, BR-13)
- **Mục tiêu:** Admin quản lý tài khoản nội bộ (5 vai trò nhân sự), gán `room_number` cho Bác sĩ / KTV; cung cấp API nội bộ chỉ đọc.
- [ ] **2.4.1** CRUD tài khoản nhân viên (`GET/POST/PUT /api/v1/auth/users`, `POST /api/v1/auth/users/{id}/lock`), `@PreAuthorize("hasRole('ADMIN')")`.
- [ ] **2.4.2** Gán / cập nhật `room_number` (P101–P103 cho Bác sĩ, P201–P202 cho KTV).
- [ ] **2.4.3** API nội bộ: `GET /internal/users/active-doctors/count`, `GET /internal/users/{id}` (họ tên, vai trò, phòng, trạng thái).

> **Hướng dẫn Kiểm thử Task 2.4:**
> 1. Gọi trực tiếp cổng service (không qua Gateway):
>    ```bash
>    curl http://localhost:8081/internal/users/active-doctors/count
>    ```
> 2. **Kết quả kỳ vọng:** `200 OK`, `data: 3` (bs_tien, bs_an, bs_mai).
> 3. Gọi `POST /api/v1/auth/users` bằng `$TOKEN_VET` → `403`, mã lỗi `SYS_1003`.

---

### Task 2.5: Cấu hình Tầng Dữ liệu & Entity `appointment-service` (:8082)
- **Người thực hiện:** Lưu Minh Hiển
- **Mục tiêu:** Kết nối `pet_clinic_appointment_db`, cài đặt Entity `Appointment` và `AppointmentStatusHistory`.
- [ ] **2.5.1** Cấu hình `application.yml` kết nối `pet_clinic_appointment_db`.
- [ ] **2.5.2** Tạo Entity `Appointment` (**9 trường**: `id`, `appointmentCode`, `petId` (khóa ngoại logic), `appointmentDate`, `startTime`, `reason`, `bookingChannel`, `status`, `createdAt`). **Không có** `owner_id` (suy ra từ `pets.owner_id`), `end_time`, `updated_at`, `cancel_reason`.
- [ ] **2.5.3** Tạo Entity `AppointmentStatusHistory` (7 trường, `@ManyToOne` tới `Appointment`; `changedByUserId` nullable).
- [ ] **2.5.4** Tạo `AppointmentRepository`, `AppointmentStatusHistoryRepository`.

> **Hướng dẫn Kiểm thử Task 2.5:**
> 1. Chạy `contextLoads()`.
> 2. **Kết quả kỳ vọng:** Khởi động thành công, đăng ký lên Eureka với tên `APPOINTMENT-SERVICE`, không lỗi validate schema.

---

### Task 2.6: Thuật toán Tính Sức chứa Khung giờ Động
- **Người thực hiện:** Lưu Minh Hiển (Phụ trách FR-13, BR-04, BR-05)
- **Mục tiêu:** Tính số lịch tối đa cho mỗi khung giờ 30 phút theo số Bác sĩ `ACTIVE`.
- [ ] **2.6.1** Tạo `AuthClient` (OpenFeign, chỉ đọc) gọi `GET /internal/users/active-doctors/count`.
- [ ] **2.6.2** Công thức: $Capacity_{slot} = N_{active} \times 2$.
- [ ] **2.6.3** API công khai `GET /api/v1/appointments/slots?date=YYYY-MM-DD`: duyệt 14 khung giờ chuẩn (sáng 08:00 → 11:00, chiều 13:30 → 16:30, mỗi khung 30 phút), đếm lịch chiếm chỗ với **`status IN ('PENDING', 'CONFIRMED', 'CHECKED_IN')`** (lịch đã check-in vẫn chiếm chỗ; chỉ `CANCELLED`, `NO_SHOW` giải phóng chỗ), trả về số chỗ còn lại.

> **Hướng dẫn Kiểm thử Task 2.6:**
> 1. `curl "http://localhost:8080/api/v1/appointments/slots?date=2026-11-12"` (không cần token).
> 2. **Kết quả kỳ vọng:** 14 khung giờ (`08:00` … `11:00` và `13:30` … `16:30`, nghỉ trưa 12:00 – 13:30); mỗi khung: `maxCapacity: 6`, `bookedCount: 0`, `availableCount: 6`, `full: false`.
> 3. Đặt 1 lịch rồi check-in (Task 3.2) → gọi lại: khung giờ đó vẫn `bookedCount: 1`.

---

### Task 2.7: Đặt lịch, Duyệt lịch, Hủy lịch & Audit Trail
- **Người thực hiện:** Lưu Minh Hiển (Phụ trách FR-12, FR-14, FR-15, FR-16, UC-14 → UC-17)
- **Mục tiêu:** Khách đặt hẹn trực tuyến, Lễ tân duyệt / từ chối, khách tự hủy; ghi vết mọi lần đổi trạng thái.
- [ ] **2.7.1** API Đặt lịch (`POST /api/v1/appointments`): kiểm tra thú cưng thuộc chủ nuôi qua Feign `GET /internal/pets/{id}` (clinical), kiểm tra khung giờ còn chỗ, tạo `appointments` (`PENDING`, `booking_channel = ONLINE`, mã `APT-YYYYMMDD-XXX`); phát `AppointmentBookedEvent`.
- [ ] **2.7.2** Ghi lịch sử đầu tiên (`from_status = NULL`, `to_status = PENDING`, `changed_by_user_id` = id chủ nuôi).
- [ ] **2.7.3** API Duyệt (`POST /api/v1/appointments/{id}/confirm`, chỉ `RECEPTIONIST`): `PENDING → CONFIRMED`, ghi lịch sử, phát `AppointmentStatusChangedEvent`.
- [ ] **2.7.4** API Hủy / Từ chối (`POST /api/v1/appointments/{id}/cancel`, body `{"reason": "..."}` bắt buộc): chuyển `CANCELLED`, **lý do ghi vào `appointment_status_histories.notes`**; chủ nuôi chỉ tự hủy được trước giờ hẹn ≥ 2 tiếng (`APPT_1204`).
- [ ] **2.7.5** API Lễ tân đặt lịch qua điện thoại / tại quầy (`POST /api/v1/appointments/by-receptionist`, FR-15): tạo thẳng `CONFIRMED`, `booking_channel = PHONE` hoặc `WALK_IN`.

> **Hướng dẫn Kiểm thử Task 2.7:**
> 1. Chủ nuôi đặt lịch cho mèo Lu:
>    ```bash
>    curl -X POST http://localhost:8080/api/v1/appointments \
>      -H "Authorization: Bearer $TOKEN_OWNER" -H "Content-Type: application/json" \
>      -d '{"petId": 1, "appointmentDate": "2026-11-12", "startTime": "09:00:00",
>           "reason": "Mèo bị nôn mửa và bỏ ăn 2 ngày"}'
>    ```
>    **Kỳ vọng:** `201 Created`, mã dạng `APT-20261112-001`, status `PENDING`. (Body **không** có `endTime`, `ownerId`.)
> 2. Lễ tân duyệt: `curl -X POST http://localhost:8080/api/v1/appointments/1/confirm -H "Authorization: Bearer $TOKEN_REC"`.
> 3. Kiểm tra Audit Trail:
>    ```sql
>    SELECT from_status, to_status, changed_by_user_id, notes
>    FROM pet_clinic_appointment_db.appointment_status_histories WHERE appointment_id = 1;
>    ```
> 4. **Kết quả kỳ vọng:** 2 dòng: `NULL → PENDING` (user 8) và `PENDING → CONFIRMED` (user 5).

---

### Task 2.8: Quét Tự động Lịch hẹn Vắng mặt (No-Show Scheduler) – EX-01
- **Người thực hiện:** Lưu Minh Hiển (Phụ trách FR-17, EX-01)
- **Mục tiêu:** `@Scheduled` tự chuyển `NO_SHOW` các lịch `CONFIRMED` đã quá `appointment_date + start_time + 30 phút` mà chưa check-in.
- [ ] **2.8.1** Bật `@EnableScheduling`, tạo `AppointmentNoShowScheduler` (Quy chuẩn 11.3).
- [ ] **2.8.2** Cron 5 phút một lần, múi giờ `Asia/Ho_Chi_Minh` (`0 */5 7-21 * * *`); truy vấn `status = CONFIRMED AND (appointment_date < hôm nay OR (appointment_date = hôm nay AND start_time < bây giờ − 30 phút))`. **Không** dùng `end_time`.
- [ ] **2.8.3** Cập nhật `status = NO_SHOW`, ghi lịch sử với `changed_by_user_id = NULL` (hệ thống). Không có cột `updated_at`.
- [ ] **2.8.4** Phát `AppointmentNoShowEvent` (routing key `appointment.no_show`).

> **Hướng dẫn Kiểm thử Task 2.8:**
> 1. Nạp 1 lịch `CONFIRMED` hôm nay có `start_time` = 40 phút trước.
> 2. Gọi trực tiếp `scheduler.scanAndMarkNoShowAppointments()` trong test.
> 3. **Kết quả kỳ vọng:** lịch chuyển `NO_SHOW`; có dòng lịch sử `CONFIRMED → NO_SHOW`, `changed_by_user_id IS NULL`; RabbitMQ Management thấy 1 message `appointment.no_show`. Lịch có `start_time` = 20 phút trước **không** bị đổi.

---

## GIAI ĐOẠN 3: PHÂN HỆ LÂM SÀNG 2 PHA, CẬN LÂM SÀNG, KHÓA ƯU TIÊN & HÓA ĐƠN DỊCH VỤ

### Task 3.1: Cấu hình CSDL `clinical-service` (:8083) & Danh mục
- **Người thực hiện:** Lưu Minh Hiển & Nguyễn Đức Khởi
- **Mục tiêu:** Quản lý Loài, Thú cưng, Dịch vụ (gồm gói xét nghiệm), Chỉ số xét nghiệm, Khoảng tham chiếu theo loài.
- [ ] **3.1.1** Kết nối `pet_clinic_clinical_db` gồm **14 bảng** và VIEW `v_service_invoice_amounts`.
- [ ] **3.1.2** CRUD Thú cưng (`/api/v1/pets`, `/api/v1/species`) (FR-10, FR-11). Tìm thú cưng theo chủ: `GET /api/v1/pets?ownerId=` (`pets.owner_id`); tra theo số điện thoại thì Frontend tìm chủ nuôi ở `auth-service` trước rồi lọc theo `ownerId`. API nội bộ `GET /internal/pets/{id}` cho `appointment-service`.
- [ ] **3.1.3** CRUD Danh mục dịch vụ (`services`: `price`, `vat_rate`, `is_active`) và gói xét nghiệm (`service_lab_test_items`) (FR-03, FR-05); CRUD chỉ số xét nghiệm `lab_test_items`.
- [ ] **3.1.4** CRUD khoảng tham chiếu `lab_test_reference_ranges` (`min_value`, `max_value` theo `species_id`) (FR-06).

> **Hướng dẫn Kiểm thử Task 3.1:**
> 1. `curl "http://localhost:8080/api/v1/clinical/lab-test-items/RBC/reference-ranges" -H "Authorization: Bearer $TOKEN_LAB"`
> 2. **Kết quả kỳ vọng:** 2 khoảng tham chiếu: Chó (DOG) `5.50 – 8.50`, Mèo (CAT) `5.00 – 10.00` (đơn vị `10^12/L`).
> 3. `GET /api/v1/clinical/services/5/lab-test-items` → 4 chỉ số WBC, RBC, HGB, PLT của gói `LAB_CBC`.

---

### Task 3.2: Tiếp đón tại Quầy (Check-in), Khách Vãng lai & Hàng đợi Sảnh
- **Người thực hiện:** Nguyễn Đức Khởi (Phụ trách FR-18, FR-19, FR-20, FR-21, FR-26, UC-18, UC-19, UC-20, EX-02, EX-03, EX-04)
- **Mục tiêu:** Lễ tân tiếp nhận thú cưng (có hẹn hoặc vãng lai), tạo `pet_visits` (`WAITING`). **Lễ tân không cân, không đo thân nhiệt** – Bác sĩ làm trong phòng khám (Task 3.3).
- [ ] **3.2.1** API Check-in thống nhất (`POST /api/v1/clinical/pet-visits/check-in`), body `{petId, appointmentId (null nếu vãng lai), isEmergency, initialSymptoms}`:
  - Nếu có `appointmentId`: Feign **chỉ đọc** `GET /internal/appointments/{id}` – phải `CONFIRMED`, đúng ngày, đúng thú cưng (`APPT_1205`).
  - Chặn nếu thú cưng còn đợt khám chưa kết thúc (`CLIN_1306`).
  - Trong giao dịch: tạo `pet_visits` (`WAITING`, `checked_in_at`, `receptionist_id`, `is_emergency`), ghi lịch sử `NULL → WAITING`.
  - Sau commit: phát `VisitCheckedInEvent`. `appointment-service` (consumer, idempotent) chuyển lịch `CONFIRMED → CHECKED_IN` và ghi lịch sử. **Không** gọi Feign để ghi sang `appointment-service`.
- [ ] **3.2.2** Khách vãng lai (EX-02) dùng cùng endpoint với `appointmentId = null`. Khách đến sau khi lịch đã `NO_SHOW` cũng tiếp nhận như vãng lai (FR-18).
- [ ] **3.2.3** API Hàng đợi (FR-21, EX-04): `GET /api/v1/clinical/pet-visits/queue` (Lễ tân) trả **danh sách chờ phân công** và **hàng đợi của từng Bác sĩ** (kèm `waitingCount`, `suggestedDoctorId` = Bác sĩ ít người chờ nhất); `GET /api/v1/clinical/pet-visits/my-queue` (Bác sĩ) trả hàng đợi của chính mình. Thứ tự `ORDER BY (is_emergency AND skip_count = 0) DESC, queue_order ASC`. Check-in gán `queue_order = QueueOrders.now()` và nhận `doctorId` tùy chọn để xếp ngay vào hàng đợi Bác sĩ.
- [ ] **3.2.4** API Hủy tiếp nhận (`POST /api/v1/clinical/pet-visits/{id}/cancel`, body `{"reason": "..."}`, EX-03): `WAITING → CANCELLED`, **lý do ghi vào `pet_visit_status_histories.notes`** (không có cột `cancel_reason`).
- [ ] **3.2.5** Consumer `VisitCheckedInEvent` trong `appointment-service`: idempotent, retry 3 lần rồi vào DLQ.

> **Hướng dẫn Kiểm thử Task 3.2:**
> 1. Check-in lịch hẹn #1 của mèo Lu:
>    ```bash
>    curl -X POST http://localhost:8080/api/v1/clinical/pet-visits/check-in \
>      -H "Authorization: Bearer $TOKEN_REC" -H "Content-Type: application/json" \
>      -d '{"petId": 1, "appointmentId": 1, "isEmergency": false, "initialSymptoms": "Bỏ ăn, nôn 2 ngày"}'
>    ```
> 2. **Kết quả kỳ vọng:**
>    - `201 Created`, mã dạng `VISIT-2026-0001`, `status: "WAITING"`; `weight_at_visit`, `temperature` đang `NULL`.
>    - Sau ≤ 1 giây: `SELECT status FROM pet_clinic_appointment_db.appointments WHERE id = 1;` → `CHECKED_IN`, kèm 1 dòng lịch sử `CONFIRMED → CHECKED_IN` (user 5).
> 3. Gọi check-in lần nữa cho thú cưng 1 → `409`, mã lỗi `CLIN_1306`.
> 4. Check-in vãng lai cho chó Milo (dùng ở Task 3.3 và 3.7): body `{"petId": 2, "appointmentId": null, "isEmergency": false, "initialSymptoms": "Ngứa, rụng lông"}` → ca #2 `WAITING`; `GET /api/v1/clinical/pet-visits/queue` trả cả hai ca trong danh sách chờ phân công, ca #1 đứng trước ca #2.

---

### Task 3.3: Xếp ca vào Hàng đợi Bác sĩ, Gọi số, Đẩy lùi 1 bậc & Bắt đầu Khám Giai đoạn 1
- **Người thực hiện:** Lưu Minh Hiển (Phụ trách FR-22, FR-24, FR-25, FR-27, FR-28, FR-29, FR-47, UC-21, UC-22, EX-05, EX-10)
- **Mục tiêu:** Lễ tân xếp ca vào hàng đợi riêng của Bác sĩ bất kỳ (không cần Bác sĩ rảnh); Bác sĩ gọi số, đẩy lùi 1 bậc khi vắng mặt, bắt đầu khám (T02), hệ thống tự tạo dịch vụ khám + hóa đơn dịch vụ.
- [ ] **3.3.1** Truy vấn trạng thái Bác sĩ (`GET /api/v1/clinical/doctors/status`) theo State Machine mục 3.3: `BUSY` nếu có ca `IN_PROGRESS`, ngược lại `AVAILABLE`; kèm `waitingCount` (số ca `WAITING` / `RESULTS_READY` trong hàng đợi). Danh sách Bác sĩ, tên, phòng lấy qua Feign `auth-service`.
- [ ] **3.3.2** **API Xếp ca vào hàng đợi Bác sĩ** (`POST /api/v1/clinical/pet-visits/{id}/assign-doctor`, body `{"doctorId": 2}`, chỉ `RECEPTIONIST`): ca phải `WAITING` (`version` chống trùng); Bác sĩ phải là `VETERINARIAN` `ACTIVE` (Feign); **không kiểm tra Bác sĩ rảnh**; gán `doctor_id`, giữ nguyên `queue_order`. Gọi lại với Bác sĩ khác = chuyển hàng đợi. Màn hình Bác sĩ thấy ca mới ở lần làm mới hàng đợi kế tiếp.
- [ ] **3.3.2b** **API Gỡ phân công** (`POST /api/v1/clinical/pet-visits/{id}/unassign-doctor`, chỉ `RECEPTIONIST`, UC-21 Luồng 5c): ca phải `WAITING` và đã có `doctor_id`; đặt `doctor_id = NULL`, ca về danh sách chờ phân công, giữ `queue_order`. Trạng thái không đổi nên không ghi `pet_visit_status_histories`.
- [ ] **3.3.2c** **API Gọi số tiếp theo** (`POST /api/v1/clinical/pet-visits/call-next`, chỉ `VETERINARIAN`, Quy chuẩn 11.2 mục 6b): Bác sĩ không có ca `IN_PROGRESS` (`CLIN_1302`); chọn ca đầu `my-queue` (`CLIN_1303` nếu trống); phát `PatientCalledEvent`; ca chưa đổi trạng thái.
- [ ] **3.3.2d** **API Đẩy lùi 1 bậc** (`POST /api/v1/clinical/pet-visits/{id}/skip`, chỉ `VETERINARIAN`, EX-10, FR-47): áp dụng cho ca `WAITING` / `RESULTS_READY` trong hàng đợi của Bác sĩ; `skip_count + 1`, ca đứng ngay sau người kế tiếp (Q4), gọi người kế tiếp. Không còn ai phía sau thì giữ nguyên.
- [ ] **3.3.3** API Bắt đầu khám (`POST /api/v1/clinical/pet-visits/{id}/start-exam`, Quy chuẩn 11.2): chỉ Bác sĩ được gán (`CLIN_1311`), không có ca `IN_PROGRESS` khác; `WAITING → IN_PROGRESS` + lịch sử (thời điểm bắt đầu = `created_at` của dòng lịch sử, **không có cột `started_at`**); tự tạo `visit_service_details` dịch vụ khám `EXAM_GEN` (`IN_PROGRESS`) và **1 `service_invoices` `PENDING`** (snapshot `unit_price = 100000.00`, `vat_rate = 0.00`). Sinh hiệu có thể gửi kèm hoặc cập nhật sau.
- [ ] **3.3.4** API cập nhật sinh hiệu & ghi chú (`PUT /api/v1/clinical/pet-visits/{id}/clinical-info`): `weight_at_visit`, `temperature`, `clinical_notes`; API lịch sử bệnh án thú cưng (`GET /api/v1/pets/{id}/medical-history`, FR-28).

> **Hướng dẫn Kiểm thử Task 3.3:**
> 1. Lễ tân xếp ca #1 vào hàng đợi Bác sĩ Tiến:
>    ```bash
>    curl -X POST http://localhost:8080/api/v1/clinical/pet-visits/1/assign-doctor \
>      -H "Authorization: Bearer $TOKEN_REC" -H "Content-Type: application/json" -d '{"doctorId": 2}'
>    ```
>    **Kỳ vọng:** `200 OK`; ca vẫn `WAITING`; `GET /doctors/status`: Bác sĩ 2 `AVAILABLE`, `waitingCount = 1`.
> 2. Xếp tiếp ca #2 (chó Milo, check-in ở Task 3.2 bước 4) vào hàng đợi Bác sĩ 2 → `200 OK` (**không bị chặn**); `GET /pet-visits/my-queue` (token Bác sĩ 2) trả `[#1, #2]`.
> 2b. Gọi số và đẩy lùi:
>    ```bash
>    curl -X POST http://localhost:8080/api/v1/clinical/pet-visits/call-next -H "Authorization: Bearer $TOKEN_VET"   # gọi ca #1
>    curl -X POST http://localhost:8080/api/v1/clinical/pet-visits/1/skip -H "Authorization: Bearer $TOKEN_VET"      # #1 vắng mặt
>    ```
>    **Kỳ vọng:** lệnh `skip` trả ca #2 (người được gọi tiếp); `my-queue` = `[#2, #1]`, ca #1 `skipCount = 1`. Đẩy lùi ca #2 một lần để trả lại thứ tự `[#1, #2]` cho các bước sau. Gọi `call-next` khi Bác sĩ đang có ca `IN_PROGRESS` → `409 CLIN_1302`.
> 3. Bác sĩ Tiến bắt đầu khám:
>    ```bash
>    curl -X POST http://localhost:8080/api/v1/clinical/pet-visits/1/start-exam \
>      -H "Authorization: Bearer $TOKEN_VET" -H "Content-Type: application/json" \
>      -d '{"weightAtVisit": 4.6, "temperature": 39.2, "clinicalNotes": "Niêm mạc nhợt, ấn đau vùng bụng"}'
>    ```
>    *(Tên trường JSON đúng theo DTO `StartExaminationRequest`; gửi sai tên, ví dụ `weight`, Jackson sẽ bỏ qua và cân nặng không được lưu.)*
> 4. **Kết quả kỳ vọng:** `200 OK`, `status: "IN_PROGRESS"`; `SELECT * FROM service_invoices;` → 1 dòng `SINV-…`, `unit_price = 100000.00`, `payment_status = PENDING`. Bác sĩ An (id 3) gọi start-exam ca này → `403`, mã `CLIN_1311`.

---

### Task 3.4: Chỉ định Dịch vụ, Lập Hóa đơn Dịch vụ & Tách hàng đợi Song song (Fork)
- **Người thực hiện:** Lưu Minh Hiển (Phụ trách FR-30, FR-31, FR-32, FR-33, FR-34, UC-23, BR-19, BR-25, BR-33)
- **Mục tiêu:** Mỗi dịch vụ được chỉ định sinh **đúng 1 hóa đơn dịch vụ** trong cùng giao dịch; chỉ định cận lâm sàng chuyển ca sang `WAITING_RESULTS` (T04) và giải phóng Bác sĩ.
- [ ] **3.4.1** API Chỉ định cận lâm sàng (`POST /api/v1/clinical/pet-visits/{id}/paraclinical-orders`, body `{serviceIds, notes}`): chỉ nhận dịch vụ `LABORATORY` / `IMAGING`; yêu cầu đã có `weight_at_visit`, `temperature` (`CLIN_1308`) và không còn dịch vụ tại phòng dang dở (`CLIN_1309`).
- [ ] **3.4.2** Trong **một giao dịch**: với mỗi dịch vụ tạo `visit_service_details` (`PENDING`, history `action = ORDERED`) **và** `service_invoices` (`PENDING`, snapshot `unit_price = services.price`, `vat_rate = services.vat_rate`, mã `SINV-YYYY-XXXX`); dịch vụ khám → `COMPLETED`; `pet_visits` → `WAITING_RESULTS` + lịch sử. (`visit_service_details` **không** chứa giá.)
- [ ] **3.4.3** Dịch vụ tại phòng (tiêm, tẩy giun, thủ thuật – FR-30): `POST /api/v1/clinical/pet-visits/{id}/in-room-services` tạo chỉ định + hóa đơn `PENDING`; `POST /api/v1/clinical/service-details/{detailId}/perform` → `COMPLETED`.
- [ ] **3.4.4** API Hủy dịch vụ (`POST /api/v1/clinical/service-details/{detailId}/cancel`, body `{"reason": "..."}`): dịch vụ `CANCELLED` **và hóa đơn của nó `CANCELLED`** cùng giao dịch; chặn nếu hóa đơn đã `PAID` (`CLIN_1310`).
- [ ] **3.4.5** API Hủy ca / Chuyển viện GĐ 1 (`POST /api/v1/clinical/pet-visits/{id}/cancel-exam`, FR-34): chỉ khi **chưa có dịch vụ tại phòng nào `COMPLETED`** (ngược lại trả `400 CLIN_1305`, Bác sĩ phải chốt ca); hủy mọi dịch vụ của ca kèm hóa đơn, ca → `CANCELLED`, lý do vào lịch sử.
- [ ] **3.4.6** Phát `PatientCalledEvent` hướng dẫn chủ nuôi sang khu cận lâm sàng (không còn `ServicesPrescribedEvent`).

> **Hướng dẫn Kiểm thử Task 3.4:**
> 1. Bác sĩ chỉ định xét nghiệm CBC (service 5) và X-quang (service 7):
>    ```bash
>    curl -X POST http://localhost:8080/api/v1/clinical/pet-visits/1/paraclinical-orders \
>      -H "Authorization: Bearer $TOKEN_VET" -H "Content-Type: application/json" \
>      -d '{"serviceIds": [5, 7], "notes": "Kiểm tra viêm tụy cấp và dị vật đường tiêu hóa"}'
>    ```
> 2. **Kết quả kỳ vọng:**
>    - `200 OK`; ca `status: "WAITING_RESULTS"`; Bác sĩ 2 trở về `AVAILABLE`.
>    - `visit_service_details`: dòng 1 (khám) `COMPLETED`, dòng 2 (CBC) và 3 (X-quang) `PENDING`.
>    - `service_invoices`: 3 dòng `PENDING` với `unit_price` 100000.00 / 250000.00 / 180000.00.
>    - `SELECT SUM(payable_amount) FROM v_service_invoice_amounts WHERE visit_id = 1;` → `530000.00`.
> 3. Thử chỉ định trên một ca chưa nhập cân nặng → `400`, mã `CLIN_1308`.

---

### Task 3.5: Phòng Xét nghiệm – Gọi số, Đẩy lùi 1 bậc, Lấy mẫu & Nhập Kết quả
- **Người thực hiện:** Nguyễn Đức Khởi (Phụ trách FR-35, FR-37, FR-38, FR-39, FR-40, FR-41, UC-25, BR-23, BR-24, BR-34, EX-06, EX-07)
- **Mục tiêu:** KTV Lab gọi số, lấy mẫu, nhập chỉ số; hệ thống lưu khoảng tham chiếu snapshot. Nhãn `LOW / NORMAL / HIGH` **tính khi hiển thị**, không lưu.
- [ ] **3.5.1** API Hàng đợi Lab: `GET /api/v1/clinical/lab-queue` (dịch vụ `LABORATORY` `PENDING`, tự vào hàng đợi khi chỉ định; `ORDER BY (is_emergency AND skip_count = 0) DESC, queue_order ASC`, chỉ mục `idx_vsd_queue`).
- [ ] **3.5.2** API thao tác dịch vụ: `POST /api/v1/clinical/lab-queue/call-next` và `/imaging-queue/call-next` (chọn dịch vụ đầu hàng đợi phòng, phát `PatientCalledEvent`, giữ `PENDING`), `POST /api/v1/clinical/service-details/{id}/skip` (Đẩy lùi 1 bậc, EX-06: `skip_count + 1`, đổi `queue_order`, `action = SKIPPED`, gọi người kế tiếp), `/start` (`PENDING → IN_PROGRESS`, `action = START_PROCESSING`), `/sample-collected` (`action = SAMPLE_COLLECTED`, giữ `IN_PROGRESS`). Khách quay lại sau khi bị lùi (EX-07) không cần API riêng.
- [ ] **3.5.3** API Nhập kết quả (`POST /api/v1/clinical/lab-results/{detailId}`), body `{"results": [{"labTestItemId": 2, "resultValue": 4.20}, …]}`:
  - Phải nhập đủ các chỉ số thuộc gói (`service_lab_test_items`).
  - Lưu `lab_test_results` (`result_value`, `min_value_snapshot`, `max_value_snapshot` theo loài của thú cưng, `performed_by`).
  - Chuyển dịch vụ `COMPLETED`; kiểm tra điều kiện Join (Task 3.7).
- [ ] **3.5.4** API xem kết quả trả về thêm trường tính toán `evaluation` (enum `LabEvaluation`, không có cột trong CSDL).

> **Hướng dẫn Kiểm thử Task 3.5:**
> 1. KTV Lab bắt đầu và đánh dấu đã lấy mẫu cho dòng chỉ định #2:
>    ```bash
>    curl -X POST http://localhost:8080/api/v1/clinical/service-details/2/start -H "Authorization: Bearer $TOKEN_LAB"
>    curl -X POST http://localhost:8080/api/v1/clinical/service-details/2/sample-collected -H "Authorization: Bearer $TOKEN_LAB"
>    ```
> 2. Nhập 4 chỉ số cho mèo Lu (RBC = 4.20, ngưỡng mèo 5.00 – 10.00):
>    ```bash
>    curl -X POST http://localhost:8080/api/v1/clinical/lab-results/2 \
>      -H "Authorization: Bearer $TOKEN_LAB" -H "Content-Type: application/json" \
>      -d '{"results": [{"labTestItemId": 1, "resultValue": 12.30}, {"labTestItemId": 2, "resultValue": 4.20},
>                       {"labTestItemId": 3, "resultValue": 9.10},  {"labTestItemId": 4, "resultValue": 410.00}]}'
>    ```
> 3. **Kết quả kỳ vọng:**
>    - `200 OK`; `lab_test_results` có 4 dòng; dòng RBC: `min_value_snapshot = 5.00`, `max_value_snapshot = 10.00` (bảng **không có** cột `evaluation`).
>    - `GET /api/v1/clinical/lab-results/2` trả RBC kèm `"evaluation": "LOW"`.
>    - Dòng chỉ định #2 `COMPLETED`; `visit_service_detail_histories` có các action `ORDERED`, `START_PROCESSING`, `SAMPLE_COLLECTED`, `COMPLETED`.
>    - Gửi thiếu chỉ số PLT → `400`, mã `SYS_1001`.

---

### Task 3.6: Phòng Chẩn đoán Hình ảnh – Huy hiệu liên phòng, Kết quả & Tệp đính kèm
- **Người thực hiện:** Nguyễn Đức Khởi (Phụ trách FR-36, FR-42, UC-26, EX-09)
- **Mục tiêu:** KTV CĐHA chụp X-quang / siêu âm, nhập mô tả, kết luận và tải ảnh. Thứ tự lưu đúng khóa ngoại: `imaging_results` trước, `imaging_attachments` sau.
- [ ] **3.6.1** Huy hiệu liên phòng trên `GET /api/v1/clinical/imaging-queue`: `labStatus = SAMPLING` nếu dịch vụ Lab cùng ca `IN_PROGRESS` và `action` mới nhất `START_PROCESSING`; `labStatus = SAMPLE_COLLECTED` nếu đã lấy mẫu (EX-09).
- [ ] **3.6.2** API Hoàn tất CĐHA **một request multipart** (`POST /api/v1/clinical/imaging-results/{detailId}`): trường `description`, `conclusion` và `files[]`. Trong một giao dịch: tạo `imaging_results` → lưu tệp vào volume `/app/uploads/imaging/` → tạo `imaging_attachments` trỏ tới `imaging_result_id` vừa tạo → dịch vụ `COMPLETED`. Lỗi lưu tệp thì rollback và xóa tệp đã ghi.
- [ ] **3.6.3** Giới hạn định dạng `image/jpeg`, `image/png`, `application/dicom`; dung lượng tối đa mỗi tệp cấu hình ở `spring.servlet.multipart.max-file-size`.

> **Hướng dẫn Kiểm thử Task 3.6:**
> 1. KTV CĐHA hoàn tất X-quang cho dòng chỉ định #3:
>    ```bash
>    curl -X POST http://localhost:8080/api/v1/clinical/service-details/3/start -H "Authorization: Bearer $TOKEN_IMG"
>    curl -X POST http://localhost:8080/api/v1/clinical/imaging-results/3 \
>      -H "Authorization: Bearer $TOKEN_IMG" \
>      -F "description=Dạ dày giãn nhẹ, có hình ảnh cản quang nghi dị vật" \
>      -F "conclusion=Nghi ngờ dị vật đường tiêu hóa đoạn môn vị" \
>      -F "files=@xray_cat_001.jpg"
>    ```
> 2. **Kết quả kỳ vọng:** `200 OK`; `imaging_results` 1 dòng; `imaging_attachments` 1 dòng có `imaging_result_id` đúng; dòng chỉ định #3 `COMPLETED`.
> 3. EX-09: trước khi Lab bấm "Đã lấy mẫu", `imaging-queue` hiển thị `labStatus: "SAMPLING"`.

---

### Task 3.7: Hợp nhất Kết quả (Join) & Đưa ca lên đầu hàng đợi Bác sĩ
- **Người thực hiện:** Lưu Minh Hiển (Phụ trách FR-23, FR-43, FR-44, BR-11, EX-05, EX-08)
- **Mục tiêu:** Khi mọi dịch vụ cận lâm sàng của ca đã `COMPLETED` hoặc `CANCELLED`, chuyển ca `RESULTS_READY` (T06) và đưa ca lên đầu hàng đợi của Bác sĩ khám chính.
- [ ] **3.7.1** Sau mỗi lần lưu kết quả / hủy dịch vụ: nếu không còn dịch vụ `LABORATORY` / `IMAGING` nào `PENDING` hoặc `IN_PROGRESS` → `pet_visits.status = RESULTS_READY`, lịch sử `changed_by_user_id = NULL`.
- [ ] **3.7.2** Phát `ParaclinicalResultsReadyEvent` (routing key `visit.results_ready`) sau commit.
- [ ] **3.7.3** Đặt `queue_order = findMinQueueOrder(doctorId) − 1`, `skip_count = 0` trong cùng giao dịch T06: ca đứng đầu hàng đợi Bác sĩ, chỉ sau ca cấp cứu (FR-23). Lễ tân vẫn xếp ca mới vào hàng đợi Bác sĩ này bình thường.

> **Hướng dẫn Kiểm thử Task 3.7:**
> 1. Sau Task 3.5 và 3.6: `SELECT status FROM pet_clinic_clinical_db.pet_visits WHERE id = 1;` → `RESULTS_READY`.
> 2. `GET /pet-visits/my-queue` (Bác sĩ 2) → ca #1 (`RESULTS_READY`) đứng đầu, trước ca #2 (`WAITING`). Xếp thêm một ca mới vào hàng đợi Bác sĩ 2 → `200 OK`, ca mới đứng sau ca #1 (EX-05).
> 3. EX-08: tạo ca khác chỉ định CBC + Siêu âm, hủy Siêu âm khi CBC đã xong → ca chuyển `RESULTS_READY`; hóa đơn Siêu âm `CANCELLED`, hóa đơn CBC vẫn `PENDING`.

---

### Task 3.8: Bắt đầu Giai đoạn 2, Đóng ca, Chốt Ca & Mở lại Hồ sơ
- **Người thực hiện:** Lưu Minh Hiển (Phụ trách FR-45, FR-46, FR-48, FR-49, FR-50, FR-54, UC-30, UC-33, EX-11, EX-12)
- **Mục tiêu:** Bác sĩ đón ca có kết quả, chẩn đoán, chốt ca (`WAITING_PAYMENT`); xử lý khách vắng / bỏ về và mở lại hồ sơ.
- [ ] **3.8.1** API Bắt đầu Giai đoạn 2 (`POST /api/v1/clinical/pet-visits/{id}/start-phase2`, T07): Bác sĩ gọi ca bằng `call-next` (Task 3.3.2c, ca có kết quả đứng đầu); khi thú cưng vào phòng gọi API này: ca `RESULTS_READY` thuộc hàng đợi của Bác sĩ, Bác sĩ không có ca `IN_PROGRESS` (`CLIN_1302`); → `IN_PROGRESS` + lịch sử.
- [ ] **3.8.2** Khách vắng mặt khi gọi ca có kết quả (EX-10): dùng chung API `skip` (Task 3.3.2d); ca giữ `RESULTS_READY`. Không còn API `postpone-callback` và tab "ca đã hoãn" (bỏ T13).
- [ ] **3.8.3** API Đóng ca / Khách bỏ về (`POST /api/v1/clinical/pet-visits/{id}/abandon`, T08 / T12, EX-11, FR-45, FR-48): áp dụng cho `RESULTS_READY` hoặc `WAITING_RESULTS` (không có dịch vụ đang `IN_PROGRESS`); dịch vụ còn `PENDING` → `CANCELLED` kèm hóa đơn; **không tạo hóa đơn mới** – hóa đơn của dịch vụ đã làm giữ `PENDING` làm công nợ; ca → `COMPLETED`.
- [ ] **3.8.4** API Chốt đợt khám (`POST /api/v1/clinical/pet-visits/{id}/close-visit`, T05 / T09): body `{diagnosis, treatmentPlan, doctorAdvice}`; chặn khi thiếu chẩn đoán (`CLIN_1307`, EX-12) hoặc còn dịch vụ tại phòng chưa xử lý (`CLIN_1309`); → `WAITING_PAYMENT` + lịch sử (**không có cột `closed_at`**); không lập thêm hóa đơn; không phát sự kiện sang billing.
- [ ] **3.8.5** API Mở lại hồ sơ (`POST /api/v1/clinical/pet-visits/{id}/reopen`, T14): Bác sĩ phụ trách hoặc ADMIN, lý do bắt buộc; `WAITING_PAYMENT → IN_PROGRESS`.

> **Hướng dẫn Kiểm thử Task 3.8:**
> 1. Bác sĩ gọi số rồi đón ca #1: `curl -X POST …/pet-visits/call-next -H "Authorization: Bearer $TOKEN_VET"` (trả ca #1), sau đó `curl -X POST …/pet-visits/1/start-phase2 -H "Authorization: Bearer $TOKEN_VET"` → `IN_PROGRESS`.
> 2. Bấm chốt khi chưa có chẩn đoán → `400`, mã `CLIN_1307`.
> 3. Chốt chuyên môn (đơn thuốc đã lưu ở Task 4.2):
>    ```bash
>    curl -X POST http://localhost:8080/api/v1/clinical/pet-visits/1/close-visit \
>      -H "Authorization: Bearer $TOKEN_VET" -H "Content-Type: application/json" \
>      -d '{"diagnosis": "Viêm dạ dày ruột cấp do búi lông tắc nghẽn",
>           "treatmentPlan": "Gel tiêu lông, bù nước điện giải, kháng sinh 5 ngày",
>           "doctorAdvice": "Theo dõi phân; nếu tiếp tục nôn phải tái khám ngay"}'
>    ```
> 4. **Kết quả kỳ vọng:** `200 OK`, `status: "WAITING_PAYMENT"`; mọi API sửa chuyên môn trên ca #1 trả `400 CLIN_1305`; `service_invoices` vẫn 3 dòng `PENDING`.
> 5. EX-10: với một ca `RESULTS_READY` khác, `call-next` rồi `skip` → ca vẫn `RESULTS_READY`, đứng sau người kế tiếp; Bác sĩ vẫn `AVAILABLE`.

---

### Task 3.9: Thu tiền Hóa đơn Dịch vụ & Hoàn tất Ca khám (`clinical-service`)
- **Người thực hiện:** Lưu Minh Hiển (Phụ trách FR-55, FR-56, FR-57, FR-58, FR-59, FR-60, UC-34, UC-35, BR-27, BR-28, EX-14)
- **Mục tiêu:** Thu ngân thu tiền các hóa đơn dịch vụ; khi mọi hóa đơn dịch vụ `PAID` / `CANCELLED`, ca `COMPLETED` **trong cùng giao dịch cục bộ** (T10). Không phụ thuộc việc mua thuốc.
- [ ] **3.9.1** API Bảng kê (`GET /api/v1/clinical/pet-visits/{id}/service-invoices`): danh sách hóa đơn + số tiền từ VIEW `v_service_invoice_amounts`, tổng cần thu = tổng các hóa đơn `PENDING`. Danh sách ca chờ thu: `GET /api/v1/clinical/pet-visits?status=WAITING_PAYMENT` và `GET /api/v1/clinical/pet-visits/with-debt` (ca `COMPLETED` còn hóa đơn `PENDING`).
- [ ] **3.9.2** API Giảm giá (`POST /api/v1/clinical/service-invoices/{id}/discount`, body `{"discountAmount": 30000}`): `discountAmount ≤ quantity × unit_price × (1 + vat_rate)` của **chính hóa đơn đó** (`BILL_1402`, EX-14).
- [ ] **3.9.3** API Xác nhận thanh toán (`POST /api/v1/clinical/pet-visits/{id}/service-invoices/confirm-payment`, body `{"invoiceIds": [...]}`, Quy chuẩn 8.3): ca phải `WAITING_PAYMENT` hoặc `COMPLETED` có công nợ (`BILL_1409`); hóa đơn `PAID`, `paid_at`, `cashier_id`; mọi `invoiceIds` phải thuộc ca (`BILL_1401`), đang `PENDING` (`BILL_1403` nếu đã thu, `BILL_1408` nếu đã hủy); `@Version` chống thu trùng (`SYS_1005`); nếu hết hóa đơn `PENDING` và ca `WAITING_PAYMENT` → `COMPLETED` + lịch sử; phát `VisitCompletedEvent`. Không lưu phương thức thanh toán (FR-57).
- [ ] **3.9.4** API in phiếu tạm tính / phiếu thu (FR-58).

> **Hướng dẫn Kiểm thử Task 3.9:**
> 1. Xem bảng kê ca #1: `curl http://localhost:8080/api/v1/clinical/pet-visits/1/service-invoices -H "Authorization: Bearer $TOKEN_REC"` → 3 hóa đơn, tổng `530000.00`.
> 2. Giảm giá 300.000 cho hóa đơn X-quang (180.000) → `400`, mã `BILL_1402`.
> 3. Thanh toán:
>    ```bash
>    curl -X POST http://localhost:8080/api/v1/clinical/pet-visits/1/service-invoices/confirm-payment \
>      -H "Authorization: Bearer $TOKEN_REC" -H "Content-Type: application/json" -d '{"invoiceIds": [1, 2, 3]}'
>    ```
> 4. **Kết quả kỳ vọng:** `200 OK`; 3 hóa đơn `PAID` (`cashier_id = 5`); `pet_visits.status = COMPLETED` ngay trong cùng phản hồi; lịch sử có dòng `WAITING_PAYMENT → COMPLETED`.
> 5. Gửi lại cùng request → `409`, mã `BILL_1403`.

---

## GIAI ĐOẠN 4: KÊ ĐƠN, BÁN THUỐC THEO ĐƠN (TÙY CHỌN) & TRỪ KHO NGUYÊN TỬ

### Task 4.1: Cấu hình CSDL `billing-pharmacy-service` (:8084)
- **Người thực hiện:** Lưu Minh Hiển
- **Mục tiêu:** Quản lý thuốc, đơn thuốc, hóa đơn thuốc, chi tiết hóa đơn thuốc và nhật ký kho.
- [ ] **4.1.1** Kết nối `pet_clinic_billing_pharmacy_db` gồm 6 bảng và VIEW `v_medicine_invoice_amounts`.
- [ ] **4.1.2** Entities: `Medicine` (`@Version`), `Prescription`, `PrescriptionItem`, `MedicineInvoice` (`@Version`), `MedicineInvoiceItem`, `InventoryTransaction`. **Không có** `Invoice`, `InvoiceItem`; `Prescription` **không có** `status`; `InventoryTransaction` **không có** `balance_after`.
- [ ] **4.1.3** Khóa ngoại nội bộ cần ánh xạ: `prescription_items → prescriptions, medicines`; `medicine_invoices.prescription_id → prescriptions` (UNIQUE); `medicine_invoice_items → medicine_invoices, prescription_items`; `inventory_transactions → medicines, medicine_invoices`.
- [ ] **4.1.4** Feign chỉ đọc `ClinicalVisitClient`: `GET /internal/pet-visits/{id}/summary` (status, doctorId).

> **Hướng dẫn Kiểm thử Task 4.1:**
> 1. Khởi động `billing-pharmacy-service`.
> 2. **Kết quả kỳ vọng:** khởi động không lỗi validate schema, đăng ký Eureka thành công.

---

### Task 4.2: Kê Đơn thuốc Điện tử & Cảnh báo Tồn kho
- **Người thực hiện:** Lưu Minh Hiển (Phụ trách FR-51, FR-52, FR-53, UC-31, BR-18, BR-30, BR-32, EX-13)
- **Mục tiêu:** Bác sĩ kê đơn thuốc mang về; đơn thuốc **không có giá, không có trạng thái**; vượt tồn kho chỉ cảnh báo.
- [ ] **4.2.1** API Kê / cập nhật đơn (`POST /api/v1/pharmacy/prescriptions`, `PUT /api/v1/pharmacy/prescriptions/{id}`): Facade gọi Feign kiểm tra ca `IN_PROGRESS` và đúng Bác sĩ phụ trách (`PHARM_1411` nếu đã khóa); khi sửa đơn sau "Mở lại hồ sơ", chặn nếu đơn đã có hóa đơn thuốc chưa hủy (`PHARM_1411`); tối đa 1 đơn / đợt khám (`visit_id UNIQUE`); mỗi thuốc 1 dòng.
- [ ] **4.2.2** Mỗi dòng bắt buộc đủ các trường NOT NULL: `medicineId`, `quantity` (> 0), `dosage`, `frequency`, `durationDays` (> 0); `instructions` tùy chọn.
- [ ] **4.2.3** Phản hồi kèm danh sách cảnh báo `stockWarnings` nếu `quantity > stock_quantity` (EX-13), **không chặn** lưu.

> **Hướng dẫn Kiểm thử Task 4.2:**
> 1. Kê 10 viên Clavamox (thuốc #1, tồn 200) cho ca #1 trước khi chốt ca:
>    ```bash
>    curl -X POST http://localhost:8080/api/v1/pharmacy/prescriptions \
>      -H "Authorization: Bearer $TOKEN_VET" -H "Content-Type: application/json" \
>      -d '{"visitId": 1, "doctorNotes": "Uống sau ăn",
>           "items": [{"medicineId": 1, "quantity": 10, "dosage": "1 viên/lần",
>                      "frequency": "2 lần/ngày", "durationDays": 5, "instructions": "Uống sau ăn no"}]}'
>    ```
> 2. **Kết quả kỳ vọng:** `201 Created`; `prescriptions` và `prescription_items` không có cột giá / trạng thái; `stockWarnings: []`.
> 3. EX-13: kê 300 viên → `201 Created` kèm `stockWarnings: ["Clavamox 250mg: tồn kho 200 < số lượng kê 300"]`.
> 4. Thiếu `frequency` → `400`, mã `SYS_1001`. Kê thêm cho ca đã `WAITING_PAYMENT` → `409`, mã `PHARM_1411`.

---

### Task 4.3: Lập Hóa đơn Thuốc khi Khách chọn Mua tại Phòng khám
- **Người thực hiện:** Lưu Minh Hiển (Phụ trách FR-56, FR-61, FR-62, UC-36, BR-26, BR-32, EX-14)
- **Mục tiêu:** Khách được mua tại phòng khám (một phần hoặc toàn bộ đơn) hoặc mua ngoài. Giá thuốc chốt tại thời điểm lập hóa đơn thuốc.
- [ ] **4.3.1** API Lập hóa đơn thuốc (`POST /api/v1/pharmacy/prescriptions/{id}/medicine-invoices`), body `{items: [{prescriptionItemId, quantity}], discountAmount}` (Quy chuẩn 8.2 `createInvoice`): Facade kiểm tra ca `WAITING_PAYMENT` / `COMPLETED` qua Feign; chặn nếu đơn đã có hóa đơn thuốc (`PHARM_1407`); `quantity ≤` số lượng kê (`PHARM_1410`); snapshot `unit_price = medicines.sale_price`, `vat_rate = medicines.vat_rate`; giảm giá ≤ tổng tiền thuốc (`BILL_1402`); trạng thái `PENDING`, mã `MINV-YYYY-XXXX`.
- [ ] **4.3.2** API Hủy hóa đơn thuốc khi khách đổi ý (`POST /api/v1/billing/medicine-invoices/{id}/cancel`): `PENDING → CANCELLED`, kho không đổi. Hủy là kết thúc: đơn này không lập lại hóa đơn thuốc.
- [ ] **4.3.4** API Sửa hóa đơn thuốc (`PUT /api/v1/billing/medicine-invoices/{id}/items`, body `{"items": [{"prescriptionItemId": 1, "quantity": 5}], "discountAmount": 0}`, Quy chuẩn 8.2 `updateItems`): chỉ khi `PENDING` (`BILL_1403` / `BILL_1408`); `quantity = 0` để bỏ dòng, `quantity ≤` số lượng kê (`PHARM_1410`); còn ít nhất 1 dòng; giữ snapshot giá; kiểm tra lại giảm giá (`BILL_1402`).
- [ ] **4.3.3** API In đơn thuốc cho khách mua ngoài (`GET /api/v1/pharmacy/prescriptions/{id}/print`), không tạo hóa đơn.

> **Hướng dẫn Kiểm thử Task 4.3:**
> 1. Khách mua cả 10 viên:
>    ```bash
>    curl -X POST http://localhost:8080/api/v1/pharmacy/prescriptions/1/medicine-invoices \
>      -H "Authorization: Bearer $TOKEN_REC" -H "Content-Type: application/json" \
>      -d '{"items": [{"prescriptionItemId": 1, "quantity": 10}], "discountAmount": 0}'
>    ```
> 2. **Kết quả kỳ vọng:** `201 Created`; `medicine_invoice_items`: `unit_price = 15000.00`, `vat_rate = 0.05`; `SELECT payable_amount FROM v_medicine_invoice_amounts WHERE invoice_id = 1;` → `157500.00` (10 × 15.000 × 1,05).
> 3. Lập hóa đơn thứ hai cho cùng đơn → `409`, mã `PHARM_1407`. Mua 12 viên → `400`, mã `PHARM_1410`.
> 4. Sửa hóa đơn #1 về 8 viên (`PUT …/medicine-invoices/1/items`) → `payable_amount = 126000.00`; sửa lại 10 viên → `157500.00` (đơn giá vẫn 15.000 dù danh mục có đổi giá).

---

### Task 4.4: Xác nhận Thanh toán Thuốc & Trừ kho Nguyên tử (một giao dịch)
- **Người thực hiện:** Lưu Minh Hiển (Phụ trách FR-63, FR-64, FR-65, UC-36, BR-29, BR-30, BR-31, EX-15, EX-16)
- **Mục tiêu:** Chuyển hóa đơn thuốc `PAID`, trừ kho và ghi nhật ký `EXPORT_SALE` trong **cùng một `@Transactional`** (Quy chuẩn 8.2 `confirmPayment`). Không ảnh hưởng trạng thái đợt khám.
- [ ] **4.4.1** Hóa đơn phải `PENDING` (`BILL_1403` nếu đã `PAID`, `BILL_1408` nếu `CANCELLED`).
- [ ] **4.4.2** Sắp xếp dòng theo `medicineId`; trừ kho bằng `deductStockQuantity` (`UPDATE … WHERE stock_quantity >= :qty`, tăng `version`). Ảnh hưởng 0 dòng → ném `PHARM_1406` → rollback toàn bộ, hóa đơn giữ `PENDING` (EX-15).
- [ ] **4.4.3** Ghi `inventory_transactions` mỗi dòng: `transaction_type = 'EXPORT_SALE'`, `quantity = -qty`, `medicine_invoice_id`, `created_by`.
- [ ] **4.4.4** Cập nhật `payment_status = PAID`, `paid_at`, `cashier_id`; `@Version` chặn bấm đúp (`SYS_1005`, EX-16).
- [ ] **4.4.5** Sau commit phát `MedicineInvoicePaidEvent`; nếu thuốc chạm `min_stock_alert` phát `MedicineLowStockEvent`.
- [ ] **4.4.6** API Nhập kho / Cân chỉnh kho (`POST /api/v1/pharmacy/inventory/import`, `/adjust`, chỉ ADMIN, FR-66): ghi `IMPORT` (+) / `ADJUSTMENT` (±) và cập nhật `stock_quantity` cùng giao dịch.

> **Hướng dẫn Kiểm thử Task 4.4:**
> 1. Thu ngân xác nhận thanh toán thuốc:
>    ```bash
>    curl -X POST http://localhost:8080/api/v1/billing/medicine-invoices/1/confirm-payment \
>      -H "Authorization: Bearer $TOKEN_REC"
>    ```
> 2. **Kết quả kỳ vọng:**
>    - `200 OK`; `medicine_invoices.payment_status = 'PAID'`, `cashier_id = 5`.
>    - `medicines.stock_quantity` của thuốc #1: 200 → **190**.
>    - `inventory_transactions`: 1 dòng `EXPORT_SALE`, `quantity = -10`, `medicine_invoice_id = 1`.
>    - Bất biến: `SUM(quantity)` của thuốc #1 = 190.
>    - `pet_visits.status` của ca #1 **không đổi** (đã `COMPLETED` từ Task 3.9).
> 3. EX-16: gọi lại cùng API → `409`, mã `BILL_1403`; tồn kho vẫn 190.
> 4. EX-15: dùng API cân chỉnh kho (4.4.6, `ADJUSTMENT −185`) để thuốc #1 còn 5 viên; lập hóa đơn mua 10 viên của một đơn khác rồi xác nhận → `409`, mã `PHARM_1406`; tồn kho vẫn 5, không có dòng `EXPORT_SALE` mới, hóa đơn vẫn `PENDING`. Sửa hóa đơn đó về 5 viên (4.3.4) rồi xác nhận lại → `PAID`, tồn kho 0, bất biến `SUM(quantity) = stock_quantity` vẫn đúng.

---

## GIAI ĐOẠN 5: THÔNG BÁO REALTIME, FRONTEND REACT & KIỂM THỬ TOÀN DIỆN

### Task 5.1: Phân hệ Thông báo & Realtime WebSocket (`notification-service` :8085)
- **Người thực hiện:** Nguyễn Đức Khởi
- **Mục tiêu:** Lắng nghe sự kiện trên exchange `clinic.events`, đẩy thông báo realtime qua WebSocket STOMP và gửi Email. Không dùng SMS.
- [ ] **5.1.1** Cấu hình STOMP Broker (`/topic/lobby`, `/topic/doctor/{id}`, `/topic/lab`, `/topic/imaging`, `/topic/admin`, `/user/queue/notifications`).
- [ ] **5.1.2** Listener `AppointmentBookedEvent`, `AppointmentStatusChangedEvent`, `AppointmentNoShowEvent` → Email / thông báo Portal cho chủ nuôi.
- [ ] **5.1.3** Listener `VisitCheckedInEvent`, `PatientCalledEvent` → cập nhật bảng hàng đợi và màn hình gọi số ở sảnh.
- [ ] **5.1.4** Listener `ParaclinicalResultsReadyEvent` → huy hiệu "Có kết quả" và làm mới hàng đợi trên `/topic/doctor/{doctorId}`.
- [ ] **5.1.5** Listener `VisitCompletedEvent`, `MedicineInvoicePaidEvent` → gửi phiếu thu / hóa đơn thuốc điện tử; `MedicineLowStockEvent` → cảnh báo `/topic/admin`.

> **Hướng dẫn Kiểm thử Task 5.1:**
> 1. Kết nối WebSocket `ws://localhost:8080/ws`, subscribe `/topic/doctor/2`.
> 2. Hoàn tất dịch vụ cận lâm sàng cuối cùng của ca #1 (Task 3.6).
> 3. **Kết quả kỳ vọng:** nhận ngay payload: *"Ca khám VISIT-2026-0001 của thú cưng Lu đã có đủ kết quả cận lâm sàng!"*.

---

### Task 5.2: Khởi tạo Khung Giao diện Frontend React (Vite + TailwindCSS)
- **Người thực hiện:** Vũ Hồng Linh
- **Mục tiêu:** Dựng SPA, Axios Interceptor tự gắn JWT và tự refresh khi nhận `401`; Route Guards theo 6 vai trò (NFR-03, NFR-05).
- [ ] **5.2.1** Khởi tạo `frontend/` bằng Vite (React 18 + TypeScript + TailwindCSS / Ant Design).
- [ ] **5.2.2** Axios: Request Interceptor gắn `Authorization: Bearer <accessToken>`; Response Interceptor gặp `401` thì gọi `POST /api/v1/auth/refresh` một lần rồi retry; gặp `403` thì hiển thị "Không đủ quyền", **không** refresh.
- [ ] **5.2.3** Route Guards:
  - Chưa đăng nhập: trang chủ, bảng giá dịch vụ, tra cứu khung giờ trống, đăng nhập / đăng ký.
  - `PET_OWNER`: thú cưng của tôi, đặt lịch, lịch hẹn, bệnh án, đơn thuốc (in để mua ngoài).
  - `RECEPTIONIST`: tiếp đón, xếp ca vào hàng đợi riêng của Bác sĩ, thu tiền hóa đơn dịch vụ, công nợ, bán thuốc theo đơn.
  - `VETERINARIAN`: màn hình khám 2 pha, ca chờ tái khám / đã hoãn, kê đơn.
  - `LAB_TECHNICIAN` / `IMAGING_TECHNICIAN`: hàng đợi và nhập kết quả phòng mình.
  - `ADMIN`: tài khoản, danh mục, kho, báo cáo doanh thu (2 nguồn) & công nợ.

> **Hướng dẫn Kiểm thử Task 5.2:**
> 1. `npm run dev`; đăng nhập Bác sĩ: menu chỉ có chức năng y tế.
> 2. Đăng nhập Khách hàng, vào URL `/reception/queue` → bị chặn kèm thông báo không đủ quyền.
> 3. Đợi Access Token hết hạn (hoặc sửa TTL ngắn khi test) → request tiếp theo tự refresh và thành công.

---

### Task 5.3: Hoàn thiện Các Màn hình Nghiệp vụ Frontend
- **Người thực hiện:** Vũ Hồng Linh
- **Mục tiêu:** Hiện thực hóa bản vẽ Figma, gắn API Backend qua Gateway :8080.
- [ ] **5.3.1** Cổng Đặt lịch (Customer Portal): chọn ngày → tải khung giờ trống → chọn thú cưng → nhập triệu chứng → nhận mã hẹn.
- [ ] **5.3.2** Tiếp đón Lễ tân: lịch hẹn trong ngày, nút Check-in một chạm (chọn Bác sĩ theo gợi ý), tiếp nhận vãng lai, **bảng điều phối**: danh sách chờ phân công + một cột hàng đợi cho mỗi Bác sĩ (trạng thái, số người chờ, số lần bị lùi), nút Xếp / Chuyển / Gỡ phân công luôn dùng được.
- [ ] **5.3.3** Bệnh án Bác sĩ 2 Pha: GĐ 1 (sinh hiệu, ghi chú, dịch vụ tại phòng, chỉ định CLS) → kết quả Lab / CĐHA tô màu Vàng / Xanh / Đỏ → đơn thuốc (cảnh báo tồn kho) → chốt ca; màn hình hàng đợi của Bác sĩ với nút "Gọi số tiếp theo" / "Đẩy lùi 1 bậc"; nút mở lại hồ sơ.
- [ ] **5.3.4** Hàng đợi Cận lâm sàng: "Gọi số tiếp theo", "Đẩy lùi 1 bậc" (hiển thị số lần bị lùi), bắt đầu, "Đã lấy mẫu", form nhập chỉ số theo gói, form CĐHA multipart, huy hiệu liên phòng.
- [ ] **5.3.5** Thu ngân: bảng kê hóa đơn dịch vụ (giảm giá từng hóa đơn, xác nhận thanh toán, in phiếu thu, thu công nợ) và màn hình **Bán thuốc theo đơn** (chọn thuốc / số lượng khách mua, hóa đơn thuốc, xác nhận thanh toán & xuất thuốc, in đơn cho khách mua ngoài).

> **Hướng dẫn Kiểm thử Task 5.3:**
> 1. Thao tác trọn vẹn luồng Đặt lịch → Tiếp đón → Khám → Thanh toán dịch vụ → (tùy chọn) Mua thuốc trên giao diện.
> 2. **Kết quả kỳ vọng:** Toast thông báo rõ ràng, không lỗi console JS.

---

### Task 5.4: Kiểm thử Tích hợp Luồng Chuẩn (Happy Path E2E Test)
- **Người thực hiện:** Cả nhóm (Hiển, Khởi, Linh)
- **Mục tiêu:** Kiểm thử xuyên suốt một ca khám thực tế từ A đến Z với dữ liệu demo.
- [ ] **5.4.1** Bước 1: Chủ nuôi `khach_lan` đặt lịch cho mèo Lu lúc 09:00 ngày khám trên Web Portal → `PENDING`.
- [ ] **5.4.2** Bước 2: Lễ tân duyệt lịch → `CONFIRMED`.
- [ ] **5.4.3** Bước 3: Đúng ngày, Lễ tân bấm Check-in (không cân đo) → ca `WAITING`; lịch hẹn tự chuyển `CHECKED_IN` qua sự kiện.
- [ ] **5.4.4** Bước 4: Lễ tân xếp ca vào hàng đợi Bác sĩ Tiến (P101, gợi ý vì đang 0 người chờ) → Bác sĩ Tiến bấm "Gọi số tiếp theo", màn hình sảnh gọi mèo Lu.
- [ ] **5.4.5** Bước 5: Bác sĩ bấm "Bắt đầu khám" (hệ thống tạo hóa đơn phí khám 100.000), cân 4,6 kg, đo 39,2°C, chỉ định CBC + X-quang (2 hóa đơn 250.000 và 180.000) → ca `WAITING_RESULTS`, Bác sĩ `AVAILABLE`.
- [ ] **5.4.6** Bước 6: KTV Lab lấy mẫu, bấm "Đã lấy mẫu", nhập 4 chỉ số → KTV CĐHA chụp X-quang, nhập kết luận và tải ảnh.
- [ ] **5.4.7** Bước 7: Ca `RESULTS_READY`, tự lên đầu hàng đợi Bác sĩ Tiến → Bác sĩ "Gọi số tiếp theo", bấm "Bắt đầu GĐ 2", kê 10 viên Clavamox, chốt chuyên môn → `WAITING_PAYMENT`.
- [ ] **5.4.8** Bước 8: Thu ngân xác nhận thanh toán **3 hóa đơn dịch vụ, tổng 530.000đ** → 3 hóa đơn `PAID`, **ca khám `COMPLETED` ngay**, dữ liệu vào lịch sử bệnh án.
- [ ] **5.4.9** Bước 9 (tùy chọn): Khách chọn mua thuốc tại phòng khám → hóa đơn thuốc **157.500đ** (10 × 15.000 × 1,05) → xác nhận thanh toán & xuất thuốc → hóa đơn thuốc `PAID`, tồn kho Clavamox 200 → 190, có dòng `EXPORT_SALE -10`. *(Biến thể: khách mua ngoài → in đơn thuốc, không có hóa đơn thuốc, kho không đổi, ca vẫn `COMPLETED`.)*

> **Hướng dẫn Kiểm thử Task 5.4:**
> 1. Thực hiện 9 bước trên trình duyệt, đối chiếu CSDL sau mỗi bước.
> 2. **Kết quả kỳ vọng:** không lỗi 500; doanh thu dịch vụ hôm đó (`v_service_invoice_amounts`, `PAID`) = 530.000; doanh thu thuốc (`v_medicine_invoice_amounts`, `PAID`) = 157.500 (hoặc 0 ở biến thể mua ngoài).

---

### Task 5.5: Bộ Kịch bản Kiểm thử 16 Tình huống Ngoại lệ (EX-01 → EX-16)
- **Người thực hiện:** Cả nhóm (Hiển, Khởi, Linh)
- **Mục tiêu:** Chứng minh hệ thống xử lý đúng mọi ngoại lệ theo `TONG_HOP_NGOAI_LE_VA_XU_LY_HE_THONG.md` v3.0.
- [ ] **5.5.1 [EX-01]** Lịch `CONFIRMED` quá `start_time + 30'` chưa check-in → tự chuyển `NO_SHOW`, lịch sử `changed_by_user_id = NULL`, khung giờ được giải phóng.
- [ ] **5.5.2 [EX-02]** Khách vãng lai → check-in với `appointmentId = null`, ca `WAITING`.
- [ ] **5.5.3 [EX-03]** Khách bỏ về khi đang chờ → `CANCELLED`, lý do trong `pet_visit_status_histories.notes`; ca rời khỏi hàng đợi Bác sĩ, người phía sau lên một bậc.
- [ ] **5.5.4 [EX-04]** Ca cấp cứu → `is_emergency = true`, lên đầu danh sách chờ phân công, đầu hàng đợi Bác sĩ và hàng đợi Lab / CĐHA; đẩy lùi một lần thì xếp như ca thường.
- [ ] **5.5.5 [EX-05]** Xếp ca mới vào hàng đợi Bác sĩ đang có ca vừa có kết quả → `200 OK`, ca có kết quả vẫn đứng đầu và được gọi trước.
- [ ] **5.5.6 [EX-06]** Vắng mặt khi gọi vào Lab / CĐHA → `skip`, dịch vụ giữ `PENDING`, `action = SKIPPED`, đứng sau người kế tiếp, thông báo ứng dụng (không SMS).
- [ ] **5.5.7 [EX-07]** Khách quay lại sau khi bị lùi → không cần thao tác; đến lượt `call-next` gọi đúng dịch vụ đó, sau đó `start` → `IN_PROGRESS`.
- [ ] **5.5.8 [EX-08]** Hủy 1 dịch vụ CLS → dịch vụ và **hóa đơn của nó `CANCELLED`**; dịch vụ còn lại xong → ca `RESULTS_READY`.
- [ ] **5.5.9 [EX-09]** CĐHA gọi khi Lab chưa bấm "Đã lấy mẫu" → huy hiệu `SAMPLING`; CĐHA `skip`, gọi người kế tiếp.
- [ ] **5.5.10 [EX-10]** Bác sĩ gọi số (ca `WAITING` hoặc `RESULTS_READY`) nhưng khách vắng → `skip`, ca giữ trạng thái, đứng sau người kế tiếp, Bác sĩ vẫn `AVAILABLE`.
- [ ] **5.5.11 [EX-11]** Khách bỏ về (ở `WAITING_RESULTS` hoặc `RESULTS_READY`) → `abandon`: dịch vụ chưa làm hủy kèm hóa đơn, hóa đơn dịch vụ đã làm giữ `PENDING` (công nợ), ca `COMPLETED`; lần sau thu được qua Task 3.9.
- [ ] **5.5.12 [EX-12]** Chốt ca khi thiếu chẩn đoán → `400 CLIN_1307`.
- [ ] **5.5.13 [EX-13]** Kê vượt tồn kho → lưu đơn thành công kèm `stockWarnings` (không chặn).
- [ ] **5.5.14 [EX-14]** Giảm giá vượt số tiền của một hóa đơn (dịch vụ hoặc thuốc) → `400 BILL_1402`.
- [ ] **5.5.15 [EX-15]** Thiếu kho đúng lúc xác nhận bán thuốc → `409 PHARM_1406`, rollback toàn bộ, hóa đơn thuốc giữ `PENDING`, tồn kho không đổi; Thu ngân sửa hóa đơn (giảm số lượng) rồi xác nhận lại thành công, hoặc hủy để khách mua ngoài.
- [ ] **5.5.16 [EX-16]** Bán trùng: lập hóa đơn thứ hai cho cùng đơn → `409 PHARM_1407`; xác nhận lại hóa đơn đã `PAID` → `409 BILL_1403`; bấm đúp đồng thời → một lần thành công, lần kia `409 SYS_1005`.

> **Hướng dẫn Kiểm thử Task 5.5:**
> 1. Chạy từng kịch bản theo [TONG_HOP_NGOAI_LE_VA_XU_LY_HE_THONG.md](TONG_HOP_NGOAI_LE_VA_XU_LY_HE_THONG.md).
> 2. **Kết quả kỳ vọng:** 16/16 tình huống được phát hiện và xử lý đúng mã lỗi, ghi lịch sử đầy đủ, dữ liệu tiền và kho toàn vẹn.

---

## BẢNG MA TRẬN PHÂN CÔNG & TIẾN ĐỘ THỰC THI (TASK TRACKING MATRIX)

| Mã Task | Tên Nhiệm vụ trọng tâm | Thành viên chính | FR / Ngoại lệ liên quan | Tình trạng |
| :---: | :--- | :---: | :---: | :---: |
| **T1.1 - T1.3** | Multi-Module, Docker Compose, CSDL 25 bảng + dữ liệu demo, Common-Library (Auto-Configuration) | Hiển, Khởi | NFR-07, NFR-08 | `[ ] Chưa xong` |
| **T1.4 - T1.5** | Service Registry (Eureka :8761) & API Gateway (:8080, trả 401) | Khởi | NFR-02, NFR-03 | `[ ] Chưa xong` |
| **T2.1 - T2.4** | `auth-service` (:8081): BCrypt, JWT, Refresh Token Rotation, nhân sự & phòng | Khởi | FR-01, FR-02, FR-09, NFR-02, NFR-03 | `[ ] Chưa xong` |
| **T2.5 - T2.8** | `appointment-service` (:8082): Slot động, Đặt / duyệt / hủy lịch, No-Show | Hiển | FR-12 → FR-17, EX-01 | `[ ] Chưa xong` |
| **T3.1 - T3.3** | `clinical-service` (:8083): Danh mục, Thú cưng, Check-in, Hàng đợi riêng từng Bác sĩ (xếp ca, gọi số, đẩy lùi), Bắt đầu khám | Khởi, Hiển | FR-03, FR-05 → FR-08, FR-10, FR-11, FR-18 → FR-29, EX-02 → EX-05 | `[ ] Chưa xong` |
| **T3.4 - T3.8** | `clinical-service`: Chỉ định + hóa đơn dịch vụ, CLS song song (gọi số, đẩy lùi), GĐ 2 | Hiển, Khởi | FR-30 → FR-50, FR-54, EX-06 → EX-12 | `[ ] Chưa xong` |
| **T3.9** | `clinical-service`: Thu tiền hóa đơn dịch vụ & hoàn tất ca khám | Hiển | FR-55 → FR-60, EX-11, EX-14 | `[ ] Chưa xong` |
| **T4.1 - T4.4** | `billing-pharmacy-service` (:8084): Kê đơn, Hóa đơn thuốc, Trừ kho nguyên tử, Nhập kho | Hiển | FR-04, FR-51 → FR-53, FR-61 → FR-66, EX-13 → EX-16 | `[ ] Chưa xong` |
| **T5.1** | `notification-service` (:8085): WebSocket STOMP & Email theo 9 sự kiện | Khởi | Thông báo cho FR-12 → FR-60 | `[ ] Chưa xong` |
| **T5.2 - T5.3** | Frontend React Vite: phân quyền 6 vai trò, ghép nối API | Linh | FR-67 → FR-70, NFR-01, NFR-05 | `[ ] Chưa xong` |
| **T5.4 - T5.5** | Kiểm thử E2E Happy Path & 16 ngoại lệ | Cả nhóm | Toàn bộ hệ thống, NFR-04, NFR-06 | `[ ] Chưa xong` |

---

## HƯỚNG DẪN CÁCH SỬ DỤNG FILE NÀY TRONG QUÁ TRÌNH LẬP TRÌNH

1. **Trước khi bắt đầu một Task:** Đọc kỹ mô tả, endpoints cần tạo, đối chiếu tên với Quy chuẩn mục 3.2 và Kiến trúc mục 5.
2. **Sau khi viết mã nguồn xong:** Thực hiện đúng các bước trong phần **"Hướng dẫn Kiểm thử"** của task đó, trên dữ liệu demo Task 1.2.3.
3. **Khi kiểm thử thành công:** Đổi `[ ]` thành `[x]` (ví dụ: `- [x] **1.1.1** Khởi tạo Git repository...`).
4. **Nếu gặp lỗi:** Tra bảng mã lỗi tại [QUY_CHUAN_THIET_KE_VA_LAP_TRINH_BACKEND_SPRINGBOOT.md](QUY_CHUAN_THIET_KE_VA_LAP_TRINH_BACKEND_SPRINGBOOT.md) (mục 5.1) và các ngoại lệ tại [TONG_HOP_NGOAI_LE_VA_XU_LY_HE_THONG.md](TONG_HOP_NGOAI_LE_VA_XU_LY_HE_THONG.md) để khắc phục trước khi chuyển task kế tiếp.

---

## PHỤ LỤC: THAY ĐỔI SO VỚI PHIÊN BẢN TRƯỚC

| Vị trí | Bản cũ | Bản 3.0 | Lý do |
| :--- | :--- | :--- | :--- |
| Đầu tài liệu, 1.1 | Spring Boot "4.1.11" | Spring Boot 4.1.1, Spring Cloud 2025.1.2 | Không có bản 4.1.11 |
| 1.2, ma trận | 23 bảng, "20 khóa ngoại", clinical 12 bảng | 25 bảng, 25 khóa ngoại nội bộ, 2 VIEW, clinical 14 bảng | Lược đồ v3.0 (đếm từ `schema_init.sql`) |
| 1.2.3 (mới) | Test dùng `bs_tien`, id 2, 4, 5, 7, 8 không có trong seed | Thêm `seed_demo_data.sql` với bảng ID cố định | `schema_init.sql` chỉ có tài khoản admin |
| 1.3 | ApiResponse `{code: 1000}`, `error()`; 30 mã lỗi; 13 enum | Đúng cấu trúc Quy chuẩn; 39 mã lỗi chuỗi; 10 enum + `LabEvaluation`; Auto-Configuration | Khớp Quy chuẩn v3.0 |
| 1.5, 2.3 | Gateway không trả 401; `/refresh-token` | Gateway trả 401, chặn `/internal/**`; `/refresh` | Khớp Quy chuẩn 10.1, 10.3 |
| 2.4, 2.6 | `/api/v1/internal/...` qua Gateway; `/available-slots`; đếm slot thiếu `CHECKED_IN` | `/internal/**` gọi trực tiếp cổng service; `/slots`; đếm cả `CHECKED_IN` | Endpoint nội bộ không ra ngoài; lịch đã check-in vẫn chiếm chỗ |
| 2.5, 2.7 | Entity 17 trường có `owner_id`; body có `endTime`; `cancel_reason` | 9 trường, không `owner_id`, `end_time`; lý do hủy ở bảng lịch sử | Lược đồ v3.0 |
| 2.8 | `end_time + 30m` | `appointment_date + start_time + 30'` | Khớp EX-01, FR-17 |
| 3.1 | Tra thú cưng qua `owner_id` như số điện thoại | `ownerId` + tra số điện thoại ở auth-service | Số điện thoại nằm ở `users` |
| 3.2 | Check-in nhận `weight`, `temperature`; gọi Feign ghi `CHECKED_IN` | Không cân đo; `VisitCheckedInEvent`; chặn ca mở | Bác sĩ cân đo; Feign chỉ đọc |
| 3.3 | Không có endpoint phân công; start-exam gán `doctor_id`, `started_at` | Thêm `assign-doctor`; start-exam kiểm tra Bác sĩ được gán, tạo dịch vụ khám + hóa đơn | Bổ sung chức năng thiếu; State Machine T02 |
| 3.4 | Snapshot `unit_price` vào `visit_service_details`; `ServicesPrescribedEvent` | Mỗi chỉ định sinh `service_invoices`; dịch vụ tại phòng; hủy dịch vụ kéo theo hóa đơn | Hóa đơn riêng cho từng dịch vụ |
| 3.5 | Gán cột `evaluation`; `reference_range_snapshot` | Nhãn tính khi hiển thị; `min/max_value_snapshot`; thêm "Đã lấy mẫu" | Bỏ cột dẫn xuất; EX-09 |
| 3.6 | Upload ảnh trước khi có `imaging_results` | Một request multipart: kết quả trước, tệp đính kèm sau | Đúng thứ tự khóa ngoại |
| 3.8 | `closed_at`; `ClinicalCompletedEvent` sang billing | Ghi lịch sử; thêm call-in, postpone, abandon, reopen | Lược đồ và State Machine v3.0 |
| 3.9 (mới), 4.1 → 4.4 | `invoices`, `invoice_items`, `PRESCRIBED`, `DISPENSED`, `balance_after`, `EXPORT_PRESCRIPTION`, `pay-and-dispense` | Thanh toán hóa đơn dịch vụ ở clinical; bán thuốc (hóa đơn thuốc + trừ kho) ở billing-pharmacy | Mua thuốc tùy chọn |
| 4.2 | `dosageInstructions`; chặn kê vượt kho | `dosage`, `frequency`, `durationDays` bắt buộc; chỉ cảnh báo | Cột NOT NULL; EX-13 v3.0 |
| 5.1 | `ServicesCompletedEvent`… | 9 sự kiện chuẩn Kiến trúc mục 5.2 | Thống nhất tên |
| 5.4, 5.5 | 440.000đ, `DISPENSED`, hoàn tất sau khi xuất thuốc | 530.000đ dịch vụ → `COMPLETED`; thuốc 157.500đ tùy chọn | Giá theo seed; luồng mới |
| Ma trận | FR trích dẫn lệch tài liệu FR (FR-26 → FR-46 cho tasks khác nghĩa) | Theo đúng FR v3.0 | Đồng bộ truy vết |
| 2.6 (rà soát 10/11) | "14 khung giờ 08:00, 08:30, …, 16:30" (giống liên tục) | 08:00 → 11:00 và 13:30 → 16:30, nghỉ trưa | Khớp Mô tả nghiệp vụ mục 5 |
| 3.2, 3.3 (rà soát 10/11) | Test dùng ca thú cưng #2 nhưng không có bước check-in; curl gửi `weight` | Thêm bước check-in Milo; curl gửi `weightAtVisit`; thêm API gỡ phân công (3.3.2b) | Lệnh test chạy được đúng thứ tự; sai tên trường làm Task 3.4 lỗi `CLIN_1308` |
| 3.4.5, 3.9.3, 4.2.1 (rà soát 10/11) | Hủy ca không xét dịch vụ tại phòng; mã lỗi hóa đơn hủy; sửa đơn sau mở lại | Guard T11; `BILL_1401` / `BILL_1408`; chặn sửa đơn khi có hóa đơn thuốc chưa hủy | Đồng bộ State Machine và Quy chuẩn |
| 4.3.4 (mới), 4.4, 5.5.15 (rà soát 10/11) | Không có API sửa hóa đơn thuốc; test EX-15 sửa trực tiếp `stock_quantity` | Thêm `PUT …/medicine-invoices/{id}/items`; test dùng `ADJUSTMENT` rồi sửa hóa đơn và xác nhận lại | EX-15 thực hiện được; giữ bất biến kho |
| 3.2, 3.3, 3.5, 3.7, 3.8, 5.1, 5.3, 5.4, 5.5 (rà soát 11/11) | Hàng đợi sảnh chung; phân công chỉ cho Bác sĩ `AVAILABLE` (`CLIN_1302` / `CLIN_1303`); CLS `postpone` / `recall`; GĐ 2 `call-in`, `postpone-callback`; Khóa ưu tiên | `GET …/queue` (danh sách chờ + hàng đợi từng Bác sĩ), `…/my-queue`; `assign-doctor` không kiểm tra Bác sĩ rảnh; thêm `call-next`, `skip` (Bác sĩ) và `lab-queue/call-next`, `imaging-queue/call-next`, `service-details/{id}/skip`; `start-phase2`; test 3.3, 3.7, 3.8 và EX-03 → EX-10 viết lại | Mô hình hàng đợi riêng từng Bác sĩ + Đẩy lùi 1 bậc |
