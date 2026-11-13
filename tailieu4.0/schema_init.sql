-- ==============================================================================
-- HỆ THỐNG QUẢN LÝ PHÒNG KHÁM THÚ Y - DATABASE INITIALIZATION SCRIPT (DDL & SEED)
-- PHIÊN BẢN 3.0 - CHUẨN HÓA LẠI THEO GÓP Ý CỦA GIẢNG VIÊN HƯỚNG DẪN
-- MÔ HÌNH KIẾN TRÚC: MICROSERVICES (DATABASE-PER-SERVICE PATTERN)
-- ==============================================================================
-- 4 Cơ sở dữ liệu logic:
-- 1. pet_clinic_auth_db             : auth-service (:8081)             - 3 bảng
-- 2. pet_clinic_appointment_db      : appointment-service (:8082)      - 2 bảng
-- 3. pet_clinic_clinical_db         : clinical-service (:8083)         - 14 bảng
-- 4. pet_clinic_billing_pharmacy_db : billing-pharmacy-service (:8084) - 6 bảng
-- TỔNG CỘNG: 25 BẢNG
--
-- CÁC THAY ĐỔI CHÍNH SO VỚI PHIÊN BẢN 2.0:
-- (1) Hóa đơn tách theo từng dịch vụ: mỗi dòng chỉ định dịch vụ (visit_service_details)
--     có đúng 1 hóa đơn riêng (service_invoices), đặt cùng DB với dịch vụ để dùng
--     khóa ngoại vật lý và truy xuất doanh thu theo dịch vụ/nhóm dịch vụ bằng JOIN nội bộ.
-- (2) Hóa đơn thuốc là TÙY CHỌN: đơn thuốc (prescriptions) chỉ là chỉ định chuyên môn.
--     Khách mua tại phòng khám -> sinh medicine_invoices; mua ngoài -> không sinh hóa đơn.
-- (3) Bỏ toàn bộ thuộc tính dẫn xuất (tính được từ thuộc tính khác):
--     subtotal, total_*_amount, final_amount, vat_amount, balance_after, evaluation, end_time.
-- (4) Bỏ thuộc tính trùng lặp với bảng lịch sử trạng thái (audit trail):
--     confirmed_by/at, cancelled_by/at, cancel_reason, started_at, closed_at, completed_at...
--     Thời điểm/người/lý do chuyển trạng thái được lấy từ bảng *_status_histories.
-- (5) Bổ sung bảng nối service_lab_test_items: gói xét nghiệm gồm những chỉ số nào.
-- (6) Bổ sung cột version (khóa lạc quan @Version) cho các bảng có cập nhật đồng thời.
-- (7) [Rà soát 11/11] Hàng đợi riêng cho từng Bác sĩ và cho phòng Xét nghiệm / CĐHA:
--     cột queue_order ở pet_visits và visit_service_details.
--     Thứ tự: ORDER BY is_emergency DESC, queue_order.
--     [Cập nhật 13/11/2026] Gọi theo từng dòng: bác sĩ / KTV bấm "Gọi" ở dòng bất kỳ, không đổi thứ tự (queue_order giữ nguyên).
--     Đã BỎ cơ chế "Đẩy lùi 1 bậc" cùng cột skip_count và hành động SKIPPED (làm hai ca đầu hàng đổi chỗ mãi mãi).
--     Mỗi lần "Gọi" ghi last_called_at = thời điểm gọi để màn hình đánh dấu ca "Đã gọi HH:mm" (không dùng để xếp thứ tự).
--
-- NGUYÊN TẮC TOÀN VẸN DỮ LIỆU LIÊN DỊCH VỤ:
-- - Bảng cùng Service: ràng buộc FOREIGN KEY vật lý.
-- - Liên kết chéo Service: khóa ngoại logic (BIGINT) + Index, kiểm soát qua OpenFeign/RabbitMQ.
--   Các cột này được đánh dấu chú thích "LFK: <db>.<bảng>".
-- - Giá trị tiền thanh toán KHÔNG lưu, được tính bằng VIEW (xem cuối mỗi phần).
-- ==============================================================================

-- [12/11] Bắt buộc: client mysql trong entrypoint Docker mặc định dùng latin1,
-- thiếu dòng này tiếng Việt trong seed bị mã hóa 2 lần.
SET NAMES utf8mb4;


-- ==============================================================================
-- PHẦN 1: PET_CLINIC_AUTH_DB (AUTH-SERVICE :8081)
-- ==============================================================================
CREATE DATABASE IF NOT EXISTS pet_clinic_auth_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE pet_clinic_auth_db;

-- 1. ROLES (VAI TRÒ NGƯỜI DÙNG)
CREATE TABLE IF NOT EXISTS roles (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    code ENUM('ADMIN', 'VETERINARIAN', 'RECEPTIONIST', 'LAB_TECHNICIAN', 'IMAGING_TECHNICIAN', 'PET_OWNER') NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(255) NULL
);

-- 2. USERS (TÀI KHOẢN: NHÂN SỰ & KHÁCH HÀNG)
CREATE TABLE IF NOT EXISTS users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    role_id BIGINT NOT NULL,
    username VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(150) NOT NULL,
    phone_number VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(150) NULL,
    address VARCHAR(255) NULL,
    room_number VARCHAR(20) NULL, -- Phòng làm việc cố định của Bác sĩ / KTV
    status ENUM('ACTIVE', 'INACTIVE', 'LOCKED') NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_users_role FOREIGN KEY (role_id) REFERENCES roles(id)
);
CREATE INDEX idx_users_role_status ON users(role_id, status);

-- 3. REFRESH_TOKENS (PHIÊN ĐĂNG NHẬP & XOAY VÒNG TOKEN)
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    token VARCHAR(255) NOT NULL UNIQUE,
    expiry_date TIMESTAMP NOT NULL,
    revoked BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_refresh_tokens_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_id);

INSERT INTO roles (code, name, description) VALUES
('ADMIN', 'Quản trị viên', 'Toàn quyền cấu hình hệ thống, quản lý danh mục và xem báo cáo'),
('VETERINARIAN', 'Bác sĩ thú y khám chính', 'Khám lâm sàng, chỉ định xét nghiệm, chẩn đoán xác định và kê đơn'),
('RECEPTIONIST', 'Lễ tân / Thu ngân', 'Tiếp đón, phân công bác sĩ, thu ngân và bán thuốc'),
('LAB_TECHNICIAN', 'Bác sĩ / KTV Xét nghiệm', 'Tiếp nhận mẫu bệnh phẩm, phân tích và nhập chỉ số kết quả'),
('IMAGING_TECHNICIAN', 'Bác sĩ / KTV Chẩn đoán hình ảnh', 'Siêu âm, chụp X-quang, tải tệp ảnh và kết luận hình thái học'),
('PET_OWNER', 'Chủ thú cưng', 'Đặt lịch trực tuyến, theo dõi hồ sơ bệnh án và đơn thuốc');

-- Tài khoản Admin mặc định (mật khẩu: Admin@123, BCrypt strength 12 - đã kiểm tra bằng bcrypt.checkpw ngày 12/11)
INSERT INTO users (role_id, username, password_hash, full_name, phone_number, email, status) VALUES
(1, 'admin', '$2a$12$QfxJtMwsg2Wd72ZkvcQ.BeADCJqgMjJ7OPeBqNkj1um98Jt/dcBPG', 'Quản trị viên hệ thống', '0901234567', 'admin@vetclinic.com', 'ACTIVE');


-- ==============================================================================
-- PHẦN 2: PET_CLINIC_APPOINTMENT_DB (APPOINTMENT-SERVICE :8082)
-- ==============================================================================
CREATE DATABASE IF NOT EXISTS pet_clinic_appointment_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE pet_clinic_appointment_db;

-- 4. APPOINTMENTS (LỊCH HẸN KHÁM)
-- Đã bỏ: end_time (= start_time + 30 phút cố định), owner_id (suy ra từ pets.owner_id),
--        confirmed_by/at, cancelled_by/at, cancel_reason, updated_at (lấy từ bảng lịch sử).
CREATE TABLE IF NOT EXISTS appointments (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    appointment_code VARCHAR(50) NOT NULL UNIQUE,
    pet_id BIGINT NOT NULL, -- LFK: clinical.pets
    appointment_date DATE NOT NULL,
    start_time TIME NOT NULL, -- Giờ bắt đầu khung 30 phút
    reason TEXT NOT NULL,
    booking_channel ENUM('ONLINE', 'PHONE', 'WALK_IN') NOT NULL DEFAULT 'ONLINE',
    status ENUM('PENDING', 'CONFIRMED', 'CHECKED_IN', 'CANCELLED', 'NO_SHOW') NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_appointments_slot ON appointments(appointment_date, start_time, status);
CREATE INDEX idx_appointments_pet ON appointments(pet_id);

-- 5. APPOINTMENT_STATUS_HISTORIES (AUDIT TRAIL LỊCH HẸN)
-- Người duyệt / người hủy / lý do hủy / thời điểm đều được ghi ở đây.
CREATE TABLE IF NOT EXISTS appointment_status_histories (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    appointment_id BIGINT NOT NULL,
    from_status ENUM('PENDING', 'CONFIRMED', 'CHECKED_IN', 'CANCELLED', 'NO_SHOW') NULL,
    to_status ENUM('PENDING', 'CONFIRMED', 'CHECKED_IN', 'CANCELLED', 'NO_SHOW') NOT NULL,
    changed_by_user_id BIGINT NULL, -- LFK: auth.users (NULL = hệ thống tự quét NO_SHOW)
    notes TEXT NULL, -- Lý do hủy / từ chối / ghi chú
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ash_appointment FOREIGN KEY (appointment_id) REFERENCES appointments(id) ON DELETE CASCADE
);
CREATE INDEX idx_ash_appointment ON appointment_status_histories(appointment_id);
CREATE INDEX idx_ash_user ON appointment_status_histories(changed_by_user_id);


-- ==============================================================================
-- PHẦN 3: PET_CLINIC_CLINICAL_DB (CLINICAL-SERVICE :8083)
-- ==============================================================================
CREATE DATABASE IF NOT EXISTS pet_clinic_clinical_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE pet_clinic_clinical_db;

-- 6. SPECIES (DANH MỤC LOÀI)
CREATE TABLE IF NOT EXISTS species (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(255) NULL
);

-- 7. PETS (HỒ SƠ THÚ CƯNG)
-- Đã bỏ: weight (cân nặng hiện tại = weight_at_visit của đợt khám gần nhất).
CREATE TABLE IF NOT EXISTS pets (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    owner_id BIGINT NOT NULL, -- LFK: auth.users
    species_id BIGINT NOT NULL,
    pet_code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    breed VARCHAR(100) NULL,
    gender ENUM('MALE', 'FEMALE', 'UNKNOWN') NOT NULL DEFAULT 'UNKNOWN',
    date_of_birth DATE NULL,
    color VARCHAR(100) NULL,
    is_neutered BOOLEAN NOT NULL DEFAULT FALSE,
    identifying_characteristics TEXT NULL,
    notes TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_pets_species FOREIGN KEY (species_id) REFERENCES species(id)
);
CREATE INDEX idx_pets_owner ON pets(owner_id);

-- 8. SERVICES (DANH MỤC DỊCH VỤ)
CREATE TABLE IF NOT EXISTS services (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    category ENUM('EXAMINATION', 'VACCINATION', 'DEWORMING', 'EXTERNAL_PARASITE', 'INJECTION_INFUSION', 'LABORATORY', 'IMAGING', 'SURGERY', 'PROCEDURE') NOT NULL,
    price DECIMAL(12, 2) NOT NULL, -- Giá niêm yết hiện tại
    vat_rate DECIMAL(4, 2) NOT NULL DEFAULT 0.00, -- Thuế suất VAT hiện hành của dịch vụ
    description TEXT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_services_price CHECK (price >= 0),
    CONSTRAINT chk_services_vat CHECK (vat_rate >= 0 AND vat_rate <= 1)
);

-- 9. LAB_TEST_ITEMS (DANH MỤC CHỈ SỐ XÉT NGHIỆM)
CREATE TABLE IF NOT EXISTS lab_test_items (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    unit VARCHAR(30) NOT NULL,
    description VARCHAR(255) NULL
);

-- 10. SERVICE_LAB_TEST_ITEMS (BẢNG NỐI: GÓI XÉT NGHIỆM GỒM NHỮNG CHỈ SỐ NÀO) - MỚI
CREATE TABLE IF NOT EXISTS service_lab_test_items (
    service_id BIGINT NOT NULL,
    lab_test_item_id BIGINT NOT NULL,
    PRIMARY KEY (service_id, lab_test_item_id),
    CONSTRAINT fk_slti_service FOREIGN KEY (service_id) REFERENCES services(id),
    CONSTRAINT fk_slti_item FOREIGN KEY (lab_test_item_id) REFERENCES lab_test_items(id)
);

-- 11. LAB_TEST_REFERENCE_RANGES (KHOẢNG THAM CHIẾU THEO LOÀI)
CREATE TABLE IF NOT EXISTS lab_test_reference_ranges (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    lab_test_item_id BIGINT NOT NULL,
    species_id BIGINT NOT NULL,
    min_value DECIMAL(8, 2) NOT NULL,
    max_value DECIMAL(8, 2) NOT NULL,
    CONSTRAINT fk_ltrr_item FOREIGN KEY (lab_test_item_id) REFERENCES lab_test_items(id),
    CONSTRAINT fk_ltrr_species FOREIGN KEY (species_id) REFERENCES species(id),
    CONSTRAINT uq_ltrr_item_species UNIQUE (lab_test_item_id, species_id),
    CONSTRAINT chk_ltrr_range CHECK (min_value <= max_value)
);

-- 12. PET_VISITS (ĐỢT KHÁM NGOẠI TRÚ 2 PHA)
-- Đã bỏ: assigned_room (= users.room_number của bác sĩ), cancel_reason, started_at,
--        closed_at, completed_at (lấy từ pet_visit_status_histories).
-- Giữ checked_in_at: là thời điểm tạo bản ghi, dùng để xếp hàng đợi FIFO.
CREATE TABLE IF NOT EXISTS pet_visits (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    visit_code VARCHAR(50) NOT NULL UNIQUE,
    pet_id BIGINT NOT NULL,
    appointment_id BIGINT NULL UNIQUE, -- LFK: appointment.appointments (NULL = khách vãng lai)
    doctor_id BIGINT NULL, -- LFK: auth.users (bác sĩ được phân công)
    receptionist_id BIGINT NOT NULL, -- LFK: auth.users (lễ tân tiếp đón)
    is_emergency BOOLEAN NOT NULL DEFAULT FALSE,
    weight_at_visit DECIMAL(5, 2) NULL, -- Bác sĩ cân tại phòng khám
    temperature DECIMAL(4, 1) NULL, -- Bác sĩ đo tại phòng khám
    initial_symptoms TEXT NULL,
    clinical_notes TEXT NULL,
    diagnosis TEXT NULL,
    treatment_plan TEXT NULL,
    doctor_advice TEXT NULL,
    status ENUM('WAITING', 'IN_PROGRESS', 'WAITING_RESULTS', 'RESULTS_READY', 'WAITING_PAYMENT', 'COMPLETED', 'CANCELLED') NOT NULL DEFAULT 'WAITING',
    checked_in_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    queue_order BIGINT NOT NULL, -- Thứ tự trong hàng đợi (nhỏ gọi trước). Gán = thời điểm tiếp nhận (epoch micro giây), không đổi khi gọi; ca vừa có kết quả CLS = nhỏ nhất hàng đợi - 1
    last_called_at TIMESTAMP NULL, -- Lần "Gọi" / "Gọi lại" gần nhất của Bác sĩ; NULL = chưa được gọi. Chỉ để hiển thị "Đã gọi", không ảnh hưởng thứ tự
    version BIGINT NOT NULL DEFAULT 0, -- Khóa lạc quan
    CONSTRAINT fk_visits_pet FOREIGN KEY (pet_id) REFERENCES pets(id)
);
CREATE INDEX idx_visits_pet ON pet_visits(pet_id);
CREATE INDEX idx_visits_doctor_status ON pet_visits(doctor_id, status);
CREATE INDEX idx_visits_queue ON pet_visits(doctor_id, status, is_emergency, queue_order); -- Hàng đợi từng Bác sĩ; doctor_id IS NULL = danh sách chờ phân công
CREATE INDEX idx_visits_receptionist ON pet_visits(receptionist_id);

-- 13. PET_VISIT_STATUS_HISTORIES (AUDIT TRAIL ĐỢT KHÁM)
-- Thời điểm bắt đầu khám / chốt ca / hoàn tất / lý do hủy đều truy từ bảng này.
CREATE TABLE IF NOT EXISTS pet_visit_status_histories (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    visit_id BIGINT NOT NULL,
    from_status ENUM('WAITING', 'IN_PROGRESS', 'WAITING_RESULTS', 'RESULTS_READY', 'WAITING_PAYMENT', 'COMPLETED', 'CANCELLED') NULL,
    to_status ENUM('WAITING', 'IN_PROGRESS', 'WAITING_RESULTS', 'RESULTS_READY', 'WAITING_PAYMENT', 'COMPLETED', 'CANCELLED') NOT NULL,
    changed_by_user_id BIGINT NULL, -- LFK: auth.users (NULL = hệ thống tự chuyển)
    notes TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pvsh_visit FOREIGN KEY (visit_id) REFERENCES pet_visits(id) ON DELETE CASCADE
);
CREATE INDEX idx_pvsh_visit ON pet_visit_status_histories(visit_id);
CREATE INDEX idx_pvsh_user ON pet_visit_status_histories(changed_by_user_id);

-- 14. VISIT_SERVICE_DETAILS (CHỈ ĐỊNH DỊCH VỤ - THUẦN CHUYÊN MÔN)
-- Đã bỏ: unit_price, subtotal (thông tin tiền chuyển sang service_invoices).
CREATE TABLE IF NOT EXISTS visit_service_details (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    visit_id BIGINT NOT NULL,
    service_id BIGINT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    status ENUM('PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED') NOT NULL DEFAULT 'PENDING',
    notes TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    queue_order BIGINT NOT NULL, -- Thứ tự trong hàng đợi phòng XN / CĐHA (nhỏ gọi trước). Gán = thời điểm chỉ định (epoch micro giây), không đổi khi gọi
    last_called_at TIMESTAMP NULL, -- Lần KTV "Gọi" / "Gọi lại" gần nhất; gọi một ca thì cập nhật mọi dịch vụ PENDING cùng đợt khám, cùng phòng. NULL = chưa được gọi
    CONSTRAINT fk_vsd_visit FOREIGN KEY (visit_id) REFERENCES pet_visits(id),
    CONSTRAINT fk_vsd_service FOREIGN KEY (service_id) REFERENCES services(id),
    CONSTRAINT chk_vsd_quantity CHECK (quantity > 0)
);
CREATE INDEX idx_vsd_visit ON visit_service_details(visit_id);
CREATE INDEX idx_vsd_queue ON visit_service_details(status, queue_order); -- Hàng đợi phòng XN / CĐHA

-- 15. VISIT_SERVICE_DETAIL_HISTORIES (AUDIT TRAIL TIẾN ĐỘ DỊCH VỤ)
-- "Gọi" / "Gọi lại" không ghi lịch sử vì không đổi trạng thái hay thứ tự; chỉ cập nhật visit_service_details.last_called_at.
CREATE TABLE IF NOT EXISTS visit_service_detail_histories (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    visit_service_detail_id BIGINT NOT NULL,
    from_status ENUM('PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED') NULL,
    to_status ENUM('PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED') NOT NULL,
    action VARCHAR(50) NOT NULL, -- ORDERED, START_PROCESSING, SAMPLE_COLLECTED, COMPLETED, CANCELLED
    changed_by_user_id BIGINT NOT NULL, -- LFK: auth.users
    reason TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_vsdh_vsd FOREIGN KEY (visit_service_detail_id) REFERENCES visit_service_details(id) ON DELETE CASCADE
);
CREATE INDEX idx_vsdh_detail ON visit_service_detail_histories(visit_service_detail_id);
CREATE INDEX idx_vsdh_user ON visit_service_detail_histories(changed_by_user_id);

-- 16. LAB_TEST_RESULTS (KẾT QUẢ XÉT NGHIỆM)
-- Đã bỏ: evaluation (LOW/NORMAL/HIGH tính từ result_value so với min/max snapshot).
-- Giữ min/max snapshot: không dẫn xuất được vì danh mục tham chiếu có thể đổi sau này.
CREATE TABLE IF NOT EXISTS lab_test_results (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    visit_service_detail_id BIGINT NOT NULL,
    lab_test_item_id BIGINT NOT NULL,
    result_value DECIMAL(8, 2) NOT NULL,
    min_value_snapshot DECIMAL(8, 2) NOT NULL,
    max_value_snapshot DECIMAL(8, 2) NOT NULL,
    performed_by BIGINT NOT NULL, -- LFK: auth.users (LAB_TECHNICIAN)
    notes TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ltr_vsd FOREIGN KEY (visit_service_detail_id) REFERENCES visit_service_details(id),
    CONSTRAINT fk_ltr_item FOREIGN KEY (lab_test_item_id) REFERENCES lab_test_items(id),
    CONSTRAINT uq_ltr_vsd_item UNIQUE (visit_service_detail_id, lab_test_item_id)
);
CREATE INDEX idx_ltr_performer ON lab_test_results(performed_by);

-- 17. IMAGING_RESULTS (KẾT QUẢ CHẨN ĐOÁN HÌNH ẢNH)
CREATE TABLE IF NOT EXISTS imaging_results (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    visit_service_detail_id BIGINT NOT NULL UNIQUE,
    description TEXT NOT NULL,
    conclusion TEXT NOT NULL,
    performed_by BIGINT NOT NULL, -- LFK: auth.users (IMAGING_TECHNICIAN)
    performed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ir_vsd FOREIGN KEY (visit_service_detail_id) REFERENCES visit_service_details(id)
);
CREATE INDEX idx_ir_performer ON imaging_results(performed_by);

-- 18. IMAGING_ATTACHMENTS (TỆP ẢNH ĐÍNH KÈM)
CREATE TABLE IF NOT EXISTS imaging_attachments (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    imaging_result_id BIGINT NOT NULL,
    file_url VARCHAR(500) NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_size BIGINT NULL,
    content_type VARCHAR(50) NULL,
    CONSTRAINT fk_ia_result FOREIGN KEY (imaging_result_id) REFERENCES imaging_results(id) ON DELETE CASCADE
);
CREATE INDEX idx_ia_result ON imaging_attachments(imaging_result_id);

-- 19. SERVICE_INVOICES (HÓA ĐƠN RIÊNG CHO TỪNG DỊCH VỤ) - MỚI
-- Mỗi dòng chỉ định dịch vụ có đúng 1 hóa đơn (quan hệ 1-1).
-- Hóa đơn được tạo cùng lúc bác sĩ chỉ định (snapshot đơn giá & thuế suất tại thời điểm đó).
-- Dịch vụ bị hủy (EX-08) -> hóa đơn chuyển CANCELLED trong cùng giao dịch.
-- Số tiền phải trả = quantity * unit_price * (1 + vat_rate) - discount_amount (xem VIEW bên dưới).
CREATE TABLE IF NOT EXISTS service_invoices (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    invoice_code VARCHAR(50) NOT NULL UNIQUE,
    visit_service_detail_id BIGINT NOT NULL UNIQUE,
    unit_price DECIMAL(12, 2) NOT NULL, -- Snapshot đơn giá lúc chỉ định
    vat_rate DECIMAL(4, 2) NOT NULL DEFAULT 0.00, -- Snapshot thuế suất lúc chỉ định
    discount_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    payment_status ENUM('PENDING', 'PAID', 'CANCELLED') NOT NULL DEFAULT 'PENDING',
    cashier_id BIGINT NULL, -- LFK: auth.users (gán khi thu tiền)
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

-- VIEW tính tiền hóa đơn dịch vụ (không lưu giá trị dẫn xuất)
CREATE OR REPLACE VIEW v_service_invoice_amounts AS
SELECT si.id AS invoice_id,
       si.invoice_code,
       vsd.visit_id,
       s.id AS service_id,
       s.name AS service_name,
       s.category,
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
JOIN services s ON s.id = vsd.service_id;

-- Seed clinical-service
INSERT INTO species (code, name, description) VALUES
('DOG', 'Chó', 'Loài chó (Canis lupus familiaris)'),
('CAT', 'Mèo', 'Loài mèo (Felis catus)');

INSERT INTO services (code, name, category, price, vat_rate, description, is_active) VALUES
('EXAM_GEN', 'Khám lâm sàng tổng quát', 'EXAMINATION', 100000.00, 0.00, 'Khám tổng thể, kiểm tra thân nhiệt, cân nặng và triệu chứng', TRUE),
('VAC_7B', 'Tiêm phòng Vaccine 7 bệnh (Chó)', 'VACCINATION', 150000.00, 0.00, 'Công tiêm phòng vaccine phòng 7 bệnh truyền nhiễm', TRUE),
('VAC_4B', 'Tiêm phòng Vaccine 4 bệnh (Mèo)', 'VACCINATION', 150000.00, 0.00, 'Công tiêm phòng vaccine cho mèo', TRUE),
('DEWORM', 'Dịch vụ tẩy giun đường ruột', 'DEWORMING', 50000.00, 0.00, 'Công kiểm tra và hỗ trợ cho uống thuốc tẩy giun', TRUE),
('LAB_CBC', 'Xét nghiệm tổng phân tích tế bào máu (CBC)', 'LABORATORY', 250000.00, 0.00, 'Xét nghiệm chỉ số tế bào máu tự động', TRUE),
('IMG_US_AB', 'Siêu âm ổ bụng tổng quát', 'IMAGING', 200000.00, 0.00, 'Siêu âm màu kiểm tra các cơ quan nội tạng ổ bụng', TRUE),
('IMG_XRAY', 'Chụp X-quang kỹ thuật số (1 tư thế)', 'IMAGING', 180000.00, 0.00, 'Chụp X-quang tim phổi / xương khớp', TRUE);

INSERT INTO lab_test_items (code, name, unit, description) VALUES
('WBC', 'Bạch cầu (White Blood Cells)', '10^9/L', 'Số lượng bạch cầu tổng số'),
('RBC', 'Hồng cầu (Red Blood Cells)', '10^12/L', 'Số lượng hồng cầu tổng số'),
('HGB', 'Huyết sắc tố (Hemoglobin)', 'g/dL', 'Nồng độ huyết sắc tố'),
('PLT', 'Tiểu cầu (Platelets)', '10^9/L', 'Số lượng tiểu cầu');

-- Gói LAB_CBC (services.id = 5) gồm 4 chỉ số
INSERT INTO service_lab_test_items (service_id, lab_test_item_id) VALUES
(5, 1), (5, 2), (5, 3), (5, 4);

-- Chó (species_id = 1)
INSERT INTO lab_test_reference_ranges (lab_test_item_id, species_id, min_value, max_value) VALUES
(1, 1, 6.00, 17.00),
(2, 1, 5.50, 8.50),
(3, 1, 12.00, 18.00),
(4, 1, 200.00, 500.00);

-- Mèo (species_id = 2)
INSERT INTO lab_test_reference_ranges (lab_test_item_id, species_id, min_value, max_value) VALUES
(1, 2, 5.50, 19.50),
(2, 2, 5.00, 10.00),
(3, 2, 8.00, 15.00),
(4, 2, 300.00, 700.00);


-- ==============================================================================
-- PHẦN 4: PET_CLINIC_BILLING_PHARMACY_DB (BILLING-PHARMACY-SERVICE :8084)
-- ==============================================================================
-- Đơn thuốc là chỉ định chuyên môn của bác sĩ. Khách tự quyết định mua tại phòng khám
-- (sinh medicine_invoices, bán & trừ kho trong CÙNG 1 giao dịch) hoặc mua ngoài (không sinh hóa đơn).
CREATE DATABASE IF NOT EXISTS pet_clinic_billing_pharmacy_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE pet_clinic_billing_pharmacy_db;

-- 20. MEDICINES (DANH MỤC THUỐC & TỒN KHO)
-- stock_quantity là phi chuẩn hóa CÓ CHỦ ĐÍCH: về lý thuyết = SUM(inventory_transactions.quantity),
-- nhưng cần lưu để trừ kho nguyên tử (UPDATE ... WHERE stock_quantity >= :qty) và chống bán âm kho.
CREATE TABLE IF NOT EXISTS medicines (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    active_ingredient VARCHAR(150) NULL,
    dosage_form VARCHAR(50) NOT NULL,
    unit VARCHAR(30) NOT NULL,
    sale_price DECIMAL(12, 2) NOT NULL, -- Giá bán niêm yết hiện tại
    vat_rate DECIMAL(4, 2) NOT NULL DEFAULT 0.05, -- Thuế suất VAT hiện hành của thuốc
    stock_quantity INT NOT NULL DEFAULT 0,
    min_stock_alert INT NOT NULL DEFAULT 10,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    version BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT chk_med_price CHECK (sale_price >= 0),
    CONSTRAINT chk_med_vat CHECK (vat_rate >= 0 AND vat_rate <= 1),
    CONSTRAINT chk_med_stock CHECK (stock_quantity >= 0)
);

-- 21. PRESCRIPTIONS (ĐƠN THUỐC - CHỈ ĐỊNH CHUYÊN MÔN)
-- Đã bỏ: status, dispensed_by, dispensed_at (việc mua/xuất thuốc thể hiện qua medicine_invoices).
CREATE TABLE IF NOT EXISTS prescriptions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    visit_id BIGINT NOT NULL UNIQUE, -- LFK: clinical.pet_visits
    doctor_notes TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 22. PRESCRIPTION_ITEMS (CHI TIẾT THUỐC ĐƯỢC KÊ)
-- Đã bỏ: unit_price, subtotal (đơn thuốc không phải chứng từ tiền; giá chốt tại hóa đơn thuốc).
CREATE TABLE IF NOT EXISTS prescription_items (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    prescription_id BIGINT NOT NULL,
    medicine_id BIGINT NOT NULL,
    quantity INT NOT NULL, -- Số lượng bác sĩ kê
    dosage VARCHAR(100) NOT NULL,
    frequency VARCHAR(100) NOT NULL,
    duration_days INT NOT NULL,
    instructions TEXT NULL,
    CONSTRAINT fk_pi_prescription FOREIGN KEY (prescription_id) REFERENCES prescriptions(id) ON DELETE CASCADE,
    CONSTRAINT fk_pi_medicine FOREIGN KEY (medicine_id) REFERENCES medicines(id),
    CONSTRAINT uq_pi_prescription_medicine UNIQUE (prescription_id, medicine_id),
    CONSTRAINT chk_pi_quantity CHECK (quantity > 0),
    CONSTRAINT chk_pi_duration CHECK (duration_days > 0)
);

-- 23. MEDICINE_INVOICES (HÓA ĐƠN THUỐC - TÙY CHỌN, TỐI ĐA 1 / ĐƠN THUỐC) - MỚI
CREATE TABLE IF NOT EXISTS medicine_invoices (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    invoice_code VARCHAR(50) NOT NULL UNIQUE,
    prescription_id BIGINT NOT NULL UNIQUE,
    discount_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    payment_status ENUM('PENDING', 'PAID', 'CANCELLED') NOT NULL DEFAULT 'PENDING',
    cashier_id BIGINT NULL, -- LFK: auth.users (gán khi thu tiền)
    paid_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    version BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT fk_mi_prescription FOREIGN KEY (prescription_id) REFERENCES prescriptions(id),
    CONSTRAINT chk_mi_discount CHECK (discount_amount >= 0)
);
CREATE INDEX idx_mi_status_paid ON medicine_invoices(payment_status, paid_at);
CREATE INDEX idx_mi_cashier ON medicine_invoices(cashier_id);

-- 24. MEDICINE_INVOICE_ITEMS (CÁC THUỐC KHÁCH MUA TẠI PHÒNG KHÁM) - MỚI
-- Khách có thể mua một phần đơn: quantity <= prescription_items.quantity (kiểm tra ở tầng ứng dụng).
CREATE TABLE IF NOT EXISTS medicine_invoice_items (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    medicine_invoice_id BIGINT NOT NULL,
    prescription_item_id BIGINT NOT NULL,
    quantity INT NOT NULL, -- Số lượng khách mua
    unit_price DECIMAL(12, 2) NOT NULL, -- Snapshot giá bán lúc lập hóa đơn
    vat_rate DECIMAL(4, 2) NOT NULL, -- Snapshot thuế suất lúc lập hóa đơn
    CONSTRAINT fk_mii_invoice FOREIGN KEY (medicine_invoice_id) REFERENCES medicine_invoices(id) ON DELETE CASCADE,
    CONSTRAINT fk_mii_pitem FOREIGN KEY (prescription_item_id) REFERENCES prescription_items(id),
    CONSTRAINT uq_mii_invoice_pitem UNIQUE (medicine_invoice_id, prescription_item_id),
    CONSTRAINT chk_mii_quantity CHECK (quantity > 0),
    CONSTRAINT chk_mii_price CHECK (unit_price >= 0),
    CONSTRAINT chk_mii_vat CHECK (vat_rate >= 0 AND vat_rate <= 1)
);

-- 25. INVENTORY_TRANSACTIONS (NHẬT KÝ BIẾN ĐỘNG KHO)
-- Đã bỏ: balance_after (tồn sau giao dịch = tổng lũy kế quantity, tính bằng window function).
-- Thay reference_id chung chung bằng FK rõ ràng tới hóa đơn thuốc.
CREATE TABLE IF NOT EXISTS inventory_transactions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    medicine_id BIGINT NOT NULL,
    transaction_type ENUM('IMPORT', 'EXPORT_SALE', 'ADJUSTMENT') NOT NULL,
    quantity INT NOT NULL, -- Có dấu: + nhập / - xuất
    medicine_invoice_id BIGINT NULL, -- Bắt buộc khi EXPORT_SALE
    notes VARCHAR(255) NULL,
    created_by BIGINT NOT NULL, -- LFK: auth.users
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_it_medicine FOREIGN KEY (medicine_id) REFERENCES medicines(id),
    CONSTRAINT fk_it_invoice FOREIGN KEY (medicine_invoice_id) REFERENCES medicine_invoices(id),
    CONSTRAINT chk_it_quantity CHECK (quantity <> 0)
);
CREATE INDEX idx_it_med_date ON inventory_transactions(medicine_id, created_at);
CREATE INDEX idx_it_creator ON inventory_transactions(created_by);

-- VIEW tính tiền hóa đơn thuốc (không lưu giá trị dẫn xuất)
CREATE OR REPLACE VIEW v_medicine_invoice_amounts AS
SELECT mi.id AS invoice_id,
       mi.invoice_code,
       p.visit_id,
       mi.discount_amount,
       ROUND(SUM(mii.quantity * mii.unit_price), 2) AS amount_before_vat,
       ROUND(SUM(mii.quantity * mii.unit_price * mii.vat_rate), 2) AS vat_amount,
       ROUND(SUM(mii.quantity * mii.unit_price * (1 + mii.vat_rate)) - mi.discount_amount, 2) AS payable_amount,
       mi.payment_status,
       mi.paid_at
FROM medicine_invoices mi
JOIN prescriptions p ON p.id = mi.prescription_id
JOIN medicine_invoice_items mii ON mii.medicine_invoice_id = mi.id
GROUP BY mi.id, mi.invoice_code, p.visit_id, mi.discount_amount, mi.payment_status, mi.paid_at;

-- Seed billing-pharmacy-service
INSERT INTO medicines (code, name, active_ingredient, dosage_form, unit, sale_price, vat_rate, stock_quantity, min_stock_alert, is_active) VALUES
('MED_AMOX', 'Clavamox 250mg', 'Amoxicillin + Clavulanate', 'Viên nén', 'Viên', 15000.00, 0.05, 200, 20, TRUE),
('MED_VANG_7B', 'Vaccine Vanguard Plus 5/L (7 bệnh)', 'Attenuated Virus', 'Lọ tiêm', 'Lọ', 180000.00, 0.05, 50, 10, TRUE),
('MED_PURE_4B', 'Vaccine Purevax RCP (Mèo)', 'Attenuated Virus', 'Lọ tiêm', 'Lọ', 190000.00, 0.05, 40, 10, TRUE),
('MED_DRON_DOG', 'Drontal Plus tẩy giun cho chó', 'Febantel, Pyrantel, Praziquantel', 'Viên nén', 'Viên', 45000.00, 0.05, 100, 15, TRUE);

-- Nhập kho ban đầu được ghi nhật ký để thỏa bất biến: stock_quantity = SUM(quantity)
INSERT INTO inventory_transactions (medicine_id, transaction_type, quantity, notes, created_by) VALUES
(1, 'IMPORT', 200, 'Tồn kho đầu kỳ', 1),
(2, 'IMPORT', 50, 'Tồn kho đầu kỳ', 1),
(3, 'IMPORT', 40, 'Tồn kho đầu kỳ', 1),
(4, 'IMPORT', 100, 'Tồn kho đầu kỳ', 1);

-- ==============================================================================
-- TRUY VẤN DOANH THU MẪU (không cần thuộc tính tổng tiền)
-- ==============================================================================
-- Doanh thu dịch vụ theo nhóm trong tháng (clinical-service):
--   SELECT category, SUM(payable_amount) FROM pet_clinic_clinical_db.v_service_invoice_amounts
--   WHERE payment_status = 'PAID' AND paid_at >= '2026-11-01' AND paid_at < '2026-12-01'
--   GROUP BY category;
-- Doanh thu thuốc trong tháng (billing-pharmacy-service):
--   SELECT SUM(payable_amount) FROM pet_clinic_billing_pharmacy_db.v_medicine_invoice_amounts
--   WHERE payment_status = 'PAID' AND paid_at >= '2026-11-01' AND paid_at < '2026-12-01';
-- Tồn kho sau từng giao dịch (thay cho balance_after):
--   SELECT id, medicine_id, quantity,
--          SUM(quantity) OVER (PARTITION BY medicine_id ORDER BY created_at, id) AS balance_after
--   FROM pet_clinic_billing_pharmacy_db.inventory_transactions;
