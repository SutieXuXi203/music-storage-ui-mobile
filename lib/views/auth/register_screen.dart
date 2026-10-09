import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/song_provider.dart';
import '../../providers/folder_provider.dart';
import '../../core/theme/app_theme.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister(AuthProvider authProvider) async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final fullName = _fullNameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng nhập tên đăng nhập và mật khẩu')),
      );
      return;
    }

    if (username.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tên đăng nhập phải có tối thiểu 3 ký tự')),
      );
      return;
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Tên đăng nhập chỉ gồm chữ cái không dấu, chữ số và dấu gạch dưới (_)')),
      );
      return;
    }

    final hasLetters = RegExp(r'[A-Za-z]').hasMatch(password);
    final hasDigits = RegExp(r'[0-9]').hasMatch(password);
    if (password.length < 6 || !hasLetters || !hasDigits) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Mật khẩu phải từ 6 ký tự trở lên, bao gồm cả chữ cái và chữ số')),
      );
      return;
    }

    if (email.isNotEmpty &&
        !RegExp(r'^[\w\.\+\-]+@[a-zA-Z0-9_\.\-]+$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email không đúng định dạng hợp lệ')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final success = await authProvider.register(
      username: username,
      password: password,
      email: email.isNotEmpty ? email : '$username@drive.local',
      fullName: fullName.isNotEmpty ? fullName : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Provider.of<SongProvider>(context, listen: false).fetchSongs();
      Provider.of<FolderProvider>(context, listen: false).fetchFolders();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.getBg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.getBg(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: AppTheme.getText(context), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tạo tài khoản',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.getText(context),
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32.0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đăng ký thành viên',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.getText(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tạo tài khoản để đồng bộ nhạc cá nhân qua Google Drive.',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.getTextSecondary(context)),
                        ),
                        const SizedBox(height: 20),
                        if (authProvider.errorMessage != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: AppTheme.getDanger(context),
                                  width: 1.0),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSm),
                              color: AppTheme.getSurface(context),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline,
                                    size: 15,
                                    color: AppTheme.getDanger(context)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    authProvider.errorMessage!,
                                    style: TextStyle(
                                        color: AppTheme.getDanger(context),
                                        fontSize: 11.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        _buildInputField(
                          context,
                          controller: _fullNameController,
                          hint: 'Họ và tên (ví dụ: Mạnh Đình)',
                          icon: Icons.badge_outlined,
                        ),
                        const SizedBox(height: 10),
                        _buildInputField(
                          context,
                          controller: _usernameController,
                          hint: 'Tên đăng nhập (từ 3 ký tự, không dấu)',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 10),
                        _buildInputField(
                          context,
                          controller: _emailController,
                          hint: 'Email (tùy chọn, ví dụ: user@gmail.com)',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 10),
                        _buildInputField(
                          context,
                          controller: _passwordController,
                          hint: 'Mật khẩu (từ 6 ký tự, gồm cả chữ & số)',
                          icon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 18,
                              color: AppTheme.getTextMuted(context),
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.getAction(context),
                              foregroundColor: AppTheme.getActionText(context),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusSm),
                              ),
                            ),
                            onPressed: _isLoading
                                ? null
                                : () => _handleRegister(authProvider),
                            child: _isLoading
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.8,
                                      color: AppTheme.getActionText(context),
                                    ),
                                  )
                                : Text(
                                    'ĐĂNG KÝ',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                      color: AppTheme.getActionText(context),
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInputField(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Container(
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.getBorder(context), width: 1.0),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textAlignVertical: TextAlignVertical.center,
        style: TextStyle(fontSize: 13, color: AppTheme.getText(context)),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle:
              TextStyle(color: AppTheme.getTextMuted(context), fontSize: 12.5),
          prefixIcon:
              Icon(icon, size: 18, color: AppTheme.getTextSecondary(context)),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 42, minHeight: 44),
          suffixIcon: suffixIcon,
          suffixIconConstraints:
              const BoxConstraints(minWidth: 42, minHeight: 44),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.only(right: 12),
        ),
      ),
    );
  }
}
