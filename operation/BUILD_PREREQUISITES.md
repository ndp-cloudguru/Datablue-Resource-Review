# 🛠️ Yêu Cầu Môi Trường & Cấu Hình Bắt Buộc Để Build Toàn Bộ Ứng Dụng

Tài liệu này liệt kê chi tiết **Yêu cầu phần cứng, Các phần mềm cần thiết, Biến môi trường, Hướng dẫn cài đặt Docker trên Mac/Linux/Windows và File cấu hình mẫu** để đảm bảo việc biên dịch (build) toàn bộ Backend Java & Frontend UI của hệ thống **XianZhu / Lilishop S2B2C** diễn ra thành công.

---

## 📋 1. Danh Mục Phần Mềm & Phiên Bản Yêu Cầu (Software Matrix)

| Công cụ / Runtime | Phiên bản Tối thiểu | Phiên bản Khuyên dùng | Mục đích sử dụng |
| :--- | :--- | :--- | :--- |
| **JDK (Java Dev Kit)** | `JDK 17` | `OpenJDK 21` / `Eclipse Temurin 21` | Biên dịch các Microservices Java Spring Boot |
| **Apache Maven** | `v3.8.0` | `v3.9.6` | Trình quản lý dependency & build module Backend Java |
| **Node.js** | `v18.0.0` | `v22 LTS` | Runtime môi trường biên dịch cho Frontend Vue.js |
| **Yarn / NPM** | `Yarn v1.22+` / `NPM v8+` | `Yarn v1.22.x` | Trình quản lý gói cho các ứng dụng Frontend UI |
| **Docker Engine** | `v20.10.0+` | `v24.0.0+` | Đóng gói ứng dụng thành Docker Image |
| **Docker Compose** | `v2.17.0+` | `v2.20.0+` | Khởi chạy cụm container Middleware & API local |
| **Git** | `v2.30.0+` | `v2.40.0+` | Trình quản lý mã nguồn |

---

## ⚙️ 2. Biến Môi Trường Bắt Buộc (Environment Variables)

Thêm các biến môi trường sau vào file cấu hình shell của bạn (`~/.bashrc`, `~/.zshrc` hoặc `/etc/profile` trên Linux):

```bash
# ------------------------------------------------------------------------------
# Cấu hình Biến Môi Trường cho XianZhu Build Environment
# ------------------------------------------------------------------------------

# 1. Java JDK 21+ Environment
export JAVA_HOME=/opt/jdk-21.0.2      # Thay đổi theo đường dẫn cài đặt JDK của bạn
export PATH=$JAVA_HOME/bin:$PATH
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar

# 2. Apache Maven Environment
export M2_HOME=/opt/apache-maven-3.9.6 # Thay đổi theo đường dẫn Maven của bạn
export PATH=$M2_HOME/bin:$PATH

# 3. JVM Options Bắt Buộc Cho JDK 21+ (Tránh lỗi Reflection Access)
export JAVA_OPTS="--add-opens java.base/java.lang.reflect=ALL-UNNAMED --add-opens java.base/java.lang=ALL-UNNAMED"
export MAVEN_OPTS="-Xms512m -Xmx2048m $JAVA_OPTS"
```

Tải lại cấu hình môi trường sau khi chỉnh sửa:
```bash
source ~/.bashrc  # Hoặc source /etc/profile
```

---

## 🌐 3. File Cấu Hình Maven Bắt Buộc (`settings.xml`)

Để Maven tải thư viện nhanh chóng và tránh bị lỗi thiếu gói trong quá trình build, cấu hình file `~/.m2/settings.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.2.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.2.0 https://maven.apache.org/xsd/settings-1.2.0.xsd">

    <servers>
        <server>
            <id>bluesix-maven</id>
            <username>${env.NEXUS_USERNAME}</username>
            <password>${env.NEXUS_PASSWORD}</password>
        </server>
        <server>
            <id>bluesix-releases</id>
            <username>${env.NEXUS_USERNAME}</username>
            <password>${env.NEXUS_PASSWORD}</password>
        </server>
        <server>
            <id>bluesix-snapshots</id>
            <username>${env.NEXUS_USERNAME}</username>
            <password>${env.NEXUS_PASSWORD}</password>
        </server>
    </servers>

    <mirrors>
        <mirror>
            <id>bluesix-maven</id>
            <name>Bluesix Nexus Maven Repository</name>
            <url>https://mvn.bluesix.xyz/repository/maven-public/</url>
            <mirrorOf>*</mirrorOf>
        </mirror>
    </mirrors>

    <profiles>
        <profile>
            <id>bluesix</id>
            <repositories>
                <repository>
                    <id>bluesix-public</id>
                    <url>https://mvn.bluesix.xyz/repository/maven-public/</url>
                    <releases><enabled>true</enabled></releases>
                    <snapshots><enabled>true</enabled></snapshots>
                </repository>
            </repositories>
        </profile>
    </profiles>

    <activeProfiles>
        <activeProfile>bluesix</activeProfile>
    </activeProfiles>
</settings>
```

### 🔐 3.1. Hướng Dẫn Tạo File `.mvn-credentials` & Dynamic Load Vào Môi Trường

Để không phải mã hóa cứng (hardcode) mật khẩu Nexus private repository vào file cấu hình hay biến môi trường hệ thống, dự án hỗ trợ tự động đọc tài khoản từ file ẩn **`.mvn-credentials`** ở thư mục gốc dự án.

#### **1. Tạo file `.mvn-credentials` tại thư mục gốc:**
Tạo file `.mvn-credentials` tại thư mục gốc dự án (`XianZhu/.mvn-credentials`) với nội dung sau:

```bash
export NEXUS_USERNAME='admin'
export NEXUS_PASSWORD='<chèn_mật_khẩu_nexus_của_bạn>'
```

#### **2. Cơ chế Tự động Load Môi trường:**
* **Khi chạy Build qua Script Docker (`build-artifacts-docker.sh` / `build-single-artifact.sh`):**
  Script sẽ tự động phát hiện và thực thi `source .mvn-credentials`, nạp 2 biến `NEXUS_USERNAME` & `NEXUS_PASSWORD` truyền trực tiếp vào Docker Container Maven.
* **Khi build thủ công trên Terminal máy Host:**
  Bạn chỉ cần chạy lệnh nạp thủ công trước khi build:
  ```bash
  source .mvn-credentials
  mvn clean install -DskipTests
  ```

> ⚠️ **Lưu ý An toàn Bảo mật:** File `.mvn-credentials` chứa thông tin đăng nhập quan trọng và đã được cấu hình trong `.gitignore` để không bao giờ bị push nhầm lên Git Repository.

---

## 🐳 4. Hướng Dẫn Cài Đặt Docker & Docker Compose (macOS, Linux, Windows)

### 🍎 4.1 Trên Hệ Điều Hành macOS

1. **Cách 1: Cài đặt qua Docker Desktop (Khuyên dùng):**
   * Tải bộ cài chính thức:
     * Cho chip **Apple Silicon (M1/M2/M3)**: [Tải Docker Desktop (ARM64)](https://desktop.docker.com/mac/main/arm64/Docker.dmg)
     * Cho chip **Intel**: [Tải Docker Desktop (AMD64)](https://desktop.docker.com/mac/main/amd64/Docker.dmg)
   * Kéo biểu tượng Docker vào thư mục `Applications`.
   * Mở Docker Desktop từ Launchpad để khởi chạy Docker Daemon.

2. **Cách 2: Cài đặt bằng Homebrew Terminal:**
   ```bash
   brew install --cask docker
   ```

3. **Kiểm tra sau khi cài:**
   ```bash
   docker --version
   docker compose version
   ```

---

### 🐧 4.2 Trên Hệ Điều Hành Linux (Ubuntu / CentOS)

#### **Trên Ubuntu / Debian:**
```bash
# 1. Cập nhật apt index và cài phụ thuộc
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# 2. Thêm GPG key của Docker
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 3. Thêm Docker Repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 4. Cài đặt Docker Engine & Docker Compose Plugin
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 5. Khởi chạy service & phân quyền user hiện tại
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```

#### **Trên CentOS / RHEL:**
```bash
# 1. Thêm repo Docker CE chính thức
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# 2. Cài đặt Docker Engine & Compose
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 3. Kích hoạt service
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```

---

### 🪟 4.3 Trên Hệ Điều Hành Windows (Windows 10 / 11)

1. **Bước 1: Bật tính năng WSL 2 (Windows Subsystem for Linux 2):**
   * Mở PowerShell bằng quyền Administrator và chạy lệnh:
     ```powershell
     wsl --install
     ```
   * Restart lại máy Windows.

2. **Bước 2: Cài đặt Docker Desktop for Windows:**
   * Tải bộ cài chính thức: [Tải Docker Desktop for Windows](https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe)
   * Chạy file `Docker Desktop Installer.exe`.
   * Đảm bảo đánh tích chọn **"Use WSL 2 instead of Hyper-V"**.
   * Bấm **Close & Restart**.

3. **Bước 3: Kiểm tra từ PowerShell / Command Prompt:**
   ```powershell
   docker --version
   docker compose version
   ```

---

## 📥 5. Hướng Dẫn Clone Mã Nguồn Vào `source-code/`

Trước khi thực thi script build, bạn cần clone mã nguồn từ Git repository vào thư mục `source-code/`:

### **Cách 1: Clone nhánh `develop` (Khuyên dùng cho Môi trường Phát triển):**
```bash
cd source-code
git clone -b develop https://git.bluesix.xyz/XianZhu/S2B2B2C-Service.git S2B2B2C-Service-develop
git clone -b develop https://git.bluesix.xyz/XianZhu/S2B2B2C-UI.git S2B2B2C-UI-develop
cd ..
```

### **Cách 2: Clone nhánh `master` (Dùng cho Môi trường Production):**
```bash
cd source-code
git clone -b master https://git.bluesix.xyz/XianZhu/S2B2B2C-Service.git S2B2B2C-Service
git clone -b master https://git.bluesix.xyz/XianZhu/S2B2B2C-UI.git S2B2B2C-UI
cd ..
```

---

## 🚀 6. Script Biên Dịch Toàn Bộ Dự Án Qua Docker (`build-artifacts-docker.sh`)

Dự án sử dụng **100% môi trường build Docker Container** (không cần cài JDK, Maven hay Node.js trên máy host): 📄 **[build-artifacts-docker.sh](../build-artifacts-docker.sh)**.

### **Cú pháp thực thi:**
```bash
# Biên dịch toàn bộ Backend Java + Frontend UI bằng Docker (Mặc định nhánh develop)
./build-artifacts-docker.sh all develop

# Hoặc biên dịch nhánh master
./build-artifacts-docker.sh all master

# Chỉ biên dịch Backend Java Microservices bằng Docker
./build-artifacts-docker.sh backend develop

# Chỉ biên dịch Frontend UI Modules bằng Docker
./build-artifacts-docker.sh frontend develop
```

**Tính năng tự động:**
1. Tự động kéo và chạy container `maven:3.9.6-eclipse-temurin-21` và `node:22-alpine`.
2. Tự động load tài khoản Nexus từ file `.mvn-credenntials` nếu có.
3. Tự động mount cache volume (`~/.m2` & `~/.cache/yarn`) giúp tăng tốc độ biên dịch.
4. Gom toàn bộ file `.jar` và thư mục `dist/` vào `operation/builds/`.
