import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/audio_player_service.dart';

import '../core/theme/app_theme.dart';
import '../views/player/now_playing_screen.dart';

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
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 48,
                height: 48,
                color: AppTheme.surface,
                child: song.coverUrl != null && song.coverUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: song.coverUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (c, u, e) => const Icon(Icons.music_note, color: AppTheme.primaryLight),
                      )
                    : const Icon(Icons.music_note, color: AppTheme.primaryLight),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                playerService.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 30,
              ),
              onPressed: playerService.togglePlayPause,
            ),
            IconButton(
              icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 28),
              onPressed: playerService.next,
            ),
          ],
        ),
      ),
    );
  }
}
