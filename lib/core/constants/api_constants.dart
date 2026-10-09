import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String defaultProductionUrl = 'https://music-storage-backend.fly.dev/api';

  // Tự động nhận diện host phù hợp hoặc cấu hình qua --dart-define=API_BASE_URL=...
  static String get baseUrl {
    const String envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;

    // Trong Release mode (bản APK cài trên điện thoại) luôn mặc định dùng Production Fly.io
    if (kReleaseMode) {
      return defaultProductionUrl;
    }

    if (kIsWeb) return 'http://localhost:8000/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Mặc định luôn kết nối máy chủ Production trên Android
      return defaultProductionUrl;
    }
    return 'http://localhost:8000/api';
  }

  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String getMe = '/auth/me';

  // Song endpoints
  static const String songs = '/songs';
  static const String uploadSong = '/songs/upload';

  // YouTube Ingestion
  static const String youtubeDownload = '/dowload-music-from-yt';

  // Folder endpoints
  static const String folders = '/folders';
}
