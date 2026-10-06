import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../providers/auth_provider.dart';
import '../../providers/song_provider.dart';
import '../../services/audio_player_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/song_card_widget.dart';
import '../../widgets/mini_player_widget.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  void _showYouTubeDownloadDialog() {
    final urlController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.video_library_rounded, color: Colors.redAccent, size: 28),
                  SizedBox(width: 10),
                  Text(
                    'Tải nhạc từ YouTube',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Nhập đường dẫn YouTube (URL), hệ thống sẽ trích xuất MP3 192kbps và tự động lưu vào Google Drive của bạn:',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  hintText: 'https://www.youtube.com/watch?v=...',
                  prefixIcon: Icon(Icons.link, color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 20),
              Consumer<SongProvider>(
                builder: (context, songProv, _) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: songProv.isDownloading
                          ? null
                          : () async {
                              final url = urlController.text.trim();
                              if (url.isEmpty) return;

                              final success = await songProv.downloadFromYouTube(url);
                              if (mounted) {
                                Navigator.of(ctx).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success ? 'Tải bài hát lên Google Drive thành công!' : 'Tải nhạc thất bại, vui lòng thử lại.',
                                    ),
                                    backgroundColor: success ? Colors.green : AppTheme.error,
                                  ),
                                );
                              }
                            },
                      child: songProv.isDownloading
                          ? const SpinKitThreeBounce(color: Colors.white, size: 20)
                          : const Text('Tải về & Lưu Google Drive'),
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
            Text(
              'Xin chào, ${authProvider.user?.fullName ?? authProvider.user?.username ?? 'bạn'}!',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Kho nhạc Google Drive của bạn',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryLight, size: 28),
            tooltip: 'Tải nhạc từ YouTube',
            onPressed: _showYouTubeDownloadDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.textSecondary),
            tooltip: 'Đăng xuất',
            onPressed: () async {
              await authProvider.logout();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Thanh tìm kiếm
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm bài hát, ca sĩ, album...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                            onPressed: () {
                              _searchController.clear();
                              songProvider.fetchSongs(query: '');
                            },
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
                  color: AppTheme.primary,
                  onRefresh: () => songProvider.fetchSongs(),
                  child: songProvider.isLoading
                      ? const Center(child: SpinKitFadingCircle(color: AppTheme.primary, size: 40))
                      : songProvider.songs.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.library_music_outlined, size: 64, color: AppTheme.textSecondary),
                                  const SizedBox(height: 12),
                                  const Text('Chưa có bài hát nào trong kho nhạc', style: TextStyle(color: AppTheme.textSecondary)),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.add),
                                    label: const Text('Thêm bài hát từ YouTube'),
                                    onPressed: _showYouTubeDownloadDialog,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 90), // chừa chỗ cho Mini Player
                              itemCount: songProvider.songs.length,
                              itemBuilder: (context, index) {
                                final song = songProvider.songs[index];
                                final isCurrentPlaying = audioPlayerService.currentSong?.id == song.id && audioPlayerService.isPlaying;

                                return SongCardWidget(
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
                                        title: const Text('Xác nhận xóa'),
                                        content: Text('Bạn có chắc muốn xóa bài hát "${song.title}" khỏi Google Drive và hệ thống?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text('Xóa', style: TextStyle(color: AppTheme.error)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await songProvider.deleteSong(song.id);
                                    }
                                  },
                                );
                              },
                            ),
                ),
              ),
            ],
          ),

          // Pinned Mini Player ở đáy
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ListenableBuilder(
              listenable: audioPlayerService,
              builder: (context, _) => MiniPlayerWidget(playerService: audioPlayerService),
            ),
          ),
        ],
      ),
    );
  }
}
