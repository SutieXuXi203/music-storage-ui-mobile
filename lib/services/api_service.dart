import 'dart:async';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../models/song_model.dart';
import '../models/user_model.dart';
import '../models/folder_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  late final Dio _tokenDio;
  Completer<String?>? _refreshCompleter;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 120),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _tokenDio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
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
          final path = error.requestOptions.path;
          final isAuthEndpoint = path.contains('/auth/login') ||
              path.contains('/auth/register') ||
              path.contains('/auth/refresh');

          if (error.response?.statusCode == 401 && !isAuthEndpoint) {
            final newToken = await _handleTokenRefresh();
            if (newToken != null && newToken.isNotEmpty) {
              final retryOptions = error.requestOptions;
              retryOptions.headers['Authorization'] = 'Bearer $newToken';
              try {
                final retryRes = await _dio.fetch(retryOptions);
                return handler.resolve(retryRes);
              } on DioException catch (retryErr) {
                return handler.next(retryErr);
              } catch (_) {
                return handler.next(error);
              }
            } else {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('access_token');
              await prefs.remove('refresh_token');
              await prefs.remove('cached_user');
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<String?> _handleTokenRefresh() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<String?>();
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      if (refreshToken == null || refreshToken.isEmpty) {
        _refreshCompleter!.complete(null);
        return null;
      }

      final response = await _tokenDio.post(
        ApiConstants.refresh,
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final newAccessToken = data['access_token'] as String?;
          final newRefreshToken =
              (data['refresh_token'] as String?) ?? refreshToken;

          if (newAccessToken != null && newAccessToken.isNotEmpty) {
            await prefs.setString('access_token', newAccessToken);
            await prefs.setString('refresh_token', newRefreshToken);
            _refreshCompleter!.complete(newAccessToken);
            return newAccessToken;
          }
        }
      }
      _refreshCompleter!.complete(null);
      return null;
    } catch (_) {
      _refreshCompleter!.complete(null);
      return null;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<String?> refreshToken() => _handleTokenRefresh();

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await _dio.post(
      ApiConstants.login,
      data: {
        'username': username,
        'password': password,
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final prefs = await SharedPreferences.getInstance();
      if (data['access_token'] != null) {
        await prefs.setString('access_token', data['access_token']);
      }
      if (data['refresh_token'] != null) {
        await prefs.setString('refresh_token', data['refresh_token']);
      }
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

  Future<bool> updateProfile({String? fullName, String? email}) async {
    try {
      final body = <String, dynamic>{};
      if (fullName != null && fullName.trim().isNotEmpty) {
        body['full_name'] = fullName.trim();
      }
      if (email != null && email.trim().isNotEmpty) {
        body['email'] = email.trim();
      }
      if (body.isEmpty) return true;
      final response = await _dio.put(ApiConstants.getMe, data: body);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('cached_user');
  }

  Future<List<Song>> getSongs(
      {String? search, int skip = 0, int limit = 50}) async {
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

  Future<Map<String, dynamic>?> getSongLyrics(String songId,
      {bool refresh = false}) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.songs}/$songId/lyrics',
        queryParameters: {'refresh': refresh},
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return response.data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

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

  String? _lastErrorMessage;
  String? get lastErrorMessage => _lastErrorMessage;

  void _extractError(dynamic e) {
    if (e is DioException) {
      final res = e.response;
      if (res?.data is Map) {
        final d = res!.data;
        if (d['detail'] != null) {
          if (d['detail'] is String) {
            _lastErrorMessage = d['detail'];
            return;
          } else if (d['detail'] is List) {
            _lastErrorMessage = (d['detail'] as List)
                .map((i) => i['msg'] ?? i.toString())
                .join(', ');
            return;
          }
        }
        if (d['message'] != null) {
          _lastErrorMessage = d['message'].toString();
          return;
        }
      }
      _lastErrorMessage =
          e.message ?? 'Lỗi kết nối máy chủ (${res?.statusCode ?? 'network'})';
    } else {
      _lastErrorMessage = e.toString();
    }
  }

  Future<List<Folder>> getFolders() async {
    try {
      _lastErrorMessage = null;
      final response = await _dio.get(ApiConstants.folders);
      final List list = response.data['data'] ?? [];
      return list.map((item) => Folder.fromJson(item)).toList();
    } catch (e) {
      _extractError(e);
      return [];
    }
  }

  Future<Folder?> createFolder(String name) async {
    try {
      _lastErrorMessage = null;
      final response = await _dio.post(
        ApiConstants.folders,
        data: {'name': name.trim()},
      );
      if (response.data['data'] != null) {
        return Folder.fromJson(response.data['data']);
      }
      _lastErrorMessage =
          response.data['message'] ?? 'Không nhận được dữ liệu phản hồi';
      return null;
    } catch (e) {
      _extractError(e);
      return null;
    }
  }

  Future<Folder?> getFolderDetails(String folderId) async {
    try {
      _lastErrorMessage = null;
      final response = await _dio.get('${ApiConstants.folders}/$folderId');
      if (response.data['data'] != null) {
        return Folder.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      _extractError(e);
      return null;
    }
  }

  Future<bool> renameFolder(String folderId, String newName) async {
    try {
      _lastErrorMessage = null;
      final response = await _dio.put(
        '${ApiConstants.folders}/$folderId',
        data: {'name': newName.trim()},
      );
      return response.statusCode == 200;
    } catch (e) {
      _extractError(e);
      return false;
    }
  }

  Future<bool> updateFolderCoverUrl(String folderId, String? coverUrl) async {
    try {
      _lastErrorMessage = null;
      final response = await _dio.put(
        '${ApiConstants.folders}/$folderId',
        data: {'cover_url': coverUrl ?? ''},
      );
      return response.statusCode == 200;
    } catch (e) {
      _extractError(e);
      return false;
    }
  }

  Future<Folder?> uploadFolderCoverImage(
      String folderId, List<int> bytes, String filename) async {
    try {
      _lastErrorMessage = null;
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final response = await _dio.post(
        '${ApiConstants.folders}/$folderId/cover-image',
        data: formData,
      );
      if (response.data['data'] != null) {
        return Folder.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      _extractError(e);
      return null;
    }
  }

  Future<bool> deleteFolder(String folderId) async {
    try {
      _lastErrorMessage = null;
      final response = await _dio.delete('${ApiConstants.folders}/$folderId');
      return response.statusCode == 200;
    } catch (e) {
      _extractError(e);
      return false;
    }
  }

  Future<bool> addSongToFolder(String folderId, String songId,
      {String? fromFolderId}) async {
    try {
      _lastErrorMessage = null;
      final data = <String, dynamic>{
        'song_id': songId,
      };
      if (fromFolderId != null && fromFolderId.isNotEmpty) {
        data['from_folder_id'] = fromFolderId;
      }
      final response = await _dio.post(
        '${ApiConstants.folders}/$folderId/songs',
        data: data,
      );
      return response.statusCode == 200;
    } catch (e) {
      _extractError(e);
      return false;
    }
  }

  Future<bool> removeSongFromFolder(String folderId, String songId) async {
    try {
      _lastErrorMessage = null;
      final response =
          await _dio.delete('${ApiConstants.folders}/$folderId/songs/$songId');
      return response.statusCode == 200;
    } catch (e) {
      _extractError(e);
      return false;
    }
  }
}

final apiService = ApiService();
