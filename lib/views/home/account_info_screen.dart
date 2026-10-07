import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/song_provider.dart';

class AccountInfoScreen extends StatefulWidget {
  const AccountInfoScreen({super.key});

  @override
  State<AccountInfoScreen> createState() => _AccountInfoScreenState();
}

class _AccountInfoScreenState extends State<AccountInfoScreen> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.refreshProfile();
    if (mounted) {
      setState(() => _isRefreshing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã đồng bộ thông tin tài khoản mới nhất',
            style: AppTheme.monoStyle(fontSize: 12),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: AppTheme.getSurfaceElevated(context),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _copyToClipboard(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã sao chép $label vào bộ nhớ tạm',
          style: AppTheme.monoStyle(fontSize: 12),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.getSurfaceElevated(context),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showEditProfileDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    final nameController = TextEditingController(text: user?.fullName ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.getSurface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.getBorder(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'CHỈNH SỬA THÔNG TIN',
                  style: AppTheme.monoStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppTheme.getText(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cập nhật họ tên và địa chỉ email tài khoản của bạn',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppTheme.getTextSecondary(context),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Họ và tên',
                  style: AppTheme.monoStyle(
                    fontSize: 11,
                    color: AppTheme.getTextSecondary(context),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  style: TextStyle(fontSize: 13, color: AppTheme.getText(context)),
                  decoration: InputDecoration(
                    hintText: 'Nhập họ và tên...',
                    hintStyle: TextStyle(color: AppTheme.getTextMuted(context), fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: AppTheme.getSurfaceElevated(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      borderSide: BorderSide(color: AppTheme.getBorder(context), width: 0.8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      borderSide: BorderSide(color: AppTheme.getBorder(context), width: 0.8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      borderSide: BorderSide(color: AppTheme.getText(context), width: 1.0),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Email',
                  style: AppTheme.monoStyle(
                    fontSize: 11,
                    color: AppTheme.getTextSecondary(context),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(fontSize: 13, color: AppTheme.getText(context)),
                  decoration: InputDecoration(
                    hintText: 'Nhập địa chỉ email...',
                    hintStyle: TextStyle(color: AppTheme.getTextMuted(context), fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: AppTheme.getSurfaceElevated(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      borderSide: BorderSide(color: AppTheme.getBorder(context), width: 0.8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      borderSide: BorderSide(color: AppTheme.getBorder(context), width: 0.8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      borderSide: BorderSide(color: AppTheme.getText(context), width: 1.0),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: AppTheme.getBorder(context), width: 0.8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          ),
                        ),
                        onPressed: isSaving ? null : () => Navigator.pop(ctx),
                        child: Text(
                          'Hủy',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.getTextSecondary(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: AppTheme.getText(context),
                          foregroundColor: AppTheme.getBg(context),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          ),
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                setModalState(() => isSaving = true);
                                final ok = await authProvider.updateProfile(
                                  fullName: nameController.text.trim(),
                                  email: emailController.text.trim(),
                                );
                                if (!ctx.mounted) return;
                                Navigator.pop(ctx);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ok ? 'Đã cập nhật thông tin thành công' : 'Cập nhật thất bại',
                                      style: AppTheme.monoStyle(fontSize: 12),
                                    ),
                                    duration: const Duration(seconds: 2),
                                    backgroundColor: AppTheme.getSurfaceElevated(context),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                        child: isSaving
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.getBg(context),
                                ),
                              )
                            : Text(
                                'Lưu thay đổi',
                                style: AppTheme.monoStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _exportJson(Map<String, dynamic> data) {
    final buffer = StringBuffer('{\n');
    data.forEach((key, value) {
      buffer.writeln('  "$key": "$value",');
    });
    buffer.write('}');
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã sao chép toàn bộ thông tin tài khoản dạng JSON',
          style: AppTheme.monoStyle(fontSize: 12),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.getSurfaceElevated(context),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Không xác định';
    final local = dt.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute:$second';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final songProvider = Provider.of<SongProvider>(context);
    final user = authProvider.user;

    final displayName = (user != null && user.fullName != null && user.fullName!.isNotEmpty)
        ? user.fullName!
        : (user != null && user.username.isNotEmpty ? user.username : 'Mạnh Đình');
    final username = user?.username ?? 'user_dev';
    final email = (user != null && user.email.isNotEmpty) ? user.email : 'email@example.com';
    final userId = (user != null && user.id.isNotEmpty) ? user.id : 'N/A';
    final driveFolderId = (user != null && user.driveFolderId != null && user.driveFolderId!.isNotEmpty)
        ? user.driveFolderId!
        : 'N/A';
    final driveFolderName = user?.driveFolderName ?? user?.fullName ?? user?.username ?? 'My Music Folder';
    final isActive = user?.isActive ?? true;
    final createdAtStr = _formatDate(user?.createdAt);
    final songCount = songProvider.songs.length;

    return Scaffold(
      backgroundColor: AppTheme.getBg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.getBg(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.getText(context), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Thông tin tài khoản',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.getText(context),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: _isRefreshing
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.getText(context),
                    ),
                  )
                : Icon(Icons.refresh, color: AppTheme.getText(context), size: 20),
            onPressed: _isRefreshing ? null : _handleRefresh,
          ),
          IconButton(
            tooltip: 'Chỉnh sửa',
            icon: Icon(Icons.edit_outlined, color: AppTheme.getText(context), size: 20),
            onPressed: _showEditProfileDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // 1. Profile Hero Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.getSurface(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: AppTheme.getBorder(context), width: 0.8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.getSurfaceElevated(context),
                          border: Border.all(color: AppTheme.getBorder(context), width: 1.0),
                        ),
                        child: Center(
                          child: Text(
                            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                            style: TextStyle(
                              color: AppTheme.getText(context),
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.getText(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '@$username',
                              style: AppTheme.monoStyle(
                                fontSize: 12,
                                color: AppTheme.getTextSecondary(context),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppTheme.getTextMuted(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Badges Row
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildTag(
                        context,
                        label: 'STATUS: ${isActive ? 'ACTIVE' : 'INACTIVE'}',
                        isHighlighted: isActive,
                      ),
                      _buildTag(
                        context,
                        label: 'TIER: PREMIUM',
                        isHighlighted: false,
                      ),
                      _buildTag(
                        context,
                        label: 'ROLE: OWNER',
                        isHighlighted: false,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. Section: Định danh tài khoản (Identity)
            _buildSectionHeader('Định danh & Thông tin cá nhân'),
            _buildDetailCard(
              context,
              children: [
                _buildInfoRow(
                  context,
                  label: 'User ID',
                  value: userId,
                  isMonospace: true,
                  onCopy: userId != 'N/A' ? () => _copyToClipboard('User ID', userId) : null,
                ),
                _buildDivider(context),
                _buildInfoRow(
                  context,
                  label: 'Tên đăng nhập',
                  value: username,
                  isMonospace: true,
                ),
                _buildDivider(context),
                _buildInfoRow(
                  context,
                  label: 'Họ và tên',
                  value: displayName,
                  trailingBadge: 'EDIT',
                  onBadgeTap: _showEditProfileDialog,
                ),
                _buildDivider(context),
                _buildInfoRow(
                  context,
                  label: 'Email',
                  value: email,
                  trailingBadge: 'VERIFIED',
                ),
                _buildDivider(context),
                _buildInfoRow(
                  context,
                  label: 'Trạng thái',
                  value: isActive ? 'Hoạt động (Active)' : 'Vô hiệu hóa (Inactive)',
                  statusColor: isActive ? null : AppTheme.getDanger(context),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // 3. Section: Google Drive & Cloud Storage
            _buildSectionHeader('Lưu trữ đám mây & Google Drive'),
            _buildDetailCard(
              context,
              children: [
                _buildInfoRow(
                  context,
                  label: 'Nhà cung cấp',
                  value: 'Google Drive API v3',
                ),
                _buildDivider(context),
                _buildInfoRow(
                  context,
                  label: 'Thư mục Drive',
                  value: driveFolderName,
                  isMonospace: true,
                ),
                _buildDivider(context),
                _buildInfoRow(
                  context,
                  label: 'Mã thư mục (Folder ID)',
                  value: driveFolderId,
                  isMonospace: true,
                  onCopy: driveFolderId != 'N/A' ? () => _copyToClipboard('Folder ID', driveFolderId) : null,
                ),
                _buildDivider(context),
                _buildInfoRow(
                  context,
                  label: 'Trạng thái đồng bộ',
                  value: driveFolderId != 'N/A' ? 'Đã kết nối (Synchronized)' : 'Chưa liên kết',
                ),
              ],
            ),

            const SizedBox(height: 18),

            // 4. Section: Thống kê & Hệ thống (System & Stats)
            _buildSectionHeader('Hệ thống & Thống kê'),
            _buildDetailCard(
              context,
              children: [
                _buildInfoRow(
                  context,
                  label: 'Thời điểm tạo',
                  value: createdAtStr,
                  isMonospace: true,
                ),
                _buildDivider(context),
                _buildInfoRow(
                  context,
                  label: 'Số bài hát trong thư viện',
                  value: '$songCount bài hát',
                  isMonospace: true,
                ),
                _buildDivider(context),
                _buildInfoRow(
                  context,
                  label: 'Cơ chế xác thực',
                  value: 'OAuth2 JWT Bearer',
                  isMonospace: true,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 5. Actions Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      backgroundColor: AppTheme.getSurface(context),
                      side: BorderSide(color: AppTheme.getBorder(context), width: 0.8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                    ),
                    icon: Icon(Icons.code, size: 16, color: AppTheme.getText(context)),
                    label: Text(
                      'Sao chép JSON',
                      style: AppTheme.monoStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getText(context),
                      ),
                    ),
                    onPressed: () => _exportJson({
                      'id': userId,
                      'username': username,
                      'email': email,
                      'full_name': displayName,
                      'drive_folder_id': driveFolderId,
                      'drive_folder_name': driveFolderName,
                      'is_active': isActive,
                      'created_at': createdAtStr,
                      'total_songs': songCount,
                    }),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      backgroundColor: AppTheme.getText(context),
                      foregroundColor: AppTheme.getBg(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                    ),
                    icon: Icon(Icons.edit, size: 16, color: AppTheme.getBg(context)),
                    label: Text(
                      'Cập nhật hồ sơ',
                      style: AppTheme.monoStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: _showEditProfileDialog,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
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

  Widget _buildDetailCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.getBorder(context), width: 0.8),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
    bool isMonospace = false,
    Color? statusColor,
    String? trailingBadge,
    VoidCallback? onBadgeTap,
    VoidCallback? onCopy,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.getTextSecondary(context),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    style: isMonospace
                        ? AppTheme.monoStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: statusColor ?? AppTheme.getText(context),
                          )
                        : TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: statusColor ?? AppTheme.getText(context),
                          ),
                  ),
                ),
                if (trailingBadge != null) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: onBadgeTap,
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.getSurfaceElevated(context),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.getBorder(context), width: 0.8),
                      ),
                      child: Text(
                        trailingBadge,
                        style: AppTheme.monoStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.getText(context),
                        ),
                      ),
                    ),
                  ),
                ],
                if (onCopy != null) ...[
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: onCopy,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.copy,
                        size: 13,
                        color: AppTheme.getTextMuted(context),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.6,
      color: AppTheme.getBorder(context),
    );
  }

  Widget _buildTag(BuildContext context, {required String label, required bool isHighlighted}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isHighlighted ? AppTheme.getSurfaceElevated(context) : AppTheme.getSurfaceSubtle(context),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isHighlighted ? AppTheme.getText(context).withValues(alpha: 0.4) : AppTheme.getBorder(context),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: AppTheme.monoStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: AppTheme.getText(context),
        ),
      ),
    );
  }
}
