# 📱 Music Storage Mobile UI (Flutter)

Ứng dụng nghe nhạc đa nền tảng hiện đại viết bằng **Flutter (Dart)**, kết nối trực tiếp với hệ thống **FastAPI & Google Drive Backend**.

---

## 🌟 Tính năng của Mobile App

- 🔐 **Xác thực người dùng**:
  - Đăng nhập & Đăng ký tài khoản với JWT Token.
  - Tự động lưu phiên đăng nhập an toàn với `SharedPreferences`.
  - Tự động kích hoạt tạo thư mục riêng biệt trên Google Drive khi đăng ký.
- 🎵 **Kho bài hát & Phát nhạc**:
  - Hiển thị danh sách bài hát cá nhân từ MongoDB.
  - Tìm kiếm bài hát theo tên, ca sĩ, album tức thời.
  - Xóa bài hát (Đồng bộ xóa cả trong Database và Google Drive).
  - Trình phát nhạc nền (`just_audio`) phát nhạc mượt mà từ Google Drive Direct Stream URL.
- 🎧 **Giao diện Trình phát nhạc (Player UI)**:
  - **Mini Player**: Thanh điều khiển nhỏ gọn nổi ở đáy màn hình, vuốt trượt mở rộng mượt mà giống Spotify.
  - **Now Playing Screen**: Màn hình phát nhạc đầy đủ với ảnh bìa bài hát lớn, thanh tua thời gian (Slider), Play/Pause/Skip/Shuffle/Repeat.
- 📥 **Tải nhạc từ YouTube**:
  - Nút tải nhạc nhanh trực tiếp trong App: Nhập link YouTube -> Backend tự động trích xuất MP3 192kbps + ảnh thumbnail -> Lưu vào Google Drive -> Cập nhật ngay vào danh sách bài hát của bạn.

---

## 🛠 Cấu trúc Thư mục

```text
mobile_ui/
├── lib/
│   ├── core/
│   │   ├── constants/api_constants.dart   # Cấu hình IP/BaseURL Backend
│   │   └── theme/app_theme.dart           # Giao diện Obsidian Dark Mode hiện đại
│   ├── models/
│   │   ├── song_model.dart                # Model Bài hát
│   │   └── user_model.dart                # Model Người dùng
│   ├── services/
│   │   ├── api_service.dart               # HTTP Client Dio kết nối FastAPI
│   │   └── audio_player_service.dart      # Quản lý phát nhạc & Playlist
│   ├── providers/
│   │   ├── auth_provider.dart             # State management Đăng nhập/Đăng ký
│   │   └── song_provider.dart             # State management Danh sách & Tải nhạc
│   ├── views/
│   │   ├── auth/                          # Màn hình Login & Register
│   │   ├── home/home_screen.dart          # Màn hình chính & Danh sách bài hát
│   │   └── player/now_playing_screen.dart # Màn hình phát nhạc chi tiết
│   ├── widgets/
│   │   ├── mini_player_widget.dart        # Mini player ghim cố định ở đáy
│   │   └── song_card_widget.dart          # Card từng bài hát
│   └── main.dart                          # Điểm khởi chạy ứng dụng
├── pubspec.yaml                           # Khai báo thư viện & assets
└── android/, ios/, web/, windows/         # Mã nguồn native các nền tảng
```

---

## 🚀 Hướng dẫn Chạy Ứng dụng

### 1. Di chuyển vào thư mục `mobile_ui`
```powershell
cd c:\Users\manhd\Desktop\music-app\mobile_ui
```

### 2. Cấu hình địa chỉ IP Backend (Nếu cần)
Mở tệp [lib/core/constants/api_constants.dart](file:///c:/Users/manhd/Desktop/music-app/mobile_ui/lib/core/constants/api_constants.dart):
- **Nếu chạy trên Android Emulator**: Sử dụng `http://10.0.2.2:8000/api` (Đã cấu hình tự động).
- **Nếu chạy trên Điện thoại thật cắm cáp USB / Wi-Fi**: Đổi thành địa chỉ IP mạng LAN của máy tính bạn (ví dụ: `http://192.168.1.15:8000/api`).
- **Nếu chạy trên Trình duyệt Web / Windows Desktop**: Sử dụng `http://localhost:8000/api` (Đã cấu hình tự động).

### 3. Chạy ứng dụng

#### A. Chạy trên trình duyệt Web (Test nhanh nhất):
```powershell
flutter run -d chrome
```

#### B. Chạy trên ứng dụng Windows Desktop:
```powershell
flutter run -d windows
```

#### C. Chạy trên điện thoại Android (Máy thật cắm cáp hoặc Máy ảo Android Studio):
```powershell
flutter run -d android
```
*(Hoặc gõ `flutter run` và chọn thiết bị bạn muốn)*
