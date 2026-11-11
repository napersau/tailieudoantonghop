# QUY CHUẨN THIẾT KẾ VÀ LẬP TRÌNH BACKEND (JAVA 21 & SPRING BOOT 4.1.1)
## HỆ THỐNG QUẢN LÝ PHÒNG KHÁM THÚ Y (MICROSERVICES ARCHITECTURE)
### PHIÊN BẢN 3.0 (PRODUCTION-GRADE STANDARDS – đồng bộ lược đồ CSDL v3.0 và Kiến trúc v3.0)

> **Tài liệu quy chuẩn kỹ thuật bắt buộc (Mandatory Engineering Standards)**  
> **Áp dụng cho:** Toàn bộ thành viên đội ngũ phát triển Backend (Lưu Minh Hiển, Nguyễn Đức Khởi, Vũ Hồng Linh).  
> **Mục tiêu:** Đồng bộ hóa 100% phong cách lập trình (Code Style), kiến trúc phân tầng, định dạng API, quản lý giao dịch CSDL, an toàn concurrency kho dược, xử lý ngoại lệ và giao tiếp phân tán liên Microservice.

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
| **Database Engine** | **MySQL 8.0+** | Mô hình Database-per-Service: 4 logical schemas độc lập. |
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
├── billing-pharmacy-service/             # Kê đơn, bán thuốc (hóa đơn thuốc) & kho dược (:8084) - Dùng spring-boot-starter-web
│   ├── pom.xml
│   └── src/main/java/com/vetclinic/billing/
└── notification-service/                 # Dịch vụ WebSocket & email (:8085) - Dùng spring-boot-starter-web
    ├── pom.xml
    └── src/main/java/com/vetclinic/notification/
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
├── event/                   # Event DTOs cụ thể & Producer/Consumer RabbitMQ
└── constant/                # Enum nội bộ, Hằng số nghiệp vụ riêng của service
```

---

## CHƯƠNG 3: QUY CHUẨN ĐẶT TÊN & THIẾT KẾ RESTFUL API

### 3.1. Quy chuẩn Java Code Style & Kiểu Dữ liệu Bắt buộc
- **Java Platform:** Java 21 LTS. DTOs có thể sử dụng `record` (bất biến) hoặc class thường với Lombok.
- **Tiền tệ & Số thực tài chính:** **Bắt buộc dùng `BigDecimal`** (ví dụ: `unitPrice`, `vatRate`, `discountAmount`; tổng tiền không lưu mà tính khi cần). Tuyệt đối cấm dùng `double` hoặc `float` gây sai số làm tròn số tiền.
- **Thời gian (Timestamp):** Dùng `Instant` cho thời điểm giao dịch (`checkedInAt`, `paidAt`, `createdAt`). Lưu trữ dạng UTC trong Database; tầng hiển thị Frontend hoặc DTO Response chuyển đổi sang múi giờ Việt Nam (`Asia/Ho_Chi_Minh` - GMT+7).
- **Hằng số & Enum:** `UPPER_SNAKE_CASE` (ví dụ: `WAITING_RESULTS`, `EXPORT_SALE`). Khớp 100% với file `DANH_SACH_KIEU_ENUM_HE_THONG.md` v3.0 (10 enum CSDL + `LabEvaluation` chỉ dùng ở tầng ứng dụng; không còn `PrescriptionStatus`, `InvoiceItemType`).

### 3.2. Quy chuẩn Thiết kế RESTful API URIs & Prefix Thống nhất
Nhằm đồng bộ hoàn toàn giữa **Spring Cloud Gateway**, **Controller** và **OpenFeign Clients**, toàn bộ URI tuân thủ quy tắc tiền tố:

| Microservice | Prefix URI qua Gateway & Controller | Ví dụ Endpoint CRUD | Ví dụ Action Endpoint (Động từ) |
| :--- | :--- | :--- | :--- |
| **`auth-service`** | `/api/v1/auth/**` | `GET /api/v1/auth/users` | `POST /api/v1/auth/login`<br>`POST /api/v1/auth/refresh` |
| **`appointment-service`** | `/api/v1/appointments/**` | `GET /api/v1/appointments`<br>`GET /api/v1/appointments/slots?date=` | `POST /api/v1/appointments/{id}/confirm`<br>`POST /api/v1/appointments/{id}/cancel` |
| **`clinical-service`** | `/api/v1/clinical/**`<br>`/api/v1/pets/**`<br>`/api/v1/species/**` | `GET /api/v1/clinical/pet-visits`<br>`GET /api/v1/clinical/pet-visits/{id}/service-invoices`<br>`GET /api/v1/pets/{id}` | `POST /api/v1/clinical/pet-visits/check-in`<br>`POST /api/v1/clinical/pet-visits/{id}/start-exam`<br>`POST /api/v1/clinical/pet-visits/{id}/close-visit`<br>`POST /api/v1/clinical/pet-visits/{id}/reopen`<br>`POST /api/v1/clinical/service-invoices/{id}/discount`<br>`POST /api/v1/clinical/pet-visits/{id}/service-invoices/confirm-payment` |
| **`billing-pharmacy-service`** | `/api/v1/pharmacy/**`<br>`/api/v1/billing/**` | `GET /api/v1/pharmacy/medicines`<br>`GET /api/v1/pharmacy/prescriptions/{id}`<br>`GET /api/v1/billing/medicine-invoices/{id}` | `POST /api/v1/pharmacy/prescriptions/{id}/medicine-invoices` (lập hóa đơn thuốc)<br>`PUT /api/v1/billing/medicine-invoices/{id}/items` (sửa dòng khi `PENDING`)<br>`POST /api/v1/billing/medicine-invoices/{id}/confirm-payment` (thu tiền + trừ kho)<br>`POST /api/v1/billing/medicine-invoices/{id}/cancel` |
| **`notification-service`** | `/api/v1/notifications/**`<br>`/ws/**` | `GET /api/v1/notifications` (thông báo của người dùng hiện tại) | `POST /api/v1/notifications/{id}/read`. Không có API gửi email công khai: Email / WebSocket chỉ được kích hoạt bởi sự kiện RabbitMQ. |

> [!NOTE]
> **Quy tắc về Action Endpoint:** Đối với các thao tác chuyển đổi trạng thái nghiệp vụ (bắt đầu khám, chốt ca, mở lại hồ sơ, xác nhận thanh toán, bán thuốc), cho phép dùng động từ ở cuối URI nhưng **bắt buộc dùng phương thức `POST`**, và tầng Service phải chống bấm trùng (kiểm tra trạng thái nguồn + `@Version`).
>
> **Endpoint nội bộ:** lời gọi Feign giữa các service dùng tiền tố `/internal/**` (ví dụ `GET /internal/pet-visits/{id}/summary`). Gateway **không định tuyến** tiền tố này ra ngoài. Danh mục lời gọi Feign theo `THIET_KE_KIEN_TRUC_MICROSERVICES.md` mục 5.1.


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

    // 3. Thú cưng & Lịch hẹn (APPT: 1200 - 1299)
    PET_NOT_FOUND("APPT_1201", "Không tìm thấy hồ sơ thú cưng", HttpStatus.NOT_FOUND),
    APPOINTMENT_NOT_FOUND("APPT_1202", "Không tìm thấy lịch hẹn", HttpStatus.NOT_FOUND),
    SLOT_CAPACITY_EXCEEDED("APPT_1203", "Khung giờ khám đã kín chỗ, vui lòng chọn khung giờ khác", HttpStatus.BAD_REQUEST),
    CANNOT_CANCEL_APPOINTMENT("APPT_1204", "Chỉ được phép hủy hẹn trước giờ khám tối thiểu 2 tiếng", HttpStatus.BAD_REQUEST),
    APPOINTMENT_NOT_CHECKABLE("APPT_1205", "Lịch hẹn không ở trạng thái CONFIRMED hoặc không đúng ngày hẹn", HttpStatus.BAD_REQUEST),

    // 4. Khám lâm sàng & Cận lâm sàng (CLIN: 1300 - 1399)
    VISIT_NOT_FOUND("CLIN_1301", "Không tìm thấy đợt khám y tế", HttpStatus.NOT_FOUND),
    DOCTOR_NOT_AVAILABLE("CLIN_1302", "Bác sĩ đang nhận hoặc đang khám ca khác", HttpStatus.CONFLICT),
    DOCTOR_PRIORITY_LOCKED("CLIN_1303", "Bác sĩ đang có ca vừa có kết quả cận lâm sàng, vui lòng ưu tiên gọi lại ca tái khám", HttpStatus.CONFLICT),
    PARACLINICAL_SERVICE_IN_PROGRESS("CLIN_1304", "Dịch vụ cận lâm sàng đang thực hiện, không thể hủy", HttpStatus.BAD_REQUEST),
    INVALID_STATUS_TRANSITION("CLIN_1305", "Trạng thái ca khám không hợp lệ để thực hiện thao tác này", HttpStatus.BAD_REQUEST),
    PET_HAS_OPEN_VISIT("CLIN_1306", "Thú cưng đang có đợt khám chưa kết thúc", HttpStatus.CONFLICT),
    DIAGNOSIS_REQUIRED("CLIN_1307", "Vui lòng nhập chẩn đoán trước khi chốt đợt khám", HttpStatus.BAD_REQUEST),
    VITAL_SIGNS_REQUIRED("CLIN_1308", "Vui lòng nhập cân nặng và thân nhiệt của thú cưng", HttpStatus.BAD_REQUEST),
    IN_ROOM_SERVICE_PENDING("CLIN_1309", "Còn dịch vụ tại phòng chưa thực hiện hoặc chưa hủy", HttpStatus.BAD_REQUEST),
    PAID_SERVICE_CANNOT_BE_CANCELLED("CLIN_1310", "Không thể hủy dịch vụ đã được thanh toán", HttpStatus.CONFLICT),
    NOT_ASSIGNED_DOCTOR("CLIN_1311", "Bạn không phải Bác sĩ được phân công cho ca khám này", HttpStatus.FORBIDDEN),

    // 5. Hóa đơn & Kho dược (BILL/PHARM: 1400 - 1499) – dùng cho cả service_invoices (clinical) và medicine_invoices (billing-pharmacy)
    INVOICE_NOT_FOUND("BILL_1401", "Không tìm thấy hóa đơn", HttpStatus.NOT_FOUND),
    DISCOUNT_EXCEEDS_INVOICE_AMOUNT("BILL_1402", "Số tiền giảm giá không được vượt quá số tiền của hóa đơn này", HttpStatus.BAD_REQUEST),
    INVOICE_ALREADY_PAID("BILL_1403", "Hóa đơn này đã được thanh toán trước đó", HttpStatus.CONFLICT),
    INVOICE_ALREADY_CANCELLED("BILL_1408", "Hóa đơn này đã bị hủy", HttpStatus.CONFLICT),
    VISIT_NOT_READY_FOR_PAYMENT("BILL_1409", "Đợt khám chưa được Bác sĩ chốt chuyên môn", HttpStatus.BAD_REQUEST),
    PRESCRIPTION_NOT_FOUND("PHARM_1404", "Không tìm thấy đơn thuốc của đợt khám", HttpStatus.NOT_FOUND),
    MEDICINE_NOT_FOUND("PHARM_1405", "Không tìm thấy thuốc trong danh mục kho", HttpStatus.NOT_FOUND),
    INSUFFICIENT_STOCK("PHARM_1406", "Số lượng tồn kho không đủ để bán", HttpStatus.CONFLICT),
    PRESCRIPTION_ALREADY_INVOICED("PHARM_1407", "Đơn thuốc này đã được lập hóa đơn thuốc trước đó", HttpStatus.CONFLICT),
    PURCHASE_QUANTITY_EXCEEDS_PRESCRIBED("PHARM_1410", "Số lượng mua không được vượt quá số lượng Bác sĩ đã kê", HttpStatus.BAD_REQUEST),
    PRESCRIPTION_LOCKED("PHARM_1411", "Đơn thuốc đã khóa (đợt khám đã chốt hoặc đơn đã được bán), không thể chỉnh sửa", HttpStatus.CONFLICT);

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

### 7.2. Kiểm soát Concurrency với `@Version`
Đối với các Entity có trạng thái thay đổi đồng thời (`PetVisit`, `ServiceInvoice`, `MedicineInvoice`, `Medicine`), bắt buộc thêm trường `@Version` để ngăn ngừa ghi đè dữ liệu (Optimistic Locking):

```java
@Entity
@Table(name = "medicines")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Medicine {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "code", nullable = false, unique = true, length = 50)
    private String code;

    @Column(name = "name", nullable = false, length = 150)
    private String name;

    @Column(name = "sale_price", nullable = false, precision = 12, scale = 2)
    private BigDecimal salePrice;    // Giá bán niêm yết hiện tại (snapshot sang medicine_invoice_items khi bán)

    @Column(name = "vat_rate", nullable = false, precision = 4, scale = 2)
    private BigDecimal vatRate;

    @Column(name = "stock_quantity", nullable = false)
    private Integer stockQuantity;   // Chỉ thay đổi qua deductStockQuantity / giao dịch kho, không sửa tay

    @Column(name = "min_stock_alert", nullable = false)
    private Integer minStockAlert;

    @Version
    private Long version; // Khóa lạc quan chống race condition
}
```

---

## CHƯƠNG 8: QUẢN LÝ GIAO DỊCH CSDL & AN TOÀN CONCURRENCY KHO DƯỢC

### 8.0. Nguyên tắc chung
- Mỗi nghiệp vụ tiền / kho nằm trọn trong CSDL của **một** service và được bọc trong **một** phương thức `@Transactional(rollbackFor = Exception.class)`:
  - `clinical-service`: chỉ định dịch vụ + lập `service_invoices`; hủy dịch vụ + hủy hóa đơn; thu hóa đơn dịch vụ + hoàn tất ca khám.
  - `billing-pharmacy-service`: lập `medicine_invoices`; thu tiền hóa đơn thuốc + trừ kho + ghi `inventory_transactions`.
- **Không gọi Feign bên trong `@Transactional`.** Kiểm tra điều kiện liên service (ví dụ trạng thái đợt khám) thực hiện ở lớp Facade trước khi gọi phương thức giao dịch.
- **Không lưu tổng tiền.** Số tiền được tính bằng VIEW (`v_service_invoice_amounts`, `v_medicine_invoice_amounts`) hoặc tính trong code từ `quantity × unitPrice × (1 + vatRate) − discountAmount`.

### 8.1. Trừ kho Nguyên tử Tuyệt đối (Atomic SQL Update)
Để chống hiện tượng hai thu ngân cùng bán hộp thuốc cuối cùng dẫn đến kho bị âm, **Repository bắt buộc định nghĩa câu lệnh cập nhật có điều kiện kiểm tra tồn kho tại tầng Database** (đồng thời tăng `version` vì câu lệnh bulk update không đi qua cơ chế `@Version` của Hibernate):

```java
package com.vetclinic.billing.repository;

import com.vetclinic.billing.entity.Medicine;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MedicineRepository extends JpaRepository<Medicine, Long> {

    // Không dùng clearAutomatically: xóa persistence context giữa giao dịch sẽ làm các entity đã nạp
    // (hóa đơn, thuốc) bị detach và gây LazyInitializationException ở các dòng sau.
    @Modifying(flushAutomatically = true)
    @Query("UPDATE Medicine m SET m.stockQuantity = m.stockQuantity - :quantity, m.version = m.version + 1 " +
           "WHERE m.id = :id AND m.stockQuantity >= :quantity")
    int deductStockQuantity(@Param("id") Long id, @Param("quantity") int quantity);

    // Đọc lại tồn kho sau khi trừ (native query bỏ qua bộ nhớ đệm cấp 1) để phát MedicineLowStockEvent
    @Query(value = "SELECT * FROM medicines WHERE id IN (:ids) AND stock_quantity <= min_stock_alert", nativeQuery = true)
    List<Medicine> findLowStock(@Param("ids") List<Long> ids);
}
```

### 8.2. Mẫu chuẩn: Bán thuốc theo đơn & Trừ kho (`billing-pharmacy-service`)
Quy trình gồm 2 bước chính và 1 thao tác sửa (UC-36):
1. **Lập hóa đơn thuốc** (`PENDING`): khách chọn thuốc và số lượng (≤ số lượng kê), snapshot `unitPrice = medicines.sale_price`, `vatRate = medicines.vat_rate`.
   - **Sửa hóa đơn thuốc** khi còn `PENDING` (khách bớt thuốc, hoặc sau EX-15): cập nhật / xóa dòng, giữ snapshot giá đã chốt, kiểm tra lại giảm giá. Không lập hóa đơn mới vì `prescription_id UNIQUE`; hóa đơn đã hủy là kết thúc.
2. **Xác nhận thanh toán & xuất thuốc:** trong **một giao dịch**: trừ kho có điều kiện → ghi `inventory_transactions` (`EXPORT_SALE`, `quantity` âm) → hóa đơn `PAID`. Thiếu kho ở bất kỳ dòng nào thì rollback toàn bộ (EX-15).

Quy tắc bổ sung:
- Sắp xếp các dòng theo `medicineId` tăng dần trước khi trừ để **loại trừ nguy cơ Deadlock**.
- Chống bán trùng (EX-16): `medicine_invoices.prescription_id UNIQUE` + kiểm tra trạng thái `PENDING` + `@Version` trên `MedicineInvoice`.

```java
package com.vetclinic.billing.service.impl;

import com.vetclinic.billing.client.ClinicalVisitClient;
import com.vetclinic.billing.constant.InventoryTransactionType;
import com.vetclinic.billing.constant.PaymentStatus;
import com.vetclinic.billing.dto.request.CreateMedicineInvoiceRequest;
import com.vetclinic.billing.entity.*;
import com.vetclinic.billing.event.MedicineInvoicePaidEvent;
import com.vetclinic.billing.event.MedicineLowStockEvent;
import com.vetclinic.billing.repository.*;
import com.vetclinic.common.exception.AppException;
import com.vetclinic.common.exception.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class MedicineSaleServiceImpl implements MedicineSaleService {

    private final PrescriptionRepository prescriptionRepository;
    private final MedicineRepository medicineRepository;
    private final MedicineInvoiceRepository medicineInvoiceRepository;
    private final InventoryTransactionRepository inventoryRepository;
    private final InvoiceCodeGenerator invoiceCodeGenerator;
    private final ApplicationEventPublisher eventPublisher;

    /**
     * Bước 1 – Lập hóa đơn thuốc (PENDING).
     * Điều kiện "đợt khám đã WAITING_PAYMENT / COMPLETED" được Facade kiểm tra qua Feign TRƯỚC khi gọi hàm này.
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public MedicineInvoice createInvoice(Long prescriptionId, CreateMedicineInvoiceRequest request) {
        Prescription prescription = prescriptionRepository.findById(prescriptionId)
                .orElseThrow(() -> new AppException(ErrorCode.PRESCRIPTION_NOT_FOUND));

        if (medicineInvoiceRepository.existsByPrescriptionId(prescriptionId)) {
            throw new AppException(ErrorCode.PRESCRIPTION_ALREADY_INVOICED);          // EX-16
        }

        Map<Long, PrescriptionItem> prescribed = prescription.getItems().stream()
                .collect(Collectors.toMap(PrescriptionItem::getId, Function.identity()));

        MedicineInvoice invoice = MedicineInvoice.builder()
                .invoiceCode(invoiceCodeGenerator.next("MINV"))
                .prescription(prescription)
                .discountAmount(request.discountAmount())
                .paymentStatus(PaymentStatus.PENDING)
                .build();

        for (var line : request.items()) {                                            // khách được mua một phần đơn
            PrescriptionItem pi = prescribed.get(line.prescriptionItemId());
            if (pi == null) throw new AppException(ErrorCode.INVALID_INPUT_DATA);
            if (line.quantity() > pi.getQuantity()) {
                throw new AppException(ErrorCode.PURCHASE_QUANTITY_EXCEEDS_PRESCRIBED);
            }
            Medicine med = pi.getMedicine();
            invoice.addItem(MedicineInvoiceItem.builder()
                    .prescriptionItem(pi)
                    .quantity(line.quantity())
                    .unitPrice(med.getSalePrice())                                    // snapshot giá bán
                    .vatRate(med.getVatRate())                                        // snapshot thuế suất
                    .build());
        }

        if (invoice.getDiscountAmount().compareTo(invoice.grossAmount()) > 0) {      // EX-14
            throw new AppException(ErrorCode.DISCOUNT_EXCEEDS_INVOICE_AMOUNT);
        }
        return medicineInvoiceRepository.save(invoice);                               // UNIQUE(prescription_id) chặn race
    }

    /**
     * Sửa hóa đơn thuốc đang PENDING (UC-36 Luồng 9a, EX-15): giảm số lượng hoặc bỏ dòng.
     * Map: prescriptionItemId -> số lượng mới (0 = bỏ dòng). Snapshot giá của các dòng còn lại giữ nguyên.
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public MedicineInvoice updateItems(Long invoiceId, Map<Long, Integer> newQuantities, BigDecimal discountAmount) {
        MedicineInvoice invoice = medicineInvoiceRepository.findById(invoiceId)
                .orElseThrow(() -> new AppException(ErrorCode.INVOICE_NOT_FOUND));
        switch (invoice.getPaymentStatus()) {
            case PAID -> throw new AppException(ErrorCode.INVOICE_ALREADY_PAID);
            case CANCELLED -> throw new AppException(ErrorCode.INVOICE_ALREADY_CANCELLED);
            case PENDING -> { }
        }
        for (var entry : newQuantities.entrySet()) {
            MedicineInvoiceItem item = invoice.findItemByPrescriptionItemId(entry.getKey())
                    .orElseThrow(() -> new AppException(ErrorCode.INVALID_INPUT_DATA)); // chỉ sửa / bỏ dòng đã có
            int qty = entry.getValue();
            if (qty == 0) {
                invoice.removeItem(item);                                             // orphanRemoval = true
            } else if (qty < 0 || qty > item.getPrescriptionItem().getQuantity()) {
                throw new AppException(ErrorCode.PURCHASE_QUANTITY_EXCEEDS_PRESCRIBED);
            } else {
                item.setQuantity(qty);                                                // giữ unitPrice, vatRate
            }
        }
        if (invoice.getItems().isEmpty()) {
            throw new AppException(ErrorCode.INVALID_INPUT_DATA, "Hóa đơn thuốc phải còn ít nhất 1 dòng; nếu khách không mua, hãy hủy hóa đơn");
        }
        if (discountAmount != null) invoice.setDiscountAmount(discountAmount);
        if (invoice.getDiscountAmount().compareTo(invoice.grossAmount()) > 0) {      // EX-14 kiểm tra lại
            throw new AppException(ErrorCode.DISCOUNT_EXCEEDS_INVOICE_AMOUNT);
        }
        return medicineInvoiceRepository.save(invoice);                               // @Version chống sửa đồng thời
    }

    /**
     * Bước 2 – Xác nhận thanh toán & xuất thuốc: PAID + trừ kho + EXPORT_SALE trong CÙNG MỘT giao dịch.
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public MedicineInvoice confirmPayment(Long invoiceId, Long cashierId) {
        MedicineInvoice invoice = medicineInvoiceRepository.findById(invoiceId)
                .orElseThrow(() -> new AppException(ErrorCode.INVOICE_NOT_FOUND));

        switch (invoice.getPaymentStatus()) {
            case PAID -> throw new AppException(ErrorCode.INVOICE_ALREADY_PAID);       // EX-16
            case CANCELLED -> throw new AppException(ErrorCode.INVOICE_ALREADY_CANCELLED);
            case PENDING -> { }
        }

        // Sắp xếp theo medicineId để mọi giao dịch khóa dòng theo cùng thứ tự -> tránh Deadlock
        List<MedicineInvoiceItem> items = invoice.getItems().stream()
                .sorted(Comparator.comparing(i -> i.getPrescriptionItem().getMedicine().getId()))
                .toList();

        for (MedicineInvoiceItem item : items) {
            Medicine med = item.getPrescriptionItem().getMedicine();
            int updated = medicineRepository.deductStockQuantity(med.getId(), item.getQuantity());
            if (updated == 0) {                                                       // EX-15: rollback toàn bộ
                throw new AppException(ErrorCode.INSUFFICIENT_STOCK,
                        "Thuốc [" + med.getName() + "] hiện không đủ tồn kho. Vui lòng giảm số lượng hoặc bỏ thuốc này khỏi hóa đơn");
            }
            inventoryRepository.save(InventoryTransaction.builder()
                    .medicineId(med.getId())
                    .transactionType(InventoryTransactionType.EXPORT_SALE)
                    .quantity(-item.getQuantity())                                    // số lượng có dấu: âm = xuất
                    .medicineInvoiceId(invoice.getId())
                    .notes("Bán theo hóa đơn " + invoice.getInvoiceCode())
                    .createdBy(cashierId)
                    .build());
        }

        invoice.setPaymentStatus(PaymentStatus.PAID);
        invoice.setPaidAt(Instant.now());
        invoice.setCashierId(cashierId);
        MedicineInvoice saved = medicineInvoiceRepository.save(invoice);
        // Hai lần bấm gần như đồng thời: lần sau bị OptimisticLockException (@Version) khi flush
        // -> rollback cả phần trừ kho của lần sau -> trả SYS_1005.

        // Sự kiện nội bộ, được gửi ra RabbitMQ SAU KHI COMMIT (xem 9.2)
        eventPublisher.publishEvent(new MedicineInvoicePaidEvent(saved.getId(),
                saved.getPrescription().getVisitId(), cashierId));
        medicineRepository.findLowStock(items.stream()
                        .map(i -> i.getPrescriptionItem().getMedicine().getId()).toList())
                .forEach(m -> eventPublisher.publishEvent(new MedicineLowStockEvent(m.getId(), m.getStockQuantity())));
        return saved;
    }
}
```

> **Entity hỗ trợ:** `MedicineInvoice` khai báo `@OneToMany(mappedBy = "medicineInvoice", cascade = ALL, orphanRemoval = true)` cho `items` và các hàm tiện ích `addItem`, `removeItem`, `findItemByPrescriptionItemId`, `grossAmount()` (tổng `quantity × unitPrice × (1 + vatRate)` của các dòng, không lưu thành cột).

> **Lưu ý:** Bước 2 không thay đổi trạng thái đợt khám. Việc khách mua thuốc là tùy chọn; ca khám đã `COMPLETED` từ khi thu đủ hóa đơn dịch vụ (8.3).

### 8.3. Mẫu chuẩn: Thu tiền hóa đơn dịch vụ & Hoàn tất ca khám (`clinical-service`)
Hóa đơn dịch vụ và đợt khám cùng CSDL nên việc thu tiền và chuyển ca sang `COMPLETED` (T10) nằm trong một giao dịch cục bộ, **không cần sự kiện từ service khác**:

```java
// ServiceInvoiceRepository
@Query("SELECT si FROM ServiceInvoice si WHERE si.id IN :ids AND si.visitServiceDetail.visit.id = :visitId")
List<ServiceInvoice> findByIdsAndVisitId(@Param("ids") List<Long> ids, @Param("visitId") Long visitId);

@Query("SELECT COUNT(si) > 0 FROM ServiceInvoice si " +
       "WHERE si.visitServiceDetail.visit.id = :visitId AND si.paymentStatus = :status")
boolean existsByVisitIdAndStatus(@Param("visitId") Long visitId, @Param("status") PaymentStatus status);

// ServiceInvoicePaymentServiceImpl
@Override
@Transactional(rollbackFor = Exception.class)
public void confirmServicePayment(Long visitId, List<Long> invoiceIds, Long cashierId) {
    PetVisit visit = petVisitRepository.findById(visitId)
            .orElseThrow(() -> new AppException(ErrorCode.VISIT_NOT_FOUND));
    if (visit.getStatus() != VisitStatus.WAITING_PAYMENT && visit.getStatus() != VisitStatus.COMPLETED) {
        throw new AppException(ErrorCode.VISIT_NOT_READY_FOR_PAYMENT);              // BR-27
    }

    // service_invoices không có cột visit_id: repository dùng JPQL JOIN qua visitServiceDetail.visit
    List<ServiceInvoice> invoices = serviceInvoiceRepository.findByIdsAndVisitId(invoiceIds, visitId);
    if (invoiceIds.isEmpty() || invoices.size() != new HashSet<>(invoiceIds).size()) {
        throw new AppException(ErrorCode.INVOICE_NOT_FOUND);                       // có id không thuộc đợt khám này
    }
    for (ServiceInvoice inv : invoices) {
        switch (inv.getPaymentStatus()) {
            case PAID -> throw new AppException(ErrorCode.INVOICE_ALREADY_PAID);
            case CANCELLED -> throw new AppException(ErrorCode.INVOICE_ALREADY_CANCELLED);
            case PENDING -> { }
        }
        inv.setPaymentStatus(PaymentStatus.PAID);
        inv.setPaidAt(Instant.now());
        inv.setCashierId(cashierId);                                                // @Version chống thu trùng
    }

    // T10: mọi hóa đơn dịch vụ của ca đều PAID hoặc CANCELLED -> COMPLETED (không xét thuốc)
    boolean allSettled = !serviceInvoiceRepository.existsByVisitIdAndStatus(visitId, PaymentStatus.PENDING);
    if (allSettled && visit.getStatus() == VisitStatus.WAITING_PAYMENT) {
        visit.setStatus(VisitStatus.COMPLETED);
        statusHistoryRepository.save(PetVisitStatusHistory.of(visitId,
                VisitStatus.WAITING_PAYMENT, VisitStatus.COMPLETED, cashierId, "Thu đủ hóa đơn dịch vụ"));
        eventPublisher.publishEvent(new VisitCompletedEvent(visitId, cashierId));
    }
    // Ca đã COMPLETED do khách bỏ về (EX-11): chỉ thu công nợ, giữ nguyên trạng thái.
}
```

---

## CHƯƠNG 9: QUY CHUẨN GIAO TIẾP LIÊN DỊCH VỤ (OPENFEIGN & RABBITMQ)

### 9.1. Giao tiếp Đồng bộ (OpenFeign)
0. **Chỉ dùng để ĐỌC:** Feign chỉ dùng cho truy vấn đọc / kiểm tra điều kiện tiên quyết, gọi tới endpoint nội bộ `/internal/**`. **Cấm** dùng Feign để ghi dữ liệu sang service khác (ví dụ check-in không gọi Feign để đổi trạng thái lịch hẹn mà phát `VisitCheckedInEvent`). Lời gọi Feign đặt ngoài `@Transactional`. Danh mục lời gọi được phép: `THIET_KE_KIEN_TRUC_MICROSERVICES.md` mục 5.1.
1. **Cấu hình Timeouts Bắt buộc:** Cấm để timeout mặc định (60s). Phải đặt rõ ràng:
   ```yaml
   spring:
     cloud:
       openfeign:
         client:
           config:
             default:
               connectTimeout: 3000   # 3 giây
               readTimeout: 5000      # 5 giây
   ```
2. **Custom ErrorDecoder Chuẩn sử dụng Spring ObjectMapper:**
   ```java
   // Không gắn @Component: bean được tạo trong CommonWebAutoConfiguration (mục 2.2)
   @RequiredArgsConstructor
   public class CustomFeignErrorDecoder implements ErrorDecoder {
       private final ObjectMapper objectMapper; // Inject ObjectMapper từ Spring (đã có JavaTimeModule)

       @Override
       public Exception decode(String methodKey, Response response) {
           try {
               if (response.body() != null) {
                   ApiResponse<?> errorResponse = objectMapper.readValue(
                           response.body().asInputStream(), ApiResponse.class);
                   // Khôi phục chính xác ErrorCode từ service con trả về
                   for (ErrorCode ec : ErrorCode.values()) {
                       if (ec.getCode().equals(errorResponse.getErrorCode())) {
                           return new AppException(ec, errorResponse.getMessage());
                       }
                   }
                   return new AppException(ErrorCode.UNCATEGORIZED_EXCEPTION, errorResponse.getMessage());
               }
           } catch (IOException e) {
               return new AppException(ErrorCode.SERVICE_UNAVAILABLE);
           }
           return new AppException(ErrorCode.SERVICE_UNAVAILABLE);
       }
   }
   ```

### 9.2. Giao tiếp Bất đồng bộ (RabbitMQ) & Bắn Event Sau Commit
> [!IMPORTANT]
> **Cơ chế Bắn Event Sau Commit (`@TransactionalEventListener`):**  
> Tuyệt đối không gọi `rabbitTemplate.convertAndSend` trực tiếp bên trong method `@Transactional`. Bắt buộc phải lắng nghe sự kiện nội bộ và chỉ gửi ra RabbitMQ khi CSDL đã Commit hoàn tất 100%:

```java
@Component
@RequiredArgsConstructor
public class ClinicalEventPublisher {

    private final RabbitTemplate rabbitTemplate;

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onVisitCompleted(VisitCompletedEvent event) {
        rabbitTemplate.convertAndSend("clinic.events", "visit.completed", event);
    }
}
```

**Cấu hình Message Converter chuẩn JSON:**
```java
@Configuration
public class RabbitConfig {
    @Bean
    public MessageConverter jsonMessageConverter(ObjectMapper objectMapper) {
        return new Jackson2JsonMessageConverter(objectMapper);
    }
}
```

**Danh mục 9 Sự kiện & Routing Keys chuẩn v3.0** (Exchange `clinic.events`; khớp 100% với `THIET_KE_KIEN_TRUC_MICROSERVICES.md` mục 5.2 – Lộ trình mã nguồn bắt buộc dùng đúng các tên này):

| Tên Event Class | Routing Key | Dịch vụ Phát (Producer) | Dịch vụ Nhận (Consumer) |
| :--- | :--- | :--- | :--- |
| `AppointmentBookedEvent` | `appointment.booked` | `appointment-service` | `notification-service` |
| `AppointmentStatusChangedEvent` | `appointment.status_changed` | `appointment-service` | `notification-service` |
| `AppointmentNoShowEvent` | `appointment.no_show` | `appointment-service` | `notification-service` |
| `VisitCheckedInEvent` | `visit.checked_in` | `clinical-service` | `appointment-service` (chuyển lịch `CHECKED_IN`), `notification-service` |
| `PatientCalledEvent` | `visit.patient_called` | `clinical-service` | `notification-service` |
| `ParaclinicalResultsReadyEvent` | `visit.results_ready` | `clinical-service` | `notification-service` |
| `VisitCompletedEvent` | `visit.completed` | `clinical-service` | `notification-service` |
| `MedicineInvoicePaidEvent` | `pharmacy.medicine_invoice_paid` | `billing-pharmacy-service` | `notification-service` |
| `MedicineLowStockEvent` | `pharmacy.low_stock` | `billing-pharmacy-service` | `notification-service` |

**Quy tắc Consumer:**
- **Idempotent:** kiểm tra trạng thái hiện tại trước khi cập nhật (ví dụ `appointment-service` chỉ chuyển `CONFIRMED → CHECKED_IN`; nhận trùng thì bỏ qua).
- **Retry & DLQ:** cấu hình retry 3 lần (backoff 1s, 2s, 4s); thất bại thì đẩy vào `<queue>.dlq` để xử lý tay, không nuốt lỗi.
- **Đã bỏ:** `VisitClosedToPaymentEvent`, `PaymentAndDispenseCompletedEvent` (ca khám hoàn tất bằng giao dịch cục bộ ở `clinical-service`), cùng các tên cũ `AppointmentCreatedEvent`, `DoctorPriorityCallbackEvent`, `LowStockEvent`.

---

## CHƯƠNG 10: QUY CHUẨN BẢO MẬT & PHÂN QUYỀN TRUY CẬP (SECURITY & RBAC)

### 10.1. Bảo vệ Toàn vẹn tại Spring Cloud Gateway
> [!CAUTION]
> **Quy tắc Phòng chống Giả mạo Quyền & Trả đúng mã lỗi:**
> 1. Kẻ xấu có thể tự thêm Header `X-User-Role: ADMIN` từ bên ngoài. Gateway **xóa toàn bộ** các Headers này trước khi giải mã JWT và gán Headers nội bộ mới.
> 2. Với route **không công khai**, nếu thiếu / sai / hết hạn token, Gateway **trả ngay `401` (SYS_1002)**, không chuyển tiếp request. Nhờ đó Axios Interceptor nhận `401` và tự gọi `/api/v1/auth/refresh`. (Nếu Gateway chuyển tiếp request không có header, service bên dưới sẽ trả `403`, Frontend không biết cần làm mới token.)
> 3. Gateway chặn mọi request tới `/internal/**` từ bên ngoài.
> 4. Claim `role` chứa mã vai trò **không có tiền tố** (`VETERINARIAN`); header `X-User-Role` chuyển nguyên giá trị đó.

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
                .headers(h -> { h.remove("X-User-Id"); h.remove("X-User-Role"); });

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
        builder.header("X-User-Id", String.valueOf(claims.get("userId")));
        builder.header("X-User-Role", claims.get("role", String.class));
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

Mỗi Microservice servlet không giải mã lại JWT, mà dùng một Filter không trạng thái đọc `X-User-Id` và `X-User-Role` do Gateway chuyển tiếp, rồi nạp vào `SecurityContextHolder`. Các lớp dưới đây nằm trong `com.vetclinic.common.web` và được nạp bằng `CommonWebAutoConfiguration` (mục 2.2), **không gắn `@Component`** (nếu gắn, Spring Boot sẽ tự đăng ký filter vào servlet container một lần nữa, khiến filter chạy hai lần).

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
import java.util.List;

public class HeaderAuthenticationFilter extends OncePerRequestFilter {

    private static final String ROLE_PREFIX = "ROLE_";

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String userId = request.getHeader("X-User-Id");
        String userRole = request.getHeader("X-User-Role");

        if (userId != null && userRole != null) {
            // Thêm tiền tố ROLE_ đúng MỘT lần (phòng thủ nếu giá trị đã có tiền tố -> tránh ROLE_ROLE_)
            String authority = userRole.startsWith(ROLE_PREFIX) ? userRole : ROLE_PREFIX + userRole;
            var authentication = new UsernamePasswordAuthenticationToken(
                    userId, null, List.of(new SimpleGrantedAuthority(authority)));
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

    public static Long getCurrentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || authentication.getPrincipal() == null) {
            throw new AppException(ErrorCode.UNAUTHORIZED);
        }
        try {
            return Long.parseLong(authentication.getPrincipal().toString());
        } catch (NumberFormatException e) {
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
| **Access Token** | **30 phút** (1,800 giây) | Ký số JWT (HMAC-SHA256), Stateless | `userId`, `username`, `role` (mã vai trò **không có tiền tố**, ví dụ `VETERINARIAN`; tiền tố `ROLE_` chỉ thêm tại `HeaderAuthenticationFilter`), `roomNumber`, `exp`, `iat` |
| **Refresh Token** | **7 ngày** (604,800 giây) | Chuỗi ngẫu nhiên (UUID v4), Stateful lưu bảng `refresh_tokens` trong `pet_clinic_auth_db` | Khóa ngẫu nhiên ánh xạ tới `userId`, có cờ `revoked` và `expiry_date` |

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
        RefreshToken token = refreshTokenRepository.findByToken(tokenStr)
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
        String newAccessToken = jwtTokenProvider.generateAccessToken(user);
        RefreshToken newRefreshToken = RefreshToken.builder()
                .user(user)
                .token(UUID.randomUUID().toString())
                .expiryDate(Instant.now().plus(7, ChronoUnit.DAYS))
                .revoked(false)
                .build();
        refreshTokenRepository.save(newRefreshToken);

        return new TokenRefreshResponse(newAccessToken, newRefreshToken.getToken(), "Bearer", 1800);
    }

    @Transactional
    public void logout(String tokenStr) {
        refreshTokenRepository.findByToken(tokenStr).ifPresent(token -> {
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

Dưới đây là một lát cắt hoàn chỉnh (Vertical Slice) cho nghiệp vụ **Bác sĩ bắt đầu khám lâm sàng Giai đoạn 1 (UC-22)** trong `clinical-service`, làm hình mẫu chuẩn mực để toàn bộ các thành viên tham chiếu và phát triển các tính năng khác:

#### 1. Request DTO (`StartExaminationRequest.java`)
Bác sĩ bấm "Bắt đầu khám" ngay khi bệnh nhân bước vào phòng, nên sinh hiệu **không bắt buộc** ở bước này (Bác sĩ có thể nhập kèm hoặc cập nhật sau). Cân nặng và thân nhiệt là điều kiện bắt buộc khi gửi chỉ định cận lâm sàng / chốt ca (lỗi `CLIN_1308`).

```java
package com.vetclinic.clinical.dto.request;

import jakarta.validation.constraints.*;
import lombok.*;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StartExaminationRequest {

    @DecimalMin(value = "0.1", message = "Cân nặng phải lớn hơn 0.1 kg")
    @DecimalMax(value = "150.0", message = "Cân nặng không hợp lý (tối đa 150 kg)")
    private BigDecimal weightAtVisit; // Bác sĩ trực tiếp cân tại phòng khám (có thể để trống ở bước này)

    @DecimalMin(value = "35.0", message = "Thân nhiệt đo được quá thấp (tối thiểu 35°C)")
    @DecimalMax(value = "43.0", message = "Thân nhiệt đo được quá cao (tối đa 43°C)")
    private BigDecimal temperature;   // Bác sĩ trực tiếp đo nhiệt độ

    @Size(max = 1000, message = "Ghi chú triệu chứng lâm sàng không được vượt quá 1000 ký tự")
    private String clinicalNotes;

    private Long examinationServiceId; // Dịch vụ khám (nhóm EXAMINATION); null = "Khám tổng quát" mặc định
}
```

#### 2. Response DTO (`PetVisitResponse.java`)
Bảng `pet_visits` v3.0 không còn `started_at`, `closed_at`, `completed_at`, `assigned_room`; các thời điểm lấy từ `pet_visit_status_histories` khi cần, số phòng lấy từ `auth-service`.

```java
package com.vetclinic.clinical.dto.response;

import com.vetclinic.clinical.constant.VisitStatus;
import lombok.*;

import java.math.BigDecimal;
import java.time.Instant;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PetVisitResponse {
    private Long id;
    private String visitCode;
    private Long petId;
    private String petName;        // Lấy từ Entity Pet nội bộ clinical-service
    private String speciesName;    // Lấy từ Entity Species nội bộ
    private Long doctorId;
    private String doctorName;     // Làm giàu qua OpenFeign gọi auth-service (ngoài transaction)
    private String roomNumber;     // users.room_number của Bác sĩ (ngoài transaction)
    private Long receptionistId;
    private boolean emergency;
    private BigDecimal weightAtVisit;
    private BigDecimal temperature;
    private String initialSymptoms;
    private String clinicalNotes;
    private VisitStatus status;
    private Instant checkedInAt;
}
```

#### 3. MapStruct Mapper (`PetVisitMapper.java`)
```java
package com.vetclinic.clinical.mapper;

import com.vetclinic.clinical.dto.request.StartExaminationRequest;
import com.vetclinic.clinical.dto.response.PetVisitResponse;
import com.vetclinic.clinical.entity.PetVisit;
import org.mapstruct.*;

@Mapper(componentModel = "spring", unmappedTargetPolicy = ReportingPolicy.WARN)
public interface PetVisitMapper {

    @Mapping(target = "petName", source = "pet.name")
    @Mapping(target = "speciesName", source = "pet.species.name")
    @Mapping(target = "doctorName", ignore = true)
    @Mapping(target = "roomNumber", ignore = true)
    PetVisitResponse toResponse(PetVisit entity);

    @BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
    @Mapping(target = "examinationServiceId", ignore = true)
    void updateExamInfo(StartExaminationRequest request, @MappingTarget PetVisit entity);
}
```

#### 4. Spring Data JPA Repository (`PetVisitRepository.java`)
```java
package com.vetclinic.clinical.repository;

import com.vetclinic.clinical.constant.VisitStatus;
import com.vetclinic.clinical.entity.PetVisit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PetVisitRepository extends JpaRepository<PetVisit, Long> {

    // T02: Bác sĩ không được có ca IN_PROGRESS khác
    boolean existsByDoctorIdAndStatusAndIdNot(Long doctorId, VisitStatus status, Long excludeVisitId);

    // T01: thú cưng không được có đợt khám chưa kết thúc
    @Query("SELECT COUNT(v) > 0 FROM PetVisit v WHERE v.pet.id = :petId AND v.status NOT IN ('COMPLETED', 'CANCELLED')")
    boolean existsOpenVisit(@Param("petId") Long petId);

    // Hàng đợi sảnh 2 tầng: cấp cứu lên đầu, sau đó FIFO theo checked_in_at (index idx_visits_queue)
    @Query("SELECT v FROM PetVisit v WHERE v.status = 'WAITING' ORDER BY v.emergency DESC, v.checkedInAt ASC")
    List<PetVisit> findWaitingQueue();
}
```

#### 5. OpenFeign Client Gọi auth-service (`UserClient.java`)
```java
package com.vetclinic.clinical.client;

import com.vetclinic.clinical.dto.response.UserSummaryResponse;
import com.vetclinic.common.dto.ApiResponse;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

@FeignClient(name = "auth-service", path = "/internal/users")   // endpoint nội bộ, chỉ đọc
public interface UserClient {

    @GetMapping("/{id}")
    ApiResponse<UserSummaryResponse> getUserById(@PathVariable("id") Long id); // fullName, role, roomNumber
}
```

#### 6. Service Implementation (`PetVisitServiceImpl.java`) – chỉ thao tác CSDL nội bộ trong giao dịch
```java
package com.vetclinic.clinical.service.impl;

import com.vetclinic.clinical.constant.*;
import com.vetclinic.clinical.dto.request.StartExaminationRequest;
import com.vetclinic.clinical.dto.response.PetVisitResponse;
import com.vetclinic.clinical.entity.*;
import com.vetclinic.clinical.mapper.PetVisitMapper;
import com.vetclinic.clinical.repository.*;
import com.vetclinic.clinical.service.PetVisitService;
import com.vetclinic.common.exception.AppException;
import com.vetclinic.common.exception.ErrorCode;
import com.vetclinic.common.util.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Objects;

@Service
@RequiredArgsConstructor
public class PetVisitServiceImpl implements PetVisitService {

    private final PetVisitRepository petVisitRepository;
    private final PetVisitStatusHistoryRepository statusHistoryRepository;
    private final ClinicServiceRepository clinicServiceRepository;           // bảng services
    private final VisitServiceDetailRepository serviceDetailRepository;
    private final VisitServiceDetailHistoryRepository serviceDetailHistoryRepository;
    private final ServiceInvoiceRepository serviceInvoiceRepository;
    private final InvoiceCodeGenerator invoiceCodeGenerator;
    private final PetVisitMapper petVisitMapper;

    /** T02 – Bác sĩ bắt đầu khám Giai đoạn 1 (UC-22). */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public PetVisitResponse startExamination(Long visitId, StartExaminationRequest request) {
        Long currentDoctorId = SecurityUtils.getCurrentUserId();

        PetVisit visit = petVisitRepository.findById(visitId)
                .orElseThrow(() -> new AppException(ErrorCode.VISIT_NOT_FOUND));

        // 1. Trạng thái nguồn phải là WAITING
        if (visit.getStatus() != VisitStatus.WAITING) {
            throw new AppException(ErrorCode.INVALID_STATUS_TRANSITION,
                    "Chỉ có thể bắt đầu khám đối với ca đang ở trạng thái Chờ khám (WAITING)");
        }
        // 2. Ca phải được Lễ tân phân công cho chính Bác sĩ này (doctor_id gán ở bước phân công, không gán ở đây)
        if (!Objects.equals(visit.getDoctorId(), currentDoctorId)) {
            throw new AppException(ErrorCode.NOT_ASSIGNED_DOCTOR);
        }
        // 3. Bác sĩ không có ca IN_PROGRESS khác
        if (petVisitRepository.existsByDoctorIdAndStatusAndIdNot(currentDoctorId, VisitStatus.IN_PROGRESS, visitId)) {
            throw new AppException(ErrorCode.DOCTOR_NOT_AVAILABLE, "Bác sĩ đang có một ca khám khác chưa kết thúc!");
        }

        // 4. Cập nhật sinh hiệu (nếu có) và chuyển trạng thái; @Version chống bấm trùng
        petVisitMapper.updateExamInfo(request, visit);
        visit.setStatus(VisitStatus.IN_PROGRESS);
        statusHistoryRepository.save(PetVisitStatusHistory.of(visit.getId(),
                VisitStatus.WAITING, VisitStatus.IN_PROGRESS, currentDoctorId,
                "Bác sĩ bắt đầu khám lâm sàng Giai đoạn 1"));          // thời điểm bắt đầu = created_at

        // 5. Phí khám là một dịch vụ: tạo chỉ định EXAMINATION (IN_PROGRESS) + 1 hóa đơn dịch vụ PENDING
        ClinicService exam = request.getExaminationServiceId() != null
                ? clinicServiceRepository.findByIdAndCategoryAndActiveTrue(request.getExaminationServiceId(), ServiceCategory.EXAMINATION)
                        .orElseThrow(() -> new AppException(ErrorCode.INVALID_INPUT_DATA))
                : clinicServiceRepository.findDefaultExamination();
        VisitServiceDetail detail = serviceDetailRepository.save(VisitServiceDetail.builder()
                .visit(visit).service(exam).quantity(1).status(ServiceDetailStatus.IN_PROGRESS).build());
        serviceDetailHistoryRepository.save(VisitServiceDetailHistory.of(detail.getId(),
                null, ServiceDetailStatus.IN_PROGRESS, "ORDERED", currentDoctorId, null));
        serviceInvoiceRepository.save(ServiceInvoice.builder()
                .invoiceCode(invoiceCodeGenerator.next("SINV"))
                .visitServiceDetail(detail)
                .unitPrice(exam.getPrice())                  // snapshot đơn giá (BR-25)
                .vatRate(exam.getVatRate())                  // snapshot thuế suất
                .discountAmount(BigDecimal.ZERO)
                .paymentStatus(PaymentStatus.PENDING)
                .build());

        return petVisitMapper.toResponse(visit);
    }
}
```

#### 7. REST Controller (`PetVisitController.java`) – làm giàu dữ liệu qua Feign **sau khi** giao dịch đã commit
```java
package com.vetclinic.clinical.controller;

import com.vetclinic.clinical.dto.request.StartExaminationRequest;
import com.vetclinic.clinical.dto.response.PetVisitResponse;
import com.vetclinic.clinical.service.PetVisitService;
import com.vetclinic.clinical.service.UserInfoEnricher;
import com.vetclinic.common.dto.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/clinical/pet-visits")
@RequiredArgsConstructor
public class PetVisitController {

    private final PetVisitService petVisitService;
    private final UserInfoEnricher userInfoEnricher;   // gọi UserClient, lỗi Feign chỉ log cảnh báo, không làm hỏng nghiệp vụ

    /** Bác sĩ bắt đầu khám lâm sàng Giai đoạn 1 (UC-22, T02) */
    @PostMapping("/{id}/start-exam")
    @PreAuthorize("hasRole('VETERINARIAN')")
    public ResponseEntity<ApiResponse<PetVisitResponse>> startExamination(
            @PathVariable("id") Long id,
            @Valid @RequestBody(required = false) StartExaminationRequest request) {

        PetVisitResponse response = petVisitService.startExamination(id,
                request != null ? request : new StartExaminationRequest());
        userInfoEnricher.fillDoctorInfo(response);   // ngoài @Transactional: doctorName, roomNumber
        return ResponseEntity.ok(ApiResponse.success("Bác sĩ đã bắt đầu khám lâm sàng", response));
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
import org.springframework.context.ApplicationEventPublisher;
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
    private final ApplicationEventPublisher eventPublisher;

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
            eventPublisher.publishEvent(new AppointmentNoShowEvent(appt.getId(), appt.getPetId()));
        }
    }
}
```

> **Phối hợp với check-in:** `VisitCheckedInEvent` có thể đến sau vài trăm mili giây. Consumer ở `appointment-service` chỉ chuyển `CONFIRMED → CHECKED_IN`; nếu lịch đã bị đánh dấu `NO_SHOW` đúng lúc đó, consumer ghi log cảnh báo để Lễ tân kiểm tra (trường hợp hiếm vì Lễ tân không check-in lịch đã quá mốc; khách đến muộn được tiếp nhận như khách vãng lai).

---

## TỔNG KẾT & CAM KẾT TUÂN THỦ

1. **Hiệu lực thi hành:** Tài liệu Phiên bản 3.0 có giá trị áp dụng ngay từ ngày bắt đầu lập trình (Sprint 1 - Tuần 9 theo Kế hoạch đồ án; khung dự án dựng từ Tuần 8).
2. **Quy tắc Code Review:** Khi tạo Pull Request (PR) trên Git, mọi thành viên bắt buộc kiểm tra đối soát chéo theo danh sách 11 Chương quy chuẩn này. Bất kỳ đoạn mã nào vi phạm (ví dụ: trừ kho không nguyên tử, bắn RabbitMQ trước commit, trả Entity trực tiếp, thiếu `@PreAuthorize`) đều bị từ chối phê duyệt (Reject PR).

---

## PHỤ LỤC: THAY ĐỔI SO VỚI PHIÊN BẢN 2.0

| Vị trí | Bản 2.0 | Bản 3.0 | Lý do |
| :--- | :--- | :--- | :--- |
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
