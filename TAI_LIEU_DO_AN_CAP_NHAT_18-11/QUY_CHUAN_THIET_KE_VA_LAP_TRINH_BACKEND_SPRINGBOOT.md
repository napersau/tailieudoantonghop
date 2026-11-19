# QUY CHUẨN THIẾT KẾ VÀ LẬP TRÌNH BACKEND (JAVA 21 & SPRING BOOT 4.1.1)
## HỆ THỐNG QUẢN LÝ PHÒNG KHÁM THÚ Y (MICROSERVICES ARCHITECTURE)
### PHIÊN BẢN 4.0 (PRODUCTION-GRADE STANDARDS – đồng bộ lược đồ CSDL v4.0 và Kiến trúc v4.0, 18/11/2026)

> **Tài liệu quy chuẩn kỹ thuật bắt buộc (Mandatory Engineering Standards)**  
> **Áp dụng cho:** Toàn bộ thành viên đội ngũ phát triển Backend (Lưu Minh Hiển, Nguyễn Đức Khởi, Vũ Hồng Linh).  
> **Mục tiêu:** Đồng bộ hóa 100% phong cách lập trình (Code Style), kiến trúc phân tầng, định dạng API, quản lý giao dịch CSDL, an toàn concurrency kho dược, xử lý ngoại lệ và giao tiếp phân tán liên Microservice.  
> **Điểm mới v4.0:** khóa UUIDv7 (`java.util.UUID`), Transactional Outbox + consumer idempotent (Chương 9), hàng đợi trên Redis bằng Lua script (mục 9.3), bảng giá có lịch sử (`PriceBook`), hóa đơn thuốc nháp từ `PrescriptionCreatedEvent` (8.2), `reporting-service`, trạng thái lưu `VARCHAR` + enum Java, header `X-User-Roles` nhiều vai trò, ảnh lưu `file_key`.

---

## MỤC LỤC TỔNG QUAN

1. [Chương 1: Khung Công nghệ & Phiên bản Chuẩn (Tech Stack)](#chương-1-khung-công-nghệ--phiên-bản-chuẩn)
2. [Chương 2: Chuẩn Cấu trúc Dự án Maven & Package Thư mục](#chương-2-chuẩn-cấu-trúc-dự-án-maven--package-thư-mục)
3. [Chương 3: Quy chuẩn Đặt tên & Thiết kế RESTful API (Naming & URI Standards)](#chương-3-quy-chuẩn-đặt-tên--thiết-kế-restful-api)
4. [Chương 4: Chuẩn hóa Định dạng Phản hồi API (Unified API Envelope)](#chương-4-chuẩn-hóa-định-dạng-phản-hồi-api-unified-api-envelope)
5. [Chương 5: Cơ chế Bắt lỗi & Ngoại lệ Tập trung (Global Exception Handling)](#chương-5-cơ-chế-bắt-lỗi--ngoại-lệ-tập-trung-global-exception-handling)
6. [Chương 6: Quy chuẩn DTO, Validation & Object Mapping (Lombok + MapStruct)](#chương-6-quy-chuẩn-dto-validation--object-mapping)
7. [Chương 7: Quy chuẩn Tầng Dữ liệu & Persistence (Spring Data JPA)](#chương-7-quy-chuẩn-tầng-dữ-liệu--persistence-spring-data-jpa)
8. [Chương 8: Quản lý Giao dịch CSDL & An toàn Concurrency Kho Dược](#chương-8-quản-lý-giao-dịch-csdl--an-toàn-concurrency-kho-dược)
9. [Chương 9: Quy chuẩn Giao tiếp Liên Dịch vụ (OpenFeign & RabbitMQ)](#chương-9-quy-chuẩn-giao-tiếp-liên-dịch-vụ-openfeign--rabbitmq)
10. [Chương 10: Quy chuẩn Bảo mật & Phân quyền Truy cập (Security & RBAC)](#chương-10-quy-chuẩn-bảo-mật--phân-quyền-truy-cập-security--rbac)
11. [Chương 11: Mẫu Cấu hình Maven (pom.xml) & Mã nguồn Tham chiếu Chuẩn](#chương-11-mẫu-cấu-hình-maven-pomxml--mã-nguồn-tham-chiếu-chuẩn)

---

## CHƯƠNG 1: KHUNG CÔNG NGHỆ & PHIÊN BẢN CHUẨN

Tất cả các dịch vụ Backend bắt buộc phải chạy trên cùng một nền tảng công nghệ thống nhất, tương thích chính xác giữa Spring Boot 4.x và Spring Cloud:

| Thành phần kỹ thuật | Phiên bản chuẩn hóa | Ghi chú & Mục đích sử dụng |
| :--- | :---: | :--- |
| **Java Platform** | **Java 21 LTS** | Khuyến nghị Eclipse Temurin 21 hoặc Oracle JDK 21. Tận dụng Record Patterns, Sequenced Collections. |
| **Backend Framework** | **Spring Boot 4.1.1** | Nền tảng microservices cốt lõi (dòng 4.1, phát hành 06/2026; bản vá 4.1.1 tháng 08/2026), tích hợp Spring Framework 7.x và Jackson 3. |
| **Spring Cloud** | **2025.1.2 (Oakwood) trở lên** | Bản 2025.1.2 là bản Spring Cloud đầu tiên hỗ trợ Spring Boot 4.1 (bản 2025.1.0 / 2025.1.1 chỉ chạy với Boot 4.0 và sẽ báo lỗi tương thích khi khởi động). Tuyệt đối không dùng 2023.x / 2024.x của Boot 3. |
| **Build Tool** | **Apache Maven 3.9+** | Quản lý vòng đời build, dependencies tập trung qua Parent POM. |
| **Service Discovery** | **Spring Cloud Netflix Eureka** | Module `service-registry` (:8761). |
| **API Gateway** | **Spring Cloud Gateway** | Module `api-gateway` (:8080) - **Nền tảng Reactive (WebFlux)**. |
| **Data Persistence** | **Spring Data JPA / Hibernate** | Jakarta Persistence API (Jakarta EE). Cấu hình `open-in-view = false`. |
| **Database Engine** | **MySQL 8.0+** | Database-per-Service: 5 logical schemas (auth, appointment, clinical, billing_pharmacy, reporting). Khóa thực thể `BINARY(16)` (UUIDv7). |
| **Cache / Hàng đợi** | **Redis 7 + Spring Data Redis** | Chỉ `clinical-service`: hàng đợi phiếu (Sorted Set, Hash, Lua script). Bật AOF. |
| **Khả năng chịu lỗi** | **Resilience4j (Spring Cloud CircuitBreaker)** | Circuit Breaker + timeout cho mọi Feign client. |
| **Message Broker** | **RabbitMQ (AMQP 0-9-1)** | Topic Exchange `clinic.events` (:5672) với JSON Converter. |
| **Boilerplate Code** | **Project Lombok** | Sinh Getters, Setters, Builders tại compile-time. |
| **Object Mapper** | **MapStruct 1.5+** | Sinh code chuyển đổi Entity $\leftrightarrow$ DTO tại compile-time (chế độ cảnh báo `unmappedTargetPolicy = WARN`). |
| **Input Validation** | **Jakarta Bean Validation** | Kiểm soát tính toàn vẹn dữ liệu đầu vào (`@NotNull`, `@NotBlank`, ...). |
| **Containerization** | **Docker & Docker Compose** | Đóng gói toàn bộ hệ thống; chỉ public port của Gateway (:8080) ra ngoài. |

---

## CHƯƠNG 2: CHUẨN CẤU TRÚC DỰ ÁN MAVEN & PACKAGE THƯ MỤC

### 2.1. Cấu trúc Multi-Module Maven của Hệ thống
Mã nguồn Backend được tổ chức dưới dạng Maven Multi-Module với Parent `pom.xml` **chỉ quản lý dependencyManagement**, không ép cứng dependency Servlet MVC lên toàn bộ dự án:

```text
vetclinic-backend/
├── pom.xml                               # Parent POM: Quản lý dependencyManagement và pluginManagement
├── common-library/                       # Thư viện dùng chung (ApiResponse, ErrorCode, BaseEvent, Utils) + Auto-Configuration servlet có điều kiện
│   ├── pom.xml                           # KHÔNG phụ thuộc spring-boot-starter-web (để Gateway WebFlux dùng được)
│   └── src/main/java/com/vetclinic/common/
├── service-registry/                     # Eureka Service Registry (:8761)
│   ├── pom.xml
│   └── src/main/java/com/vetclinic/registry/
├── api-gateway/                          # Spring Cloud Gateway (:8080) - Dùng spring-boot-starter-webflux
│   ├── pom.xml
│   └── src/main/java/com/vetclinic/gateway/
├── auth-service/                         # Dịch vụ xác thực & người dùng (:8081) - Dùng spring-boot-starter-web
│   ├── pom.xml
│   └── src/main/java/com/vetclinic/auth/
├── appointment-service/                  # Cổng đặt lịch hẹn trực tuyến (:8082) - Dùng spring-boot-starter-web
│   ├── pom.xml
│   └── src/main/java/com/vetclinic/appointment/
├── clinical-service/                     # Thú cưng, khám lâm sàng 2 pha, hóa đơn dịch vụ (:8083) - Dùng spring-boot-starter-web
│   ├── pom.xml
│   └── src/main/java/com/vetclinic/clinical/
├── billing-pharmacy-service/             # Danh mục thuốc, giá, tồn kho, hóa đơn thuốc (:8084) - Dùng spring-boot-starter-web
│   ├── pom.xml
│   └── src/main/java/com/vetclinic/billing/
├── notification-service/                 # Dịch vụ WebSocket & email (:8085) - Dùng spring-boot-starter-web
│   ├── pom.xml
│   └── src/main/java/com/vetclinic/notification/
└── reporting-service/                    # Mô hình đọc cho báo cáo, chỉ ghi bằng sự kiện (:8086) - Dùng spring-boot-starter-web
    ├── pom.xml
    └── src/main/java/com/vetclinic/reporting/
```

### 2.2. Quy tắc nạp cấu hình dùng chung từ `common-library` (Auto-Configuration)
> [!IMPORTANT]
> **Không dùng `scanBasePackages = "com.vetclinic"`.** Nếu mọi service quét chung package, các lớp servlet trong `common-library` (`GlobalExceptionHandler`, `CommonSecurityConfig`, `HeaderAuthenticationFilter`) sẽ bị nạp cả vào `api-gateway` (WebFlux) và `service-registry`, làm hai thành phần này lỗi khi khởi động.

Quy chuẩn bắt buộc:

1. **Mỗi service chỉ quét package của chính nó** (mặc định của `@SpringBootApplication`):
   ```java
   @SpringBootApplication          // chỉ quét com.vetclinic.clinical.*
   @EnableFeignClients
   public class ClinicalServiceApplication {
       public static void main(String[] args) {
           SpringApplication.run(ClinicalServiceApplication.class, args);
       }
   }
   ```
2. **`common-library` chia 2 phần:**
   - `com.vetclinic.common.dto`, `.exception`, `.event`, `.util`: lớp thuần (POJO, enum, record), không gắn `@Component` / `@Configuration`; mọi module đều dùng được.
   - `com.vetclinic.common.web`: cấu hình servlet (`GlobalExceptionHandler`, `CommonSecurityConfig`, `HeaderAuthenticationFilter`, `FeignClientInterceptor`, `CustomFeignErrorDecoder`), **được nạp bằng Spring Boot Auto-Configuration có điều kiện**, không qua component scan.
3. **Lớp auto-configuration duy nhất:**
   ```java
   package com.vetclinic.common.web;

   @AutoConfiguration
   @ConditionalOnWebApplication(type = ConditionalOnWebApplication.Type.SERVLET) // Gateway (REACTIVE) bỏ qua
   @Import({GlobalExceptionHandler.class, CommonSecurityConfig.class})
   public class CommonWebAutoConfiguration {

       @Bean
       @ConditionalOnClass(name = "feign.RequestInterceptor")   // chỉ khi service có OpenFeign
       public FeignClientInterceptor feignClientInterceptor() { return new FeignClientInterceptor(); }

       @Bean
       @ConditionalOnClass(name = "feign.codec.ErrorDecoder")
       public CustomFeignErrorDecoder customFeignErrorDecoder(ObjectMapper objectMapper) {
           return new CustomFeignErrorDecoder(objectMapper);
       }

       @Bean
       @ConditionalOnClass(name = "feign.FeignException")
       public FeignExceptionHandler feignExceptionHandler() { return new FeignExceptionHandler(); }
   }
   ```
   Đăng ký trong file `common-library/src/main/resources/META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports`:
   ```text
   com.vetclinic.common.web.CommonWebAutoConfiguration
   ```
4. **Phụ thuộc của `common-library` khai báo `<optional>true</optional>`** (spring-boot-starter-web, spring-boot-starter-security, spring-cloud-starter-openfeign) để không kéo Servlet MVC sang Gateway. Mỗi service servlet tự khai báo các starter này trong `pom.xml` của mình.
5. **`service-registry` không phụ thuộc `common-library`.** `api-gateway` chỉ dùng phần lớp thuần (DTO, ErrorCode) nếu cần.

### 2.3. Cấu trúc Package nội bộ trong mỗi Microservice
```text
com.vetclinic.<servicename>/
├── config/                  # Cấu hình Spring (Security, OpenFeign, RabbitMQ, WebMvc, OpenAPI)
├── controller/              # Tầng Trình diễn: Tiếp nhận HTTP Requests (@RestController)
├── service/                 # Tầng Nghiệp vụ: Định nghĩa Interfaces chuyên môn
│   └── impl/                # Cài đặt cụ thể các phương thức nghiệp vụ (@Service)
├── repository/              # Tầng Truy xuất dữ liệu: Spring Data JPA Interfaces (@Repository)
├── entity/                  # Tầng Thực thể CSDL: JPA Entities (@Entity, @Table)
├── dto/                     # Tầng Truyền tải dữ liệu
│   ├── request/             # Request DTO nhận từ Client (@Valid)
│   └── response/            # Response DTO gửi về cho Client
├── mapper/                  # Chuyển đổi dữ liệu MapStruct (@Mapper)
├── client/                  # OpenFeign Interfaces gọi sang Microservice khác (@FeignClient)
├── event/                   # Event DTOs cụ thể & Consumer RabbitMQ (@RabbitListener)
├── outbox/                  # OutboxEvent entity, OutboxWriter, OutboxRelay (mọi service phát sự kiện) – Chương 9
├── queue/                   # Chỉ clinical-service: QueueRedisRepository, Lua scripts, QueueIssuerListener, QueueRebuildJob – mục 9.3
└── constant/                # Enum nội bộ (lưu VARCHAR), Hằng số nghiệp vụ riêng của service
```

---

## CHƯƠNG 3: QUY CHUẨN ĐẶT TÊN & THIẾT KẾ RESTFUL API

### 3.1. Quy chuẩn Java Code Style & Kiểu Dữ liệu Bắt buộc
- **Java Platform:** Java 21 LTS. DTOs có thể sử dụng `record` (bất biến) hoặc class thường với Lombok.
- **Tiền tệ & Số thực tài chính:** **Bắt buộc dùng `BigDecimal`** (ví dụ: `unitPrice`, `vatRate`, `discountAmount`; tổng tiền không lưu mà tính khi cần). Tuyệt đối cấm dùng `double` hoặc `float` gây sai số làm tròn số tiền.
- **Thời gian (Timestamp):** Dùng `Instant` cho thời điểm giao dịch (`checkedInAt`, `paidAt`, `createdAt`). Lưu trữ dạng UTC trong Database; tầng hiển thị Frontend hoặc DTO Response chuyển đổi sang múi giờ Việt Nam (`Asia/Ho_Chi_Minh` - GMT+7).
- **Hằng số & Enum:** `UPPER_SNAKE_CASE` (ví dụ: `WAITING_RESULTS`, `EXPORT_SALE`). Khớp 100% với `DANH_SACH_KIEU_ENUM_HE_THONG.md` v4.0: **18 enum Java lưu `VARCHAR`** (`@Enumerated(EnumType.STRING)`, cột `length = 20/30`) + `LabEvaluation` chỉ ở ứng dụng. **Không dùng kiểu ENUM của MySQL.** Vai trò, nhóm dịch vụ, loài, nhóm thuốc là **bảng danh mục** (entity `Role`, `ServiceCategory`, `Species`, `MedicineCategory`), code tham chiếu bằng `code` (hằng trong `RoleCodes`, `CategoryCodes`), không tham chiếu bằng `id`.
- **Khóa chính & tham chiếu (v4.0):** thực thể nghiệp vụ dùng `java.util.UUID` sinh bằng `@UuidGenerator(style = UuidGenerator.Style.VERSION_7)`, cột `BINARY(16)`; dữ liệu chỉ thêm dùng `Long` + `IDENTITY`; danh mục dùng `Short` + `IDENTITY`. Mọi id trong URL, DTO, sự kiện là chuỗi UUID 36 ký tự (`@PathVariable UUID id`). Khóa ngoại logic sang service khác khai báo là `UUID` thuần (không `@ManyToOne`).
- **Snapshot:** cột `*Snapshot` (ví dụ `doctorNameSnapshot`) chỉ được ghi lúc tạo và bởi listener sự kiện cập nhật tên; không đọc snapshot để ra quyết định nghiệp vụ (kiểm tra Bác sĩ còn `ACTIVE` phải gọi Feign).

### 3.2. Quy chuẩn Thiết kế RESTful API URIs & Prefix Thống nhất
Nhằm đồng bộ hoàn toàn giữa **Spring Cloud Gateway**, **Controller** và **OpenFeign Clients**, toàn bộ URI tuân thủ quy tắc tiền tố:

| Microservice | Prefix URI qua Gateway & Controller | Ví dụ Endpoint CRUD | Ví dụ Action Endpoint (Động từ) |
| :--- | :--- | :--- | :--- |
| **`auth-service`** | `/api/v1/auth/**`<br>`/api/v1/users/**`<br>`/api/v1/staff/**`<br>`/api/v1/roles/**` | `GET /api/v1/users/me` (tài khoản + hồ sơ chung)<br>`GET /api/v1/staff`, `GET /api/v1/staff/{id}` (hồ sơ nhân sự + hồ sơ chuyên môn)<br>`GET /api/v1/staff/doctors` (danh sách Bác sĩ kèm chuyên khoa, cho trang đặt lịch)<br>`GET /api/v1/roles` | `POST /api/v1/auth/login`, `/refresh`, `/logout`, `/register` (khách tự đăng ký)<br>`POST /api/v1/staff` (tạo tài khoản + `user_profiles` + `staff_profiles` [+ `veterinarian_profiles`] trong 1 giao dịch)<br>`PUT /api/v1/users/{id}/profile`, `PUT /api/v1/staff/{id}/vet-profile`<br>`PUT /api/v1/users/{id}/roles`<br>`POST /api/v1/users/{id}/lock`, `/unlock`, `/deactivate` (xóa mềm) |
| **`appointment-service`** | `/api/v1/appointments/**` | `GET /api/v1/appointments`<br>`GET /api/v1/appointments/slots?date=` | `POST /api/v1/appointments/{id}/confirm`<br>`POST /api/v1/appointments/{id}/cancel` |
| **`clinical-service`** | `/api/v1/clinical/**`<br>`/api/v1/pets/**`<br>`/api/v1/species/**`<br>`/api/v1/catalog/**` | `GET /api/v1/clinical/pet-visits`<br>`GET /api/v1/clinical/pet-visits/queue` (bảng điều phối, đọc Redis)<br>`GET /api/v1/clinical/pet-visits/my-queue` (hàng đợi Bác sĩ, đọc Redis)<br>`GET /api/v1/clinical/lab-queue`, `/imaging-queue`<br>`GET /api/v1/clinical/cashier/pending?section=EXAM_FEE\|PARACLINIC\|FINAL`<br>`GET /api/v1/clinical/doctors/status`<br>`GET /api/v1/clinical/pet-visits/{id}/medical-record`, `/vital-signs`, `/prescription`, `/service-invoices`<br>`GET /api/v1/catalog/services?categoryCode=` (kèm giá đang áp dụng)<br>`GET /api/v1/catalog/services/{id}/prices` (lịch sử giá)<br>`GET /api/v1/clinical/imaging-attachments/{id}/url` (URL ký tạm 1 giờ)<br>`GET /api/v1/pets/{id}` | `POST /api/v1/clinical/pet-visits/check-in`<br>`POST /api/v1/clinical/pet-visits/{id}/assign-doctor`, `/unassign-doctor`<br>`POST /api/v1/clinical/queue-tickets/call-next?queueType=DOCTOR\|LABORATORY\|IMAGING`<br>`POST /api/v1/clinical/queue-tickets/{ticketId}/call` (Redis: tăng `calledCount`)<br>`POST /api/v1/clinical/queue-tickets/{ticketId}/start` (phòng XN / CĐHA)<br>`POST /api/v1/clinical/pet-visits/{id}/start-exam`, `/start-phase2`, `/close-visit`, `/reopen`<br>`POST /api/v1/clinical/pet-visits/{id}/vital-signs` (thêm một lần đo)<br>`PUT /api/v1/clinical/pet-visits/{id}/medical-record` (`@Version`)<br>`PUT /api/v1/clinical/pet-visits/{id}/prescription` (lưu cả đơn; chỉ khi ca `IN_PROGRESS`)<br>`POST /api/v1/clinical/service-details/{id}/cancel`<br>`POST /api/v1/clinical/service-invoices/{id}/discount`<br>`POST /api/v1/clinical/pet-visits/{id}/service-invoices/confirm-payment`<br>`POST /api/v1/catalog/services/{id}/prices` (ADMIN đổi giá: đóng dòng cũ + thêm dòng mới) |
| **`billing-pharmacy-service`** | `/api/v1/pharmacy/**`<br>`/api/v1/billing/**` | `GET /api/v1/pharmacy/medicines` (kèm thành phần, quy cách, giá hiện hành, tồn)<br>`GET /api/v1/pharmacy/medicines/{id}/prices` (lịch sử giá)<br>`GET /api/v1/billing/medicine-invoices?visitId=` (hóa đơn nháp của ca)<br>`GET /api/v1/billing/medicine-invoices/{id}` | `POST /api/v1/pharmacy/medicines` (thuốc + thành phần + giá đầu + dòng tồn = 0)<br>`POST /api/v1/pharmacy/medicines/{id}/prices` (ADMIN đổi giá)<br>`POST /api/v1/pharmacy/medicines/{id}/import`, `/adjust` (nhập / cân chỉnh kho)<br>`PUT /api/v1/billing/medicine-invoices/{id}/items` (sửa số lượng / bỏ dòng khi `PENDING`)<br>`POST /api/v1/billing/medicine-invoices/{id}/confirm-payment` (thu tiền + trừ kho)<br>`POST /api/v1/billing/medicine-invoices/{id}/cancel` (khách mua ngoài). Hóa đơn thuốc **không có API tạo**: chỉ sinh từ `PrescriptionCreatedEvent`. |
| **`notification-service`** | `/api/v1/notifications/**`<br>`/ws/**` | `GET /api/v1/notifications` (thông báo của người dùng hiện tại) | `POST /api/v1/notifications/{id}/read`. Không có API gửi email công khai: Email / WebSocket chỉ được kích hoạt bởi sự kiện RabbitMQ. |
| **`reporting-service`** | `/api/v1/reports/**` | `GET /api/v1/reports/revenue/daily?from=&to=&type=SERVICE\|MEDICINE`<br>`GET /api/v1/reports/revenue/by-category?month=`<br>`GET /api/v1/reports/doctors/performance?from=&to=`<br>`GET /api/v1/reports/visits/summary?date=` | Không có API ghi (chỉ listener sự kiện). Chỉ vai trò `ADMIN`. |

> [!NOTE]
> **Quy tắc về Action Endpoint:** Đối với các thao tác chuyển đổi trạng thái nghiệp vụ (bắt đầu khám, chốt ca, mở lại hồ sơ, xác nhận thanh toán, bán thuốc), cho phép dùng động từ ở cuối URI nhưng **bắt buộc dùng phương thức `POST`**, và tầng Service phải chống bấm trùng (kiểm tra trạng thái nguồn + `@Version`).
>
> **Endpoint nội bộ:** lời gọi Feign giữa các service dùng tiền tố `/internal/**` (ví dụ `GET /internal/medicines?keyword=`). Gateway **không định tuyến** tiền tố này ra ngoài. Danh mục lời gọi Feign theo `THIET_KE_KIEN_TRUC_MICROSERVICES.md` mục 5.1.


---

## CHƯƠNG 4: CHUẨN HÓA ĐỊNH DẠNG PHẢN HỒI API (UNIFIED API ENVELOPE)

### 4.1. Cấu trúc Lớp `ApiResponse<T>` Chuẩn mực
Bổ sung trường `errorCode` để hỗ trợ Frontend và `CustomErrorDecoder` của OpenFeign nhận diện chính xác mã lỗi nghiệp vụ:

```java
package com.vetclinic.common.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.*;

import java.time.Instant;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ApiResponse<T> {
    private int status;            // Mã HTTP Status (200, 201, 400, 403, 404, 500)
    private String errorCode;      // Mã lỗi nghiệp vụ (VD: "CLIN_1302"), null nếu thành công
    private String message;        // Thông điệp phản hồi thân thiện
    private T data;                // Dữ liệu payload nghiệp vụ
    @Builder.Default
    private Instant timestamp = Instant.now();

    public static <T> ApiResponse<T> success(T data) {
        return ApiResponse.<T>builder()
                .status(200)
                .message("Thao tác thành công")
                .data(data)
                .build();
    }

    public static <T> ApiResponse<T> success(String message, T data) {
        return ApiResponse.<T>builder()
                .status(200)
                .message(message)
                .data(data)
                .build();
    }

    public static <T> ApiResponse<T> created(String message, T data) {
        return ApiResponse.<T>builder()
                .status(201)
                .message(message)
                .data(data)
                .build();
    }
}
```

> [!IMPORTANT]
> **Đồng bộ giữa HTTP Header Status và Body Status:**  
> Khi tạo mới thành công, Controller phải trả về `ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.created(...))` để mã HTTP Header thật sự là **201**, tránh tình trạng Header trả về 200 trong khi Body ghi 201.

### 4.2. Chuẩn hóa Phân trang `PageResponse<T>`
```java
package com.vetclinic.common.dto;

import lombok.*;
import java.util.List;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PageResponse<T> {
    private List<T> items;
    private int page;
    private int size;
    private long totalElements;
    private int totalPages;
    private boolean last; // Đặt tên là 'last' để khớp với JSON property chuẩn của Jackson
}
```

---

## CHƯƠNG 5: CƠ CHẾ BẮT LỖI & NGOẠI LỆ TẬP TRUNG (GLOBAL EXCEPTION HANDLING)

### 5.1. Danh mục Mã lỗi `ErrorCode` Đầy đủ
> v4.0: **49 mã** (41 mã cũ + 8 mã mới:  `AUTH_1107`, `AUTH_1108`, `CLIN_1315`–`CLIN_1318`, `BILL_1410`, `PHARM_1412`; `PHARM_1407 PRESCRIPTION_ALREADY_INVOICED` nay báo khi nhận trùng `PrescriptionCreatedEvent` và chỉ ghi log). Mã `PHARM_1404`, `PHARM_1411` giữ số cũ nhưng do `clinical-service` trả về vì đơn thuốc đã chuyển sang đây.

```java
package com.vetclinic.common.exception;

import lombok.Getter;
import org.springframework.http.HttpStatus;

@Getter
public enum ErrorCode {
    // 1. Hệ thống chung (SYS: 1000 - 1099)
    UNCATEGORIZED_EXCEPTION("SYS_1000", "Lỗi hệ thống không xác định, vui lòng thử lại sau", HttpStatus.INTERNAL_SERVER_ERROR),
    INVALID_INPUT_DATA("SYS_1001", "Dữ liệu đầu vào không hợp lệ", HttpStatus.BAD_REQUEST),
    UNAUTHORIZED("SYS_1002", "Chưa đăng nhập hoặc token đã hết hạn", HttpStatus.UNAUTHORIZED),
    ACCESS_DENIED("SYS_1003", "Bạn không có quyền thực hiện thao tác này", HttpStatus.FORBIDDEN),
    SERVICE_UNAVAILABLE("SYS_1004", "Dịch vụ liên quan hiện không phản hồi, vui lòng thử lại sau", HttpStatus.SERVICE_UNAVAILABLE),
    OPTIMISTIC_LOCK_CONFLICT("SYS_1005", "Dữ liệu vừa được người khác cập nhật, vui lòng tải lại trang", HttpStatus.CONFLICT),

    // 2. Người dùng & Xác thực (AUTH: 1100 - 1199)
    USER_NOT_FOUND("AUTH_1101", "Không tìm thấy người dùng", HttpStatus.NOT_FOUND),
    PHONE_NUMBER_ALREADY_EXISTS("AUTH_1102", "Số điện thoại đã được đăng ký trong hệ thống", HttpStatus.CONFLICT),
    INVALID_CREDENTIALS("AUTH_1103", "Tên đăng nhập hoặc mật khẩu không chính xác", HttpStatus.UNAUTHORIZED),
    REFRESH_TOKEN_NOT_FOUND("AUTH_1104", "Không tìm thấy phiên Refresh Token", HttpStatus.UNAUTHORIZED),
    REFRESH_TOKEN_REVOKED("AUTH_1105", "Refresh Token đã bị thu hồi hoặc đã qua sử dụng (Cảnh báo bảo mật)", HttpStatus.UNAUTHORIZED),
    REFRESH_TOKEN_EXPIRED("AUTH_1106", "Refresh Token đã hết hạn, vui lòng đăng nhập lại", HttpStatus.UNAUTHORIZED),
    ACCOUNT_DISABLED("AUTH_1107", "Tài khoản đã bị khóa hoặc ngừng sử dụng", HttpStatus.UNAUTHORIZED),          // v4.0
    VET_PROFILE_REQUIRED("AUTH_1108", "Tài khoản Bác sĩ phải có hồ sơ chuyên môn (số chứng chỉ hành nghề)", HttpStatus.BAD_REQUEST), // v4.0

    // 3. Thú cưng & Lịch hẹn (APPT: 1200 - 1299)
    PET_NOT_FOUND("APPT_1201", "Không tìm thấy hồ sơ thú cưng", HttpStatus.NOT_FOUND),
    APPOINTMENT_NOT_FOUND("APPT_1202", "Không tìm thấy lịch hẹn", HttpStatus.NOT_FOUND),
    SLOT_CAPACITY_EXCEEDED("APPT_1203", "Khung giờ khám đã kín chỗ, vui lòng chọn khung giờ khác", HttpStatus.BAD_REQUEST),
    CANNOT_CANCEL_APPOINTMENT("APPT_1204", "Chỉ được phép hủy hẹn trước giờ khám tối thiểu 2 tiếng", HttpStatus.BAD_REQUEST),
    APPOINTMENT_NOT_CHECKABLE("APPT_1205", "Lịch hẹn không ở trạng thái CONFIRMED hoặc không đúng ngày hẹn", HttpStatus.BAD_REQUEST),

    // 4. Khám lâm sàng & Cận lâm sàng (CLIN: 1300 - 1399)
    VISIT_NOT_FOUND("CLIN_1301", "Không tìm thấy đợt khám y tế", HttpStatus.NOT_FOUND),
    DOCTOR_NOT_AVAILABLE("CLIN_1302", "Bác sĩ đang khám một ca khác, hãy kết thúc ca hiện tại trước", HttpStatus.CONFLICT),
    QUEUE_EMPTY("CLIN_1303", "Hàng đợi hiện không còn bệnh nhân nào", HttpStatus.NOT_FOUND),
    PARACLINICAL_SERVICE_IN_PROGRESS("CLIN_1304", "Dịch vụ cận lâm sàng đang thực hiện, không thể hủy", HttpStatus.BAD_REQUEST),
    INVALID_STATUS_TRANSITION("CLIN_1305", "Trạng thái ca khám không hợp lệ để thực hiện thao tác này", HttpStatus.BAD_REQUEST),
    PET_HAS_OPEN_VISIT("CLIN_1306", "Thú cưng đang có đợt khám chưa kết thúc", HttpStatus.CONFLICT),
    DIAGNOSIS_REQUIRED("CLIN_1307", "Vui lòng nhập chẩn đoán trước khi chốt đợt khám", HttpStatus.BAD_REQUEST),
    VITAL_SIGNS_REQUIRED("CLIN_1308", "Vui lòng nhập cân nặng và thân nhiệt của thú cưng", HttpStatus.BAD_REQUEST),
    IN_ROOM_SERVICE_PENDING("CLIN_1309", "Còn dịch vụ tại phòng chưa thực hiện hoặc chưa hủy", HttpStatus.BAD_REQUEST),
    REFUND_NOT_ALLOWED("CLIN_1310", "Phí khám và dịch vụ khách tự hủy không được hoàn tiền", HttpStatus.CONFLICT),
    NOT_ASSIGNED_DOCTOR("CLIN_1311", "Bạn không phải Bác sĩ được phân công cho ca khám này", HttpStatus.FORBIDDEN),
    TICKET_NOT_FOUND("CLIN_1312", "Không tìm thấy phiếu xếp hàng", HttpStatus.NOT_FOUND),
    TICKET_NOT_WAITING("CLIN_1313", "Phiếu không còn ở trạng thái chờ gọi", HttpStatus.CONFLICT),
    NO_QUEUE_TICKET("CLIN_1314", "Ca chưa có phiếu xếp hàng (khách chưa nộp phí khám / tiền dịch vụ)", HttpStatus.BAD_REQUEST),
    SERVICE_PRICE_NOT_FOUND("CLIN_1315", "Dịch vụ chưa có giá đang áp dụng", HttpStatus.CONFLICT),                // v4.0
    DOCTOR_INACTIVE("CLIN_1316", "Bác sĩ được chọn đã bị khóa hoặc ngừng làm việc", HttpStatus.CONFLICT),          // v4.0
    MEDICAL_RECORD_LOCKED("CLIN_1317", "Hồ sơ khám đã khóa (đợt khám đã chốt), không thể chỉnh sửa", HttpStatus.CONFLICT), // v4.0
    QUEUE_UNAVAILABLE("CLIN_1318", "Hàng đợi tạm thời không truy cập được, vui lòng thử lại sau ít giây", HttpStatus.SERVICE_UNAVAILABLE), // v4.0 (Redis lỗi)

    // 5. Hóa đơn & Kho dược (BILL/PHARM: 1400 - 1499) – dùng cho cả service_invoices (clinical) và medicine_invoices (billing-pharmacy)
    INVOICE_NOT_FOUND("BILL_1401", "Không tìm thấy hóa đơn", HttpStatus.NOT_FOUND),
    DISCOUNT_EXCEEDS_INVOICE_AMOUNT("BILL_1402", "Số tiền giảm giá không được vượt quá số tiền của hóa đơn này", HttpStatus.BAD_REQUEST),
    INVOICE_ALREADY_PAID("BILL_1403", "Hóa đơn này đã được thanh toán trước đó", HttpStatus.CONFLICT),
    INVOICE_ALREADY_CANCELLED("BILL_1408", "Hóa đơn này đã bị hủy", HttpStatus.CONFLICT),
    VISIT_NOT_READY_FOR_PAYMENT("BILL_1409", "Dịch vụ làm tại phòng chỉ thu khi Bác sĩ đã chốt chuyên môn", HttpStatus.BAD_REQUEST),
    PRICE_EFFECTIVE_DATE_INVALID("BILL_1410", "Thời điểm hiệu lực của giá mới phải sau thời điểm bắt đầu của giá đang áp dụng", HttpStatus.BAD_REQUEST), // v4.0
    MEDICINE_PRICE_NOT_FOUND("PHARM_1412", "Thuốc chưa có giá bán đang áp dụng", HttpStatus.CONFLICT),           // v4.0
    PRESCRIPTION_NOT_FOUND("PHARM_1404", "Không tìm thấy đơn thuốc của đợt khám", HttpStatus.NOT_FOUND),   // v4.0: dùng ở clinical-service (giữ mã cũ)
    MEDICINE_NOT_FOUND("PHARM_1405", "Không tìm thấy thuốc trong danh mục kho", HttpStatus.NOT_FOUND),
    INSUFFICIENT_STOCK("PHARM_1406", "Số lượng tồn kho không đủ để bán", HttpStatus.CONFLICT),
    PRESCRIPTION_ALREADY_INVOICED("PHARM_1407", "Đơn thuốc này đã được lập hóa đơn thuốc trước đó", HttpStatus.CONFLICT),
    PRESCRIPTION_LOCKED("PHARM_1411", "Đơn thuốc đã khóa (đợt khám đã chốt), không thể chỉnh sửa", HttpStatus.CONFLICT); // v4.0: dùng ở clinical-service

    private final String code;
    private final String message;
    private final HttpStatus httpStatus;

    ErrorCode(String code, String message, HttpStatus httpStatus) {
        this.code = code;
        this.message = message;
        this.httpStatus = httpStatus;
    }
}
```

### 5.2. Bộ Xử lý Ngoại lệ Toàn cục `@RestControllerAdvice` (Chuẩn An ninh)
```java
package com.vetclinic.common.web;   // nạp qua CommonWebAutoConfiguration (@Import), không qua component scan

import com.vetclinic.common.dto.ApiResponse;
import com.vetclinic.common.exception.AppException;
import com.vetclinic.common.exception.ErrorCode;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.HashMap;
import java.util.Map;

@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    // 1. Bắt ngoại lệ nghiệp vụ do ứng dụng ném ra
    @ExceptionHandler(AppException.class)
    public ResponseEntity<ApiResponse<Object>> handleAppException(AppException ex) {
        ErrorCode errorCode = ex.getErrorCode();
        ApiResponse<Object> response = ApiResponse.builder()
                .status(errorCode.getHttpStatus().value())
                .errorCode(errorCode.getCode())
                .message(ex.getMessage() != null ? ex.getMessage() : errorCode.getMessage())
                .build();
        return ResponseEntity.status(errorCode.getHttpStatus()).body(response);
    }

    // 2. Bắt lỗi phân quyền Spring Security (@PreAuthorize) -> Bắt buộc trả về HTTP 403
    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ApiResponse<Object>> handleAccessDeniedException(AccessDeniedException ex) {
        ErrorCode errorCode = ErrorCode.ACCESS_DENIED;
        ApiResponse<Object> response = ApiResponse.builder()
                .status(HttpStatus.FORBIDDEN.value())
                .errorCode(errorCode.getCode())
                .message(errorCode.getMessage())
                .build();
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(response);
    }

    // 3. Bắt lỗi Validation DTO (@Valid)
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Map<String, String>>> handleValidationException(MethodArgumentNotValidException ex) {
        Map<String, String> errors = new HashMap<>();
        for (FieldError fieldError : ex.getBindingResult().getFieldErrors()) {
            errors.put(fieldError.getField(), fieldError.getDefaultMessage());
        }
        ApiResponse<Map<String, String>> response = ApiResponse.<Map<String, String>>builder()
                .status(HttpStatus.BAD_REQUEST.value())
                .errorCode(ErrorCode.INVALID_INPUT_DATA.getCode())
                .message("Dữ liệu đầu vào không hợp lệ")
                .data(errors)
                .build();
        return ResponseEntity.badRequest().body(response);
    }

    // 4. Bắt lỗi định dạng JSON gửi lên bị sai cú pháp
    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ApiResponse<Object>> handleHttpMessageNotReadable(HttpMessageNotReadableException ex) {
        ApiResponse<Object> response = ApiResponse.builder()
                .status(HttpStatus.BAD_REQUEST.value())
                .errorCode(ErrorCode.INVALID_INPUT_DATA.getCode())
                .message("Định dạng dữ liệu JSON không hợp lệ hoặc thiếu Body")
                .build();
        return ResponseEntity.badRequest().body(response);
    }

    // 5. Bắt lỗi hệ thống chung không xác định (Log chi tiết ở server, ẩn stacktrace với client)
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Object>> handleGeneralException(Exception ex) {
        log.error("Unhandled system error: ", ex);
        ApiResponse<Object> response = ApiResponse.builder()
                .status(HttpStatus.INTERNAL_SERVER_ERROR.value())
                .errorCode(ErrorCode.UNCATEGORIZED_EXCEPTION.getCode())
                .message("Hệ thống phát sinh sự cố, quản trị viên đã ghi nhận để khắc phục")
                .build();
        return ResponseEntity.internalServerError().body(response);
    }
}
```

> **Lỗi kết nối Feign** (`feign.FeignException`, ví dụ service đích không phản hồi) được xử lý ở lớp riêng `FeignExceptionHandler`, chỉ đăng ký khi service có OpenFeign trên classpath. Nếu đặt chung trong `GlobalExceptionHandler`, service không dùng Feign (ví dụ `notification-service`) sẽ lỗi `NoClassDefFoundError` khi khởi động.

```java
package com.vetclinic.common.web;

@Slf4j
@RestControllerAdvice
public class FeignExceptionHandler {   // đăng ký trong CommonWebAutoConfiguration với @ConditionalOnClass(name = "feign.FeignException")

    @ExceptionHandler(feign.FeignException.class)
    public ResponseEntity<ApiResponse<Object>> handleFeignException(feign.FeignException ex) {
        log.error("Feign client communication error: status = {}, message = {}", ex.status(), ex.getMessage());
        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(ApiResponse.builder()
                .status(HttpStatus.SERVICE_UNAVAILABLE.value())
                .errorCode(ErrorCode.SERVICE_UNAVAILABLE.getCode())
                .message("Không thể kết nối đến dịch vụ phụ thuộc, vui lòng thử lại sau")
                .build());
    }
}
```

---

## CHƯƠNG 6: QUY CHUẨN DTO, VALIDATION & OBJECT MAPPING

### 6.1. Quy tắc Vàng: Không bao giờ Expose Entity ra ngoài API
- 100% Request gửi lên phải dùng **RequestDTO** kèm Jakarta Validation.
- 100% Dữ liệu trả về phải qua **ResponseDTO**.

### 6.2. Cấu hình MapStruct trên Java 21
Đặt `unmappedTargetPolicy = ReportingPolicy.WARN` để trình biên dịch cảnh báo nếu lập trình viên quên ánh xạ trường dữ liệu:

```java
package com.vetclinic.clinical.mapper;

import com.vetclinic.clinical.dto.request.CreatePetRequest;
import com.vetclinic.clinical.dto.response.PetResponse;
import com.vetclinic.clinical.entity.Pet;
import org.mapstruct.*;

@Mapper(componentModel = "spring", unmappedTargetPolicy = ReportingPolicy.WARN)
public interface PetMapper {
    @Mapping(target = "speciesName", source = "species.name")
    PetResponse toResponse(Pet pet);

    Pet toEntity(CreatePetRequest request);

    @BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
    void updateEntityFromRequest(CreatePetRequest request, @MappingTarget Pet pet);
}
```

---

## CHƯƠNG 7: QUY CHUẨN TẦNG DỮ LIỆU & PERSISTENCE (SPRING DATA JPA)

### 7.1. Cấu hình Bắt buộc trong `application.yml`
```yaml
spring:
  jpa:
    open-in-view: false        # TẮT Open-in-View để giải phóng connection ngay sau khi Service kết thúc
    hibernate:
      ddl-auto: validate       # Không để Hibernate tự ý sửa cấu trúc bảng trên môi trường thực tế
    properties:
      hibernate:
        format_sql: true
        jdbc:
          batch_size: 50       # Tối ưu hóa ghi hàng loạt
```

### 7.2. Khóa chính UUIDv7, kiểu cột và ánh xạ Entity (v4.0)

| Loại bảng | Kiểu Java | Ánh xạ |
| :--- | :--- | :--- |
| Thực thể nghiệp vụ (`users`, `pets`, `pet_visits`, `services`, `medicines`, hóa đơn, đơn thuốc...) | `UUID` | `@Id @UuidGenerator(style = UuidGenerator.Style.VERSION_7) @Column(columnDefinition = "BINARY(16)")` |
| Dữ liệu chỉ thêm (lịch sử, dòng giá, nhật ký kho, outbox...) | `Long` | `@Id @GeneratedValue(strategy = GenerationType.IDENTITY)` |
| Danh mục (`roles`, `species`, `service_categories`, `medicine_categories`, `lab_test_items`) | `Short` | `@Id @GeneratedValue(strategy = GenerationType.IDENTITY)`; code nghiệp vụ dùng cột `code` |
| Quan hệ 1–1 mở rộng (`user_profiles`, `medical_records`, `medicine_stocks`...) | `UUID` | `@Id` + `@MapsId` trên `@OneToOne` tới bảng cha |
| Cột trạng thái | enum Java | `@Enumerated(EnumType.STRING) @Column(length = 20)` – cột `VARCHAR`, không phải `ENUM` |

```java
package com.vetclinic.billing.entity;

@Entity
@Table(name = "medicines")
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class Medicine {

    @Id
    @UuidGenerator(style = UuidGenerator.Style.VERSION_7)   // sinh ở ứng dụng, tăng dần theo thời gian
    @Column(columnDefinition = "BINARY(16)")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "category_id")
    private MedicineCategory category;                        // bảng danh mục, không phải enum

    @Column(nullable = false, unique = true, length = 50) private String code;
    @Column(nullable = false, length = 150) private String name;
    @Column(name = "dosage_form", nullable = false, length = 50) private String dosageForm;
    @Column(length = 50) private String strength;
    @Column(name = "base_unit", nullable = false, length = 30) private String baseUnit;
    @Column(name = "packaging_spec", nullable = false, length = 150) private String packagingSpec;
    @Column(length = 150) private String manufacturer;
    @Column(name = "requires_prescription", nullable = false) private boolean requiresPrescription;
    @Column(name = "min_stock_alert", nullable = false) private int minStockAlert;
    @Column(name = "is_active", nullable = false) private boolean active;   // xóa mềm

    @OneToMany(mappedBy = "medicine", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<MedicineIngredient> ingredients = new ArrayList<>();
    // KHÔNG có giá và tồn kho: giá ở MedicinePrice (lịch sử), tồn ở MedicineStock (1–1)
}

@Entity
@Table(name = "medicine_stocks")
@Getter @Setter @NoArgsConstructor
public class MedicineStock {
    @Id
    @Column(name = "medicine_id", columnDefinition = "BINARY(16)")
    private UUID medicineId;

    @OneToOne(fetch = FetchType.LAZY) @MapsId @JoinColumn(name = "medicine_id")
    private Medicine medicine;

    @Column(name = "quantity_on_hand", nullable = false)
    private int quantityOnHand;          // chỉ đổi qua deduct / import / adjust, luôn kèm dòng inventory_transactions

    @Version
    private Long version;                // khóa lạc quan
}
```

> **Lưu ý:** Hibernate ánh xạ `java.util.UUID` sang `BINARY(16)` trên MySQL; `columnDefinition` để `ddl-auto: validate` khớp chính xác `schema_init.sql`. Không dùng `UUID.randomUUID()` (v4, ngẫu nhiên) làm khóa vì gây phân mảnh chỉ mục.

### 7.3. Kiểm soát Concurrency với `@Version`
Bắt buộc `@Version` trên các entity có thể bị sửa đồng thời: `PetVisit`, `MedicalRecord`, `VisitServiceDetail`, `ServiceInvoice`, `MedicineInvoice`, `MedicineStock`, `Appointment`, `User`. Xung đột → `ObjectOptimisticLockingFailureException` → `GlobalExceptionHandler` trả `SYS_1005`. **Phiếu xếp hàng không còn là entity** (nằm ở Redis, mục 9.3) nên không còn xung đột phiên bản khi gọi số.

### 7.4. Bảng giá có lịch sử (`PriceBook`)
Giá dịch vụ (`service_prices`) và giá thuốc (`medicine_prices`) dùng chung quy tắc: dòng giá **không bao giờ bị sửa số tiền hay xóa**; đổi giá = đóng dòng đang mở + thêm dòng mới trong một giao dịch; hóa đơn chụp `unitPrice`, `vatRate` từ dòng đang hiệu lực.

```java
// ServicePriceRepository (clinical-service)
@Query("""
        SELECT p FROM ServicePrice p
        WHERE p.service.id = :serviceId AND p.effectiveFrom <= :at
          AND (p.effectiveTo IS NULL OR p.effectiveTo > :at)
        """)
Optional<ServicePrice> findEffective(@Param("serviceId") UUID serviceId, @Param("at") LocalDateTime at);

Optional<ServicePrice> findByServiceIdAndEffectiveToIsNull(UUID serviceId);   // dòng đang mở

// ServicePriceBook
@Service
@RequiredArgsConstructor
public class ServicePriceBook {
    private final ServicePriceRepository priceRepository;

    /** Giá dùng để lập hóa đơn lúc chỉ định / tiếp đón. */
    public ServicePrice current(UUID serviceId) {
        return priceRepository.findEffective(serviceId, LocalDateTime.now(CLINIC_ZONE))
                .orElseThrow(() -> new AppException(ErrorCode.SERVICE_PRICE_NOT_FOUND));   // CLIN_1315
    }

    /** ADMIN đổi giá (UC quản lý danh mục). Có thể đặt giá có hiệu lực trong tương lai. */
    @Transactional(rollbackFor = Exception.class)
    public ServicePrice changePrice(UUID serviceId, ChangePriceRequest req, UUID adminId) {
        ServicePrice open = priceRepository.findByServiceIdAndEffectiveToIsNull(serviceId)
                .orElseThrow(() -> new AppException(ErrorCode.SERVICE_PRICE_NOT_FOUND));
        if (!req.effectiveFrom().isAfter(open.getEffectiveFrom())) {
            throw new AppException(ErrorCode.PRICE_EFFECTIVE_DATE_INVALID);              // BILL_1410
        }
        open.setEffectiveTo(req.effectiveFrom());                                       // chỉ đóng, không sửa tiền
        return priceRepository.save(ServicePrice.builder()
                .service(open.getService()).price(req.price()).vatRate(req.vatRate())
                .effectiveFrom(req.effectiveFrom()).changeReason(req.reason()).createdBy(adminId)
                .build());                                                              // UNIQUE(service_id, effective_from)
    }
}
```
`MedicinePriceBook` trong `billing-pharmacy-service` giống hệt (bảng `medicine_prices`, lỗi `PHARM_1412`).

### 7.5. Tệp ảnh: lưu `file_key`, trả URL ký tạm
- Khi tải lên: `file_key = "imaging/" + yyyy + "/" + MM + "/" + UUIDv7 + "." + đuôi`; ghi tệp vào thư mục gốc cấu hình `app.storage.root` (Docker Volume); lưu `file_key`, `original_file_name`, `content_type`, `file_size`, `uploaded_by`.
- Khi đọc: `GET /api/v1/clinical/imaging-attachments/{id}/url` kiểm tra quyền rồi trả `"/files/" + fileKey + "?exp=" + epoch + "&sig=" + HMAC_SHA256(fileKey + exp, app.storage.secret)`, hạn 1 giờ. Endpoint `/files/**` kiểm tra chữ ký và hạn trước khi trả tệp.
- Không lưu URL tuyệt đối trong CSDL: đổi máy chủ, tên miền hay chuyển sang kho đối tượng chỉ đổi cấu hình.

---

## CHƯƠNG 8: QUẢN LÝ GIAO DỊCH CSDL & AN TOÀN CONCURRENCY KHO DƯỢC

### 8.0. Nguyên tắc chung
- Mỗi nghiệp vụ tiền / kho nằm trọn trong CSDL của **một** service, bọc trong **một** `@Transactional(rollbackFor = Exception.class)`.
- **Sự kiện ghi vào `outbox_events` trong cùng giao dịch** bằng `OutboxWriter` (mục 9.2). Không gọi `rabbitTemplate` trong nghiệp vụ; không dùng `@TransactionalEventListener(AFTER_COMMIT)` để gửi sự kiện nghiệp vụ nữa.
- **Không gọi Feign bên trong `@Transactional`.** Kiểm tra liên service (Bác sĩ còn `ACTIVE`, tra thuốc) làm ở lớp Facade trước khi gọi phương thức giao dịch.
- **Không gọi Redis bên trong `@Transactional` để thay đổi phiếu.** Thao tác Redis chạy sau commit (`TransactionSynchronization.afterCommit`) hoặc trong listener sự kiện; dữ liệu cần cho lịch sử phiếu được đọc từ Redis trước khi mở giao dịch.
- **Không lưu tổng tiền.** Tính bằng VIEW hoặc trong code.

### 8.1. Trừ kho Nguyên tử (Atomic SQL Update) trên `medicine_stocks`

```java
@Repository
public interface MedicineStockRepository extends JpaRepository<MedicineStock, UUID> {

    @Modifying(flushAutomatically = true)
    @Query("UPDATE MedicineStock s SET s.quantityOnHand = s.quantityOnHand - :qty, s.version = s.version + 1 " +
           "WHERE s.medicineId = :id AND s.quantityOnHand >= :qty")
    int deduct(@Param("id") UUID medicineId, @Param("qty") int quantity);          // 0 dòng = thiếu kho

    @Modifying(flushAutomatically = true)
    @Query("UPDATE MedicineStock s SET s.quantityOnHand = s.quantityOnHand + :qty, s.version = s.version + 1 " +
           "WHERE s.medicineId = :id")
    int add(@Param("id") UUID medicineId, @Param("qty") int quantity);             // nhập kho / cân chỉnh dương

    @Query(value = "SELECT BIN_TO_UUID(s.medicine_id) AS id, s.quantity_on_hand AS qty FROM medicine_stocks s " +
                   "JOIN medicines m ON m.id = s.medicine_id " +
                   "WHERE s.medicine_id IN (:ids) AND s.quantity_on_hand <= m.min_stock_alert", nativeQuery = true)
    List<LowStockRow> findLowStock(@Param("ids") List<UUID> ids);
}
```
Tách tồn kho khỏi `medicines` nên dòng bị cập nhật liên tục khi bán là dòng nhỏ của `medicine_stocks`; sửa thông tin thuốc (quy cách, nhà sản xuất) không đụng tới, không gây xung đột `@Version`.

### 8.2. Mẫu chuẩn: Hóa đơn thuốc nháp từ đơn thuốc & Thu tiền + Trừ kho (`billing-pharmacy-service`)
1. **Tạo nháp (listener):** nhận `PrescriptionCreatedEvent` (phát khi Bác sĩ chốt ca) → tạo `medicine_invoices` `PENDING` + các dòng theo đơn (`prescribedQuantity = quantity` = số kê; giá từ `MedicinePriceBook`). Không có API tạo hóa đơn thuốc.
2. **Sửa nháp (UC-36):** Thu ngân đổi số lượng theo khách (được nhiều hơn / ít hơn số kê, không vượt tồn kho – BR-32) hoặc bỏ dòng; cập nhật lại giá theo dòng giá hiện hành.
3. **Thu tiền:** trong **một giao dịch**: trừ `medicine_stocks` có điều kiện → ghi `inventory_transactions` (`EXPORT_SALE`, âm) → `PAID` → outbox `MedicineInvoicePaidEvent` (+ `MedicineLowStockEvent`). Thiếu kho ở bất kỳ dòng nào thì rollback toàn bộ (EX-15).

```java
@Slf4j
@Component
@RequiredArgsConstructor
public class PrescriptionCreatedListener {

    private final IdempotentConsumer idempotent;            // mục 9.2
    private final MedicineSaleService saleService;

    @RabbitListener(queues = "billing.prescription-created")
    public void on(PrescriptionCreatedEvent e) {
        idempotent.run(e.eventId(), "billing.prescription-created", () -> saleService.createDraft(e));
    }
}

@Slf4j
@Service
@RequiredArgsConstructor
public class MedicineSaleServiceImpl implements MedicineSaleService {

    private final MedicineRepository medicineRepository;
    private final MedicineStockRepository stockRepository;
    private final MedicineInvoiceRepository invoiceRepository;
    private final InventoryTransactionRepository inventoryRepository;
    private final MedicinePriceBook priceBook;
    private final InvoiceCodeGenerator codeGenerator;
    private final OutboxWriter outbox;

    /** Bước 1 – gọi trong giao dịch của IdempotentConsumer. */
    @Override
    public void createDraft(PrescriptionCreatedEvent e) {
        Optional<MedicineInvoice> existing = invoiceRepository.findByPrescriptionId(e.prescriptionId());
        if (existing.isPresent()) {                                            // UNIQUE(prescription_id)
            MedicineInvoice inv = existing.get();
            if (inv.getPaymentStatus() == PaymentStatus.PENDING) {             // Bác sĩ mở lại hồ sơ (T14) rồi chốt lại
                inv.clearItems();                                               // dựng lại nháp theo đơn mới
                addLines(inv, e);
            } else {
                log.warn("{}: đơn {} đã có hóa đơn {}", ErrorCode.PRESCRIPTION_ALREADY_INVOICED.getCode(),
                        e.prescriptionId(), inv.getPaymentStatus());
            }
            return;
        }
        MedicineInvoice invoice = MedicineInvoice.builder()
                .invoiceCode(codeGenerator.next("MINV"))
                .prescriptionId(e.prescriptionId()).visitId(e.visitId())
                .customerNameSnapshot(e.customerName()).customerPhoneSnapshot(e.customerPhone())
                .petNameSnapshot(e.petName()).doctorNameSnapshot(e.doctorName())
                .discountAmount(BigDecimal.ZERO).paymentStatus(PaymentStatus.PENDING)
                .build();
        addLines(invoice, e);
        invoiceRepository.save(invoice);
    }

    private void addLines(MedicineInvoice invoice, PrescriptionCreatedEvent e) {
        for (var line : e.items()) {
            Medicine med = medicineRepository.getReferenceById(line.medicineId());
            MedicinePrice price = priceBook.current(line.medicineId());
            invoice.addItem(MedicineInvoiceItem.builder()
                    .medicine(med)
                    .prescribedQuantity(line.quantity())                        // số kê, để đối chiếu
                    .quantity(line.quantity())                                  // mặc định mua đúng đơn
                    .unitPrice(price.getSalePrice()).vatRate(price.getVatRate())
                    .build());
        }
    }

    /** Bước 2 – sửa dòng khi PENDING: medicineId -> số lượng mới (0 = bỏ dòng). */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public MedicineInvoice updateItems(UUID invoiceId, Map<UUID, Integer> newQuantities, BigDecimal discount) {
        MedicineInvoice invoice = loadPending(invoiceId);
        for (var entry : newQuantities.entrySet()) {
            MedicineInvoiceItem item = invoice.findItemByMedicineId(entry.getKey())
                    .orElseThrow(() -> new AppException(ErrorCode.INVALID_INPUT_DATA));      // chỉ thuốc có trong đơn
            int qty = entry.getValue();
            if (qty == 0) { invoice.removeItem(item); continue; }
            int onHand = stockRepository.findById(entry.getKey()).orElseThrow().getQuantityOnHand();
            if (qty < 0 || qty > onHand) throw new AppException(ErrorCode.INSUFFICIENT_STOCK); // BR-32
            item.setQuantity(qty);
        }
        if (invoice.getItems().isEmpty()) {
            throw new AppException(ErrorCode.INVALID_INPUT_DATA, "Khách không mua thuốc nào: hãy hủy hóa đơn thuốc");
        }
        if (discount != null) invoice.setDiscountAmount(discount);
        if (invoice.getDiscountAmount().compareTo(invoice.grossAmount()) > 0) {
            throw new AppException(ErrorCode.DISCOUNT_EXCEEDS_INVOICE_AMOUNT);                // EX-14
        }
        return invoice;                                                                       // @Version khi flush
    }

    /** Bước 3 – PAID + trừ kho + EXPORT_SALE + outbox trong CÙNG MỘT giao dịch. */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public MedicineInvoice confirmPayment(UUID invoiceId, UUID cashierId) {
        MedicineInvoice invoice = loadPending(invoiceId);
        // giá chốt tại thời điểm thu (bảng giá có thể đã đổi từ lúc tạo nháp)
        invoice.getItems().forEach(i -> {
            MedicinePrice p = priceBook.current(i.getMedicine().getId());
            i.setUnitPrice(p.getSalePrice()); i.setVatRate(p.getVatRate());
        });
        List<MedicineInvoiceItem> items = invoice.getItems().stream()
                .sorted(Comparator.comparing(i -> i.getMedicine().getId()))   // cùng thứ tự khóa dòng -> tránh deadlock
                .toList();
        for (MedicineInvoiceItem item : items) {
            if (stockRepository.deduct(item.getMedicine().getId(), item.getQuantity()) == 0) {
                throw new AppException(ErrorCode.INSUFFICIENT_STOCK,
                        "Thuốc [" + item.getMedicine().getName() + "] không đủ tồn kho"); // EX-15: rollback toàn bộ
            }
            inventoryRepository.save(InventoryTransaction.exportSale(item, invoice, cashierId)); // quantity âm
        }
        invoice.markPaid(cashierId, Instant.now());
        outbox.write("MEDICINE_INVOICE", invoice.getId(), "pharmacy.medicine_invoice_paid",
                MedicineInvoicePaidEvent.of(invoice));                                // reporting + notification
        stockRepository.findLowStock(items.stream().map(i -> i.getMedicine().getId()).toList())
                .forEach(r -> outbox.write("MEDICINE", r.id(), "pharmacy.low_stock", new MedicineLowStockEvent(r.id(), r.qty())));
        return invoice;
    }

    private MedicineInvoice loadPending(UUID id) {
        MedicineInvoice inv = invoiceRepository.findById(id).orElseThrow(() -> new AppException(ErrorCode.INVOICE_NOT_FOUND));
        switch (inv.getPaymentStatus()) {
            case PAID -> throw new AppException(ErrorCode.INVOICE_ALREADY_PAID);            // EX-16
            case CANCELLED -> throw new AppException(ErrorCode.INVOICE_ALREADY_CANCELLED);
            default -> { }
        }
        return inv;
    }
}
```

> Bước 3 không đổi trạng thái đợt khám. Ca khám `COMPLETED` khi thu đủ hóa đơn dịch vụ (8.3); khách mua ngoài thì `POST …/cancel` → `CANCELLED`.

### 8.3. Mẫu chuẩn: Thu tiền hóa đơn dịch vụ & Hoàn tất ca khám (`clinical-service`)
v4.0 **không phát phiếu trong giao dịch thu tiền**: giao dịch chỉ chuyển hóa đơn sang `PAID` và ghi outbox `ServiceInvoicePaidEvent`; listener `QueueIssuerListener` của chính `clinical-service` nhận sự kiện và phát phiếu trên Redis (mục 9.3). Nhờ outbox, đã thu tiền thì chắc chắn có phiếu, kể cả khi Redis hoặc service sập ngay sau commit.

```java
@Override
@Transactional(rollbackFor = Exception.class)
public void confirmServicePayment(UUID visitId, List<UUID> invoiceIds, UUID cashierId) {
    PetVisit visit = petVisitRepository.findById(visitId)
            .orElseThrow(() -> new AppException(ErrorCode.VISIT_NOT_FOUND));
    List<ServiceInvoice> invoices = serviceInvoiceRepository.findByIdsAndVisitId(invoiceIds, visitId);
    if (invoiceIds.isEmpty() || invoices.size() != new HashSet<>(invoiceIds).size()) {
        throw new AppException(ErrorCode.INVOICE_NOT_FOUND);
    }
    Instant paidAt = Instant.now();
    boolean closed = visit.getStatus() == VisitStatus.WAITING_PAYMENT || visit.getStatus() == VisitStatus.COMPLETED;
    for (ServiceInvoice inv : invoices) {
        switch (inv.getPaymentStatus()) {
            case PAID, REFUNDED -> throw new AppException(ErrorCode.INVOICE_ALREADY_PAID);
            case CANCELLED -> throw new AppException(ErrorCode.INVOICE_ALREADY_CANCELLED);
            default -> { }
        }
        ServiceCategory cat = inv.getVisitServiceDetail().getService().getCategory();   // bảng danh mục
        if (!cat.isRequiresPrepayment() && !closed) {
            throw new AppException(ErrorCode.VISIT_NOT_READY_FOR_PAYMENT);              // làm tại phòng: thu khi chốt ca
        }
        inv.markPaid(cashierId, paidAt);                                                // @Version chống thu trùng
    }

    // Một sự kiện cho cả lần thu: reporting ghi doanh thu, queue-issuer phát phiếu cho dòng có queueType
    outbox.write("VISIT", visitId, "invoice.service_paid",
            ServiceInvoicePaidEvent.of(visit, invoices, cashierId, paidAt));

    // T10: mọi hóa đơn dịch vụ đã PAID / CANCELLED / REFUNDED -> COMPLETED
    if (visit.getStatus() == VisitStatus.WAITING_PAYMENT
            && !serviceInvoiceRepository.existsByVisitIdAndStatus(visitId, PaymentStatus.PENDING)) {
        visit.changeStatus(VisitStatus.COMPLETED, cashierId, "Thu đủ hóa đơn dịch vụ", statusHistoryRepository);
        outbox.write("VISIT", visitId, "visit.completed", VisitCompletedEvent.of(visit));
    }
}
```

**Lập hóa đơn lúc chỉ định / tiếp đón** luôn lấy giá từ `ServicePriceBook.current(serviceId)` và chụp sang `service_invoices.unit_price`, `vat_rate`. Hủy dịch vụ đã thu do phòng khám không làm được → `REFUNDED` + outbox `ServiceInvoiceRefundedEvent`; khách tự hủy → giữ `PAID`; phí khám không bao giờ `REFUNDED` (`CLIN_1310`).

---

## CHƯƠNG 9: QUY CHUẨN GIAO TIẾP LIÊN DỊCH VỤ (OPENFEIGN, RABBITMQ, OUTBOX, REDIS)

### 9.1. Giao tiếp Đồng bộ (OpenFeign)
0. **Chỉ dùng để ĐỌC**, gọi `/internal/**`, đặt ngoài `@Transactional`. Danh mục lời gọi: `THIET_KE_KIEN_TRUC_MICROSERVICES.md` mục 5.1 (v4.0 thêm `clinical → billing-pharmacy` tra thuốc; bỏ `billing → clinical`).
1. **Timeout + Circuit Breaker:**
   ```yaml
   spring:
     cloud:
       openfeign:
         circuitbreaker:
           enabled: true
         client:
           config:
             default:
               connectTimeout: 2000
               readTimeout: 2000
   resilience4j:
     circuitbreaker:
       configs:
         default:
           slidingWindowSize: 20
           failureRateThreshold: 50
           waitDurationInOpenState: 10s
   ```
   Lời gọi chỉ để **hiển thị** (làm giàu tên) dùng fallback trả snapshot; lời gọi để **kiểm tra điều kiện ghi** (Bác sĩ còn `ACTIVE`, thuốc tồn tại) không có fallback: lỗi thì trả `SYS_1004`, không ghi dữ liệu.
2. **`CustomFeignErrorDecoder`** khôi phục `ErrorCode` từ phản hồi của service con (giữ như v3.0):
   ```java
   @RequiredArgsConstructor
   public class CustomFeignErrorDecoder implements ErrorDecoder {
       private final ObjectMapper objectMapper;
       @Override
       public Exception decode(String methodKey, Response response) {
           try {
               if (response.body() != null) {
                   ApiResponse<?> err = objectMapper.readValue(response.body().asInputStream(), ApiResponse.class);
                   for (ErrorCode ec : ErrorCode.values()) {
                       if (ec.getCode().equals(err.getErrorCode())) return new AppException(ec, err.getMessage());
                   }
                   return new AppException(ErrorCode.UNCATEGORIZED_EXCEPTION, err.getMessage());
               }
           } catch (IOException e) {
               return new AppException(ErrorCode.SERVICE_UNAVAILABLE);
           }
           return new AppException(ErrorCode.SERVICE_UNAVAILABLE);
       }
   }
   ```

### 9.2. Giao tiếp Bất đồng bộ: Transactional Outbox & Consumer Idempotent

> [!IMPORTANT]
> **Quy tắc v4.0:** mọi sự kiện làm thay đổi dữ liệu ở service khác được ghi vào bảng `outbox_events` **trong cùng giao dịch** với thay đổi nghiệp vụ, rồi `OutboxRelay` mới gửi ra RabbitMQ. Không gửi trực tiếp trong `@Transactional`, không dùng `AFTER_COMMIT` (sập ngay sau commit là mất sự kiện). Ngoại lệ duy nhất: `QueueTicketIssuedEvent`, `PatientCalledEvent` (chỉ làm mới màn hình, sinh từ thao tác Redis) được gửi trực tiếp.

**1. Ghi sự kiện (`OutboxWriter`, dùng chung trong `common-library`, phần JPA):**
```java
@Component
@RequiredArgsConstructor
public class OutboxWriter {
    private final OutboxEventRepository repository;
    private final ObjectMapper objectMapper;

    /** Phải được gọi BÊN TRONG một @Transactional đang mở. */
    @Transactional(propagation = Propagation.MANDATORY)
    public void write(String aggregateType, UUID aggregateId, String routingKey, BaseEvent event) {
        repository.save(OutboxEvent.builder()
                .eventId(event.eventId())                       // UUIDv7 sinh khi tạo event
                .aggregateType(aggregateType).aggregateId(aggregateId)
                .eventType(event.getClass().getSimpleName()).routingKey(routingKey)
                .payload(objectMapper.writeValueAsString(event))
                .status(OutboxStatus.PENDING).build());
    }
}

/** Mọi sự kiện kế thừa: có eventId, occurredAt. */
public interface BaseEvent { UUID eventId(); Instant occurredAt(); }
```

**2. Gửi sự kiện (`OutboxRelay`, mỗi service một tiến trình):**
```java
@Slf4j
@Component
@RequiredArgsConstructor
public class OutboxRelay {
    private final OutboxEventRepository repository;
    private final RabbitTemplate rabbitTemplate;          // bật publisher confirms (spring.rabbitmq.publisher-confirm-type: correlated)

    @Scheduled(fixedDelay = 500)
    @Transactional
    public void publishBatch() {
        // SELECT ... WHERE status='PENDING' AND next_attempt_at <= NOW() ORDER BY id LIMIT 100 FOR UPDATE SKIP LOCKED
        for (OutboxEvent e : repository.lockNextBatch(100)) {
            try {
                CorrelationData cd = new CorrelationData(e.getEventId().toString());
                rabbitTemplate.convertAndSend("clinic.events", e.getRoutingKey(), toMessage(e), cd);
                if (!cd.getFuture().get(5, TimeUnit.SECONDS).isAck()) throw new AmqpException("nack");
                e.markPublished(Instant.now());
            } catch (Exception ex) {
                e.markFailedAttempt(ex.getMessage());     // attempt_count++, next_attempt_at lùi dần; >10 lần -> FAILED
                log.warn("Gửi outbox {} lỗi lần {}: {}", e.getEventId(), e.getAttemptCount(), ex.getMessage());
                break;                                    // giữ thứ tự: dừng lô, lần sau gửi tiếp từ dòng này
            }
        }
    }

    @Scheduled(cron = "0 0 3 * * *", zone = "Asia/Ho_Chi_Minh")
    @Transactional
    public void cleanup() { repository.deletePublishedBefore(Instant.now().minus(7, ChronoUnit.DAYS)); }
}
```

**3. Nhận sự kiện idempotent (`IdempotentConsumer`):**
```java
@Component
@RequiredArgsConstructor
public class IdempotentConsumer {
    private final ProcessedEventRepository repository;

    /** Chạy action trong MỘT giao dịch cùng với việc ghi processed_events; nhận trùng thì bỏ qua. */
    @Transactional(rollbackFor = Exception.class)
    public void run(UUID eventId, String consumer, Runnable action) {
        if (repository.existsById(new ProcessedEventId(eventId, consumer))) return;
        action.run();
        repository.save(new ProcessedEvent(eventId, consumer));     // trùng khóa do chạy song song -> rollback, an toàn
    }
}
```

**Cấu hình:** `Jackson2JsonMessageConverter`; mỗi listener một queue `<service>.<listener>` bind vào `clinic.events` theo routing key, kèm DLQ `<queue>.dlq`; retry 3 lần (1s, 2s, 4s) rồi vào DLQ.

**Danh mục 17 sự kiện v4.0** (khớp `THIET_KE_KIEN_TRUC_MICROSERVICES.md` mục 5.2):

| Event class | Routing key | Producer | Consumer (queue) |
| :--- | :--- | :--- | :--- |
| `UserProfileUpdatedEvent` | `user.profile_updated` | auth | clinical (`clinical.snapshot-updater`), appointment (`appointment.snapshot-updater`), reporting |
| `UserStatusChangedEvent` | `user.status_changed` | auth | clinical (`clinical.doctor-status`), notification |
| `AppointmentBookedEvent` | `appointment.booked` | appointment | notification |
| `AppointmentStatusChangedEvent` | `appointment.status_changed` | appointment | notification |
| `AppointmentNoShowEvent` | `appointment.no_show` | appointment | notification |
| `PetUpdatedEvent` | `pet.updated` | clinical | appointment, reporting |
| `VisitCheckedInEvent` | `visit.checked_in` | clinical | appointment, clinical (`clinical.queue-issuer`, ca cấp cứu), reporting, notification |
| `ServiceInvoicePaidEvent` | `invoice.service_paid` | clinical | clinical (`clinical.queue-issuer`), reporting, notification |
| `ServiceInvoiceRefundedEvent` | `invoice.service_refunded` | clinical | reporting, notification |
| `QueueTicketIssuedEvent` | `queue.ticket_issued` | clinical (trực tiếp) | notification |
| `PatientCalledEvent` | `visit.patient_called` | clinical (trực tiếp) | notification |
| `ParaclinicalResultsReadyEvent` | `visit.results_ready` | clinical | clinical (`clinical.queue-issuer`), notification |
| `PrescriptionCreatedEvent` | `prescription.created` | clinical | billing-pharmacy (`billing.prescription-created`) |
| `VisitCompletedEvent` | `visit.completed` | clinical | reporting, notification |
| `VisitCancelledEvent` | `visit.cancelled` | clinical | reporting, notification |
| `MedicineInvoicePaidEvent` | `pharmacy.medicine_invoice_paid` | billing-pharmacy | reporting, notification |
| `MedicineLowStockEvent` | `pharmacy.low_stock` | billing-pharmacy | notification |

**Cập nhật snapshot (ví dụ `clinical.snapshot-updater`):**
```java
@RabbitListener(queues = "clinical.snapshot-updater")
public void on(UserProfileUpdatedEvent e) {
    idempotent.run(e.eventId(), "clinical.snapshot-updater", () -> {
        petRepository.updateOwnerSnapshot(e.userId(), e.fullName(), e.phoneNumber());     // UPDATE ... WHERE owner_id = ?
        petVisitRepository.updateDoctorNameSnapshot(e.userId(), e.fullName());            // UPDATE ... WHERE doctor_id = ?
    });
}
```

### 9.3. Hàng đợi trên Redis (`clinical-service`)

**Khóa:** xem `THIET_KE_CO_SO_DU_LIEU_ERD.md` Mục 3. `score = (2 − priority) × 10^13 + paidAtEpochMillis` (ca cấp cứu / ca có kết quả: thời điểm tiếp đón / có kết quả). Giờ ngày dùng múi `Asia/Ho_Chi_Minh`.

**1. Phát phiếu nguyên tử (`issue_ticket.lua`):**
```lua
-- KEYS[1]=queue:{date}:{type}:{owner}  KEYS[2]=queue:seq:{date}:{type}  KEYS[3]=queue:dedupe:{eventId}  KEYS[4]=queue:visit:{visitId}
-- ARGV[1]=ticketId ARGV[2]=score ARGV[3]=ttlSeconds ARGV[4..]=cặp field/value của Hash phiếu
local existed = redis.call('GET', KEYS[3])
if existed then return {existed, redis.call('HGET', 'ticket:' .. existed, 'ticketNo')} end   -- nhận trùng sự kiện
local no = redis.call('INCR', KEYS[2])
redis.call('EXPIRE', KEYS[2], 172800)
local tkey = 'ticket:' .. ARGV[1]
redis.call('HSET', tkey, 'ticketNo', no, 'status', 'WAITING', 'calledCount', 0, unpack(ARGV, 4))
redis.call('EXPIRE', tkey, tonumber(ARGV[3]))
redis.call('ZADD', KEYS[1], ARGV[2], ARGV[1])
redis.call('SADD', KEYS[4], ARGV[1])
redis.call('SET', KEYS[3], ARGV[1], 'EX', 172800)
return {ARGV[1], no}
```

**2. Bắt đầu phục vụ (`start_ticket.lua`):** kiểm tra `status == WAITING` (nếu không: trả mã `NOT_WAITING` → `CLIN_1313`), với hàng đợi Bác sĩ kiểm tra khóa `queue:busy:{doctorId}` chưa tồn tại (nếu có: `DOCTOR_BUSY` → `CLIN_1302`); rồi `HSET status IN_SERVICE startedAt …`, `SET queue:busy:{doctorId} ticketId`, `ZREM` khỏi Sorted Set (phiếu đang phục vụ không còn trong danh sách chờ).

**3. Kết thúc / hủy (`finish_ticket.lua`):** `ZREM`, `SREM queue:visit:{visitId}`, `DEL queue:busy:{doctorId}` nếu đúng phiếu, `DEL ticket:{id}`.

**4. Listener phát phiếu:**
```java
@Component
@RequiredArgsConstructor
public class QueueIssuerListener {
    private final QueueRedisRepository queue;
    private final RabbitTemplate rabbitTemplate;

    @RabbitListener(queues = "clinical.queue-issuer.invoice-paid")
    public void onPaid(ServiceInvoicePaidEvent e) {
        // gom các dòng theo queueType: DOCTOR (phí khám), LABORATORY, IMAGING; dòng không có queueType bỏ qua
        e.lines().stream().filter(l -> l.queueType() != null)
                .collect(Collectors.groupingBy(ServiceInvoicePaidEvent.Line::queueType))
                .forEach((type, lines) -> {
                    UUID owner = type == QueueType.DOCTOR ? e.doctorId() : null;   // null -> UNASSIGNED / ALL
                    IssuedTicket t = queue.issue(e.eventId() + ":" + type, type, owner, e.visitId(),
                            e.emergency() ? 2 : 0, e.paidAt(), lines, e.cashierId(), e.petName(), e.ownerName());
                    rabbitTemplate.convertAndSend("clinic.events", "queue.ticket_issued", QueueTicketIssuedEvent.of(t));
                });
        // Lỗi Redis -> ném ngoại lệ -> RabbitMQ retry -> DLQ; khóa dedupe bảo đảm không phát 2 phiếu
    }
}
```

**5. Bắt đầu khám và ghi lịch sử phiếu:** xem `PetVisitServiceImpl.startExamination` (11.2 mục 6) – giao dịch MySQL đổi trạng thái đợt khám; `afterCommit` chạy `start_ticket.lua`. Khi phiếu kết thúc (Bác sĩ chỉ định CLS / chốt ca; dịch vụ cuối của phiếu phòng xong / hủy), service đọc Hash phiếu từ Redis, rồi trong giao dịch MySQL ghi `queue_ticket_histories` (+ `queue_ticket_history_items`) cùng thay đổi nghiệp vụ, `afterCommit` chạy `finish_ticket.lua`. `ticket_id UNIQUE` chặn ghi trùng khi thử lại.

**6. Dựng lại hàng đợi (`QueueRebuildJob`):** chạy khi khởi động nếu không có khóa `queue:meta:{date}` và có thể gọi tay từ trang quản trị. Dựng phiếu `DOCTOR` cho đợt khám `WAITING` đã thu phí khám hoặc cấp cứu, và `RESULTS_READY` (`priority 1`); phiếu `LABORATORY` / `IMAGING` cho dịch vụ `PENDING` có hóa đơn `PAID` chưa có lịch sử phiếu `DONE`; thứ tự theo `paid_at` / `checked_in_at`; số phiếu cấp lại từ 1.

**7. Cấu hình Redis:** `spring.data.redis.host/port`, `timeout: 1s`; lỗi kết nối khi đọc hàng đợi → `CLIN_1318`. Docker: `redis:7-alpine --appendonly yes --appendfsync everysec`.

---

## CHƯƠNG 10: QUY CHUẨN BẢO MẬT & PHÂN QUYỀN TRUY CẬP (SECURITY & RBAC)

### 10.1. Bảo vệ Toàn vẹn tại Spring Cloud Gateway
> [!CAUTION]
> **Quy tắc Phòng chống Giả mạo Quyền & Trả đúng mã lỗi:**
> 1. Kẻ xấu có thể tự thêm Header `X-User-Roles: ADMIN` từ bên ngoài. Gateway **xóa toàn bộ** các Headers này trước khi giải mã JWT và gán Headers nội bộ mới.
> 2. Với route **không công khai**, nếu thiếu / sai / hết hạn token, Gateway **trả ngay `401` (SYS_1002)**, không chuyển tiếp request. Nhờ đó Axios Interceptor nhận `401` và tự gọi `/api/v1/auth/refresh`. (Nếu Gateway chuyển tiếp request không có header, service bên dưới sẽ trả `403`, Frontend không biết cần làm mới token.)
> 3. Gateway chặn mọi request tới `/internal/**` từ bên ngoài.
> 4. Claim `roles` là **danh sách** mã vai trò **không có tiền tố** (`["VETERINARIAN", "ADMIN"]`, v4.0: một tài khoản có thể nhiều vai trò qua `user_roles`); header `X-User-Roles` nối các mã bằng dấu phẩy. Claim `sub` / header `X-User-Id` là UUID dạng chuỗi.

```java
@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter implements GlobalFilter, Ordered {

    private static final List<String> PUBLIC_PATHS = List.of(
            "/api/v1/auth/login", "/api/v1/auth/refresh", "/api/v1/auth/register",
            "/api/v1/appointments/slots");                       // tra cứu khung giờ công khai

    private final JwtValidator jwtValidator;
    private final AntPathMatcher matcher = new AntPathMatcher();

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        ServerHttpRequest request = exchange.getRequest();
        String path = request.getPath().value();

        // 0. Không cho bên ngoài gọi endpoint nội bộ
        if (matcher.match("/internal/**", path)) {
            return writeError(exchange, HttpStatus.FORBIDDEN, "SYS_1003", "Không được phép truy cập");
        }

        // 1. XÓA HEADER NỘI BỘ NẾU CLIENT CỐ TÌNH TRUYỀN VÀO ĐỂ GIẢ MẠO
        ServerHttpRequest.Builder builder = request.mutate()
                .headers(h -> { h.remove("X-User-Id"); h.remove("X-User-Roles"); });

        boolean isPublic = PUBLIC_PATHS.stream().anyMatch(p -> matcher.match(p, path));
        String token = extractBearerToken(request);

        if (token == null || !jwtValidator.validate(token)) {
            if (isPublic) {
                return chain.filter(exchange.mutate().request(builder.build()).build());
            }
            // 2. Route cần đăng nhập mà thiếu/sai/hết hạn token -> 401 để Frontend gọi /refresh
            return writeError(exchange, HttpStatus.UNAUTHORIZED, "SYS_1002", "Chưa đăng nhập hoặc token đã hết hạn");
        }

        // 3. Gán Header chính thống từ Claims (role KHÔNG có tiền tố ROLE_)
        Claims claims = jwtValidator.getClaims(token);
        builder.header("X-User-Id", claims.getSubject());                                   // UUID chuỗi
        builder.header("X-User-Roles", String.join(",", claims.get("roles", List.class)));
        return chain.filter(exchange.mutate().request(builder.build()).build());
    }

    private Mono<Void> writeError(ServerWebExchange exchange, HttpStatus status, String code, String message) {
        ServerHttpResponse response = exchange.getResponse();
        response.setStatusCode(status);
        response.getHeaders().setContentType(MediaType.APPLICATION_JSON);
        String body = "{\"status\":%d,\"errorCode\":\"%s\",\"message\":\"%s\"}".formatted(status.value(), code, message);
        return response.writeWith(Mono.just(response.bufferFactory().wrap(body.getBytes(StandardCharsets.UTF_8))));
    }

    @Override
    public int getOrder() {
        return -100; // Chạy sớm nhất trước tất cả các filter khác
    }
}
```

### 10.2. Phân quyền Phương thức tại Microservices Con & HeaderAuthenticationFilter

Mỗi Microservice servlet không giải mã lại JWT, mà dùng một Filter không trạng thái đọc `X-User-Id` và `X-User-Roles` do Gateway chuyển tiếp, rồi nạp vào `SecurityContextHolder`. Các lớp dưới đây nằm trong `com.vetclinic.common.web` và được nạp bằng `CommonWebAutoConfiguration` (mục 2.2), **không gắn `@Component`** (nếu gắn, Spring Boot sẽ tự đăng ký filter vào servlet container một lần nữa, khiến filter chạy hai lần).

#### 1. Lớp `HeaderAuthenticationFilter`
```java
package com.vetclinic.common.web;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Arrays;
import java.util.List;

public class HeaderAuthenticationFilter extends OncePerRequestFilter {

    private static final String ROLE_PREFIX = "ROLE_";

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String userId = request.getHeader("X-User-Id");
        String roles = request.getHeader("X-User-Roles");          // "VETERINARIAN,ADMIN"

        if (userId != null && roles != null) {
            // Thêm tiền tố ROLE_ đúng MỘT lần cho từng vai trò (tránh ROLE_ROLE_)
            List<SimpleGrantedAuthority> authorities = Arrays.stream(roles.split(","))
                    .map(String::trim).filter(r -> !r.isEmpty())
                    .map(r -> new SimpleGrantedAuthority(r.startsWith(ROLE_PREFIX) ? r : ROLE_PREFIX + r))
                    .toList();
            var authentication = new UsernamePasswordAuthenticationToken(userId, null, authorities);
            SecurityContextHolder.getContext().setAuthentication(authentication);
        }
        filterChain.doFilter(request, response);
    }
}
```

#### 2. Lớp Tiện ích `SecurityUtils` (Lấy User ID hiện tại)
```java
package com.vetclinic.common.util;

import com.vetclinic.common.exception.AppException;
import com.vetclinic.common.exception.ErrorCode;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

public final class SecurityUtils {

    private SecurityUtils() {}

    public static UUID getCurrentUserId() {                       // v4.0: khóa người dùng là UUID
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || authentication.getPrincipal() == null) {
            throw new AppException(ErrorCode.UNAUTHORIZED);
        }
        try {
            return UUID.fromString(authentication.getPrincipal().toString());
        } catch (IllegalArgumentException e) {
            throw new AppException(ErrorCode.UNAUTHORIZED);
        }
    }
}
```

#### 3. Cấu hình Spring Security `CommonSecurityConfig` (trả 401 / 403 đúng chuẩn)
```java
package com.vetclinic.common.web;

import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration(proxyBeanMethods = false)
@EnableWebSecurity
@EnableMethodSecurity
public class CommonSecurityConfig {

    @Bean
    @ConditionalOnMissingBean(SecurityFilterChain.class)   // auth-service có thể tự khai báo chain riêng cho /login
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        return http
                .csrf(csrf -> csrf.disable())
                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/actuator/health", "/v3/api-docs/**", "/swagger-ui/**").permitAll()
                        .requestMatchers("/internal/**").permitAll()   // chỉ gọi được trong mạng nội bộ (Gateway chặn từ ngoài)
                        .anyRequest().authenticated())
                .exceptionHandling(ex -> ex
                        // Chưa xác thực -> 401 (mặc định của chain STATELESS là 403, sai với quy ước Frontend)
                        .authenticationEntryPoint((req, res, e) -> writeJson(res, HttpStatus.UNAUTHORIZED,
                                "SYS_1002", "Chưa đăng nhập hoặc token đã hết hạn"))
                        // Đã xác thực nhưng sai vai trò -> 403
                        .accessDeniedHandler((req, res, e) -> writeJson(res, HttpStatus.FORBIDDEN,
                                "SYS_1003", "Bạn không có quyền thực hiện thao tác này")))
                .addFilterBefore(new HeaderAuthenticationFilter(), UsernamePasswordAuthenticationFilter.class)
                .build();
    }

    private static void writeJson(jakarta.servlet.http.HttpServletResponse res, HttpStatus status,
                                  String code, String message) throws java.io.IOException {
        res.setStatus(status.value());
        res.setContentType(MediaType.APPLICATION_JSON_VALUE);
        res.setCharacterEncoding("UTF-8");
        res.getWriter().write("{\"status\":%d,\"errorCode\":\"%s\",\"message\":\"%s\"}"
                .formatted(status.value(), code, message));
    }
}
```

> **Bảng quy ước mã lỗi bảo mật:** thiếu / sai / hết hạn token → `401` (Gateway trả trực tiếp; service trả bằng `authenticationEntryPoint` nếu request lọt vào không có header) → Frontend tự gọi `/refresh`. Đã đăng nhập nhưng sai vai trò → `403` (`accessDeniedHandler` hoặc `GlobalExceptionHandler` bắt `AccessDeniedException` từ `@PreAuthorize`).

---

### 10.3. Quy Chuẩn Quản Lý Phiên Đăng Nhập & Xoay Vòng Refresh Token (Token Rotation)

Nhằm đảm bảo an toàn cao nhất trước nguy cơ lộ lọt JWT nhưng vẫn mang lại trải nghiệm mượt mà không bắt người dùng đăng nhập lại liên tục, hệ thống áp dụng cơ chế **Stateful Refresh Token kết hợp Token Rotation**:

```text
[ React Client (Axios) ]                   [ API Gateway ]                [ auth-service ]
           │                                      │                               │
           │── 1. POST /api/v1/auth/login ───────▶│──────────────────────────────▶│
           │◀─ 2. AuthResponse (Access + Refresh)─│◀──────────────────────────────│
           │   (Access TTL: 30m, Refresh TTL: 7d) │                               │
           │                                      │                               │
           │── 3. Gọi API với Access Token ──────▶│ (Giải mã JWT & Gắn Header)    │
           │                                      │────── Forward Header ────────▶│ [Other Services]
           │                                      │                               │
           │   [Sau 30 phút - Access Token hết hạn]                               │
           │◀─ 4. Nhận mã lỗi 401 (UNAUTHORIZED)──│◀──────────────────────────────│
           │                                      │                               │
           │── 5. Axios Interceptor tự động gọi: ─│                               │
           │      POST /api/v1/auth/refresh ─────▶│──────────────────────────────▶│ (Kiểm tra DB)
           │      { refreshToken: "uuid-v4" }     │                               │ 1. revoked == false?
           │                                      │                               │ 2. expiry_date > now?
           │                                      │                               │ 3. Đánh dấu token cũ revoked!
           │                                      │                               │ 4. Lưu Refresh Token mới
           │◀─ 6. TokenRefreshResponse ───────────│◀──────────────────────────────│ 5. Cấp cặp Token mới
           │      (Cặp Access + Refresh Token mới)│                               │
           │                                      │                               │
           │── 7. Retry request ban đầu (Thành công)                              │
```

#### 1. Bảng Thông số Thời hạn & Chiến lược Token
| Loại Token | Thời hạn sống (TTL) | Nơi lưu trữ / Quản lý | Nội dung / Payload |
| :--- | :---: | :--- | :--- |
| **Access Token** | **30 phút** (1,800 giây) | Ký số JWT (HMAC-SHA256), Stateless | `sub` (userId UUID), `username`, `fullName`, `roles` (danh sách mã vai trò **không có tiền tố**; tiền tố `ROLE_` chỉ thêm tại `HeaderAuthenticationFilter`), `exp`, `iat` |
| **Refresh Token** | **7 ngày** (604,800 giây) | Chuỗi ngẫu nhiên 256 bit (`SecureRandom`, Base64URL) trả cho client; CSDL chỉ lưu **SHA-256** của chuỗi (`refresh_tokens.token_hash`) | Ánh xạ tới `user_id`, có cờ `revoked` và `expiry_date`. Lộ CSDL không dùng lại được token |

#### 2. Nguyên tắc An ninh Xoay Vòng Token (Refresh Token Rotation)
1. **Một lần dùng duy nhất (Single-Use):** Mỗi khi một Refresh Token được sử dụng để lấy Access Token mới thành công, nó **ngay lập tức bị đánh dấu là `revoked = TRUE`**. Một Refresh Token mới tinh sẽ được tạo ra thay thế.
2. **Cơ chế Phát hiện Đánh cắp Token (Theft Detection):** Nếu hệ thống nhận được yêu cầu `/refresh` với một token **đã từng bị `revoked = TRUE`**, hệ thống nhận diện khả năng cao token đã bị rò rỉ và kẻ gian đang cố tái sử dụng (Replay Attack). Ngay lập tức:
   - Thu hồi toàn bộ các Refresh Token còn lại của người dùng đó (Force Logout trên tất cả thiết bị).
   - Ném ngoại lệ `REFRESH_TOKEN_REVOKED` (HTTP 401).
3. **Thu hồi khi Đăng xuất (Logout):** Khi người dùng bấm Đăng xuất (`POST /api/v1/auth/logout`), Refresh Token gửi kèm sẽ bị đánh dấu `revoked = TRUE`.

#### 3. Danh mục Endpoints & DTOs Chuẩn
- **`POST /api/v1/auth/refresh`**:
  ```java
  public record RefreshTokenRequest(
      @NotBlank(message = "Refresh token không được để trống")
      String refreshToken
  ) {}

  public record TokenRefreshResponse(
      String accessToken,
      String refreshToken,
      String tokenType,
      long expiresIn // 1800 giây
  ) {}
  ```
- **`POST /api/v1/auth/logout`**:
  ```java
  public record LogoutRequest(
      @NotBlank(message = "Refresh token không được để trống")
      String refreshToken
  ) {}
  ```

#### 4. Mã Nguồn Tham Chiếu Xử Lý Nghiệp Vụ (`RefreshTokenServiceImpl.java`)
```java
package com.vetclinic.auth.service.impl;

import com.vetclinic.auth.entity.RefreshToken;
import com.vetclinic.auth.entity.User;
import com.vetclinic.auth.repository.RefreshTokenRepository;
import com.vetclinic.auth.repository.UserRepository;
import com.vetclinic.auth.dto.response.TokenRefreshResponse;
import com.vetclinic.common.exception.AppException;
import com.vetclinic.common.exception.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class RefreshTokenServiceImpl {

    private final RefreshTokenRepository refreshTokenRepository;
    private final UserRepository userRepository;
    private final JwtTokenProvider jwtTokenProvider;

    @Transactional
    public TokenRefreshResponse refresh(String tokenStr) {
        RefreshToken token = refreshTokenRepository.findByTokenHash(TokenHasher.sha256(tokenStr))   // v4.0: tra theo giá trị băm
                .orElseThrow(() -> new AppException(ErrorCode.REFRESH_TOKEN_NOT_FOUND));

        // 1. Phát hiện xâm nhập: Token đã bị thu hồi mà vẫn cố sử dụng
        if (token.isRevoked()) {
            log.warn("CẢNH BÁO AN NINH: Phát hiện tái sử dụng Refresh Token đã thu hồi của User ID: {}. Thu hồi toàn bộ phiên!", token.getUser().getId());
            refreshTokenRepository.revokeAllUserTokens(token.getUser().getId());
            throw new AppException(ErrorCode.REFRESH_TOKEN_REVOKED);
        }

        // 2. Kiểm tra hết hạn
        if (token.getExpiryDate().isBefore(Instant.now())) {
            token.setRevoked(true);
            refreshTokenRepository.save(token);
            throw new AppException(ErrorCode.REFRESH_TOKEN_EXPIRED);
        }

        // 3. Xoay vòng Token (Rotation): Thu hồi token cũ, cấp token mới
        token.setRevoked(true);
        refreshTokenRepository.save(token);

        User user = token.getUser();
        if (user.getStatus() != UserStatus.ACTIVE) {                       // tài khoản bị khóa / ngừng: không làm mới
            refreshTokenRepository.revokeAllUserTokens(user.getId());
            throw new AppException(ErrorCode.ACCOUNT_DISABLED);           // AUTH_1107
        }
        String newAccessToken = jwtTokenProvider.generateAccessToken(user);   // roles lấy từ user_roles
        String rawToken = TokenHasher.randomToken();                          // 256 bit, chỉ trả cho client
        refreshTokenRepository.save(RefreshToken.builder()
                .user(user)
                .tokenHash(TokenHasher.sha256(rawToken))
                .expiryDate(Instant.now().plus(7, ChronoUnit.DAYS))
                .revoked(false)
                .build());

        return new TokenRefreshResponse(newAccessToken, rawToken, "Bearer", 1800);
    }

    @Transactional
    public void logout(String tokenStr) {
        refreshTokenRepository.findByTokenHash(TokenHasher.sha256(tokenStr)).ifPresent(token -> {
            token.setRevoked(true);
            refreshTokenRepository.save(token);
        });
    }
}
```

---

## CHƯƠNG 11: MẪU CẤU HÌNH MAVEN (POM.XML) & MÃ NGUỒN THAM CHIẾU CHUẨN

### 11.1. File `pom.xml` Chuẩn mực cho Java 21 & Spring Boot 4.1.1
Cấu hình tích hợp chuẩn giữa **Java 21**, **Spring Boot 4.1.1**, **Spring Cloud 2025.1.2**, **Lombok** và **MapStruct**:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.vetclinic</groupId>
    <artifactId>vetclinic-parent</artifactId>
    <version>1.0.0-SNAPSHOT</version>
    <packaging>pom</packaging>

    <name>VetClinic Parent POM</name>
    <description>Parent POM for Veterinary Clinic Management Microservices</description>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>4.1.1</version>
        <relativePath/>
    </parent>

    <modules>
        <module>common-library</module>
        <module>service-registry</module>
        <module>api-gateway</module>
        <module>auth-service</module>
        <module>appointment-service</module>
        <module>clinical-service</module>
        <module>billing-pharmacy-service</module>
        <module>notification-service</module>
        <module>reporting-service</module>
    </modules>

    <properties>
        <java.version>21</java.version>
        <spring-cloud.version>2025.1.2</spring-cloud.version>
        <org.mapstruct.version>1.5.5.Final</org.mapstruct.version>
        <lombok-mapstruct-binding.version>0.2.0</lombok-mapstruct-binding.version>
    </properties>

    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>org.springframework.cloud</groupId>
                <artifactId>spring-cloud-dependencies</artifactId>
                <version>${spring-cloud.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
            <dependency>
                <groupId>com.vetclinic</groupId>
                <artifactId>common-library</artifactId>
                <version>${project.version}</version>
            </dependency>
        </dependencies>
    </dependencyManagement>

    <dependencies>
        <!-- Lombok & MapStruct dùng chung cho toàn bộ dự án -->
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>org.mapstruct</groupId>
            <artifactId>mapstruct</artifactId>
            <version>${org.mapstruct.version}</version>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <!-- Maven Compiler Plugin hỗ trợ kết hợp Lombok và MapStruct trên Java 21 -->
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <configuration>
                    <annotationProcessorPaths>
                        <path>
                            <groupId>org.projectlombok</groupId>
                            <artifactId>lombok</artifactId>
                        </path>
                        <path>
                            <groupId>org.projectlombok</groupId>
                            <artifactId>lombok-mapstruct-binding</artifactId>
                            <version>${lombok-mapstruct-binding.version}</version>
                        </path>
                        <path>
                            <groupId>org.mapstruct</groupId>
                            <artifactId>mapstruct-processor</artifactId>
                            <version>${org.mapstruct.version}</version>
                        </path>
                    </annotationProcessorPaths>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
```


#### `common-library/pom.xml` – các phụ thuộc servlet khai báo `optional`
```xml
<artifactId>common-library</artifactId>
<dependencies>
    <!-- Dùng ở mọi module (DTO, ErrorCode, BaseEvent) -->
    <dependency>
        <groupId>com.fasterxml.jackson.core</groupId>
        <artifactId>jackson-annotations</artifactId>
    </dependency>
    <!-- Chỉ phục vụ phần com.vetclinic.common.web: optional để KHÔNG kéo Servlet MVC sang api-gateway -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
        <optional>true</optional>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-security</artifactId>
        <optional>true</optional>
    </dependency>
    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-openfeign</artifactId>
        <optional>true</optional>
    </dependency>
</dependencies>
```
Kèm file `src/main/resources/META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports` chứa một dòng `com.vetclinic.common.web.CommonWebAutoConfiguration` (mục 2.2).

---

### 11.2. Mẫu Mã Nguồn Tham Chiếu Chuẩn (Gold Standard Vertical Slice)

Lát cắt hoàn chỉnh cho nghiệp vụ **Bác sĩ bắt đầu khám lâm sàng Giai đoạn 1 (UC-22, T02)** trong `clinical-service` theo lược đồ v4.0: đợt khám (`pet_visits`) chỉ giữ thông tin hành chính; sinh hiệu ghi ở `vital_signs`; nội dung chuyên môn ở `medical_records` (tạo khi bắt đầu khám); phiếu xếp hàng nằm trên Redis.

#### 1. Request DTO (`StartExaminationRequest.java`, `VitalSignsRequest.java`)
Sinh hiệu **không bắt buộc** khi bấm "Bắt đầu khám" (Bác sĩ có thể nhập ngay hoặc thêm sau bằng `POST …/vital-signs`). Trước khi gửi chỉ định cận lâm sàng / chốt ca phải có ít nhất một lần đo có cân nặng và thân nhiệt (`CLIN_1308`).

```java
package com.vetclinic.clinical.dto.request;

public record VitalSignsRequest(
        @DecimalMin("0.1") @DecimalMax("150.0") BigDecimal weightKg,
        @DecimalMin("30.0") @DecimalMax("45.0") BigDecimal temperatureC,
        @Min(10) @Max(400) Integer heartRateBpm,
        @Min(5) @Max(200) Integer respiratoryRateBpm,
        @Min(1) @Max(9) Integer bodyConditionScore,
        @Size(max = 30) String mucousMembraneColor,
        @DecimalMin("0.0") @DecimalMax("10.0") BigDecimal capillaryRefillSec,
        @Size(max = 255) String notes) {}

public record StartExaminationRequest(
        @Valid VitalSignsRequest vitalSigns,                 // có thể null
        @Size(max = 4000) String anamnesis) {}                // bệnh sử chủ nuôi kể, ghi vào medical_records
```

#### 2. Response DTO (`PetVisitResponse.java`)
```java
public record PetVisitResponse(
        UUID id, String visitCode,
        UUID petId, String petName, String speciesName,
        String ownerName,                 // pets.owner_name_snapshot – không gọi auth-service
        UUID doctorId, String doctorName, // pet_visits.doctor_name_snapshot – không gọi auth-service
        String roomNumber,                // phòng của Bác sĩ: cache đọc từ auth-service (có fallback)
        boolean emergency, String reasonForVisit,
        VisitStatus status, Instant checkedInAt,
        VitalSignsResponse latestVitalSigns,
        Integer queueTicketNo) {}         // số phiếu DOCTOR hiện tại (đọc Redis), null nếu không có
```

#### 3. MapStruct Mapper (`PetVisitMapper.java`)
```java
@Mapper(componentModel = "spring", unmappedTargetPolicy = ReportingPolicy.WARN)
public interface PetVisitMapper {
    @Mapping(target = "petId", source = "pet.id")
    @Mapping(target = "petName", source = "pet.name")
    @Mapping(target = "speciesName", source = "pet.species.name")
    @Mapping(target = "ownerName", source = "pet.ownerNameSnapshot")
    @Mapping(target = "doctorName", source = "doctorNameSnapshot")
    @Mapping(target = "emergency", source = "emergency")
    @Mapping(target = "roomNumber", ignore = true)
    @Mapping(target = "latestVitalSigns", ignore = true)
    @Mapping(target = "queueTicketNo", ignore = true)
    PetVisitResponse toResponse(PetVisit entity);

    VitalSigns toEntity(VitalSignsRequest request);       // visit, recordedBy gán ở service
}
```

#### 4. Repository (`PetVisitRepository.java`)
```java
@Repository
public interface PetVisitRepository extends JpaRepository<PetVisit, UUID> {

    boolean existsByDoctorIdAndStatusAndIdNot(UUID doctorId, VisitStatus status, UUID excludeVisitId);   // T02

    @Query("SELECT COUNT(v) > 0 FROM PetVisit v WHERE v.pet.id = :petId AND v.status NOT IN :closed")
    boolean existsOpenVisit(@Param("petId") UUID petId, @Param("closed") Collection<VisitStatus> closed); // T01

    @Modifying
    @Query("UPDATE PetVisit v SET v.doctorNameSnapshot = :name WHERE v.doctorId = :doctorId")
    int updateDoctorNameSnapshot(@Param("doctorId") UUID doctorId, @Param("name") String name);      // listener sự kiện
}
```
Không còn `QueueTicketRepository` (JPA): hàng đợi đọc qua `QueueRedisRepository` (mục 9.3), lịch sử qua `QueueTicketHistoryRepository`.

#### 5. OpenFeign Client (`UserClient.java`)
```java
@FeignClient(name = "auth-service", path = "/internal/users", fallbackFactory = UserClientFallback.class)
public interface UserClient {
    @GetMapping("/{id}")
    ApiResponse<UserSummaryResponse> getUserById(@PathVariable("id") UUID id);   // fullName, roles, status, roomNumber
}
```
Phân công Bác sĩ gọi `getUserById` **không dùng fallback** (Facade kiểm tra vai trò `VETERINARIAN` và `status = ACTIVE`, sai thì `CLIN_1316`); hiển thị số phòng dùng bản có fallback.

#### 6. Service Implementation (`PetVisitServiceImpl.java`)
```java
@Service
@RequiredArgsConstructor
public class PetVisitServiceImpl implements PetVisitService {

    private final PetVisitRepository petVisitRepository;
    private final PetVisitStatusHistoryRepository statusHistoryRepository;
    private final MedicalRecordRepository medicalRecordRepository;
    private final VitalSignsRepository vitalSignsRepository;
    private final VisitServiceDetailRepository serviceDetailRepository;
    private final VisitServiceDetailHistoryRepository serviceDetailHistoryRepository;
    private final QueueRedisRepository queue;
    private final PetVisitMapper mapper;

    /** T02 – Bác sĩ bấm "Bắt đầu" khi bệnh nhân vào phòng (UC-22). Phí khám đã thu, phiếu DOCTOR đang WAITING. */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public PetVisitResponse startExamination(UUID visitId, StartExaminationRequest request) {
        UUID doctorId = SecurityUtils.getCurrentUserId();
        PetVisit visit = petVisitRepository.findById(visitId)
                .orElseThrow(() -> new AppException(ErrorCode.VISIT_NOT_FOUND));

        if (visit.getStatus() != VisitStatus.WAITING) throw new AppException(ErrorCode.INVALID_STATUS_TRANSITION);
        if (!doctorId.equals(visit.getDoctorId())) throw new AppException(ErrorCode.NOT_ASSIGNED_DOCTOR);
        if (petVisitRepository.existsByDoctorIdAndStatusAndIdNot(doctorId, VisitStatus.IN_PROGRESS, visitId)) {
            throw new AppException(ErrorCode.DOCTOR_NOT_AVAILABLE);
        }
        // Phiếu DOCTOR đang chờ của ca (đọc Redis, không khóa) – không có nghĩa là chưa nộp phí khám (BR-35)
        QueueTicketView ticket = queue.findOpenTicket(visitId, QueueType.DOCTOR)
                .filter(t -> t.status() == TicketStatus.WAITING)
                .orElseThrow(() -> new AppException(ErrorCode.NO_QUEUE_TICKET));

        // 1. Đợt khám (hành chính) đổi trạng thái + lịch sử; @Version chống bấm trùng
        visit.setStatus(VisitStatus.IN_PROGRESS);
        statusHistoryRepository.save(PetVisitStatusHistory.of(visit, VisitStatus.WAITING, VisitStatus.IN_PROGRESS,
                doctorId, "Bác sĩ bắt đầu khám lâm sàng Giai đoạn 1"));

        // 2. Hồ sơ khám chuyên môn (1–1) được tạo ở bước này
        medicalRecordRepository.save(MedicalRecord.open(visit, request.anamnesis()));

        // 3. Sinh hiệu (nếu Bác sĩ nhập ngay)
        if (request.vitalSigns() != null) {
            VitalSigns vs = mapper.toEntity(request.vitalSigns());
            vs.setVisit(visit); vs.setRecordedBy(doctorId);
            vitalSignsRepository.save(vs);
        }

        // 4. Dịch vụ khám chuyển IN_PROGRESS + lịch sử
        VisitServiceDetail exam = serviceDetailRepository.findExaminationOfVisit(visitId)
                .orElseThrow(() -> new AppException(ErrorCode.INVALID_STATUS_TRANSITION));
        exam.setStatus(ServiceDetailStatus.IN_PROGRESS);
        serviceDetailHistoryRepository.save(VisitServiceDetailHistory.of(exam, ServiceDetailStatus.PENDING,
                ServiceDetailStatus.IN_PROGRESS, ServiceDetailAction.START_PROCESSING, doctorId, null));

        // 5. Chỉ sau khi commit mới đổi phiếu trên Redis (rollback thì phiếu giữ nguyên WAITING)
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override public void afterCommit() { queue.start(ticket.ticketId(), doctorId); }   // start_ticket.lua
        });
        return mapper.toResponse(visit);
    }
}
```
> Nếu `queue.start` lỗi sau commit (Redis vừa mất kết nối), đợt khám vẫn `IN_PROGRESS` – trạng thái nghiệp vụ đúng; phiếu được `QueueReconcileJob` (mỗi phút) chuyển `IN_SERVICE` theo trạng thái đợt khám. Hai Bác sĩ / hai lần bấm đồng thời bị chặn bởi `@Version` của `PetVisit` (MySQL) và kiểm tra trong `start_ticket.lua` (Redis).

#### 6b. Gọi số theo từng dòng (`QueueTicketServiceImpl.java`)
"Gọi" / "Gọi lại" **không đổi trạng thái hay thứ tự**: chỉ tăng `calledCount`, cập nhật `lastCalledAt` trên Hash phiếu (Redis) và gửi `PatientCalledEvent`. Không có giao dịch MySQL, không ghi lịch sử.

```java
@Service
@RequiredArgsConstructor
public class QueueTicketServiceImpl implements QueueTicketService {

    private final QueueRedisRepository queue;
    private final PetVisitRepository petVisitRepository;
    private final UserRoomResolver roomResolver;
    private final RabbitTemplate rabbitTemplate;

    @Override
    public QueueTicketView callNext(QueueType type) {
        UUID userId = SecurityUtils.getCurrentUserId();
        QueueTicketView head = queue.peekHead(type, type == QueueType.DOCTOR ? userId : null)   // ZRANGE 0 0
                .orElseThrow(() -> new AppException(ErrorCode.QUEUE_EMPTY));
        return doCall(head, userId);
    }

    @Override
    public QueueTicketView call(UUID ticketId) {
        UUID userId = SecurityUtils.getCurrentUserId();
        QueueTicketView t = queue.find(ticketId).orElseThrow(() -> new AppException(ErrorCode.TICKET_NOT_FOUND));
        if (t.queueType() == QueueType.DOCTOR && !userId.equals(t.doctorId())) {
            throw new AppException(ErrorCode.NOT_ASSIGNED_DOCTOR);                         // CLIN_1311
        }
        return doCall(t, userId);
    }

    private QueueTicketView doCall(QueueTicketView t, UUID userId) {
        if (t.status() != TicketStatus.WAITING) throw new AppException(ErrorCode.TICKET_NOT_WAITING);   // CLIN_1313
        if (t.queueType() == QueueType.DOCTOR
                && petVisitRepository.existsByDoctorIdAndStatusAndIdNot(userId, VisitStatus.IN_PROGRESS, t.visitId())) {
            throw new AppException(ErrorCode.DOCTOR_NOT_AVAILABLE);                        // BR-12
        }
        QueueTicketView called = queue.markCalled(t.ticketId(), Instant.now());              // HINCRBY + HSET
        rabbitTemplate.convertAndSend("clinic.events", "visit.patient_called",
                PatientCalledEvent.of(called, roomResolver.roomOf(userId)));               // gửi trực tiếp (chỉ hiển thị)
        return called;
    }
}
```
> Phân công Bác sĩ (`assign-doctor`) cập nhật `pet_visits.doctor_id`, `doctor_name_snapshot` trong giao dịch MySQL, `afterCommit` chuyển phiếu `DOCTOR` đang chờ sang Sorted Set của Bác sĩ mới (giữ `score`, giữ số phiếu – Lua `move_ticket.lua`). Ca có kết quả CLS (T06) ghi outbox `ParaclinicalResultsReadyEvent`; `QueueIssuerListener` phát phiếu `priority = 1`.

#### 7. REST Controller (`PetVisitController.java`)
```java
@RestController
@RequestMapping("/api/v1/clinical/pet-visits")
@RequiredArgsConstructor
public class PetVisitController {

    private final PetVisitService petVisitService;
    private final UserRoomResolver roomResolver;     // ngoài giao dịch, có cache + fallback

    @PostMapping("/{id}/start-exam")
    @PreAuthorize("hasRole('VETERINARIAN')")
    public ResponseEntity<ApiResponse<PetVisitResponse>> startExamination(
            @PathVariable UUID id, @Valid @RequestBody(required = false) StartExaminationRequest request) {
        PetVisitResponse res = petVisitService.startExamination(id,
                request != null ? request : new StartExaminationRequest(null, null));
        return ResponseEntity.ok(ApiResponse.success("Bác sĩ đã bắt đầu khám lâm sàng",
                res.withRoomNumber(roomResolver.roomOf(res.doctorId()))));   // tên Bác sĩ đã có sẵn từ snapshot
    }
}
```

### 11.3. Mẫu Triển Khai Tác Vụ Tự Động (Scheduled Task) & Audit Trail (`AppointmentNoShowScheduler.java`)

Áp dụng cho nghiệp vụ **EX-01 (Tự động đánh dấu vắng mặt No-show & giải phóng slot hẹn)** trong `appointment-service`. Bảng `appointments` v3.0 **không có `end_time` và `updated_at`**: khung giờ cố định 30 phút, mốc vắng mặt là `appointment_date + start_time + 30 phút` (khớp EX-01, FR-17); thời điểm đổi trạng thái lấy từ `appointment_status_histories.created_at`.

```java
// AppointmentRepository – lấy cả lịch của ngày trước còn sót (ví dụ hệ thống tắt qua đêm)
@Query("SELECT a FROM Appointment a WHERE a.status = 'CONFIRMED' AND " +
       "(a.appointmentDate < :today OR (a.appointmentDate = :today AND a.startTime < :cutoff))")
List<Appointment> findOverdueConfirmed(@Param("today") LocalDate today, @Param("cutoff") LocalTime cutoff);
```

```java
package com.vetclinic.appointment.scheduler;

import com.vetclinic.appointment.constant.AppointmentStatus;
import com.vetclinic.appointment.entity.Appointment;
import com.vetclinic.appointment.entity.AppointmentStatusHistory;
import com.vetclinic.appointment.event.AppointmentNoShowEvent;
import com.vetclinic.appointment.repository.AppointmentRepository;
import com.vetclinic.appointment.repository.AppointmentStatusHistoryRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import com.vetclinic.common.outbox.OutboxWriter;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.*;
import java.util.List;

@Slf4j
@Component
@RequiredArgsConstructor
public class AppointmentNoShowScheduler {

    private static final ZoneId CLINIC_ZONE = ZoneId.of("Asia/Ho_Chi_Minh");

    private final AppointmentRepository appointmentRepository;
    private final AppointmentStatusHistoryRepository statusHistoryRepository;
    private final OutboxWriter outbox;                          // v4.0: ghi sự kiện cùng giao dịch

    /**
     * Chạy mỗi 5 phút trong giờ làm việc.
     * Quy tắc EX-01: status == CONFIRMED && appointment_date + start_time + 30 phút < NOW
     */
    @Scheduled(cron = "0 */5 7-21 * * *", zone = "Asia/Ho_Chi_Minh")
    @Transactional
    public void scanAndMarkNoShowAppointments() {
        LocalDateTime now = LocalDateTime.now(CLINIC_ZONE);
        List<Appointment> overdue = appointmentRepository
                .findOverdueConfirmed(now.toLocalDate(), now.toLocalTime().minusMinutes(30));
        if (overdue.isEmpty()) {
            return;
        }
        log.info("Phát hiện {} lịch hẹn quá start_time + 30 phút chưa check-in, chuyển sang NO_SHOW", overdue.size());

        for (Appointment appt : overdue) {
            appt.setStatus(AppointmentStatus.NO_SHOW);          // không còn cột updated_at
            statusHistoryRepository.save(AppointmentStatusHistory.builder()
                    .appointmentId(appt.getId())
                    .fromStatus(AppointmentStatus.CONFIRMED)
                    .toStatus(AppointmentStatus.NO_SHOW)
                    .changedByUserId(null)                      // null = hệ thống tự động
                    .notes("Tự động đánh dấu vắng mặt do trễ quá 30 phút so với giờ hẹn")
                    .build());                                  // created_at do CSDL gán
            outbox.write("APPOINTMENT", appt.getId(), "appointment.no_show",
                    AppointmentNoShowEvent.of(appt));          // id là UUID; payload có tên thú cưng / chủ nuôi từ snapshot
        }
    }
}
```

> **Phối hợp với check-in:** `VisitCheckedInEvent` có thể đến sau vài trăm mili giây. Consumer ở `appointment-service` chỉ chuyển `CONFIRMED → CHECKED_IN`; nếu lịch đã bị đánh dấu `NO_SHOW` đúng lúc đó, consumer ghi log cảnh báo để Lễ tân kiểm tra (trường hợp hiếm vì Lễ tân không check-in lịch đã quá mốc; khách đến muộn được tiếp nhận như khách vãng lai).

---

## TỔNG KẾT & CAM KẾT TUÂN THỦ

1. **Hiệu lực thi hành:** Tài liệu Phiên bản 4.0 (18/11/2026) có giá trị áp dụng ngay từ ngày bắt đầu lập trình (Sprint 1 - Tuần 9 theo Kế hoạch đồ án; khung dự án dựng từ Tuần 8).
2. **Quy tắc Code Review:** Khi tạo Pull Request (PR) trên Git, mọi thành viên bắt buộc kiểm tra đối soát chéo theo danh sách 11 Chương quy chuẩn này. Bất kỳ đoạn mã nào vi phạm (ví dụ: trừ kho không nguyên tử, gửi sự kiện nghiệp vụ không qua outbox, consumer không idempotent, thao tác Redis trong `@Transactional`, khóa thực thể dùng `Long` / UUIDv4, cột `ENUM` MySQL, sửa số tiền của dòng giá cũ, trả Entity trực tiếp, thiếu `@PreAuthorize`) đều bị từ chối phê duyệt (Reject PR).

---

## PHỤ LỤC: LỊCH SỬ THAY ĐỔI

| Vị trí | Bản cũ | Bản mới | Lý do |
| :--- | :--- | :--- | :--- |
| **Toàn bộ (v4.0, 18/11/2026)** | Khóa `Long`; `QueueTicket` JPA + `TicketIssuer` phát phiếu trong giao dịch thu tiền; `@TransactionalEventListener(AFTER_COMMIT)` gửi sự kiện; `Medicine` chứa giá, tồn; bán thuốc từ `prescription_items`; `X-User-Role` một vai trò; refresh token lưu nguyên văn; 41 mã lỗi; 9–10 sự kiện | Khóa `UUID` v7 (`@UuidGenerator VERSION_7`), danh mục `Short`; hàng đợi Redis (`QueueRedisRepository`, Lua `issue/start/finish/move_ticket`, `QueueIssuerListener`, `QueueRebuildJob`); `OutboxWriter` + `OutboxRelay` + `IdempotentConsumer`; `ServicePriceBook` / `MedicinePriceBook`; `MedicineStock` tách riêng, trừ kho trên `medicine_stocks`; hóa đơn thuốc nháp từ `PrescriptionCreatedEvent`, dòng trỏ `medicines`; `X-User-Roles` nhiều vai trò, `SecurityUtils` trả `UUID`; refresh token lưu SHA-256; 49 mã lỗi; 17 sự kiện; module `reporting-service`; Redis + Resilience4j trong tech stack; mẫu 11.2 dùng `vital_signs`, `medical_records` | Nhận xét chi tiết của GVHD (Notes.pdf + góp ý bổ sung) |
| Tiêu đề, Chương 1, 11.1 | Spring Boot "4.1.11" | Spring Boot 4.1.1 + Spring Cloud 2025.1.2 (Oakwood) trở lên | Không có bản 4.1.11; 2025.1.2 là bản Spring Cloud đầu tiên hỗ trợ Boot 4.1 |
| 2.2 | `scanBasePackages = "com.vetclinic"` cho mọi service; cấu hình servlet là `@Component` / `@Configuration` trong `common-library` | Mỗi service quét package riêng; cấu hình servlet nạp bằng `CommonWebAutoConfiguration` (`@ConditionalOnWebApplication(SERVLET)`); phụ thuộc servlet của `common-library` là `optional`; Eureka không dùng `common-library` | Gateway (WebFlux) và Eureka lỗi khởi động khi nạp nhầm cấu hình servlet |
| 3.1 | Ví dụ enum `DISPENSED`; tiền `totalAmount` | `EXPORT_SALE`; không lưu tổng tiền | Enum và cột đã bỏ ở v3.0 |
| 3.2 | `/billing/invoices`, `/pharmacy/prescriptions/{id}/dispense` | Hóa đơn dịch vụ ở `/clinical/...service-invoices`; bán thuốc ở `/pharmacy/prescriptions/{id}/medicine-invoices` và `/billing/medicine-invoices/{id}/confirm-payment`; endpoint nội bộ `/internal/**` | Hai loại hóa đơn ở hai service |
| 5.1 | `PRESCRIPTION_ALREADY_DISPENSED`, `DISCOUNT_EXCEEDS_TOTAL` | `PRESCRIPTION_ALREADY_INVOICED`, `DISCOUNT_EXCEEDS_INVOICE_AMOUNT`; thêm mã cho các ràng buộc mới (`PET_HAS_OPEN_VISIT`, `DIAGNOSIS_REQUIRED`, `VITAL_SIGNS_REQUIRED`, `PURCHASE_QUANTITY_EXCEEDS_PRESCRIBED`…) | Bỏ trạng thái đơn thuốc; giảm giá theo từng hóa đơn |
| 5.2 | `FeignException` xử lý trong `GlobalExceptionHandler` | Tách `FeignExceptionHandler` có điều kiện | Service không có Feign sẽ lỗi `NoClassDefFoundError` |
| 7.2 | `@Version` trên `Invoice` | Trên `ServiceInvoice`, `MedicineInvoice`; entity `Medicine` có `salePrice`, `vatRate` | Lược đồ v3.0 |
| Chương 8 | `dispensePrescription`: đổi `prescriptions.status`, `EXPORT_PRESCRIPTION`, `balanceAfter`, phát `PaymentAndDispenseCompletedEvent` | `MedicineSaleServiceImpl`: lập hóa đơn thuốc + `confirmPayment` (trừ kho, `EXPORT_SALE` số lượng âm, `PAID` trong 1 giao dịch); thêm mẫu thu hóa đơn dịch vụ + hoàn tất ca ở `clinical-service`; bulk update tăng `version` | Mua thuốc tùy chọn; ca khám hoàn tất cục bộ |
| 9.1 | Không quy định Feign chỉ đọc | Feign chỉ đọc, gọi `/internal/**`, ngoài `@Transactional` | Tránh ghi chéo CSDL (check-in dùng sự kiện) |
| 9.2 | 6 sự kiện, tên lệch với Kiến trúc và Lộ trình | 9 sự kiện chuẩn trên `clinic.events`, consumer idempotent + DLQ | Thống nhất một danh mục |
| 10.1 | Gateway chuyển tiếp request không token | Gateway trả `401` cho route cần đăng nhập; chặn `/internal/**` | Thiếu token bị trả `403` nên Axios không gọi refresh |
| 10.2 | `"ROLE_" + userRole` trong khi token đã chứa `ROLE_...`; filter là `@Component`; không có entry point | Claim `role` không tiền tố, filter thêm `ROLE_` đúng một lần; filter không phải `@Component`; `authenticationEntryPoint` 401, `accessDeniedHandler` 403 | Sửa lỗi `ROLE_ROLE_`, filter chạy 2 lần, mã 403 sai |
| 11.2 | `StartExaminationRequest` bắt buộc sinh hiệu; gán `doctorId` khi bắt đầu khám; `startedAt`, `getAssignedRoom()`; gọi Feign trong `@Transactional` | Sinh hiệu tùy chọn ở bước này; kiểm tra đúng Bác sĩ được phân công; tạo dịch vụ khám + hóa đơn dịch vụ; ghi lịch sử; Feign làm giàu dữ liệu ở Controller sau commit | Cột đã bỏ; khớp State Machine T02 |
| 11.3 | `end_time + 30'`, `setUpdatedAt` | `appointment_date + start_time + 30'`; không có `updated_at`; phát `AppointmentNoShowEvent` | Khớp lược đồ và EX-01 |
| Mục lục (rà soát 10/11) | 5 liên kết chương 4, 5, 7, 9, 10 không trỏ đúng tiêu đề | Sửa anchor theo đúng tiêu đề | Liên kết hỏng |
| 3.2 (rà soát 10/11) | `POST /api/v1/notifications/send-email` công khai; không có API sửa hóa đơn thuốc | Bỏ API gửi email công khai; thêm `PUT /api/v1/billing/medicine-invoices/{id}/items` | Notification chỉ nhận sự kiện; EX-15 cần sửa hóa đơn |
| 8.1, 8.2 (rà soát 10/11) | `clearAutomatically = true` làm detach entity giữa giao dịch; `findLowStock` chưa khai báo; không có hàm sửa hóa đơn | Bỏ `clearAutomatically`; khai báo `findLowStock`; thêm `updateItems` | Lỗi LazyInitializationException; thiếu chức năng |
| 8.3 (rà soát 10/11) | Hóa đơn `CANCELLED` báo `BILL_1403`; id không thuộc ca bị bỏ qua; so sánh enum bằng chuỗi trong JPQL | Báo `BILL_1408`; kiểm tra đủ id (`BILL_1401`); truyền enum qua tham số | Mã lỗi đúng, không bỏ sót dữ liệu sai |
| Tổng kết (rà soát 10/11) | "Sprint 1 - Tuần 8" | Sprint 1 - Tuần 9 | Khớp Kế hoạch |
| 3.2, 5.1, 11.2 (rà soát 11/11) | `findWaitingQueue()` hàng đợi sảnh chung; `CLIN_1303 DOCTOR_PRIORITY_LOCKED`; không có API gọi số / đẩy lùi | Hàng đợi riêng từng Bác sĩ: `findDoctorQueue`, `findUnassigned`, `countWaitingByDoctor`; `DoctorQueueServiceImpl` (`callNext`, `skip`), `QueueOrders`; `CLIN_1303 QUEUE_EMPTY` (vẫn 39 mã); thêm `GET …/queue`, `…/my-queue`, `POST …/call-next`, `…/{id}/skip`, `service-details/{id}/skip` | Mô hình hàng đợi riêng + Đẩy lùi 1 bậc |
| 3.2, 6b (cập nhật 13/11) | `POST …/{id}/skip`, `service-details/{id}/skip`; mã mẫu `skip` (Đẩy lùi 1 bậc) và ghi chú về `rest` | `POST …/{id}/call`, `service-details/{id}/call`; mã mẫu `call` (không đổi trạng thái/thứ tự); ghi chú vì sao bỏ đẩy lùi | Đẩy lùi 1 bậc làm hai ca đầu hàng đổi chỗ mãi mãi và làm ca cấp cứu mất ưu tiên; gọi theo từng dòng giống thực tế phòng khám |
| 5.1, 8.2 (cập nhật 13/11) | `PURCHASE_QUANTITY_EXCEEDS_PRESCRIBED` (`PHARM_1410`): mua ≤ số lượng kê; mã mẫu `createInvoice` / `updateItems` chặn theo số kê | Bỏ mã `PHARM_1410` (còn 38 mã); mã mẫu chặn theo tồn kho bằng `INSUFFICIENT_STOCK` (`PHARM_1406`); số kê chỉ để tham khảo | Khách có thể mua nhiều hơn / ít hơn đơn; ràng buộc đúng là tồn kho (kiểm tra sớm, và kiểm tra lại nguyên tử lúc thu tiền) |
| 3.1, 3.2, 5.1, 7.2, 8.3, 11.2 (cập nhật 16–17/11) | Hàng đợi đọc `queue_order` trên `PetVisit` / `VisitServiceDetail` (`QueueOrders`, `findMinQueueOrder`); API gọi số theo `pet-visits/{id}/call`, `service-details/{id}/call`; dịch vụ khám tạo lúc `start-exam`; thu tiền chỉ khi `WAITING_PAYMENT`; `CLIN_1310` cấm hủy dịch vụ đã thu | Hàng đợi là `QueueTicket` (`QueueTicketRepository`, `QueueTicketServiceImpl`, `TicketIssuer`); API `queue-tickets/{id}/call`, `/start`, `call-next?queueType=`; `cashier/pending` 3 mục; `start-exam` yêu cầu phiếu `DOCTOR` `WAITING` (`CLIN_1314`); `confirmServicePayment` thu ngay dịch vụ `requiresPrepayment` và phát phiếu cùng giao dịch; `REFUNDED`; mã lỗi `CLIN_1310` (không hoàn), `CLIN_1312`–`CLIN_1314`; 12 enum | Góp ý GVHD: tách quy trình thanh toán khỏi quy trình khám; tách dữ liệu hàng đợi khỏi hồ sơ khám |
