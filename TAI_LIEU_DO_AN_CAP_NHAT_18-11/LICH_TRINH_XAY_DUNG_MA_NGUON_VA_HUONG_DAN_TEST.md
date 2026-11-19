# LỊCH TRÌNH CHI TIẾT XÂY DỰNG MÃ NGUỒN & HƯỚNG DẪN KIỂM THỬ HỆ THỐNG
## HỆ THỐNG QUẢN LÝ PHÒNG KHÁM THÚ Y (MICROSERVICES ARCHITECTURE)
### NỀN TẢNG: JAVA 21 LTS | SPRING BOOT 4.1.1 | SPRING CLOUD 2025.1.2 | MYSQL 8.0 | REACT VITE
### PHIÊN BẢN 4.0 (18/11/2026) – đồng bộ lược đồ CSDL v4.0, Kiến trúc v4.0 và Quy chuẩn Backend v4.0

> **Mục đích tài liệu:**  
> - Bản lộ trình hành động (Actionable Implementation Roadmap) chia nhỏ toàn bộ quá trình lập trình thành các nhiệm vụ cụ thể (Tasks) đi kèm hộp kiểm `[ ]` để đánh dấu tiến độ thực tế.  
> - Bao phủ **70 Yêu cầu chức năng (FR-01 → FR-70)**, **10 Yêu cầu phi chức năng (NFR-01 → NFR-10)**, **20 Tình huống ngoại lệ (EX-01 → EX-20)** và **52 bảng Cơ sở dữ liệu** (5 CSDL logic + Redis, 40 khóa ngoại nội bộ, 4 VIEW). Mã FR trích dẫn theo đúng `YEU_CAU_CHUC_NANG_VA_PHI_CHUC_NANG.md` v4.0.
> - **Thay đổi v4.0 (nhận xét chi tiết của GVHD):** khóa UUIDv7; hồ sơ người dùng theo loại; bảng giá dịch vụ / thuốc có lịch sử; đợt khám tách `pet_visits` / `vital_signs` / `medical_records`; hàng đợi trên **Redis** (MySQL chỉ lưu `queue_ticket_histories`); đơn thuốc ở `clinical-service`, chốt ca → `PrescriptionCreatedEvent` → **hóa đơn thuốc nháp**; **Transactional Outbox** + consumer idempotent; **`reporting-service`** (Task 4.5); 4 ngoại lệ phân tán EX-17 → EX-20 (Task 5.5).  
> - Cung cấp **hướng dẫn kiểm thử sau từng task** (câu lệnh `curl`, dữ liệu mẫu JSON, mã lỗi kỳ vọng, truy vấn SQL xác minh và kiểm tra sự kiện).
>
> **Quy ước dùng chung:**
> - Tên endpoint, sự kiện RabbitMQ (exchange `clinic.events`) và mã lỗi theo đúng `THIET_KE_KIEN_TRUC_MICROSERVICES.md` (mục 5) và `QUY_CHUAN_THIET_KE_VA_LAP_TRINH_BACKEND_SPRINGBOOT.md` (mục 3.2, 5.1, 9.2).
> - Các lệnh `curl` qua Gateway dùng biến `$TOKEN_<VAI_TRÒ>` lấy từ API đăng nhập (Task 2.2). Endpoint `/internal/**` chỉ gọi trực tiếp cổng service, Gateway chặn tiền tố này.
> - **Khóa là UUID (v4.0):** ID trong ví dụ được viết dạng biến shell: tài khoản / thú cưng demo có UUID cố định (`$U_TIEN`, `$PET_LU`... – Task 1.2.3); dịch vụ / thuốc dùng UUID seed trong `schema_init.sql` (`$S_EXAM`, `$S_CBC`, `$S_XRAY`, `$S_DEWORM`, `$M_AMOX` ứng với biến `@s_exam`, `@s_cbc`, `@s_xray`, `@s_deworm`, `@m_amox`); bản ghi sinh ra khi chạy kịch bản (`$VISIT_1`, `$INV_1`, `$DETAIL_3`, `$TICKET_1`...) lấy từ phản hồi API, ví dụ `VISIT_1=$(curl ... | jq -r .data.id)`. Số thứ tự trong tên biến là thứ tự tạo trong kịch bản; "phiếu số N" là số in trên phiếu (`ticketNo`).
> - **Kiểm tra hàng đợi (v4.0):** phiếu đang chờ / đang phục vụ xem bằng API hàng đợi hoặc `redis-cli` (`ZRANGE queue:{yyyyMMdd}:DOCTOR:{doctorId} 0 -1 WITHSCORES`, `HGETALL ticket:{id}`); phiếu đã kết thúc xem bằng `SELECT ... FROM queue_ticket_histories`. Sau thao tác thu tiền, chờ ~1 giây để sự kiện outbox được xử lý.

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
│ PHA 4: Kê đơn (clinical), Hóa đơn thuốc nháp & Trừ kho (billing :8084), Báo cáo (reporting :8086)│
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
- [ ] **1.1.2** Tạo tệp `pom.xml` gốc khai báo 9 modules con: `common-library`, `service-registry`, `api-gateway`, `auth-service`, `appointment-service`, `clinical-service`, `billing-pharmacy-service`, `notification-service`, `reporting-service`.
- [ ] **1.1.3** Khởi tạo khung thư mục `src/main/java` và `src/main/resources` cho từng module.

> **Hướng dẫn Kiểm thử Task 1.1:**
> 1. Mở terminal tại thư mục gốc dự án: `mvn clean compile`
> 2. **Kết quả kỳ vọng:** Build thành công cả 9 modules (`BUILD SUCCESS`). Nếu dùng Spring Cloud cũ hơn 2025.1.2, ứng dụng sẽ báo lỗi `Spring Boot [4.1.x] is not compatible with this Spring Cloud release train` khi khởi động.

---

### Task 1.2: Thiết lập Hạ tầng MySQL, Redis, RabbitMQ & Dữ liệu demo (Docker Compose)
- **Người thực hiện:** Nguyễn Đức Khởi
- **Mục tiêu:** Dựng MySQL (5 CSDL logic), Redis (hàng đợi) và RabbitMQ bằng Docker, nạp lược đồ v4.0 (52 bảng) và dữ liệu demo dùng cho mọi hướng dẫn kiểm thử.
- [ ] **1.2.1** Viết tệp `docker-compose.yml` khởi chạy:
  - MySQL 8.0 Server (Port 3306), `utf8mb4_unicode_ci`; khởi tạo 5 CSDL: `pet_clinic_auth_db`, `pet_clinic_appointment_db`, `pet_clinic_clinical_db`, `pet_clinic_billing_pharmacy_db`, `pet_clinic_reporting_db`.
  - **Redis 7** (`redis:7-alpine`, Port 6379, `--appendonly yes --appendfsync everysec`, volume `redis-data`) – chỉ `clinical-service` kết nối.
  - RabbitMQ Server với Management Plugin (Port 5672 và 15672).
  - Volume `imaging-uploads` gắn vào `clinical-service` tại `/app/uploads/imaging/` (CSDL chỉ lưu `file_key`).
- [ ] **1.2.2** Thực thi `schema_init.sql` v4.0: **52 bảng** (auth 9, appointment 4, clinical 24, billing-pharmacy 10, reporting 5), **40 khóa ngoại nội bộ** (auth 7, appointment 1, clinical 24, billing-pharmacy 8, reporting 0), **4 VIEW** (`v_service_invoice_amounts`, `v_current_service_prices`, `v_medicine_invoice_amounts`, `v_current_medicine_prices`) và dữ liệu danh mục (6 vai trò, 1 admin kèm hồ sơ, 2 loài, 9 nhóm dịch vụ, 7 dịch vụ + 7 dòng giá, 4 chỉ số xét nghiệm, 4 nhóm thuốc, 4 thuốc + thành phần + giá + tồn kho, nhập kho đầu kỳ). Khóa thực thể là UUIDv7 `BINARY(16)`; seed dùng UUID cố định (biến `@u_admin`, `@s_exam`...).
- [ ] **1.2.3** Viết `seed_demo_data.sql` (chỉ dev/demo, chạy sau `schema_init.sql`): tài khoản, hồ sơ, thú cưng mẫu với **UUID cố định** để tài liệu kiểm thử tham chiếu được. Bảng tài khoản demo:

  | Biến trong tài liệu | Tài khoản | Vai trò | Phòng | Ghi chú |
  | :--- | :--- | :--- | :---: | :--- |
  | `$U_ADMIN` | `admin` | ADMIN | – | Có sẵn trong `schema_init.sql` (`019a9442-d800-7729-87cc-fbb1ceda8817`) |
  | `$U_TIEN` | `bs_tien` | VETERINARIAN | P101 | Bác sĩ Nguyễn Văn Tiến – có `veterinarian_profiles` (CCHN-HN-0102) |
  | `$U_AN` | `bs_an` | VETERINARIAN | P102 | Bác sĩ Trần Bình An |
  | `$U_MAI` | `bs_mai` | VETERINARIAN | P103 | Bác sĩ Lê Thị Mai |
  | `$U_HOA` | `letan_hoa` | RECEPTIONIST | – | Lễ tân / Thu ngân |
  | `$U_MINH` | `ktv_lab_minh` | LAB_TECHNICIAN | P201 | Phòng Xét nghiệm |
  | `$U_DUNG` | `ktv_cdha_dung` | IMAGING_TECHNICIAN | P202 | Phòng CĐHA |
  | `$U_LAN` | `khach_lan` | PET_OWNER | – | Chủ của thú cưng `$PET_LU` "Lu" (Mèo) và `$PET_MILO` "Milo" (Chó) |

  ```sql
  USE pet_clinic_auth_db;
  SET @u_tien = UUID_TO_BIN('019a9442-d810-7000-8000-000000000002');   -- tương tự cho các tài khoản còn lại
  INSERT INTO users (id, username, password_hash, status) VALUES (@u_tien, 'bs_tien', '<bcrypt>', 'ACTIVE');
  INSERT INTO user_roles (user_id, role_id) SELECT @u_tien, id FROM roles WHERE code = 'VETERINARIAN';
  INSERT INTO user_profiles (user_id, full_name, phone_number) VALUES (@u_tien, 'Nguyễn Văn Tiến', '0902000002');
  INSERT INTO staff_profiles (user_id, employee_code, position_title, department, room_number, hire_date)
  VALUES (@u_tien, 'NV0002', 'Bác sĩ thú y', 'Khám bệnh', 'P101', '2026-01-05');
  INSERT INTO veterinarian_profiles (user_id, license_number, license_issued_date, license_issued_by, academic_degree, specialty, career_start_year)
  VALUES (@u_tien, 'CCHN-HN-0102', '2020-06-01', 'Chi cục Chăn nuôi và Thú y Hà Nội', 'Bác sĩ thú y', 'Nội khoa', 2019);
  -- khach_lan: users + user_roles (PET_OWNER) + user_profiles + pet_owner_profiles (KH0001, AT_CLINIC)

  USE pet_clinic_clinical_db;
  INSERT INTO pets (id, owner_id, owner_name_snapshot, owner_phone_snapshot, species_id, pet_code, name, breed, gender)
  SELECT UUID_TO_BIN('019a9442-d820-7000-8000-000000000001'), UUID_TO_BIN('019a9442-d810-7000-8000-000000000008'),
         'Hoàng Thị Lan', '0912000008', id, 'PET-2026-0001', 'Lu', 'Mèo Anh lông ngắn', 'FEMALE' FROM species WHERE code = 'CAT';
  -- Milo (Chó, Poodle) tương tự
  ```

> **Hướng dẫn Kiểm thử Task 1.2:**
> 1. `docker compose up -d`; mở `http://localhost:15672` (`guest/guest`); `docker exec -it redis redis-cli CONFIG GET appendonly` → `yes`.
> 2. Kiểm tra số bảng, khóa ngoại và VIEW:
>    ```sql
>    SELECT table_schema, SUM(table_type = 'BASE TABLE') AS tables, SUM(table_type = 'VIEW') AS views
>    FROM information_schema.tables WHERE table_schema LIKE 'pet_clinic_%' GROUP BY table_schema;
>    SELECT COUNT(*) AS fk_count FROM information_schema.referential_constraints WHERE constraint_schema LIKE 'pet_clinic_%';
>    SELECT COUNT(*) FROM information_schema.columns WHERE table_schema LIKE 'pet_clinic_%' AND data_type = 'enum';
>    ```
> 3. **Kết quả kỳ vọng:**
>    - auth 9 · appointment 4 · clinical 24 + 2 VIEW · billing-pharmacy 10 + 2 VIEW · reporting 5 → **52 bảng, 4 VIEW**; `fk_count = 40`; **0 cột kiểu ENUM**.
>    - Bất biến kho: `SELECT s.medicine_id, s.quantity_on_hand, SUM(t.quantity) FROM medicine_stocks s JOIN inventory_transactions t ON t.medicine_id = s.medicine_id GROUP BY s.medicine_id;` → hai cột bằng nhau (200, 50, 40, 100).
>    - Giá đang áp dụng: `SELECT code, price FROM v_current_service_prices;` → 7 dịch vụ (EXAM_GEN 100000.00...).

---

### Task 1.3: Xây dựng Module Dùng chung (`common-library`)
- **Người thực hiện:** Lưu Minh Hiển
- **Mục tiêu:** Cung cấp bộ khung lớp dùng chung, nạp cấu hình servlet bằng Auto-Configuration có điều kiện (Quy chuẩn mục 2.2), và hạ tầng sự kiện dùng chung (Outbox, consumer idempotent).
- [ ] **1.3.1** Xây dựng `ApiResponse<T>` và `PageResponse<T>` (Quy chuẩn Chương 4).
- [ ] **1.3.2** Xây dựng `ErrorCode` (**49 mã lỗi** – Quy chuẩn 5.1 v4.0) và `AppException`.
- [ ] **1.3.3** Đặt `GlobalExceptionHandler`, `FeignExceptionHandler`, `CommonSecurityConfig`, `HeaderAuthenticationFilter` (đọc `X-User-Roles` nhiều vai trò), `FeignClientInterceptor`, `CustomFeignErrorDecoder` trong `com.vetclinic.common.web`; `CommonWebAutoConfiguration` (`@ConditionalOnWebApplication(SERVLET)`). `SecurityUtils.getCurrentUserId()` trả `UUID`.
- [ ] **1.3.4** Định nghĩa **18 enum Java lưu `VARCHAR`** + `LabEvaluation` theo `DANH_SACH_KIEU_ENUM_HE_THONG.md` v4.0 (vai trò, nhóm dịch vụ là bảng danh mục, không phải enum); `BaseEvent` (`eventId` UUIDv7, `occurredAt`) và **17 lớp sự kiện** theo Kiến trúc mục 5.2.
- [ ] **1.3.5** Hạ tầng sự kiện (Quy chuẩn 9.2): entity `OutboxEvent`, `OutboxWriter` (`Propagation.MANDATORY`), `OutboxRelay` (`@Scheduled(fixedDelay = 500)`, `FOR UPDATE SKIP LOCKED`, publisher confirm, thử lại lùi dần, `FAILED` sau 10 lần, dọn dòng `PUBLISHED` > 7 ngày); entity `ProcessedEvent` + `IdempotentConsumer`. Đóng gói thành phần JPA trong `com.vetclinic.common.outbox`, kích hoạt khi service có JPA.

> **Hướng dẫn Kiểm thử Task 1.3:**
> 1. Unit Test `ApiResponseTest`, `GlobalExceptionHandlerTest` (`AppException(ErrorCode.INVOICE_ALREADY_PAID)` → HTTP 409).
> 2. `OutboxRelayTest` (Testcontainers MySQL + RabbitMQ): ghi 3 dòng outbox trong một giao dịch rồi rollback → không dòng nào được gửi; ghi rồi commit → 3 tin nhắn đến queue test, 3 dòng `PUBLISHED`. Dừng RabbitMQ → dòng giữ `PENDING`, `attempt_count` tăng; bật lại → gửi đủ, đúng thứ tự.
> 3. `IdempotentConsumerTest`: gọi `run(sameEventId, "c1", action)` hai lần → `action` chạy đúng 1 lần.
> 4. Chạy: `mvn test -pl common-library` → passed.

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
- [ ] **1.5.2** Định tuyến: `/api/v1/auth/**`, `/api/v1/users/**`, `/api/v1/staff/**`, `/api/v1/roles/**` → `lb://auth-service`; `/api/v1/appointments/**` → `lb://appointment-service`; `/api/v1/clinical/**`, `/api/v1/pets/**`, `/api/v1/species/**`, `/api/v1/catalog/**` → `lb://clinical-service`; `/api/v1/pharmacy/**`, `/api/v1/billing/**` → `lb://billing-pharmacy-service`; `/api/v1/notifications/**`, `/ws/**` → `lb://notification-service`; `/api/v1/reports/**` → `lb://reporting-service`.
- [ ] **1.5.3** Viết `JwtAuthenticationFilter` (Quy chuẩn 10.1): xóa `X-User-*` từ client; route công khai (`/api/v1/auth/login`, `/refresh`, `/register`, `/api/v1/appointments/slots`) cho qua; route khác thiếu / sai / hết hạn token → **401 `SYS_1002`**; token hợp lệ → gắn `X-User-Id` (UUID), `X-User-Roles` (danh sách vai trò cách nhau dấu phẩy, **không có** tiền tố `ROLE_`); chặn `/internal/**` → 403.
- [ ] **1.5.4** Cấu hình CORS cho Frontend `http://localhost:5173`.

> **Hướng dẫn Kiểm thử Task 1.5:**
> 1. Gọi route cần đăng nhập mà không có token:
>    ```bash
>    curl -i http://localhost:8080/api/v1/clinical/pet-visits/queue
>    ```
>    **Kỳ vọng:** `401`, `"errorCode": "SYS_1002"` (không phải 403 – để Axios tự gọi refresh).
> 2. Gọi endpoint nội bộ qua Gateway: `curl -i http://localhost:8080/internal/users/$U_TIEN` → **Kỳ vọng:** `403`.
> 3. Giả mạo header: `curl -i -H "X-User-Roles: ADMIN" http://localhost:8080/api/v1/staff` (không token) → **Kỳ vọng:** `401`, header giả bị xóa.

---

## GIAI ĐOẠN 2: PHÂN HỆ XÁC THỰC, PHÂN QUYỀN & CỔNG ĐẶT LỊCH HẸN

### Task 2.1: Cấu hình Tầng Dữ liệu `auth-service` (:8081)
- **Người thực hiện:** Nguyễn Đức Khởi
- **Mục tiêu:** Kết nối `pet_clinic_auth_db`, thiết lập Entities và Repositories.
- [ ] **2.1.1** Khai báo kết nối MySQL trong `application.yml`, `ddl-auto: validate`.
- [ ] **2.1.2** Tạo Entities `Role` (`Short` id), `User` (`UUID` v7, `@ManyToMany` qua `user_roles`), `UserProfile`, `StaffProfile`, `VeterinarianProfile`, `PetOwnerProfile` (`@MapsId` 1–1), `RefreshToken` (`token_hash`), `OutboxEvent`, ánh xạ đúng cột trong `schema_init.sql`.
- [ ] **2.1.3** Tạo các Repository tương ứng; `UserRepository.findByUsername` nạp kèm vai trò.

> **Hướng dẫn Kiểm thử Task 2.1:**
> 1. Chạy `UserRepositoryTest`: `userRepository.findByUsername("bs_tien")`.
> 2. **Kết quả kỳ vọng:** Tải được tài khoản `$U_TIEN` với vai trò `VETERINARIAN`, `staffProfile.roomNumber = P101`, `veterinarianProfile.licenseNumber = CCHN-HN-0102`; không lỗi `SchemaManagementException`.

---

### Task 2.2: Đăng nhập, Đăng ký Khách hàng & Cấp phát JWT
- **Người thực hiện:** Nguyễn Đức Khởi (Phụ trách FR-09, NFR-02)
- **Mục tiêu:** Mã hóa BCrypt, xác thực đăng nhập, cấp Access Token (30 phút) + Refresh Token (7 ngày).
- [ ] **2.2.1** `AuthService.login()`: kiểm tra username / password, trạng thái `ACTIVE` (tài khoản `LOCKED` / `INACTIVE` → `401 AUTH_1107`).
- [ ] **2.2.2** Tạo Access Token chứa claims: `userId` (UUID), `username`, `roles` (**danh sách mã vai trò không tiền tố**, ví dụ `["VETERINARIAN"]`), `fullName` (từ `user_profiles`), `roomNumber` (từ `staff_profiles`, nếu có).
- [ ] **2.2.3** Sinh Refresh Token ngẫu nhiên, trả cho client; chỉ lưu **SHA-256** (`token_hash`) vào `refresh_tokens`.
- [ ] **2.2.4** API Đăng ký Khách hàng (`POST /api/v1/auth/register`) tạo `users` + `user_roles` (`PET_OWNER`) + `user_profiles` + `pet_owner_profiles` (`registration_channel = ONLINE`) trong một giao dịch; số điện thoại trùng → `AUTH_1102`.

> **Hướng dẫn Kiểm thử Task 2.2:**
> 1. Đăng nhập tài khoản Bác sĩ demo và lưu token:
>    ```bash
>    curl -X POST http://localhost:8080/api/v1/auth/login \
>      -H "Content-Type: application/json" \
>      -d '{"username": "bs_tien", "password": "<mật khẩu demo>"}'
>    ```
> 2. **Kết quả kỳ vọng:** `200 OK`, body có `accessToken` và `refreshToken`; giải mã JWT thấy `"roles": ["VETERINARIAN"]` (không có `ROLE_`).
> 3. Kiểm tra DB: `SELECT HEX(token_hash), revoked FROM pet_clinic_auth_db.refresh_tokens WHERE user_id = UUID_TO_BIN('$U_TIEN');` → có 1 bản ghi `revoked = 0`, không có token gốc trong CSDL.
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

### Task 2.4: Quản lý Nhân sự, Hồ sơ chuyên môn, Phòng làm việc & API nội bộ cho Feign
- **Người thực hiện:** Nguyễn Đức Khởi (Phụ trách FR-01, FR-02, BR-13, BR-37, BR-39, BR-41)
- **Mục tiêu:** Admin tạo tài khoản nhân viên kèm hồ sơ cá nhân, hồ sơ nhân sự, hồ sơ chuyên môn Bác sĩ; gán nhiều vai trò; khóa / ngừng (xóa mềm); phát sự kiện thay đổi; cung cấp API nội bộ chỉ đọc.
- [ ] **2.4.1** `POST /api/v1/staff` tạo trong một giao dịch: `users` + `user_roles` + `user_profiles` + `staff_profiles` (+ `veterinarian_profiles` bắt buộc khi có vai trò `VETERINARIAN`, thiếu → `AUTH_1108`); `GET /api/v1/staff`, `PUT /api/v1/users/{id}/profile`, `PUT /api/v1/staff/{id}/vet-profile`, `PUT /api/v1/users/{id}/roles`; `@PreAuthorize("hasRole('ADMIN')")`.
- [ ] **2.4.2** Gán / cập nhật `staff_profiles.room_number` (P101–P103 cho Bác sĩ, P201–P202 cho KTV).
- [ ] **2.4.3** `POST /api/v1/users/{id}/lock`, `/unlock`, `/deactivate` (không xóa cứng); mỗi thao tác đổi trạng thái / sửa họ tên ghi outbox `UserStatusChangedEvent` / `UserProfileUpdatedEvent` cùng giao dịch.
- [ ] **2.4.4** API nội bộ: `GET /internal/users/active-doctors/count`, `GET /internal/users/{id}` (họ tên, vai trò, phòng, trạng thái), `GET /internal/users/doctors?status=ACTIVE`.

> **Hướng dẫn Kiểm thử Task 2.4:**
> 1. Gọi trực tiếp cổng service (không qua Gateway):
>    ```bash
>    curl http://localhost:8081/internal/users/active-doctors/count
>    ```
> 2. **Kết quả kỳ vọng:** `200 OK`, `data: 3` (bs_tien, bs_an, bs_mai).
> 3. Gọi `POST /api/v1/staff` bằng `$TOKEN_VET` → `403`, mã lỗi `SYS_1003`. Tạo Bác sĩ thiếu `vetProfile` bằng `$TOKEN_ADMIN` → `400 AUTH_1108`.
> 4. Khóa `bs_mai`: `POST /api/v1/users/$U_MAI/lock` → `outbox_events` có 1 dòng `UserStatusChangedEvent` → sau ≤ 1 giây `PUBLISHED`; `active-doctors/count` → `2`; mở khóa lại cho các task sau. `bs_mai` đăng nhập khi đang khóa → `401 AUTH_1107`.

---

### Task 2.5: Cấu hình Tầng Dữ liệu & Entity `appointment-service` (:8082)
- **Người thực hiện:** Lưu Minh Hiển
- **Mục tiêu:** Kết nối `pet_clinic_appointment_db`, cài đặt Entity `Appointment` và `AppointmentStatusHistory`.
- [ ] **2.5.1** Cấu hình `application.yml` kết nối `pet_clinic_appointment_db`.
- [ ] **2.5.2** Tạo Entity `Appointment` (**14 trường**: `id` UUIDv7, `appointmentCode`, `petId`, `ownerId` (khóa ngoại logic), `petNameSnapshot`, `ownerNameSnapshot`, `ownerPhoneSnapshot`, `appointmentDate`, `startTime`, `reason`, `bookingChannel`, `status`, `createdAt`, `version`). Snapshot lấy từ Feign `GET /internal/pets/{id}` lúc đặt; cập nhật bởi listener `UserProfileUpdatedEvent`, `PetUpdatedEvent`. **Không có** `end_time`, `updated_at`, `cancel_reason`.
- [ ] **2.5.3** Tạo Entity `AppointmentStatusHistory` (7 trường, `@ManyToOne` tới `Appointment`; `changedByUserId` nullable).
- [ ] **2.5.4** Tạo `AppointmentRepository` (có `findByOwnerIdOrderByAppointmentDateDesc` – không gọi chéo service), `AppointmentStatusHistoryRepository`; `OutboxEvent`, `ProcessedEvent` từ `common-library`.

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
>      -d '{"petId": "'$PET_LU'", "appointmentDate": "2026-11-12", "startTime": "09:00:00",
>           "reason": "Mèo bị nôn mửa và bỏ ăn 2 ngày"}'
>    ```
>    **Kỳ vọng:** `201 Created`, mã dạng `APT-20261112-001`, status `PENDING`; `owner_id`, `pet_name_snapshot = 'Lu'`, `owner_phone_snapshot` được điền từ Feign. (Body **không** có `endTime`, `ownerId`.) Lưu `APPT_1`.
> 2. Lễ tân duyệt: `curl -X POST http://localhost:8080/api/v1/appointments/$APPT_1/confirm -H "Authorization: Bearer $TOKEN_REC"`.
> 3. Kiểm tra Audit Trail:
>    ```sql
>    SELECT from_status, to_status, changed_by_user_id, notes
>    FROM pet_clinic_appointment_db.appointment_status_histories WHERE appointment_id = UUID_TO_BIN('$APPT_1');
>    ```
> 4. **Kết quả kỳ vọng:** 2 dòng: `NULL → PENDING` (`$U_LAN`) và `PENDING → CONFIRMED` (`$U_HOA`).

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
- [ ] **3.1.1** Kết nối `pet_clinic_clinical_db` gồm **24 bảng** và 2 VIEW (`v_service_invoice_amounts`, `v_current_service_prices`); kết nối **Redis** (`spring-boot-starter-data-redis`, `timeout: 1s`) và nạp các Lua script hàng đợi (`issue_ticket`, `start_ticket`, `finish_ticket`, `move_ticket`).
- [ ] **3.1.2** CRUD Thú cưng (`/api/v1/pets`, `/api/v1/species`) (FR-10, FR-11), xóa mềm bằng `deleted_at`; sửa tên / chủ ghi outbox `PetUpdatedEvent`. Tìm thú cưng theo chủ: `GET /api/v1/pets?ownerId=`; theo số điện thoại: `GET /api/v1/pets?ownerPhone=` (dùng `owner_phone_snapshot`, không gọi `auth-service`). Listener `UserProfileUpdatedEvent` cập nhật `owner_*_snapshot`, `doctor_name_snapshot`. API nội bộ `GET /internal/pets/{id}`.
- [ ] **3.1.3** CRUD nhóm dịch vụ (`service_categories`: `queue_type`, `requires_prepayment`), dịch vụ (`services`, xóa mềm `is_active`), **bảng giá có lịch sử** (`service_prices`, `ServicePriceBook.changePrice` – Quy chuẩn 7.4) và gói xét nghiệm (`service_lab_test_items`) (FR-03, FR-05); CRUD chỉ số xét nghiệm `lab_test_items`.
- [ ] **3.1.4** CRUD khoảng tham chiếu `lab_test_reference_ranges` (`min_value`, `max_value` theo `species_id`) (FR-06).

> **Hướng dẫn Kiểm thử Task 3.1:**
> 1. `curl "http://localhost:8080/api/v1/clinical/lab-test-items/RBC/reference-ranges" -H "Authorization: Bearer $TOKEN_LAB"`
> 2. **Kết quả kỳ vọng:** 2 khoảng tham chiếu: Chó (DOG) `5.50 – 8.50`, Mèo (CAT) `5.00 – 10.00` (đơn vị `10^12/L`).
> 3. `GET /api/v1/clinical/services/$S_CBC/lab-test-items` → 4 chỉ số WBC, RBC, HGB, PLT của gói `LAB_CBC`.
> 4. Đổi giá: `POST /api/v1/catalog/services/$S_EXAM/prices` body `{"price": 120000, "vatRate": 0, "effectiveFrom": "<ngày mai 00:00>", "reason": "Điều chỉnh giá"}` → `service_prices` có 2 dòng: dòng cũ `effective_to` = ngày mai, dòng mới đang mở; hôm nay `v_current_service_prices` vẫn trả 100000. Gửi `effectiveFrom` sớm hơn giá hiện hành → `400 BILL_1410`. (Xóa dòng thử này trước khi chạy Task 3.2.)

---

### Task 3.2: Tiếp đón tại Quầy (Check-in), Khách Vãng lai & Danh sách chờ phân công
- **Người thực hiện:** Nguyễn Đức Khởi (Phụ trách FR-18, FR-19, FR-20, FR-21, FR-26, UC-18, UC-19, UC-20, EX-02, EX-03, EX-04)
- **Mục tiêu:** Lễ tân tiếp nhận thú cưng (có hẹn hoặc vãng lai), tạo `pet_visits` (`WAITING`) kèm **hóa đơn phí khám**; khách nộp phí thì hệ thống **phát phiếu xếp hàng**. **Lễ tân không cân, không đo thân nhiệt** – Bác sĩ làm trong phòng khám (Task 3.3).
- [ ] **3.2.1** API Check-in thống nhất (`POST /api/v1/clinical/pet-visits/check-in`), body `{petId, appointmentId (null nếu vãng lai), isEmergency, reasonForVisit}`:
  - Nếu có `appointmentId`: Feign **chỉ đọc** `GET /internal/appointments/{id}` – phải `CONFIRMED`, đúng ngày, đúng thú cưng (`APPT_1205`).
  - Chặn nếu thú cưng còn đợt khám chưa kết thúc (`CLIN_1306`).
  - Trong giao dịch: tạo `pet_visits` (`WAITING`, `checked_in_at`, `receptionist_id`, `is_emergency`, `doctor_id` tùy chọn), ghi lịch sử `NULL → WAITING`; tạo dịch vụ khám `EXAM_GEN` (`PENDING`, history `ORDERED`) + `service_invoices` `PENDING` (giá từ `ServicePriceBook.current` – `unit_price = 100000.00`); ghi outbox `VisitCheckedInEvent` (kèm `isEmergency`, tên thú cưng / chủ nuôi).
  - Sau commit: `OutboxRelay` gửi `VisitCheckedInEvent`; ca cấp cứu → `QueueIssuerListener` phát phiếu `DOCTOR` `priority = 2` trên Redis. `appointment-service` (consumer, idempotent) chuyển lịch `CONFIRMED → CHECKED_IN` và ghi lịch sử. **Không** gọi Feign để ghi sang `appointment-service`.
- [ ] **3.2.2** Khách vãng lai (EX-02) dùng cùng endpoint với `appointmentId = null`. Khách đến sau khi lịch đã `NO_SHOW` cũng tiếp nhận như vãng lai (FR-18).
- [ ] **3.2.3** API Hàng đợi (FR-21, EX-04): `GET /api/v1/clinical/pet-visits/queue` (Lễ tân) trả **danh sách chờ phân công** (Sorted Set `queue:{ngày}:DOCTOR:UNASSIGNED`) và **hàng đợi của từng Bác sĩ** (kèm `waitingCount` = `ZCARD`, `suggestedDoctorId` = Bác sĩ ít phiếu chờ nhất); `GET /api/v1/clinical/pet-visits/my-queue` (Bác sĩ) trả phiếu của chính mình. Thứ tự theo `score` của Sorted Set (Quy chuẩn 9.3, `QueueRedisRepository`); tên thú cưng / chủ nuôi lấy từ Hash phiếu (snapshot).
- [ ] **3.2.3b** API Thu ngân (FR-55, FR-59): `GET /api/v1/clinical/cashier/pending?section=EXAM_FEE` (ca `WAITING` chưa có phiếu) và `POST /api/v1/clinical/pet-visits/{id}/service-invoices/confirm-payment` (Quy chuẩn 8.3): thu hóa đơn phí khám → `PAID` + outbox `ServiceInvoicePaidEvent` trong cùng giao dịch; `QueueIssuerListener` nhận sự kiện, chạy `issue_ticket.lua` phát **phiếu `DOCTOR`** (số phiếu `INCR` theo ngày, người phát = Thu ngân, chống trùng theo `eventId`) rồi gửi `QueueTicketIssuedEvent`.
- [ ] **3.2.4** API Hủy tiếp nhận (`POST /api/v1/clinical/pet-visits/{id}/cancel`, body `{"reason": "..."}`, EX-03): `WAITING → CANCELLED`, **lý do ghi vào `pet_visit_status_histories.notes`** (không có cột `cancel_reason`); phiếu `WAITING` → `CANCELLED`; dịch vụ khám → `CANCELLED`; hóa đơn phí khám chưa thu → `CANCELLED`, **đã thu → giữ `PAID`** (không hoàn).
- [ ] **3.2.5** Consumer `VisitCheckedInEvent` trong `appointment-service`: idempotent, retry 3 lần rồi vào DLQ.

> **Hướng dẫn Kiểm thử Task 3.2:**
> 1. Check-in lịch hẹn `$APPT_1` của mèo Lu:
>    ```bash
>    curl -X POST http://localhost:8080/api/v1/clinical/pet-visits/check-in \
>      -H "Authorization: Bearer $TOKEN_REC" -H "Content-Type: application/json" \
>      -d '{"petId": "'$PET_LU'", "appointmentId": "'$APPT_1'", "isEmergency": false, "reasonForVisit": "Bỏ ăn, nôn 2 ngày"}'   # lưu VISIT_1 = .data.id
>    ```
> 2. **Kết quả kỳ vọng:**
>    - `201 Created`, mã dạng `VISIT-2026-0001`, `status: "WAITING"`; chưa có dòng `vital_signs`, chưa có `medical_records`.
>    - `service_invoices`: 1 dòng (`$INV_1`) phí khám `100000.00` `PENDING`; `redis-cli KEYS 'ticket:*'` → rỗng (**chưa nộp phí thì chưa có phiếu**); `outbox_events` có `VisitCheckedInEvent` `PUBLISHED`.
>    - Sau ≤ 1 giây: `SELECT status FROM pet_clinic_appointment_db.appointments WHERE id = 1;` → `CHECKED_IN`, kèm 1 dòng lịch sử `CONFIRMED → CHECKED_IN` (user 5).
> 3. Gọi check-in lần nữa cho thú cưng 1 → `409`, mã lỗi `CLIN_1306`.
> 4. Check-in vãng lai cho chó Milo (dùng ở Task 3.3 và 3.7): body `{"petId": "'$PET_MILO'", "appointmentId": null, "isEmergency": false, "reasonForVisit": "Ngứa, rụng lông"}` → ca `$VISIT_2` `WAITING`, hóa đơn phí khám `$INV_2` `PENDING`; `GET /api/v1/clinical/cashier/pending?section=EXAM_FEE` trả cả hai ca.
> 5. Thu phí khám (Lễ tân kiêm Thu ngân):
>    ```bash
>    curl -X POST http://localhost:8080/api/v1/clinical/pet-visits/$VISIT_1/service-invoices/confirm-payment \
>      -H "Authorization: Bearer $TOKEN_REC" -H "Content-Type: application/json" -d '{"invoiceIds": ["'$INV_1'"]}'
>    curl -X POST http://localhost:8080/api/v1/clinical/pet-visits/$VISIT_2/service-invoices/confirm-payment \
>      -H "Authorization: Bearer $TOKEN_REC" -H "Content-Type: application/json" -d '{"invoiceIds": ["'$INV_2'"]}'
>    ```
>    **Kỳ vọng:** `200 OK`; hóa đơn `$INV_1`, `$INV_2` `PAID`; sau ~1 giây Redis có phiếu số 1 (ca `$VISIT_1`, `DOCTOR`) và phiếu số 2 (ca `$VISIT_2`), cả hai `WAITING` trong `queue:{ngày}:DOCTOR:UNASSIGNED` (lưu `TICKET_1`, `TICKET_2`); cả hai ca vẫn `WAITING`. Phát lại `ServiceInvoicePaidEvent` của `$INV_1` (đặt dòng outbox về `PENDING`) → không có phiếu thứ ba (EX-19). `GET /api/v1/clinical/pet-visits/queue` trả 2 phiếu trong danh sách chờ phân công, phiếu `$TICKET_1` đứng trước phiếu `$TICKET_2`.

---

### Task 3.3: Xếp phiếu vào Hàng đợi Bác sĩ, Gọi số theo từng dòng & Bắt đầu Khám Giai đoạn 1
- **Người thực hiện:** Lưu Minh Hiển (Phụ trách FR-22, FR-24, FR-25, FR-27, FR-28, FR-29, FR-47, UC-21, UC-22, EX-05, EX-10)
- **Mục tiêu:** Lễ tân xếp phiếu vào hàng đợi riêng của Bác sĩ bất kỳ (không cần Bác sĩ rảnh); Bác sĩ gọi số theo phiếu (phiếu bất kỳ; khách vắng thì gọi phiếu khác, thứ tự không đổi), bắt đầu khám (T02) – chỉ được khi ca có phiếu (đã nộp phí khám hoặc cấp cứu).
- [ ] **3.3.1** Truy vấn trạng thái Bác sĩ (`GET /api/v1/clinical/doctors/status`) theo State Machine mục 3.3: `BUSY` nếu có ca `IN_PROGRESS`, ngược lại `AVAILABLE`; kèm `waitingCount` (số phiếu `DOCTOR` `WAITING` của Bác sĩ). Danh sách Bác sĩ, tên, phòng lấy qua Feign `auth-service` (có cache + fallback); `waitingCount` = `ZCARD` trên Redis.
- [ ] **3.3.2** **API Xếp ca vào hàng đợi Bác sĩ** (`POST /api/v1/clinical/pet-visits/{id}/assign-doctor`, body `{"doctorId": "'$U_TIEN'"}`, chỉ `RECEPTIONIST`): ca phải `WAITING` (`version` chống trùng); Bác sĩ phải là `VETERINARIAN` `ACTIVE` (Feign, không fallback – `CLIN_1316`); **không kiểm tra Bác sĩ rảnh**; gán `pet_visits.doctor_id`, `doctor_name_snapshot`; sau commit `move_ticket.lua` chuyển phiếu `DOCTOR` đang `WAITING` (nếu có) sang Sorted Set của Bác sĩ, giữ nguyên số phiếu và `score`. Gọi lại với Bác sĩ khác = chuyển hàng đợi. Màn hình Bác sĩ thấy ca mới ở lần làm mới hàng đợi kế tiếp.
- [ ] **3.3.2b** **API Gỡ phân công** (`POST /api/v1/clinical/pet-visits/{id}/unassign-doctor`, chỉ `RECEPTIONIST`, UC-21 Luồng 5c): ca phải `WAITING` và đã có `doctor_id`; đặt `doctor_id = NULL`, phiếu về `UNASSIGNED` (Redis), giữ số phiếu. Trạng thái không đổi nên không ghi `pet_visit_status_histories`.
- [ ] **3.3.2c** **API Gọi số** (Quy chuẩn 11.2 mục 6b, `QueueTicketServiceImpl`): `POST /api/v1/clinical/queue-tickets/{id}/call` gọi một phiếu **bất kỳ** trong hàng đợi của mình (phiếu `DOCTOR` phải thuộc Bác sĩ này – `CLIN_1311`; phiếu phải `WAITING` – `CLIN_1313`); `POST /api/v1/clinical/queue-tickets/call-next?queueType=DOCTOR` là phím tắt gọi phiếu đứng đầu `my-queue` (`CLIN_1303` nếu trống). Phòng Bác sĩ: không có ca `IN_PROGRESS` (`CLIN_1302`). Chỉ tăng `calledCount`, ghi `lastCalledAt` trên Hash phiếu và phát `PatientCalledEvent` (`action = CALLED`, kèm `ticketNo`), **không đổi trạng thái, không đổi thứ tự**, không ghi CSDL.
- [x] **3.3.2d** *(Đã bỏ 13/11/2026)* API Đẩy lùi 1 bậc (`POST /api/v1/clinical/pet-visits/{id}/skip`) cùng cột `skip_count`, hành động `SKIPPED` và sự kiện `PUSHED_BACK` đã bị xóa: "Đẩy lùi 1 bậc" làm hai ca đầu hàng đổi chỗ cho nhau mãi mãi và làm ca cấp cứu mất ưu tiên. Thay bằng gọi ca khác (3.3.2c).
- [ ] **3.3.3** API Bắt đầu khám (`POST /api/v1/clinical/pet-visits/{id}/start-exam`, Quy chuẩn 11.2): chỉ Bác sĩ được gán (`CLIN_1311`), không có ca `IN_PROGRESS` khác; ca phải có phiếu `DOCTOR` `WAITING` trên Redis (`CLIN_1314` nếu khách chưa nộp phí khám); `WAITING → IN_PROGRESS` + lịch sử (thời điểm bắt đầu = `created_at` của dòng lịch sử); tạo `medical_records`; dịch vụ khám `PENDING → IN_PROGRESS`; sau commit `start_ticket.lua` → phiếu `IN_SERVICE` (hai lần bấm đồng thời: một lần `CLIN_1313`). **Không tạo hóa đơn mới.** Sinh hiệu có thể gửi kèm hoặc thêm sau.
- [ ] **3.3.4** API sinh hiệu (`POST /api/v1/clinical/pet-visits/{id}/vital-signs` – mỗi lần đo một dòng `vital_signs`: cân nặng, thân nhiệt, nhịp tim, nhịp thở, BCS, niêm mạc, CRT) và hồ sơ khám (`PUT /api/v1/clinical/pet-visits/{id}/medical-record` – bệnh sử, kết quả khám, chẩn đoán sơ bộ; `@Version`; khóa khi ca đã chốt → `CLIN_1317`); API lịch sử bệnh án thú cưng (`GET /api/v1/pets/{id}/medical-history`, FR-28).

> **Hướng dẫn Kiểm thử Task 3.3:**
> 1. Lễ tân xếp ca `$VISIT_1` vào hàng đợi Bác sĩ Tiến:
>    ```bash
>    curl -X POST http://localhost:8080/api/v1/clinical/pet-visits/$VISIT_1/assign-doctor \
>      -H "Authorization: Bearer $TOKEN_REC" -H "Content-Type: application/json" -d '{"doctorId": "'$U_TIEN'"}'
>    ```
>    **Kỳ vọng:** `200 OK`; ca vẫn `WAITING`, `doctor_name_snapshot = 'Nguyễn Văn Tiến'`; `HGET ticket:$TICKET_1 doctorId` = `$U_TIEN`, vẫn số 1; phiếu đã rời `…:DOCTOR:UNASSIGNED` sang `…:DOCTOR:$U_TIEN`; `GET /doctors/status`: `bs_tien` `AVAILABLE`, `waitingCount = 1`.
> 2. Xếp tiếp ca `$VISIT_2` (chó Milo, đã nộp phí ở Task 3.2 bước 5) vào hàng đợi `bs_tien` → `200 OK` (**không bị chặn**); `GET /pet-visits/my-queue` (token `bs_tien`) trả phiếu số `[1, 2]`.
> 2b. Gọi số, khách vắng thì gọi phiếu khác:
>    ```bash
>    curl -X POST "http://localhost:8080/api/v1/clinical/queue-tickets/call-next?queueType=DOCTOR" -H "Authorization: Bearer $TOKEN_VET"   # gọi phiếu số 1 (đầu hàng)
>    curl -X POST http://localhost:8080/api/v1/clinical/queue-tickets/$TICKET_2/call -H "Authorization: Bearer $TOKEN_VET"                       # phiếu số 1 vắng: gọi thẳng phiếu số 2
>    ```
>    **Kỳ vọng:** cả hai lệnh `200 OK`; `my-queue` vẫn `[1, 2]`, cả hai phiếu vẫn `WAITING` và có `calledCount = 1`, `lastCalledAt`; mỗi lệnh phát một `PatientCalledEvent` `CALLED`. Gọi lại phiếu số 1 (`…/queue-tickets/$TICKET_1/call`) khi khách quay lại → `200 OK`, thứ tự không đổi. Gọi khi Bác sĩ đang có ca `IN_PROGRESS` → `409 CLIN_1302`; gọi phiếu của Bác sĩ khác → `403 CLIN_1311`.
> 3. Bác sĩ Tiến bắt đầu khám:
>    ```bash
>    curl -X POST http://localhost:8080/api/v1/clinical/pet-visits/$VISIT_1/start-exam \
>      -H "Authorization: Bearer $TOKEN_VET" -H "Content-Type: application/json" \
>      -d '{"vitalSigns": {"weightKg": 4.6, "temperatureC": 39.2, "heartRateBpm": 180, "mucousMembraneColor": "Nhợt"},
>           "anamnesis": "Bỏ ăn, nôn 2 ngày, nghi nuốt búi lông"}'
>    ```
>    *(Tên trường JSON đúng theo DTO `StartExaminationRequest` / `VitalSignsRequest`; gửi sai tên, ví dụ `weight`, Jackson sẽ bỏ qua và cân nặng không được lưu.)*
> 4. **Kết quả kỳ vọng:** `200 OK`, `status: "IN_PROGRESS"`; `HGET ticket:$TICKET_1 status` = `IN_SERVICE`; `vital_signs` 1 dòng (4.6 kg, 39.2 °C, `recorded_by = $U_TIEN`); `medical_records` 1 dòng có `anamnesis`; dịch vụ khám (`$DETAIL_1`) `IN_PROGRESS`; `service_invoices` vẫn 2 dòng (không lập thêm). `bs_an` gọi start-exam ca này → `403`, mã `CLIN_1311`. Một ca vừa check-in chưa nộp phí khám gọi start-exam → `400 CLIN_1314`.

---

### Task 3.4: Chỉ định Dịch vụ, Lập Hóa đơn Dịch vụ & Tách hàng đợi Song song (Fork)
- **Người thực hiện:** Lưu Minh Hiển (Phụ trách FR-30, FR-31, FR-32, FR-33, FR-34, UC-23, BR-19, BR-25, BR-33)
- **Mục tiêu:** Mỗi dịch vụ được chỉ định sinh **đúng 1 hóa đơn dịch vụ** trong cùng giao dịch; chỉ định cận lâm sàng chuyển ca sang `WAITING_RESULTS` (T04) và giải phóng Bác sĩ; khách **nộp tiền XN / CĐHA xong mới được phát phiếu phòng**.
- [ ] **3.4.1** API Chỉ định cận lâm sàng (`POST /api/v1/clinical/pet-visits/{id}/paraclinical-orders`, body `{serviceIds, notes}`): chỉ nhận dịch vụ `LABORATORY` / `IMAGING`; yêu cầu đã có lần đo `vital_signs` có cân nặng, thân nhiệt (`CLIN_1308`) và không còn dịch vụ tại phòng dang dở (`CLIN_1309`).
- [ ] **3.4.2** Trong **một giao dịch**: với mỗi dịch vụ tạo `visit_service_details` (`PENDING`, history `action = ORDERED`) **và** `service_invoices` (`PENDING`, snapshot `unit_price`, `vat_rate` từ `service_prices` đang hiệu lực, mã `SINV-YYYY-XXXX`); dịch vụ khám → `COMPLETED`; phiếu `DOCTOR` → `DONE` (ghi `queue_ticket_histories`, sau commit `finish_ticket.lua`); `pet_visits` → `WAITING_RESULTS` + lịch sử. Dịch vụ CLS **chưa có phiếu** (hiện ở `cashier/pending?section=PARACLINIC`); ca cấp cứu thì phát phiếu phòng `priority = 2` ngay. (`visit_service_details` **không** chứa giá.)
- [ ] **3.4.2b** Thu tiền CLS: `confirm-payment` với hóa đơn XN / CĐHA → `PAID` + outbox `ServiceInvoicePaidEvent`; `QueueIssuerListener` phát phiếu `LABORATORY` / `IMAGING` trên Redis (dịch vụ cùng phòng của lần thu gộp một phiếu, `vsdIds` trong Hash).
- [ ] **3.4.3** Dịch vụ tại phòng (tiêm, tẩy giun, thủ thuật – FR-30): `POST /api/v1/clinical/pet-visits/{id}/in-room-services` tạo chỉ định + hóa đơn `PENDING` (không thu trước, không có phiếu); `POST /api/v1/clinical/service-details/{detailId}/perform` → `COMPLETED`.
- [ ] **3.4.4** API Hủy dịch vụ (`POST /api/v1/clinical/service-details/{detailId}/cancel`, body `{"reason": "...", "reasonType": "CUSTOMER|CLINIC"}`): dịch vụ `CANCELLED`, rời phiếu; hóa đơn chưa thu → `CANCELLED`; đã thu + `CUSTOMER` → giữ `PAID`; đã thu + `CLINIC` (phòng khám không làm được) → `REFUNDED`; phí khám không bao giờ `REFUNDED` (`CLIN_1310`). Phiếu hết dịch vụ chờ → `CANCELLED`.
- [ ] **3.4.5** API Hủy ca / Chuyển viện GĐ 1 (`POST /api/v1/clinical/pet-visits/{id}/cancel-exam`, FR-34): chỉ khi **chưa có dịch vụ tại phòng nào `COMPLETED`** (ngược lại trả `400 CLIN_1305`, Bác sĩ phải chốt ca); hủy mọi dịch vụ của ca, hủy hóa đơn chưa thu (phí khám đã thu giữ `PAID`), phiếu → `CANCELLED`, ca → `CANCELLED`, lý do vào lịch sử.
- [ ] **3.4.6** Hướng dẫn chủ nuôi ra quầy nộp tiền rồi sang khu cận lâm sàng; phiếu phòng được phát kèm `QueueTicketIssuedEvent` (không còn `ServicesPrescribedEvent`).

> **Hướng dẫn Kiểm thử Task 3.4:**
> 1. Bác sĩ chỉ định xét nghiệm CBC (service 5) và X-quang (service 7):
>    ```bash
>    curl -X POST http://localhost:8080/api/v1/clinical/pet-visits/$VISIT_1/paraclinical-orders \
>      -H "Authorization: Bearer $TOKEN_VET" -H "Content-Type: application/json" \
>      -d '{"serviceIds": ["'$S_CBC'", "'$S_XRAY'"], "notes": "Kiểm tra viêm tụy cấp và dị vật đường tiêu hóa"}'
>    ```
> 2. **Kết quả kỳ vọng:**
>    - `200 OK`; ca `status: "WAITING_RESULTS"`; `bs_tien` trở về `AVAILABLE`.
>    - `visit_service_details` của ca `$VISIT_1`: `$DETAIL_1` (khám) `COMPLETED`, `$DETAIL_3` (CBC) và `$DETAIL_4` (X-quang) `PENDING` (`$DETAIL_2` là dịch vụ khám của ca `$VISIT_2`).
>    - `service_invoices` của ca `$VISIT_1`: hóa đơn `$INV_1` `PAID` (100000.00), hóa đơn `$INV_3`, `$INV_4` `PENDING` (250000.00 / 180000.00); phiếu `$TICKET_1` `DONE`; `GET /lab-queue` và `/imaging-queue` **trống** (chưa nộp tiền).
>    - `SELECT SUM(payable_amount) FROM v_service_invoice_amounts WHERE visit_id = UUID_TO_BIN('$VISIT_1');` → `530000.00`.
> 2b. Thu tiền CLS: `confirm-payment` ca `$VISIT_1` với `{"invoiceIds": ["'$INV_3'", "'$INV_4'"]}` → hóa đơn `$INV_3`, `$INV_4` `PAID`; phiếu `$TICKET_3` (`LABORATORY`, số 1, `vsdIds = $DETAIL_3`) và phiếu `$TICKET_4` (`IMAGING`, số 1, `vsdIds = $DETAIL_4`) `WAITING` trên Redis; ca vẫn `WAITING_RESULTS`. Thu tiền hóa đơn dịch vụ làm tại phòng khi ca chưa chốt → `400 BILL_1409`.
> 3. Thử chỉ định trên một ca chưa nhập cân nặng → `400`, mã `CLIN_1308`.

---

### Task 3.5: Phòng Xét nghiệm – Gọi số theo từng dòng, Lấy mẫu & Nhập Kết quả
- **Người thực hiện:** Nguyễn Đức Khởi (Phụ trách FR-35, FR-37, FR-38, FR-39, FR-40, FR-41, UC-25, BR-23, BR-24, BR-34, EX-06, EX-07)
- **Mục tiêu:** KTV Lab gọi số, lấy mẫu, nhập chỉ số; hệ thống lưu khoảng tham chiếu snapshot. Nhãn `LOW / NORMAL / HIGH` **tính khi hiển thị**, không lưu.
- [ ] **3.5.1** API Hàng đợi Lab: `GET /api/v1/clinical/lab-queue` (phiếu `LABORATORY` `WAITING` kèm các dịch vụ của phiếu; chỉ có khi khách đã nộp tiền; `ORDER BY priority DESC, issued_at, id`, chỉ mục `idx_qt_queue`).
- [ ] **3.5.2** API thao tác: `POST /api/v1/clinical/queue-tickets/{id}/call` (gọi một phiếu bất kỳ của phòng mình; chỉ tăng `calledCount` trên Redis và phát `PatientCalledEvent`), `POST /api/v1/clinical/queue-tickets/call-next?queueType=LABORATORY|IMAGING` (phím tắt gọi phiếu đứng đầu), `POST /api/v1/clinical/queue-tickets/{id}/start` (phiếu → `IN_SERVICE`; mọi dịch vụ của phiếu `PENDING → IN_PROGRESS`, `action = START_PROCESSING`), `POST /api/v1/clinical/service-details/{id}/sample-collected` (`action = SAMPLE_COLLECTED`, giữ `IN_PROGRESS`). Dịch vụ cuối cùng của phiếu xong / hủy → phiếu `DONE`. Khách vắng thì gọi phiếu khác, khách quay lại thì gọi lại (EX-06, EX-07), không cần API riêng.
- [ ] **3.5.3** API Nhập kết quả (`POST /api/v1/clinical/lab-results/{detailId}`), body `{"results": [{"labTestItemId": 2, "resultValue": 4.20}, …]}`:
  - Phải nhập đủ các chỉ số thuộc gói (`service_lab_test_items`).
  - Lưu `lab_test_results` (`result_value`, `min_value_snapshot`, `max_value_snapshot` theo loài của thú cưng, `performed_by`).
  - Chuyển dịch vụ `COMPLETED`; kiểm tra điều kiện Join (Task 3.7).
- [ ] **3.5.4** API xem kết quả trả về thêm trường tính toán `evaluation` (enum `LabEvaluation`, không có cột trong CSDL).

> **Hướng dẫn Kiểm thử Task 3.5:**
> 1. KTV Lab gọi phiếu `$TICKET_3`, bắt đầu và đánh dấu đã lấy mẫu cho dòng chỉ định `$DETAIL_3` (CBC):
>    ```bash
>    curl -X POST http://localhost:8080/api/v1/clinical/queue-tickets/$TICKET_3/call  -H "Authorization: Bearer $TOKEN_LAB"
>    curl -X POST http://localhost:8080/api/v1/clinical/queue-tickets/$TICKET_3/start -H "Authorization: Bearer $TOKEN_LAB"
>    curl -X POST http://localhost:8080/api/v1/clinical/service-details/$DETAIL_3/sample-collected -H "Authorization: Bearer $TOKEN_LAB"
>    ```
> 2. Nhập 4 chỉ số cho mèo Lu (RBC = 4.20, ngưỡng mèo 5.00 – 10.00):
>    ```bash
>    curl -X POST http://localhost:8080/api/v1/clinical/lab-results/$DETAIL_3 \
>      -H "Authorization: Bearer $TOKEN_LAB" -H "Content-Type: application/json" \
>      -d '{"results": [{"labTestItemId": 1, "resultValue": 12.30}, {"labTestItemId": 2, "resultValue": 4.20},
>                       {"labTestItemId": 3, "resultValue": 9.10},  {"labTestItemId": 4, "resultValue": 410.00}]}'
>    ```
> 3. **Kết quả kỳ vọng:**
>    - `200 OK`; `lab_test_results` có 4 dòng; dòng RBC: `min_value_snapshot = 5.00`, `max_value_snapshot = 10.00` (bảng **không có** cột `evaluation`).
>    - `GET /api/v1/clinical/lab-results/$DETAIL_3` trả RBC kèm `"evaluation": "LOW"`.
>    - Dòng chỉ định `$DETAIL_3` `COMPLETED`, phiếu `$TICKET_3` `DONE`; `visit_service_detail_histories` có các action `ORDERED`, `START_PROCESSING`, `SAMPLE_COLLECTED`, `COMPLETED`.
>    - Gửi thiếu chỉ số PLT → `400`, mã `SYS_1001`.

---

### Task 3.6: Phòng Chẩn đoán Hình ảnh – Huy hiệu liên phòng, Kết quả & Tệp đính kèm
- **Người thực hiện:** Nguyễn Đức Khởi (Phụ trách FR-36, FR-42, UC-26, EX-09)
- **Mục tiêu:** KTV CĐHA chụp X-quang / siêu âm, nhập mô tả, kết luận và tải ảnh. Thứ tự lưu đúng khóa ngoại: `imaging_results` trước, `imaging_attachments` sau.
- [ ] **3.6.1** Huy hiệu liên phòng trên `GET /api/v1/clinical/imaging-queue` (danh sách phiếu `IMAGING` `WAITING`): `labStatus = SAMPLING` nếu dịch vụ Lab cùng ca `IN_PROGRESS` và `action` mới nhất `START_PROCESSING`; `labStatus = SAMPLE_COLLECTED` nếu đã lấy mẫu (EX-09).
- [ ] **3.6.2** API Hoàn tất CĐHA **một request multipart** (`POST /api/v1/clinical/imaging-results/{detailId}`): trường `description`, `conclusion` và `files[]`. Trong một giao dịch: tạo `imaging_results` → lưu tệp vào volume `/app/uploads/imaging/` → tạo `imaging_attachments` trỏ tới `imaging_result_id` vừa tạo → dịch vụ `COMPLETED`. Lỗi lưu tệp thì rollback và xóa tệp đã ghi.
- [ ] **3.6.3** Giới hạn định dạng `image/jpeg`, `image/png`, `application/dicom`; dung lượng tối đa mỗi tệp cấu hình ở `spring.servlet.multipart.max-file-size`.

> **Hướng dẫn Kiểm thử Task 3.6:**
> 1. KTV CĐHA hoàn tất X-quang cho dòng chỉ định `$DETAIL_4` (phiếu `$TICKET_4`):
>    ```bash
>    curl -X POST http://localhost:8080/api/v1/clinical/queue-tickets/$TICKET_4/start -H "Authorization: Bearer $TOKEN_IMG"
>    curl -X POST http://localhost:8080/api/v1/clinical/imaging-results/$DETAIL_4 \
>      -H "Authorization: Bearer $TOKEN_IMG" \
>      -F "description=Dạ dày giãn nhẹ, có hình ảnh cản quang nghi dị vật" \
>      -F "conclusion=Nghi ngờ dị vật đường tiêu hóa đoạn môn vị" \
>      -F "files=@xray_cat_001.jpg"
>    ```
> 2. **Kết quả kỳ vọng:** `200 OK`; `imaging_results` 1 dòng; `imaging_attachments` 1 dòng có `imaging_result_id` đúng; dòng chỉ định `$DETAIL_4` `COMPLETED`, phiếu `$TICKET_4` `DONE`.
> 3. EX-09: trước khi Lab bấm "Đã lấy mẫu", `imaging-queue` hiển thị `labStatus: "SAMPLING"`.

---

### Task 3.7: Hợp nhất Kết quả (Join) & Phát phiếu ưu tiên cho Bác sĩ
- **Người thực hiện:** Lưu Minh Hiển (Phụ trách FR-23, FR-43, FR-44, BR-11, EX-05, EX-08)
- **Mục tiêu:** Khi mọi dịch vụ cận lâm sàng của ca đã `COMPLETED` hoặc `CANCELLED`, chuyển ca `RESULTS_READY` (T06) và phát phiếu `DOCTOR` ưu tiên (`priority = 1`, không thu tiền) cho Bác sĩ khám chính.
- [ ] **3.7.1** Sau mỗi lần lưu kết quả / hủy dịch vụ: nếu không còn dịch vụ `LABORATORY` / `IMAGING` nào `PENDING` hoặc `IN_PROGRESS` → `pet_visits.status = RESULTS_READY`, lịch sử `changed_by_user_id = NULL`.
- [ ] **3.7.2** Ghi outbox `ParaclinicalResultsReadyEvent` (routing key `visit.results_ready`) cùng giao dịch T06.
- [ ] **3.7.3** `QueueIssuerListener` nhận sự kiện, phát phiếu `DOCTOR` mới `priority = 1` (người phát = hệ thống) vào Sorted Set của Bác sĩ khám chính; đứng đầu hàng đợi, chỉ sau phiếu cấp cứu (FR-23). Lễ tân vẫn xếp ca mới vào hàng đợi Bác sĩ này bình thường.

> **Hướng dẫn Kiểm thử Task 3.7:**
> 1. Sau Task 3.5 và 3.6: `SELECT status FROM pet_clinic_clinical_db.pet_visits WHERE id = 1;` → `RESULTS_READY`.
> 2. Redis có phiếu `$TICKET_5` (`DOCTOR`, ca `$VISIT_1`, `priority = 1`, Bác sĩ `$U_TIEN`, người phát hệ thống). `GET /pet-visits/my-queue` (`bs_tien`) → `$TICKET_5` đứng đầu, trước phiếu của ca `$VISIT_2`. Xếp thêm một ca mới (đã nộp phí) vào hàng đợi `bs_tien` → `200 OK`, phiếu mới đứng sau phiếu `$TICKET_5` (EX-05).
> 3. EX-08: tạo ca khác chỉ định CBC + Siêu âm, nộp tiền cả hai; CBC xong rồi hủy Siêu âm với `reasonType = CUSTOMER` → ca chuyển `RESULTS_READY`; hóa đơn Siêu âm **giữ `PAID`** (không hoàn). Lặp lại với `reasonType = CLINIC` → hóa đơn Siêu âm `REFUNDED`. Nếu khách chỉ nộp tiền CBC, hủy Siêu âm ở quầy → hóa đơn Siêu âm `CANCELLED`.

---

### Task 3.8: Bắt đầu Giai đoạn 2, Đóng ca, Chốt Ca & Mở lại Hồ sơ
- **Người thực hiện:** Lưu Minh Hiển (Phụ trách FR-45, FR-46, FR-48, FR-49, FR-50, FR-54, UC-30, UC-33, EX-11, EX-12)
- **Mục tiêu:** Bác sĩ đón ca có kết quả, chẩn đoán, chốt ca (`WAITING_PAYMENT`); xử lý khách vắng / bỏ về và mở lại hồ sơ.
- [ ] **3.8.1** API Bắt đầu Giai đoạn 2 (`POST /api/v1/clinical/pet-visits/{id}/start-phase2`, T07): Bác sĩ gọi phiếu bằng `queue-tickets/call-next?queueType=DOCTOR` (phiếu ưu tiên đứng đầu); khi thú cưng vào phòng gọi API này: ca `RESULTS_READY` có phiếu `DOCTOR` `WAITING` thuộc Bác sĩ, Bác sĩ không có ca `IN_PROGRESS` (`CLIN_1302`); phiếu → `IN_SERVICE`, ca → `IN_PROGRESS` + lịch sử.
- [ ] **3.8.2** Khách vắng mặt khi gọi ca có kết quả (EX-10): gọi phiếu khác bằng `queue-tickets/{id}/call` (Task 3.3.2c); ca giữ `RESULTS_READY`, phiếu giữ vị trí. Không còn API `skip`, `postpone-callback` và tab "ca đã hoãn" (bỏ T13).
- [ ] **3.8.3** API Đóng ca / Khách bỏ về (`POST /api/v1/clinical/pet-visits/{id}/abandon`, T08 / T12, EX-11, FR-45, FR-48): áp dụng cho `RESULTS_READY` hoặc `WAITING_RESULTS` (không có dịch vụ đang `IN_PROGRESS`); dịch vụ còn `PENDING` → `CANCELLED` (hóa đơn chưa thu → `CANCELLED`, đã thu giữ `PAID`); phiếu `WAITING` → `CANCELLED`; **không tạo hóa đơn mới, không hoàn tiền** – hóa đơn của dịch vụ đã làm mà chưa thu (ca cấp cứu) giữ `PENDING` làm công nợ; ca → `COMPLETED`.
- [ ] **3.8.4** API Chốt đợt khám (`POST /api/v1/clinical/pet-visits/{id}/close-visit`, T05 / T09): body `{finalDiagnosis, treatmentPlan, doctorAdvice, followUpDate}`; ghi vào `medical_records` (`final_diagnosis`, `treatment_plan`, `doctor_advice`, `follow_up_date`); chặn khi thiếu chẩn đoán (`CLIN_1307`, EX-12) hoặc còn dịch vụ tại phòng chưa xử lý (`CLIN_1309`); → phiếu `DONE` (lịch sử phiếu), `WAITING_PAYMENT` + lịch sử; khóa hồ sơ khám và đơn thuốc; không lập thêm hóa đơn dịch vụ; nếu có đơn thuốc ghi outbox `PrescriptionCreatedEvent` (billing tạo hóa đơn nháp – Task 4.3).
- [ ] **3.8.5** API Mở lại hồ sơ (`POST /api/v1/clinical/pet-visits/{id}/reopen`, T14): Bác sĩ phụ trách hoặc ADMIN, lý do bắt buộc; `WAITING_PAYMENT → IN_PROGRESS`.

> **Hướng dẫn Kiểm thử Task 3.8:**
> 1. Bác sĩ gọi số rồi đón ca `$VISIT_1`: `curl -X POST "…/queue-tickets/call-next?queueType=DOCTOR" -H "Authorization: Bearer $TOKEN_VET"` (trả phiếu `$TICKET_5`), sau đó `curl -X POST …/pet-visits/$VISIT_1/start-phase2 -H "Authorization: Bearer $TOKEN_VET"` → `IN_PROGRESS`, phiếu `$TICKET_5` `IN_SERVICE`.
> 1b. Dịch vụ làm tại phòng ở GĐ 2 (không thu trước): `POST …/pet-visits/$VISIT_1/in-room-services` với `{"serviceIds": ["'$S_DEWORM'"]}` (Tẩy giun 50.000) → `$DETAIL_5` + hóa đơn `$INV_5` `PENDING`, không có phiếu; `POST …/service-details/$DETAIL_5/perform` → `COMPLETED`.
> 2. Bấm chốt khi chưa có chẩn đoán → `400`, mã `CLIN_1307`.
> 3. Chốt chuyên môn (đơn thuốc đã lưu ở Task 4.2):
>    ```bash
>    curl -X POST http://localhost:8080/api/v1/clinical/pet-visits/$VISIT_1/close-visit \
>      -H "Authorization: Bearer $TOKEN_VET" -H "Content-Type: application/json" \
>      -d '{"finalDiagnosis": "Viêm dạ dày ruột cấp do búi lông tắc nghẽn",
>           "treatmentPlan": "Gel tiêu lông, bù nước điện giải, kháng sinh 5 ngày",
>           "doctorAdvice": "Theo dõi phân; nếu tiếp tục nôn phải tái khám ngay"}'
>    ```
> 4. **Kết quả kỳ vọng:** `200 OK`, `status: "WAITING_PAYMENT"`; phiếu `$TICKET_5` `DONE`; mọi API sửa chuyên môn trên ca `$VISIT_1` trả `400 CLIN_1305`; hóa đơn của ca `$VISIT_1`: `$INV_1`, `$INV_3`, `$INV_4` `PAID`, hóa đơn `$INV_5` (tẩy giun) `PENDING`.
> 5. EX-10: với một ca `RESULTS_READY` khác, `call-next` rồi `…/queue-tickets/{id}/call` ở phiếu khác → ca vắng vẫn `RESULTS_READY`, phiếu giữ nguyên vị trí (đứng đầu); Bác sĩ vẫn `AVAILABLE`.

---

### Task 3.9: Thu tiền Hóa đơn Dịch vụ & Hoàn tất Ca khám (`clinical-service`)
- **Người thực hiện:** Lưu Minh Hiển (Phụ trách FR-55, FR-56, FR-57, FR-58, FR-59, FR-60, UC-34, UC-35, BR-27, BR-28, EX-14)
- **Mục tiêu:** Thu ngân thu các hóa đơn dịch vụ còn lại khi chốt ca (chủ yếu dịch vụ làm tại phòng; phí khám, XN, CĐHA đã thu ở Task 3.2, 3.4); khi mọi hóa đơn dịch vụ `PAID` / `CANCELLED` / `REFUNDED`, ca `COMPLETED` **trong cùng giao dịch cục bộ** (T10). Không phụ thuộc việc mua thuốc.
- [ ] **3.9.1** API Bảng kê (`GET /api/v1/clinical/pet-visits/{id}/service-invoices`): danh sách hóa đơn + số tiền từ VIEW `v_service_invoice_amounts`, tổng cần thu = tổng các hóa đơn `PENDING`. Danh sách ca chờ thu cuối ca: `GET /api/v1/clinical/cashier/pending?section=FINAL` (ca `WAITING_PAYMENT`) và `GET /api/v1/clinical/pet-visits/with-debt` (ca `COMPLETED` còn hóa đơn `PENDING`).
- [ ] **3.9.2** API Giảm giá (`POST /api/v1/clinical/service-invoices/{id}/discount`, body `{"discountAmount": 30000}`): `discountAmount ≤ quantity × unit_price × (1 + vat_rate)` của **chính hóa đơn đó** (`BILL_1402`, EX-14).
- [ ] **3.9.3** API Xác nhận thanh toán (`POST /api/v1/clinical/pet-visits/{id}/service-invoices/confirm-payment`, body `{"invoiceIds": [...]}`, Quy chuẩn 8.3): dịch vụ thuộc nhóm thu trước (`service_categories.requires_prepayment`) thu được bất cứ lúc nào (phiếu phát qua `ServiceInvoicePaidEvent`); dịch vụ làm tại phòng chỉ thu khi ca `WAITING_PAYMENT` hoặc `COMPLETED` có công nợ (`BILL_1409`); hóa đơn `PAID`, `paid_at`, `cashier_id`; mọi `invoiceIds` phải thuộc ca (`BILL_1401`), đang `PENDING` (`BILL_1403` nếu đã thu, `BILL_1408` nếu đã hủy); `@Version` chống thu trùng (`SYS_1005`); nếu hết hóa đơn `PENDING` và ca `WAITING_PAYMENT` → `COMPLETED` + lịch sử; outbox `ServiceInvoicePaidEvent`, `VisitCompletedEvent` (reporting ghi doanh thu, notification). Không lưu phương thức thanh toán (FR-57).
- [ ] **3.9.4** API in phiếu tạm tính / phiếu thu (FR-58).

> **Hướng dẫn Kiểm thử Task 3.9:**
> 1. Xem bảng kê ca `$VISIT_1`: `curl http://localhost:8080/api/v1/clinical/pet-visits/$VISIT_1/service-invoices -H "Authorization: Bearer $TOKEN_REC"` → 4 hóa đơn (`$INV_1`, `$INV_3`, `$INV_4` `PAID`; `$INV_5` `PENDING`), cần thu `50000.00`.
> 2. Giảm giá 300.000 cho hóa đơn tẩy giun (50.000) → `400`, mã `BILL_1402`.
> 3. Thanh toán:
>    ```bash
>    curl -X POST http://localhost:8080/api/v1/clinical/pet-visits/$VISIT_1/service-invoices/confirm-payment \
>      -H "Authorization: Bearer $TOKEN_REC" -H "Content-Type: application/json" -d '{"invoiceIds": ["'$INV_5'"]}'
>    ```
> 4. **Kết quả kỳ vọng:** `200 OK`; hóa đơn `$INV_5` `PAID` (`cashier_id = $U_HOA`); cả 4 hóa đơn của ca `$VISIT_1` đã `PAID` → `pet_visits.status = COMPLETED` ngay trong cùng phản hồi; không phát thêm phiếu; lịch sử có dòng `WAITING_PAYMENT → COMPLETED`.
> 5. Gửi lại cùng request → `409`, mã `BILL_1403`.

---

## GIAI ĐOẠN 4: KÊ ĐƠN (CLINICAL), HÓA ĐƠN THUỐC NHÁP, TRỪ KHO NGUYÊN TỬ & PHÂN HỆ BÁO CÁO

### Task 4.1: Cấu hình CSDL `billing-pharmacy-service` (:8084)
- **Người thực hiện:** Lưu Minh Hiển
- **Mục tiêu:** Quản lý danh mục thuốc (thông tin, thành phần, giá có lịch sử, tồn kho), hóa đơn thuốc nháp và nhật ký kho.
- [ ] **4.1.1** Kết nối `pet_clinic_billing_pharmacy_db` gồm **10 bảng** và 2 VIEW (`v_medicine_invoice_amounts`, `v_current_medicine_prices`).
- [ ] **4.1.2** Entities: `MedicineCategory` (`Short`), `Medicine` (UUIDv7, không giá, không tồn), `MedicineIngredient`, `MedicinePrice`, `MedicineStock` (`@MapsId`, `@Version`), `MedicineInvoice` (`@Version`, `prescriptionId` UUID thuần – khóa ngoại logic, 4 cột snapshot), `MedicineInvoiceItem` (`@ManyToOne Medicine`, `prescribedQuantity`), `InventoryTransaction`, `OutboxEvent`, `ProcessedEvent`. **Không có** `Prescription`, `PrescriptionItem` (đã chuyển sang clinical).
- [ ] **4.1.3** Khóa ngoại nội bộ (8): `medicines → medicine_categories`; `medicine_ingredients`, `medicine_prices`, `medicine_stocks → medicines`; `medicine_invoice_items → medicine_invoices, medicines`; `inventory_transactions → medicines, medicine_invoices`.
- [ ] **4.1.4** CRUD thuốc + thành phần + giá (`MedicinePriceBook.changePrice`) + API nội bộ cho clinical: `GET /internal/medicines?keyword=&active=true`, `GET /internal/medicines/{id}`, `GET /internal/medicine-invoices/status?prescriptionId=`.

> **Hướng dẫn Kiểm thử Task 4.1:**
> 1. Khởi động service: không lỗi validate schema, đăng ký Eureka thành công.
> 2. `curl "http://localhost:8084/internal/medicines?keyword=clava"` → Clavamox 250mg, quy cách "Hộp 10 vỉ x 10 viên", thành phần Amoxicillin 200 mg + Clavulanic acid 50 mg, giá 15.000, tồn 200.

---

### Task 4.2: Kê Đơn thuốc Điện tử & Cảnh báo Tồn kho (`clinical-service`)
- **Người thực hiện:** Lưu Minh Hiển (Phụ trách FR-51, FR-52, FR-53, UC-31, BR-18, BR-30, BR-32, EX-13)
- **Mục tiêu:** Đơn thuốc thuộc `clinical-service` (cùng hồ sơ khám); **không có giá, không có trạng thái**; vượt tồn kho chỉ cảnh báo.
- [ ] **4.2.1** API lưu cả đơn `PUT /api/v1/clinical/pet-visits/{id}/prescription`: kiểm tra nội bộ ca `IN_PROGRESS` và đúng Bác sĩ phụ trách (`PHARM_1411` nếu đã khóa); tối đa 1 đơn / đợt khám (`prescriptions.visit_id UNIQUE`, FK vật lý); mỗi thuốc 1 dòng.
- [ ] **4.2.2** Facade (ngoài giao dịch) gọi Feign `GET /internal/medicines/{id}` cho từng thuốc: tồn tại, đang kinh doanh; chụp `medicine_name_snapshot`, `unit_snapshot`; so tồn kho để cảnh báo. Mỗi dòng bắt buộc `medicineId`, `quantity` (> 0), `dosage`, `frequency`, `durationDays` (> 0).
- [ ] **4.2.3** Phản hồi kèm `stockWarnings` nếu `quantity > quantityOnHand` (EX-13) và `allergyWarning` nếu `pets.allergies` có ghi chú, **không chặn** lưu.
- [ ] **4.2.4** Khi chốt ca (Task 3.8): ghi outbox `PrescriptionCreatedEvent` (`prescriptionId`, `visitId`, tên khách / SĐT / thú cưng / Bác sĩ, các dòng `medicineId`, `quantity`). Mở lại hồ sơ (T14): Feign `GET /internal/medicine-invoices/status?prescriptionId=` – đã `PAID` thì chặn sửa đơn (`PHARM_1411`).

> **Hướng dẫn Kiểm thử Task 4.2:**
> 1. Kê 10 viên Clavamox (`$M_AMOX`, tồn 200) cho ca `$VISIT_1` trước khi chốt ca:
>    ```bash
>    curl -X PUT http://localhost:8080/api/v1/clinical/pet-visits/$VISIT_1/prescription \
>      -H "Authorization: Bearer $TOKEN_VET" -H "Content-Type: application/json" \
>      -d '{"doctorNotes": "Uống sau ăn",
>           "items": [{"medicineId": "'$M_AMOX'", "quantity": 10, "dosage": "1 viên/lần",
>                      "frequency": "2 lần/ngày", "durationDays": 5, "instructions": "Uống sau ăn no"}]}'
>    ```
> 2. **Kết quả kỳ vọng:** `200 OK`; `pet_clinic_clinical_db.prescription_items` có `medicine_name_snapshot = 'Clavamox 250mg'`, `unit_snapshot = 'Viên'`, không có cột giá / trạng thái; `stockWarnings: []`.
> 3. EX-13: kê 300 viên → `200` kèm `stockWarnings: ["Clavamox 250mg: tồn kho 200 < số lượng kê 300"]` (sửa lại 10 viên).
> 4. Thiếu `frequency` → `400 SYS_1001`. Sửa đơn khi ca đã `WAITING_PAYMENT` → `409 PHARM_1411`.

---

### Task 4.3: Hóa đơn Thuốc nháp từ `PrescriptionCreatedEvent` & Sửa / Hủy nháp
- **Người thực hiện:** Lưu Minh Hiển (Phụ trách FR-56, FR-61, FR-62, UC-36, BR-26, BR-31, BR-32, EX-14, EX-19)
- **Mục tiêu:** Chốt ca có đơn thuốc thì quầy thuốc tự có hóa đơn nháp; khách mua thì sửa số lượng và thu, mua ngoài thì hủy.
- [ ] **4.3.1** Listener `billing.prescription-created` (Quy chuẩn 8.2 `createDraft`, `IdempotentConsumer`): tạo `medicine_invoices` `PENDING` (mã `MINV-YYYY-XXXX`, snapshot khách / thú cưng / Bác sĩ) + một dòng mỗi thuốc (`prescribed_quantity` = `quantity` = số kê, giá từ `medicine_prices` hiện hành); đã có hóa đơn `PENDING` (chốt lại sau T14) thì dựng lại dòng; đã `PAID` / `CANCELLED` thì chỉ ghi log.
- [ ] **4.3.2** `GET /api/v1/billing/medicine-invoices?visitId=` cho màn hình Thu ngân.
- [ ] **4.3.3** `PUT /api/v1/billing/medicine-invoices/{id}/items` (Quy chuẩn 8.2 `updateItems`): chỉ khi `PENDING` (`BILL_1403` / `BILL_1408`); `quantity = 0` để bỏ dòng; `quantity ≤` tồn kho (`PHARM_1406`), được khác số kê; còn ít nhất 1 dòng; kiểm tra lại giảm giá (`BILL_1402`).
- [ ] **4.3.4** `POST /api/v1/billing/medicine-invoices/{id}/cancel` (khách mua ngoài): `PENDING → CANCELLED`, kho không đổi; in đơn thuốc `GET /api/v1/clinical/pet-visits/{id}/prescription/print`.

> **Hướng dẫn Kiểm thử Task 4.3:**
> 1. Sau khi chốt ca `$VISIT_1` (Task 3.8) chờ ~1 giây: `GET /api/v1/billing/medicine-invoices?visitId=$VISIT_1` → 1 hóa đơn `PENDING`, 1 dòng Clavamox `prescribed_quantity = 10`, `quantity = 10`, `unit_price = 15000.00`, `vat_rate = 0.05`; `v_medicine_invoice_amounts.payable_amount = 157500.00`. Lưu `MINV_1`.
> 2. EX-19: lấy dòng `outbox_events` của sự kiện đó ở clinical, đặt lại `status = 'PENDING'` để relay gửi lần nữa → vẫn chỉ 1 hóa đơn; `processed_events` có 1 dòng cho `billing.prescription-created`.
> 3. Sửa về 12 viên (`PUT …/medicine-invoices/$MINV_1/items`, tồn đủ) → `200` (khác số kê được); 0 dòng → `400`; vượt tồn kho → `409 PHARM_1406`. Sửa lại 10 viên.

---

### Task 4.4: Xác nhận Thanh toán Thuốc & Trừ kho Nguyên tử (một giao dịch)
- **Người thực hiện:** Lưu Minh Hiển (Phụ trách FR-63, FR-64, FR-65, UC-36, BR-29, BR-30, BR-31, EX-15, EX-16)
- **Mục tiêu:** Hóa đơn thuốc `PAID`, trừ `medicine_stocks`, ghi `EXPORT_SALE` và outbox trong **cùng một `@Transactional`** (Quy chuẩn 8.2 `confirmPayment`). Không ảnh hưởng trạng thái đợt khám.
- [ ] **4.4.1** Hóa đơn phải `PENDING` (`BILL_1403` / `BILL_1408`); cập nhật đơn giá theo `medicine_prices` hiện hành (EX-20).
- [ ] **4.4.2** Sắp xếp dòng theo `medicineId`; `MedicineStockRepository.deduct` (`UPDATE medicine_stocks … WHERE quantity_on_hand >= :qty`, tăng `version`). 0 dòng → `PHARM_1406` → rollback toàn bộ (EX-15).
- [ ] **4.4.3** Ghi `inventory_transactions` mỗi dòng (`EXPORT_SALE`, `quantity = -qty`, `medicine_invoice_id`, `created_by`).
- [ ] **4.4.4** `payment_status = PAID`, `paid_at`, `cashier_id`; `@Version` chặn bấm đúp (`SYS_1005`, EX-16).
- [ ] **4.4.5** Outbox `MedicineInvoicePaidEvent` (reporting, notification); thuốc chạm `min_stock_alert` → outbox `MedicineLowStockEvent`.
- [ ] **4.4.6** API Nhập kho / Cân chỉnh kho (`POST /api/v1/pharmacy/medicines/{id}/import`, `/adjust`, chỉ ADMIN, FR-66): ghi `IMPORT` (+, `unit_cost`) / `ADJUSTMENT` (±) và cập nhật `medicine_stocks` cùng giao dịch.

> **Hướng dẫn Kiểm thử Task 4.4:**
> 1. `curl -X POST http://localhost:8080/api/v1/billing/medicine-invoices/$MINV_1/confirm-payment -H "Authorization: Bearer $TOKEN_REC"`
> 2. **Kết quả kỳ vọng:** `200 OK`; hóa đơn `PAID`, `cashier_id = $U_HOA`; `medicine_stocks.quantity_on_hand` của Clavamox 200 → **190**; `inventory_transactions` 1 dòng `EXPORT_SALE`, `quantity = -10`; bất biến `SUM(quantity) = 190`; `pet_visits.status` của ca không đổi; outbox có `MedicineInvoicePaidEvent` → `PUBLISHED`.
> 3. EX-16: gọi lại → `409 BILL_1403`; tồn kho vẫn 190.
> 4. EX-15: cân chỉnh kho (`ADJUSTMENT −185`) còn 5 viên; với hóa đơn nháp của một ca khác mua 10 viên, xác nhận → `409 PHARM_1406`; tồn kho vẫn 5, hóa đơn vẫn `PENDING`. Sửa về 5 viên rồi xác nhận → `PAID`, tồn 0.

---

### Task 4.5: Phân hệ Báo cáo `reporting-service` (:8086) – CQRS Read Model
- **Người thực hiện:** Nguyễn Đức Khởi (Phụ trách FR-69, FR-70, UC-08, NFR-09, NFR-10)
- **Mục tiêu:** Dựng CSDL đọc `pet_clinic_reporting_db` (5 bảng) từ sự kiện; API báo cáo chỉ đọc một CSDL, không gọi service khác.
- [ ] **4.5.1** Module `reporting-service`: kết nối `pet_clinic_reporting_db`, entities `VisitFact`, `RevenueFact`, `DailyRevenueSummary`, `DoctorDailyPerformance`, `ProcessedEvent`.
- [ ] **4.5.2** Listener (mỗi listener một queue, `IdempotentConsumer`): `VisitCheckedInEvent` (tạo `visit_facts`), `VisitCompletedEvent` / `VisitCancelledEvent` (cập nhật, cộng `doctor_daily_performances`), `ServiceInvoicePaidEvent` / `MedicineInvoicePaidEvent` (ghi `revenue_facts` `SALE`, cộng `daily_revenue_summaries` bằng `INSERT … ON DUPLICATE KEY UPDATE`), `ServiceInvoiceRefundedEvent` (dòng `REFUND` âm), `UserProfileUpdatedEvent` / `PetUpdatedEvent` (cập nhật tên).
- [ ] **4.5.3** API (`ADMIN`): `GET /api/v1/reports/revenue/daily?from=&to=&type=`, `/revenue/by-category?month=`, `/doctors/performance?from=&to=`, `/visits/summary?date=`; Gateway route `/api/v1/reports/**`.
- [ ] **4.5.4** Job dựng lại (chạy tay): xóa bảng reporting, đặt lại `processed_events`, phát lại sự kiện từ `outbox_events` (≤ 7 ngày) của các service.

> **Hướng dẫn Kiểm thử Task 4.5:**
> 1. Sau khi chạy hết kịch bản Task 3.2 → 4.4: `GET /api/v1/reports/revenue/daily?from=<hôm nay>&to=<hôm nay>` → dòng SERVICE (khám 2 × 100.000 + CBC 250.000 + X-quang 180.000 + tẩy giun 50.000) và dòng MEDICINE 157.500, khớp tổng `v_service_invoice_amounts` / `v_medicine_invoice_amounts` (`PAID`).
> 2. Hoàn tiền một dịch vụ CĐHA (EX-08 c) → có dòng `REFUND` âm, tổng ngày giảm đúng bằng số tiền hoàn.
> 3. Phát lại một `ServiceInvoicePaidEvent` (EX-19) → tổng không đổi.
> 4. `GET /api/v1/reports/doctors/performance` → `bs_tien` có số ca hoàn tất và doanh thu dịch vụ đúng; tên lấy từ bảng phẳng (không có lời gọi tới `auth-service` trong log).

---

## GIAI ĐOẠN 5: THÔNG BÁO REALTIME, FRONTEND REACT & KIỂM THỬ TOÀN DIỆN

### Task 5.1: Phân hệ Thông báo & Realtime WebSocket (`notification-service` :8085)
- **Người thực hiện:** Nguyễn Đức Khởi
- **Mục tiêu:** Lắng nghe sự kiện trên exchange `clinic.events`, đẩy thông báo realtime qua WebSocket STOMP và gửi Email. Không dùng SMS.
- [ ] **5.1.1** Cấu hình STOMP Broker (`/topic/lobby`, `/topic/doctor/{id}`, `/topic/lab`, `/topic/imaging`, `/topic/admin`, `/user/queue/notifications`).
- [ ] **5.1.2** Listener `AppointmentBookedEvent`, `AppointmentStatusChangedEvent`, `AppointmentNoShowEvent` → Email / thông báo Portal cho chủ nuôi.
- [ ] **5.1.3** Listener (mỗi listener một queue, `IdempotentConsumer` với các sự kiện gửi mail) `VisitCheckedInEvent` (mục chờ thu phí khám), `QueueTicketIssuedEvent` (làm mới hàng đợi Bác sĩ / Lab / CĐHA, gửi số phiếu cho chủ nuôi), `PatientCalledEvent` → màn hình gọi số ở sảnh.
- [ ] **5.1.4** Listener `ParaclinicalResultsReadyEvent` → huy hiệu "Có kết quả" và làm mới hàng đợi trên `/topic/doctor/{doctorId}`.
- [ ] **5.1.5** Listener `VisitCompletedEvent`, `MedicineInvoicePaidEvent` → gửi phiếu thu / hóa đơn thuốc điện tử; `PrescriptionCreatedEvent` → mục "Hóa đơn thuốc nháp" trên màn hình Thu ngân; `MedicineLowStockEvent` → cảnh báo `/topic/admin`; `UserStatusChangedEvent` (Bác sĩ bị khóa) → cảnh báo Lễ tân chuyển hàng đợi (EX-17).

> **Hướng dẫn Kiểm thử Task 5.1:**
> 1. Kết nối WebSocket `ws://localhost:8080/ws`, subscribe `/topic/doctor/$U_TIEN`.
> 2. Hoàn tất dịch vụ cận lâm sàng cuối cùng của ca `$VISIT_1` (Task 3.6).
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
  - `RECEPTIONIST`: tiếp đón, xếp ca vào hàng đợi riêng của Bác sĩ, thu phí khám / tiền XN, CĐHA (phát phiếu), thu hóa đơn cuối ca, công nợ, hoàn tiền, bán thuốc theo đơn.
  - `VETERINARIAN`: màn hình khám 2 pha, danh sách phiếu (nút "Gọi", "Bắt đầu"), kê đơn.
  - `LAB_TECHNICIAN` / `IMAGING_TECHNICIAN`: hàng đợi và nhập kết quả phòng mình.
  - `ADMIN`: tài khoản + hồ sơ nhân sự / chuyên môn, danh mục + bảng giá có lịch sử, kho, báo cáo (`reporting-service`) & công nợ.
  - Tài khoản nhiều vai trò: menu là hợp các vai trò trong JWT.

> **Hướng dẫn Kiểm thử Task 5.2:**
> 1. `npm run dev`; đăng nhập Bác sĩ: menu chỉ có chức năng y tế.
> 2. Đăng nhập Khách hàng, vào URL `/reception/queue` → bị chặn kèm thông báo không đủ quyền.
> 3. Đợi Access Token hết hạn (hoặc sửa TTL ngắn khi test) → request tiếp theo tự refresh và thành công.

---

### Task 5.3: Hoàn thiện Các Màn hình Nghiệp vụ Frontend
- **Người thực hiện:** Vũ Hồng Linh
- **Mục tiêu:** Hiện thực hóa bản vẽ Figma, gắn API Backend qua Gateway :8080.
- [ ] **5.3.1** Cổng Đặt lịch (Customer Portal): chọn ngày → tải khung giờ trống → chọn thú cưng → nhập triệu chứng → nhận mã hẹn.
- [ ] **5.3.2** Tiếp đón Lễ tân: lịch hẹn trong ngày, nút Check-in một chạm (chọn Bác sĩ theo gợi ý), tiếp nhận vãng lai, **bảng điều phối**: mục chờ thu phí khám + danh sách chờ phân công + một cột hàng đợi (phiếu) cho mỗi Bác sĩ (trạng thái, số phiếu chờ, phiếu cấp cứu), nút Xếp / Chuyển / Gỡ phân công luôn dùng được.
- [ ] **5.3.3** Bệnh án Bác sĩ 2 Pha: GĐ 1 (thêm lần đo sinh hiệu, bệnh sử, kết quả khám, chẩn đoán sơ bộ, dịch vụ tại phòng, chỉ định CLS) → kết quả Lab / CĐHA tô màu Vàng / Xanh / Đỏ → đơn thuốc (cảnh báo tồn kho) → chốt ca; màn hình hàng đợi của Bác sĩ với số phiếu, giờ gọi và nút "Gọi" / "Bắt đầu" trên từng phiếu (phím tắt "Gọi số tiếp theo"); nút mở lại hồ sơ.
- [ ] **5.3.4** Hàng đợi Cận lâm sàng: chỉ hiện phiếu đã nộp tiền; nút "Gọi" / "Gọi lại" trên từng phiếu (phím tắt "Gọi số tiếp theo"), bắt đầu cả phiếu, "Đã lấy mẫu", form nhập chỉ số theo gói, form CĐHA multipart, huy hiệu liên phòng.
- [ ] **5.3.5** Thu ngân: 3 mục (chờ thu phí khám / chờ thu tiền CLS / chờ thanh toán cuối ca), bảng kê hóa đơn dịch vụ (giảm giá từng hóa đơn, xác nhận thanh toán, **in phiếu số thứ tự**, in phiếu thu, thu công nợ, hoàn tiền) và màn hình **Hóa đơn thuốc nháp** (tự có khi Bác sĩ chốt ca có đơn; sửa số lượng khách mua, xác nhận thanh toán & xuất thuốc, hoặc hủy nháp và in đơn cho khách mua ngoài).
- [ ] **5.3.6** Quản trị (ADMIN): tạo nhân viên kèm hồ sơ chuyên môn Bác sĩ, gán nhiều vai trò, khóa / ngừng; đổi giá dịch vụ / thuốc theo ngày hiệu lực và xem lịch sử giá; màn hình báo cáo đọc `/api/v1/reports/**`.

> **Hướng dẫn Kiểm thử Task 5.3:**
> 1. Thao tác trọn vẹn luồng Đặt lịch → Tiếp đón → Khám → Thanh toán dịch vụ → (tùy chọn) Mua thuốc trên giao diện.
> 2. **Kết quả kỳ vọng:** Toast thông báo rõ ràng, không lỗi console JS.

---

### Task 5.4: Kiểm thử Tích hợp Luồng Chuẩn (Happy Path E2E Test)
- **Người thực hiện:** Cả nhóm (Hiển, Khởi, Linh)
- **Mục tiêu:** Kiểm thử xuyên suốt một ca khám thực tế từ A đến Z với dữ liệu demo.
- [ ] **5.4.1** Bước 1: Chủ nuôi `khach_lan` đặt lịch cho mèo Lu lúc 09:00 ngày khám trên Web Portal → `PENDING`.
- [ ] **5.4.2** Bước 2: Lễ tân duyệt lịch → `CONFIRMED`.
- [ ] **5.4.3** Bước 3: Đúng ngày, Lễ tân bấm Check-in (không cân đo), chọn Bác sĩ Tiến (P101, gợi ý vì đang 0 người chờ) → ca `WAITING`, hóa đơn phí khám 100.000 `PENDING`; lịch hẹn tự chuyển `CHECKED_IN` qua sự kiện. Màn hình Bác sĩ **chưa thấy** mèo Lu.
- [ ] **5.4.4** Bước 4: Khách nộp phí khám 100.000 → hệ thống in **phiếu P101 – số 001**, mèo Lu xuất hiện trong hàng đợi Bác sĩ Tiến → Bác sĩ bấm "Gọi số tiếp theo", màn hình sảnh gọi số 001.
- [ ] **5.4.5** Bước 5: Bác sĩ bấm "Bắt đầu" (phiếu `IN_SERVICE`), cân 4,6 kg, đo 39,2°C, chỉ định CBC + X-quang (2 hóa đơn 250.000 và 180.000) → ca `WAITING_RESULTS`, Bác sĩ `AVAILABLE`; phòng Lab / CĐHA **chưa thấy** ca.
- [ ] **5.4.6** Bước 6: Khách nộp 430.000 → in phiếu **Xét nghiệm số 001** và **CĐHA số 001**; KTV Lab gọi, lấy mẫu, bấm "Đã lấy mẫu", nhập 4 chỉ số → KTV CĐHA gọi, chụp X-quang, nhập kết luận và tải ảnh.
- [ ] **5.4.7** Bước 7: Ca `RESULTS_READY`, hệ thống phát **phiếu ưu tiên** cho Bác sĩ Tiến (không thu tiền) → Bác sĩ "Gọi số tiếp theo", bấm "Bắt đầu GĐ 2", cho tẩy giun tại phòng (50.000, làm ngay không thu trước), kê 10 viên Clavamox, ghi chẩn đoán xác định, chốt chuyên môn → `WAITING_PAYMENT`; quầy thuốc tự có **hóa đơn thuốc nháp** 10 viên.
- [ ] **5.4.8** Bước 8: Thu ngân xác nhận thanh toán **hóa đơn tẩy giun 50.000đ** (3 hóa đơn còn lại đã thu trước, tổng dịch vụ 580.000đ) → **ca khám `COMPLETED` ngay**, dữ liệu vào lịch sử bệnh án.
- [ ] **5.4.9** Bước 9 (tùy chọn): Khách mua thuốc tại phòng khám → Thu ngân mở hóa đơn nháp **157.500đ** (10 × 15.000 × 1,05) → xác nhận thanh toán & xuất thuốc → hóa đơn thuốc `PAID`, `medicine_stocks` Clavamox 200 → 190, có dòng `EXPORT_SALE -10`. *(Biến thể: khách mua ngoài → hủy hóa đơn nháp (`CANCELLED`), in đơn thuốc, kho không đổi, ca vẫn `COMPLETED`.)*
- [ ] **5.4.10** Bước 10: ADMIN mở báo cáo ngày → dịch vụ 580.000, thuốc 157.500 (khớp hai VIEW); `queue_ticket_histories` có đủ 5 phiếu `DONE` của ca.

> **Hướng dẫn Kiểm thử Task 5.4:**
> 1. Thực hiện 10 bước trên trình duyệt, đối chiếu CSDL và Redis sau mỗi bước.
> 2. **Kết quả kỳ vọng:** không lỗi 500; doanh thu dịch vụ hôm đó (`v_service_invoice_amounts`, `PAID`) = 580.000 (khám 100.000 + CBC 250.000 + X-quang 180.000 + tẩy giun 50.000; hóa đơn `REFUNDED` không tính); doanh thu thuốc (`v_medicine_invoice_amounts`, `PAID`) = 157.500 (hoặc 0 ở biến thể mua ngoài).

---

### Task 5.5: Bộ Kịch bản Kiểm thử 20 Tình huống Ngoại lệ (EX-01 → EX-20)
- **Người thực hiện:** Cả nhóm (Hiển, Khởi, Linh)
- **Mục tiêu:** Chứng minh hệ thống xử lý đúng mọi ngoại lệ theo `TONG_HOP_NGOAI_LE_VA_XU_LY_HE_THONG.md` v4.0.
- [ ] **5.5.1 [EX-01]** Lịch `CONFIRMED` quá `start_time + 30'` chưa check-in → tự chuyển `NO_SHOW`, lịch sử `changed_by_user_id = NULL`, khung giờ được giải phóng.
- [ ] **5.5.2 [EX-02]** Khách vãng lai → check-in với `appointmentId = null`, ca `WAITING`, hóa đơn phí khám `PENDING`; nộp phí → phiếu `DOCTOR`.
- [ ] **5.5.3 [EX-03]** Khách bỏ về khi đang chờ → `CANCELLED`, lý do trong `pet_visit_status_histories.notes`; phiếu bị xóa khỏi Sorted Set và ghi `queue_ticket_histories` `CANCELLED`, người phía sau lên một bậc; phí khám đã nộp giữ `PAID` (không hoàn), chưa nộp thì hóa đơn `CANCELLED`.
- [ ] **5.5.4 [EX-04]** Ca cấp cứu → `is_emergency = true`, **phát phiếu `priority = 2` ngay không cần nộp tiền** (cả phiếu Lab / CĐHA khi chỉ định), lên đầu danh sách chờ phân công, đầu hàng đợi Bác sĩ và hàng đợi Lab / CĐHA; các hóa đơn thu khi chốt ca; gọi ca khác khi khách vắng thì ca cấp cứu vẫn giữ ưu tiên và cảnh báo đỏ.
- [ ] **5.5.5 [EX-05]** Xếp ca mới vào hàng đợi Bác sĩ đang có ca vừa có kết quả → `200 OK`, phiếu `priority = 1` của ca có kết quả vẫn đứng đầu và được gọi trước.
- [ ] **5.5.6 [EX-06]** Vắng mặt khi gọi vào Lab / CĐHA → KTV bấm `…/queue-tickets/{id}/call` ở phiếu khác; phiếu vắng giữ `WAITING`, dịch vụ giữ `PENDING`, giữ nguyên vị trí (không ghi lịch sử), thông báo ứng dụng (không SMS).
- [ ] **5.5.7 [EX-07]** Khách quay lại sau khi vắng → KTV bấm `call` lại ở đúng phiếu đó, sau đó `start` → phiếu `IN_SERVICE`, dịch vụ `IN_PROGRESS`.
- [ ] **5.5.8 [EX-08]** Hủy 1 dịch vụ CLS → dịch vụ `CANCELLED`; hóa đơn: chưa nộp → `CANCELLED`, khách tự hủy → giữ `PAID`, phòng khám không làm được → `REFUNDED`; dịch vụ còn lại xong → ca `RESULTS_READY`.
- [ ] **5.5.9 [EX-09]** CĐHA gọi khi Lab chưa bấm "Đã lấy mẫu" → huy hiệu `SAMPLING`; CĐHA `call` phiếu khác, thú cưng sang thì `call` lại.
- [ ] **5.5.10 [EX-10]** Bác sĩ gọi số (ca `WAITING` hoặc `RESULTS_READY`) nhưng khách vắng → `…/queue-tickets/{id}/call` ở phiếu khác, ca vắng giữ trạng thái, phiếu giữ vị trí, Bác sĩ vẫn `AVAILABLE`.
- [ ] **5.5.11 [EX-11]** Khách bỏ về (ở `WAITING_RESULTS` hoặc `RESULTS_READY`) → `abandon`: dịch vụ chưa làm hủy (đã nộp thì giữ `PAID`, không hoàn), phiếu chờ `CANCELLED`, hóa đơn đã làm mà chưa thu (ca cấp cứu) giữ `PENDING` (công nợ), ca `COMPLETED`; lần sau thu được qua Task 3.9.
- [ ] **5.5.12 [EX-12]** Chốt ca khi thiếu chẩn đoán → `400 CLIN_1307`.
- [ ] **5.5.13 [EX-13]** Kê vượt tồn kho → lưu đơn thành công kèm `stockWarnings` (không chặn).
- [ ] **5.5.14 [EX-14]** Giảm giá vượt số tiền của một hóa đơn (dịch vụ hoặc thuốc) → `400 BILL_1402`.
- [ ] **5.5.15 [EX-15]** Thiếu kho đúng lúc xác nhận bán thuốc → `409 PHARM_1406`, rollback toàn bộ, hóa đơn thuốc giữ `PENDING`, tồn kho không đổi; Thu ngân sửa hóa đơn (giảm số lượng) rồi xác nhận lại thành công, hoặc hủy để khách mua ngoài.
- [ ] **5.5.16 [EX-16]** Bán trùng: sự kiện `PrescriptionCreatedEvent` gửi lại không tạo hóa đơn thứ hai (`medicine_invoices.prescription_id` UNIQUE); xác nhận lại hóa đơn đã `PAID` → `409 BILL_1403`; bấm đúp đồng thời → một lần thành công, lần kia `409 SYS_1005`.
- [ ] **5.5.17 [EX-17]** Khóa `bs_mai` khi hàng đợi của bác sĩ còn 2 phiếu → `UserStatusChangedEvent` → clinical gắn cờ hàng đợi, Lễ tân nhận cảnh báo; xếp ca mới cho `bs_mai` → `409 CLIN_1316`; Lễ tân chuyển 2 phiếu sang `bs_an` (giữ số, giữ `score`); `bs_mai` đăng nhập → `401 AUTH_1107`.
- [ ] **5.5.18 [EX-18]** Dừng RabbitMQ (`docker stop rabbitmq`), thu phí khám một ca → `200 OK`, hóa đơn `PAID`, dòng outbox giữ `PENDING`, chưa có phiếu; bật lại → trong vài giây có phiếu, đúng một phiếu. Dừng Redis → API hàng đợi trả `503 CLIN_1318`, check-in / thu tiền vẫn chạy; bật lại → `QueueReconcileJob` phát bù phiếu còn thiếu; xóa sạch Redis (`FLUSHALL`) rồi chạy `QueueRebuildJob` → hàng đợi dựng lại từ CSDL đúng thứ tự.
- [ ] **5.5.19 [EX-19]** Gửi trùng sự kiện (đặt lại dòng outbox về `PENDING`) cho `ServiceInvoicePaidEvent`, `PrescriptionCreatedEvent`, `MedicineInvoicePaidEvent` → không thêm phiếu, không thêm hóa đơn nháp, doanh thu báo cáo không đổi; `processed_events` mỗi consumer một dòng.
- [ ] **5.5.20 [EX-20]** ADMIN đổi giá khám 100.000 → 120.000 hiệu lực từ ngày mai → ca check-in hôm nay vẫn 100.000; hôm sau check-in mới 120.000; hóa đơn đã lập giữ giá cũ; `GET /api/v1/catalog/services/$S_EXAM/prices` trả cả hai dòng. Đổi giá Clavamox khi đang có hóa đơn nháp `PENDING` → lúc xác nhận thanh toán đơn giá cập nhật theo giá hiện hành; hóa đơn đã `PAID` không đổi.

> **Hướng dẫn Kiểm thử Task 5.5:**
> 1. Chạy từng kịch bản theo [TONG_HOP_NGOAI_LE_VA_XU_LY_HE_THONG.md](TONG_HOP_NGOAI_LE_VA_XU_LY_HE_THONG.md).
> 2. **Kết quả kỳ vọng:** 20/20 tình huống được phát hiện và xử lý đúng mã lỗi, ghi lịch sử đầy đủ, dữ liệu tiền, kho, hàng đợi và báo cáo toàn vẹn.

---

## BẢNG MA TRẬN PHÂN CÔNG & TIẾN ĐỘ THỰC THI (TASK TRACKING MATRIX)

| Mã Task | Tên Nhiệm vụ trọng tâm | Thành viên chính | FR / Ngoại lệ liên quan | Tình trạng |
| :---: | :--- | :---: | :---: | :---: |
| **T1.1 - T1.3** | Multi-Module (9 module), Docker Compose (MySQL 5 CSDL, Redis, RabbitMQ), CSDL 52 bảng + dữ liệu demo UUID, Common-Library (Auto-Configuration, Outbox, consumer idempotent) | Hiển, Khởi | NFR-07, NFR-08, NFR-09 | `[ ] Chưa xong` |
| **T1.4 - T1.5** | Service Registry (Eureka :8761) & API Gateway (:8080, trả 401) | Khởi | NFR-02, NFR-03 | `[ ] Chưa xong` |
| **T2.1 - T2.4** | `auth-service` (:8081): BCrypt, JWT nhiều vai trò, Refresh Token Rotation (lưu hash), hồ sơ người dùng / nhân sự / Bác sĩ, khóa – ngừng | Khởi | FR-01, FR-02, FR-09, NFR-02, NFR-03 | `[ ] Chưa xong` |
| **T2.5 - T2.8** | `appointment-service` (:8082): Slot động, Đặt / duyệt / hủy lịch, No-Show | Hiển | FR-12 → FR-17, EX-01 | `[ ] Chưa xong` |
| **T3.1 - T3.3** | `clinical-service` (:8083): Danh mục + bảng giá có lịch sử, Thú cưng, Check-in + hóa đơn phí khám, Thu phí → outbox → phiếu trên Redis, Hàng đợi riêng từng Bác sĩ, Bắt đầu khám, sinh hiệu / hồ sơ khám | Khởi, Hiển | FR-03, FR-05 → FR-08, FR-10, FR-11, FR-18 → FR-29, EX-02 → EX-05 | `[ ] Chưa xong` |
| **T3.4 - T3.8** | `clinical-service`: Chỉ định + hóa đơn dịch vụ, thu tiền CLS → phiếu phòng, CLS song song (gọi theo từng dòng, gộp phiếu), phiếu ưu tiên, GĐ 2 | Hiển, Khởi | FR-30 → FR-50, FR-54, EX-06 → EX-12 | `[ ] Chưa xong` |
| **T3.9** | `clinical-service`: Thu tiền hóa đơn còn lại (dịch vụ tại phòng), hoàn tiền & hoàn tất ca khám | Hiển | FR-55 → FR-60, EX-11, EX-14 | `[ ] Chưa xong` |
| **T4.1 - T4.4** | Kê đơn (clinical); `billing-pharmacy-service` (:8084): danh mục thuốc + giá + tồn, hóa đơn thuốc nháp từ sự kiện, trừ kho nguyên tử, nhập kho | Hiển | FR-04, FR-51 → FR-53, FR-61 → FR-66, EX-13 → EX-16, EX-19, EX-20 | `[ ] Chưa xong` |
| **T4.5** | `reporting-service` (:8086): CSDL đọc từ sự kiện, API báo cáo | Khởi | FR-69, FR-70, NFR-09, NFR-10 | `[ ] Chưa xong` |
| **T5.1** | `notification-service` (:8085): WebSocket STOMP & Email theo sự kiện (17 sự kiện chuẩn) | Khởi | Thông báo cho FR-12 → FR-60 | `[ ] Chưa xong` |
| **T5.2 - T5.3** | Frontend React Vite: phân quyền 6 vai trò, ghép nối API | Linh | FR-67 → FR-70, NFR-01, NFR-05 | `[ ] Chưa xong` |
| **T5.4 - T5.5** | Kiểm thử E2E Happy Path & 20 ngoại lệ | Cả nhóm | Toàn bộ hệ thống, NFR-04, NFR-06, NFR-10 | `[ ] Chưa xong` |

---

## HƯỚNG DẪN CÁCH SỬ DỤNG FILE NÀY TRONG QUÁ TRÌNH LẬP TRÌNH

1. **Trước khi bắt đầu một Task:** Đọc kỹ mô tả, endpoints cần tạo, đối chiếu tên với Quy chuẩn mục 3.2 và Kiến trúc mục 5.
2. **Sau khi viết mã nguồn xong:** Thực hiện đúng các bước trong phần **"Hướng dẫn Kiểm thử"** của task đó, trên dữ liệu demo Task 1.2.3.
3. **Khi kiểm thử thành công:** Đổi `[ ]` thành `[x]` (ví dụ: `- [x] **1.1.1** Khởi tạo Git repository...`).
4. **Nếu gặp lỗi:** Tra bảng mã lỗi tại [QUY_CHUAN_THIET_KE_VA_LAP_TRINH_BACKEND_SPRINGBOOT.md](QUY_CHUAN_THIET_KE_VA_LAP_TRINH_BACKEND_SPRINGBOOT.md) (mục 5.1) và các ngoại lệ tại [TONG_HOP_NGOAI_LE_VA_XU_LY_HE_THONG.md](TONG_HOP_NGOAI_LE_VA_XU_LY_HE_THONG.md) để khắc phục trước khi chuyển task kế tiếp.

---

## PHỤ LỤC: THAY ĐỔI SO VỚI PHIÊN BẢN TRƯỚC

| Vị trí | Bản cũ | Bản mới | Lý do |
| :--- | :--- | :--- | :--- |
| Đầu tài liệu, 1.1 | Spring Boot "4.1.11" | Spring Boot 4.1.1, Spring Cloud 2025.1.2 | Không có bản 4.1.11 |
| 1.2, ma trận | 23 bảng, "20 khóa ngoại", clinical 12 bảng | 25 bảng, 25 khóa ngoại nội bộ, 2 VIEW, clinical 14 bảng | Lược đồ v3.0 (đếm từ `schema_init.sql`) |
| 1.2.3 (mới) | Test dùng `bs_tien`, id 2, 4, 5, 7, 8 không có trong seed | Thêm `seed_demo_data.sql` với bảng ID cố định | `schema_init.sql` chỉ có tài khoản admin |
| 1.3 | ApiResponse `{code: 1000}`, `error()`; 30 mã lỗi; 13 enum | Đúng cấu trúc Quy chuẩn; 38 mã lỗi chuỗi; 10 enum + `LabEvaluation`; Auto-Configuration | Khớp Quy chuẩn v3.0 |
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
| 3.3, 3.5, 5.3, 5.5 (cập nhật 13/11) | `call-next` + `skip` (Đẩy lùi 1 bậc, xếp sau người kế tiếp, `skip_count + 1`, `action = SKIPPED`); test 2b `skip` rồi "đẩy lùi ca #2 để trả lại thứ tự"; EX-04, EX-06, EX-07, EX-09, EX-10 dùng `skip` | Thêm `POST …/pet-visits/{id}/call` và `…/service-details/{id}/call` (gọi ca bất kỳ, không đổi thứ tự/trạng thái); `call-next` giữ làm phím tắt; đã xóa API `skip` và cột `skip_count`; CLS gộp dịch vụ cùng đợt khám, cùng phòng thành một ca; test 2b và EX-04/06/07/09/10 viết lại | Đẩy lùi 1 bậc làm hai ca đầu hàng đổi chỗ mãi mãi (ca thứ 3, 4 không được gọi) và làm ca cấp cứu mất ưu tiên |
| 4.3.1, 4.3.4, test 4.3 (cập nhật 13/11) | Số lượng mua ≤ số lượng kê, vượt → `400 PHARM_1410` | Số kê chỉ tham khảo; mua vượt **tồn kho** → `409 PHARM_1406` ngay lúc lập / sửa hóa đơn (lúc thu tiền vẫn kiểm tra lại bằng UPDATE nguyên tử, EX-15); bỏ mã `PHARM_1410` (còn 38 mã); response kèm `stockQuantity`, `minStockAlert` | Khách có thể cần nhiều hơn / ít hơn đơn; ràng buộc đúng là tồn kho |
| 1.2, 3.1–3.9, 5.1, 5.3, 5.4, 5.5, ma trận (cập nhật 16–17/11) | 25 bảng / 25 khóa ngoại; hóa đơn phí khám tạo ở `start-exam`; dịch vụ CLS tự vào hàng đợi; API gọi số `pet-visits/{id}/call`, `service-details/{id}/call`; `queue_order`; thu tiền một lần khi chốt ca (3 hóa đơn 530.000) | 27 bảng / 28 khóa ngoại; check-in lập hóa đơn phí khám, **nộp phí xong mới có phiếu**; thu tiền XN / CĐHA xong mới có phiếu phòng; API `queue-tickets/{id}/call`, `/start`, `call-next?queueType=`, `cashier/pending`; phiếu ưu tiên T06; kịch bản test đánh số lại (detail 3 = CBC, 4 = X-quang; phiếu 1–5) và thêm dịch vụ tẩy giun thu cuối ca; EX-03, EX-08, EX-11 kiểm tra không hoàn / `REFUNDED`; 10 sự kiện | Góp ý GVHD: tách quy trình thanh toán khỏi quy trình khám, tách dữ liệu hàng đợi khỏi hồ sơ khám |
| Toàn bộ (cập nhật 18/11, v4.0) | 27 bảng / 28 khóa ngoại / 2 VIEW, khóa `BIGINT`; ID số trong test (`/pet-visits/1`); `queue_tickets` trong MySQL; `X-User-Role`; giá, tồn kho trên `services` / `medicines`; sinh hiệu trên `pet_visits`; đơn thuốc ở billing, hóa đơn thuốc lập tay; 16 ngoại lệ | 52 bảng / 40 khóa ngoại / 4 VIEW, UUIDv7; biến `$VISIT_1`, `$U_TIEN`...; hàng đợi Redis + `queue_ticket_histories`; `X-User-Roles`; `service_prices`, `medicine_prices`, `medicine_stocks`; `vital_signs`, `medical_records`; đơn thuốc ở clinical, hóa đơn thuốc nháp từ `PrescriptionCreatedEvent`; Outbox (Task 1.3.5), Task 4.5 `reporting-service`; EX-17 → EX-20 | Nhận xét chi tiết của GVHD (6 rủi ro + góp ý khóa, hồ sơ người dùng, giá có lịch sử, tách `pet_visits`, hàng đợi) |
