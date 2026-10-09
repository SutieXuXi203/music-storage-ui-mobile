import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/audio_player_service.dart';

class TechPlaybackControls extends StatelessWidget {
  final AudioPlayerService playerService;

  const TechPlaybackControls({
    super.key,
    required this.playerService,
  });

  @override
  Widget build(BuildContext context) {
    final isPlaying = playerService.isPlaying;
    final isShuffle = playerService.isShuffle;
    final isLoop = playerService.isLoop;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        TechShuffleButton(
          isActive: isShuffle,
          onTap: () => playerService.toggleShuffle(),
        ),
        TechSeekButton(
          isNext: false,
          onTap: () => playerService.previous(),
        ),
        TechPlayCoreButton(
          isPlaying: isPlaying,
          onTap: () {
            if (isPlaying) {
              playerService.pause();
            } else {
              playerService.resume();
            }
          },
        ),
        TechSeekButton(
          isNext: true,
          onTap: () => playerService.next(),
        ),
        TechRepeatButton(
          isActive: isLoop,
          onTap: () => playerService.toggleLoop(),
        ),
      ],
    );
  }
}

class TechPlayCoreButton extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onTap;
  final double size;

  const TechPlayCoreButton({
    super.key,
    required this.isPlaying,
    required this.onTap,
    this.size = 60.0,
  });

  @override
  State<TechPlayCoreButton> createState() => _TechPlayCoreButtonState();
}

class _TechPlayCoreButtonState extends State<TechPlayCoreButton>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _morphController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      value: widget.isPlaying ? 1.0 : 0.0,
    );

    if (widget.isPlaying) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant TechPlayCoreButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _rotationController.repeat();
        _morphController.forward();
      } else {
        _rotationController.stop();
        _morphController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _morphController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.getText(context);
    final totalSize = widget.size;
    final innerCircleSize = totalSize - 10.0;
    final iconSize = totalSize * (27.0 / 60.0);

    return BouncingWidget(
      onTap: widget.onTap,
      scaleFactor: 0.88,
      child: AnimatedBuilder(
        animation: _rotationController,
        builder: (context, _) {
          return SizedBox(
            width: totalSize,
            height: totalSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size(totalSize, totalSize),
                  painter: _TechOrbitPainter(
                    angle: _rotationController.value * 2 * math.pi,
                    isPlaying: widget.isPlaying,
                    color: textColor,
                  ),
                ),
                Container(
                  width: innerCircleSize,
                  height: innerCircleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.isDark(context)
                        ? const Color(0xFF141414)
                        : const Color(0xFFFFFFFF),
                    border: Border.all(
                      color: textColor,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: AnimatedIcon(
                      icon: AnimatedIcons.play_pause,
                      progress: _morphController,
                      size: iconSize,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TechOrbitPainter extends CustomPainter {
  final double angle;
  final bool isPlaying;
  final Color color;

  _TechOrbitPainter({
    required this.angle,
    required this.isPlaying,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1.5;

    final arcPaint = Paint()
      ..color = color.withValues(alpha: isPlaying ? 0.55 : 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    const arcCount = 4;
    const sweep = (2 * math.pi / arcCount) * 0.55;

    for (int i = 0; i < arcCount; i++) {
      final startAngle = angle + (i * 2 * math.pi / arcCount);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TechOrbitPainter oldDelegate) {
    return oldDelegate.angle != angle ||
        oldDelegate.isPlaying != isPlaying ||
        oldDelegate.color != color;
  }
}

class TechSeekButton extends StatefulWidget {
  final bool isNext;
  final VoidCallback onTap;

  const TechSeekButton({
    super.key,
    required this.isNext,
    required this.onTap,
  });

  @override
  State<TechSeekButton> createState() => _TechSeekButtonState();
}

class _TechSeekButtonState extends State<TechSeekButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _nudgeController;

  @override
  void initState() {
    super.initState();
    _nudgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _nudgeController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _nudgeController.forward(from: 0.0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.getText(context);

    return BouncingWidget(
      onTap: _handleTap,
      scaleFactor: 0.85,
      child: AnimatedBuilder(
        animation: _nudgeController,
        builder: (context, _) {
          final t = _nudgeController.value;
          final nudge =
              math.sin(t * math.pi) * 3.0 * (widget.isNext ? 1.0 : -1.0);

          return Transform.translate(
            offset: Offset(nudge, 0),
            child: SizedBox(
              width: 44,
              height: 44,
              child: CustomPaint(
                painter: _TechSeekPainter(
                  isNext: widget.isNext,
                  pulse: t,
                  color: textColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TechSeekPainter extends CustomPainter {
  final bool isNext;
  final double pulse;
  final Color color;

  _TechSeekPainter({
    required this.isNext,
    required this.pulse,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final barPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.square;

    const chevronWidth = 7.0;
    const chevronHeight = 13.0;

    canvas.save();
    canvas.translate(cx, cy);
    if (!isNext) {
      canvas.scale(-1, 1);
    }

    final p1 = Path()
      ..moveTo(-9.5, -chevronHeight / 2)
      ..lineTo(-9.5 + chevronWidth, 0)
      ..lineTo(-9.5, chevronHeight / 2)
      ..close();

    final p2 = Path()
      ..moveTo(-3.0, -chevronHeight / 2)
      ..lineTo(-3.0 + chevronWidth, 0)
      ..lineTo(-3.0, chevronHeight / 2)
      ..close();

    final alpha1 = (0.75 + 0.25 * (1.0 - pulse)).clamp(0.0, 1.0);
    final alpha2 = (0.90 + 0.10 * pulse).clamp(0.0, 1.0);

    fillPaint.color = color.withValues(alpha: alpha1);
    canvas.drawPath(p1, fillPaint);

    fillPaint.color = color.withValues(alpha: alpha2);
    canvas.drawPath(p2, fillPaint);

    canvas.drawLine(
      const Offset(6.5, -chevronHeight / 2),
      const Offset(6.5, chevronHeight / 2),
      barPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TechSeekPainter oldDelegate) {
    return oldDelegate.pulse != pulse ||
        oldDelegate.color != color ||
        oldDelegate.isNext != isNext;
  }
}

class TechShuffleButton extends StatefulWidget {
  final bool isActive;
  final VoidCallback onTap;

  const TechShuffleButton({
    super.key,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<TechShuffleButton> createState() => _TechShuffleButtonState();
}

class _TechShuffleButtonState extends State<TechShuffleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _rotationController.forward(from: 0.0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.getText(context);
    final activeColor =
        widget.isActive ? textColor : textColor.withValues(alpha: 0.38);

    return BouncingWidget(
      onTap: _handleTap,
      scaleFactor: 0.85,
      child: SizedBox(
        width: 42,
        height: 44,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(28, 28),
                  painter: _TechBracketsPainter(
                    isActive: widget.isActive,
                    color: textColor,
                  ),
                ),
                RotationTransition(
                  turns: Tween<double>(begin: 0.0, end: 0.5).animate(
                    CurvedAnimation(
                      parent: _rotationController,
                      curve: Curves.easeOutBack,
                    ),
                  ),
                  child: CustomPaint(
                    size: const Size(20, 16),
                    painter: _TechShufflePainter(
                      color: activeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(0.5),
                color: widget.isActive ? textColor : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TechShufflePainter extends CustomPainter {
  final Color color;

  _TechShufflePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.square;

    final p1 = Path()
      ..moveTo(cx - 7, cy - 4.5)
      ..lineTo(cx - 2.5, cy - 4.5)
      ..lineTo(cx + 2.5, cy + 4.5)
      ..lineTo(cx + 7, cy + 4.5);
    canvas.drawPath(p1, paint);

    final a1 = Path()
      ..moveTo(cx + 4.5, cy + 2.0)
      ..lineTo(cx + 7.5, cy + 4.5)
      ..lineTo(cx + 4.5, cy + 7.0);
    canvas.drawPath(a1, paint);

    final p2a = Path()
      ..moveTo(cx - 7, cy + 4.5)
      ..lineTo(cx - 2.5, cy + 4.5)
      ..lineTo(cx - 0.8, cy + 1.8);
    canvas.drawPath(p2a, paint);

    final p2b = Path()
      ..moveTo(cx + 0.8, cy - 1.8)
      ..lineTo(cx + 2.5, cy - 4.5)
      ..lineTo(cx + 7, cy - 4.5);
    canvas.drawPath(p2b, paint);

    final a2 = Path()
      ..moveTo(cx + 4.5, cy - 7.0)
      ..lineTo(cx + 7.5, cy - 4.5)
      ..lineTo(cx + 4.5, cy - 2.0);
    canvas.drawPath(a2, paint);
  }

  @override
  bool shouldRepaint(covariant _TechShufflePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class TechRepeatButton extends StatefulWidget {
  final bool isActive;
  final VoidCallback onTap;

  const TechRepeatButton({
    super.key,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<TechRepeatButton> createState() => _TechRepeatButtonState();
}

class _TechRepeatButtonState extends State<TechRepeatButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _rotationController.forward(from: 0.0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.getText(context);
    final activeColor =
        widget.isActive ? textColor : textColor.withValues(alpha: 0.38);

    return BouncingWidget(
      onTap: _handleTap,
      scaleFactor: 0.85,
      child: SizedBox(
        width: 42,
        height: 44,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(28, 28),
                  painter: _TechBracketsPainter(
                    isActive: widget.isActive,
                    color: textColor,
                  ),
                ),
                RotationTransition(
                  turns: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _rotationController,
                      curve: Curves.easeOutBack,
                    ),
                  ),
                  child: CustomPaint(
                    size: const Size(20, 16),
                    painter: _TechRepeatPainter(
                      color: activeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(0.5),
                color: widget.isActive ? textColor : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TechRepeatPainter extends CustomPainter {
  final Color color;

  _TechRepeatPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const r = 6.0;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.square;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      math.pi * 0.15,
      math.pi * 0.72,
      false,
      paint,
    );

    final a1 = Path()
      ..moveTo(cx - r - 2.2, cy + 1.2)
      ..lineTo(cx - r + 0.4, cy - 1.2)
      ..lineTo(cx - r + 3.0, cy + 1.2);
    canvas.drawPath(a1, paint);

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      math.pi * 1.15,
      math.pi * 0.72,
      false,
      paint,
    );

    final a2 = Path()
      ..moveTo(cx + r - 3.0, cy - 1.2)
      ..lineTo(cx + r - 0.4, cy + 1.2)
      ..lineTo(cx + r + 2.2, cy - 1.2);
    canvas.drawPath(a2, paint);
  }

  @override
  bool shouldRepaint(covariant _TechRepeatPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _TechBracketsPainter extends CustomPainter {
  final bool isActive;
  final Color color;

  _TechBracketsPainter({required this.isActive, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final alpha = isActive ? 0.65 : 0.16;
    final paint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    const arm = 3.5;
    final w = size.width;
    final h = size.height;

    canvas.drawLine(const Offset(0, 0), const Offset(arm, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, arm), paint);

    canvas.drawLine(Offset(w, 0), Offset(w - arm, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, arm), paint);

    canvas.drawLine(Offset(0, h), Offset(arm, h), paint);
    canvas.drawLine(Offset(0, h), Offset(0, h - arm), paint);

    canvas.drawLine(Offset(w, h), Offset(w - arm, h), paint);
    canvas.drawLine(Offset(w, h), Offset(w, h - arm), paint);
  }

  @override
  bool shouldRepaint(covariant _TechBracketsPainter oldDelegate) {
    return oldDelegate.isActive != isActive || oldDelegate.color != color;
  }
}
