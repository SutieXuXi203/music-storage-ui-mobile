import 'package:flutter/material.dart';
import 'package:reicon_flutter/reicon_flutter.dart';
import '../services/audio_player_service.dart';
import '../core/theme/app_theme.dart';
import '../views/player/now_playing_screen.dart';
import 're_icon.dart';

class MiniPlayerWidget extends StatelessWidget {
  final AudioPlayerService playerService;

  const MiniPlayerWidget({super.key, required this.playerService});

  @override
  Widget build(BuildContext context) {
    final song = playerService.currentSong;
    if (song == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, anim, secAnim) => NowPlayingScreen(playerService: playerService),
            transitionsBuilder: (context, anim, secAnim, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                child: child,
              );
            },
          ),
        );
      },
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.zero, // Bỏ bo tròn hoàn toàn
          border: Border(
            top: BorderSide(color: AppTheme.borderHighlight, width: 1.0),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thanh tiến trình chạy cực mỏng, không bo góc
              StreamBuilder<Duration>(
                stream: playerService.player.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final duration = playerService.player.duration ?? Duration(seconds: song.duration);
                  final progress = duration.inMilliseconds > 0
                      ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
                      : 0.0;

                  return Container(
                    height: 2,
                    width: double.infinity,
                    color: AppTheme.border,
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(color: AppTheme.terminalGreen),
                    ),
                  );
                },
              ),
              const SizedBox(height: 6),

              Row(
                children: [
                  // Dấu prompt terminal
                  const Text(
                    '> ',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      color: AppTheme.terminalGreen,
                      fontSize: 14,
                    ),
                  ),

                  // Cover Art thu nhỏ vuông vức viền mảnh
                  Container(
                    width: 38,
                    height: 38,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: const BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.zero, // Bỏ bo tròn
                      border: Border.fromBorderSide(BorderSide(color: AppTheme.border, width: 1)),
                    ),
                    child: song.coverUrl != null && song.coverUrl!.isNotEmpty
                        ? Image.network(
                            song.coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              final coverId = song.coverDriveFileId ?? song.thumbnailDriveFileId;
                              if (coverId != null && !song.coverUrl!.contains('googleusercontent')) {
                                return Image.network(
                                  'https://lh3.googleusercontent.com/d/$coverId',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: ReIcon(Reicon.outline.musicNote, size: 14, color: AppTheme.textMuted),
                                  ),
                                );
                              }
                              return Center(
                                child: ReIcon(Reicon.outline.musicNote, size: 14, color: AppTheme.textMuted),
                              );
                            },
                          )
                        : Center(
                            child: ReIcon(Reicon.outline.musicNote, size: 14, color: AppTheme.textMuted),
                          ),
                  ),

                  // Tên bài hát & ca sĩ
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '${song.artist} // ${song.format.toUpperCase()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Nút Play / Pause dùng Reicon
                  TerminalActionBtn(
                    onTap: playerService.togglePlayPause,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    defaultColor: playerService.isPlaying ? AppTheme.terminalGreen : AppTheme.textPrimary,
                    hoverColor: AppTheme.terminalGreen,
                    icon: ReIcon(
                      playerService.isPlaying ? Reicon.outline.pause : Reicon.outline.play,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Nút Next dùng Reicon
                  TerminalActionBtn(
                    onTap: playerService.next,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    defaultColor: AppTheme.textSecondary,
                    hoverColor: AppTheme.terminalGreen,
                    icon: ReIcon(
                      Reicon.outline.skipNext,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
