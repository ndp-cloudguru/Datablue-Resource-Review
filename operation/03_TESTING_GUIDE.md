# 🧪 XIANZHU S2B2C - HƯỚNG DẪN KIỂM THỬ TOÀN BỘ HỆ THỐNG (TESTING GUIDE)

Tài liệu này hướng dẫn từng bước kiểm thử (Testing) toàn bộ hệ thống **XianZhu S2B2C**, từ kiểm tra hạ tầng Backend, API Gateway, cho tới các luồng nghiệp vụ trên giao diện Web (Buyer, Seller, Manager).

---

## 📌 BƯỚC 1: KIỂM TRA HẠ TẦNG BACKEND & DỊCH VỤ (HEALTH CHECK)

### 1.1. Kiểm tra trạng thái Container Docker
Mở terminal và chạy lệnh:
```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```
*Đảm bảo các container `builds-nacos`, `builds-mysql`, `builds-redis`, `builds-gateway`, `builds-buyer-ui`... đều ở trạng thái Up.*

### 1.2. Kiểm tra Nacos Registry Center
1. Truy cập: **[http://localhost:8848/nacos](http://localhost:8848/nacos)**
2. Nhập tài khoản mặc định: `nacos` / `nacos`
3. Vào **Service Management** ➔ **Service List** ➔ **Chọn Namespace `middle`**.
4. **Kỳ vọng:** Cột `Healthy Instance Count` của tất cả các services (`gateway`, `auth-service`, `goods-service`, `order-service`, `user-service`...) hiện **`1/1` (màu xanh)**.

---

## 📌 BƯỚC 2: TEST API QUA SWAGGER / OPENAPI

* **Thông tin API Documentation:**
  * Hệ thống backend sử dụng **SpringDoc OpenAPI 3.0** (`springdoc-openapi-starter-webmvc-ui`).
  * Tất cả request API từ Web Client và UI đều gọi tập trung thông qua **API Gateway tại cổng 8888** (`http://localhost:8888/`).
* **Test trực tiếp qua cURL / Postman hoặc Script Python:**
  * **API Kiểm tra Captcha (auth-service):** `GET http://localhost:8888/auth/verification/LOGIN` (Headers: `uuid: <random_uuid>`, `scene: MANAGER`)
  * **API Danh mục sản phẩm (goods-service):** `GET http://localhost:8888/goods/category/0/all-children`


---

## 📌 BƯỚC 3: TEST GIAO DIỆN NGƯỜI MUA (BUYER UI)

* **URL:** **[http://localhost:8080/buyer/](http://localhost:8080/buyer/)** (hoặc `http://localhost:8080/`)

### Kịch bản kiểm thử:
1. **Duyệt Trang chủ:** Xem Banner, Sản phẩm gợi ý, Danh mục sản phẩm.
2. **Tìm kiếm:** Gõ từ khóa tìm kiếm (ví dụ: `phone`, `áo`, `giày`).
3. **Chi tiết Sản phẩm:** Click vào 1 sản phẩm xem thông tin, giá cả, thông số SKU, hình ảnh.
4. **Đăng ký / Đăng nhập:**
   - Thử đăng ký tài khoản người mua mới bằng số điện thoại.
   - Nhận mã OTP thử nghiệm (mặc định môi trường dev OTP là `123456` hoặc kiểm tra log service).
5. **Giỏ hàng & Đặt hàng:**
   - Thêm sản phẩm vào giỏ.
   - Chuyển sang trang thanh toán ➔ Điền địa chỉ nhận hàng ➔ Nhấn **Đặt hàng**.

---

## 📌 BƯỚC 4: TEST GIAO DIỆN THƯƠNG GIA / NGƯỜI BÁN (SELLER UI)

* **URL:** **[http://localhost:8080/seller/](http://localhost:8080/seller/)**

### Kịch bản kiểm thử:
1. **Đăng nhập Gian hàng (Store Seller Login):**
   * **Số điện thoại:** `15200000000` *(hoặc `13500000000`, `13800000003`)*
   * **Mã OTP:** Bấm **获取验证码 (Lấy mã OTP)** ➔ Điền mã mặc định: **`123456`**
   * **Mật khẩu:** `123456`
   * **Thao tác:** Bấm nút **`Login`** ➔ Đăng nhập thành công vào bảng điều khiển Kênh người bán (Seller Dashboard).
2. **Quản lý Hàng hóa:**
   * Vào mục **Hàng hóa ➔ Đăng bán sản phẩm mới**.
   * Chọn Danh mục ➔ Tải ảnh ➔ Điền tên, giá cả, số lượng kho ➔ Nhấn **Phát hành (Publish)**.
3. **Quản lý Đơn hàng:**
   * Vào mục **Đơn hàng ➔ Danh sách đơn hàng**.
   * Tìm đơn hàng người mua vừa đặt ở Bước 3 ➔ Nhấn **Duyệt đơn / Chuẩn bị giao hàng**.

---

## 📌 BƯỚC 5: TEST GIAO DIỆN QUẢN TRỊ SÀN (MANAGER UI)

* **URL:** **[http://localhost:8080/manager/](http://localhost:8080/manager/)**

### Kịch bản kiểm thử:
1. **Đăng nhập Quản trị viên (Admin Login):**
   * **Số điện thoại:** `15200000000` *(hoặc `13500000000`)*
   * **Mã OTP:** Bấm **获取验证码 (Lấy mã OTP)** ➔ Điền mã mặc định: **`123456`**
   * **Mật khẩu:** `123456`
   * **Hoặc Tài khoản Admin gốc:** `admin` / Mật khẩu: `123456`
   * **Thao tác:** Bấm nút **`Login`** ➔ Đăng nhập thành công vào Admin Management Console.
2. **Quản lý Gian hàng & Người dùng:**
   * Vào **Thương gia ➔ Danh sách gian hàng** (Duyệt gian hàng mới, khoá gian hàng vi phạm).
   * Vào **Người dùng ➔ Danh sách thành viên** (Quản lý tài khoản Buyer/Seller).
3. **Quản lý Trang chủ & Trang trí Web:**
   * Vào **Cấu hình ➔ Trang trí trang chủ** (Chỉnh sửa Banner, Khối hiển thị sản phẩm hot).
4. **Quản lý Cấu hình Hệ thống:**
   * Kiểm tra các thông số cài đặt thanh toán (VNPay/Alipay/WeChat), dịch vụ gửi SMS, bộ lọc từ cấm.

---

## 📌 BƯỚC 6: TEST GIAO DIỆN NHÀ CUNG CẤP & CHAT (SUPPLIER & IM)

* **Supplier Platform UI (Nhà cung cấp sỉ S2B):** **[http://localhost:8080/supplier-platform/](http://localhost:8080/supplier-platform/)**
  * **Đăng nhập:** SĐT: `15200000000` | OTP: `123456` | Mật khẩu: `123456`
  * **Chức năng:** Quản lý kho hàng sỉ, cấp hàng cho các Merchant/Seller.
* **IM Chat UI (Hệ thống CSKH & Chat trực tuyến):** **[http://localhost:8080/im/](http://localhost:8080/im/)**
  * **Chức năng:** Giao diện Trát/Chat trực tiếp giữa Buyer (Người mua) và Seller/CSKH (Người bán). Kết nối qua WebSocket tới `im-service` (Port 11130).

