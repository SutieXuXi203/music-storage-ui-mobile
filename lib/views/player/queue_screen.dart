import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/audio_player_service.dart';
import '../../providers/song_provider.dart';
import '../../models/song_model.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  int _selectedTab = 0; // 0: Up Next, 1: Playlist

  @override
  Widget build(BuildContext context) {
    final songProvider = Provider.of<SongProvider>(context);

    return ListenableBuilder(
      listenable: audioPlayerService,
      builder: (context, _) {
        final playlist = audioPlayerService.playlist.isNotEmpty
            ? audioPlayerService.playlist
            : songProvider.songs;

        final currentSong = audioPlayerService.currentSong;

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
              'Hàng đợi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.getText(context),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.more_horiz, color: AppTheme.getText(context), size: 20),
                onPressed: () {},
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // 1. Tabs: [ Up Next ] [ Playlist ]
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      _buildPillTab(
                        title: 'Up Next',
                        isSelected: _selectedTab == 0,
                        onTap: () => setState(() => _selectedTab = 0),
                      ),
                      const SizedBox(width: 8),
                      _buildPillTab(
                        title: 'Playlist',
                        isSelected: _selectedTab == 1,
                        onTap: () => setState(() => _selectedTab = 1),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // 2. Info Row: 12 tracks · 52m | [ Xóa tất cả ]
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${playlist.length} tracks · ${_calculateTotalDuration(playlist)}',
                        style: AppTheme.monoStyle(
                          fontSize: 11,
                          color: AppTheme.getTextSecondary(context),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã xoá hàng đợi'), duration: Duration(seconds: 1)),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            border: Border.all(color: AppTheme.getBorder(context), width: 0.8),
                          ),
                          child: Text(
                            'Xóa tất cả',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.getTextSecondary(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // 3. Queue List
                Expanded(
                  child: playlist.isEmpty
                      ? Center(
                          child: Text(
                            'Hàng đợi đang trống',
                            style: TextStyle(color: AppTheme.getTextMuted(context), fontSize: 12),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          itemCount: playlist.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final song = playlist[index];
                            final isCurrent = currentSong?.id == song.id;
                            final trackStr = (index + 1).toString().padLeft(2, '0');

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: isCurrent ? AppTheme.getSurfaceSubtle(context) : AppTheme.getSurface(context),
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                border: Border.all(
                                  color: isCurrent ? AppTheme.getText(context).withValues(alpha: 0.3) : AppTheme.getBorder(context),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Drag handle icon
                                  Icon(Icons.drag_handle, size: 16, color: AppTheme.getTextMuted(context)),
                                  const SizedBox(width: 8),

                                  // Track number: 01, 02...
                                  SizedBox(
                                    width: 20,
                                    child: Text(
                                      trackStr,
                                      style: AppTheme.monoStyle(
                                        fontSize: 11,
                                        color: AppTheme.getTextMuted(context),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),

                                  // Thumbnail (36x36)
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppTheme.getSurfaceSubtle(context),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                      border: Border.all(color: AppTheme.getBorder(context), width: 0.8),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: song.coverUrl != null && song.coverUrl!.isNotEmpty
                                        ? Image.network(
                                            song.coverUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Icon(Icons.music_note, color: AppTheme.getTextMuted(context), size: 16),
                                          )
                                        : Icon(Icons.music_note, color: AppTheme.getTextMuted(context), size: 16),
                                  ),
                                  const SizedBox(width: 10),

                                  // Title & Artist
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
                                            Flexible(
                                              child: Text(
                                                song.artist,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(fontSize: 11, color: AppTheme.getTextSecondary(context)),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              song.formattedDuration,
                                              style: AppTheme.monoStyle(fontSize: 10, color: AppTheme.getTextMuted(context)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Trailing 3-dots
                                  Icon(Icons.more_vert, size: 18, color: AppTheme.getTextMuted(context)),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                // 4. Bottom Action Bar: [ + Thêm vào playlist ] [ ✕ Xóa ]
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.getSurface(context),
                    border: Border(top: BorderSide(color: AppTheme.getBorder(context), width: 0.8)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppTheme.getSurface(context),
                              foregroundColor: AppTheme.getText(context),
                              side: BorderSide(color: AppTheme.getBorder(context), width: 0.8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              ),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Đã lưu vào playlist!'), duration: Duration(seconds: 1)),
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add, size: 16, color: AppTheme.getText(context)),
                                const SizedBox(width: 6),
                                Text(
                                  'Thêm vào playlist',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.getText(context)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppTheme.getSurface(context),
                              foregroundColor: AppTheme.getText(context),
                              side: BorderSide(color: AppTheme.getBorder(context), width: 0.8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              ),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Đã dọn dẹp hàng đợi'), duration: Duration(seconds: 1)),
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.close, size: 16, color: AppTheme.getText(context)),
                                const SizedBox(width: 6),
                                Text(
                                  'Xóa',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.getText(context)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPillTab({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final activeBg = AppTheme.getAction(context);
    final activeText = AppTheme.getActionText(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : AppTheme.getSurface(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          border: Border.all(
            color: isSelected ? activeBg : AppTheme.getBorder(context),
            width: 0.8,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isSelected ? activeText : AppTheme.getTextSecondary(context),
          ),
        ),
      ),
    );
  }

  String _calculateTotalDuration(List<Song> songs) {
    final totalSec = songs.fold<int>(0, (sum, s) => sum + s.duration);
    final min = totalSec ~/ 60;
    return '${min}m';
  }
}
