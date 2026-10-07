import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/audio_player_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/song_model.dart';
import 'queue_screen.dart';

class NowPlayingScreen extends StatefulWidget {
  final AudioPlayerService playerService;

  const NowPlayingScreen({super.key, required this.playerService});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  double _dragOffset = 0.0;
  bool _isDraggingSeek = false;
  double _seekPosition = 0.0;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '00:00';
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (details.delta.dy > 0 || _dragOffset > 0) {
      setState(() {
        _dragOffset = math.max(0.0, _dragOffset + details.delta.dy);
      });
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0.0;
    if (_dragOffset > 120 || velocity > 280) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _dragOffset = 0.0;
      });
    }
  }

  void _showMoreMenu(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.getSurfaceElevated(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusSheet)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 3,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.getTextMuted(context).withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                dense: true,
                leading: Icon(Icons.queue_music, color: AppTheme.getText(context), size: 20),
                title: Text('Xem hàng đợi phát nhạc', style: TextStyle(fontSize: 13, color: AppTheme.getText(context))),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const QueueScreen()));
                },
              ),
              ListTile(
                dense: true,
                leading: Icon(Icons.playlist_add, color: AppTheme.getText(context), size: 20),
                title: Text('Thêm vào danh sách phát', style: TextStyle(fontSize: 13, color: AppTheme.getText(context))),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã thêm "${song.title}" vào playlist!'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
              ListTile(
                dense: true,
                leading: Icon(Icons.info_outline, color: AppTheme.getText(context), size: 20),
                title: Text('Chi tiết kỹ thuật tệp', style: TextStyle(fontSize: 13, color: AppTheme.getText(context))),
                subtitle: Text(
                  '${song.format.toUpperCase()} · ${song.bitrate.toUpperCase()} · Google Drive',
                  style: AppTheme.monoStyle(fontSize: 11, color: AppTheme.getTextSecondary(context)),
                ),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.playerService,
      builder: (context, _) {
        final song = widget.playerService.currentSong;
        if (song == null) {
          return Scaffold(
            backgroundColor: AppTheme.getBg(context),
            body: Center(
              child: Text(
                'NO_TRACK_LOADED',
                style: AppTheme.monoStyle(color: AppTheme.getTextMuted(context)),
              ),
            ),
          );
        }

        final position = widget.playerService.player.position;
        final duration = widget.playerService.player.duration ?? Duration(seconds: song.duration > 0 ? song.duration : 1);
        final totalSeconds = duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1000.0;
        final currentSeconds = _isDraggingSeek
            ? _seekPosition
            : position.inMilliseconds.toDouble().clamp(0.0, totalSeconds);

        final nextSong = widget.playerService.nextSong;

        return Transform.translate(
          offset: Offset(0, _dragOffset),
          child: Scaffold(
            backgroundColor: AppTheme.getBg(context),
            appBar: AppBar(
              backgroundColor: AppTheme.getBg(context),
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.keyboard_arrow_down, size: 26, color: AppTheme.getText(context)),
                onPressed: () => Navigator.of(context).pop(),
              ),
              centerTitle: true,
              title: Text(
                'AUDIO_ENGINE_EXEC',
                style: AppTheme.monoStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.getTextSecondary(context),
                  letterSpacing: 1.2,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.more_horiz, size: 20, color: AppTheme.getText(context)),
                  onPressed: () => _showMoreMenu(context, song),
                ),
              ],
            ),
            body: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onVerticalDragUpdate: _onVerticalDragUpdate,
              onVerticalDragEnd: _onVerticalDragEnd,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Column(
                    children: [
                      const Spacer(flex: 1),

                      // 1. Cover Art (Square rounded 240x240)
                      Center(
                        child: Container(
                          width: 230,
                          height: 230,
                          decoration: BoxDecoration(
                            color: AppTheme.getSurfaceSubtle(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.getBorder(context), width: 1.0),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: song.coverUrl != null && song.coverUrl!.isNotEmpty
                              ? Image.network(
                                  song.coverUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.music_note,
                                    size: 64,
                                    color: AppTheme.getTextMuted(context),
                                  ),
                                )
                              : Icon(
                                  Icons.music_note,
                                  size: 64,
                                  color: AppTheme.getTextMuted(context),
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 2. Track Title & Artist
                      Text(
                        song.title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.getText(context),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.artist,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.getTextSecondary(context),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 3. Audio Waveform Progress Indicator
                      _buildWaveformBar(context, currentSeconds / totalSeconds),

                      const SizedBox(height: 6),

                      // 4. Timestamps Row (Mono)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(_isDraggingSeek ? Duration(milliseconds: _seekPosition.round()) : position),
                              style: AppTheme.monoStyle(
                                fontSize: 11,
                                color: AppTheme.getTextSecondary(context),
                              ),
                            ),
                            Text(
                              _formatDuration(duration),
                              style: AppTheme.monoStyle(
                                fontSize: 11,
                                color: AppTheme.getTextSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // 5. Playback Controls Row: [ Shuffle | Prev | Play/Pause Circle | Next | Repeat ]
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.shuffle,
                              size: 20,
                              color: widget.playerService.isShuffle
                                  ? AppTheme.getText(context)
                                  : AppTheme.getTextMuted(context),
                            ),
                            onPressed: () => widget.playerService.toggleShuffle(),
                          ),
                          IconButton(
                            icon: Icon(Icons.skip_previous, size: 28, color: AppTheme.getText(context)),
                            onPressed: () => widget.playerService.previous(),
                          ),
                          // Circle Play/Pause Button
                          GestureDetector(
                            onTap: () {
                              if (widget.playerService.isPlaying) {
                                widget.playerService.pause();
                              } else {
                                widget.playerService.resume();
                              }
                            },
                            child: Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.getSurface(context),
                                border: Border.all(color: AppTheme.getText(context), width: 1.5),
                              ),
                              child: Center(
                                child: Icon(
                                  widget.playerService.isPlaying ? Icons.pause : Icons.play_arrow,
                                  size: 30,
                                  color: AppTheme.getText(context),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.skip_next, size: 28, color: AppTheme.getText(context)),
                            onPressed: () => widget.playerService.next(),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.repeat,
                              size: 20,
                              color: widget.playerService.isLoop
                                  ? AppTheme.getText(context)
                                  : AppTheme.getTextMuted(context),
                            ),
                            onPressed: () => widget.playerService.toggleLoop(),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // 6. Technical Audio Specs Ticker: [ MP3 | 192 KBPS | 44.1 KHZ ]
                      Text(
                        '${song.format.toUpperCase()}  |  ${song.bitrate.toUpperCase()}  |  44.1 KHZ',
                        style: AppTheme.monoStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.getTextMuted(context),
                          letterSpacing: 1.0,
                        ),
                      ),

                      const Spacer(flex: 1),

                      // 7. Peek Card: [ Tiếp theo ]
                      if (nextSong != null) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Tiếp theo',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.getText(context),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const QueueScreen()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.getSurface(context),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              border: Border.all(color: AppTheme.getBorder(context), width: 0.8),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppTheme.getSurfaceSubtle(context),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppTheme.getBorder(context), width: 0.8),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: nextSong.coverUrl != null && nextSong.coverUrl!.isNotEmpty
                                      ? Image.network(
                                          nextSong.coverUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(
                                            Icons.music_note,
                                            size: 16,
                                            color: AppTheme.getTextMuted(context),
                                          ),
                                        )
                                      : Icon(
                                          Icons.music_note,
                                          size: 16,
                                          color: AppTheme.getTextMuted(context),
                                        ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        nextSong.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.getText(context),
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        '${nextSong.artist} · ${nextSong.formattedDuration}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTheme.monoStyle(
                                          fontSize: 10,
                                          color: AppTheme.getTextSecondary(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: AppTheme.getTextMuted(context),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaveformBar(BuildContext context, double progress) {
    final isPlaying = widget.playerService.isPlaying;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (details) {
        final duration = widget.playerService.player.duration;
        if (duration == null) return;
        setState(() {
          _isDraggingSeek = true;
          _seekPosition = (details.localPosition.dx / MediaQuery.of(context).size.width) * duration.inMilliseconds;
        });
      },
      onHorizontalDragUpdate: (details) {
        final duration = widget.playerService.player.duration;
        if (duration == null) return;
        final screenWidth = MediaQuery.of(context).size.width - 48;
        final ratio = (details.localPosition.dx / screenWidth).clamp(0.0, 1.0);
        setState(() {
          _seekPosition = ratio * duration.inMilliseconds;
        });
      },
      onHorizontalDragEnd: (details) {
        setState(() {
          _isDraggingSeek = false;
        });
        widget.playerService.seek(Duration(milliseconds: _seekPosition.round()));
      },
      child: SizedBox(
        height: 28,
        child: AnimatedBuilder(
          animation: _waveController,
          builder: (context, _) {
            const barCount = 42;
            final activeBarCount = (progress.clamp(0.0, 1.0) * barCount).round();

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(barCount, (index) {
                final isActive = index <= activeBarCount;

                // Subtle animation wave modulation
                final baseHeight = 4.0 + (math.sin(index * 0.45) * 8.0).abs() + ((index % 3 == 0) ? 6.0 : 2.0);
                final waveMod = isPlaying ? math.sin((index * 0.3) + (_waveController.value * math.pi * 2)) * 3.0 : 0.0;
                final barHeight = (baseHeight + waveMod).clamp(3.0, 24.0);

                return Container(
                  width: 2.2,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.getText(context)
                        : AppTheme.getTextMuted(context).withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(1),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
