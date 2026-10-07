import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/song_provider.dart';
import '../../../services/audio_player_service.dart';
import '../../../models/song_model.dart';
import '../../../widgets/song_card_widget.dart';
import '../../details/playlist_screen.dart';
import '../../details/artist_screen.dart';

class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key});

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  String _selectedCategory = 'Bài hát';
  String _sortOption = 'Gần đây nhất';
  final List<String> _categories = ['Bài hát', 'Nghệ sĩ', 'Playlist'];

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
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.getSurfaceElevated(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          side: BorderSide(color: AppTheme.getBorder(context), width: 1.0),
        ),
        title: Text(
          'Add from YouTube',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.getText(context)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter YouTube URL to download to Google Drive:',
              style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              style: TextStyle(color: AppTheme.getText(context), fontSize: 12.5),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'https://youtube.com/watch?v=...',
                prefixIcon: Icon(Icons.link, size: 18, color: AppTheme.getTextMuted(context)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 12)),
          ),
          ElevatedButton(
            onPressed: () async {
              final url = urlController.text.trim();
              if (url.isNotEmpty) {
                Navigator.pop(ctx);
                final songProv = Provider.of<SongProvider>(context, listen: false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Downloading track...'), duration: Duration(seconds: 2)),
                );
                await songProv.downloadFromYouTube(url);
              }
            },
            child: const Text('Download', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final songProvider = Provider.of<SongProvider>(context);
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
            // 1. Filter Tabs: [ Bài hát | Album | Nghệ sĩ | Playlist ]
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
              child: _buildCategoryContent(context, songs),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryContent(BuildContext context, List<Song> songs) {
    if (_selectedCategory == 'Nghệ sĩ') {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
        children: [
          _buildItemTile(
            title: 'Sơn Tùng M-TP',
            subtitle: '214 songs',
            icon: Icons.person,
            isCircle: true,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ArtistScreen(artistName: 'Sơn Tùng M-TP')),
            ),
          ),
        ],
      );
    } else if (_selectedCategory == 'Playlist') {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
        children: [
          _buildItemTile(
            title: 'Nhạc Tâm Trạng',
            subtitle: 'Mạnh Đình · 42 songs',
            icon: Icons.queue_music,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PlaylistScreen(title: 'Nhạc Tâm Trạng')),
            ),
          ),
          _buildItemTile(
            title: 'Giai Điệu Chill',
            subtitle: 'Mạnh Đình · 25 songs',
            icon: Icons.queue_music,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PlaylistScreen(title: 'Giai Điệu Chill')),
            ),
          ),
        ],
      );
    }

    // Default: 'Bài hát'
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

  Widget _buildItemTile({
    required String title,
    required String subtitle,
    required IconData icon,
    bool isCircle = false,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.getBorder(context), width: 0.8),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppTheme.getSurfaceSubtle(context),
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isCircle ? null : BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(color: AppTheme.getBorder(context), width: 0.8),
          ),
          child: Icon(icon, color: AppTheme.getTextSecondary(context), size: 18),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.getText(context),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 11, color: AppTheme.getTextSecondary(context)),
        ),
        trailing: Icon(Icons.chevron_right, color: AppTheme.getTextMuted(context), size: 18),
        onTap: onTap,
      ),
    );
  }
}
