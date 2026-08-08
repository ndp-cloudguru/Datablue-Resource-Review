# 🔄 SEATA - ARCHITECTURE, CONFIGURATION & EKS DEPLOYMENT GUIDE

Tài liệu hướng dẫn chi tiết về **Apache Seata** (Distributed Transaction Management) trong kiến trúc Microservices của hệ thống, bao gồm nguyên lý hoạt động, cấu hình Nacos, triển khai Local & EKS, cùng các bước khắc phục sự cố (Troubleshooting).

---

## 📌 1. Tổng Quan về Seata trong Hệ Thống

Trong hệ thống Microservices (`order-service`, `goods-service`, `payment-service`, `promotion-service`...), một thao tác của người dùng (ví dụ: **Đặt hàng & Thanh toán**) đụng tới nhiều database độc lập. 

Apache Seata giúp đảm bảo tính toàn vẹn dữ liệu **ACID / Distributed Transaction** (Giao dịch phân tán).

### 3 Thành Phần Cốt Lõi của Seata:
1. **TC (Transaction Coordinator - Seata Server):**
   * Quản lý trạng thái của các giao dịch toàn cục (Global Transaction).
   * Điều phối việc Commit hoặc Rollback giữa các microservices.
2. **TM (Transaction Manager):**
   * Được tích hợp trong Microservice khởi tạo giao dịch (ví dụ: `order-service` với Annotation `@GlobalTransactional`).
   * Bắt đầu (Begin), Commit hoặc Rollback Global Transaction.
3. **RM (Resource Manager):**
   * Tích hợp trong các Microservice tham gia nhánh giao dịch (ví dụ: `goods-service` trừ kho, `promotion-service` trừ coupon).
   * Quản lý tài nguyên local (Undo Log DB table) và báo cáo trạng thái nhánh (Branch Transaction) cho TC.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Transaction Coordinator                         │
│                             (Seata Server)                             │
└───────────────▲────────────────────────────────────────▲───────────────┘
                │ Register/Status                        │ Register/Status
                │                                        │
    ┌───────────┴───────────┐                ┌───────────┴───────────┐
    │   Order Service (TM)  │─── RPC/HTTP ──►│   Goods Service (RM)  │
    │  @GlobalTransactional │                │     (Stock Deduct)    │
    └───────────┬───────────┘                └───────────┬───────────┘
                │ Local DB                               │ Local DB
                ▼                                        ▼
    ┌───────────────────────┐                ┌───────────────────────┐
    │  order_db (undo_log)  │                │  goods_db (undo_log)  │
    └───────────────────────┘                └───────────────────────┘
```

---

## 📌 2. Cấu Hình Seata trên Nacos

Seata Server và các Microservices trao đổi thông tin cấu hình & service registry thông qua **Nacos**.

### A. Dynamic Config trên Nacos (`SEATA_GROUP`)
Cấu hình mapping giữa **TX Service Group** của từng Microservice tới Nacos Cluster được lưu trữ tại Nacos dưới Data ID `seataServer.properties` với `group=SEATA_GROUP`:

```properties
service.vgroupMapping.auth-service-group=default
service.vgroupMapping.broadcast-service-group=default
service.vgroupMapping.distribution-service-group=default
service.vgroupMapping.goods-service-group=default
service.vgroupMapping.im-service-group=default
service.vgroupMapping.order-service-group=default
service.vgroupMapping.payment-service-group=default
service.vgroupMapping.promotion-service-group=default
service.vgroupMapping.resource-service-group=default
service.vgroupMapping.statistics-service-group=default
service.vgroupMapping.supplier-service-group=default
service.vgroupMapping.system-service-group=default
```

### B. Cấu hình Client Microservice (`application-dev.yml` / Nacos Config)
Tất cả Microservice kết nối tới Seata Server thông qua cấu hình Spring Cloud Starter Seata:

```yaml
seata:
  enabled: true
  tx-service-group: ${spring.application.name}-group   # e.g., order-service-group
  enable-auto-data-source-proxy: true                 # Tự động proxy DataSource để ghi undo_log
  service:
    vgroup-mapping:
      ${spring.application.name}-group: default
    grouplist:
      default: 127.0.0.1:8091                          # Hoặc Seata Cluster Address
  config:
    type: nacos
    nacos:
      server-addr: ${spring.cloud.nacos.config.server-addr}
      namespace: ${spring.cloud.nacos.config.namespace}
      group: SEATA_GROUP
      data-id: seataServer.properties
  registry:
    type: nacos
    nacos:
      server-addr: ${spring.cloud.nacos.discovery.server-addr}
      namespace: ${spring.cloud.nacos.discovery.namespace}
      group: DEFAULT_GROUP
      application: seata-server
```

---

## 📌 3. Yêu Cầu Database (Table `undo_log`)

Để chế độ AT (Auto Transaction) của Seata hoạt động, **tất cả các Database của Microservice** có tham gia giao dịch phân tán phải tạo bảng `undo_log`:

```sql
CREATE TABLE IF NOT EXISTS `undo_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `branch_id` bigint(20) NOT NULL,
  `xid` varchar(100) NOT NULL,
  `context` varchar(128) NOT NULL,
  `rollback_info` longblob NOT NULL,
  `log_status` int(11) NOT NULL,
  `log_created` datetime NOT NULL,
  `log_modified` datetime NOT NULL,
  `ext` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ux_undo_log` (`branch_id`,`xid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Seata AT Mode Undo Log Table';
```

---

## 📌 4. Triển Khai Seata Server trên Amazon EKS

Khi đưa lên môi trường Production (Amazon EKS):

### A. Kiến Trúc HA Cluster
* Sử dụng K8s **Deployment / StatefulSet** với `replicas: 2` trở lên.
* **Store Mode:** Dùng DB mode (`store.mode=db`) trỏ tới **AWS RDS MySQL** chung để lưu trữ `global_table`, `branch_table`, `lock_table` thay vì lưu trong file/memory local.
* **Registration:** Seata Server tự động đăng ký tên dịch vụ `seata-server` lên Nacos Registry.

### B. Kubernetes Manifest Mẫu cho Seata Server (`seata-deployment.yaml`)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: seata-server
  namespace: infrastructure
spec:
  replicas: 2
  selector:
    matchLabels:
      app: seata-server
  template:
    metadata:
      labels:
        app: seata-server
    spec:
      containers:
        - name: seata-server
          image: apache/seata-server:1.7.1
          ports:
            - containerPort: 8091 # Service Port
            - containerPort: 7091 # HTTP / Admin Port
          env:
            - name: SEATA_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP
            - name: SEATA_PORT
              value: "8091"
            - name: STORE_MODE
              value: "db"
            - name: DB_HOST
              value: "rds-mysql.prod.internal"
            - name: DB_PORT
              value: "3306"
            - name: DB_NAME
              value: "seata"
            - name: DB_USER
              value: "seata"
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-secrets
                  key: seata-password
```

---

## 📌 5. Checklist Kiểm Thử & Troubleshooting

### Checklist Kiểm Trả Dịch Vụ:
1. **Kiểm tra Nacos Console:**
   * Trong **Service Management ➔ Service List**, đảm bảo thấy service `seata-server` có ít nhất 1 Healthy Instance.
   * Trong **Configuration Management ➔ Config List** (Group `SEATA_GROUP`), đảm bảo Data ID `seataServer.properties` đã được nạp.
2. **Kiểm tra Bảng `undo_log`:**
   * Đảm bảo các DB `lilishop_order`, `lilishop_goods`, `lilishop_promotion`, `lilishop_payment` đều chứa bảng `undo_log`.

### Lỗi Thường Gặp & Cách Xử Lý:

* ❌ **Lỗi: `no available service 'default' found, please check registry config`**
  * *Nguyên nhân:* Microservice không tìm thấy Seata TC hoặc mapping `vgroupMapping` bị sai.
  * *Khắc phục:* Kiểm tra file `seataServer.properties` trên Nacos có đúng group `${spring.application.name}-group` hay chưa.

* ❌ **Lỗi: `Could not found transaction log table undo_log`**
  * *Nguyên nhân:* Database của service chưa được khởi tạo bảng `undo_log`.
  * *Khắc phục:* Chạy script SQL tạo bảng `undo_log` cho database đó.

* ❌ **Lỗi: `Global lock acquire failed`**
  * *Nguyên nhân:* Xảy ra xung đột ghi (write lock) giữa 2 giao dịch phân tán trên cùng một record dữ liệu.
  * *Khắc phục:* Kiểm tra xem có service nào đang giữ lock quá lâu hoặc bị timeout.
