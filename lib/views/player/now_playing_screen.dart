import 'package:flutter/material.dart';
import 'package:reicon_flutter/reicon_flutter.dart';
import '../../services/audio_player_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/re_icon.dart';

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
            backgroundColor: AppTheme.background,
            body: Center(
              child: Text('> NO_TRACK_LOADED', style: TextStyle(fontFamily: 'monospace', color: AppTheme.textMuted)),
            ),
          );
        }

        final position = playerService.player.position;
        final duration = playerService.player.duration ?? Duration(seconds: song.duration);

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: AppTheme.background,
            elevation: 0,
            leading: Center(
              child: TerminalActionBtn(
                onTap: () => Navigator.of(context).pop(),
                hasBorder: false,
                padding: const EdgeInsets.all(6),
                defaultColor: AppTheme.textSecondary,
                hoverColor: AppTheme.terminalGreen,
                icon: ReIcon(Reicon.outline.arrowLeft, size: 18),
                label: 'ESC',
              ),
            ),
            leadingWidth: 70,
            title: const Text(
              '// AUDIO_ENGINE_EXEC',
              style: TextStyle(fontFamily: 'monospace', fontSize: 13, letterSpacing: 1.2),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: const BoxDecoration(
                      border: Border.fromBorderSide(BorderSide(color: AppTheme.border, width: 1)),
                      borderRadius: BorderRadius.zero,
                      color: AppTheme.surface,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              color: playerService.isPlaying ? AppTheme.terminalGreen : AppTheme.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              playerService.isPlaying ? 'STATE: STREAMING' : 'STATE: PAUSED',
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                        Text(
                          'BITRATE: 192K // ${song.format.toUpperCase()}',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),

                  // Cover Art vuông vức viền trắng đơn sắc
                  Container(
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: MediaQuery.of(context).size.width * 0.7,
                    decoration: const BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.zero, // Bỏ bo tròn hoàn toàn
                      border: Border.fromBorderSide(BorderSide(color: AppTheme.borderHighlight, width: 1.5)),
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
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Text('[ NO_COVER ]', style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppTheme.textMuted)),
                                  ),
                                );
                              }
                              return const Center(
                                child: Text('[ NO_COVER ]', style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppTheme.textMuted)),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: Text('> LOADING_ART...', style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppTheme.textMuted)),
                              );
                            },
                          )
                        : const Center(
                            child: Text('[ NO_COVER ]', style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppTheme.textMuted)),
                          ),
                  ),

                  // Metadata Text
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '> TITLE: ${song.title}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '> ARTIST: ${song.artist}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '> CLOUD_ID: ${song.driveFileId ?? "LOCAL"}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),

                  // Timeline Slider tối giản
                  Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 3),
                          activeTrackColor: AppTheme.terminalGreen,
                          inactiveTrackColor: AppTheme.border,
                          thumbColor: AppTheme.terminalGreen,
                          overlayShape: SliderComponentShape.noOverlay, // Bỏ quầng hover tròn
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
                            Text(_formatDuration(position), style: const TextStyle(fontFamily: 'monospace', color: AppTheme.textSecondary, fontSize: 11)),
                            Text(_formatDuration(duration), style: const TextStyle(fontFamily: 'monospace', color: AppTheme.textSecondary, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Playback Command Controls dùng Reicon và TerminalActionBtn
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TerminalActionBtn(
                        onTap: playerService.previous,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        defaultColor: AppTheme.textSecondary,
                        hoverColor: AppTheme.terminalGreen,
                        icon: ReIcon(Reicon.outline.skipPrev, size: 18),
                        label: 'PREV',
                      ),
                      TerminalActionBtn(
                        onTap: playerService.togglePlayPause,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                        defaultColor: playerService.isPlaying ? AppTheme.terminalGreen : AppTheme.textPrimary,
                        hoverColor: AppTheme.terminalGreen,
                        defaultBorderColor: playerService.isPlaying ? AppTheme.terminalGreen : AppTheme.textPrimary,
                        hoverBorderColor: AppTheme.terminalGreen,
                        icon: ReIcon(
                          playerService.isPlaying ? Reicon.outline.pause : Reicon.outline.play,
                          size: 20,
                        ),
                        label: playerService.isPlaying ? 'PAUSE' : 'PLAY',
                      ),
                      TerminalActionBtn(
                        onTap: playerService.next,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        defaultColor: AppTheme.textSecondary,
                        hoverColor: AppTheme.terminalGreen,
                        icon: ReIcon(Reicon.outline.skipNext, size: 18),
                        label: 'NEXT',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
