import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String defaultProductionUrl =
      'https://music-storage-backend.fly.dev/api';

  static String get baseUrl {
    const String envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;

    if (kReleaseMode) {
      return defaultProductionUrl;
    }

    if (kIsWeb) return 'http://localhost:8000/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return defaultProductionUrl;
    }
    return 'http://localhost:8000/api';
  }

  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String getMe = '/auth/me';

  static const String songs = '/songs';
  static const String uploadSong = '/songs/upload';

  static const String youtubeDownload = '/dowload-music-from-yt';

  static const String folders = '/folders';
}
