import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../models/song_model.dart';
import '../models/user_model.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 120), // Cho phép tải nhạc YouTube mất nhiều thời gian
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('access_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Xử lý khi token hết hạn
          if (error.response?.statusCode == 401) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('access_token');
          }
          return handler.next(error);
        },
      ),
    );
  }

  // --- AUTHENTICATION ---
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await _dio.post(
      ApiConstants.login,
      data: {
        'username': username,
        'password': password,
      },
    );
    final data = response.data;
    if (data['access_token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['access_token']);
    }
    return data;
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? fullName,
  }) async {
    final response = await _dio.post(
      ApiConstants.register,
      data: {
        'username': username,
        'email': email,
        'password': password,
        'full_name': fullName,
      },
    );
    return response.data;
  }

  Future<User?> getMe() async {
    try {
      final response = await _dio.get(ApiConstants.getMe);
      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data.containsKey('user') && data['user'] is Map<String, dynamic>) {
          return User.fromJson(data['user']);
        }
        return User.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }


  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  // --- SONGS ---
  Future<List<Song>> getSongs({String? search, int skip = 0, int limit = 50}) async {
    final queryParams = <String, dynamic>{
      'skip': skip,
      'limit': limit,
    };
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final response = await _dio.get(
      ApiConstants.songs,
      queryParameters: queryParams,
    );

    final List list = response.data['data'] ?? [];
    return list.map((item) => Song.fromJson(item)).toList();
  }

  Future<Song?> getSong(String id) async {
    final response = await _dio.get('${ApiConstants.songs}/$id');
    if (response.data['data'] != null) {
      return Song.fromJson(response.data['data']);
    }
    return null;
  }

  Future<bool> deleteSong(String id) async {
    final response = await _dio.delete('${ApiConstants.songs}/$id');
    return response.statusCode == 200;
  }

  // --- YOUTUBE INGESTION ---
  Future<Map<String, dynamic>> downloadFromYoutube({
    required String url,
    String format = 'mp3',
    bool saveToDrive = true,
  }) async {
    final response = await _dio.post(
      ApiConstants.youtubeDownload,
      data: {
        'url': url,
        'format': format,
        'return_file': false,
        'save_to_drive': saveToDrive,
      },
    );
    return response.data;
  }
}

final apiService = ApiService();
