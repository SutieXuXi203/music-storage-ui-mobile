import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/song_provider.dart';
import '../../../services/audio_player_service.dart';
import '../../../models/song_model.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          'Tìm kiếm',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.getText(context),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          children: [
            Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.getSurface(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border:
                    Border.all(color: AppTheme.getBorder(context), width: 1.0),
              ),
              child: TextField(
                controller: _searchController,
                style:
                    TextStyle(fontSize: 13, color: AppTheme.getText(context)),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Tìm kiếm bài hát, nghệ sĩ, album...',
                  hintStyle: TextStyle(
                      color: AppTheme.getTextMuted(context), fontSize: 12.5),
                  prefixIcon: Icon(Icons.search,
                      size: 18, color: AppTheme.getTextMuted(context)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(Icons.close,
                              size: 16,
                              color: AppTheme.getTextSecondary(context)),
                          onPressed: () {
                            _searchController.clear();
                            songProvider.fetchSongs(query: '');
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (val) {
                  songProvider.fetchSongs(query: val);
                  setState(() {});
                },
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bài hát',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getText(context),
                  ),
                ),
                if (songs.isNotEmpty)
                  Text(
                    '${songs.length} bài hát',
                    style: AppTheme.monoStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.getTextSecondary(context),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (songs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Không tìm thấy bài hát nào',
                    style: TextStyle(
                        color: AppTheme.getTextMuted(context), fontSize: 12.5),
                  ),
                ),
              )
            else
              ...songs.map((song) => _buildSongTile(context, song)),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildSongTile(BuildContext context, Song song) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.getBorder(context), width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.getSurfaceSubtle(context),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border:
                  Border.all(color: AppTheme.getBorder(context), width: 0.8),
            ),
            clipBehavior: Clip.antiAlias,
            child: song.coverUrl != null && song.coverUrl!.isNotEmpty
                ? Image.network(
                    song.coverUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(Icons.music_note,
                        color: AppTheme.getTextMuted(context), size: 16),
                  )
                : Icon(Icons.music_note,
                    color: AppTheme.getTextMuted(context), size: 16),
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
                          color: AppTheme.getTextSecondary(context)),
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
          GestureDetector(
            onTap: () {
              final songProv =
                  Provider.of<SongProvider>(context, listen: false);
              final idx = songProv.songs.indexWhere((s) => s.id == song.id);
              audioPlayerService.setPlaylist(songProv.songs,
                  initialIndex: idx >= 0 ? idx : 0);
            },
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border:
                    Border.all(color: AppTheme.getBorder(context), width: 1.0),
                color: Colors.transparent,
              ),
              child: Center(
                child: Icon(Icons.play_arrow,
                    size: 16, color: AppTheme.getText(context)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
