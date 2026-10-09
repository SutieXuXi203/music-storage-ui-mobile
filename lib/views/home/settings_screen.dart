import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/song_provider.dart';
import '../../providers/folder_provider.dart';
import '../auth/login_screen.dart';
import 'account_info_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final user = authProvider.user;

    final displayName =
        (user != null && user.fullName != null && user.fullName!.isNotEmpty)
            ? user.fullName!
            : (user != null && user.username.isNotEmpty
                ? user.username
                : 'Người dùng');
    final email = (user != null && user.email.isNotEmpty)
        ? user.email
        : 'email@example.com';

    return Scaffold(
      backgroundColor: AppTheme.getBg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.getBg(context),
        elevation: 0,
        leading: BouncingIconButton(
          icon: Icon(Icons.arrow_back,
              color: AppTheme.getText(context), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Cài đặt',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.getText(context),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AccountInfoScreen()),
                );
              },
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.getSurface(context),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(
                      color: AppTheme.getBorder(context), width: 0.8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.getSurfaceElevated(context),
                        border: Border.all(
                            color: AppTheme.getBorder(context), width: 1.0),
                      ),
                      child: Center(
                        child: Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : 'M',
                          style: TextStyle(
                            color: AppTheme.getText(context),
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.getText(context),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppTheme.getTextSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppTheme.getTextMuted(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            _buildSectionHeader('Giao diện'),
            _buildSelectTile<ThemeMode>(
              icon: Icons.brightness_medium_outlined,
              title: 'Chủ đề',
              currentValue: settingsProvider.themeMode,
              currentLabel: settingsProvider.themeMode == ThemeMode.dark
                  ? 'Dark'
                  : 'Light',
              items: const [
                MapEntry(ThemeMode.dark, 'Dark'),
                MapEntry(ThemeMode.light, 'Light'),
              ],
              onChanged: (mode) => settingsProvider.setThemeMode(mode),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 40,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppTheme.getSurface(context),
                  foregroundColor: AppTheme.getDanger(context),
                  side: BorderSide(
                      color: AppTheme.getBorder(context), width: 0.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                ),
                onPressed: () {
                  authProvider.logout();
                  Provider.of<SongProvider>(context, listen: false).clear();
                  Provider.of<FolderProvider>(context, listen: false).clear();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: Text(
                  'Đăng xuất',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getDanger(context),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.getTextSecondary(context),
        ),
      ),
    );
  }

  Widget _buildSelectTile<T>({
    IconData? icon,
    required String title,
    required T currentValue,
    required String currentLabel,
    required List<MapEntry<T, String>> items,
    required ValueChanged<T> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.getBorder(context), width: 0.8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: AppTheme.getTextSecondary(context)),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.getText(context),
                ),
              ),
            ],
          ),
          PopupMenuButton<T>(
            tooltip: '',
            color: AppTheme.getSurfaceElevated(context),
            surfaceTintColor: Colors.transparent,
            elevation: 4,
            shadowColor: Colors.black.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              side: BorderSide(color: AppTheme.getBorder(context), width: 1.0),
            ),
            position: PopupMenuPosition.under,
            onSelected: onChanged,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
              decoration: BoxDecoration(
                color: AppTheme.getSurfaceSubtle(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border:
                    Border.all(color: AppTheme.getBorder(context), width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentLabel,
                    style: AppTheme.monoStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getText(context),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 14,
                    color: AppTheme.getTextSecondary(context),
                  ),
                ],
              ),
            ),
            itemBuilder: (ctx) => items.map((entry) {
              final isSelected = entry.key == currentValue;
              return PopupMenuItem<T>(
                value: entry.key,
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.value,
                      style: AppTheme.monoStyle(
                        fontSize: 11.5,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? AppTheme.getText(context)
                            : AppTheme.getTextSecondary(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (isSelected)
                      Icon(Icons.check,
                          size: 14, color: AppTheme.getText(context)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
