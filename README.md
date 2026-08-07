# 🛒 XianZhu - Nền Tảng Thương Mại Điện Tử S2B2C / B2B2C Microservices

Dự án **XianZhu** (dựa trên hệ sinh thái Lilishop S2B2C) là nền tảng Thương mại Điện tử cấp doanh nghiệp theo kiến trúc **Microservices**. Hệ thống kết nối toàn diện chuỗi cung ứng giữa **Nhà cung cấp (Supplier)**, **Thương gia / Gian hàng (Seller)**, **Nhà quản trị sàn (Manager)** và **Khách hàng cuối (Buyer)**.

---

## 🌟 1. Tổng Quan & Mô Hình Hoạt Động

* **Mô hình S2B2C (Supplier-to-Business-to-Consumer):** Cho phép Nhà cung cấp (Supplier) đưa nguồn hàng sỉ vào hệ thống ➔ Các Thương gia (Seller) đăng bán sản phẩm tới Người tiêu dùng (Buyer) mà không cần quản lý kho bãi phức tạp.
* **Mô hình B2B2C Multi-vendor Marketplace:** Hỗ trợ mô hình sàn thương mại điện tử đa gian hàng, tích hợp phân chia doanh thu (online split bill settlement), hoa hồng và quản lý khuyến mãi linh hoạt.

---

## 🏛️ 2. Các Phân Hệ Ứng Dụng (User Portals)

Dự án bao gồm đầy đủ cổng thông tin cho từng nhóm đối tượng:

| Phân hệ | Mô tả & Chức năng |
| :--- | :--- |
| **Manager Portal** | Trang quản trị trung tâm: Duyệt sản phẩm, quản lý người dùng, cấu hình hoa hồng, đối soát tài chính & cấu hình cổng thanh toán. |
| **Seller Portal** | Cổng dành cho Thương gia: Đăng bán sản phẩm, quản lý gian hàng, quản lý đơn hàng & theo dõi doanh thu. |
| **Supplier Portal** | Cổng dành cho Nhà cung cấp: Quản lý danh mục nguồn hàng sỉ và kênh phân phối. |
| **Buyer Clients** | Giao diện Mua hàng đa nền tảng: Hỗ trợ PC Web, Mobile H5 / Mini App với tính năng tìm kiếm, giỏ hàng, đặt hàng, thanh toán trực tuyến. |
| **IM Service** | Hệ thống nhắn tin tức thời (Instant Messaging) tương tác giữa Khách hàng và Gian hàng / Chăm sóc khách hàng. |

---

## ⚙️ 3. Kiến Trúc Công Nghệ (Tech Stack)

### **Backend & Microservices**
* **Core Framework:** Java (JDK 21), Spring Boot / Spring Cloud.
* **Service Discovery & Config Center:** **Nacos 2.x** (Đăng ký dịch vụ và quản lý cấu hình tập trung).
* **Distributed Transactions:** **Seata 1.6.x** (Quản lý giao dịch phân tán giữa các dịch vụ: Đơn hàng, Kho, Thanh toán).
* **Distributed Job Scheduler:** **XXL-JOB 2.4.x** (Lập lịch tác vụ tự động: hủy đơn hết hạn, tính toán hoa hồng, thống kê báo cáo).
* **Message Broker:** **RabbitMQ 3.x** (Xử lý sự kiện bất đồng bộ & hàng đợi giao dịch).

### **Database, Search & Storage**
* **Primary Database:** **MySQL 8.0**
* **Caching & Locking:** **Redis 7.0**
* **Search Engine:** **Elasticsearch 7.17** (Tích hợp IK Analyzer phân tích từ khóa tiếng Trung / Pinyin & gợi ý tìm kiếm).
* **Object Storage:** Hỗ trợ MinIO, Aliyun OSS, Huawei OBS, Tencent COS.

### **DevOps & Triển khai**
* **Containerization & Orchestration:** Docker Compose & Kubernetes (K8s) với Ingress Controller.
* **Build Toolchain Containerized:** Docker Maven 3.9.6 (JDK 21) & Node 22 Alpine.
* **Log Management:** ELK Stack (Logstash, Elasticsearch, Kibana).

---

## 📁 4. Cấu Trúc Thư Mục Dự Án

```text
XianZhu/
├── build-artifacts-docker.sh   # 👈 Script tự động biên dịch toàn bộ Backend & UI bằng Docker
├── operation/                  # 👈 Thư mục quản lý Vận hành & Cấu hình Triển khai
│   ├── builds/                 # Thư mục xuất bản Artifacts (JARs/Dist) & Docker Compose vận hành
│   │   ├── docker-compose.yml  # Docker Compose khởi chạy cụm ứng dụng (Tối ưu cho Buyer test)
│   │   ├── nginx.conf          # Cấu hình Nginx Web Server cho UI & API Reverse Proxy
│   │   ├── check-health.sh     # Script kiểm tra trạng thái sức khỏe toàn bộ cụm dịch vụ
│   │   ├── backend/            # Thư mục chứa các file JAR đã biên dịch
│   │   └── frontend/           # Thư mục chứa static dist UI (buyer/ & seller/)
│   ├── deployment/             # Nơi chứa cấu hình Docker Compose gốc & script build đơn lẻ
│   │   ├── build-artifacts-docker.sh
│   │   ├── build-single-artifact.sh
│   │   ├── check-services-health.sh
│   │   └── settings.xml
│   ├── README.md               # Tổng quan tài liệu vận hành
│   ├── BUILD_PREREQUISITES.md  # Yêu cầu môi trường & Ma trận phiên bản (JDK 21, Maven 3.9, Node 22)
│   ├── DOCKER_BUILD_ENVIRONMENT_RECOMMENDATION.md
│   ├── ARCHITECTURE_AND_WORKFLOWS.md
│   ├── JENKINS_BUILD_GUIDE.md
│   └── LOCAL_DOCKER_COMPOSE_GUIDE.md
├── source-code/                # Mã nguồn chính (Backend S2B2B2C-Service & Frontend S2B2B2C-UI)
└── docs/                       # Bộ tài liệu hướng dẫn & API Docs (VitePress)
```

---

## 🚀 5. Hướng Dẫn Triển Khai Nhanh (Quick Start)

### **Yêu cầu môi trường tối thiểu**
* **Phần mềm:** Docker Desktop / Docker Engine >= 20.10, Docker Compose >= v2.17.
* **Môi trường Biên dịch (Không cần cài JDK/Node trên Host):** Tự động kéo container `maven:3.9.6-eclipse-temurin-21` & `node:22-alpine`.

### **Bước 0: Clone Mã Nguồn Dự Án Vào Thư Mục `source-code/`**

Trước khi build, cần clone 2 repository backend (`S2B2B2C-Service`) và frontend (`S2B2B2C-UI`) vào thư mục `source-code/`:

* **Trường hợp 1: Clone nhánh `develop` (Khuyên dùng cho Môi trường Phát triển):**
  ```bash
  cd source-code
  git clone -b develop https://git.bluesix.xyz/XianZhu/S2B2B2C-Service.git S2B2B2C-Service-develop
  git clone -b develop https://git.bluesix.xyz/XianZhu/S2B2B2C-UI.git S2B2B2C-UI-develop
  cd ..
  ```

* **Trường hợp 2: Clone nhánh `master` (Dùng cho Môi trường Production):**
  ```bash
  cd source-code
  git clone -b master https://git.bluesix.xyz/XianZhu/S2B2B2C-Service.git S2B2B2C-Service
  git clone -b master https://git.bluesix.xyz/XianZhu/S2B2B2C-UI.git S2B2B2C-UI
  cd ..
  ```

### **Bước 1: Biên dịch toàn bộ Backend & Frontend bằng Docker**

```bash
# Thực thi script gom artifacts tự động bằng Docker Container (Mặc định nhánh develop)
./build-artifacts-docker.sh all develop

# Hoặc biên dịch nhánh master
./build-artifacts-docker.sh all master
```

### **Bước 2: Khởi chạy cụm dịch vụ qua Docker Compose**

```bash
# Di chuyển vào thư mục operation/builds
cd operation/builds

# Khởi chạy toàn bộ cụm Middleware, Gateway & Buyer UI
docker compose up -d

# Kiểm tra trạng thái sức khỏe cụm container
./check-health.sh
```

### **Thông tin cổng & địa chỉ truy cập:**
* 🌐 **Buyer Web UI:** [http://localhost:8080](http://localhost:8080)
* 🛡️ **Gateway API:** [http://localhost:8888](http://localhost:8888)
* ⚙️ **Nacos Dashboard:** [http://localhost:8848/nacos](http://localhost:8848/nacos) (`nacos` / `nacos`)
* 🐬 **MySQL 8.0:** `root` / `lilishop` (Port: 3306)
* 🔴 **Redis Cache:** Password `lilishop` (Port: 6379)
* 🐇 **RabbitMQ Admin:** [http://localhost:15672](http://localhost:15672) (`admin` / `lilishop`)

---

## 📘 6. Tài Liệu Hướng Dẫn Chi Tiết

Vui lòng tham khảo thêm các tài liệu kỹ thuật chuyên sâu trong thư mục `operation/`:
* 📄 [Yêu Cầu Môi Môi Trường & Cấu Hình Bắt Buộc (BUILD_PREREQUISITES.md)](operation/BUILD_PREREQUISITES.md)
* 📄 [Tài Liệu Hướng Dẫn Triển Khai Docker Compose (operation/builds/README.md)](operation/builds/README.md)
* 📄 [Khuyến Nghị Kiến Trúc Docker Build Container](operation/DOCKER_BUILD_ENVIRONMENT_RECOMMENDATION.md)
* 📄 [Tài Liệu Quản Lý Vận Hành & CI/CD Jenkins](operation/JENKINS_BUILD_GUIDE.md)
