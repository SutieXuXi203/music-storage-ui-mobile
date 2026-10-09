import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/folder_model.dart';
import '../../models/song_model.dart';
import '../../providers/folder_provider.dart';
import '../../providers/song_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/audio_player_service.dart';
import 'song_detail_screen.dart';
import '../player/now_playing_screen.dart';
import '../../widgets/mini_player_widget.dart';

class FolderDetailScreen extends StatefulWidget {
  final String folderId;
  final String initialName;

  const FolderDetailScreen({
    super.key,
    required this.folderId,
    required this.initialName,
  });

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  void _openNowPlaying(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.6),
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, anim, secAnim) =>
            NowPlayingScreen(playerService: audioPlayerService),
        transitionsBuilder: (context, anim, secAnim, child) {
          final curved =
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1.0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FolderProvider>(context, listen: false)
          .fetchFolderDetails(widget.folderId);
    });
  }

  void _showRenameDialog(Folder folder) {
    final controller = TextEditingController(text: folder.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.getSurfaceElevated(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          side: BorderSide(color: AppTheme.getBorder(context), width: 0.8),
        ),
        title: Text(
          'Đổi tên thư mục',
          style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppTheme.getText(context)),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: AppTheme.getText(context), fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Nhập tên mới...',
            hintStyle:
                TextStyle(color: AppTheme.getTextMuted(context), fontSize: 13),
            isDense: true,
            filled: true,
            fillColor: AppTheme.getSurface(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              borderSide:
                  BorderSide(color: AppTheme.getBorder(context), width: 0.8),
            ),
          ),
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
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(ctx);
                final folderProv =
                    Provider.of<FolderProvider>(context, listen: false);
                await folderProv.renameFolder(folder.id, newName);
              }
            },
            child: const Text('Lưu',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFolder(Folder folder) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.getSurfaceElevated(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          side: BorderSide(color: AppTheme.getBorder(context), width: 0.8),
        ),
        title: Text(
          'Xóa thư mục?',
          style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppTheme.getText(context)),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa thư mục "${folder.name}"? Các bài hát bên trong vẫn sẽ được giữ an toàn trong kho nhạc của bạn.',
          style: TextStyle(
              color: AppTheme.getTextSecondary(context), fontSize: 12.5),
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
              backgroundColor: AppTheme.getDanger(context),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final folderProv =
                  Provider.of<FolderProvider>(context, listen: false);
              final ok = await folderProv.deleteFolder(folder.id);
              if (mounted && ok) {
                Navigator.pop(context);
                AppTheme.showSnackBar(
                  context,
                  'Đã xóa thư mục "${folder.name}"',
                );
              }
            },
            child: const Text('Xóa',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showChangeCoverDialog(Folder folder) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.getSurfaceElevated(context),
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusSheet)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color:
                        AppTheme.getTextMuted(context).withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                ),
              ),
              Text(
                'Ảnh bìa thư mục "${folder.name}"',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.getText(context),
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.getSurface(context),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(
                        color: AppTheme.getBorder(context), width: 0.8),
                  ),
                  child: Icon(Icons.photo_library_outlined,
                      size: 18, color: AppTheme.getText(context)),
                ),
                title: Text(
                  'Chọn ảnh từ thiết bị',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getText(context)),
                ),
                subtitle: Text(
                  'Tải lên ảnh từ thư viện của máy',
                  style: TextStyle(
                      fontSize: 11, color: AppTheme.getTextSecondary(context)),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final folderProv =
                      Provider.of<FolderProvider>(context, listen: false);
                  try {
                    final picker = ImagePicker();
                    final XFile? file = await picker.pickImage(
                        source: ImageSource.gallery, imageQuality: 85);
                    if (file != null) {
                      final bytes = await file.readAsBytes();
                      final ok = await folderProv.uploadFolderCoverImage(
                          folder.id, bytes, file.name);
                      if (mounted) {
                        AppTheme.showSnackBar(
                          context,
                          ok
                              ? 'Đã cập nhật ảnh bìa thư mục'
                              : 'Không thể cập nhật ảnh bìa',
                          isError: !ok,
                        );
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      AppTheme.showSnackBar(
                        context,
                        'Lỗi chọn ảnh: $e',
                        isError: true,
                      );
                    }
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.getSurface(context),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(
                        color: AppTheme.getBorder(context), width: 0.8),
                  ),
                  child: Icon(Icons.link_outlined,
                      size: 18, color: AppTheme.getText(context)),
                ),
                title: Text(
                  'Nhập đường link ảnh (URL)',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getText(context)),
                ),
                subtitle: Text(
                  'Dán liên kết ảnh trực tiếp từ web',
                  style: TextStyle(
                      fontSize: 11, color: AppTheme.getTextSecondary(context)),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showCoverUrlInputDialog(folder);
                },
              ),
              if (folder.coverUrl != null && folder.coverUrl!.isNotEmpty) ...[
                const Divider(height: 1),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.getSurface(context),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(
                          color: AppTheme.getBorder(context), width: 0.8),
                    ),
                    child: Icon(Icons.delete_outline,
                        size: 18, color: AppTheme.getDanger(context)),
                  ),
                  title: Text(
                    'Gỡ ảnh bìa tùy chỉnh',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getDanger(context)),
                  ),
                  subtitle: Text(
                    'Khôi phục ảnh bìa theo bài hát',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.getTextSecondary(context)),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final folderProv =
                        Provider.of<FolderProvider>(context, listen: false);
                    final ok =
                        await folderProv.updateFolderCoverUrl(folder.id, null);
                    if (mounted) {
                      AppTheme.showSnackBar(
                        context,
                        ok ? 'Đã gỡ ảnh bìa' : 'Thao tác thất bại',
                        isError: !ok,
                      );
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showCoverUrlInputDialog(Folder folder) {
    final controller = TextEditingController(text: folder.coverUrl ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.getSurfaceElevated(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          side: BorderSide(color: AppTheme.getBorder(context), width: 0.8),
        ),
        title: Text(
          'Đổi ảnh bìa thư mục',
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
              'Dán liên kết hình ảnh trực tiếp (JPG, PNG, WebP):',
              style: TextStyle(
                  color: AppTheme.getTextSecondary(context), fontSize: 12),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              autofocus: true,
              style: TextStyle(color: AppTheme.getText(context), fontSize: 13),
              decoration: InputDecoration(
                hintText: 'https://example.com/cover.jpg',
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
              final url = controller.text.trim();
              Navigator.pop(ctx);
              final folderProv =
                  Provider.of<FolderProvider>(context, listen: false);
              final ok = await folderProv.updateFolderCoverUrl(
                  folder.id, url.isNotEmpty ? url : null);
              if (mounted) {
                AppTheme.showSnackBar(
                  context,
                  ok ? 'Đã lưu ảnh bìa thư mục' : 'Cập nhật thất bại',
                  isError: !ok,
                );
              }
            },
            child: const Text('Lưu',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showAddSongsModal(Folder folder) {
    final songProvider = Provider.of<SongProvider>(context, listen: false);
    final allSongs = songProvider.songs;
    final folderSongIds = folder.songIds.toSet();
    final availableSongs =
        allSongs.where((s) => !folderSongIds.contains(s.id)).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.getSurfaceElevated(context),
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusSheet)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.getTextMuted(context)
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'THÊM BÀI HÁT VÀO THƯ MỤC',
                          style: AppTheme.monoStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.getText(context),
                            letterSpacing: 0.5,
                          ),
                        ),
                        BouncingIconButton(
                          icon: Icon(Icons.close,
                              size: 20,
                              color: AppTheme.getTextSecondary(context)),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Chọn bài hát từ kho nhạc để thêm vào thư mục "${folder.name}"',
                        style: TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.getTextSecondary(context)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(color: AppTheme.getBorder(context), height: 1),
                    const SizedBox(height: 8),
                    Expanded(
                      child: availableSongs.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline,
                                      size: 36,
                                      color: AppTheme.getTextMuted(context)),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tất cả bài hát đã có trong thư mục này.',
                                    style: TextStyle(
                                        color:
                                            AppTheme.getTextSecondary(context),
                                        fontSize: 12.5),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: availableSongs.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 6),
                              itemBuilder: (context, idx) {
                                final song = availableSongs[idx];
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.getSurface(context),
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusSm),
                                    border: Border.all(
                                        color: AppTheme.getBorder(context),
                                        width: 0.6),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: AppTheme.getSurfaceElevated(
                                              context),
                                          borderRadius: BorderRadius.circular(
                                              AppTheme.radiusSm),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: AppCoverImage(
                                          url: song.coverUrl,
                                          fallbackUrl: song.fallbackCoverUrl,
                                          width: 38,
                                          height: 38,
                                          iconSize: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              song.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    AppTheme.getText(context),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${song.artist} • ${song.formattedDuration}',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color:
                                                      AppTheme.getTextSecondary(
                                                          context)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          side: BorderSide(
                                              color:
                                                  AppTheme.getBorder(context),
                                              width: 0.8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                AppTheme.radiusSm),
                                          ),
                                        ),
                                        onPressed: () async {
                                          final folderProv =
                                              Provider.of<FolderProvider>(
                                                  modalCtx,
                                                  listen: false);
                                          final ok = await folderProv
                                              .addSongToFolder(folder.id, song);
                                          if (ok) {
                                            setModalState(() {
                                              availableSongs.removeAt(idx);
                                            });
                                            if (modalCtx.mounted) {
                                              AppTheme.showSnackBar(
                                                modalCtx,
                                                'Đã thêm "${song.title}" vào thư mục',
                                              );
                                            }
                                          }
                                        },
                                        child: Text(
                                          '+ Thêm',
                                          style: AppTheme.monoStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.getText(context),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSongOptions(Folder folder, Song song) {
    final folderProv = Provider.of<FolderProvider>(context, listen: false);
    final otherFolders =
        folderProv.folders.where((f) => f.id != folder.id).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.getSurfaceElevated(context),
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusSheet)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 3,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color:
                        AppTheme.getTextMuted(context).withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(
                            color: AppTheme.getBorder(context), width: 0.8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: AppCoverImage(
                        url: song.coverUrl,
                        fallbackUrl: song.fallbackCoverUrl,
                        width: 40,
                        height: 40,
                        iconSize: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppTheme.getText(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${song.artist} • ${song.formattedDuration}',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.getTextSecondary(context)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: AppTheme.getBorder(context), height: 1),
                const SizedBox(height: 4),
                ListTile(
                  dense: true,
                  leading: Icon(Icons.play_arrow_outlined,
                      color: AppTheme.getText(context), size: 20),
                  title: Text('Phát bài hát',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.getText(context))),
                  onTap: () {
                    Navigator.pop(ctx);
                    final songs = folder.songs;
                    final idx = songs.indexWhere((s) => s.id == song.id);
                    audioPlayerService.setPlaylist(songs,
                        initialIndex: idx != -1 ? idx : 0);
                    _openNowPlaying(context);
                  },
                ),
                ListTile(
                  dense: true,
                  leading: Icon(Icons.info_outline,
                      color: AppTheme.getText(context), size: 20),
                  title: Text('Xem chi tiết bài hát',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.getText(context))),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SongDetailScreen(song: song),
                      ),
                    );
                  },
                ),
                if (otherFolders.isNotEmpty)
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.drive_file_move_outlined,
                        color: AppTheme.getText(context), size: 20),
                    title: Text('Chuyển sang thư mục khác',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.getText(context))),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showMoveToOtherFolderSheet(folder, song, otherFolders);
                    },
                  ),
                ListTile(
                  dense: true,
                  leading: Icon(Icons.folder_delete_outlined,
                      color: AppTheme.getDanger(context), size: 20),
                  title: Text(
                    'Loại bỏ khỏi thư mục này',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.getDanger(context)),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final ok = await folderProv.removeSongFromFolder(
                        folder.id, song.id);
                    if (mounted && ok) {
                      AppTheme.showSnackBar(
                        context,
                        'Đã loại bỏ "${song.title}" khỏi thư mục "${folder.name}"',
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMoveToOtherFolderSheet(
      Folder currentFolder, Song song, List<Folder> otherFolders) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.getSurfaceElevated(context),
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusSheet)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 32,
                    height: 3,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color:
                          AppTheme.getTextMuted(context).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'CHUYỂN ĐẾN THƯ MỤC',
                  style: AppTheme.monoStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.getText(context),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bài hát sẽ được chuyển từ "${currentFolder.name}" sang thư mục được chọn',
                  style: TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.getTextSecondary(context)),
                ),
                const SizedBox(height: 12),
                Divider(color: AppTheme.getBorder(context), height: 1),
                const SizedBox(height: 6),
                ...otherFolders.map((target) {
                  return ListTile(
                    dense: true,
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.getSurface(context),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(
                            color: AppTheme.getBorder(context), width: 0.8),
                      ),
                      child: Icon(Icons.folder_outlined,
                          size: 16, color: AppTheme.getText(context)),
                    ),
                    title: Text(
                      target.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getText(context),
                      ),
                    ),
                    subtitle: Text(
                      '${target.songCount} bài hát',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.getTextSecondary(context)),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios,
                        size: 13, color: AppTheme.getTextMuted(context)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final folderProv =
                          Provider.of<FolderProvider>(context, listen: false);
                      final ok = await folderProv.addSongToFolder(
                          target.id, song,
                          fromFolderId: currentFolder.id);
                      if (mounted && ok) {
                        AppTheme.showSnackBar(
                          context,
                          'Đã chuyển "${song.title}" sang thư mục "${target.name}"',
                        );
                      }
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final folderProv = Provider.of<FolderProvider>(context);
    final folder = folderProv.currentFolder?.id == widget.folderId
        ? folderProv.currentFolder!
        : (folderProv.folders.firstWhere(
            (f) => f.id == widget.folderId,
            orElse: () => Folder(
              id: widget.folderId,
              name: widget.initialName,
              userId: '',
            ),
          ));

    final songs = folder.songs;

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
          folder.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.getText(context),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_horiz,
                color: AppTheme.getText(context), size: 20),
            color: AppTheme.getSurfaceElevated(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              side: BorderSide(color: AppTheme.getBorder(context), width: 0.8),
            ),
            onSelected: (val) {
              if (val == 'rename') {
                _showRenameDialog(folder);
              } else if (val == 'cover') {
                _showChangeCoverDialog(folder);
              } else if (val == 'delete') {
                _confirmDeleteFolder(folder);
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined,
                        size: 16, color: AppTheme.getText(context)),
                    const SizedBox(width: 8),
                    Text('Đổi tên thư mục',
                        style: TextStyle(
                            fontSize: 12.5, color: AppTheme.getText(context))),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'cover',
                child: Row(
                  children: [
                    Icon(Icons.image_outlined,
                        size: 16, color: AppTheme.getText(context)),
                    const SizedBox(width: 8),
                    Text('Đổi ảnh bìa',
                        style: TextStyle(
                            fontSize: 12.5, color: AppTheme.getText(context))),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline,
                        size: 16, color: AppTheme.getDanger(context)),
                    const SizedBox(width: 8),
                    Text('Xóa thư mục',
                        style: TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.getDanger(context))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: GestureDetector(
                  onTap: () => _showChangeCoverDialog(folder),
                  child: Stack(
                    children: [
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color: AppTheme.getSurfaceSubtle(context),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                          border: Border.all(
                              color: AppTheme.getBorder(context), width: 1.0),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: AppCoverImage(
                          url: folder.effectiveCoverUrl,
                          width: 160,
                          height: 160,
                          borderRadius: AppTheme.radiusMd,
                          placeholderIcon: Icons.folder_outlined,
                          iconSize: 56,
                        ),
                      ),
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: AppTheme.getSurface(context)
                                .withValues(alpha: 0.88),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSm),
                            border: Border.all(
                                color: AppTheme.getBorder(context), width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.camera_alt,
                                  size: 11, color: AppTheme.getText(context)),
                              const SizedBox(width: 4),
                              Text('Đổi ảnh',
                                  style: AppTheme.monoStyle(
                                      fontSize: 10,
                                      color: AppTheme.getText(context))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                folder.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.getText(context),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${folder.songCount} bài hát • Thư mục nhạc cá nhân',
                style: AppTheme.monoStyle(
                  fontSize: 12,
                  color: AppTheme.getTextSecondary(context),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      backgroundColor: AppTheme.getText(context),
                      foregroundColor: AppTheme.getBg(context),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusPill),
                      ),
                    ),
                    icon: Icon(Icons.play_arrow,
                        size: 18, color: AppTheme.getBg(context)),
                    label: Text(
                      'Phát tất cả',
                      style: AppTheme.monoStyle(
                          fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    onPressed: songs.isEmpty
                        ? null
                        : () {
                            audioPlayerService.setPlaylist(songs,
                                initialIndex: 0);
                            _openNowPlaying(context);
                          },
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      side: BorderSide(
                          color: AppTheme.getBorder(context), width: 0.8),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusPill),
                      ),
                    ),
                    icon: Icon(Icons.add,
                        size: 16, color: AppTheme.getText(context)),
                    label: Text(
                      'Thêm bài hát',
                      style: AppTheme.monoStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.getText(context)),
                    ),
                    onPressed: () => _showAddSongsModal(folder),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: AppTheme.getBorder(context), height: 1),
              const SizedBox(height: 12),
              if (songs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.folder_open_outlined,
                            size: 44, color: AppTheme.getTextMuted(context)),
                        const SizedBox(height: 10),
                        Text(
                          'Thư mục đang trống.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.getTextSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Nhấn "+ Thêm bài hát" để chuyển bài hát vào thư mục này.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.getTextMuted(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: songs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    final isCurrent =
                        audioPlayerService.currentSong?.id == song.id;

                    return Container(
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppTheme.getSurfaceElevated(context)
                            : AppTheme.getSurface(context),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(
                          color: isCurrent
                              ? AppTheme.getText(context).withValues(alpha: 0.4)
                              : AppTheme.getBorder(context),
                          width: 0.8,
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 2),
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSm),
                            border: Border.all(
                                color: AppTheme.getBorder(context), width: 0.8),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: AppCoverImage(
                            url: song.coverUrl,
                            fallbackUrl: song.fallbackCoverUrl,
                            width: 38,
                            height: 38,
                            iconSize: 18,
                          ),
                        ),
                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isCurrent ? FontWeight.w700 : FontWeight.w600,
                            color: AppTheme.getText(context),
                          ),
                        ),
                        subtitle: Text(
                          '${song.artist} • ${song.formattedDuration}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.getTextSecondary(context),
                          ),
                        ),
                        trailing: BouncingIconButton(
                          icon: Icon(Icons.more_vert,
                              size: 18,
                              color: AppTheme.getTextSecondary(context)),
                          onPressed: () => _showSongOptions(folder, song),
                        ),
                        onTap: () {
                          audioPlayerService.setPlaylist(songs,
                              initialIndex: index);
                          _openNowPlaying(context);
                        },
                      ),
                    );
                  },
                ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: MiniPlayerWidget(playerService: audioPlayerService),
    );
  }
}
