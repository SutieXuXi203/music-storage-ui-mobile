import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/song_provider.dart';
import '../../../services/audio_player_service.dart';
import '../../../models/song_model.dart';
import '../../details/artist_screen.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['Songs', 'Artists'];

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
            // 1. Search Bar Input (height 42px)
            Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.getSurface(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: AppTheme.getBorder(context), width: 1.0),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(fontSize: 13, color: AppTheme.getText(context)),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Tìm kiếm bài hát, nghệ sĩ, album...',
                  hintStyle: TextStyle(color: AppTheme.getTextMuted(context), fontSize: 12.5),
                  prefixIcon: Icon(Icons.search, size: 18, color: AppTheme.getTextMuted(context)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(Icons.close, size: 16, color: AppTheme.getTextSecondary(context)),
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

            const SizedBox(height: 12),

            // 2. Filter Pills: [ Songs ] [ Artists ] [ Albums ]
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: List.generate(_filters.length, (idx) {
                  final isSelected = _selectedFilterIndex == idx;
                  final activeBg = AppTheme.getAction(context);
                  final activeText = AppTheme.getActionText(context);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilterIndex = idx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? activeBg : AppTheme.getSurface(context),
                          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                          border: Border.all(
                            color: isSelected ? activeBg : AppTheme.getBorder(context),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          _filters[idx],
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? activeText : AppTheme.getTextSecondary(context),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 18),

            // 3. Section: Bài hát (when Songs or general search)
            if (_selectedFilterIndex == 0) ...[
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
                  Text(
                    'Xem tất cả →',
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'No songs found',
                      style: TextStyle(color: AppTheme.getTextMuted(context), fontSize: 12),
                    ),
                  ),
                )
              else
                ...songs.take(4).map((song) => _buildSongTile(context, song)),

              const SizedBox(height: 16),
            ],

            // 4. Section: Nghệ sĩ (when Songs overview or Artists tab)
            if (_selectedFilterIndex == 0 || _selectedFilterIndex == 1) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nghệ sĩ',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getText(context),
                    ),
                  ),
                  Text(
                    'Xem tất cả →',
                    style: AppTheme.monoStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.getTextSecondary(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Artist Tile (Compact: 38px circular avatar)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ArtistScreen(artistName: 'Sơn Tùng M-TP'),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.getSurface(context),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(color: AppTheme.getBorder(context), width: 0.8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.getSurfaceSubtle(context),
                          border: Border.all(color: AppTheme.getBorder(context), width: 0.8),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: songs.isNotEmpty && songs.first.coverUrl != null
                            ? Image.network(
                                songs.first.coverUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text('S', style: TextStyle(color: AppTheme.getText(context), fontWeight: FontWeight.w600, fontSize: 14)),
                                ),
                              )
                            : Center(
                                child: Text('S', style: TextStyle(color: AppTheme.getText(context), fontWeight: FontWeight.w600, fontSize: 14)),
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Sơn Tùng M-TP',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.getText(context),
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '12 albums · 214 songs',
                              style: AppTheme.monoStyle(
                                fontSize: 10.5,
                                color: AppTheme.getTextSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: AppTheme.getTextMuted(context), size: 18),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 120),
            ],
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
                      style: TextStyle(fontSize: 11, color: AppTheme.getTextSecondary(context)),
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
              final songProv = Provider.of<SongProvider>(context, listen: false);
              final idx = songProv.songs.indexWhere((s) => s.id == song.id);
              audioPlayerService.setPlaylist(songProv.songs, initialIndex: idx >= 0 ? idx : 0);
            },
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.getBorder(context), width: 1.0),
                color: Colors.transparent,
              ),
              child: Center(
                child: Icon(Icons.play_arrow, size: 16, color: AppTheme.getText(context)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
