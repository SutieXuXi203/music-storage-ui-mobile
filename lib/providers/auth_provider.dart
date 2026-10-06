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
        return true;
      }
      _errorMessage = 'Đăng nhập không thành công.';
      return false;
    } catch (e) {
      _errorMessage = 'Tên đăng nhập hoặc mật khẩu không chính xác.';
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
