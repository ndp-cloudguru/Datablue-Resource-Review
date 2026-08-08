# ⚙️ XianZhu S2B2C - CHỈ MỤC TÀI LIỆU VẬN HÀNH (OPERATION INDEX)

Chào mừng bạn đến với hệ thống tài liệu vận hành và kiến trúc của **XianZhu S2B2C** (dựa trên nền tảng Lilishop S2B2C Microservices). 

Để giúp bạn tiếp cận dự án một cách dễ dàng và theo đúng thứ tự logic từ **Tổng quan -> Cấu hình -> Vận hành -> Chuyên sâu**, các tài liệu trong thư mục `operation/` đã được **đánh số thứ tự tiêu chuẩn** dưới đây.

---

## 📌 LỘ TRÌNH ĐỌC TÀI LIỆU THEO THỨ TỰ (RECOMMENDED READING ORDER)

| Thứ tự | Tên File Tài Liệu | Nội dung chính |
| :---: | :--- | :--- |
| **00** | 📄 **[README.md](README.md)** | **Trang chỉ mục tổng quan** (File hiện tại) - Ma trận công cụ, cấu hình Nexus credentials. |
| **01** | 📄 **[01_BUILD_PREREQUISITES.md](01_BUILD_PREREQUISITES.md)** | **Yêu cầu môi trường & Cấu hình nạp credentials**: JDK 21, Maven 3.9, Node 22, Docker, file `.mvn-credentials`. |
| **02** | 📄 **[02_LOCAL_DOCKER_COMPOSE_GUIDE.md](02_LOCAL_DOCKER_COMPOSE_GUIDE.md)** | **Hướng dẫn chạy Local Docker**: Các bước biên dịch và khởi chạy 3 tầng Middleware - Backend - Frontend bằng Docker Compose. |
| **03** | 📄 **[03_TESTING_GUIDE.md](03_TESTING_GUIDE.md)** | **Hướng dẫn Kiểm thử Hệ thống (Testing Guide)**: Các kịch bản test trên Buyer UI, Seller UI, Manager UI và tài khoản test mặc định (`15200000000`/`123456`). |
| **04** | 📄 **[04_ARCHITECTURE_AND_WORKFLOWS.md](04_ARCHITECTURE_AND_WORKFLOWS.md)** | **Kiến trúc & Luồng nghiệp vụ**: Sơ đồ Mermaid kết nối Gateway, OpenFeign, Nacos, Seata 2PC, luồng đặt hàng & phân chia doanh thu. |
| **05** | 📄 **[05_NACOS_GUIDE.md](05_NACOS_GUIDE.md)** | **Hướng dẫn Cấu hình Nacos**: Quản lý Namespace `middle`, nạp file cấu hình YML & Seata, script kiểm tra `check-nacos-config.sh`. |
| **06** | 📄 **[06_SEATA_GUIDE.md](06_SEATA_GUIDE.md)** | **Hướng dẫn Giao dịch Phân tán Seata**: Mô hình AT Mode (TC, TM, RM), cấu hình `seataServer.properties`, bảng `undo_log` và troubleshooting. |
| **07** | 📄 **[07_FRONTEND_TAKENOTE.md](07_FRONTEND_TAKENOTE.md)** | **Ghi chú Patch & Build Frontend**: Các tùy chỉnh tắt CDN, cấu hình `publicPath`, truyền tham số `API_DEV` và đóng gói 5 ứng dụng Vue. |
| **08** | 📄 **[08_DOCKER_BUILD_ENVIRONMENT_RECOMMENDATION.md](08_DOCKER_BUILD_ENVIRONMENT_RECOMMENDATION.md)** | **Khuyến nghị Containerized Build**: Kiến trúc build bằng Docker Container (Multi-stage), tối ưu RAM & mount Maven/Yarn cache. |
| **09** | 📄 **[09_JENKINS_BUILD_GUIDE.md](09_JENKINS_BUILD_GUIDE.md)** | **Hướng dẫn CI/CD Jenkins**: Cấu hình pipeline biên dịch từng Microservice đơn lẻ (`-pl -am`) cho môi trường tự động hóa. |
| **10** | 📄 **[10_NACOS_EKS_DEPLOYMENT_NOTES.md](10_NACOS_EKS_DEPLOYMENT_NOTES.md)** | **Ghi chú Triển khai Amazon EKS (AWS Production)**: Cấu hình Nacos Cluster 3 Replicas StatefulSet, AWS RDS MySQL, Ingress & K8s Manifests. |

---

## ⚙️ Ma Trận Phiên Bản & Môi Trường Biên Dịch (Software Matrix)

Toàn bộ quy trình biên dịch dự án được đóng gói **100% bằng Docker Container** (Không yêu cầu cài JDK hay Node.js thủ công lên máy host):

| Công cụ / Runtime | Phiên bản | Môi trường Containerized | Mục đích sử dụng |
| :--- | :--- | :--- | :--- |
| **JDK (Java Dev Kit)** | `JDK 21` | `maven:3.9.6-eclipse-temurin-21` | Biên dịch 15 Microservices Java Spring Boot |
| **Apache Maven** | `v3.9.6` | Integrated in Docker Maven | Trình quản lý dependency & build module Backend Java |
| **Node.js** | `v22 LTS` | `node:22-alpine` | Runtime biên dịch cho Frontend Vue.js Modules |
| **Yarn / NPM** | `Yarn v1.22+` | Integrated in Node 22 Alpine | Trình quản lý gói cho các ứng dụng Frontend UI |
| **Docker Engine** | `v20.10.0+` | Host Native Docker Engine | Đóng gói ứng dụng & khởi chạy cụm container |

---

## 📁 Cấu Trúc Thư Mục Vận Hành (`operation/`)

```text
operation/
├── README.md                                    # 👈 00. Trang chỉ mục tổng quan (File này)
├── 01_BUILD_PREREQUISITES.md                    # 👈 01. Yêu cầu môi trường & Nexus Credentials
├── 02_LOCAL_DOCKER_COMPOSE_GUIDE.md             # 👈 02. Hướng dẫn khởi chạy Docker Compose Local
├── 03_TESTING_GUIDE.md                          # 👈 03. Hướng dẫn kịch bản kiểm thử & tài khoản test
├── 04_ARCHITECTURE_AND_WORKFLOWS.md            # 👈 04. Sơ đồ kết nối Microservices & Luồng nghiệp vụ
├── 05_NACOS_GUIDE.md                            # 👈 05. Hướng dẫn quản lý & kiểm tra Nacos Config
├── 06_SEATA_GUIDE.md                            # 👈 06. Hướng dẫn Giao dịch Phân tán Apache Seata
├── 07_FRONTEND_TAKENOTE.md                      # 👈 07. Ghi chú chỉnh sửa & biên dịch 5 Vue UI Apps
├── 08_DOCKER_BUILD_ENVIRONMENT_RECOMMENDATION.md# 👈 08. Khuyến nghị Docker Containerized Build
├── 09_JENKINS_BUILD_GUIDE.md                    # 👈 09. Hướng dẫn cấu hình Jenkins CI/CD Pipeline
├── 10_NACOS_EKS_DEPLOYMENT_NOTES.md             # 👈 10. Ghi chú triển khai Nacos Cluster lên AWS EKS
├── builds/                                      # 👈 Thư mục chứa Docker Compose vận hành chính
│   ├── docker-compose-middleware.yml            # Docker Compose riêng cho Hạ tầng Trung trạm (MySQL, Redis, Nacos, ES...)
│   ├── docker-compose-backend.yml               # Docker Compose riêng cho 15 Backend Microservices
│   ├── docker-compose-frontend.yml              # Docker Compose riêng cho 5 Frontend Vue UI Apps + Single Nginx Gateway
│   ├── README.md                                # Hướng dẫn vận hành Docker Compose chi tiết
│   ├── backend/                                 # Chứa các file JAR đã được build (.gitkeep)
│   └── frontend/                                # Chứa static dist 5 Vue Apps & Nginx config (.gitkeep)
└── scripts/                                     # 👈 Thư mục chứa các script hỗ trợ vận hành bằng Bash
    ├── build-artifacts-docker.sh                # Script biên dịch toàn bộ artifacts qua Docker
    ├── build-single-artifact.sh                 # Script biên dịch tương tác đơn lẻ theo Menu
    ├── init-nacos-config.sh                     # Script Bash tự động nạp cấu hình lên Nacos
    ├── import-mysql-init.sh                     # Script Bash tự động nạp 20 SQL init vào MySQL
    ├── check-nacos-config.sh                    # Script Bash kiểm tra sự tồn tại của Nacos Config
    ├── check-services-health.sh                 # Script Bash kiểm tra trạng thái cụm Docker Services
    └── settings.xml                             # File cấu hình Maven Nexus Repository
```
