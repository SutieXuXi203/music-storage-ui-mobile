import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/audio_player_service.dart';
import '../core/theme/app_theme.dart';
import '../models/song_model.dart';
import '../views/player/now_playing_screen.dart';
import 'tech_playback_controls.dart';

class MiniPlayerWidget extends StatelessWidget {
  final AudioPlayerService playerService;

  const MiniPlayerWidget({super.key, required this.playerService});

  void _openNowPlaying(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.54),
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (context, anim, secAnim) =>
            NowPlayingScreen(playerService: playerService),
        transitionsBuilder: (context, anim, secAnim, child) {
          final reduceMotion = MediaQuery.of(context).disableAnimations;
          if (reduceMotion) {
            return FadeTransition(opacity: anim, child: child);
          }
          final curved = CurvedAnimation(
            parent: anim,
            curve: const Cubic(0.2, 0.0, 0.0, 1.0),
            reverseCurve: Curves.easeInCubic,
          );
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
        final bool isVisible = song != null;
        final bool reduceMotion = MediaQuery.of(context).disableAnimations;

        return ClipRect(
          child: AnimatedSize(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.35),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: isVisible
                  ? _buildPlayerBar(context, song)
                  : const SizedBox(
                      key: ValueKey('mini_player_collapsed'),
                      width: double.infinity,
                      height: 0,
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayerBar(BuildContext context, Song song) {
    final isPlaying = playerService.isPlaying;
    final surfaceColor = AppTheme.getSurfaceElevated(context);
    final borderColor = AppTheme.getBorder(context);

    return Container(
      key: const ValueKey('mini_player_active_bar'),
      height: 54,
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          top: BorderSide(
            color: borderColor.withValues(alpha: 0.6),
            width: 0.8,
          ),
        ),
      ),
          child: Column(
            children: [
              _buildProgressBar(context, song),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _openNowPlaying(context);
                          },
                          child: Row(
                            children: [
                              _buildCoverImage(context, song),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildSongInfo(context, song),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TechPlayCoreButton(
                        isPlaying: isPlaying,
                        size: 34,
                        onTap: () {
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
        );
      }

  Widget _buildProgressBar(BuildContext context, Song song) {
    return StreamBuilder<Duration>(
      stream: playerService.player.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = playerService.player.duration ??
            Duration(seconds: song.duration);
        final progress = duration.inMilliseconds > 0
            ? (position.inMilliseconds / duration.inMilliseconds)
                .clamp(0.0, 1.0)
            : 0.0;

        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 250),
          curve: Curves.linear,
          tween: Tween<double>(begin: 0.0, end: progress),
          builder: (context, smoothValue, _) {
            return LinearProgressIndicator(
              value: smoothValue,
              minHeight: 2.0,
              backgroundColor:
                  AppTheme.getBorder(context).withValues(alpha: 0.35),
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.getText(context),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCoverImage(BuildContext context, Song song) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return AnimatedSwitcher(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: Container(
        key: ValueKey('mini_cover_${song.id}'),
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
        child: AppCoverImage(
          url: song.coverUrl,
          fallbackUrl: song.fallbackCoverUrl,
          width: 36,
          height: 36,
          borderRadius: AppTheme.radiusSm,
          iconSize: 18,
        ),
      ),
    );
  }

  Widget _buildSongInfo(BuildContext context, Song song) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return ClipRect(
      child: AnimatedSwitcher(
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeOutCubic,
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            alignment: Alignment.centerLeft,
            children: <Widget>[
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        transitionBuilder: (child, animation) {
          if (reduceMotion) {
            return FadeTransition(opacity: animation, child: child);
          }
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(0.04, 0.0),
            end: Offset.zero,
          ).animate(animation);

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: offsetAnimation,
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey('mini_info_${song.id}'),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }
}
