# 📐 Sơ Đồ Kết Nối Các Services & Phân Tích Luồng Nghiệp Vụ (Workflows)

Tài liệu này cung cấp **Sơ đồ kết nối tổng thể (Connection Diagram)** giữa các Client, Gateway, Microservices và Hạ tầng Middleware, cùng với **Phân tích các Luồng nghiệp vụ chính (Core Workflows)** và **Bảng giải thích quy trình chi tiết** trong hệ thống **Lilishop / XianZhu S2B2C**.

---

## 🗺️ 1. Sơ Đồ Kết Nối Tổng Thể Các Services (System Connection Diagram)

```mermaid
flowchart TD
    %% =========================================================================
    %% LAYER 1: CLIENT LAYER (GIAO DIỆN NGƯỜI DÙNG)
    %% =========================================================================
    subgraph L1["CLIENT LAYER (Frontend Web Apps)"]
        BuyerUI["Buyer UI (Port 10000 / 8080)"]
        SellerUI["Seller UI (Port 10002)"]
        ManagerUI["Manager UI (Port 10003)"]
        SupplierUI["Supplier UI (Port 10004)"]
        IMUI["IM Chat UI (Port 8000)"]
    end

    %% =========================================================================
    %% LAYER 2: INGRESS & REVERSE PROXY LAYER
    %% =========================================================================
    subgraph L2["INGRESS & GATEWAY PROXY LAYER"]
        NginxGateway["Single Nginx Gateway / Reverse Proxy (Port 8080 - Path Routing)"]
    end

    %% =========================================================================
    %% LAYER 3: API GATEWAY LAYER
    %% =========================================================================
    subgraph L3["API GATEWAY & ROUTING LAYER"]
        SpringGateway["Spring Cloud Gateway (Port 8888 - Authentication & Load Balancing)"]
    end

    %% =========================================================================
    %% LAYER 4: MICROSERVICES BUSINESS LAYER
    %% =========================================================================
    subgraph L4["BACKEND MICROSERVICES LAYER (Spring Cloud)"]
        AuthSvc["auth-service (OAuth2 & JWT)"]
        UserSvc["user-service (Member & Wallet)"]
        GoodsSvc["goods-service (Catalog & Stock)"]
        OrderSvc["order-service (Cart & Checkout)"]
        PaymentSvc["payment-service (Pay & Refund)"]
        PromoSvc["promotion-service (Coupon & Discount)"]
        SupplierSvc["supplier-service (S2B Supplier)"]
        SystemSvc["system-service (Setting & Menu)"]
        IMSvc["im-service (WebSocket Port 11130)"]
        ConsumerSvc["consumer-service (RabbitMQ Worker)"]
    end

    %% =========================================================================
    %% LAYER 5: SERVICE GOVERNANCE & MIDDLEWARE LAYER
    %% =========================================================================
    subgraph L5["GOVERNANCE & EVENT BROKER LAYER"]
        Nacos["Nacos Server 2.2 (Config & Discovery)"]
        Seata["Seata Server 1.5 (Distributed 2PC TX)"]
        RabbitMQ["RabbitMQ 3.12 (Event Queue / Async)"]
    end

    %% =========================================================================
    %% LAYER 6: DATA PERSISTENCE & CACHE LAYER
    %% =========================================================================
    subgraph L6["DATA PERSISTENCE & STORAGE LAYER"]
        MySQL[("MySQL 8.0 (RDBMS Master DB)")]
        Redis[("Redis 7.0 (Session & Cache)")]
        Elasticsearch[("Elasticsearch 7.17 (Search Engine)")]
    end

    %% =========================================================================
    %% STRICT LAYER TO LAYER CONNECTIONS
    %% =========================================================================

    %% Layer 1 -> Layer 2
    BuyerUI -->|HTTP / Path /| NginxGateway
    SellerUI -->|HTTP / Path /seller| NginxGateway
    ManagerUI -->|HTTP / Path /manager| NginxGateway
    SupplierUI -->|HTTP / Path /supplier-platform| NginxGateway
    IMUI -->|HTTP / Path /im| NginxGateway

    %% Layer 2 -> Layer 3
    NginxGateway -->|Reverse Proxy /api/*| SpringGateway

    %% Layer 3 -> Layer 4
    SpringGateway -->|lb://auth-service| AuthSvc
    SpringGateway -->|lb://user-service| UserSvc
    SpringGateway -->|lb://goods-service| GoodsSvc
    SpringGateway -->|lb://order-service| OrderSvc
    SpringGateway -->|lb://payment-service| PaymentSvc
    SpringGateway -->|lb://promotion-service| PromoSvc
    SpringGateway -->|lb://supplier-service| SupplierSvc
    SpringGateway -->|lb://system-service| SystemSvc
    SpringGateway -->|WS /im/*| IMSvc

    %% Layer 4 -> Layer 5
    L4 -.->|Register & Config| Nacos
    OrderSvc -.->|Global TX| Seata
    GoodsSvc -.->|Branch TX| Seata
    OrderSvc -->|Publish Event| RabbitMQ
    PaymentSvc -->|Publish Event| RabbitMQ
    RabbitMQ -->|Consume Event| ConsumerSvc

    %% Layer 4 -> Layer 6
    L4 ===>|CRUD SQL| MySQL
    L4 ===>|Cache / Lock| Redis
    GoodsSvc ==>|Sync Index| Elasticsearch
    ConsumerSvc ==>|Async Index| Elasticsearch

    %% =========================================================================
    %% STYLING FOR VISUAL EXCELLENCE
    %% =========================================================================
    classDef l1Style fill:#E3F2FD,stroke:#1565C0,stroke-width:2px,color:#0D47A1;
    classDef l2Style fill:#FFF3E0,stroke:#EF6C00,stroke-width:2px,color:#E65100;
    classDef l3Style fill:#FCE4EC,stroke:#C2185B,stroke-width:2px,color:#880E4F;
    classDef l4Style fill:#E8F5E9,stroke:#2E7D32,stroke-width:2px,color:#1B5E20;
    classDef l5Style fill:#F3E5F5,stroke:#7B1FA2,stroke-width:2px,color:#4A148C;
    classDef l6Style fill:#E0F7FA,stroke:#00796B,stroke-width:2px,color:#004D40;

    class L1 l1Style;
    class L2 l2Style;
    class L3 l3Style;
    class L4 l4Style;
    class L5 l5Style;
    class L6 l6Style;
```

---

## 🔄 2. Phân Tích Chi Tiết 3 Luồng Nghiệp Vụ (Workflows & Tables)

---

### 🔄 Workflow 1: Luồng S2B2C Nguồn Hàng (Supplier ➔ Seller ➔ Buyer)

```mermaid
sequenceDiagram
    autonumber
    actor Supplier as 🚚 Nha cung cap (Supplier)
    actor Admin as 🖥️ Quan tri san (Admin)
    actor Seller as 🏪 Thuong gia (Seller)
    actor Buyer as 🛍️ Khach hang (Buyer)

    Supplier->>supplier-api: 1. Dang ky thong tin va Dang kho nguon hang
    Admin->>manager-api: 2. Kiem duyet nha cung cap va danh muc hang si
    Seller->>seller-api: 3. Duyet danh muc si -> Chon san pham lien ket vao gian hang
    Seller->>seller-api: 4. Cau hinh gia ban le va Chuong trinh khuyen mai
    seller-api->>goods-api: 5. Niem yet san pham len San ban le
    Buyer->>goods-api: 6. Tim kiem san pham va Xem chi tiet gian hang
    Buyer->>order-api: 7. Dat hang le va Thanh toan don hang
    order-api->>supplier-api: 8. Tu dong tach don si tro ve Kho Nha cung cap
    Supplier->>supplier-api: 9. Xac nhan kho va Dong goi giao hang cho van chuyen
    Buyer->>order-api: 10. Nhan hang thanh cong - Don hoan tat
```

#### 📋 Bảng Giải Thích Chi Tiết Luồng S2B2C Nguồn Hàng

| STT | Thành Phần Thực Hiện | Hành Động / Tác Vụ Chi Tiết | Microservice / Database | Mục Đích & Kết Quả |
| :---: | :--- | :--- | :--- | :--- |
| **1** | **Nhà cung cấp (Supplier)** | Đăng ký tài khoản doanh nghiệp, tải hồ sơ năng lực và khai báo sản phẩm sỉ (Wholesale SKU). | `supplier-api`<br>`supplier-db` | Lưu hồ sơ kho hàng sỉ vào hệ thống. |
| **2** | **Quản trị sàn (Admin)** | Kiểm tra tính pháp lý của Supplier và duyệt danh mục mặt hàng sỉ. | `manager-api`<br>`system-api` | Kích hoạt trạng thái nguồn hàng sỉ sẵn sàng phân phối. |
| **3** | **Thương gia (Seller)** | Lướt danh mục chợ sỉ S2B, bấm chọn các sản phẩm muốn đưa vào Cửa hàng bán lẻ của mình. | `seller-api`<br>`goods-api` | Thiết lập liên kết phân phối mà không cần nhập kho thực tế. |
| **4** | **Thương gia (Seller)** | Định giá bán lẻ (Retail Price), thiết lập quy tắc lợi nhuận và chương trình KM riêng. | `seller-api`<br>`promotion-api` | Xác định biên lợi nhuận: $\text{Lợi Nhuận} = \text{Giá Lẻ} - \text{Giá Sỉ}$. |
| **5** | **Hệ Thống (Seller System)** | Niêm yết sản phẩm lên Sàn bán lẻ công khai và đồng bộ chỉ mục tìm kiếm. | `goods-api`<br>`Elasticsearch` | Khách hàng có thể tìm kiếm sản phẩm trên web/app. |
| **6** | **Khách hàng (Buyer)** | Tìm kiếm từ khóa, xem thông tin gian hàng và thêm sản phẩm vào giỏ hàng. | `goods-api`<br>`buyer-ui` | Khởi tạo quy trình mua sắm của người dùng cuối. |
| **7** | **Khách hàng (Buyer)** | Đặt hàng lẻ và thực hiện thanh toán trực tuyến. | `order-api`<br>`payment-api` | Đơn hàng tạo thành công trạng thái *Đã Thanh Toán*. |
| **8** | **Hệ Thống (Order System)** | Tự động phân tích SKU trong đơn hàng và **tách đơn sỉ trỏ thẳng về kho của Supplier**. | `order-api`<br>`supplier-api` | Thực hiện quy trình Drop-shipping tự động. |
| **9** | **Nhà cung cấp (Supplier)** | Nhận thông báo đơn sỉ, in phiếu giao hàng, đóng gói và bàn giao đơn vị vận chuyển. | `supplier-api`<br>`logistics` | Xuất kho giao hàng trực tiếp tới tay Buyer. |
| **10** | **Khách hàng (Buyer)** | Nhận hàng thành công, xác nhận hoàn tất đơn hàng. | `order-api`<br>`user-api` | Đơn hàng khép lại, sẵn sàng cho bước quyết toán tiền. |

---

### 🔄 Workflow 2: Luồng Đặt Hàng & Giao Dịch Phân Tán (Order Creation & Seata 2PC)

```mermaid
sequenceDiagram
    autonumber
    actor Buyer as 🛍️ Khach hang
    participant Gateway as ⚡ Gateway
    participant Order as 🛒 Order-API (TM)
    participant Redis as ⚡ Redis Lock
    participant Seata as 🛡️ Seata TC
    participant Goods as 📦 Goods-API (RM)
    participant Promo as 🏷️ Promo-API (RM)
    participant MQ as 🐰 RabbitMQ

    Buyer->>Gateway: 1. Gui Yeu Cau Dat Hang
    Gateway->>Order: 2. Forward request den Order-API
    Order->>Redis: 3. Check va Tru kho nhanh tren Redis
    alt Ton kho Redis hop le
        Order->>Seata: 4. Khoi tao Giao dich Phan tan Global TX
        Seata-->>Order: Tra ve Global XID
        
        Order->>Goods: 5. Goi Tru ton kho thuc te trong MySQL
        Goods-->>Order: Confirm OK
        
        Order->>Promo: 6. Goi Khoa Voucher / Ma giam gia
        Promo-->>Order: Confirm OK
        
        Order->>Order: 7. Ghi nhan Don hang trang thai Cho Thanh Toan
        Order->>Seata: 8. Commit Global Transaction
        Seata-->>Order: Global Commit Done
        
        Order->>MQ: 9. Ban Event order.created Delay Queue
        Order-->>Buyer: 10. Tra ve Dat hang thanh cong va URL Thanh toan
    else Ton kho khong du
        Order-->>Buyer: Bao loi San pham da het hang
    end
```

#### 📋 Bảng Giải Thích Chi Tiết Luồng Đặt Hàng & Giao Dịch Phân Tán

| STT | Bước / Thành Phần | Nội Dung Thao Tác Chi Tiết | Cơ Chế Bảo Vệ & Kỹ Thuật | Kết Quả / Xử Lý Ngoại Lệ |
| :---: | :--- | :--- | :--- | :--- |
| **1-2** | **Buyer ➔ Gateway** | Khách gửi request Đặt hàng. Gateway xác thực JWT và chuyển tới `order-api`. | `Spring Cloud Gateway`<br>`JWT Verification` | Request hợp lệ được phép đi tiếp vào Service. |
| **3** | **Order-API ➔ Redis** | Kiểm tra và khấu trừ ngay số lượng tồn kho trên Redis RAM bằng hàm Atomic Decr. | `Redis Redisson Lock`<br>`Lua Script` | **Chống Oversold (Bán lố):** Trả về ngay lỗi nếu kho hết mà không cần chọc xuống DB. |
| **4** | **Order-API ➔ Seata** | Khởi tạo giao dịch toàn cục (Global Transaction) với Seata Transaction Coordinator. | `Seata AT Protocol`<br>`Global XID` | Cấp phát mã `XID` định danh chuỗi giao dịch phân tán. |
| **5** | **Order-API ➔ Goods-API** | Gọi `goods-api` để trừ số lượng tồn kho thực tế trong MySQL DB của dịch vụ hàng hóa. | `Resource Manager (RM)`<br>`MySQL Lock` | Tồn kho trong DB chính thức giảm. |
| **6** | **Order-API ➔ Promo-API** | Gọi `promotion-api` để khóa mã giảm giá/voucher mà khách sử dụng cho đơn hàng. | `Resource Manager (RM)`<br>`Promo DB` | Trạng thái Voucher chuyển sang *Đang Sử Dụng*. |
| **7-8** | **Order-API ➔ Seata** | Ghi nhận đơn hàng *Chờ Thanh Toán* và gửi yêu cầu Commit Global TX tới Seata. | `Seata Two-Phase Commit`<br>`2PC Commit` | **Nếu 1 bước lỗi:** Seata tự động kích hoạt **Rollback** hoàn kho và voucher lập tức. |
| **9** | **Order-API ➔ RabbitMQ** | Đưa sự kiện `order.created` vào hàng đợi trễ (TTL 30 phút) để chờ sự kiện thanh toán. | `RabbitMQ Delay Queue`<br>`AMQP Exchange` | Chuẩn bị cơ chế tự động hủy đơn khi hết hạn 30p. |
| **10** | **Order-API ➔ Buyer** | Trả về phản hồi thành công kèm Mã đơn hàng & Đường dẫn Cổng thanh toán. | `JSON Response` | Màn hình Khách hàng chuyển sang bước Quét mã trả tiền. |

---

### 🔄 Workflow 3: Luồng Thanh Toán & Phân Chia Doanh Thu (Payment Split & Settlement)

```mermaid
sequenceDiagram
    autonumber
    actor Buyer as 🛍️ Khach hang
    participant PaySvc as 💳 Payment-API
    participant ThirdPay as 🏦 CTT Alipay / WeChat Pay
    participant MQ as 🐰 RabbitMQ
    participant Consumer as ⚙️ Consumer Svc
    participant UserSvc as 👤 User Wallet-API
    participant XXL as ⏰ XXL-JOB Scheduler

    Buyer->>PaySvc: 1. Chon phuong thuc va Yeu cau thanh toan
    PaySvc->>ThirdPay: 2. Goi API khoi tao giao dien thanh toan
    ThirdPay-->>Buyer: 3. Hien thi man hinh Quet ma / OTP
    Buyer->>ThirdPay: 4. Xac nhan thanh toan thanh cong
    ThirdPay->>PaySvc: 5. Async Webhook Callback
    PaySvc->>PaySvc: 6. Xu ly Chu ky SSL
    PaySvc->>MQ: 7. Ban Event payment.success
    
    par Xu ly bat dong bo
        MQ->>Consumer: 8a. Doi trang thai don hang sang Da Thanh Toan
        MQ->>Consumer: 8b. Cap nhat doanh so va Thong bao Gian hang
    end

    XXL->>PaySvc: 9. Trigger Job Tu dong quyet toan don hang hoan tat
    PaySvc->>PaySvc: 10. Tinh toan Ty le Split Bill
    PaySvc->>UserSvc: 11. Cong du no vao Vi Thuong gia
    PaySvc->>UserSvc: 12. Cong tien hang vao Vi Nha cung cap
    PaySvc->>PaySvc: 13. Ghi log Doi soat tai chinh
```

#### 📋 Bảng Giải Thích Chi Tiết Luồng Thanh Toán & Phân Chia Doanh Thu

| STT | Bước / Thành Phần | Quy Trình Thao Tác Chi Tiết | Công Thức / Logic Tính Toán | Kết Quả Hệ Thống |
| :---: | :--- | :--- | :--- | :--- |
| **1-3** | **PaySvc ➔ Cổng TT** | Khách chọn cổng WeChat/Alipay. `payment-api` khởi tạo mã QR / SDK thanh toán. | `RSA2048 / HMAC-SHA256`<br>`Payment Sign` | Màn hình thanh toán xuất hiện trên App khách. |
| **4-6** | **Cổng TT ➔ PaySvc** | Cổng thanh toán gửi Webhook báo kết quả. PaySvc kiểm tra chữ ký SSL để tránh giả mạo. | `Webhook Signature Check`<br>`Idempotent Key` | Đảm bảo tính chống lặp (Idempotent) giao dịch. |
| **7-8** | **PaySvc ➔ RabbitMQ** | Bắn tin nhắn `payment.success` vào RabbitMQ. Service `consumer` nhận tin xử lý ngầm. | `Message Queue Async`<br>`Fanout Exchange` | Cập nhật đơn hàng *Đã Thanh Toán* & báo chuông cho Gian hàng mà không làm lag cổng pay. |
| **9** | **XXL-JOB ➔ PaySvc** | Định kỳ hàng ngày/tuần, XXL-JOB trigger tiến trình "Auto Settlement Bill". | `XXL-JOB Cron Schedule`<br>`Cron Expression` | Kích hoạt tiến trình chia tiền tự động. |
| **10** | **Payment-API** | Tính toán phân bổ tiền theo hợp đồng chiết khấu của từng Gian hàng và Supplier. | $\text{Ví Seller} = \text{Tổng Lẻ} - \text{Hoa Hồng Sàn} - \text{Giá Sỉ}$<br>$\text{Ví Supplier} = \text{Giá Sỉ Gốc}$ | Xác định chính xác số tiền thuộc về mỗi bên. |
| **11-12**| **PaySvc ➔ User-API** | Chuyển tiền tự động vào Ví điện tử nội bộ (Internal Wallet) của Thương gia và Supplier. | `user-api`<br>`Wallet Balance Transaction` | Số dư khả dụng của Seller & Supplier tăng lên, có thể rút về Bank. |
| **13** | **Payment-API** | Tạo file và dòng log đối soát tài chính (Financial Settlement Record). | `payment-db`<br>`Audit Log` | Lưu vết đầy đủ phục vụ kế toán & kiểm toán sàn. |
