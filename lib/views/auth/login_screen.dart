import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reicon_flutter/reicon_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/re_icon.dart';
import '../home/home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoggingIn = false;
  bool _loginSuccess = false;

  late AnimationController _entryController;
  late AnimationController _shakeController;
  late AnimationController _cursorBlinkController;
  String? _lastErrorMessage;

  @override
  void initState() {
    super.initState();
    // Animation xuất hiện mượt mà đồng bộ kiểu Apple/macOS
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _entryController.forward();

    // Animation rung lắc (shake) nhẹ khi gặp lỗi đăng nhập
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Con trỏ nhấp nháy phong cách terminal
    _cursorBlinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _entryController.dispose();
    _shakeController.dispose();
    _cursorBlinkController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(AuthProvider authProvider) async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (username.isEmpty || password.isEmpty) {
      _shakeController.forward(from: 0.0);
      return;
    }

    setState(() {
      _isLoggingIn = true;
      _loginSuccess = false;
    });

    final success = await authProvider.login(username, password);
    if (!mounted) return;

    if (success) {
      setState(() {
        _isLoggingIn = false;
        _loginSuccess = true;
      });

      // Cho phép người dùng trải nghiệm xác thực thành công ACCESS_GRANTED mượt mà
      await Future.delayed(const Duration(milliseconds: 380));
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, anim, __) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) {
            final curve = CurvedAnimation(parent: anim, curve: Curves.easeInOutCubic);
            return FadeTransition(
              opacity: curve,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(curve),
                child: child,
              ),
            );
          },
        ),
      );
    } else {
      setState(() {
        _isLoggingIn = false;
        _loginSuccess = false;
      });
      _shakeController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Kích hoạt hiệu ứng rung lắc nếu có thông báo lỗi mới
    if (authProvider.errorMessage != null && authProvider.errorMessage != _lastErrorMessage) {
      _lastErrorMessage = authProvider.errorMessage;
      _shakeController.forward(from: 0.0);
    } else if (authProvider.errorMessage == null) {
      _lastErrorMessage = null;
    }

    final pageFadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    final pageSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutQuart,
    ));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: FadeTransition(
              opacity: pageFadeAnim,
              child: SlideTransition(
                position: pageSlideAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header Terminal ASCII Style
                    const Text(
                      '// TERMINAL_AUTH_v1.0',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: AppTheme.terminalGreen,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'MUSIC_STORAGE',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '> System authorization required to access Drive audio storage.',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 32),

                    // Error box với hiệu ứng mở rộng mượt mà & rung lắc nhẹ (Decaying Sine Shake)
                    AnimatedSize(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      child: authProvider.errorMessage == null
                          ? const SizedBox.shrink()
                          : AnimatedBuilder(
                              animation: _shakeController,
                              builder: (context, child) {
                                final decay = 1.0 - _shakeController.value;
                                final offset = math.sin(_shakeController.value * math.pi * 5) * 6 * decay;
                                return Transform.translate(
                                  offset: Offset(offset, 0),
                                  child: child,
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: const BoxDecoration(
                                  border: Border.fromBorderSide(BorderSide(color: AppTheme.error, width: 1)),
                                  borderRadius: BorderRadius.zero,
                                  color: AppTheme.surface,
                                ),
                                child: Row(
                                  children: [
                                    ReIcon(Reicon.outline.infoCircle, size: 14, color: AppTheme.error),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '> ERROR: ${authProvider.errorMessage!}',
                                        style: const TextStyle(fontFamily: 'monospace', color: AppTheme.error, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),

                    // Label & Input username
                    const Text(
                      '> USERNAME:',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.terminalGreen,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _usernameController,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Nhập tên đăng nhập (ví dụ: sutie)...',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Label & Input password
                    const Text(
                      '> PASSWORD:',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.terminalGreen,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Nhập mật khẩu...',
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: TerminalActionBtn(
                            hasBorder: false,
                            padding: const EdgeInsets.all(6),
                            defaultColor: AppTheme.textMuted,
                            hoverColor: AppTheme.textPrimary,
                            icon: ReIcon(
                              _obscurePassword ? Reicon.outline.eyeClosed : Reicon.outline.eye,
                              size: 16,
                            ),
                            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button với phản hồi hoạt ảnh mượt mà
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: AnimatedBuilder(
                        animation: _cursorBlinkController,
                        builder: (context, _) {
                          final cursorVisible = _cursorBlinkController.value > 0.4;
                          final isBusy = _isLoggingIn || authProvider.isLoading;

                          Widget iconWidget;
                          String labelText;
                          Color btnColor;
                          Color borderColor;

                          if (_loginSuccess) {
                            iconWidget = ReIcon(Reicon.outline.tickCircle, size: 16, color: AppTheme.terminalGreen);
                            labelText = '>>> [ ACCESS_GRANTED ] // DECRYPTING...';
                            btnColor = AppTheme.terminalGreen;
                            borderColor = AppTheme.terminalGreen;
                          } else if (isBusy) {
                            iconWidget = const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 1.6, color: AppTheme.terminalGreen),
                            );
                            labelText = cursorVisible ? '>>> AUTHENTICATING [ █ ]' : '>>> AUTHENTICATING [   ]';
                            btnColor = AppTheme.terminalGreen;
                            borderColor = AppTheme.terminalGreen;
                          } else {
                            iconWidget = ReIcon(Reicon.outline.arrowRight, size: 16);
                            labelText = 'ENTER_SYSTEM';
                            btnColor = AppTheme.textPrimary;
                            borderColor = AppTheme.textPrimary;
                          }

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            decoration: BoxDecoration(
                              boxShadow: _loginSuccess
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.terminalGreen.withValues(alpha: 0.25),
                                        blurRadius: 14,
                                        spreadRadius: 1,
                                      )
                                    ]
                                  : null,
                            ),
                            child: TerminalActionBtn(
                              onTap: (isBusy || _loginSuccess)
                                  ? null
                                  : () => _handleLogin(authProvider),
                              defaultColor: btnColor,
                              hoverColor: AppTheme.terminalGreen,
                              defaultBorderColor: borderColor,
                              hoverBorderColor: AppTheme.terminalGreen,
                              icon: iconWidget,
                              label: labelText,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Link đăng ký
                    Center(
                      child: TerminalActionBtn(
                        hasBorder: false,
                        onTap: () {
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              transitionDuration: const Duration(milliseconds: 350),
                              pageBuilder: (_, __, ___) => const RegisterScreen(),
                              transitionsBuilder: (_, anim, __, child) {
                                return SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(1.0, 0.0),
                                    end: Offset.zero,
                                  ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                        defaultColor: AppTheme.textSecondary,
                        hoverColor: AppTheme.terminalGreen,
                        icon: ReIcon(Reicon.outline.plus, size: 14),
                        label: 'CREATE_NEW_ACCOUNT [REGISTER]',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
