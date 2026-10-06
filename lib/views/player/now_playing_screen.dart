import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reicon_flutter/reicon_flutter.dart';
import '../../services/audio_player_service.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/music_wave_widget.dart';
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
            actions: [
              // Nút cấu hình kiểu sóng nhạc (Wave Settings)
              Center(
                child: TerminalActionBtn(
                  onTap: () => showWaveSettingsDialog(context),
                  hasBorder: true,
                  defaultBorderColor: const Color(0xFF444444),
                  hoverBorderColor: AppTheme.terminalGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  defaultColor: AppTheme.textSecondary,
                  hoverColor: AppTheme.terminalGreen,
                  icon: ReIcon(Reicon.outline.setting2, size: 14),
                  label: 'WAVE_FX',
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  const SizedBox(height: 18),

                  // Cover Art vuông vức viền trắng đơn sắc
                  Center(
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: const BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.zero,
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
                  ),
                  const SizedBox(height: 16),

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
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '> ARTIST: ${song.artist}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '> CLOUD_ID: ${song.driveFileId ?? "LOCAL"}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Khung sóng nhạc Real-time Wave Visualizer
                  Consumer<SettingsProvider>(
                    builder: (context, settings, _) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: const BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.zero,
                          border: Border.fromBorderSide(BorderSide(color: Color(0xFF333333), width: 1.0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header thông tin sóng & nút chuyển đổi nhanh
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      color: playerService.isPlaying ? AppTheme.terminalGreen : AppTheme.textMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '// WAVE_DSP: ${settings.waveType.label}',
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textSecondary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                TerminalActionBtn(
                                  onTap: () => showWaveSettingsDialog(context),
                                  hasBorder: false,
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  defaultColor: AppTheme.textMuted,
                                  hoverColor: AppTheme.terminalGreen,
                                  icon: ReIcon(Reicon.outline.setting2, size: 12),
                                  label: 'CONFIG',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Dải sóng nhạc chuyển động theo nhạc (Chạm vào để đổi nhanh kiểu sóng)
                            GestureDetector(
                              onTap: settings.cycleWaveType,
                              child: Container(
                                height: 46,
                                width: double.infinity,
                                color: Colors.black,
                                alignment: Alignment.bottomCenter,
                                child: MusicWaveWidget(
                                  isPlaying: playerService.isPlaying,
                                  height: 46,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),

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
                          overlayShape: SliderComponentShape.noOverlay,
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
                  const SizedBox(height: 12),

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
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
