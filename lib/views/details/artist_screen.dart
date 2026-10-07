import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/song_provider.dart';
import '../../models/song_model.dart';
import 'album_screen.dart';

class ArtistScreen extends StatefulWidget {
  final String artistName;

  const ArtistScreen({
    super.key,
    this.artistName = 'Sơn Tùng M-TP',
  });

  @override
  State<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> {
  bool _isFollowing = false;

  @override
  Widget build(BuildContext context) {
    final songProvider = Provider.of<SongProvider>(context);
    final songs = songProvider.songs;

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
          'Nghệ sĩ',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar (Compact 84x84, circle, subtle border)
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.getSurfaceSubtle(context),
                    border: Border.all(color: AppTheme.getBorder(context), width: 1.0),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: songs.isNotEmpty && songs.first.coverUrl != null
                      ? Image.network(
                          songs.first.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(Icons.person, size: 40, color: AppTheme.getTextMuted(context)),
                        )
                      : Icon(Icons.person, size: 40, color: AppTheme.getTextMuted(context)),
                ),
              ),

              const SizedBox(height: 12),

              // Artist Name & Stats
              Text(
                widget.artistName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.getText(context),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '12 albums · 214 songs',
                style: AppTheme.monoStyle(
                  fontSize: 11,
                  color: AppTheme.getTextSecondary(context),
                ),
              ),

              const SizedBox(height: 12),

              // Button: [ Theo dõi ] (compact 34px)
              SizedBox(
                height: 34,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _isFollowing ? AppTheme.getAction(context) : AppTheme.getSurface(context),
                    foregroundColor: _isFollowing ? AppTheme.getActionText(context) : AppTheme.getText(context),
                    side: BorderSide(
                      color: _isFollowing ? AppTheme.getAction(context) : AppTheme.getBorder(context),
                      width: 0.8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  onPressed: () {
                    setState(() => _isFollowing = !_isFollowing);
                  },
                  child: Text(
                    _isFollowing ? 'Đang theo dõi' : 'Theo dõi',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isFollowing ? AppTheme.getActionText(context) : AppTheme.getText(context),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Section 1: Album
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Album',
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

              SizedBox(
                height: 125,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildAlbumItem(
                      context,
                      title: 'Đừng Làm Trái Tim Anh Đau',
                      year: '2020',
                      coverUrl: songs.isNotEmpty ? songs.first.coverUrl : null,
                    ),
                    const SizedBox(width: 10),
                    _buildAlbumItem(
                      context,
                      title: 'Chúng Ta Của Hiện Tại',
                      year: '2019',
                      coverUrl: songs.length > 1 ? songs[1].coverUrl : null,
                    ),
                    const SizedBox(width: 10),
                    _buildAlbumItem(
                      context,
                      title: 'Lạc Trôi',
                      year: '2017',
                      coverUrl: songs.length > 2 ? songs[2].coverUrl : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Section 2: Bài hát phổ biến
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Bài hát phổ biến',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getText(context),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              if (songs.isEmpty)
                Center(
                  child: Text('Không có bài hát', style: TextStyle(color: AppTheme.getTextMuted(context), fontSize: 12)),
                )
              else
                ...songs.take(4).map((song) => _buildSongTile(context, song)),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumItem(BuildContext context, {required String title, required String year, String? coverUrl}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AlbumScreen(albumName: title, artistName: widget.artistName),
          ),
        );
      },
      child: SizedBox(
        width: 90,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 80,
              width: 90,
              decoration: BoxDecoration(
                color: AppTheme.getSurfaceSubtle(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: AppTheme.getBorder(context), width: 0.8),
              ),
              clipBehavior: Clip.antiAlias,
              child: coverUrl != null && coverUrl.isNotEmpty
                  ? Image.network(coverUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.album, size: 24, color: AppTheme.getTextMuted(context)))
                  : Icon(Icons.album, size: 24, color: AppTheme.getTextMuted(context)),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppTheme.getText(context)),
            ),
            Text(
              year,
              style: TextStyle(fontSize: 10, color: AppTheme.getTextSecondary(context)),
            ),
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
                ? Image.network(song.coverUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.music_note, size: 16, color: AppTheme.getTextMuted(context)))
                : Icon(Icons.music_note, size: 16, color: AppTheme.getTextMuted(context)),
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
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.getText(context)),
                ),
                const SizedBox(height: 1),
                Text(
                  song.formattedDuration,
                  style: AppTheme.monoStyle(fontSize: 10, color: AppTheme.getTextMuted(context)),
                ),
              ],
            ),
          ),
          Icon(Icons.more_vert, size: 18, color: AppTheme.getTextSecondary(context)),
        ],
      ),
    );
  }
}
