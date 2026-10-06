import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reicon_flutter/reicon_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/song_provider.dart';
import '../../services/audio_player_service.dart';
import '../../widgets/song_card_widget.dart';
import '../../widgets/mini_player_widget.dart';
import '../../widgets/re_icon.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SongProvider>(context, listen: false).fetchSongs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showYouTubeDownloadDialog() {
    final urlController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // Vuông vức kiểu terminal, không bo tròn
        side: BorderSide(color: AppTheme.borderHighlight, width: 1),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '// COMMAND: WGET_YOUTUBE_AUDIO',
                    style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                  ),
                  TerminalActionBtn(
                    onTap: () => Navigator.of(ctx).pop(),
                    hasBorder: false,
                    padding: const EdgeInsets.all(4),
                    defaultColor: AppTheme.textMuted,
                    hoverColor: AppTheme.error,
                    icon: ReIcon(Reicon.outline.xmark, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                '> Extract MP3 192k + Cover art to Google Drive storage.',
                style: TextStyle(fontFamily: 'monospace', color: AppTheme.textSecondary, fontSize: 11),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: urlController,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'https://youtube.com/watch?v=...',
                  prefixText: '> url: ',
                  prefixStyle: TextStyle(fontFamily: 'monospace', color: AppTheme.terminalGreen),
                ),
              ),
              const SizedBox(height: 16),
              Consumer<SongProvider>(
                builder: (context, songProv, _) {
                  return SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: TerminalActionBtn(
                      onTap: songProv.isDownloading
                          ? null
                          : () async {
                              final url = urlController.text.trim();
                              if (url.isEmpty) return;

                              final success = await songProv.downloadFromYouTube(url);
                              if (!mounted) return;
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: success ? AppTheme.surface : AppTheme.error,
                                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                  content: Text(
                                    success ? '> UPLOAD_COMPLETE: Bài hát đã lưu vào Drive!' : '> ERROR: Tải thất bại!',
                                    style: const TextStyle(fontFamily: 'monospace'),
                                  ),
                                ),
                              );
                            },
                      defaultColor: AppTheme.textPrimary,
                      hoverColor: AppTheme.terminalGreen,
                      hoverBorderColor: AppTheme.terminalGreen,
                      icon: songProv.isDownloading
                          ? null
                          : ReIcon(Reicon.outline.plus, size: 16),
                      label: songProv.isDownloading ? '>>> DOWNLOADING & UPLOADING...' : 'EXECUTE_DOWNLOAD',
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final songProvider = Provider.of<SongProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '// MUSIC_STORAGE_TERMINAL',
              style: TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            Text(
              'USER: ${authProvider.user?.username ?? "guest"}@drive // STATUS: OK',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          // Nút thêm nhạc YouTube với Reicon
          Center(
            child: TerminalActionBtn(
              onTap: _showYouTubeDownloadDialog,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              defaultColor: AppTheme.terminalGreen,
              hoverColor: Colors.white,
              defaultBorderColor: AppTheme.terminalGreen,
              hoverBorderColor: Colors.white,
              icon: ReIcon(Reicon.outline.plus, size: 14, color: AppTheme.terminalGreen),
              label: 'YOUTUBE',
            ),
          ),
          const SizedBox(width: 8),

          // Nút đăng xuất với Reicon
          Center(
            child: TerminalActionBtn(
              onTap: () async {
                await authProvider.logout();
                if (!mounted) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              hasBorder: false,
              padding: const EdgeInsets.all(8),
              defaultColor: AppTheme.textMuted,
              hoverColor: AppTheme.error,
              icon: ReIcon(Reicon.outline.logout, size: 18),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Thanh tìm kiếm dạng CLI prompt
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ReIcon(Reicon.outline.search, size: 15, color: AppTheme.terminalGreen),
                          const SizedBox(width: 6),
                          const Text('> grep: ', style: TextStyle(fontFamily: 'monospace', color: AppTheme.terminalGreen, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                    hintText: 'find track, artist, album...',
                    suffixIcon: _searchController.text.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: TerminalActionBtn(
                              hasBorder: false,
                              padding: const EdgeInsets.all(6),
                              defaultColor: AppTheme.textMuted,
                              hoverColor: AppTheme.error,
                              icon: ReIcon(Reicon.outline.xmark, size: 14),
                              onTap: () {
                                _searchController.clear();
                                songProvider.fetchSongs(query: '');
                              },
                            ),
                          )
                        : null,
                  ),
                  onChanged: (val) {
                    songProvider.fetchSongs(query: val);
                  },
                ),
              ),

              // Danh sách bài hát
              Expanded(
                child: RefreshIndicator(
                  color: AppTheme.textPrimary,
                  backgroundColor: AppTheme.surface,
                  onRefresh: () => songProvider.fetchSongs(),
                  child: songProvider.isLoading
                      ? const Center(
                          child: Text('> FETCHING_DATABASE...', style: TextStyle(fontFamily: 'monospace', color: AppTheme.textSecondary)),
                        )
                      : songProvider.songs.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('> REPO_EMPTY: No songs found.', style: TextStyle(fontFamily: 'monospace', color: AppTheme.textMuted)),
                                  const SizedBox(height: 16),
                                  TerminalActionBtn(
                                    onTap: _showYouTubeDownloadDialog,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    defaultColor: AppTheme.terminalGreen,
                                    hoverColor: Colors.white,
                                    icon: ReIcon(Reicon.outline.plus, size: 16),
                                    label: 'INGEST_FROM_YOUTUBE',
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 85),
                              itemCount: songProvider.songs.length,
                              itemBuilder: (context, index) {
                                final song = songProvider.songs[index];
                                final isCurrentPlaying = audioPlayerService.currentSong?.id == song.id && audioPlayerService.isPlaying;

                                return SongCardWidget(
                                  index: index,
                                  song: song,
                                  isPlaying: isCurrentPlaying,
                                  onTap: () {
                                    audioPlayerService.setPlaylist(songProvider.songs, initialIndex: index);
                                  },
                                  onDelete: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor: AppTheme.surface,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.zero,
                                          side: BorderSide(color: AppTheme.border, width: 1),
                                        ),
                                        title: const Text('// CONFIRM_DELETE', style: TextStyle(fontFamily: 'monospace', fontSize: 14)),
                                        content: Text(
                                          '> Xoá bài hát "${song.title}" khỏi Google Drive?',
                                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppTheme.textSecondary),
                                        ),
                                        actions: [
                                          TerminalActionBtn(
                                            onTap: () => Navigator.of(ctx).pop(false),
                                            defaultColor: AppTheme.textMuted,
                                            hoverColor: AppTheme.textPrimary,
                                            label: 'CANCEL',
                                          ),
                                          TerminalActionBtn(
                                            onTap: () => Navigator.of(ctx).pop(true),
                                            defaultColor: AppTheme.error,
                                            hoverColor: Colors.redAccent,
                                            defaultBorderColor: AppTheme.error,
                                            label: 'DELETE_PERMANENTLY',
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      final ok = await songProvider.deleteSong(song.id);
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: ok ? AppTheme.surface : AppTheme.error,
                                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                          content: Text(
                                            ok ? '> PURGED: Đã xoá bài hát thành công.' : '> ERROR: Không thể xoá bài hát!',
                                            style: const TextStyle(fontFamily: 'monospace'),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                ),
              ),
            ],
          ),

          // Mini Player cố định ở dưới cùng
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MiniPlayerWidget(playerService: audioPlayerService),
          ),
        ],
      ),
    );
  }
}
