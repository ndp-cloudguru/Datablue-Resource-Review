# 📝 FRONTEND CHANGE LOG & DEVELOPER TAKE NOTES

Tài liệu ghi chú tổng hợp tất cả các chỉnh sửa và sửa lỗi (Bug Fixes) trên nguồn mã **Frontend (S2B2B2C-UI-develop)**. Developer cần đồng bộ các thay đổi này vào kho mã nguồn chính.

---

## 📌 Danh sách các thay đổi cần cập nhật (Patch Details)

### 1. Truyền tham số `API_DEV` khi chạy script Build
* **Mã nguồn trong Git (`public/config.js`):** **GIỮ NGUYÊN 100% GỐC**, không sửa đổi code.
* **Cách truyền tham số lúc Build:**
  ```bash
  # Mặc định script sẽ dùng API_DEV="http://localhost:8888"
  ./build-single-artifact.sh

  # Hoặc bạn có thể truyền tùy chỉnh địa chỉ API_DEV khác:
  API_DEV="http://localhost:8888" ./build-single-artifact.sh
  ```
* **Lý do / Mục đích:** Giữ sạch mã nguồn 100% theo đúng nguyên bản repository gốc. Tham số `API_DEV` được truyền tự động ở bước build artifact ra thư mục `builds/frontend/*/config.js`.

---

### 2. Tắt CDN Trung Quốc (`enableCDN: false`) trong `src/config/index.js` của 4 UI Modules
* **File ảnh hưởng:**
  - `buyer/src/config/index.js`
  - `seller/src/config/index.js`
  - `manager/src/config/index.js`
  - `supplier-platform/src/config/index.js`
* **Mã nguồn cập nhật:**
  ```javascript
  module.exports = {
    ...
    enableCDN: false, // Tắt CDN Trung Quốc (https://cdn.pickmall.cn) để Webpack tự bundle Vue, Vuex, Axios, iView nội bộ
    ...
  }
  ```

---

### 3. Thêm `publicPath: './'` vào `vue.config.js` của TOÀN BỘ 5 UI Modules
* **File ảnh hưởng:** `buyer`, `seller`, `manager`, `supplier-platform`, `im` `vue.config.js`

---

### 4. Sửa lỗi đường dẫn Import `config` bị sai cấp thư mục
* **`seller/src/views/goods/goods-seller/goodsOperationSec.vue`** (Dòng 666): `import config from '@/config';`
* **`manager/src/views/sys/setting-manage/setting/POINT_SETTING.vue`** (Dòng 51): `import config from '@/config';`
* **`supplier-platform/src/views/goods/goods-seller/goodsOperationSec.vue`** (Dòng 640): `import config from '@/config';`

---

## 🛠️ Hướng dẫn Biên dịch cho Frontend Developer
* Dự án tương thích hoàn toàn với **Node.js LTS v18 / v20 / v22**.
* Khi sử dụng Yarn để cài đặt thư viện: `yarn install --ignore-engines`
* Lệnh build truyền tham số API_DEV: `API_DEV="http://localhost:8888" ./build-single-artifact.sh`
