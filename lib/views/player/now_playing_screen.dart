import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/audio_player_service.dart';
import '../../core/theme/app_theme.dart';

class NowPlayingScreen extends StatelessWidget {
  final AudioPlayerService playerService;

  const NowPlayingScreen({super.key, required this.playerService});

  String _formatDuration(Duration? duration) {
    if (duration == null) return '00:00';
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: playerService,
      builder: (context, _) {
        final song = playerService.currentSong;
        if (song == null) {
          return const Scaffold(
            body: Center(child: Text('Chưa có bài hát nào được chọn')),
          );
        }

        final position = playerService.player.position;
        final duration = playerService.player.duration ?? Duration(seconds: song.duration);

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 36, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text('ĐANG PHÁT', style: TextStyle(fontSize: 14, letterSpacing: 1.5, color: AppTheme.textSecondary)),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Album Art
                Center(
                  child: Hero(
                    tag: 'album_art_${song.id}',
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.75,
                      height: MediaQuery.of(context).size.width * 0.75,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.35),
                            blurRadius: 30,
                            spreadRadius: 2,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: song.coverUrl != null && song.coverUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: song.coverUrl!,
                                fit: BoxFit.cover,
                                errorWidget: (c, u, e) => Container(
                                  color: AppTheme.surfaceLight,
                                  child: const Icon(Icons.music_note, size: 80, color: AppTheme.primaryLight),
                                ),
                              )
                            : Container(
                                color: AppTheme.surfaceLight,
                                child: const Icon(Icons.music_note, size: 80, color: AppTheme.primaryLight),
                              ),
                      ),
                    ),
                  ),
                ),

                // Info: Title & Artist
                Column(
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),

                // Progress Slider
                Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        trackHeight: 4,
                        activeTrackColor: AppTheme.primary,
                        inactiveTrackColor: AppTheme.surfaceLight,
                        thumbColor: Colors.white,
                      ),
                      child: Slider(
                        value: position.inSeconds.toDouble().clamp(0.0, duration.inSeconds.toDouble()),
                        max: duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1.0,
                        onChanged: (val) {
                          playerService.seek(Duration(seconds: val.toInt()));
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(position), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          Text(_formatDuration(duration), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),

                // Playback Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shuffle_rounded, color: AppTheme.textSecondary, size: 26),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 38),
                      onPressed: playerService.previous,
                    ),
                    GestureDetector(
                      onTap: playerService.togglePlayPause,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppTheme.primary, AppTheme.accent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          playerService.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 38),
                      onPressed: playerService.next,
                    ),
                    IconButton(
                      icon: const Icon(Icons.repeat_rounded, color: AppTheme.textSecondary, size: 26),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
