# 📐 Sơ Đồ Kết Nối Các Services & Phân Tích Luồng Nghiệp Vụ (Workflows)

Tài liệu này cung cấp **Sơ đồ kết nối tổng thể (Connection Diagram)** giữa các Client, Gateway, Microservices và Hạ tầng Middleware, cùng với **Phân tích các Luồng nghiệp vụ chính (Core Workflows)** và **Bảng giải thích quy trình chi tiết** trong hệ thống **Lilishop / XianZhu S2B2C**.

---

## 🗺️ 1. Sơ Đồ Kết Nối Tổng Thể Các Services (System Connection Diagram)

```mermaid
graph TB
    subgraph ClientLayer["📱 CLIENT LAYER - Giao diện người dùng"]
        BuyerUI["🛍️ Buyer Client (PC / H5 / MiniApp)"]
        SellerUI["🏪 Seller Portal (Thương gia)"]
        SupplierUI["🚚 Supplier Portal (Nhà cung cấp)"]
        AdminUI["🖥️ Manager Portal (Quản trị sàn)"]
        IMClient["💬 IM Chat Client (Ứng dụng Chat)"]
    end

    subgraph EntryLayer["🌐 ENTRY AND GATEWAY LAYER"]
        Nginx["🌐 Nginx Ingress / Web Server"]
        Gateway["⚡ Spring Cloud Gateway (Port 8888)"]
    end

    subgraph ServiceLayer["☕ MICROSERVICES BUSINESS LAYER"]
        AuthSvc["🔐 auth-api"]
        UserSvc["👤 user-api / member-api"]
        GoodsSvc["📦 goods-api"]
        OrderSvc["🛒 order-api"]
        PaymentSvc["💳 payment-api"]
        PromoSvc["🏷️ promotion-api"]
        SupplierSvc["🏬 supplier-api"]
        IMSvc["💬 im-api (WebSocket Port 11130)"]
        ConsumerSvc["⚙️ consumer (Async Event Listener)"]
    end

    subgraph InfraLayer["🗄️ MIDDLEWARE INFRASTRUCTURE LAYER"]
        Nacos["🌀 Nacos 2.x (Registry & Config)"]
        Seata["🛡️ Seata 1.6 (Distributed TX)"]
        XXL["⏰ XXL-JOB 2.4 (Job Scheduler)"]
        Redis["⚡ Redis 7.0 (Cache & Redisson Lock)"]
        MySQL["🗄️ MySQL 8.0 (Master Database)"]
        ES["🔍 Elasticsearch 7.17 (Search Engine)"]
        RabbitMQ["🐰 RabbitMQ 3.x (Message Broker)"]
    end

    BuyerUI --> Nginx
    SellerUI --> Nginx
    SupplierUI --> Nginx
    AdminUI --> Nginx
    IMClient --> IMSvc

    Nginx --> Gateway

    Gateway --> AuthSvc
    Gateway --> UserSvc
    Gateway --> GoodsSvc
    Gateway --> OrderSvc
    Gateway --> PaymentSvc
    Gateway --> PromoSvc
    Gateway --> SupplierSvc

    ServiceLayer --> Nacos
    OrderSvc --> Seata
    GoodsSvc --> Seata
    UserSvc --> Seata

    OrderSvc --> Redis
    GoodsSvc --> Redis
    AuthSvc --> Redis
    PaymentSvc --> Redis

    ServiceLayer --> MySQL
    GoodsSvc --> ES
    BuyerUI --> ES

    OrderSvc --> RabbitMQ
    PaymentSvc --> RabbitMQ
    GoodsSvc --> RabbitMQ
    RabbitMQ --> ConsumerSvc
    ConsumerSvc --> ES
    ConsumerSvc --> MySQL

    XXL --> OrderSvc
    XXL --> PaymentSvc

    %% Vibrant Color Styling
    style ClientLayer fill:#e0f2fe,stroke:#0284c7,stroke-width:2px,color:#0369a1
    style EntryLayer fill:#fef3c7,stroke:#d97706,stroke-width:2px,color:#92400e
    style ServiceLayer fill:#dcfce7,stroke:#16a34a,stroke-width:2px,color:#15803d
    style InfraLayer fill:#f3e8ff,stroke:#9333ea,stroke-width:2px,color:#6b21a8

    style BuyerUI fill:#ffffff,stroke:#0284c7,color:#0f172a
    style SellerUI fill:#ffffff,stroke:#0284c7,color:#0f172a
    style SupplierUI fill:#ffffff,stroke:#0284c7,color:#0f172a
    style AdminUI fill:#ffffff,stroke:#0284c7,color:#0f172a
    style IMClient fill:#ffffff,stroke:#0284c7,color:#0f172a

    style Nginx fill:#ffffff,stroke:#d97706,color:#0f172a
    style Gateway fill:#ffffff,stroke:#d97706,color:#0f172a

    style AuthSvc fill:#ffffff,stroke:#16a34a,color:#0f172a
    style UserSvc fill:#ffffff,stroke:#16a34a,color:#0f172a
    style GoodsSvc fill:#ffffff,stroke:#16a34a,color:#0f172a
    style OrderSvc fill:#ffffff,stroke:#16a34a,color:#0f172a
    style PaymentSvc fill:#ffffff,stroke:#16a34a,color:#0f172a
    style PromoSvc fill:#ffffff,stroke:#16a34a,color:#0f172a
    style SupplierSvc fill:#ffffff,stroke:#16a34a,color:#0f172a
    style IMSvc fill:#ffffff,stroke:#16a34a,color:#0f172a
    style ConsumerSvc fill:#ffffff,stroke:#16a34a,color:#0f172a

    style Nacos fill:#ffffff,stroke:#9333ea,color:#0f172a
    style Seata fill:#ffffff,stroke:#9333ea,color:#0f172a
    style XXL fill:#ffffff,stroke:#9333ea,color:#0f172a
    style Redis fill:#ffffff,stroke:#9333ea,color:#0f172a
    style MySQL fill:#ffffff,stroke:#9333ea,color:#0f172a
    style ES fill:#ffffff,stroke:#9333ea,color:#0f172a
    style RabbitMQ fill:#ffffff,stroke:#9333ea,color:#0f172a
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
