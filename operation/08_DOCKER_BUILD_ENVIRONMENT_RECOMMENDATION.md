# 🐳 Đánh Giá Kiến Trúc: Có Nên Sử Dụng Docker Làm Môi Trường Build (Docker Build Environment)?

Tài liệu này phân tích chi tiết ưu/nhược điểm và đưa ra **Khuyến nghị kiến trúc (Architectural Recommendation)** cho việc lựa chọn giữa **Docker-based Build Environment** và **Host-Native Build Environment** trong hệ thống **XianZhu S2B2C**.

---

## 🎯 1. Khuyên Dùng Từ Kiến Trúc Sư (Verdict)

👉 **CỰC KỲ NÊN SỬ DỤNG DOCKER LÀM MÔI TRƯỜNG BUILD!**

Đặc biệt đối với quy trình **CI/CD trên Jenkins / GitLab CI**, việc đưa toàn bộ toolchain biên dịch (JDK 21, Maven 3.9, Node.js 22, Yarn) vào **Docker Container** là **tiêu chuẩn vàng (Golden Standard)** của DevOps hiện đại.

## 📦 1.1 Script Gom Artifacts Bằng Docker (`build-artifacts-docker.sh`)

Dự án cung cấp sẵn script tự động biên dịch toàn bộ dự án **bằng Docker Container** và gom kết quả vào thư mục `operation/builds/`: 📄 **[build-artifacts-docker.sh](../build-artifacts-docker.sh)**.

### **Cú pháp thực thi:**
```bash
# Biên dịch toàn bộ Backend Java + Frontend UI bằng Docker
./build-artifacts-docker.sh all

# Chỉ biên dịch Backend Java qua Docker (maven:3.9.6-eclipse-temurin-21)
./build-artifacts-docker.sh backend

# Chỉ biên dịch Frontend UI qua Docker (node:22-alpine)
./build-artifacts-docker.sh frontend
```

---

## 📊 2. Bảng So Sánh Chi Tiết Giữa 2 Phương Án

| Tiêu chí so sánh | 🐳 Docker Build Container (Khuyên dùng) | 💻 Host-Native Build (Chạy trực tiếp trên máy) |
| :--- | :--- | :--- |
| **Tính đồng nhất (Hermetic Build)** | 🟢 **Tuyệt đối 100%:** Mọi môi trường (Local, Dev, Staging, Production Jenkins) chạy cùng 1 container image. | 🔴 **Dễ bị sai lệch (Environment Drift):** Máy Dev chạy Java 18 nhưng Jenkins Runner chạy Java 11 dễ gây lỗi ngầm. |
| **Vệ sinh máy chủ (Host Hygiene)** | 🟢 **Sạch sẽ 100%:** Không cần cài đặt JDK, Maven, Node.js lên máy chủ Jenkins hay máy tính cá nhân. | 🔴 **Gây bẩn máy (Pollution):** Phải cài và duy trì rất nhiều công cụ, dễ xung đột phiên bản giữa các dự án. |
| **Quản lý đa phiên bản (Multi-version)** | 🟢 **Siêu linh hoạt:** Dự án A dùng Java 8, dự án B dùng Java 21 chỉ cần gọi `FROM maven:3.9.6-eclipse-temurin-21`. | 🔴 **P hức tạp:** Phải cấu hình `jenv` hoặc `update-alternatives` vất vả trên CI Slave. |
| **Tốc độ biên dịch (Build Speed)** | 🟡 **Nhanh (nếu có cache):** Cần mount volume cache (`.m2` & `node_modules`). | 🟢 **Siêu nhanh (Max I/O):** Đọc ghi thẳng trên đĩa máy host. |
| **Khả năng Scale CI Runner** | 🟢 **Nhân bản dễ dàng:** Thêm 10 Jenkins Agent mới không cần cài gì ngoài Docker Engine. | 🔴 **Tốn thời gian:** Mỗi Agent mới đều phải chạy script setup lại từ đầu. |

---

## 🏗️ 3. Giải Pháp Kỹ Thuật Đề Xuất (Hybrid Multi-Stage Docker Build)

### **Giải pháp 1: Sử dụng Docker Multi-Stage Build trong Dockerfile**

Đây là cách viết Dockerfile chuẩn giúp tự động hóa từ khâu Biên dịch nguồn ➔ Đóng gói ➔ Tạo Runtime Container chỉ với 1 lệnh `docker build`.

#### ☕ **Mẫu `Dockerfile` Multi-stage cho Backend Java Microservice:**

```dockerfile
# ==========================================
# STAGE 1: Môi trường Build Java Maven
# ==========================================
FROM maven:3.9.6-eclipse-temurin-21 AS builder

WORKDIR /app

# Mount cache ~/.m2 từ máy host để tăng tốc build
COPY pom.xml .
COPY framework ./framework
COPY lilishop-sdk ./lilishop-sdk
COPY service/order-service ./service/order-service

# Biên dịch riêng order-service
RUN mvn clean package -DskipTests -pl service/order-service -am

# ==========================================
# STAGE 2: Môi trường Runtime siêu nhẹ (JRE)
# ==========================================
FROM openjdk:17-jdk-slim

WORKDIR /app

# Copy duy nhất file JAR đã build từ STAGE 1 sang STAGE 2
COPY --from=builder /app/service/order-service/target/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar", "--add-opens", "java.base/java.lang.reflect=ALL-UNNAMED"]
```

#### 🎨 **Mẫu `Dockerfile` Multi-stage cho Frontend UI (Vue -> Nginx):**

```dockerfile
# ==========================================
# STAGE 1: Môi trường Build Node.js / Yarn
# ==========================================
FROM node:22-alpine AS ui-builder

WORKDIR /app

COPY manager/package.json manager/yarn.lock ./manager/
RUN cd manager && yarn install --frozen-lockfile

COPY manager ./manager
RUN cd manager && yarn build

# ==========================================
# STAGE 2: Môi trường Runtime Nginx
# ==========================================
FROM nginx:alpine

# Copy thư mục dist đã build sang Nginx
COPY --from=ui-builder /app/manager/dist /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

---

### **Giải pháp 2: Sử dụng Docker Agent Trong Jenkins Pipeline**

Trong Jenkinsfile, bạn không cần cài JDK hay Maven lên Jenkins Slave, chỉ cần khai báo `agent`:

```groovy
pipeline {
    agent {
        docker {
            image 'maven:3.8.6-openjdk-17-slim'
            args '-v $HOME/.m2:/root/.m2' // Mount cache Maven repository để build cực nhanh
        }
    }

    stages {
        stage('Build Java Backend') {
            steps {
                sh 'mvn clean package -DskipTests -pl service/goods-service -am'
            }
        }
    }
}
```

---

## ⚡ 4. Bí Quyết Khắc Phục Nhược Điểm Tốc Độ Của Docker Build

Nhược điểm duy nhất của Docker Build là tải lại `node_modules` hoặc file `.m2` mỗi lần build. Chúng ta giải quyết triệt để bằng cách:

1. **Mount Cache Volume cho Maven:**
   `-v /var/cache/m2:/root/.m2`
2. **Mount Cache Volume cho Yarn / NPM:**
   `-v /var/cache/yarn:/root/.cache/yarn`

👉 Với cách này, tốc độ build qua Docker Container sẽ **ngang ngửa 100% với build trực tiếp trên máy host**, nhưng lại thừa hưởng toàn bộ ưu điểm nhất quán và sạch sẽ!
