import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reicon_flutter/reicon_flutter.dart';
import '../core/theme/app_theme.dart';
import '../providers/settings_provider.dart';
import 're_icon.dart';

/// Widget hiển thị sóng nhạc chuyển động theo âm thanh (Music Wave Visualizer)
/// Hỗ trợ 3 chế độ:
/// 1. Spectrum Bars (Mặc định - Cột phổ tần số mọc từ đáy như ảnh)
/// 2. Mirrored Wave (Sóng âm đối xứng tâm SoundCloud)
/// 3. Oscilloscope (Máy hiện sóng quét Analog Sine CRT)
class MusicWaveWidget extends StatefulWidget {
  final bool isPlaying;
  final double height;
  final WaveMusicType? typeOverride; // Dùng khi muốn ép kiểu hiển thị (ví dụ preview trong settings)
  final Color? color;

  const MusicWaveWidget({
    super.key,
    required this.isPlaying,
    this.height = 42,
    this.typeOverride,
    this.color,
  });

  @override
  State<MusicWaveWidget> createState() => _MusicWaveWidgetState();
}

class _MusicWaveWidgetState extends State<MusicWaveWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant MusicWaveWidget oldWidget) {
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
    final settings = Provider.of<SettingsProvider>(context, listen: widget.typeOverride == null);
    final waveType = widget.typeOverride ?? settings.waveType;
    final waveColor = widget.color ?? (waveType == WaveMusicType.oscilloscope ? AppTheme.terminalGreen : Colors.white);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(double.infinity, widget.height),
          painter: _MusicWavePainter(
            animationValue: _controller.value,
            isPlaying: widget.isPlaying,
            waveType: waveType,
            color: waveColor,
          ),
        );
      },
    );
  }
}

class _MusicWavePainter extends CustomPainter {
  final double animationValue;
  final bool isPlaying;
  final WaveMusicType waveType;
  final Color color;

  _MusicWavePainter({
    required this.animationValue,
    required this.isPlaying,
    required this.waveType,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    switch (waveType) {
      case WaveMusicType.spectrumBars:
        _paintSpectrumBars(canvas, size);
        break;
      case WaveMusicType.mirroredWave:
        _paintMirroredWave(canvas, size);
        break;
      case WaveMusicType.oscilloscope:
        _paintOscilloscope(canvas, size);
        break;
    }
  }

  /// 1. Spectrum Bars (Mặc định - Cột phổ tần số đáy như ảnh người dùng gửi)
  void _paintSpectrumBars(Canvas canvas, Size size) {
    const int barCount = 52;
    final double totalWidth = size.width;
    final double barWidth = 2.4;
    final double spacing = (totalWidth - (barCount * barWidth)) / (barCount - 1);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final double phase = animationValue * 2 * math.pi;

    for (int i = 0; i < barCount; i++) {
      final double u = i / (barCount - 1); // 0.0 -> 1.0

      // Đường bao tần số mô phỏng chính xác hình ảnh người dùng gửi:
      // - Phần đầu thấp (u < 0.2): 0.12 -> 0.2
      // - Cụm đỉnh nhỏ giữa bên trái (u ~ 0.35): 0.45
      // - Đỉnh chính cực cao gần giữa phải (u ~ 0.65): 0.90
      // - Đỉnh phụ bên cạnh (u ~ 0.70): 0.65
      // - Đuôi dài đều thấp bên phải (u > 0.75): 0.10
      double envelope = 0.10;

      // Cụm đỉnh thứ nhất (Bass-mid, u ~ 0.35)
      final double dist1 = (u - 0.35).abs();
      if (dist1 < 0.12) {
        envelope += 0.38 * math.cos(dist1 / 0.12 * (math.pi / 2));
      }

      // Đỉnh chính cực cao (Mid-high peak, u ~ 0.63)
      final double dist2 = (u - 0.63).abs();
      if (dist2 < 0.08) {
        envelope += 0.75 * math.cos(dist2 / 0.08 * (math.pi / 2));
      }

      // Đỉnh phụ cạnh đỉnh chính (u ~ 0.71)
      final double dist3 = (u - 0.71).abs();
      if (dist3 < 0.05) {
        envelope += 0.45 * math.cos(dist3 / 0.05 * (math.pi / 2));
      }

      // Khi phát nhạc: dao động nhấp nhô theo nhịp sóng và tần số
      double dynamicFactor = 1.0;
      if (isPlaying) {
        final double wave1 = math.sin(phase * 2.5 + i * 0.45);
        final double wave2 = math.cos(phase * 4.0 + i * 0.85);
        final double beat = math.sin(phase * 2.0).abs();
        dynamicFactor = 0.65 + (wave1 * 0.22) + (wave2 * 0.13) + (beat * 0.18);
      }

      double barHeightFraction = (envelope * dynamicFactor).clamp(0.08, 0.98);
      final double barHeight = size.height * barHeightFraction;

      final double x = i * (barWidth + spacing);
      final double y = size.height - barHeight;

      canvas.drawRect(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        paint,
      );
    }
  }

  /// 2. Mirrored Wave (Sóng âm đối xứng tâm SoundCloud)
  void _paintMirroredWave(Canvas canvas, Size size) {
    const int barCount = 48;
    final double totalWidth = size.width;
    final double barWidth = 2.4;
    final double spacing = (totalWidth - (barCount * barWidth)) / (barCount - 1);
    final double centerY = size.height / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final double phase = animationValue * 2 * math.pi;

    for (int i = 0; i < barCount; i++) {
      final double u = i / (barCount - 1);

      // Đường bao hình chuông gaussian với nhiều gợn sóng âm
      final double centerDist = (u - 0.5).abs();
      double envelope = math.exp(-centerDist * centerDist * 8.0);
      envelope += 0.15 * math.sin(u * math.pi * 6);
      envelope = envelope.clamp(0.12, 0.95);

      double dynamicFactor = 1.0;
      if (isPlaying) {
        final double wave = math.sin(phase * 3.0 + i * 0.5);
        final double pulse = math.cos(phase * 1.5).abs();
        dynamicFactor = 0.7 + (wave * 0.2) + (pulse * 0.25);
      }

      final double halfHeight = (size.height * 0.46 * envelope * dynamicFactor).clamp(2.0, size.height * 0.48);

      final double x = i * (barWidth + spacing);
      final double y = centerY - halfHeight;

      canvas.drawRect(
        Rect.fromLTWH(x, y, barWidth, halfHeight * 2),
        paint,
      );
    }
  }

  /// 3. Oscilloscope (Máy hiện sóng quét Analog Sine CRT)
  void _paintOscilloscope(Canvas canvas, Size size) {
    final double centerY = size.height / 2;
    final double phase = animationValue * 2 * math.pi;

    // Vẽ đường zero-line trung tâm mờ mờ chuẩn oscilloscope
    final gridPaint = Paint()
      ..color = const Color(0xFF222222)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), gridPaint);

    final path = Path();
    final double totalPoints = size.width.clamp(50, 400);

    for (int i = 0; i <= totalPoints; i++) {
      final double x = (i / totalPoints) * size.width;
      final double u = i / totalPoints;

      double y = centerY;
      if (isPlaying) {
        final double harm1 = math.sin(u * math.pi * 5.0 + phase * 4.0) * (size.height * 0.32);
        final double harm2 = math.sin(u * math.pi * 11.0 - phase * 6.0) * (size.height * 0.12);
        final double harm3 = math.cos(u * math.pi * 2.0 + phase * 2.0) * (size.height * 0.08);
        y = centerY + harm1 + harm2 + harm3;
      } else {
        // Trạng thái dừng: sóng sine phẳng lặng
        y = centerY + math.sin(u * math.pi * 4.0) * (size.height * 0.1);
      }

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Nét quét phát sáng (Glow)
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawPath(path, glowPaint);

    // Nét chính
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _MusicWavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isPlaying != isPlaying ||
        oldDelegate.waveType != waveType ||
        oldDelegate.color != color;
  }
}

/// Dialog / Modal Cài đặt chọn kiểu sóng nhạc (Wave Visualizer Setting)
void showWaveSettingsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      final settings = Provider.of<SettingsProvider>(dialogContext);

      return Dialog(
        backgroundColor: AppTheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppTheme.borderHighlight, width: 1.0),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Dialog Terminal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '// WAVE_MUSIC_SETTINGS',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  TerminalActionBtn(
                    onTap: () => Navigator.of(dialogContext).pop(),
                    hasBorder: false,
                    padding: const EdgeInsets.all(4),
                    defaultColor: AppTheme.textMuted,
                    hoverColor: AppTheme.error,
                    icon: ReIcon(Reicon.outline.xmark, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                '> Select audio visualization pattern for realtime playback engine:',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 18),

              // Danh sách 3 kiểu sóng
              ...WaveMusicType.values.map((type) {
                final isSelected = settings.waveType == type;

                return GestureDetector(
                  onTap: () {
                    settings.setWaveType(type);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.surfaceLight : AppTheme.background,
                      borderRadius: BorderRadius.zero,
                      border: Border.all(
                        color: isSelected ? AppTheme.terminalGreen : AppTheme.border,
                        width: isSelected ? 1.2 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  isSelected ? '[X] ' : '[ ] ',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isSelected ? AppTheme.terminalGreen : AppTheme.textMuted,
                                  ),
                                ),
                                Text(
                                  type.label,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: isSelected ? AppTheme.terminalGreen : AppTheme.textPrimary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              type.tag,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10,
                                color: isSelected ? AppTheme.terminalGreen : AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          type.displayName,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Khung Preview trực tiếp của kiểu sóng
                        Container(
                          height: 32,
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.zero,
                            border: Border.fromBorderSide(BorderSide(color: Color(0xFF222222), width: 1.0)),
                          ),
                          child: MusicWaveWidget(
                            isPlaying: true,
                            height: 24,
                            typeOverride: type,
                            color: isSelected ? AppTheme.terminalGreen : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 8),

              // Nút Đóng & Áp dụng
              SizedBox(
                width: double.infinity,
                child: TerminalActionBtn(
                  onTap: () => Navigator.of(dialogContext).pop(),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  defaultColor: AppTheme.terminalGreen,
                  hoverColor: Colors.white,
                  defaultBorderColor: AppTheme.terminalGreen,
                  hoverBorderColor: Colors.white,
                  icon: ReIcon(Reicon.outline.check, size: 16, color: AppTheme.terminalGreen),
                  label: 'SAVE_AND_APPLY',
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
