import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/song_provider.dart';
import '../../../services/audio_player_service.dart';
import '../../../models/song_model.dart';
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
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final songProvider = Provider.of<SongProvider>(context);

    final user = authProvider.user;
    final userName = (user != null && user.fullName != null && user.fullName!.isNotEmpty)
        ? user.fullName!
        : (user != null && user.username.isNotEmpty ? user.username : 'Mạnh Đình');
    final songs = songProvider.songs;

    return Scaffold(
      backgroundColor: AppTheme.getBg(context),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await songProvider.fetchSongs();
          },
          color: AppTheme.getText(context),
          backgroundColor: AppTheme.getSurface(context),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // 1. Header (MUSIC_STORAGE + v1.0 / ONLINE status, Notification bell, Avatar)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MUSIC_STORAGE',
                        style: AppTheme.monoStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppTheme.getText(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Color(0xFF22C55E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'v1.0 / ONLINE',
                            style: AppTheme.monoStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.getTextSecondary(context),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Actions: Notification Bell + Avatar
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Notification Bell with unread dot
                      Stack(
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                            icon: Icon(
                              Icons.notifications_none_outlined,
                              size: 20,
                              color: AppTheme.getText(context),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Hệ thống hoạt động bình thường • v1.0 ONLINE'),
                                  duration: Duration(seconds: 1),
                                ),
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
                                color: Color(0xFF22C55E),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),

                      // Avatar (34x34px, compact, tap -> Settings)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          );
                        },
                        child: Container(
                          width: 34,
                          height: 34,
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
                              userName.isNotEmpty ? userName[0].toUpperCase() : 'M',
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

              // 2. Greeting: Chào bạn, Mạnh Đình + 14 bài hát đã được lưu...
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

              // 2. Section: Recently Played
              _buildSectionHeader('Recently Played', onSeeAll: widget.onNavigateToLibrary),
              const SizedBox(height: 8),

              if (songs.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No recent songs',
                      style: TextStyle(color: AppTheme.getTextMuted(context), fontSize: 12),
                    ),
                  ),
                )
              else
                ...songs.map((song) => _buildRecentSongTile(context, song)),

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

  Widget _buildRecentSongTile(BuildContext context, Song song) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: AppTheme.getBorder(context),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          // Thumbnail (36x36px)
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

          // Compact Circular Play button (28x28px)
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
          ),
        ],
      ),
    );
  }
}
