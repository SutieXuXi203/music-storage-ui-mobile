import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../models/song_model.dart';
import '../models/user_model.dart';
import '../models/folder_model.dart';

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
            _lastErrorMessage = (d['detail'] as List).map((i) => i['msg'] ?? i.toString()).join(', ');
            return;
          }
        }
        if (d['message'] != null) {
          _lastErrorMessage = d['message'].toString();
          return;
        }
      }
      _lastErrorMessage = e.message ?? 'Lỗi kết nối máy chủ (${res?.statusCode ?? 'network'})';
    } else {
      _lastErrorMessage = e.toString();
    }
  }

  // --- PLAYLISTS & FOLDERS ---
  Future<List<Playlist>> getPlaylists() async {
    try {
      _lastErrorMessage = null;
      final response = await _dio.get(ApiConstants.playlists);
      final List list = response.data['data'] ?? [];
      return list.map((item) => Playlist.fromJson(item)).toList();
    } catch (e) {
      _extractError(e);
      try {
        final response = await _dio.get(ApiConstants.folders);
        final List list = response.data['data'] ?? [];
        return list.map((item) => Playlist.fromJson(item)).toList();
      } catch (_) {}
      return [];
    }
  }

  Future<List<Playlist>> getFolders() => getPlaylists();

  Future<Playlist?> createPlaylist(String name) async {
    try {
      _lastErrorMessage = null;
      final response = await _dio.post(
        ApiConstants.playlists,
        data: {'name': name.trim()},
      );
      if (response.data['data'] != null) {
        return Playlist.fromJson(response.data['data']);
      }
      _lastErrorMessage = response.data['message'] ?? 'Không nhận được dữ liệu phản hồi';
      return null;
    } catch (e) {
      _extractError(e);
      try {
        final response = await _dio.post(
          ApiConstants.folders,
          data: {'name': name.trim()},
        );
        if (response.data['data'] != null) {
          _lastErrorMessage = null;
          return Playlist.fromJson(response.data['data']);
        }
      } catch (_) {}
      return null;
    }
  }

  Future<Playlist?> createFolder(String name) => createPlaylist(name);

  Future<Playlist?> getPlaylistDetails(String playlistId) async {
    try {
      _lastErrorMessage = null;
      final response = await _dio.get('${ApiConstants.playlists}/$playlistId');
      if (response.data['data'] != null) {
        return Playlist.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      _extractError(e);
      try {
        final response = await _dio.get('${ApiConstants.folders}/$playlistId');
        if (response.data['data'] != null) {
          _lastErrorMessage = null;
          return Playlist.fromJson(response.data['data']);
        }
      } catch (_) {}
      return null;
    }
  }

  Future<Playlist?> getFolderDetails(String folderId) => getPlaylistDetails(folderId);

  Future<bool> renamePlaylist(String playlistId, String newName) async {
    try {
      _lastErrorMessage = null;
      final response = await _dio.put(
        '${ApiConstants.playlists}/$playlistId',
        data: {'name': newName.trim()},
      );
      return response.statusCode == 200;
    } catch (e) {
      _extractError(e);
      try {
        final response = await _dio.put(
          '${ApiConstants.folders}/$playlistId',
          data: {'name': newName.trim()},
        );
        return response.statusCode == 200;
      } catch (_) {}
      return false;
    }
  }

  Future<bool> renameFolder(String folderId, String newName) => renamePlaylist(folderId, newName);

  Future<bool> deletePlaylist(String playlistId) async {
    try {
      _lastErrorMessage = null;
      final response = await _dio.delete('${ApiConstants.playlists}/$playlistId');
      return response.statusCode == 200;
    } catch (e) {
      _extractError(e);
      try {
        final response = await _dio.delete('${ApiConstants.folders}/$playlistId');
        return response.statusCode == 200;
      } catch (_) {}
      return false;
    }
  }

  Future<bool> deleteFolder(String folderId) => deletePlaylist(folderId);

  Future<bool> addSongToPlaylist(String playlistId, String songId, {String? fromPlaylistId}) async {
    try {
      _lastErrorMessage = null;
      final data = <String, dynamic>{
        'song_id': songId,
      };
      if (fromPlaylistId != null && fromPlaylistId.isNotEmpty) {
        data['from_playlist_id'] = fromPlaylistId;
        data['from_folder_id'] = fromPlaylistId;
      }
      final response = await _dio.post(
        '${ApiConstants.playlists}/$playlistId/songs',
        data: data,
      );
      return response.statusCode == 200;
    } catch (e) {
      _extractError(e);
      try {
        final data = <String, dynamic>{
          'song_id': songId,
        };
        if (fromPlaylistId != null && fromPlaylistId.isNotEmpty) {
          data['from_folder_id'] = fromPlaylistId;
        }
        final response = await _dio.post(
          '${ApiConstants.folders}/$playlistId/songs',
          data: data,
        );
        return response.statusCode == 200;
      } catch (_) {}
      return false;
    }
  }

  Future<bool> addSongToFolder(String folderId, String songId, {String? fromFolderId}) =>
      addSongToPlaylist(folderId, songId, fromPlaylistId: fromFolderId);

  Future<bool> removeSongFromPlaylist(String playlistId, String songId) async {
    try {
      _lastErrorMessage = null;
      final response = await _dio.delete('${ApiConstants.playlists}/$playlistId/songs/$songId');
      return response.statusCode == 200;
    } catch (e) {
      _extractError(e);
      try {
        final response = await _dio.delete('${ApiConstants.folders}/$playlistId/songs/$songId');
        return response.statusCode == 200;
      } catch (_) {}
      return false;
    }
  }

  Future<bool> removeSongFromFolder(String folderId, String songId) =>
      removeSongFromPlaylist(folderId, songId);

}

final apiService = ApiService();
