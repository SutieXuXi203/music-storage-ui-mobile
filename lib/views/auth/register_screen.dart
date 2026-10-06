import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reicon_flutter/reicon_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/re_icon.dart';
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

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('// USER_REGISTRATION', style: TextStyle(fontFamily: 'monospace', fontSize: 13)),
        leading: Center(
          child: TerminalActionBtn(
            onTap: () => Navigator.pop(context),
            hasBorder: false,
            padding: const EdgeInsets.all(6),
            defaultColor: AppTheme.textSecondary,
            hoverColor: AppTheme.terminalGreen,
            icon: ReIcon(Reicon.outline.arrowLeft, size: 16),
            label: 'BACK',
          ),
        ),
        leadingWidth: 70,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CREATE_USER_PROFILE',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  '> System will auto-create dedicated Google Drive folder based on full_name.',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 24),

                if (authProvider.errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
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

                // Username
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
                    hintText: 'Nhập tên đăng nhập...',
                  ),
                ),
                const SizedBox(height: 14),

                // Email
                const Text(
                  '> EMAIL:',
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
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'user@example.com',
                  ),
                ),
                const SizedBox(height: 14),

                // Full Name
                const Text(
                  '> FULL_NAME (DRIVE FOLDER):',
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
                  controller: _fullNameController,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Nguyen Van A (tên thư mục Drive)',
                  ),
                ),
                const SizedBox(height: 14),

                // Password
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
                    hintText: 'Tối thiểu 6 ký tự...',
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

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: TerminalActionBtn(
                    onTap: authProvider.isLoading
                        ? null
                        : () async {
                            final username = _usernameController.text.trim();
                            final email = _emailController.text.trim();
                            final fullName = _fullNameController.text.trim();
                            final password = _passwordController.text.trim();

                            if (username.isEmpty || email.isEmpty || password.isEmpty) return;

                            final success = await authProvider.register(
                              username: username,
                              email: email,
                              password: password,
                              fullName: fullName.isNotEmpty ? fullName : null,
                            );

                            if (!context.mounted) return;
                            if (success) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const HomeScreen()),
                                (route) => false,
                              );
                            }
                          },
                    defaultColor: AppTheme.textPrimary,
                    hoverColor: AppTheme.terminalGreen,
                    defaultBorderColor: AppTheme.textPrimary,
                    hoverBorderColor: AppTheme.terminalGreen,
                    icon: authProvider.isLoading
                        ? null
                        : ReIcon(Reicon.outline.plus, size: 16),
                    label: authProvider.isLoading ? '>>> CREATING ACCOUNT...' : 'INITIALIZE_ACCOUNT',
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
