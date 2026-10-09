import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/audio_player_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;

  AuthProvider() {
    checkAuth();
  }

  Future<void> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token != null) {
      _isLoading = true;
      notifyListeners();
      try {
        _user = await apiService.getMe();
      } catch (_) {
        _user = null;
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await apiService.login(username, password);
      if (res['access_token'] != null) {
        _user = await apiService.getMe();
        _user ??= User(
          id: 'user_id',
          username: username,
          email: '',
          fullName: username,
        );
        notifyListeners();
        return true;
      }
      _errorMessage = 'Đăng nhập không thành công.';
      return false;
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map &&
            data.containsKey('detail') &&
            data['detail'] is String) {
          _errorMessage = data['detail'];
          return false;
        }
      }
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          _errorMessage =
              'Hết thời gian kết nối đến máy chủ. Máy chủ có thể đang khởi động lại hoặc mạng yếu, vui lòng thử lại sau giây lát.';
          return false;
        }
      }
      if (e.toString().contains('401')) {
        _errorMessage = 'Tên đăng nhập hoặc mật khẩu không chính xác.';
      } else if (e.toString().contains('422')) {
        _errorMessage = 'Vui lòng nhập đầy đủ tên đăng nhập và mật khẩu.';
      } else {
        _errorMessage = 'Lỗi kết nối máy chủ ($e). Vui lòng thử lại.';
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String? fullName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await apiService.register(
        username: username,
        email: email,
        password: password,
        fullName: fullName,
      );
      return await login(username, password);
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data.containsKey('detail')) {
          final detail = data['detail'];
          if (detail is String) {
            _errorMessage = detail;
          } else if (detail is List && detail.isNotEmpty) {
            final firstErr = detail[0];
            if (firstErr is Map && firstErr.containsKey('msg')) {
              var msg = firstErr['msg'].toString();
              msg = msg.replaceFirst(RegExp(r'^Value error,\s*'), '');
              _errorMessage = msg;
            } else {
              _errorMessage = detail.first.toString();
            }
          } else {
            _errorMessage = 'Dữ liệu không hợp lệ (mã 422).';
          }
        } else {
          _errorMessage =
              'Đăng ký thất bại (${e.response?.statusCode ?? 'Lỗi mạng'}).';
        }
      } else {
        _errorMessage = 'Đăng ký thất bại. Vui lòng thử lại.';
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    try {
      final updated = await apiService.getMe();
      if (updated != null) {
        _user = updated;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> updateProfile({String? fullName, String? email}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final ok =
          await apiService.updateProfile(fullName: fullName, email: email);
      if (ok) {
        await refreshProfile();
        return true;
      }
      _errorMessage = 'Cập nhật thông tin không thành công';
      return false;
    } catch (e) {
      _errorMessage = 'Lỗi cập nhật: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await audioPlayerService.stopAndReset();
    await apiService.logout();
    _user = null;
    notifyListeners();
  }
}
