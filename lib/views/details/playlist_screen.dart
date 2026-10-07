import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/song_provider.dart';
import '../../services/audio_player_service.dart';
import '../../models/song_model.dart';

class PlaylistScreen extends StatelessWidget {
  final String title;

  const PlaylistScreen({
    super.key,
    this.title = 'Danh sách phát',
  });

  @override
  Widget build(BuildContext context) {
    final songProvider = Provider.of<SongProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final songs = songProvider.songs;

    final owner = authProvider.user?.fullName ?? authProvider.user?.username ?? 'Mạnh Đình';

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
          'Playlist',
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
                  // Cover (Compact 180x180, radius 12, subtle border)
                  Center(
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: AppTheme.getSurfaceSubtle(context),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: AppTheme.getBorder(context), width: 1.0),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: songs.isNotEmpty && songs.first.coverUrl != null
                          ? Image.network(
                              songs.first.coverUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(Icons.queue_music, size: 48, color: AppTheme.getTextMuted(context)),
                            )
                          : Icon(Icons.queue_music, size: 48, color: AppTheme.getTextMuted(context)),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Title, Owner, Stats
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.getText(context),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'by $owner',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.getTextSecondary(context),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${songs.length} bài hát',
                    style: AppTheme.monoStyle(
                      fontSize: 11,
                      color: AppTheme.getTextMuted(context),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action Buttons: [ ▶ Play ] [ ⤮ Shuffle ]
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.getAction(context),
                              foregroundColor: AppTheme.getActionText(context),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              ),
                            ),
                            onPressed: () {
                              if (songs.isNotEmpty) {
                                audioPlayerService.setPlaylist(songs, initialIndex: 0);
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_arrow, size: 18, color: AppTheme.getActionText(context)),
                                const SizedBox(width: 4),
                                Text('Play', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppTheme.getActionText(context))),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppTheme.getSurface(context),
                              foregroundColor: AppTheme.getText(context),
                              side: BorderSide(color: AppTheme.getBorder(context), width: 1.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              ),
                            ),
                            onPressed: () {
                              if (songs.isNotEmpty) {
                                audioPlayerService.toggleShuffle();
                                audioPlayerService.setPlaylist(songs, initialIndex: 0);
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shuffle, size: 16, color: AppTheme.getText(context)),
                                const SizedBox(width: 4),
                                Text('Shuffle', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: AppTheme.getText(context))),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Secondary Actions: [ + Thêm ] [ ⤓ Tải xuống ] [ ↪ Chia sẻ ]
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPillAction(context, icon: Icons.add, label: 'Thêm'),
                      _buildPillAction(context, icon: Icons.download_outlined, label: 'Tải xuống'),
                      _buildPillAction(context, icon: Icons.share_outlined, label: 'Chia sẻ'),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Tracks Section Header
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Danh sách bài hát',
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
                      child: Text('Danh sách phát đang trống', style: TextStyle(color: AppTheme.getTextMuted(context), fontSize: 12)),
                    )
                  else
                    ...List.generate(songs.length, (idx) {
                      final song = songs[idx];
                      final trackStr = '${idx + 1}';
                      return _buildTrackRow(context, trackStr: trackStr, song: song);
                    }),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      }

  Widget _buildPillAction(BuildContext context, {required IconData icon, required String label}) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.getSurface(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          border: Border.all(color: AppTheme.getBorder(context), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.getTextSecondary(context)),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppTheme.getText(context))),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackRow(BuildContext context, {required String trackStr, required Song song}) {
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
          // Track number: 1, 2...
          SizedBox(
            width: 18,
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
                Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: AppTheme.getTextSecondary(context)),
                ),
              ],
            ),
          ),

          // Duration in monospace
          Text(
            song.formattedDuration,
            style: AppTheme.monoStyle(
              fontSize: 10,
              color: AppTheme.getTextMuted(context),
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.more_vert, size: 18, color: AppTheme.getTextMuted(context)),
        ],
      ),
    );
  }
}
