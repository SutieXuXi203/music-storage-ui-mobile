import 'package:flutter/foundation.dart';

class ApiConstants {
  // Tự động nhận diện host phù hợp hoặc cấu hình qua --dart-define=API_BASE_URL=...
  static String get baseUrl {
    const String envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;

    if (kIsWeb) return 'http://localhost:8000/api';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8000/api';
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
