import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/song_provider.dart';
import '../../providers/folder_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/isometric_cubes_widget.dart';
import '../home/home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoggingIn = false;

  late AnimationController _entryController;
  late AnimationController _shakeController;
  String? _lastErrorMessage;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _entryController.forward();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _entryController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(AuthProvider authProvider) async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (username.isEmpty || password.isEmpty) {
      _shakeController.forward(from: 0.0);
      return;
    }

    setState(() => _isLoggingIn = true);

    final success = await authProvider.login(username, password);
    if (!mounted) return;

    if (success) {
      setState(() => _isLoggingIn = false);
      Provider.of<SongProvider>(context, listen: false).fetchSongs();
      Provider.of<FolderProvider>(context, listen: false).fetchFolders();
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, anim, __) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) {
            return FadeTransition(opacity: anim, child: child);
          },
        ),
      );
    } else {
      setState(() => _isLoggingIn = false);
      _shakeController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.errorMessage != null &&
        authProvider.errorMessage != _lastErrorMessage) {
      _lastErrorMessage = authProvider.errorMessage;
      _shakeController.forward(from: 0.0);
    } else if (authProvider.errorMessage == null) {
      _lastErrorMessage = null;
    }

    return Scaffold(
      backgroundColor: AppTheme.getBg(context),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: math.max(0, constraints.maxHeight - 40.0),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '///',
                          style: AppTheme.monoStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.getTextMuted(context),
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'MEOWSIC',
                          style: AppTheme.monoStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: AppTheme.getText(context),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Your music. Your drive.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.getTextSecondary(context),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 22),
                        IsometricCubesWidget(
                          size: 105,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.getSurface(context),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSm),
                            border: Border.all(
                                color: AppTheme.getBorder(context), width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '◈',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.getTextSecondary(context),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'System authorization required to access Drive audio storage.',
                                  textAlign: TextAlign.center,
                                  style: AppTheme.monoStyle(
                                    fontSize: 9.5,
                                    color: AppTheme.getTextSecondary(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (authProvider.errorMessage != null)
                          AnimatedBuilder(
                            animation: _shakeController,
                            builder: (context, child) {
                              final decay = 1.0 - _shakeController.value;
                              final offset = math.sin(
                                      _shakeController.value * math.pi * 4) *
                                  4 *
                                  decay;
                              return Transform.translate(
                                offset: Offset(offset, 0),
                                child: child,
                              );
                            },
                            child: Container(
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
                          ),
                        Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppTheme.getSurface(context),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSm),
                            border: Border.all(
                                color: AppTheme.getBorder(context), width: 1.0),
                          ),
                          child: TextField(
                            controller: _usernameController,
                            textAlignVertical: TextAlignVertical.center,
                            style: TextStyle(
                                fontSize: 13, color: AppTheme.getText(context)),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'Tên đăng nhập hoặc email',
                              hintStyle: TextStyle(
                                  color: AppTheme.getTextMuted(context),
                                  fontSize: 12.5),
                              prefixIcon: Icon(Icons.person_outline,
                                  size: 18,
                                  color: AppTheme.getTextSecondary(context)),
                              prefixIconConstraints: const BoxConstraints(
                                  minWidth: 42, minHeight: 44),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.only(right: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppTheme.getSurface(context),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSm),
                            border: Border.all(
                                color: AppTheme.getBorder(context), width: 1.0),
                          ),
                          child: TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textAlignVertical: TextAlignVertical.center,
                            style: TextStyle(
                                fontSize: 13, color: AppTheme.getText(context)),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'Mật khẩu',
                              hintStyle: TextStyle(
                                  color: AppTheme.getTextMuted(context),
                                  fontSize: 12.5),
                              prefixIcon: Icon(Icons.lock_outline,
                                  size: 18,
                                  color: AppTheme.getTextSecondary(context)),
                              prefixIconConstraints: const BoxConstraints(
                                  minWidth: 42, minHeight: 44),
                              suffixIcon: BouncingIconButton(
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
                              suffixIconConstraints: const BoxConstraints(
                                  minWidth: 42, minHeight: 44),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
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
                            onPressed: _isLoggingIn
                                ? null
                                : () => _handleLogin(authProvider),
                            child: _isLoggingIn
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.8,
                                      color: AppTheme.getActionText(context),
                                    ),
                                  )
                                : Text(
                                    '→ ĐĂNG NHẬP',
                                    style: AppTheme.monoStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: AppTheme.getActionText(context),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RegisterScreen()),
                            );
                          },
                          child: Text(
                            '+ ĐĂNG KÝ TÀI KHOẢN MỚI',
                            style: AppTheme.monoStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              color: AppTheme.getTextSecondary(context),
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
}
