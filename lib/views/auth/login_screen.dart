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

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Terminal ASCII Style
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

                // Error box
                if (authProvider.errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: const BoxDecoration(
                      border: Border.fromBorderSide(BorderSide(color: AppTheme.error, width: 1)),
                      borderRadius: BorderRadius.zero,
                      color: AppTheme.surface,
                    ),
                    child: Text(
                      '> ERROR: ${authProvider.errorMessage!}',
                      style: const TextStyle(fontFamily: 'monospace', color: AppTheme.error, fontSize: 12),
                    ),
                  ),

                // Input user
                TextField(
                  controller: _usernameController,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  decoration: const InputDecoration(
                    prefixText: '> username: ',
                    prefixStyle: TextStyle(fontFamily: 'monospace', color: AppTheme.textSecondary),
                    hintText: 'sutie',
                  ),
                ),
                const SizedBox(height: 14),

                // Input password
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  decoration: InputDecoration(
                    prefixText: '> password: ',
                    prefixStyle: const TextStyle(fontFamily: 'monospace', color: AppTheme.textSecondary),
                    hintText: '••••••••',
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

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: TerminalActionBtn(
                    onTap: authProvider.isLoading
                        ? null
                        : () async {
                            final username = _usernameController.text.trim();
                            final password = _passwordController.text.trim();
                            if (username.isEmpty || password.isEmpty) return;

                            final success = await authProvider.login(username, password);
                            if (!mounted) return;
                            if (success) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const HomeScreen()),
                              );
                            }
                          },
                    defaultColor: AppTheme.textPrimary,
                    hoverColor: AppTheme.terminalGreen,
                    defaultBorderColor: AppTheme.textPrimary,
                    hoverBorderColor: AppTheme.terminalGreen,
                    icon: authProvider.isLoading
                        ? null
                        : ReIcon(Reicon.outline.arrowRight, size: 16),
                    label: authProvider.isLoading ? '>>> AUTHENTICATING...' : 'ENTER_SYSTEM',
                  ),
                ),
                const SizedBox(height: 20),

                // Link đăng ký
                Center(
                  child: TerminalActionBtn(
                    hasBorder: false,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
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
    );
  }
}
