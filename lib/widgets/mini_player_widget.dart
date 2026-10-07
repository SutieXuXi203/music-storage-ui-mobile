import 'package:flutter/material.dart';
import 'package:reicon_flutter/reicon_flutter.dart';
import '../services/audio_player_service.dart';
import '../core/theme/app_theme.dart';
import '../views/player/now_playing_screen.dart';
import 'mini_equalizer_widget.dart';
import 're_icon.dart';

class MiniPlayerWidget extends StatefulWidget {
  final AudioPlayerService playerService;

  const MiniPlayerWidget({super.key, required this.playerService});

  @override
  State<MiniPlayerWidget> createState() => _MiniPlayerWidgetState();
}

class _MiniPlayerWidgetState extends State<MiniPlayerWidget> {
  bool _isHovered = false;

  void _openNowPlaying(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.65),
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 480),
        reverseTransitionDuration: const Duration(milliseconds: 380),
        pageBuilder: (context, anim, secAnim) => NowPlayingScreen(playerService: widget.playerService),
        transitionsBuilder: (context, anim, secAnim, child) {
          final curve = CurvedAnimation(
            parent: anim,
            curve: const Cubic(0.2, 0.9, 0.3, 1.0),
            reverseCurve: Curves.easeInCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1.0),
              end: Offset.zero,
            ).animate(curve),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.playerService,
      builder: (context, _) {
        final song = widget.playerService.currentSong;
        if (song == null) return const SizedBox.shrink();

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: () => _openNowPlaying(context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.zero,
                border: Border(
                  top: BorderSide(
                    color: _isHovered ? AppTheme.terminalGreen : AppTheme.borderHighlight,
                    width: _isHovered ? 1.5 : 1.0,
                  ),
                ),
                boxShadow: _isHovered
                    ? [
                        BoxShadow(
                          color: AppTheme.terminalGreen.withValues(alpha: 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, -2),
                        ),
                      ]
                    : null,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Thanh tiến trình chạy cực mỏng
                    StreamBuilder<Duration>(
                      stream: widget.playerService.player.positionStream,
                      builder: (context, snapshot) {
                        final position = snapshot.data ?? Duration.zero;
                        final duration = widget.playerService.player.duration ?? Duration(seconds: song.duration);
                        final progress = duration.inMilliseconds > 0
                            ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
                            : 0.0;

                        return Container(
                          height: 2,
                          width: double.infinity,
                          color: AppTheme.border,
                          alignment: Alignment.centerLeft,
                          child: AnimatedFractionallySizedBox(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.linear,
                            widthFactor: progress,
                            child: Container(color: AppTheme.terminalGreen),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 6),

                    Row(
                      children: [
                        // Dấu prompt terminal hoặc Mini Equalizer khi đang phát
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: widget.playerService.isPlaying
                              ? const Padding(
                                  padding: EdgeInsets.only(right: 6),
                                  child: MiniEqualizerWidget(
                                    isPlaying: true,
                                    height: 12,
                                    width: 14,
                                    barCount: 3,
                                    color: AppTheme.terminalGreen,
                                  ),
                                )
                              : const Padding(
                                  padding: EdgeInsets.only(right: 2),
                                  child: Text(
                                    '> ',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.terminalGreen,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                        ),

                        // Cover Art với Hero animation bay mượt mà vào NowPlayingScreen
                        Container(
                          width: 38,
                          height: 38,
                          margin: const EdgeInsets.only(right: 10),
                          child: Hero(
                            tag: 'player_cover_art_${song.id}',
                            flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
                              return Material(
                                color: Colors.transparent,
                                child: toHeroContext.widget,
                              );
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                color: AppTheme.background,
                                borderRadius: BorderRadius.zero,
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
                          ),
                        ),

                          // Tên bài hát & ca sĩ với hiệu ứng chuyển đổi mượt mà
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                              child: KeyedSubtree(
                                key: ValueKey(song.id),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      song.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: _isHovered ? AppTheme.terminalGreen : AppTheme.textPrimary,
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
                            ),
                          ),

                          // Nút Play / Pause dùng Reicon
                          TerminalActionBtn(
                            onTap: widget.playerService.togglePlayPause,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            defaultColor: widget.playerService.isPlaying ? AppTheme.terminalGreen : AppTheme.textPrimary,
                            hoverColor: AppTheme.terminalGreen,
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                              child: ReIcon(
                                widget.playerService.isPlaying ? Reicon.outline.pause : Reicon.outline.play,
                                key: ValueKey(widget.playerService.isPlaying),
                                size: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Nút Next dùng Reicon
                          TerminalActionBtn(
                            onTap: widget.playerService.next,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            defaultColor: AppTheme.textSecondary,
                            hoverColor: AppTheme.terminalGreen,
                            icon: ReIcon(
                              Reicon.outline.skipNext,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Nút mở rộng trình phát toàn màn hình
                          TerminalActionBtn(
                            onTap: () => _openNowPlaying(context),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            defaultColor: AppTheme.terminalGreen,
                            hoverColor: Colors.white,
                            defaultBorderColor: AppTheme.border,
                            hoverBorderColor: AppTheme.terminalGreen,
                            icon: ReIcon(
                              Reicon.outline.arrowUp2,
                              size: 15,
                            ),
                          ),
                        ],
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
