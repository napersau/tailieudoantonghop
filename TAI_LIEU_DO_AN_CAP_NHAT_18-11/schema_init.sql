-- ==============================================================================
-- HỆ THỐNG QUẢN LÝ PHÒNG KHÁM THÚ Y - DATABASE INITIALIZATION SCRIPT (DDL & SEED)
-- PHIÊN BẢN 4.0 (18/11/2026) - THIẾT KẾ LẠI THEO NHẬN XÉT CHI TIẾT CỦA GVHD (Notes.pdf)
-- MÔ HÌNH KIẾN TRÚC: MICROSERVICES (DATABASE-PER-SERVICE) + CQRS READ MODEL
-- ==============================================================================
-- 5 Cơ sở dữ liệu logic (MySQL 8.0) + 1 Redis (hàng đợi đang chạy):
-- 1. pet_clinic_auth_db             : auth-service (:8081)             -  9 bảng
-- 2. pet_clinic_appointment_db      : appointment-service (:8082)      -  4 bảng
-- 3. pet_clinic_clinical_db         : clinical-service (:8083)         - 24 bảng
-- 4. pet_clinic_billing_pharmacy_db : billing-pharmacy-service (:8084) - 10 bảng
-- 5. pet_clinic_reporting_db        : reporting-service (:8086)        -  5 bảng
-- TỔNG CỘNG: 52 BẢNG (trong đó 4 bảng outbox_events + 4 bảng processed_events là hạ tầng)
-- Redis 7 (:6379): phiếu xếp hàng WAITING / IN_SERVICE (không lưu trong MySQL).
--
-- CÁC THAY ĐỔI CHÍNH SO VỚI PHIÊN BẢN 3.0 (mỗi mục ghi nhận xét GVHD tương ứng):
-- (1) KHÓA CHÍNH: bỏ BIGINT AUTO_INCREMENT đại trà.
--     - Thực thể nghiệp vụ (users, pets, pet_visits, services, medicines, hóa đơn, đơn thuốc...):
--       UUID phiên bản 7 lưu BINARY(16). UUIDv7 tăng dần theo thời gian nên chèn vào cuối
--       chỉ mục B+Tree (không phân mảnh như UUIDv4), không lộ số lượng bản ghi, sinh được
--       ở tầng ứng dụng trước khi INSERT (gắn ngay vào sự kiện outbox).
--     - Dữ liệu đơn giản, nhiều dòng, chỉ thêm (lịch sử trạng thái, lịch sử giá, nhật ký kho,
--       kết quả từng chỉ số, outbox): BIGINT AUTO_INCREMENT.
--     - Danh mục tra cứu nhỏ (roles, species, service_categories, medicine_categories,
--       lab_test_items): SMALLINT AUTO_INCREMENT + cột code duy nhất.
-- (2) USER: tách users (tài khoản đăng nhập) / user_roles / user_profiles (thông tin chung)
--     / staff_profiles (hồ sơ nhân sự) / veterinarian_profiles (hồ sơ chuyên môn thú y)
--     / pet_owner_profiles (hồ sơ khách hàng). Quan hệ 1-1 dùng chung khóa chính user_id.
-- (3) THUỐC: medicines (thông tin, quy cách) / medicine_ingredients (thành phần, hàm lượng)
--     / medicine_prices (lịch sử giá có hiệu lực) / medicine_stocks (tồn kho, cập nhật liên tục).
-- (4) DỊCH VỤ: services (thông tin) / service_prices (lịch sử giá) / service_categories
--     (danh mục thay ENUM, kèm chính sách thu trước và loại hàng đợi).
-- (5) Bỏ quan hệ prescription_items <-> medicine_invoice_items. medicine_invoice_items trỏ thẳng
--     medicines; medicine_invoices chỉ giữ prescription_id (khóa ngoại logic).
-- (6) Tách pet_visits (hành chính - Lễ tân) / vital_signs (sinh hiệu - tiền trạm)
--     / medical_records (hồ sơ chuyên môn - Bác sĩ).
-- (7) HÀNG ĐỢI: chuyển phiếu đang chờ / đang phục vụ sang Redis (Lua script nguyên tử, không còn
--     khóa lạc quan trên queue_tickets). MySQL chỉ lưu queue_ticket_histories khi phiếu kết thúc.
-- (8) ĐƠN THUỐC: prescriptions, prescription_items chuyển về clinical-service (cùng hồ sơ khám).
--     Chốt ca -> PrescriptionCreatedEvent -> billing-pharmacy tự tạo hóa đơn thuốc nháp.
-- (9) ENUM: bỏ toàn bộ kiểu ENUM của MySQL. Danh sách mở rộng được -> bảng danh mục;
--     trạng thái vòng đời -> VARCHAR, kiểm tra hợp lệ bằng enum Java (@Enumerated STRING).
-- (10) NHẤT QUÁN PHÂN TÁN: bảng outbox_events trong mỗi CSDL phát sự kiện (Transactional Outbox),
--     processed_events ở bên nhận (chống xử lý trùng); xóa mềm dữ liệu danh mục, không xóa cứng.
-- (11) N+1 & BÁO CÁO: cột *_snapshot (tên Bác sĩ, chủ nuôi, thú cưng) cập nhật bất đồng bộ qua sự kiện;
--     reporting-service với CSDL đọc riêng (bảng phẳng doanh thu, lượt khám, hiệu suất Bác sĩ).
-- (12) TỆP ẢNH: imaging_attachments.file_key VARCHAR(255) (đường dẫn tương đối), URL ký tạm
--     sinh lúc trả về API; không lưu URL tuyệt đối.
--
-- NGUYÊN TẮC TOÀN VẸN DỮ LIỆU LIÊN DỊCH VỤ:
-- - Bảng cùng Service: ràng buộc FOREIGN KEY vật lý.
-- - Liên kết chéo Service: khóa ngoại logic BINARY(16) + Index, ghi chú "LFK: <db>.<bảng>".
--   Kiểm tra khi tạo bằng OpenFeign (chỉ đọc); bản ghi đích không bao giờ bị xóa cứng
--   (chỉ khóa / ngừng sử dụng) nên LFK cũ luôn tra được và hiển thị "Đã khóa" thay vì lỗi.
-- - Giá trị tiền thanh toán KHÔNG lưu trong CSDL giao dịch, được tính bằng VIEW.
--   Riêng CSDL reporting là mô hình đọc (read model) phi chuẩn hóa có chủ đích.
-- - Cột trạng thái VARCHAR: giá trị hợp lệ ghi ở chú thích, kiểm tra bằng enum Java.
-- ==============================================================================

-- Bắt buộc: client mysql trong entrypoint Docker mặc định dùng latin1,
-- thiếu dòng này tiếng Việt trong seed bị mã hóa 2 lần.
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci; -- cùng collation với các CSDL, tránh lỗi trộn collation khi JOIN chuỗi hằng

-- UUIDv7 cố định cho dữ liệu mẫu (để seed của các CSDL tham chiếu chéo được nhau).
-- Ứng dụng sinh UUIDv7 bằng Hibernate @UuidGenerator(style = VERSION_7).
SET @u_admin      = UUID_TO_BIN('019a9442-d800-7729-87cc-fbb1ceda8817');
SET @s_exam       = UUID_TO_BIN('019a9442-d801-7f29-8461-94154bf4727d');
SET @s_vac7       = UUID_TO_BIN('019a9442-d802-7c82-b68c-5a5bee6bd708');
SET @s_vac4       = UUID_TO_BIN('019a9442-d803-72f9-b7bc-77684d1d19b3');
SET @s_deworm     = UUID_TO_BIN('019a9442-d804-747b-9728-edfcf134959d');
SET @s_cbc        = UUID_TO_BIN('019a9442-d805-75c3-86cd-1efc7485f972');
SET @s_us         = UUID_TO_BIN('019a9442-d806-7fe9-aab6-60023c504ab3');
SET @s_xray       = UUID_TO_BIN('019a9442-d807-7b9e-8308-4bc685f447d1');
SET @m_amox       = UUID_TO_BIN('019a9442-d808-7dbc-a250-489154c55826');
SET @m_vang       = UUID_TO_BIN('019a9442-d809-7ea7-8e4b-17b6ee239ddb');
SET @m_pure       = UUID_TO_BIN('019a9442-d80a-7134-8c54-49a51bfb8607');
SET @m_dron       = UUID_TO_BIN('019a9442-d80b-7e34-a82b-c3f03b8b1ef2');


-- ==============================================================================
-- PHẦN 1: PET_CLINIC_AUTH_DB (AUTH-SERVICE :8081) - 9 BẢNG
-- ==============================================================================
CREATE DATABASE IF NOT EXISTS pet_clinic_auth_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE pet_clinic_auth_db;

-- 1. ROLES (DANH MỤC VAI TRÒ - THAY ENUM)
-- Thêm vai trò mới chỉ cần INSERT, không ALTER TABLE. is_system = TRUE: vai trò lõi, không cho xóa.
CREATE TABLE IF NOT EXISTS roles (
    id SMALLINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(255) NULL,
    is_system BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- 2. USERS (TÀI KHOẢN ĐĂNG NHẬP - CHỈ THÔNG TIN XÁC THỰC)
-- status: ACTIVE | LOCKED | INACTIVE. Không xóa cứng tài khoản (xóa mềm = INACTIVE).
CREATE TABLE IF NOT EXISTS users (
    id BINARY(16) PRIMARY KEY, -- UUIDv7
    username VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    last_login_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    version BIGINT NOT NULL DEFAULT 0
);
CREATE INDEX idx_users_status ON users(status);

-- 3. USER_ROLES (TÀI KHOẢN - VAI TRÒ, NHIỀU - NHIỀU)
-- Ví dụ một Bác sĩ kiêm Quản trị viên. JWT mang danh sách vai trò.
CREATE TABLE IF NOT EXISTS user_roles (
    user_id BINARY(16) NOT NULL,
    role_id SMALLINT NOT NULL,
    assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, role_id),
    CONSTRAINT fk_ur_user FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT fk_ur_role FOREIGN KEY (role_id) REFERENCES roles(id)
);
CREATE INDEX idx_ur_role ON user_roles(role_id);

-- 4. USER_PROFILES (THÔNG TIN CÁ NHÂN CHUNG CỦA MỌI NGƯỜI DÙNG, 1-1 VỚI USERS)
-- gender: MALE | FEMALE | OTHER. avatar_key: đường dẫn tương đối tệp ảnh đại diện.
CREATE TABLE IF NOT EXISTS user_profiles (
    user_id BINARY(16) PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    phone_number VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(150) NULL UNIQUE,
    gender VARCHAR(10) NULL,
    date_of_birth DATE NULL,
    address VARCHAR(255) NULL,
    avatar_key VARCHAR(255) NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_up_user FOREIGN KEY (user_id) REFERENCES users(id)
);

-- 5. STAFF_PROFILES (HỒ SƠ NHÂN SỰ - CHỈ NHÂN VIÊN PHÒNG KHÁM, 1-1 VỚI USERS)
-- employment_type: FULL_TIME | PART_TIME. room_number: phòng làm việc cố định (Bác sĩ / KTV).
CREATE TABLE IF NOT EXISTS staff_profiles (
    user_id BINARY(16) PRIMARY KEY,
    employee_code VARCHAR(20) NOT NULL UNIQUE,
    citizen_id VARCHAR(20) NULL UNIQUE, -- Số CCCD
    position_title VARCHAR(100) NOT NULL, -- Chức danh: Bác sĩ thú y, Lễ tân, KTV xét nghiệm...
    department VARCHAR(100) NULL, -- Bộ phận: Khám bệnh, Xét nghiệm, CĐHA, Tiếp đón...
    room_number VARCHAR(20) NULL,
    employment_type VARCHAR(20) NOT NULL DEFAULT 'FULL_TIME',
    hire_date DATE NOT NULL,
    termination_date DATE NULL,
    emergency_contact_name VARCHAR(150) NULL,
    emergency_contact_phone VARCHAR(20) NULL,
    notes TEXT NULL,
    CONSTRAINT fk_sp_user FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT chk_sp_dates CHECK (termination_date IS NULL OR termination_date >= hire_date)
);
CREATE INDEX idx_sp_room ON staff_profiles(room_number);

-- 6. VETERINARIAN_PROFILES (HỒ SƠ CHUYÊN MÔN THÚ Y, 1-1 VỚI STAFF_PROFILES)
-- Bắt buộc với vai trò VETERINARIAN; tùy chọn với Bác sĩ / KTV Xét nghiệm, CĐHA có chứng chỉ.
CREATE TABLE IF NOT EXISTS veterinarian_profiles (
    user_id BINARY(16) PRIMARY KEY,
    license_number VARCHAR(50) NOT NULL UNIQUE, -- Số chứng chỉ hành nghề thú y
    license_issued_date DATE NOT NULL,
    license_issued_by VARCHAR(150) NOT NULL, -- Cơ quan cấp (Chi cục Chăn nuôi và Thú y...)
    license_expiry_date DATE NULL,
    academic_degree VARCHAR(50) NOT NULL, -- Bác sĩ thú y / Thạc sĩ / Tiến sĩ
    specialty VARCHAR(150) NULL, -- Nội khoa, Ngoại khoa, Da liễu, Chẩn đoán hình ảnh...
    graduated_from VARCHAR(150) NULL,
    career_start_year SMALLINT NULL, -- Số năm kinh nghiệm = năm hiện tại - career_start_year
    biography TEXT NULL, -- Giới thiệu hiển thị cho khách khi đặt lịch
    CONSTRAINT fk_vp_staff FOREIGN KEY (user_id) REFERENCES staff_profiles(user_id),
    CONSTRAINT chk_vp_license CHECK (license_expiry_date IS NULL OR license_expiry_date > license_issued_date)
);

-- 7. PET_OWNER_PROFILES (HỒ SƠ KHÁCH HÀNG / CHỦ NUÔI, 1-1 VỚI USERS)
-- registered_channel: ONLINE | AT_CLINIC. preferred_contact: PHONE | EMAIL | APP.
CREATE TABLE IF NOT EXISTS pet_owner_profiles (
    user_id BINARY(16) PRIMARY KEY,
    customer_code VARCHAR(20) NOT NULL UNIQUE,
    registered_channel VARCHAR(20) NOT NULL DEFAULT 'ONLINE',
    preferred_contact VARCHAR(20) NOT NULL DEFAULT 'PHONE',
    notes TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pop_user FOREIGN KEY (user_id) REFERENCES users(id)
);

-- 8. REFRESH_TOKENS (PHIÊN ĐĂNG NHẬP & XOAY VÒNG TOKEN)
-- Chỉ lưu giá trị băm SHA-256 của token (lộ CSDL không dùng lại được token). BIGINT: dữ liệu nhiều, đơn giản.
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BINARY(16) NOT NULL,
    token_hash CHAR(64) NOT NULL UNIQUE,
    expiry_date TIMESTAMP NOT NULL,
    revoked BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_refresh_tokens_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_id);

-- 9. OUTBOX_EVENTS (TRANSACTIONAL OUTBOX) - cấu trúc giống nhau ở mọi CSDL phát sự kiện
-- Ghi trong CÙNG giao dịch với thay đổi nghiệp vụ; OutboxRelay đọc PENDING, gửi RabbitMQ,
-- đánh dấu PUBLISHED (at-least-once). status: PENDING | PUBLISHED | FAILED.
-- auth phát: UserProfileUpdatedEvent, UserStatusChangedEvent.
CREATE TABLE IF NOT EXISTS outbox_events (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    event_id BINARY(16) NOT NULL UNIQUE, -- UUIDv7, consumer dùng để chống xử lý trùng
    aggregate_type VARCHAR(50) NOT NULL, -- USER, PET, VISIT, SERVICE_INVOICE...
    aggregate_id BINARY(16) NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    routing_key VARCHAR(100) NOT NULL,
    payload JSON NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    attempt_count INT NOT NULL DEFAULT 0,
    next_attempt_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_error VARCHAR(500) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    published_at TIMESTAMP NULL
);
CREATE INDEX idx_outbox_pending ON outbox_events(status, next_attempt_at, id);

-- Seed auth-service
INSERT INTO roles (code, name, description, is_system) VALUES
('ADMIN', 'Quản trị viên', 'Toàn quyền cấu hình hệ thống, quản lý danh mục, bảng giá và xem báo cáo', TRUE),
('VETERINARIAN', 'Bác sĩ thú y khám chính', 'Khám lâm sàng, chỉ định cận lâm sàng, chẩn đoán xác định và kê đơn', TRUE),
('RECEPTIONIST', 'Lễ tân / Thu ngân', 'Tiếp đón, phân công bác sĩ, thu ngân và bán thuốc', TRUE),
('LAB_TECHNICIAN', 'Bác sĩ / KTV Xét nghiệm', 'Tiếp nhận mẫu bệnh phẩm, phân tích và nhập chỉ số kết quả', TRUE),
('IMAGING_TECHNICIAN', 'Bác sĩ / KTV Chẩn đoán hình ảnh', 'Siêu âm, chụp X-quang, tải tệp ảnh và kết luận hình thái học', TRUE),
('PET_OWNER', 'Chủ thú cưng', 'Đặt lịch trực tuyến, theo dõi hồ sơ bệnh án và đơn thuốc', TRUE);

-- Tài khoản Admin mặc định (mật khẩu: Admin@123, BCrypt strength 12 - đã kiểm tra bằng bcrypt.checkpw ngày 12/11)
INSERT INTO users (id, username, password_hash, status) VALUES
(@u_admin, 'admin', '$2a$12$QfxJtMwsg2Wd72ZkvcQ.BeADCJqgMjJ7OPeBqNkj1um98Jt/dcBPG', 'ACTIVE');
INSERT INTO user_roles (user_id, role_id) SELECT @u_admin, id FROM roles WHERE code = 'ADMIN';
INSERT INTO user_profiles (user_id, full_name, phone_number, email) VALUES
(@u_admin, 'Quản trị viên hệ thống', '0901234567', 'admin@vetclinic.com');
INSERT INTO staff_profiles (user_id, employee_code, position_title, department, hire_date) VALUES
(@u_admin, 'NV0001', 'Quản trị hệ thống', 'Ban quản lý', '2026-01-01');


-- ==============================================================================
-- PHẦN 2: PET_CLINIC_APPOINTMENT_DB (APPOINTMENT-SERVICE :8082) - 4 BẢNG
-- ==============================================================================
CREATE DATABASE IF NOT EXISTS pet_clinic_appointment_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE pet_clinic_appointment_db;

-- 10. APPOINTMENTS (LỊCH HẸN KHÁM)
-- booking_channel: ONLINE | PHONE | WALK_IN. status: PENDING | CONFIRMED | CHECKED_IN | CANCELLED | NO_SHOW.
-- owner_id + *_snapshot: tránh gọi chéo N+1 khi liệt kê lịch theo chủ nuôi / theo ngày;
-- cập nhật bất đồng bộ khi nhận UserProfileUpdatedEvent, PetUpdatedEvent.
CREATE TABLE IF NOT EXISTS appointments (
    id BINARY(16) PRIMARY KEY, -- UUIDv7
    appointment_code VARCHAR(50) NOT NULL UNIQUE,
    pet_id BINARY(16) NOT NULL, -- LFK: clinical.pets
    owner_id BINARY(16) NOT NULL, -- LFK: auth.users (chủ nuôi tại thời điểm đặt)
    pet_name_snapshot VARCHAR(100) NOT NULL,
    owner_name_snapshot VARCHAR(150) NOT NULL,
    owner_phone_snapshot VARCHAR(20) NOT NULL,
    appointment_date DATE NOT NULL,
    start_time TIME NOT NULL, -- Giờ bắt đầu khung 30 phút
    reason TEXT NOT NULL,
    booking_channel VARCHAR(20) NOT NULL DEFAULT 'ONLINE',
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    version BIGINT NOT NULL DEFAULT 0
);
CREATE INDEX idx_appointments_slot ON appointments(appointment_date, start_time, status);
CREATE INDEX idx_appointments_pet ON appointments(pet_id);
CREATE INDEX idx_appointments_owner ON appointments(owner_id, appointment_date);

-- 11. APPOINTMENT_STATUS_HISTORIES (AUDIT TRAIL LỊCH HẸN)
CREATE TABLE IF NOT EXISTS appointment_status_histories (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    appointment_id BINARY(16) NOT NULL,
    from_status VARCHAR(20) NULL,
    to_status VARCHAR(20) NOT NULL,
    changed_by_user_id BINARY(16) NULL, -- LFK: auth.users (NULL = hệ thống tự quét NO_SHOW)
    notes TEXT NULL, -- Lý do hủy / từ chối / ghi chú
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ash_appointment FOREIGN KEY (appointment_id) REFERENCES appointments(id) ON DELETE CASCADE
);
CREATE INDEX idx_ash_appointment ON appointment_status_histories(appointment_id);
CREATE INDEX idx_ash_user ON appointment_status_histories(changed_by_user_id);

-- 12. OUTBOX_EVENTS (cấu trúc như mục 9)
-- appointment phát: AppointmentBookedEvent, AppointmentStatusChangedEvent, AppointmentNoShowEvent.
CREATE TABLE IF NOT EXISTS outbox_events (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    event_id BINARY(16) NOT NULL UNIQUE,
    aggregate_type VARCHAR(50) NOT NULL,
    aggregate_id BINARY(16) NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    routing_key VARCHAR(100) NOT NULL,
    payload JSON NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    attempt_count INT NOT NULL DEFAULT 0,
    next_attempt_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_error VARCHAR(500) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    published_at TIMESTAMP NULL
);
CREATE INDEX idx_outbox_pending ON outbox_events(status, next_attempt_at, id);

-- 13. PROCESSED_EVENTS (CHỐNG XỬ LÝ TRÙNG Ở BÊN NHẬN) - cấu trúc giống nhau ở mọi CSDL nhận sự kiện
-- INSERT trong cùng giao dịch với thay đổi do sự kiện gây ra; trùng khóa = đã xử lý -> bỏ qua.
CREATE TABLE IF NOT EXISTS processed_events (
    event_id BINARY(16) NOT NULL,
    consumer VARCHAR(100) NOT NULL, -- Tên listener (một service có thể có nhiều listener cho cùng sự kiện)
    processed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (event_id, consumer)
);


-- ==============================================================================
-- PHẦN 3: PET_CLINIC_CLINICAL_DB (CLINICAL-SERVICE :8083) - 24 BẢNG
-- ==============================================================================
CREATE DATABASE IF NOT EXISTS pet_clinic_clinical_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE pet_clinic_clinical_db;

-- ----- 3A. DANH MỤC -----

-- 14. SPECIES (DANH MỤC LOÀI)
CREATE TABLE IF NOT EXISTS species (
    id SMALLINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(255) NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- 15. SERVICE_CATEGORIES (NHÓM DỊCH VỤ - THAY ENUM services.category)
-- queue_type: DOCTOR | LABORATORY | IMAGING | NULL (NULL = làm tại phòng Bác sĩ, không xếp hàng riêng).
-- requires_prepayment: TRUE = thu tiền xong mới phát phiếu xếp hàng (khám, XN, CĐHA);
--                      FALSE = làm ngay tại phòng, thu khi chốt ca.
CREATE TABLE IF NOT EXISTS service_categories (
    id SMALLINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    queue_type VARCHAR(20) NULL,
    requires_prepayment BOOLEAN NOT NULL DEFAULT FALSE,
    display_order SMALLINT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- 16. SERVICES (THÔNG TIN DỊCH VỤ - KHÔNG CHỨA GIÁ)
-- Không xóa cứng: ngừng cung cấp = is_active FALSE (hóa đơn cũ vẫn tra được).
CREATE TABLE IF NOT EXISTS services (
    id BINARY(16) PRIMARY KEY, -- UUIDv7
    category_id SMALLINT NOT NULL,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    description TEXT NULL,
    unit VARCHAR(30) NOT NULL DEFAULT 'Lần', -- Đơn vị tính: lần, mũi, tư thế...
    estimated_minutes SMALLINT NULL, -- Thời gian thực hiện dự kiến
    preparation_notes VARCHAR(255) NULL, -- Ví dụ: nhịn ăn 8 giờ trước khi siêu âm
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_services_category FOREIGN KEY (category_id) REFERENCES service_categories(id)
);
CREATE INDEX idx_services_category ON services(category_id, is_active);

-- 17. SERVICE_PRICES (LỊCH SỬ GIÁ DỊCH VỤ)
-- Giá hiệu lực tại thời điểm t: effective_from <= t AND (effective_to IS NULL OR effective_to > t).
-- Đổi giá = đóng dòng đang mở (gán effective_to) + thêm dòng mới, trong cùng giao dịch.
-- Dòng giá không bao giờ bị sửa số tiền hay xóa.
CREATE TABLE IF NOT EXISTS service_prices (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    service_id BINARY(16) NOT NULL,
    price DECIMAL(12, 2) NOT NULL,
    vat_rate DECIMAL(4, 2) NOT NULL DEFAULT 0.00,
    effective_from DATETIME NOT NULL,
    effective_to DATETIME NULL, -- NULL = giá đang áp dụng
    change_reason VARCHAR(255) NULL,
    created_by BINARY(16) NOT NULL, -- LFK: auth.users (ADMIN)
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_sprice_service FOREIGN KEY (service_id) REFERENCES services(id),
    CONSTRAINT uq_sprice_from UNIQUE (service_id, effective_from),
    CONSTRAINT chk_sprice_price CHECK (price >= 0),
    CONSTRAINT chk_sprice_vat CHECK (vat_rate >= 0 AND vat_rate <= 1),
    CONSTRAINT chk_sprice_period CHECK (effective_to IS NULL OR effective_to > effective_from)
);
CREATE INDEX idx_sprice_lookup ON service_prices(service_id, effective_from, effective_to);

-- 18. LAB_TEST_ITEMS (DANH MỤC CHỈ SỐ XÉT NGHIỆM)
CREATE TABLE IF NOT EXISTS lab_test_items (
    id SMALLINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    unit VARCHAR(30) NOT NULL,
    description VARCHAR(255) NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- 19. SERVICE_LAB_TEST_ITEMS (BẢNG NỐI: GÓI XÉT NGHIỆM GỒM NHỮNG CHỈ SỐ NÀO)
CREATE TABLE IF NOT EXISTS service_lab_test_items (
    service_id BINARY(16) NOT NULL,
    lab_test_item_id SMALLINT NOT NULL,
    PRIMARY KEY (service_id, lab_test_item_id),
    CONSTRAINT fk_slti_service FOREIGN KEY (service_id) REFERENCES services(id),
    CONSTRAINT fk_slti_item FOREIGN KEY (lab_test_item_id) REFERENCES lab_test_items(id)
);

-- 20. LAB_TEST_REFERENCE_RANGES (KHOẢNG THAM CHIẾU THEO LOÀI)
-- Khóa chính tự nhiên (chỉ số, loài): mỗi cặp có đúng 1 khoảng, không cần khóa đại diện.
CREATE TABLE IF NOT EXISTS lab_test_reference_ranges (
    lab_test_item_id SMALLINT NOT NULL,
    species_id SMALLINT NOT NULL,
    min_value DECIMAL(8, 2) NOT NULL,
    max_value DECIMAL(8, 2) NOT NULL,
    PRIMARY KEY (lab_test_item_id, species_id),
    CONSTRAINT fk_ltrr_item FOREIGN KEY (lab_test_item_id) REFERENCES lab_test_items(id),
    CONSTRAINT fk_ltrr_species FOREIGN KEY (species_id) REFERENCES species(id),
    CONSTRAINT chk_ltrr_range CHECK (min_value <= max_value)
);

-- ----- 3B. THÚ CƯNG & ĐỢT KHÁM -----

-- 21. PETS (HỒ SƠ THÚ CƯNG)
-- gender: MALE | FEMALE | UNKNOWN. Cân nặng hiện tại = vital_signs.weight_kg gần nhất.
-- owner_*_snapshot: hiển thị danh sách tiếp đón không cần gọi auth-service (cập nhật qua UserProfileUpdatedEvent).
-- Xóa mềm: deleted_at (hồ sơ khám cũ vẫn tham chiếu được).
CREATE TABLE IF NOT EXISTS pets (
    id BINARY(16) PRIMARY KEY, -- UUIDv7
    owner_id BINARY(16) NOT NULL, -- LFK: auth.users
    owner_name_snapshot VARCHAR(150) NOT NULL,
    owner_phone_snapshot VARCHAR(20) NOT NULL,
    species_id SMALLINT NOT NULL,
    pet_code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    breed VARCHAR(100) NULL,
    gender VARCHAR(10) NOT NULL DEFAULT 'UNKNOWN',
    date_of_birth DATE NULL,
    color VARCHAR(100) NULL,
    is_neutered BOOLEAN NOT NULL DEFAULT FALSE,
    microchip_number VARCHAR(30) NULL UNIQUE,
    identifying_characteristics TEXT NULL,
    allergies TEXT NULL, -- Tiền sử dị ứng thuốc (cảnh báo khi kê đơn)
    notes TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    CONSTRAINT fk_pets_species FOREIGN KEY (species_id) REFERENCES species(id)
);
CREATE INDEX idx_pets_owner ON pets(owner_id);
CREATE INDEX idx_pets_owner_phone ON pets(owner_phone_snapshot);

-- 22. PET_VISITS (ĐỢT KHÁM - CHỈ THÔNG TIN HÀNH CHÍNH, LỄ TÂN NHẬP LÚC TIẾP ĐÓN)
-- status: WAITING | IN_PROGRESS | WAITING_RESULTS | RESULTS_READY | WAITING_PAYMENT | COMPLETED | CANCELLED.
-- Sinh hiệu ở vital_signs, nội dung chuyên môn ở medical_records, hàng đợi ở Redis.
CREATE TABLE IF NOT EXISTS pet_visits (
    id BINARY(16) PRIMARY KEY, -- UUIDv7
    visit_code VARCHAR(50) NOT NULL UNIQUE,
    pet_id BINARY(16) NOT NULL,
    appointment_id BINARY(16) NULL UNIQUE, -- LFK: appointment.appointments (NULL = khách vãng lai)
    doctor_id BINARY(16) NULL, -- LFK: auth.users (Bác sĩ được phân công)
    doctor_name_snapshot VARCHAR(150) NULL, -- Tránh N+1 khi liệt kê; cập nhật qua UserProfileUpdatedEvent
    receptionist_id BINARY(16) NOT NULL, -- LFK: auth.users (Lễ tân tiếp đón)
    is_emergency BOOLEAN NOT NULL DEFAULT FALSE,
    reason_for_visit TEXT NULL, -- Lý do đến khám do chủ nuôi khai với Lễ tân
    status VARCHAR(20) NOT NULL DEFAULT 'WAITING',
    checked_in_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    version BIGINT NOT NULL DEFAULT 0, -- Khóa lạc quan (đổi trạng thái đợt khám)
    CONSTRAINT fk_visits_pet FOREIGN KEY (pet_id) REFERENCES pets(id)
);
CREATE INDEX idx_visits_pet ON pet_visits(pet_id);
CREATE INDEX idx_visits_doctor_status ON pet_visits(doctor_id, status);
CREATE INDEX idx_visits_status_date ON pet_visits(status, checked_in_at);
CREATE INDEX idx_visits_receptionist ON pet_visits(receptionist_id);

-- 23. VITAL_SIGNS (SINH HIỆU / TIỀN TRẠM - CÓ THỂ ĐO NHIỀU LẦN TRONG MỘT ĐỢT KHÁM)
CREATE TABLE IF NOT EXISTS vital_signs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    visit_id BINARY(16) NOT NULL,
    weight_kg DECIMAL(5, 2) NULL,
    temperature_c DECIMAL(4, 1) NULL,
    heart_rate_bpm SMALLINT NULL,
    respiratory_rate_bpm SMALLINT NULL,
    body_condition_score TINYINT NULL, -- Thang 1 - 9
    mucous_membrane_color VARCHAR(30) NULL, -- Hồng, nhợt, vàng, tím...
    capillary_refill_sec DECIMAL(3, 1) NULL, -- Thời gian làm đầy mao mạch
    notes VARCHAR(255) NULL,
    recorded_by BINARY(16) NOT NULL, -- LFK: auth.users
    recorded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_vs_visit FOREIGN KEY (visit_id) REFERENCES pet_visits(id),
    CONSTRAINT chk_vs_weight CHECK (weight_kg IS NULL OR weight_kg > 0),
    CONSTRAINT chk_vs_temp CHECK (temperature_c IS NULL OR temperature_c BETWEEN 30 AND 45),
    CONSTRAINT chk_vs_bcs CHECK (body_condition_score IS NULL OR body_condition_score BETWEEN 1 AND 9)
);
CREATE INDEX idx_vs_visit ON vital_signs(visit_id, recorded_at);

-- 24. MEDICAL_RECORDS (HỒ SƠ KHÁM CHUYÊN MÔN - BÁC SĨ, 1-1 VỚI PET_VISITS)
-- Tạo khi Bác sĩ bắt đầu khám; khóa chỉnh sửa khi đợt khám COMPLETED.
CREATE TABLE IF NOT EXISTS medical_records (
    visit_id BINARY(16) PRIMARY KEY,
    anamnesis TEXT NULL, -- Bệnh sử, triệu chứng chủ nuôi kể
    clinical_findings TEXT NULL, -- Kết quả khám lâm sàng
    preliminary_diagnosis TEXT NULL, -- Chẩn đoán sơ bộ (pha 1)
    final_diagnosis TEXT NULL, -- Chẩn đoán xác định (pha 2, sau cận lâm sàng)
    treatment_plan TEXT NULL,
    doctor_advice TEXT NULL,
    follow_up_date DATE NULL, -- Hẹn tái khám
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    version BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT fk_mr_visit FOREIGN KEY (visit_id) REFERENCES pet_visits(id)
);

-- 25. PET_VISIT_STATUS_HISTORIES (AUDIT TRAIL ĐỢT KHÁM)
CREATE TABLE IF NOT EXISTS pet_visit_status_histories (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    visit_id BINARY(16) NOT NULL,
    from_status VARCHAR(20) NULL,
    to_status VARCHAR(20) NOT NULL,
    changed_by_user_id BINARY(16) NULL, -- LFK: auth.users (NULL = hệ thống tự chuyển)
    notes TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pvsh_visit FOREIGN KEY (visit_id) REFERENCES pet_visits(id) ON DELETE CASCADE
);
CREATE INDEX idx_pvsh_visit ON pet_visit_status_histories(visit_id);
CREATE INDEX idx_pvsh_user ON pet_visit_status_histories(changed_by_user_id);

-- ----- 3C. CHỈ ĐỊNH DỊCH VỤ & KẾT QUẢ -----

-- 26. VISIT_SERVICE_DETAILS (CHỈ ĐỊNH DỊCH VỤ - THUẦN CHUYÊN MÔN)
-- status: PENDING | IN_PROGRESS | COMPLETED | CANCELLED.
CREATE TABLE IF NOT EXISTS visit_service_details (
    id BINARY(16) PRIMARY KEY, -- UUIDv7
    visit_id BINARY(16) NOT NULL,
    service_id BINARY(16) NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    notes TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    version BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT fk_vsd_visit FOREIGN KEY (visit_id) REFERENCES pet_visits(id),
    CONSTRAINT fk_vsd_service FOREIGN KEY (service_id) REFERENCES services(id),
    CONSTRAINT chk_vsd_quantity CHECK (quantity > 0)
);
CREATE INDEX idx_vsd_visit ON visit_service_details(visit_id);
CREATE INDEX idx_vsd_service ON visit_service_details(service_id);

-- 27. VISIT_SERVICE_DETAIL_HISTORIES (AUDIT TRAIL TIẾN ĐỘ DỊCH VỤ)
-- action: ORDERED | START_PROCESSING | SAMPLE_COLLECTED | COMPLETED | CANCELLED.
CREATE TABLE IF NOT EXISTS visit_service_detail_histories (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    visit_service_detail_id BINARY(16) NOT NULL,
    from_status VARCHAR(20) NULL,
    to_status VARCHAR(20) NOT NULL,
    action VARCHAR(30) NOT NULL,
    changed_by_user_id BINARY(16) NOT NULL, -- LFK: auth.users
    reason TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_vsdh_vsd FOREIGN KEY (visit_service_detail_id) REFERENCES visit_service_details(id) ON DELETE CASCADE
);
CREATE INDEX idx_vsdh_detail ON visit_service_detail_histories(visit_service_detail_id);
CREATE INDEX idx_vsdh_user ON visit_service_detail_histories(changed_by_user_id);

-- 28. LAB_TEST_RESULTS (KẾT QUẢ TỪNG CHỈ SỐ XÉT NGHIỆM)
-- Giữ min/max snapshot: danh mục tham chiếu có thể đổi sau này. Đánh giá thấp/cao tính khi hiển thị.
CREATE TABLE IF NOT EXISTS lab_test_results (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    visit_service_detail_id BINARY(16) NOT NULL,
    lab_test_item_id SMALLINT NOT NULL,
    result_value DECIMAL(8, 2) NOT NULL,
    min_value_snapshot DECIMAL(8, 2) NOT NULL,
    max_value_snapshot DECIMAL(8, 2) NOT NULL,
    performed_by BINARY(16) NOT NULL, -- LFK: auth.users (LAB_TECHNICIAN)
    notes TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ltr_vsd FOREIGN KEY (visit_service_detail_id) REFERENCES visit_service_details(id),
    CONSTRAINT fk_ltr_item FOREIGN KEY (lab_test_item_id) REFERENCES lab_test_items(id),
    CONSTRAINT uq_ltr_vsd_item UNIQUE (visit_service_detail_id, lab_test_item_id)
);
CREATE INDEX idx_ltr_performer ON lab_test_results(performed_by);

-- 29. IMAGING_RESULTS (KẾT QUẢ CHẨN ĐOÁN HÌNH ẢNH)
CREATE TABLE IF NOT EXISTS imaging_results (
    id BINARY(16) PRIMARY KEY, -- UUIDv7
    visit_service_detail_id BINARY(16) NOT NULL UNIQUE,
    description TEXT NOT NULL,
    conclusion TEXT NOT NULL,
    performed_by BINARY(16) NOT NULL, -- LFK: auth.users (IMAGING_TECHNICIAN)
    performed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ir_vsd FOREIGN KEY (visit_service_detail_id) REFERENCES visit_service_details(id)
);
CREATE INDEX idx_ir_performer ON imaging_results(performed_by);

-- 30. IMAGING_ATTACHMENTS (TỆP ẢNH ĐÍNH KÈM)
-- file_key: đường dẫn tương đối trong kho lưu trữ, ví dụ imaging/2026/11/<uuid>.jpg.
-- URL trả cho client được sinh lúc đọc (URL có chữ ký, hết hạn sau 1 giờ); đổi nơi lưu không phải sửa CSDL.
CREATE TABLE IF NOT EXISTS imaging_attachments (
    id BINARY(16) PRIMARY KEY, -- UUIDv7 (không đoán được khi tải ảnh)
    imaging_result_id BINARY(16) NOT NULL,
    file_key VARCHAR(255) NOT NULL UNIQUE,
    original_file_name VARCHAR(255) NOT NULL,
    content_type VARCHAR(100) NOT NULL,
    file_size BIGINT NOT NULL,
    uploaded_by BINARY(16) NOT NULL, -- LFK: auth.users
    uploaded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ia_result FOREIGN KEY (imaging_result_id) REFERENCES imaging_results(id) ON DELETE CASCADE,
    CONSTRAINT chk_ia_size CHECK (file_size > 0)
);
CREATE INDEX idx_ia_result ON imaging_attachments(imaging_result_id);

-- 31. SERVICE_INVOICES (HÓA ĐƠN RIÊNG CHO TỪNG DỊCH VỤ, 1-1 VỚI CHỈ ĐỊNH)
-- payment_status: PENDING | PAID | CANCELLED | REFUNDED.
-- unit_price, vat_rate: snapshot từ service_prices đang hiệu lực lúc chỉ định (chứng từ không đổi
-- dù bảng giá đổi sau đó). Số tiền phải trả tính bằng VIEW, không lưu.
CREATE TABLE IF NOT EXISTS service_invoices (
    id BINARY(16) PRIMARY KEY, -- UUIDv7
    invoice_code VARCHAR(50) NOT NULL UNIQUE,
    visit_service_detail_id BINARY(16) NOT NULL UNIQUE,
    unit_price DECIMAL(12, 2) NOT NULL,
    vat_rate DECIMAL(4, 2) NOT NULL DEFAULT 0.00,
    discount_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    payment_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    cashier_id BINARY(16) NULL, -- LFK: auth.users (gán khi thu tiền)
    paid_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    version BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT fk_si_vsd FOREIGN KEY (visit_service_detail_id) REFERENCES visit_service_details(id),
    CONSTRAINT chk_si_price CHECK (unit_price >= 0),
    CONSTRAINT chk_si_vat CHECK (vat_rate >= 0 AND vat_rate <= 1),
    CONSTRAINT chk_si_discount CHECK (discount_amount >= 0)
);
CREATE INDEX idx_si_status_paid ON service_invoices(payment_status, paid_at);
CREATE INDEX idx_si_cashier ON service_invoices(cashier_id);

-- ----- 3D. ĐƠN THUỐC (CHUYỂN TỪ BILLING-PHARMACY VỀ - NHẬN XÉT #5) -----

-- 32. PRESCRIPTIONS (ĐƠN THUỐC - CHỈ ĐỊNH CHUYÊN MÔN CỦA BÁC SĨ)
-- Sửa được khi đợt khám IN_PROGRESS / RESULTS_READY; khóa khi chốt ca (phát PrescriptionCreatedEvent).
CREATE TABLE IF NOT EXISTS prescriptions (
    id BINARY(16) PRIMARY KEY, -- UUIDv7
    visit_id BINARY(16) NOT NULL UNIQUE, -- FK vật lý (cùng CSDL với đợt khám)
    doctor_notes TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pres_visit FOREIGN KEY (visit_id) REFERENCES pet_visits(id)
);

-- 33. PRESCRIPTION_ITEMS (CHI TIẾT THUỐC ĐƯỢC KÊ)
-- medicine_id trỏ sang danh mục thuốc của billing-pharmacy (LFK); tên, đơn vị chụp lại lúc kê
-- để bệnh án luôn đọc được mà không gọi chéo service.
CREATE TABLE IF NOT EXISTS prescription_items (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    prescription_id BINARY(16) NOT NULL,
    medicine_id BINARY(16) NOT NULL, -- LFK: billing_pharmacy.medicines
    medicine_name_snapshot VARCHAR(150) NOT NULL,
    unit_snapshot VARCHAR(30) NOT NULL,
    quantity INT NOT NULL, -- Số lượng Bác sĩ kê
    dosage VARCHAR(100) NOT NULL,
    frequency VARCHAR(100) NOT NULL,
    duration_days INT NOT NULL,
    instructions TEXT NULL,
    CONSTRAINT fk_pi_prescription FOREIGN KEY (prescription_id) REFERENCES prescriptions(id) ON DELETE CASCADE,
    CONSTRAINT uq_pi_prescription_medicine UNIQUE (prescription_id, medicine_id),
    CONSTRAINT chk_pi_quantity CHECK (quantity > 0),
    CONSTRAINT chk_pi_duration CHECK (duration_days > 0)
);
CREATE INDEX idx_pi_medicine ON prescription_items(medicine_id);

-- ----- 3E. LỊCH SỬ HÀNG ĐỢI (PHIẾU ĐANG CHẠY NẰM Ở REDIS - NHẬN XÉT #4) -----

-- 34. QUEUE_TICKET_HISTORIES (LỊCH SỬ PHIẾU XẾP HÀNG ĐÃ KẾT THÚC)
-- Phiếu WAITING / IN_SERVICE sống trong Redis. Khi phiếu DONE / CANCELLED, ghi 1 dòng ở đây trong
-- cùng giao dịch với cập nhật trạng thái đợt khám / dịch vụ; ticket_id UNIQUE -> ghi trùng bị chặn.
-- queue_type: DOCTOR | LABORATORY | IMAGING. final_status: DONE | CANCELLED.
-- priority: 2 = cấp cứu, 1 = quay lại với kết quả CLS, 0 = thường.
-- Dùng cho tra cứu, thống kê thời gian chờ (started_at - issued_at) và dựng lại Redis khi cần.
CREATE TABLE IF NOT EXISTS queue_ticket_histories (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    ticket_id BINARY(16) NOT NULL UNIQUE, -- UUIDv7 sinh lúc phát phiếu trên Redis
    queue_type VARCHAR(20) NOT NULL,
    service_date DATE NOT NULL,
    ticket_no INT NOT NULL,
    visit_id BINARY(16) NOT NULL,
    doctor_id BINARY(16) NULL, -- LFK: auth.users (chỉ phiếu DOCTOR)
    priority TINYINT NOT NULL DEFAULT 0,
    final_status VARCHAR(20) NOT NULL,
    issued_at TIMESTAMP NOT NULL,
    issued_by BINARY(16) NULL, -- LFK: auth.users (NULL = hệ thống tự phát)
    called_count SMALLINT NOT NULL DEFAULT 0,
    started_at TIMESTAMP NULL, -- Thời điểm chuyển IN_SERVICE
    ended_at TIMESTAMP NOT NULL,
    cancel_reason VARCHAR(255) NULL,
    CONSTRAINT fk_qth_visit FOREIGN KEY (visit_id) REFERENCES pet_visits(id),
    CONSTRAINT uq_qth_number UNIQUE (queue_type, service_date, ticket_no),
    CONSTRAINT chk_qth_priority CHECK (priority BETWEEN 0 AND 2)
);
CREATE INDEX idx_qth_visit ON queue_ticket_histories(visit_id);
CREATE INDEX idx_qth_date ON queue_ticket_histories(service_date, queue_type);

-- 35. QUEUE_TICKET_HISTORY_ITEMS (CÁC DỊCH VỤ XN / CĐHA THUỘC MỘT PHIẾU ĐÃ KẾT THÚC)
CREATE TABLE IF NOT EXISTS queue_ticket_history_items (
    history_id BIGINT NOT NULL,
    visit_service_detail_id BINARY(16) NOT NULL,
    PRIMARY KEY (history_id, visit_service_detail_id),
    CONSTRAINT fk_qthi_history FOREIGN KEY (history_id) REFERENCES queue_ticket_histories(id) ON DELETE CASCADE,
    CONSTRAINT fk_qthi_vsd FOREIGN KEY (visit_service_detail_id) REFERENCES visit_service_details(id)
);

-- ----- 3F. HẠ TẦNG SỰ KIỆN -----

-- 36. OUTBOX_EVENTS (cấu trúc như mục 9)
-- clinical phát: PetUpdatedEvent, VisitCheckedInEvent, ServiceInvoicePaidEvent, ServiceInvoiceRefundedEvent,
-- ParaclinicalResultsReadyEvent, PrescriptionCreatedEvent, VisitCompletedEvent, VisitCancelledEvent.
CREATE TABLE IF NOT EXISTS outbox_events (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    event_id BINARY(16) NOT NULL UNIQUE,
    aggregate_type VARCHAR(50) NOT NULL,
    aggregate_id BINARY(16) NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    routing_key VARCHAR(100) NOT NULL,
    payload JSON NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    attempt_count INT NOT NULL DEFAULT 0,
    next_attempt_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_error VARCHAR(500) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    published_at TIMESTAMP NULL
);
CREATE INDEX idx_outbox_pending ON outbox_events(status, next_attempt_at, id);

-- 37. PROCESSED_EVENTS (cấu trúc như mục 13)
-- clinical nhận: UserProfileUpdatedEvent, UserStatusChangedEvent (cập nhật snapshot, gỡ phân công Bác sĩ bị khóa).
CREATE TABLE IF NOT EXISTS processed_events (
    event_id BINARY(16) NOT NULL,
    consumer VARCHAR(100) NOT NULL,
    processed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (event_id, consumer)
);

-- VIEW tính tiền hóa đơn dịch vụ (không lưu giá trị dẫn xuất)
CREATE OR REPLACE VIEW v_service_invoice_amounts AS
SELECT si.id AS invoice_id,
       si.invoice_code,
       vsd.visit_id,
       s.id AS service_id,
       s.name AS service_name,
       sc.code AS category_code,
       vsd.quantity,
       si.unit_price,
       si.vat_rate,
       si.discount_amount,
       ROUND(vsd.quantity * si.unit_price, 2) AS amount_before_vat,
       ROUND(vsd.quantity * si.unit_price * si.vat_rate, 2) AS vat_amount,
       ROUND(vsd.quantity * si.unit_price * (1 + si.vat_rate) - si.discount_amount, 2) AS payable_amount,
       si.payment_status,
       si.paid_at
FROM service_invoices si
JOIN visit_service_details vsd ON vsd.id = si.visit_service_detail_id
JOIN services s ON s.id = vsd.service_id
JOIN service_categories sc ON sc.id = s.category_id;

-- VIEW giá dịch vụ đang áp dụng
CREATE OR REPLACE VIEW v_current_service_prices AS
SELECT s.id AS service_id, s.code, s.name, sc.code AS category_code,
       sp.price, sp.vat_rate, sp.effective_from
FROM services s
JOIN service_categories sc ON sc.id = s.category_id
JOIN service_prices sp ON sp.service_id = s.id
WHERE sp.effective_from <= NOW() AND (sp.effective_to IS NULL OR sp.effective_to > NOW());

-- Seed clinical-service
INSERT INTO species (code, name, description) VALUES
('DOG', 'Chó', 'Loài chó (Canis lupus familiaris)'),
('CAT', 'Mèo', 'Loài mèo (Felis catus)');

INSERT INTO service_categories (code, name, queue_type, requires_prepayment, display_order) VALUES
('EXAMINATION', 'Khám bệnh', 'DOCTOR', TRUE, 1),
('VACCINATION', 'Tiêm phòng', NULL, FALSE, 2),
('DEWORMING', 'Tẩy giun', NULL, FALSE, 3),
('EXTERNAL_PARASITE', 'Trị ký sinh trùng ngoài da', NULL, FALSE, 4),
('INJECTION_INFUSION', 'Tiêm, truyền dịch', NULL, FALSE, 5),
('LABORATORY', 'Xét nghiệm', 'LABORATORY', TRUE, 6),
('IMAGING', 'Chẩn đoán hình ảnh', 'IMAGING', TRUE, 7),
('SURGERY', 'Phẫu thuật', NULL, FALSE, 8),
('PROCEDURE', 'Thủ thuật', NULL, FALSE, 9);

INSERT INTO services (id, category_id, code, name, unit, estimated_minutes, description, preparation_notes)
SELECT v.id, c.id, v.code, v.name, v.unit, v.minutes, v.descr, v.prep
FROM (
    SELECT @s_exam AS id, 'EXAMINATION' AS cat, 'EXAM_GEN' AS code, 'Khám lâm sàng tổng quát' AS name, 'Lần' AS unit, 20 AS minutes, 'Khám tổng thể, kiểm tra thân nhiệt, cân nặng và triệu chứng' AS descr, NULL AS prep
    UNION ALL SELECT @s_vac7, 'VACCINATION', 'VAC_7B', 'Tiêm phòng Vaccine 7 bệnh (Chó)', 'Mũi', 10, 'Công tiêm phòng vaccine phòng 7 bệnh truyền nhiễm', 'Thú cưng khỏe mạnh, không sốt'
    UNION ALL SELECT @s_vac4, 'VACCINATION', 'VAC_4B', 'Tiêm phòng Vaccine 4 bệnh (Mèo)', 'Mũi', 10, 'Công tiêm phòng vaccine cho mèo', 'Thú cưng khỏe mạnh, không sốt'
    UNION ALL SELECT @s_deworm, 'DEWORMING', 'DEWORM', 'Dịch vụ tẩy giun đường ruột', 'Lần', 10, 'Công kiểm tra và hỗ trợ cho uống thuốc tẩy giun', NULL
    UNION ALL SELECT @s_cbc, 'LABORATORY', 'LAB_CBC', 'Xét nghiệm tổng phân tích tế bào máu (CBC)', 'Lần', 30, 'Xét nghiệm chỉ số tế bào máu tự động', NULL
    UNION ALL SELECT @s_us, 'IMAGING', 'IMG_US_AB', 'Siêu âm ổ bụng tổng quát', 'Lần', 20, 'Siêu âm màu kiểm tra các cơ quan nội tạng ổ bụng', 'Nhịn ăn 6 - 8 giờ trước khi siêu âm'
    UNION ALL SELECT @s_xray, 'IMAGING', 'IMG_XRAY', 'Chụp X-quang kỹ thuật số (1 tư thế)', 'Tư thế', 15, 'Chụp X-quang tim phổi / xương khớp', NULL
) v JOIN service_categories c ON c.code = v.cat;

-- Bảng giá ban đầu (dòng đang mở effective_to = NULL)
INSERT INTO service_prices (service_id, price, vat_rate, effective_from, change_reason, created_by) VALUES
(@s_exam, 100000.00, 0.00, '2026-01-01 00:00:00', 'Bảng giá khởi tạo', @u_admin),
(@s_vac7, 150000.00, 0.00, '2026-01-01 00:00:00', 'Bảng giá khởi tạo', @u_admin),
(@s_vac4, 150000.00, 0.00, '2026-01-01 00:00:00', 'Bảng giá khởi tạo', @u_admin),
(@s_deworm, 50000.00, 0.00, '2026-01-01 00:00:00', 'Bảng giá khởi tạo', @u_admin),
(@s_cbc, 250000.00, 0.00, '2026-01-01 00:00:00', 'Bảng giá khởi tạo', @u_admin),
(@s_us, 200000.00, 0.00, '2026-01-01 00:00:00', 'Bảng giá khởi tạo', @u_admin),
(@s_xray, 180000.00, 0.00, '2026-01-01 00:00:00', 'Bảng giá khởi tạo', @u_admin);

INSERT INTO lab_test_items (code, name, unit, description) VALUES
('WBC', 'Bạch cầu (White Blood Cells)', '10^9/L', 'Số lượng bạch cầu tổng số'),
('RBC', 'Hồng cầu (Red Blood Cells)', '10^12/L', 'Số lượng hồng cầu tổng số'),
('HGB', 'Huyết sắc tố (Hemoglobin)', 'g/dL', 'Nồng độ huyết sắc tố'),
('PLT', 'Tiểu cầu (Platelets)', '10^9/L', 'Số lượng tiểu cầu');

-- Gói LAB_CBC gồm 4 chỉ số
INSERT INTO service_lab_test_items (service_id, lab_test_item_id)
SELECT @s_cbc, id FROM lab_test_items WHERE code IN ('WBC', 'RBC', 'HGB', 'PLT');

INSERT INTO lab_test_reference_ranges (lab_test_item_id, species_id, min_value, max_value)
SELECT i.id, s.id, v.min_v, v.max_v
FROM (
    SELECT 'WBC' AS item, 'DOG' AS sp, 6.00 AS min_v, 17.00 AS max_v
    UNION ALL SELECT 'RBC', 'DOG', 5.50, 8.50
    UNION ALL SELECT 'HGB', 'DOG', 12.00, 18.00
    UNION ALL SELECT 'PLT', 'DOG', 200.00, 500.00
    UNION ALL SELECT 'WBC', 'CAT', 5.50, 19.50
    UNION ALL SELECT 'RBC', 'CAT', 5.00, 10.00
    UNION ALL SELECT 'HGB', 'CAT', 8.00, 15.00
    UNION ALL SELECT 'PLT', 'CAT', 300.00, 700.00
) v
JOIN lab_test_items i ON i.code = v.item
JOIN species s ON s.code = v.sp;


-- ==============================================================================
-- PHẦN 4: PET_CLINIC_BILLING_PHARMACY_DB (BILLING-PHARMACY-SERVICE :8084) - 10 BẢNG
-- ==============================================================================
-- Nhận PrescriptionCreatedEvent -> tạo hóa đơn thuốc nháp (PENDING) theo đơn.
-- Khách mua tại phòng khám: thu tiền + trừ kho trong CÙNG 1 giao dịch; mua ngoài: hủy hóa đơn nháp.
CREATE DATABASE IF NOT EXISTS pet_clinic_billing_pharmacy_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE pet_clinic_billing_pharmacy_db;

-- 38. MEDICINE_CATEGORIES (NHÓM THUỐC - DANH MỤC)
CREATE TABLE IF NOT EXISTS medicine_categories (
    id SMALLINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- 39. MEDICINES (THÔNG TIN THUỐC & QUY CÁCH - KHÔNG CHỨA GIÁ, KHÔNG CHỨA TỒN KHO)
CREATE TABLE IF NOT EXISTS medicines (
    id BINARY(16) PRIMARY KEY, -- UUIDv7
    category_id SMALLINT NOT NULL,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    dosage_form VARCHAR(50) NOT NULL, -- Dạng bào chế: viên nén, lọ tiêm đông khô...
    strength VARCHAR(50) NULL, -- Hàm lượng tổng hiển thị: 250mg
    base_unit VARCHAR(30) NOT NULL, -- Đơn vị bán nhỏ nhất: viên, lọ, ống
    packaging_spec VARCHAR(150) NOT NULL, -- Quy cách: Hộp 10 vỉ x 10 viên
    manufacturer VARCHAR(150) NULL,
    country_of_origin VARCHAR(100) NULL,
    registration_number VARCHAR(50) NULL, -- Số đăng ký lưu hành
    storage_conditions VARCHAR(255) NULL, -- Bảo quản 2 - 8 độ C...
    requires_prescription BOOLEAN NOT NULL DEFAULT TRUE,
    min_stock_alert INT NOT NULL DEFAULT 10,
    is_active BOOLEAN NOT NULL DEFAULT TRUE, -- Xóa mềm
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_med_category FOREIGN KEY (category_id) REFERENCES medicine_categories(id),
    CONSTRAINT chk_med_min_stock CHECK (min_stock_alert >= 0)
);
CREATE INDEX idx_med_category ON medicines(category_id, is_active);

-- 40. MEDICINE_INGREDIENTS (THÀNH PHẦN HOẠT CHẤT)
CREATE TABLE IF NOT EXISTS medicine_ingredients (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    medicine_id BINARY(16) NOT NULL,
    ingredient_name VARCHAR(150) NOT NULL,
    strength_value DECIMAL(10, 3) NULL,
    strength_unit VARCHAR(20) NULL, -- mg, ml, IU, liều...
    CONSTRAINT fk_mingr_medicine FOREIGN KEY (medicine_id) REFERENCES medicines(id) ON DELETE CASCADE,
    CONSTRAINT uq_mingr UNIQUE (medicine_id, ingredient_name)
);

-- 41. MEDICINE_PRICES (LỊCH SỬ GIÁ BÁN THUỐC) - quy tắc như service_prices
CREATE TABLE IF NOT EXISTS medicine_prices (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    medicine_id BINARY(16) NOT NULL,
    sale_price DECIMAL(12, 2) NOT NULL,
    vat_rate DECIMAL(4, 2) NOT NULL DEFAULT 0.05,
    effective_from DATETIME NOT NULL,
    effective_to DATETIME NULL,
    change_reason VARCHAR(255) NULL,
    created_by BINARY(16) NOT NULL, -- LFK: auth.users (ADMIN)
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_mprice_medicine FOREIGN KEY (medicine_id) REFERENCES medicines(id),
    CONSTRAINT uq_mprice_from UNIQUE (medicine_id, effective_from),
    CONSTRAINT chk_mprice_price CHECK (sale_price >= 0),
    CONSTRAINT chk_mprice_vat CHECK (vat_rate >= 0 AND vat_rate <= 1),
    CONSTRAINT chk_mprice_period CHECK (effective_to IS NULL OR effective_to > effective_from)
);
CREATE INDEX idx_mprice_lookup ON medicine_prices(medicine_id, effective_from, effective_to);

-- 42. MEDICINE_STOCKS (TỒN KHO HIỆN TẠI, 1-1 VỚI MEDICINES)
-- Tách khỏi medicines: dòng tồn kho bị khóa / cập nhật liên tục khi bán, không ảnh hưởng thông tin thuốc.
-- Phi chuẩn hóa CÓ CHỦ ĐÍCH: quantity_on_hand = SUM(inventory_transactions.quantity), lưu để trừ kho
-- nguyên tử (UPDATE ... SET quantity_on_hand = quantity_on_hand - :qty WHERE quantity_on_hand >= :qty).
CREATE TABLE IF NOT EXISTS medicine_stocks (
    medicine_id BINARY(16) PRIMARY KEY,
    quantity_on_hand INT NOT NULL DEFAULT 0,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    version BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT fk_mstock_medicine FOREIGN KEY (medicine_id) REFERENCES medicines(id),
    CONSTRAINT chk_mstock_qty CHECK (quantity_on_hand >= 0)
);

-- 43. MEDICINE_INVOICES (HÓA ĐƠN THUỐC - NHÁP TỰ TẠO TỪ ĐƠN THUỐC, TỐI ĐA 1 / ĐƠN)
-- payment_status: PENDING (nháp, chờ khách quyết định) | PAID | CANCELLED (khách mua ngoài / hủy).
-- prescription_id: khóa ngoại logic DUY NHẤT sang ngữ cảnh lâm sàng. Thông tin khách, Bác sĩ chụp lại
-- từ PrescriptionCreatedEvent để in hóa đơn không cần gọi clinical / auth.
CREATE TABLE IF NOT EXISTS medicine_invoices (
    id BINARY(16) PRIMARY KEY, -- UUIDv7
    invoice_code VARCHAR(50) NOT NULL UNIQUE,
    prescription_id BINARY(16) NOT NULL UNIQUE, -- LFK: clinical.prescriptions
    visit_id BINARY(16) NOT NULL, -- LFK: clinical.pet_visits (tra cứu theo đợt khám)
    customer_name_snapshot VARCHAR(150) NOT NULL,
    customer_phone_snapshot VARCHAR(20) NOT NULL,
    pet_name_snapshot VARCHAR(100) NOT NULL,
    doctor_name_snapshot VARCHAR(150) NOT NULL,
    discount_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    payment_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    cashier_id BINARY(16) NULL, -- LFK: auth.users (gán khi thu tiền)
    paid_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    version BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT chk_mi_discount CHECK (discount_amount >= 0)
);
CREATE INDEX idx_mi_status_paid ON medicine_invoices(payment_status, paid_at);
CREATE INDEX idx_mi_visit ON medicine_invoices(visit_id);
CREATE INDEX idx_mi_cashier ON medicine_invoices(cashier_id);

-- 44. MEDICINE_INVOICE_ITEMS (DÒNG THUỐC TRÊN HÓA ĐƠN - TRỎ THẲNG MEDICINES)
-- prescribed_quantity: số lượng kê lấy từ sự kiện (giá trị, không phải khóa ngoại), chỉ để đối chiếu.
-- quantity: số lượng khách mua, được nhiều hơn / ít hơn / bằng số kê nhưng không vượt tồn kho (BR-32);
--           Thu ngân sửa trước khi thu, bỏ dòng = xóa dòng.
-- unit_price, vat_rate: snapshot từ medicine_prices đang hiệu lực lúc thu tiền.
CREATE TABLE IF NOT EXISTS medicine_invoice_items (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    medicine_invoice_id BINARY(16) NOT NULL,
    medicine_id BINARY(16) NOT NULL,
    prescribed_quantity INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(12, 2) NOT NULL,
    vat_rate DECIMAL(4, 2) NOT NULL,
    CONSTRAINT fk_mii_invoice FOREIGN KEY (medicine_invoice_id) REFERENCES medicine_invoices(id) ON DELETE CASCADE,
    CONSTRAINT fk_mii_medicine FOREIGN KEY (medicine_id) REFERENCES medicines(id),
    CONSTRAINT uq_mii_invoice_medicine UNIQUE (medicine_invoice_id, medicine_id),
    CONSTRAINT chk_mii_quantity CHECK (quantity > 0),
    CONSTRAINT chk_mii_price CHECK (unit_price >= 0),
    CONSTRAINT chk_mii_vat CHECK (vat_rate >= 0 AND vat_rate <= 1)
);
CREATE INDEX idx_mii_medicine ON medicine_invoice_items(medicine_id);

-- 45. INVENTORY_TRANSACTIONS (NHẬT KÝ BIẾN ĐỘNG KHO)
-- transaction_type: IMPORT | EXPORT_SALE | ADJUSTMENT. quantity có dấu: + nhập / - xuất.
CREATE TABLE IF NOT EXISTS inventory_transactions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    medicine_id BINARY(16) NOT NULL,
    transaction_type VARCHAR(20) NOT NULL,
    quantity INT NOT NULL,
    unit_cost DECIMAL(12, 2) NULL, -- Giá nhập (chỉ IMPORT)
    medicine_invoice_id BINARY(16) NULL, -- Bắt buộc khi EXPORT_SALE
    notes VARCHAR(255) NULL,
    created_by BINARY(16) NOT NULL, -- LFK: auth.users
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_it_medicine FOREIGN KEY (medicine_id) REFERENCES medicines(id),
    CONSTRAINT fk_it_invoice FOREIGN KEY (medicine_invoice_id) REFERENCES medicine_invoices(id),
    CONSTRAINT chk_it_quantity CHECK (quantity <> 0)
);
CREATE INDEX idx_it_med_date ON inventory_transactions(medicine_id, created_at);
CREATE INDEX idx_it_creator ON inventory_transactions(created_by);

-- 46. OUTBOX_EVENTS (cấu trúc như mục 9)
-- billing-pharmacy phát: MedicineInvoicePaidEvent, MedicineLowStockEvent.
CREATE TABLE IF NOT EXISTS outbox_events (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    event_id BINARY(16) NOT NULL UNIQUE,
    aggregate_type VARCHAR(50) NOT NULL,
    aggregate_id BINARY(16) NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    routing_key VARCHAR(100) NOT NULL,
    payload JSON NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    attempt_count INT NOT NULL DEFAULT 0,
    next_attempt_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_error VARCHAR(500) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    published_at TIMESTAMP NULL
);
CREATE INDEX idx_outbox_pending ON outbox_events(status, next_attempt_at, id);

-- 47. PROCESSED_EVENTS (cấu trúc như mục 13)
-- billing-pharmacy nhận: PrescriptionCreatedEvent (tạo hóa đơn thuốc nháp).
CREATE TABLE IF NOT EXISTS processed_events (
    event_id BINARY(16) NOT NULL,
    consumer VARCHAR(100) NOT NULL,
    processed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (event_id, consumer)
);

-- VIEW tính tiền hóa đơn thuốc (không lưu giá trị dẫn xuất)
CREATE OR REPLACE VIEW v_medicine_invoice_amounts AS
SELECT mi.id AS invoice_id,
       mi.invoice_code,
       mi.visit_id,
       mi.discount_amount,
       ROUND(SUM(mii.quantity * mii.unit_price), 2) AS amount_before_vat,
       ROUND(SUM(mii.quantity * mii.unit_price * mii.vat_rate), 2) AS vat_amount,
       ROUND(SUM(mii.quantity * mii.unit_price * (1 + mii.vat_rate)) - mi.discount_amount, 2) AS payable_amount,
       mi.payment_status,
       mi.paid_at
FROM medicine_invoices mi
JOIN medicine_invoice_items mii ON mii.medicine_invoice_id = mi.id
GROUP BY mi.id, mi.invoice_code, mi.visit_id, mi.discount_amount, mi.payment_status, mi.paid_at;

-- VIEW giá thuốc đang áp dụng kèm tồn kho
CREATE OR REPLACE VIEW v_current_medicine_prices AS
SELECT m.id AS medicine_id, m.code, m.name, m.base_unit, m.packaging_spec,
       mp.sale_price, mp.vat_rate, ms.quantity_on_hand
FROM medicines m
JOIN medicine_prices mp ON mp.medicine_id = m.id
JOIN medicine_stocks ms ON ms.medicine_id = m.id
WHERE mp.effective_from <= NOW() AND (mp.effective_to IS NULL OR mp.effective_to > NOW());

-- Seed billing-pharmacy-service (dữ liệu mẫu minh họa)
INSERT INTO medicine_categories (code, name) VALUES
('ANTIBIOTIC', 'Kháng sinh'),
('VACCINE', 'Vắc-xin'),
('ANTIPARASITIC', 'Thuốc trị ký sinh trùng'),
('SUPPLEMENT', 'Thực phẩm bổ sung, vitamin');

INSERT INTO medicines (id, category_id, code, name, dosage_form, strength, base_unit, packaging_spec, manufacturer, country_of_origin, storage_conditions, requires_prescription, min_stock_alert)
SELECT v.id, c.id, v.code, v.name, v.form, v.strength, v.unit, v.pack, v.maker, v.origin, v.storage, v.rx, v.min_alert
FROM (
    SELECT @m_amox AS id, 'ANTIBIOTIC' AS cat, 'MED_AMOX' AS code, 'Clavamox 250mg' AS name, 'Viên nén' AS form, '250mg' AS strength, 'Viên' AS unit, 'Hộp 10 vỉ x 10 viên' AS pack, 'Zoetis' AS maker, 'Hoa Kỳ' AS origin, 'Nơi khô ráo, dưới 25 độ C' AS storage, TRUE AS rx, 20 AS min_alert
    UNION ALL SELECT @m_vang, 'VACCINE', 'MED_VANG_7B', 'Vaccine Vanguard Plus 5/L (7 bệnh)', 'Lọ tiêm đông khô', '1 liều', 'Lọ', 'Hộp 25 liều (lọ vaccine + lọ dung môi)', 'Zoetis', 'Hoa Kỳ', 'Bảo quản lạnh 2 - 8 độ C', TRUE, 10
    UNION ALL SELECT @m_pure, 'VACCINE', 'MED_PURE_4B', 'Vaccine Purevax RCP (Mèo)', 'Lọ tiêm đông khô', '1 liều', 'Lọ', 'Hộp 10 liều', 'Boehringer Ingelheim', 'Pháp', 'Bảo quản lạnh 2 - 8 độ C', TRUE, 10
    UNION ALL SELECT @m_dron, 'ANTIPARASITIC', 'MED_DRON_DOG', 'Drontal Plus tẩy giun cho chó', 'Viên nén', NULL, 'Viên', 'Hộp 2 vỉ x 2 viên', 'Elanco', 'Đức', 'Nơi khô ráo, dưới 25 độ C', FALSE, 15
) v JOIN medicine_categories c ON c.code = v.cat;

INSERT INTO medicine_ingredients (medicine_id, ingredient_name, strength_value, strength_unit) VALUES
(@m_amox, 'Amoxicillin', 200.000, 'mg'),
(@m_amox, 'Clavulanic acid', 50.000, 'mg'),
(@m_vang, 'Virus Care, Adeno type 2, Parainfluenza, Parvo (nhược độc)', NULL, NULL),
(@m_vang, 'Leptospira canicola, icterohaemorrhagiae (vô hoạt)', NULL, NULL),
(@m_pure, 'Virus Rhinotracheitis, Calici, Panleukopenia (nhược độc)', NULL, NULL),
(@m_dron, 'Febantel', 150.000, 'mg'),
(@m_dron, 'Pyrantel embonate', 144.000, 'mg'),
(@m_dron, 'Praziquantel', 50.000, 'mg');

INSERT INTO medicine_prices (medicine_id, sale_price, vat_rate, effective_from, change_reason, created_by) VALUES
(@m_amox, 15000.00, 0.05, '2026-01-01 00:00:00', 'Bảng giá khởi tạo', @u_admin),
(@m_vang, 180000.00, 0.05, '2026-01-01 00:00:00', 'Bảng giá khởi tạo', @u_admin),
(@m_pure, 190000.00, 0.05, '2026-01-01 00:00:00', 'Bảng giá khởi tạo', @u_admin),
(@m_dron, 45000.00, 0.05, '2026-01-01 00:00:00', 'Bảng giá khởi tạo', @u_admin);

INSERT INTO medicine_stocks (medicine_id, quantity_on_hand) VALUES
(@m_amox, 200), (@m_vang, 50), (@m_pure, 40), (@m_dron, 100);

-- Nhập kho ban đầu được ghi nhật ký để thỏa bất biến: quantity_on_hand = SUM(quantity)
INSERT INTO inventory_transactions (medicine_id, transaction_type, quantity, notes, created_by) VALUES
(@m_amox, 'IMPORT', 200, 'Tồn kho đầu kỳ', @u_admin),
(@m_vang, 'IMPORT', 50, 'Tồn kho đầu kỳ', @u_admin),
(@m_pure, 'IMPORT', 40, 'Tồn kho đầu kỳ', @u_admin),
(@m_dron, 'IMPORT', 100, 'Tồn kho đầu kỳ', @u_admin);


-- ==============================================================================
-- PHẦN 5: PET_CLINIC_REPORTING_DB (REPORTING-SERVICE :8086) - 5 BẢNG (CQRS READ MODEL)
-- ==============================================================================
-- Chỉ được ghi bởi các listener sự kiện của reporting-service; các service khác không đọc / ghi.
-- Bảng phẳng, phi chuẩn hóa CÓ CHỦ ĐÍCH (đã chứa tên, nhóm, số tiền) để báo cáo chỉ cần 1 truy vấn,
-- không JOIN chéo service, không gọi API hàng loạt. Có thể dựng lại bằng cách phát lại sự kiện.
CREATE DATABASE IF NOT EXISTS pet_clinic_reporting_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE pet_clinic_reporting_db;

-- 48. VISIT_FACTS (MỘT DÒNG / ĐỢT KHÁM)
-- Tạo khi nhận VisitCheckedInEvent; cập nhật khi VisitCompletedEvent / VisitCancelledEvent / đổi tên.
CREATE TABLE IF NOT EXISTS visit_facts (
    visit_id BINARY(16) PRIMARY KEY,
    visit_code VARCHAR(50) NOT NULL,
    business_date DATE NOT NULL,
    checked_in_at TIMESTAMP NOT NULL,
    completed_at TIMESTAMP NULL,
    current_status VARCHAR(20) NOT NULL,
    is_emergency BOOLEAN NOT NULL,
    pet_id BINARY(16) NOT NULL,
    pet_name VARCHAR(100) NOT NULL,
    species_code VARCHAR(30) NOT NULL,
    owner_id BINARY(16) NOT NULL,
    owner_name VARCHAR(150) NOT NULL,
    doctor_id BINARY(16) NULL,
    doctor_name VARCHAR(150) NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
CREATE INDEX idx_vf_date ON visit_facts(business_date, current_status);
CREATE INDEX idx_vf_doctor ON visit_facts(doctor_id, business_date);

-- 49. REVENUE_FACTS (MỘT DÒNG / DÒNG TIỀN ĐÃ THU HOẶC ĐÃ HOÀN)
-- revenue_type: SERVICE | MEDICINE. entry_type: SALE | REFUND (REFUND mang số tiền âm).
CREATE TABLE IF NOT EXISTS revenue_facts (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    revenue_type VARCHAR(20) NOT NULL,
    entry_type VARCHAR(20) NOT NULL,
    source_invoice_id BINARY(16) NOT NULL,
    invoice_code VARCHAR(50) NOT NULL,
    item_id BINARY(16) NOT NULL, -- service_id hoặc medicine_id
    item_code VARCHAR(50) NOT NULL,
    item_name VARCHAR(150) NOT NULL,
    category_code VARCHAR(30) NOT NULL,
    category_name VARCHAR(100) NOT NULL,
    visit_id BINARY(16) NOT NULL,
    doctor_id BINARY(16) NULL,
    doctor_name VARCHAR(150) NULL,
    cashier_id BINARY(16) NULL,
    business_date DATE NOT NULL,
    occurred_at TIMESTAMP NOT NULL, -- paid_at hoặc thời điểm hoàn tiền
    quantity INT NOT NULL,
    amount_before_vat DECIMAL(14, 2) NOT NULL,
    vat_amount DECIMAL(14, 2) NOT NULL,
    discount_amount DECIMAL(14, 2) NOT NULL,
    net_amount DECIMAL(14, 2) NOT NULL,
    CONSTRAINT uq_rf_line UNIQUE (source_invoice_id, item_id, entry_type)
);
CREATE INDEX idx_rf_date ON revenue_facts(business_date, revenue_type, category_code);
CREATE INDEX idx_rf_doctor ON revenue_facts(doctor_id, business_date);

-- 50. DAILY_REVENUE_SUMMARIES (TỔNG HỢP DOANH THU THEO NGÀY / LOẠI / NHÓM)
-- Cập nhật cộng dồn trong cùng giao dịch với INSERT revenue_facts (INSERT ... ON DUPLICATE KEY UPDATE).
CREATE TABLE IF NOT EXISTS daily_revenue_summaries (
    business_date DATE NOT NULL,
    revenue_type VARCHAR(20) NOT NULL,
    category_code VARCHAR(30) NOT NULL,
    category_name VARCHAR(100) NOT NULL,
    line_count INT NOT NULL DEFAULT 0,
    amount_before_vat DECIMAL(16, 2) NOT NULL DEFAULT 0,
    vat_amount DECIMAL(16, 2) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(16, 2) NOT NULL DEFAULT 0,
    net_amount DECIMAL(16, 2) NOT NULL DEFAULT 0,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (business_date, revenue_type, category_code)
);

-- 51. DOCTOR_DAILY_PERFORMANCES (HIỆU SUẤT BÁC SĨ THEO NGÀY)
CREATE TABLE IF NOT EXISTS doctor_daily_performances (
    business_date DATE NOT NULL,
    doctor_id BINARY(16) NOT NULL,
    doctor_name VARCHAR(150) NOT NULL,
    completed_visits INT NOT NULL DEFAULT 0,
    cancelled_visits INT NOT NULL DEFAULT 0,
    emergency_visits INT NOT NULL DEFAULT 0,
    service_net_revenue DECIMAL(16, 2) NOT NULL DEFAULT 0,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (business_date, doctor_id)
);

-- 52. PROCESSED_EVENTS (cấu trúc như mục 13)
-- reporting nhận: VisitCheckedInEvent, VisitCompletedEvent, VisitCancelledEvent, ServiceInvoicePaidEvent,
-- ServiceInvoiceRefundedEvent, MedicineInvoicePaidEvent, UserProfileUpdatedEvent, PetUpdatedEvent.
CREATE TABLE IF NOT EXISTS processed_events (
    event_id BINARY(16) NOT NULL,
    consumer VARCHAR(100) NOT NULL,
    processed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (event_id, consumer)
);

-- ==============================================================================
-- TRUY VẤN MẪU
-- ==============================================================================
-- Doanh thu theo nhóm trong tháng (reporting-service, 1 truy vấn, không gọi chéo):
--   SELECT revenue_type, category_name, SUM(net_amount)
--   FROM pet_clinic_reporting_db.daily_revenue_summaries
--   WHERE business_date BETWEEN '2026-11-01' AND '2026-11-30'
--   GROUP BY revenue_type, category_name;
-- Giá dịch vụ tại một thời điểm trong quá khứ (clinical-service):
--   SELECT price, vat_rate FROM pet_clinic_clinical_db.service_prices
--   WHERE service_id = :id AND effective_from <= :t AND (effective_to IS NULL OR effective_to > :t);
-- Tồn kho sau từng giao dịch:
--   SELECT id, medicine_id, quantity,
--          SUM(quantity) OVER (PARTITION BY medicine_id ORDER BY created_at, id) AS balance_after
--   FROM pet_clinic_billing_pharmacy_db.inventory_transactions;
-- Thời gian chờ trung bình theo hàng đợi trong ngày:
--   SELECT queue_type, AVG(TIMESTAMPDIFF(MINUTE, issued_at, started_at))
--   FROM pet_clinic_clinical_db.queue_ticket_histories
--   WHERE service_date = CURDATE() AND final_status = 'DONE' GROUP BY queue_type;
-- Hiển thị UUID dạng chuỗi khi gỡ lỗi: SELECT BIN_TO_UUID(id) FROM pets;
-- ==============================================================================
-- CẤU TRÚC KHÓA REDIS CỦA HÀNG ĐỢI (clinical-service, không phải bảng MySQL):
--   queue:{yyyyMMdd}:{DOCTOR|LABORATORY|IMAGING}:{doctorId|UNASSIGNED|ALL}  ZSET  member = ticketId,
--        (DOCTOR: theo từng Bác sĩ, UNASSIGNED = chờ phân công; LABORATORY / IMAGING: ALL)
--        score = (2 - priority) * 10^13 + issuedAtEpochMillis  (ZRANGE tăng dần = ưu tiên cao, đến trước)
--   ticket:{ticketId}                     HASH  queueType, serviceDate, ticketNo, visitId, doctorId,
--        priority, status (WAITING | IN_SERVICE), issuedAt, issuedBy, calledCount, lastCalledAt,
--        startedAt, vsdIds, petName, ownerName, roomNumber        (TTL 36 giờ)
--   queue:seq:{yyyyMMdd}:{queueType}      STRING INCR -> ticket_no theo ngày, theo loại hàng đợi (TTL 48 giờ)
--   queue:dedupe:{eventId}                STRING ticketId, chống phát phiếu trùng khi nhận lại sự kiện (TTL 48 giờ)
--   queue:visit:{visitId}                 SET các ticketId đang mở của đợt khám (hủy ca -> hủy hết)
-- Mọi thao tác phát / bắt đầu / kết thúc / hủy phiếu chạy bằng Lua script (nguyên tử, không khóa).
-- Redis bật AOF (appendfsync everysec). Mất dữ liệu Redis -> QueueRebuildJob dựng lại từ MySQL.
-- ==============================================================================
