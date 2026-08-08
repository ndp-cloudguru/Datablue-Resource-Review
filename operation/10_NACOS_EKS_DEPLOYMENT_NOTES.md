# ☁️ NACOS DEPLOYMENT ON AMAZON EKS - PRODUCTION TAKE NOTES

Tài liệu ghi chú tổng hợp các yêu cầu kiến trúc, cấu hình K8s, checklist bảo mật và mẹo triển khai **Nacos Server & Spring Cloud Microservices** trên cụm **Amazon EKS (Elastic Kubernetes Service)**.

---

## 📌 1. Tổng Quan Kiến Trúc Nacos trên EKS

Khi chuyển từ môi trường **Docker Compose (Local/Standalone)** sang **AWS EKS (Production)**:
* ❌ **Không dùng Standalone Node:** Không chạy 1 container Nacos đơn lẻ như local dev.
* ✅ **Mô hình HA Cluster:** Triển khai Nacos Cluster bằng K8s **StatefulSet** với tối thiểu **3 Replicas** nằm ở các Availability Zones (AZs) khác nhau.
* ✅ **Database bên ngoài (External DB):** Nacos Cluster kết nối tới **AWS RDS MySQL** (Multi-AZ) để lưu trữ cấu hình bền vững, thay vì dùng H2 Database nội bộ.

```
                     ┌──────────────────────────────────────────────┐
                     │          AWS ALB Ingress Controller          │
                     └──────────────────────┬───────────────────────┘
                                            │ (HTTPS - ACM Certificate)
                                            ▼
                    ┌────────────────────────────────────────────────┐
                    │  K8s Service: nacos-ui (ClusterIP / NodePort)  │
                    └───────────────────────┬────────────────────────┘
                                            │
        ┌───────────────────────────────────┼───────────────────────────────────┐
        ▼                                   ▼                                   ▼
┌───────────────┐                   ┌───────────────┐                   ┌───────────────┐
│ Pod: nacos-0  │ ◄─ (Headless) ──► │ Pod: nacos-1  │ ◄─ (Headless) ──► │ Pod: nacos-2  │
│  (us-east-1a) │                   │  (us-east-1b) │                   │  (us-east-1c) │
└───────┬───────┘                   └───────┬───────┘                   └───────┬───────┘
        │                                   │                                   │
        └───────────────────────────────────┼───────────────────────────────────┘
                                            │ (JDBC Connection)
                                            ▼
                           ┌─────────────────────────────────┐
                           │   AWS RDS MySQL (Multi-AZ DB)   │
                           └─────────────────────────────────┘
```

---

## 📌 2. K8s Manifests Checklist cho Nacos Cluster

### A. StatefulSet & Headless Service
* **StatefulSet:** Quản lý định danh Pod cố định (`nacos-0`, `nacos-1`, `nacos-2`).
* **Headless Service (`nacos-headless`):** Cung cấp FQDN cố định cho từng Pod phục vụ bầu cử Raft/CP và đồng bộ dữ liệu gRPC giữa các node Nacos:
  - Domain dạng: `nacos-0.nacos-headless.infrastructure.svc.cluster.local:8848`
* **Cổng (Ports):**
  - `8848`: Cổng HTTP Client / OpenAPI / Dashboard.
  - `9848`: Cổng gRPC Server (Clients kết nối cấu hình & discovery).
  - `9849`: Cổng gRPC Server-to-Server (Đồng bộ nội bộ giữa các Nacos Node).

### B. Environment Variables quan trọng trong Container Nacos
```yaml
env:
  - name: MODE
    value: "cluster"
  - name: NACOS_REPLICAS
    value: "3"
  - name: NACOS_SERVER_PORT
    value: "8848"
  - name: SPRING_DATASOURCE_PLATFORM
    value: "mysql"
  - name: MYSQL_SERVICE_HOST
    value: "rds-mysql.prod.internal" # Endpoint của AWS RDS
  - name: MYSQL_SERVICE_DB_NAME
    value: "nacos_config"
  - name: MYSQL_SERVICE_USER
    value: "nacos"
  - name: MYSQL_SERVICE_PASSWORD
    valueFrom:
      secretKeyRef:
        name: nacos-secrets
        key: rds-password
  # Bật Authentication cho Nacos Production
  - name: NACOS_AUTH_ENABLE
    value: "true"
  - name: NACOS_AUTH_IDENTITY_KEY
    value: "xianzhu-nacos-key"
  - name: NACOS_AUTH_IDENTITY_VALUE
    value: "xianzhu-nacos-secret"
  - name: NACOS_AUTH_TOKEN_SECRET_KEY
    valueFrom:
      secretKeyRef:
        name: nacos-secrets
        key: auth-token-secret
```

---

## 📌 3. Thay Đổi Cấu Hình Trong Spring Boot Microservices Pods

Khi các Spring Boot Microservices (`gateway`, `auth-service`, `goods-service`...) chạy dưới dạng K8s Deployments trên EKS:

### A. Cập nhật `bootstrap.yml` hoặc K8s Environment Variables
Chuyển `nacos.server-addr` từ Docker container name (`nacos:8848`) sang K8s DNS Service Name:

```yaml
spring:
  cloud:
    nacos:
      config:
        server-addr: nacos-service.infrastructure.svc.cluster.local:8848
        namespace: ${SPRING_CLOUD_NACOS_CONFIG_NAMESPACE:production}
        group: DEFAULT_GROUP
        username: ${NACOS_USERNAME}
        password: ${NACOS_PASSWORD}
      discovery:
        server-addr: nacos-service.infrastructure.svc.cluster.local:8848
        namespace: ${SPRING_CLOUD_NACOS_DISCOVERY_NAMESPACE:production}
        ip: ${POD_IP} # Đăng ký Pod IP chính xác trong VPC CNI
```

### B. Lấy Pod IP chính xác bằng K8s Downward API
Trong file K8s Deployment Manifest của từng Microservice, truyền `POD_IP` vào container:

```yaml
spec:
  containers:
    - name: user-service
      env:
        - name: POD_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
        - name: SPRING_CLOUD_NACOS_CONFIG_NAMESPACE
          value: "production" # Hoặc "staging"
        - name: SPRING_CLOUD_NACOS_DISCOVERY_NAMESPACE
          value: "production"
```

---

## 📌 4. Quy Trình Import & Sync Config lên EKS

### A. Tạo Namespace môi trường trên Nacos EKS
Không dùng namespace `middle` (Local). Tạo các Namespace chuẩn trên Production Nacos:
- `production` (Namespace ID: `prod-xianzhu-01`)
- `staging` (Namespace ID: `staging-xianzhu-01`)

### B. Tự động hóa CI/CD Publish Config (GitOps Pipeline)
Tận dụng Script Python [`init-nacos-config.py`](file:///d:/My%20Workspace/Datablue-Resource-Review/operation/deployment/init-nacos-config.py) trong GitHub Actions / GitLab CI:

```bash
# Trong Pipeline CI/CD Deploy lên EKS
python operation/deployment/init-nacos-config.py \
  --nacos-url "http://nacos-service.infrastructure.svc.cluster.local:8848" \
  --namespace "prod-xianzhu-01" \
  --config-dir "source-code/S2B2B2C-Service-develop/docker/prod/nacos/config"
```

---

## 📌 5. Mẹo Debug & Best Practices trên AWS EKS

1. **VPC CNI Network Plugin:**
   - AWS EKS cấp trực tiếp IP trong AWS VPC cho từng Pod. Đảm bảo Security Group của EKS Node Group cho phép mở cổng `8848`, `9848`, `9849` giữa các Node.
2. **K8s Health Check (Probes):**
   - **Liveness Probe:** `httpGet` cổng `8848` đường dẫn `/nacos/v1/console/health/liveness`
   - **Readiness Probe:** `httpGet` cổng `8848` đường dẫn `/nacos/v1/console/health/readiness`
3. **PreStop Hook & Graceful Shutdown:**
   - Khi EKS thực hiện Rolling Update hoặc Auto Scaling hủy Pod Microservice, cấu hình `preStop` hook hoặc `spring.cloud.nacos.discovery.watch.delay` để Microservice tự hủy đăng ký (Deregister) trên Nacos trước khi Pod ngắt hoàn toàn. Tránh việc Gateway gửi request tới Pod đã chết.
4. **Bảo mật Nacos Dashboard trên EKS:**
   - Không mở cổng Nacos UI công khai ra Internet.
   - Chỉ cho phép truy cập qua AWS Client VPN hoặc ALB Ingress có tích hợp AWS Cognito / OIDC Authentication.
