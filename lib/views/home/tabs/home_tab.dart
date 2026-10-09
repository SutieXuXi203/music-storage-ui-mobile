import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/folder_model.dart';
import '../../../models/song_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/folder_provider.dart';
import '../../../providers/song_provider.dart';
import '../../../services/audio_player_service.dart';
import '../../details/folder_detail_screen.dart';
import '../settings_screen.dart';

class HomeTab extends StatefulWidget {
  final VoidCallback? onNavigateToSearch;
  final VoidCallback onNavigateToLibrary;

  const HomeTab({
    super.key,
    this.onNavigateToSearch,
    required this.onNavigateToLibrary,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  void _showCreateFolderDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.getSurfaceElevated(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          side: BorderSide(color: AppTheme.getBorder(context), width: 0.8),
        ),
        title: Text(
          'Tạo thư mục mới',
          style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppTheme.getText(context)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đặt tên cho thư mục bài hát của bạn:',
              style: TextStyle(
                  color: AppTheme.getTextSecondary(context), fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              autofocus: true,
              style: TextStyle(color: AppTheme.getText(context), fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Ví dụ: Nhạc Acoustic, Lofi, EDM...',
                hintStyle: TextStyle(
                    color: AppTheme.getTextMuted(context), fontSize: 12.5),
                isDense: true,
                filled: true,
                fillColor: AppTheme.getSurface(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  borderSide: BorderSide(
                      color: AppTheme.getBorder(context), width: 0.8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hủy',
                style: TextStyle(
                    color: AppTheme.getTextSecondary(context), fontSize: 12.5)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.getText(context),
              foregroundColor: AppTheme.getBg(context),
            ),
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                final folderProv =
                    Provider.of<FolderProvider>(context, listen: false);
                final folder = await folderProv.createFolder(name);
                if (context.mounted) {
                  if (folder != null) {
                    AppTheme.showSnackBar(
                      context,
                      'Đã tạo thư mục "$name"',
                    );
                  } else {
                    AppTheme.showSnackBar(
                      context,
                      folderProv.errorMessage ??
                          'Tạo thư mục thất bại. Vui lòng thử lại!',
                      isError: true,
                    );
                  }
                }
              }
            },
            child: const Text('Tạo',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final songProvider = Provider.of<SongProvider>(context);
    final folderProvider = Provider.of<FolderProvider>(context);

    final user = authProvider.user;
    final userName =
        (user != null && user.fullName != null && user.fullName!.isNotEmpty)
            ? user.fullName!
            : (user != null && user.username.isNotEmpty
                ? user.username
                : 'Người dùng');
    final songs = songProvider.songs;
    final folders = folderProvider.folders;

    final recentSongs = songProvider.recentSongs;

    return Scaffold(
      backgroundColor: AppTheme.getBg(context),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              songProvider.fetchSongs(),
              folderProvider.fetchFolders(),
            ]);
          },
          color: AppTheme.getText(context),
          backgroundColor: AppTheme.getSurface(context),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MEOWSIC',
                        style: AppTheme.monoStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: AppTheme.getText(context),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppTheme.terminalGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'v1.0 / TRỰC TUYẾN',
                            style: AppTheme.monoStyle(
                              fontSize: 9.5,
                              color: AppTheme.getTextSecondary(context),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        children: [
                          BouncingIconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 34, minHeight: 34),
                            icon: Icon(
                              Icons.notifications_none_outlined,
                              size: 19,
                              color: AppTheme.getText(context),
                            ),
                            onPressed: () {
                              AppTheme.showSnackBar(
                                context,
                                'Hệ thống hoạt động bình thường // v1.0 TRỰC TUYẾN',
                                icon: Icons.info_outline_rounded,
                              );
                            },
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppTheme.terminalGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),
                      BouncingWidget(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SettingsScreen()),
                          );
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.getSurfaceElevated(context),
                            border: Border.all(
                              color: AppTheme.getBorder(context),
                              width: 1.0,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              userName.isNotEmpty
                                  ? userName[0].toUpperCase()
                                  : 'M',
                              style: TextStyle(
                                color: AppTheme.getText(context),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chào bạn,',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.getTextSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    userName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: AppTheme.getText(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${songs.length} bài hát đã được lưu trong kho nhạc của bạn.',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.getTextMuted(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildSectionHeader('Thư mục',
                  onSeeAll: widget.onNavigateToLibrary),
              const SizedBox(height: 8),
              if (folders.isEmpty)
                _buildEmptyFolderCard(context)
              else ...[
                ...folders
                    .take(4)
                    .map((folder) => _buildFolderTile(context, folder)),
                if (folders.length > 4)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Center(
                      child: TextButton(
                        onPressed: widget.onNavigateToLibrary,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Xem thêm ${folders.length - 4} thư mục trong Thư viện →',
                          style: AppTheme.monoStyle(
                            fontSize: 10.5,
                            color: AppTheme.getTextSecondary(context),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 22),
              _buildSectionHeader('Nghe gần đây',
                  onSeeAll: widget.onNavigateToLibrary),
              const SizedBox(height: 8),
              if (recentSongs.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'Chưa có bài hát nào gần đây',
                      style: TextStyle(
                          color: AppTheme.getTextMuted(context), fontSize: 12),
                    ),
                  ),
                )
              else
                ...recentSongs
                    .map((song) => _buildRecentSongTile(context, song)),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {required VoidCallback onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.getText(context),
          ),
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: Text(
            'Xem tất cả →',
            style: AppTheme.monoStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.getTextSecondary(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFolderTile(BuildContext context, Folder folder) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: AppTheme.getBorder(context),
          width: 0.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FolderDetailScreen(
                  folderId: folder.id,
                  initialName: folder.name,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.getSurfaceElevated(context),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(
                      color: AppTheme.getBorder(context),
                      width: 0.8,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: AppCoverImage(
                    url: folder.coverUrl,
                    width: 36,
                    height: 36,
                    borderRadius: AppTheme.radiusSm,
                    placeholderIcon: Icons.folder_outlined,
                    iconSize: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        folder.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.getText(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${folder.songCount} bài hát',
                        style: AppTheme.monoStyle(
                          fontSize: 10,
                          color: AppTheme.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppTheme.getSurfaceElevated(context),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(
                      color: AppTheme.getBorder(context),
                      width: 0.8,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 10,
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
  }

  Widget _buildEmptyFolderCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: AppTheme.getBorder(context),
          width: 0.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          onTap: () => _showCreateFolderDialog(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.getSurfaceElevated(context),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(
                      color: AppTheme.getBorder(context),
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    Icons.create_new_folder_outlined,
                    size: 18,
                    color: AppTheme.getText(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Chưa có thư mục nào',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.getText(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Nhấn để tạo thư mục lưu trữ bài hát đầu tiên',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.getTextMuted(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.add,
                  size: 18,
                  color: AppTheme.getText(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSongTile(BuildContext context, Song song) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: AppTheme.getBorder(context),
          width: 0.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          onTap: () {
            final songProv = Provider.of<SongProvider>(context, listen: false);
            final idx = songProv.songs.indexWhere((s) => s.id == song.id);
            audioPlayerService.setPlaylist(songProv.songs,
                initialIndex: idx >= 0 ? idx : 0);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.getSurfaceSubtle(context),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(
                      color: AppTheme.getBorder(context),
                      width: 0.8,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: AppCoverImage(
                    url: song.coverUrl,
                    width: 36,
                    height: 36,
                    borderRadius: AppTheme.radiusSm,
                    iconSize: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppTheme.getText(context),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Row(
                        children: [
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.getTextSecondary(context),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            song.formattedDuration,
                            style: AppTheme.monoStyle(
                              fontSize: 10,
                              color: AppTheme.getTextMuted(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.getBorder(context),
                      width: 1.0,
                    ),
                    color: Colors.transparent,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.play_arrow,
                      size: 16,
                      color: AppTheme.getText(context),
                    ),
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
