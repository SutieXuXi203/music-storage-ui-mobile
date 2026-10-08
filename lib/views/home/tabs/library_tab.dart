import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/folder_model.dart';
import '../../../models/song_model.dart';
import '../../../providers/download_provider.dart';
import '../../../providers/folder_provider.dart';
import '../../../providers/song_provider.dart';
import '../../../services/audio_player_service.dart';
import '../../../widgets/song_card_widget.dart';
import '../../details/folder_detail_screen.dart';

class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key});

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  String _selectedCategory = 'Bài hát';
  String _sortOption = 'Gần đây nhất';
  final List<String> _categories = ['Bài hát', 'Thư mục'];

  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.getSurfaceElevated(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusSheet)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.getTextMuted(context).withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Sắp xếp theo',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppTheme.getText(context),
                      ),
                    ),
                  ),
                ),
                ...['Gần đây nhất', 'Tiêu đề A-Z', 'Nghệ sĩ A-Z'].map((opt) {
                  final isSelected = _sortOption == opt;
                  return ListTile(
                    dense: true,
                    title: Text(
                      opt,
                      style: TextStyle(
                        color: isSelected ? AppTheme.getText(context) : AppTheme.getTextSecondary(context),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check, color: AppTheme.getText(context), size: 18)
                        : null,
                    onTap: () {
                      setState(() => _sortOption = opt);
                      Navigator.pop(ctx);
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

  void _showAddSongDialog() {
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final screenWidth = MediaQuery.of(ctx).size.width;
          // Cố định chiều rộng chuẩn Terminal, không bị co giãn hay vỡ layout khi paste URL dài
          final dialogWidth = (screenWidth * 0.9).clamp(320.0, 440.0);

          void submit() {
            final url = urlController.text.replaceAll('\r', '').replaceAll('\n', '').trim();
            if (url.isNotEmpty) {
              Navigator.pop(ctx);
              final songProv = Provider.of<SongProvider>(context, listen: false);
              final downloadProv = Provider.of<DownloadProvider>(context, listen: false);
              downloadProv.startDownload(url, songProvider: songProv);
            }
          }

          return AlertDialog(
            backgroundColor: AppTheme.getSurfaceElevated(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.zero, // Góc vuông chuẩn Terminal
              side: BorderSide(color: AppTheme.getBorder(context), width: 1.0),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    '[CMD://INGEST_YOUTUBE_STREAM]',
                    style: GoogleFonts.jetBrainsMono(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      letterSpacing: 0.5,
                      color: const Color(0xFF38BDF8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: dialogWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '> TARGET: HTTPS://YOUTUBE_AUDIO_EXTRACTION',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppTheme.getTextSecondary(context),
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: urlController,
                    autofocus: true,
                    maxLines: 1,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.go,
                    onSubmitted: (_) => submit(),
                    onChanged: (_) => setDialogState(() {}),
                    style: GoogleFonts.jetBrainsMono(
                      color: AppTheme.getText(context),
                      fontSize: 12,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: AppTheme.getSurface(context),
                      hintText: 'https://youtube.com/watch?v=...',
                      hintStyle: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: AppTheme.getTextMuted(context),
                      ),
                      prefixText: '> ',
                      prefixStyle: GoogleFonts.jetBrainsMono(
                        color: const Color(0xFF38BDF8),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      suffixIcon: urlController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              splashRadius: 16,
                              tooltip: 'Clear',
                              color: AppTheme.getTextMuted(context),
                              onPressed: () {
                                urlController.clear();
                                setDialogState(() {});
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: AppTheme.getBorder(context), width: 0.8),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: Color(0xFF38BDF8), width: 1.2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  '[CANCEL]',
                  style: GoogleFonts.jetBrainsMono(
                    color: AppTheme.getTextSecondary(context),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38BDF8),
                  foregroundColor: Colors.black,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  elevation: 0,
                ),
                onPressed: submit,
                child: Text(
                  '[EXECUTE]',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCreateFolderDialog() {
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
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.getText(context)),
        ),
        content: SizedBox(
          width: (MediaQuery.of(ctx).size.width * 0.9).clamp(320.0, 420.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Đặt tên cho thư mục bài hát của bạn:',
                style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                autofocus: true,
                maxLines: 1,
                style: TextStyle(color: AppTheme.getText(context), fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Ví dụ: Nhạc Acoustic, Lofi, EDM...',
                  hintStyle: TextStyle(color: AppTheme.getTextMuted(context), fontSize: 12.5),
                  isDense: true,
                  filled: true,
                  fillColor: AppTheme.getSurface(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    borderSide: BorderSide(color: AppTheme.getBorder(context), width: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hủy', style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 12.5)),
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
                final folderProv = Provider.of<FolderProvider>(context, listen: false);
                final folder = await folderProv.createFolder(name);
                if (mounted && folder != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã tạo thư mục "$name"', style: AppTheme.monoStyle(fontSize: 12)),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppTheme.getSurfaceElevated(context),
                    ),
                  );
                }
              }
            },
            child: const Text('Tạo', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showRenameFolderDialog(Folder folder) {
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
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.getText(context)),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: AppTheme.getText(context), fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Nhập tên mới...',
            hintStyle: TextStyle(color: AppTheme.getTextMuted(context), fontSize: 13),
            isDense: true,
            filled: true,
            fillColor: AppTheme.getSurface(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              borderSide: BorderSide(color: AppTheme.getBorder(context), width: 0.8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hủy', style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 12.5)),
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
                final folderProv = Provider.of<FolderProvider>(context, listen: false);
                await folderProv.renameFolder(folder.id, newName);
              }
            },
            child: const Text('Lưu', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
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
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.getText(context)),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa thư mục "${folder.name}"? Các bài hát vẫn sẽ được giữ an toàn trong kho nhạc chính.',
          style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 12.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hủy', style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 12.5)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.getDanger(context),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final folderProv = Provider.of<FolderProvider>(context, listen: false);
              final ok = await folderProv.deleteFolder(folder.id);
              if (mounted && ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã xóa thư mục "${folder.name}"', style: AppTheme.monoStyle(fontSize: 12)),
                    backgroundColor: AppTheme.getSurfaceElevated(context),
                  ),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final songProvider = Provider.of<SongProvider>(context);
    final folderProvider = Provider.of<FolderProvider>(context);
    final songs = songProvider.songs;

    return Scaffold(
      backgroundColor: AppTheme.getBg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.getBg(context),
        elevation: 0,
        title: Text(
          'Thư viện',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.getText(context),
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          if (_selectedCategory == 'Thư mục')
            IconButton(
              icon: Icon(Icons.create_new_folder_outlined, color: AppTheme.getText(context), size: 22),
              tooltip: 'Tạo thư mục mới',
              onPressed: _showCreateFolderDialog,
            )
          else
            IconButton(
              icon: Icon(Icons.add, color: AppTheme.getText(context), size: 22),
              tooltip: 'Thêm từ YouTube',
              onPressed: _showAddSongDialog,
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Filter Tabs: [ Bài hát | Thư mục ]
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  final activeBg = AppTheme.getAction(context);
                  final activeText = AppTheme.getActionText(context);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? activeBg : AppTheme.getSurface(context),
                          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                          border: Border.all(
                            color: isSelected ? activeBg : AppTheme.getBorder(context),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? activeText : AppTheme.getTextSecondary(context),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // 2. Sort Bar: Sắp xếp: Gần đây nhất
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _showSortMenu,
                    child: Row(
                      children: [
                        Text(
                          'Sắp xếp: ',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.getTextMuted(context),
                          ),
                        ),
                        Text(
                          _sortOption,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.getText(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _showSortMenu,
                    child: Icon(
                      Icons.sort,
                      size: 18,
                      color: AppTheme.getTextSecondary(context),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Main Content
            Expanded(
              child: _selectedCategory == 'Thư mục'
                  ? _buildFoldersContent(context, folderProvider)
                  : _buildSongsContent(context, songs),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoldersContent(BuildContext context, FolderProvider folderProvider) {
    if (folderProvider.isLoading && folderProvider.folders.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppTheme.getText(context),
        ),
      );
    }

    final folders = folderProvider.folders;

    if (folders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.getSurface(context),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.getBorder(context), width: 0.8),
              ),
              child: Icon(Icons.folder_open_outlined, size: 24, color: AppTheme.getTextMuted(context)),
            ),
            const SizedBox(height: 12),
            Text(
              'Chưa có thư mục nào.',
              style: TextStyle(
                color: AppTheme.getTextSecondary(context),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tạo thư mục để phân loại và gom nhóm bài hát.',
              style: TextStyle(
                color: AppTheme.getTextMuted(context),
                fontSize: 11.5,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                backgroundColor: AppTheme.getText(context),
                foregroundColor: AppTheme.getBg(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
              ),
              icon: Icon(Icons.add, size: 16, color: AppTheme.getBg(context)),
              label: Text(
                'Tạo thư mục mới',
                style: AppTheme.monoStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              onPressed: _showCreateFolderDialog,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
      itemCount: folders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final folder = folders[index];

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.getSurface(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(color: AppTheme.getBorder(context), width: 0.8),
          ),
          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.getSurfaceElevated(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: AppTheme.getBorder(context), width: 0.8),
              ),
              clipBehavior: Clip.antiAlias,
              child: folder.coverUrl != null && folder.coverUrl!.isNotEmpty
                  ? Image.network(
                      folder.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.folder_outlined,
                        color: AppTheme.getText(context),
                        size: 22,
                      ),
                    )
                  : Icon(
                      Icons.folder_outlined,
                      color: AppTheme.getText(context),
                      size: 22,
                    ),
            ),
            title: Text(
              folder.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.getText(context),
              ),
            ),
            subtitle: Text(
              '${folder.songCount} bài hát',
              style: AppTheme.monoStyle(
                fontSize: 11,
                color: AppTheme.getTextSecondary(context),
              ),
            ),
            trailing: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 18, color: AppTheme.getTextSecondary(context)),
              color: AppTheme.getSurfaceElevated(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                side: BorderSide(color: AppTheme.getBorder(context), width: 0.8),
              ),
              onSelected: (val) {
                if (val == 'rename') {
                  _showRenameFolderDialog(folder);
                } else if (val == 'delete') {
                  _confirmDeleteFolder(folder);
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'rename',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 16, color: AppTheme.getText(context)),
                      const SizedBox(width: 8),
                      Text('Đổi tên', style: TextStyle(fontSize: 12, color: AppTheme.getText(context))),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 16, color: AppTheme.getDanger(context)),
                      const SizedBox(width: 8),
                      Text('Xóa thư mục', style: TextStyle(fontSize: 12, color: AppTheme.getDanger(context))),
                    ],
                  ),
                ),
              ],
            ),
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
          ),
        );
      },
    );
  }

  Widget _buildSongsContent(BuildContext context, List<Song> songs) {
    if (songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Kho nhạc của bạn đang trống.',
              style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              'Thêm bài hát đầu tiên từ YouTube.',
              style: TextStyle(color: AppTheme.getTextMuted(context), fontSize: 11.5),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
      itemCount: songs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final song = songs[index];
        final isCurrent = audioPlayerService.currentSong?.id == song.id;

        return SongCardWidget(
          index: index,
          song: song,
          isCurrent: isCurrent,
          isPlaying: isCurrent && audioPlayerService.isPlaying,
          isBuffering: isCurrent && audioPlayerService.isBuffering,
          onTap: () {
            audioPlayerService.setPlaylist(songs, initialIndex: index);
          },
          onDelete: () {
            Provider.of<SongProvider>(context, listen: false).deleteSong(song.id);
          },
        );
      },
    );
  }
}
