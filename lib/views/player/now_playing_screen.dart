import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reicon_flutter/reicon_flutter.dart';
import '../../services/audio_player_service.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/music_wave_widget.dart';
import '../../widgets/re_icon.dart';

class NowPlayingScreen extends StatefulWidget {
  final AudioPlayerService playerService;

  const NowPlayingScreen({super.key, required this.playerService});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _dismissAnimController;
  Animation<double>? _snapBackAnimation;
  double _dragOffset = 0.0;
  bool _pageTransitionDone = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _dismissAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addListener(() {
      if (_snapBackAnimation != null && mounted) {
        setState(() => _dragOffset = _snapBackAnimation!.value);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = ModalRoute.of(context);
      if (route != null && route.animation != null) {
        if (route.animation!.isCompleted) {
          setState(() => _pageTransitionDone = true);
          _syncGlowState();
        } else {
          route.animation!.addStatusListener((status) {
            if (status == AnimationStatus.completed && mounted) {
              setState(() => _pageTransitionDone = true);
              _syncGlowState();
            }
          });
        }
      } else {
        _pageTransitionDone = true;
        _syncGlowState();
      }
    });
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
    if (_dragOffset > 140 || velocity > 320) {
      Navigator.of(context).pop();
    } else if (_dragOffset > 0) {
      _startSnapBackAnimation();
    }
  }

  void _startSnapBackAnimation() {
    _snapBackAnimation = Tween<double>(begin: _dragOffset, end: 0.0).animate(
      CurvedAnimation(parent: _dismissAnimController, curve: Curves.easeOutCubic),
    );
    _dismissAnimController.forward(from: 0.0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncGlowState();
  }

  void _syncGlowState() {
    if (!_pageTransitionDone) return;
    if (widget.playerService.isPlaying && !_glowController.isAnimating) {
      _glowController.repeat(reverse: true);
    } else if (!widget.playerService.isPlaying && _glowController.isAnimating) {
      _glowController.stop();
      _glowController.animateTo(0.0, duration: const Duration(milliseconds: 300));
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _dismissAnimController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '00:00';
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.playerService,
      builder: (context, _) {
        _syncGlowState();
        final song = widget.playerService.currentSong;
        if (song == null) {
          return const Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: Text('> NO_TRACK_LOADED', style: TextStyle(fontFamily: 'monospace', color: AppTheme.textMuted)),
            ),
          );
        }

        final position = widget.playerService.player.position;
        final duration = widget.playerService.player.duration ?? Duration(seconds: song.duration);

        return Transform.translate(
          offset: Offset(0, _dragOffset),
          child: Scaffold(
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
              title: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: _onVerticalDragUpdate,
                onVerticalDragEnd: _onVerticalDragEnd,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF555555),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Text(
                      '// AUDIO_ENGINE_EXEC',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 13, letterSpacing: 1.2),
                    ),
                  ],
                ),
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
            body: GestureDetector(
              onVerticalDragUpdate: _onVerticalDragUpdate,
              onVerticalDragEnd: _onVerticalDragEnd,
              behavior: HitTestBehavior.translucent,
              child: SafeArea(
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
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: widget.playerService.isPlaying ? AppTheme.terminalGreen : AppTheme.textMuted,
                                boxShadow: widget.playerService.isPlaying
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.terminalGreen.withValues(alpha: 0.6),
                                          blurRadius: 6,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.playerService.isPlaying ? 'STATE: STREAMING' : 'STATE: PAUSED',
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

                  // Cover Art với Hero animation và Breathing Pulse theo nhịp điệu (Sine curve mượt mà)
                  Center(
                    child: AnimatedBuilder(
                      animation: _glowController,
                      builder: (context, child) {
                        final curvedVal = _pageTransitionDone ? Curves.easeInOutSine.transform(_glowController.value) : 0.0;
                        final scale = (_pageTransitionDone && widget.playerService.isPlaying) ? 1.0 + (curvedVal * 0.02) : 1.0;
                        final glowOpacity = (_pageTransitionDone && widget.playerService.isPlaying) ? (0.12 + curvedVal * 0.20) : 0.0;

                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: widget.playerService.isPlaying
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.terminalGreen.withValues(alpha: glowOpacity),
                                        blurRadius: 18 + curvedVal * 12,
                                        spreadRadius: 2 + curvedVal * 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: child,
                          ),
                        );
                      },
                      child: Hero(
                        tag: 'player_cover_art_${song.id}',
                        flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
                          return Material(
                            color: Colors.transparent,
                            child: toHeroContext.widget,
                          );
                        },
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.zero,
                            border: Border.all(
                              color: widget.playerService.isPlaying ? AppTheme.terminalGreen : AppTheme.borderHighlight,
                              width: 1.5,
                            ),
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
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Metadata Text với hiệu ứng chuyển bài hát mượt mà
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.08),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(song.id),
                      child: Column(
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
                    ),
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
                            // Header thông tin sóng & nút cấu hình
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      color: widget.playerService.isPlaying ? AppTheme.terminalGreen : AppTheme.textMuted,
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
                                  isPlaying: widget.playerService.isPlaying,
                                  position: position,
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
                            widget.playerService.seek(Duration(seconds: val.toInt()));
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
                        onTap: widget.playerService.previous,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        defaultColor: AppTheme.textSecondary,
                        hoverColor: AppTheme.terminalGreen,
                        icon: ReIcon(Reicon.outline.skipPrev, size: 18),
                        label: 'PREV',
                      ),
                      TerminalActionBtn(
                        onTap: widget.playerService.togglePlayPause,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                        defaultColor: widget.playerService.isPlaying ? AppTheme.terminalGreen : AppTheme.textPrimary,
                        hoverColor: AppTheme.terminalGreen,
                        defaultBorderColor: widget.playerService.isPlaying ? AppTheme.terminalGreen : AppTheme.textPrimary,
                        hoverBorderColor: AppTheme.terminalGreen,
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, anim) => RotationTransition(
                            turns: Tween<double>(begin: 0.8, end: 1.0).animate(anim),
                            child: ScaleTransition(scale: anim, child: child),
                          ),
                          child: ReIcon(
                            widget.playerService.isPlaying ? Reicon.outline.pause : Reicon.outline.play,
                            key: ValueKey(widget.playerService.isPlaying),
                            size: 20,
                          ),
                        ),
                        label: widget.playerService.isPlaying ? 'PAUSE' : 'PLAY',
                      ),
                      TerminalActionBtn(
                        onTap: widget.playerService.next,
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
        ),
      ),
    );
  },
);
  }
}
