# ⚙️ XianZhu S2B2C - Tài Liệu Vận Hành & Kiến Trúc Triển Khai (Operation Index)

Tài liệu này tổng hợp toàn bộ cấu trúc hệ thống vận hành, ma trận môi trường, hướng dẫn biên dịch containerized và sơ đồ kết nối Microservices của dự án **XianZhu S2B2C** (hệ sinh thái Lilishop S2B2C).

---

## 📚 1. Danh Mục Tài Liệu Vận Hành Trong `operation/`

Mọi tài liệu kỹ thuật chuyên sâu và kịch bản triển khai được lưu trữ tại thư mục `operation/`:

* 📄 **[Tài Liệu Hướng Dẫn Docker Compose (builds/README.md)](builds/README.md)**: Hướng dẫn chi tiết khởi chạy cụm ứng dụng đã biên dịch, bảng thông số Cổng (Port), giới hạn RAM và script `check-health.sh`.
* 📄 **[Yêu Cầu Môi Trường & Cấu Hình Bắt Buộc (BUILD_PREREQUISITES.md)](BUILD_PREREQUISITES.md)**: Danh mục công cụ (JDK 21, Maven 3.9, Node 22, Docker), cấu hình file `.mvn-credentials` nạp tài khoản Nexus và biến môi trường.
* 📄 **[Khuyến Nghị Sử Dụng Docker Làm Môi Môi Trường Build (DOCKER_BUILD_ENVIRONMENT_RECOMMENDATION.md)](DOCKER_BUILD_ENVIRONMENT_RECOMMENDATION.md)**: Phân tích ưu điểm của Docker Build Container, mẫu `Dockerfile Multi-stage` chuẩn và giải pháp mount cache volume.
* 📄 **[Hướng Dẫn CI/CD & Build Đơn Lẻ (JENKINS_BUILD_GUIDE.md)](JENKINS_BUILD_GUIDE.md)**: Hướng dẫn cơ chế build từng Microservice độc lập (`-pl -am`) và mẫu file `Jenkinsfile` chuẩn CI/CD.
* 📄 **[Sơ Đồ Kết Nối Services & Phân Tích Luồng Nghiệp Vụ (ARCHITECTURE_AND_WORKFLOWS.md)](ARCHITECTURE_AND_WORKFLOWS.md)**: Sơ đồ Mermaid kết nối giữa Gateway, Microservices API, Middleware và phân tích 3 luồng công việc cốt lõi (S2B2C, Đặt hàng Seata 2PC, Phân chia doanh thu).
* 📄 **[Hướng Dẫn Triển Khai Local Docker Compose (LOCAL_DOCKER_COMPOSE_GUIDE.md)](LOCAL_DOCKER_COMPOSE_GUIDE.md)**: Hướng dẫn chi tiết review cấu trúc mã nguồn Backend/Frontend và khởi chạy cục bộ.

---

## ⚙️ 2. Ma Trận Phiên Bản & Môi Trường Biên Dịch (Software Matrix)

Toàn bộ quy trình biên dịch dự án đã được đóng gói **100% bằng Docker Container** (Không yêu cầu cài JDK hay Node.js lên máy tính host):

| Công cụ / Runtime | Phiên bản Tối thiểu | Môi trường Containerized | Mục đích sử dụng |
| :--- | :--- | :--- | :--- |
| **JDK (Java Dev Kit)** | `JDK 21` | `maven:3.9.6-eclipse-temurin-21` | Biên dịch 15 Microservices Java Spring Boot |
| **Apache Maven** | `v3.9.6` | Integrated in Docker Maven | Trình quản lý dependency & build module Backend Java |
| **Node.js** | `v22 LTS` | `node:22-alpine` | Runtime biên dịch cho Frontend Vue.js Modules |
| **Yarn / NPM** | `Yarn v1.22+` | Integrated in Node 22 Alpine | Trình quản lý gói cho các ứng dụng Frontend UI |
| **Docker Engine** | `v20.10.0+` | Host Native Docker Engine | Đóng gói ứng dụng & khởi chạy cụm container |

---

## 🔐 3. Cấu Hình Tài Khoản Nexus Private Repository (`.mvn-credentials`)

Dự án hỗ trợ nạp tự động thông tin đăng nhập Nexus Repository từ file ẩn **`.mvn-credentials`** tại thư mục gốc dự án:

1. **Tạo file `.mvn-credentials` tại gốc dự án (`XianZhu/.mvn-credentials`):**
   ```bash
   export NEXUS_USERNAME='admin'
   export NEXUS_PASSWORD='<chèn_mật_khẩu_nexus_của_bạn>'
   ```
2. **Cơ chế tự động:** Các script build (`build-artifacts-docker.sh`) sẽ tự động nạp hai biến này và truyền trực tiếp vào Container Docker Maven khi biên dịch. File này đã được thêm vào `.gitignore` để bảo mật.

---

## 📡 4. Cấu Hình Nacos & Luồng Kết Nối Giữa Các Service

Nacos Server (`nacos:8848`) đóng vai trò là **Service Registry & Config Center** trung tâm:

1. **Tự động đăng ký dịch vụ (Service Discovery):**
   - Các Microservice khi khởi tạo sẽ tự động đăng ký tên Service (`spring.application.name`), IP & Port lên Nacos Naming Service.
2. **Định tuyến Gateway (`gateway` - Port 8888):**
   - Gateway giao tiếp với Nacos để điều hướng các request HTTP từ Web UI đến đúng Service xử lý backend qua cú pháp `lb://<service-name>`.
3. **Giao tiếp nội bộ Service-to-Service (OpenFeign):**
   - Các Microservices gọi API lẫn nhau thông qua **Spring Cloud OpenFeign** kết hợp Nacos (Ví dụ: `Order Service` gọi `Goods Service` qua `@FeignClient(name = "goods-service")`).

---

## 📁 5. Cấu Trúc Thư Mục Vận Hành (`operation/`)

```text
operation/
├── builds/                             # 👈 Thư mục chứa Artifacts xuất bản & Docker Compose vận hành chính
│   ├── docker-compose.yml              # File Docker Compose khởi chạy cụm ứng dụng (Tối ưu cho Buyer test)
│   ├── nginx.conf                      # Cấu hình Nginx Web Server & Reverse Proxy (Port 8080)
│   ├── check-health.sh                 # Script kiểm tra trạng thái sức khỏe toàn bộ cụm dịch vụ
│   ├── metadata.json                   # File thống kê phiên bản & thông tin bản build
│   ├── backend/                        # Nơi chứa các file JAR đã được build (.gitkeep)
│   └── frontend/                       # Nơi chứa static dist UI đã được build (.gitkeep)
├── deployment/                         # 👈 Thư mục chứa các script hỗ trợ & Dockerfiles gốc
│   ├── build-artifacts-docker.sh       # Script biên dịch gom artifacts qua Docker
│   ├── build-single-artifact.sh        # Script biên dịch tương tác đơn lẻ theo Menu
│   ├── check-services-health.sh        # Script kiểm tra sức khỏe hạ tầng gốc
│   └── settings.xml                    # File cấu hình Nexus Repository cho Maven
├── README.md                           # File này (Tổng quan tài liệu vận hành)
├── BUILD_PREREQUISITES.md              # Yêu cầu môi trường & Cấu hình nạp tài khoản Nexus
├── DOCKER_BUILD_ENVIRONMENT_RECOMMENDATION.md # Khuyến nghị kiến trúc Docker Containerized Build
├── ARCHITECTURE_AND_WORKFLOWS.md       # Sơ đồ kết nối Microservices & Luồng nghiệp vụ
├── JENKINS_BUILD_GUIDE.md              # Hướng dẫn build Jenkins CI/CD
└── LOCAL_DOCKER_COMPOSE_GUIDE.md       # Hướng dẫn review mã nguồn & chạy Local Docker
```

---

## 🚀 6. Quy Trình 4 Bước Biên Dịch & Khởi Chạy Nhanh

### **Bước 0: Clone Mã Nguồn Vào Thư Mục `source-code/`**
```bash
# Clone nhánh develop (Mặc định):
cd source-code
git clone -b develop https://git.bluesix.xyz/XianZhu/S2B2B2C-Service.git S2B2B2C-Service-develop
git clone -b develop https://git.bluesix.xyz/XianZhu/S2B2B2C-UI.git S2B2B2C-UI-develop
cd ..

# Hoặc clone nhánh master:
cd source-code
git clone -b master https://git.bluesix.xyz/XianZhu/S2B2B2C-Service.git S2B2B2C-Service
git clone -b master https://git.bluesix.xyz/XianZhu/S2B2B2C-UI.git S2B2B2C-UI
cd ..
```

### **Bước 1: Biên dịch toàn bộ Backend & Frontend bằng Docker**
Thực thi script tại thư mục gốc dự án để tự động biên dịch và gom tất cả file JAR & UI dist vào `operation/builds/`:
```bash
# Biên dịch nhánh develop (Mặc định)
./build-artifacts-docker.sh all develop

# Hoặc biên dịch nhánh master
./build-artifacts-docker.sh all master
```

### **Bước 2: Khởi chạy cụm dịch vụ bằng Docker Compose**
```bash
cd operation/builds
docker compose up -d
```

### **Bước 3: Kiểm tra trạng thái sức khỏe dịch vụ**
```bash
./check-health.sh
```

---

## 🌐 7. Danh Sách Địa Chỉ Truy Cập Mặc Định

* 🌐 **Buyer Web UI:** [http://localhost:8080](http://localhost:8080)
* 🛡️ **Gateway API Service:** [http://localhost:8888](http://localhost:8888)
* ⚙️ **Nacos Admin Dashboard:** [http://localhost:8848/nacos](http://localhost:8848/nacos) (`nacos` / `nacos`)
* 🐬 **MySQL Database:** Port `3306` (`root` / `lilishop`)
* 🔴 **Redis Cache:** Port `6379` (Password: `lilishop`)
* 🐇 **RabbitMQ Management:** [http://localhost:15672](http://localhost:15672) (`admin` / `lilishop`)
