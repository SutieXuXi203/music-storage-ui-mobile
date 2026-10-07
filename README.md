# 🎵 Music Storage App - Ứng Dụng Nghe Nhạc & Lưu Trữ Đa Nền Tảng

[![Build Android APK](https://github.com/SutieXuXi203/music-storage-ui-mobile/actions/workflows/build_apk.yml/badge.svg)](https://github.com/SutieXuXi203/music-storage-ui-mobile/actions/workflows/build_apk.yml)
[![Latest Release](https://img.shields.io/github/v/release/SutieXuXi203/music-storage-ui-mobile?color=black&label=Release)](https://github.com/SutieXuXi203/music-storage-ui-mobile/releases)
[![Flutter](https://img.shields.io/badge/Flutter-3.47.6-02569B?logo=flutter)](https://flutter.dev)
[![Backend Status](https://img.shields.io/badge/Backend-Fly.io%20Live-success)](https://music-storage-backend.fly.dev/docs)

Ứng dụng nghe nhạc đa nền tảng được phát triển bằng **Flutter**, kết nối trực tiếp với hệ thống máy chủ đám mây **FastAPI** trên **Fly.io**, cơ sở dữ liệu **MongoDB Atlas** và kho lưu trữ âm thanh không giới hạn trên **Google Drive**.

Giao diện ứng dụng được thiết kế theo phong cách **Terminal / CLI Minimalist** (Black & White, góc vuông sắc nét, hiệu ứng sóng nhạc âm thanh động).

---

## 📲 TẢI VỀ & CÀI ĐẶT ỨNG DỤNG ANDROID (.APK)

Bạn có thể tải file cài đặt APK mới nhất trực tiếp về điện thoại Android theo các liên kết bên dưới:

* 📦 **Tải bản phát hành mới nhất (Mọi phiên bản):**  
  👉 **[GitHub Releases - Sutorage App Releases](https://github.com/SutieXuXi203/music-storage-ui-mobile/releases)**
* 📥 **Tải trực tiếp file APK (Direct Download):**  
  👉 **[Download sutorage.apk](https://github.com/SutieXuXi203/music-storage-ui-mobile/releases/latest/download/sutorage.apk)**

### Hướng dẫn cài đặt trên điện thoại Android:
1. Nhấn vào liên kết trên để tải file **`sutorage.apk`** về máy.
2. Mở file vừa tải về trong mục **Tệp đã tải xuống** (Downloads).
3. Nếu điện thoại hiển thị cảnh báo *"Cài đặt ứng dụng không rõ nguồn gốc"*, chọn **Cài đặt (Settings)** ➔ Bật **Cho phép nguồn này (Allow from this source)**.
4. Nhấn **Cài đặt (Install)** và mở ứng dụng để trải nghiệm nghe nhạc!

---

## ✨ TÍNH NĂNG NỔI BẬT

- 🎧 **Nghe nhạc & Phát trực tuyến:** Tự động phát âm thanh chất lượng cao từ Google Drive với trình phát `just_audio` mượt mà, hỗ trợ phát ngầm.
- 📥 **Tải nhạc từ YouTube tự động:** Nhập link YouTube bất kỳ, máy chủ Fly.io (`yt-dlp` + `ffmpeg`) sẽ tự động trích xuất file MP3 chất lượng cao, tải ảnh bìa và đồng bộ lên Google Drive.
- 🎨 **Thiết kế tối giản ấn tượng (B&W Minimalist):** Giao diện đen trắng thanh lịch, hiệu ứng sóng nhạc đa tầng, hiển thị thời lượng bài hát chuẩn xác.
- ⚡ **Tìm kiếm & Phân trang tức thì:** Tìm kiếm theo tên bài hát, nghệ sĩ với thanh tìm kiếm thời gian thực.
- 🔐 **Xác thực an toàn:** Đăng nhập, đăng ký tài khoản với JWT token và bảo mật mật khẩu bcrypt.

---

## 🛠️ HƯỚNG DẪN DÀNH CHO LẬP TRÌNH VIÊN

### 1. Yêu cầu môi trường
* Flutter SDK: `^3.5.0`
* Dart SDK: `^3.5.0`

### 2. Cài đặt thư viện
```bash
flutter pub get
```

### 3. Chạy ứng dụng trên môi trường Local
```bash
flutter run
```

### 4. Tự biên dịch bản phát hành (Build Release)

* **Build file APK Android kết nối server Fly.io:**
```bash
flutter build apk --release --dart-define=API_BASE_URL=https://music-storage-backend.fly.dev/api
```
*(File xuất ra tại: `build/app/outputs/flutter-apk/app-release.apk`)*

* **Build bản Web App:**
```bash
flutter build web --release --dart-define=API_BASE_URL=https://music-storage-backend.fly.dev/api
```
*(Thư mục xuất ra tại: `build/web`)*
