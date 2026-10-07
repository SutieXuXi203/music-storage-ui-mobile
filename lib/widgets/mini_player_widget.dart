import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/audio_player_service.dart';
import '../core/theme/app_theme.dart';
import '../views/player/now_playing_screen.dart';

class MiniPlayerWidget extends StatelessWidget {
  final AudioPlayerService playerService;

  const MiniPlayerWidget({super.key, required this.playerService});

  void _openNowPlaying(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.6),
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, anim, secAnim) =>
            NowPlayingScreen(playerService: playerService),
        transitionsBuilder: (context, anim, secAnim, child) {
          final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1.0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: playerService,
      builder: (context, _) {
        final song = playerService.currentSong;
        if (song == null) return const SizedBox.shrink();

        final isPlaying = playerService.isPlaying;
        final surfaceColor = AppTheme.getSurfaceElevated(context);
        final borderColor = AppTheme.getBorder(context);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _openNowPlaying(context),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      surfaceColor.withValues(alpha: 0.65),
                      surfaceColor.withValues(alpha: 0.90),
                    ],
                  ),
                  border: Border(
                    top: BorderSide(
                      color: borderColor.withValues(alpha: 0.6),
                      width: 0.8,
                    ),
                  ),
                ),
            child: Column(
              children: [
                // Thin progress line on top (1.5px)
                StreamBuilder<Duration>(
                  stream: playerService.player.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final duration = playerService.player.duration ??
                        Duration(seconds: song.duration);
                    final progress = duration.inMilliseconds > 0
                        ? (position.inMilliseconds / duration.inMilliseconds)
                            .clamp(0.0, 1.0)
                        : 0.0;

                    return LinearProgressIndicator(
                      value: progress,
                      minHeight: 1.5,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.getText(context),
                      ),
                    );
                  },
                ),

                // Content row
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        // Small square album artwork (36x36, 8px radius)
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
                          child: (song.coverUrl != null && song.coverUrl!.isNotEmpty)
                              ? Image.network(
                                  song.coverUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.music_note,
                                    color: AppTheme.getTextMuted(context),
                                    size: 18,
                                  ),
                                )
                              : Icon(
                                  Icons.music_note,
                                  color: AppTheme.getTextMuted(context),
                                  size: 18,
                                ),
                        ),
                        const SizedBox(width: 10),

                        // Song title & artist
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppTheme.getText(context),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppTheme.getTextSecondary(context),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Compact Play/Pause button
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                          icon: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: AppTheme.getText(context),
                            size: 22,
                          ),
                          onPressed: () {
                            if (isPlaying) {
                              playerService.pause();
                            } else {
                              playerService.resume();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
      },
    );
  }
}
