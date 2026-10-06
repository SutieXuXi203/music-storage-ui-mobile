import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

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
        // Fallback tạo user tạm thời nếu getMe chưa kịp trả về
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
      if (e.toString().contains('401')) {
        _errorMessage = 'Tên đăng nhập hoặc mật khẩu không chính xác.';
      } else if (e.toString().contains('422')) {
        _errorMessage = 'Vui lòng nhập đầy đủ tên đăng nhập và mật khẩu.';
      } else {
        _errorMessage = 'Lỗi kết nối máy chủ ($e). Vui lòng kiểm tra lại backend.';
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
      // Đăng nhập luôn sau khi đăng ký
      return await login(username, password);
    } catch (e) {
      _errorMessage = 'Đăng ký thất bại. Vui lòng thử lại.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await apiService.logout();
    _user = null;
    notifyListeners();
  }
}
