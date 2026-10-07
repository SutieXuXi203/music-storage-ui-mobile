import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Dải sóng equalizer mini (3 hoặc 4 cột) render siêu mượt qua GPU CustomPainter.
/// Nhảy nhót theo sóng sin liên tục không giật lag.
class MiniEqualizerWidget extends StatefulWidget {
  final bool isPlaying;
  final Color color;
  final double height;
  final double width;
  final int barCount;

  const MiniEqualizerWidget({
    super.key,
    required this.isPlaying,
    this.color = AppTheme.terminalGreen,
    this.height = 14,
    this.width = 16,
    this.barCount = 4,
  });

  @override
  State<MiniEqualizerWidget> createState() => _MiniEqualizerWidgetState();
}

class _MiniEqualizerWidgetState extends State<MiniEqualizerWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant MiniEqualizerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _EqualizerPainter(
            progress: _controller.value,
            isPlaying: widget.isPlaying,
            color: widget.color,
            barCount: widget.barCount,
          ),
        );
      },
    );
  }
}

class _EqualizerPainter extends CustomPainter {
  final double progress;
  final bool isPlaying;
  final Color color;
  final int barCount;

  _EqualizerPainter({
    required this.progress,
    required this.isPlaying,
    required this.color,
    required this.barCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final barWidth = (size.width / barCount) - 1.2;
    final gap = barCount > 1 ? (size.width - (barWidth * barCount)) / (barCount - 1) : 0.0;

    for (int i = 0; i < barCount; i++) {
      double factor;
      if (isPlaying) {
        final phase = i * (math.pi / 2.2);
        final freq = 1.0 + (i % 2) * 0.4;
        final wave = (math.sin((progress * 2 * math.pi * freq) + phase) + 1.0) / 2.0;
        factor = 0.22 + wave * 0.78;
      } else {
        factor = 0.22;
      }

      final barH = (size.height * factor).clamp(2.0, size.height);
      final left = i * (barWidth + gap);
      final top = size.height - barH;

      canvas.drawRect(
        Rect.fromLTWH(left, top, barWidth, barH),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EqualizerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isPlaying != isPlaying ||
        oldDelegate.color != color;
  }
}
