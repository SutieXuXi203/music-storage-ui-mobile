import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:reicon_flutter/reicon_flutter.dart';
import '../core/theme/app_theme.dart';
import '../providers/settings_provider.dart';
import 're_icon.dart';

/// Widget hiển thị sóng nhạc chuyển động theo nhịp điệu bài hát (Beat-reactive Music Wave Visualizer)
/// Hỗ trợ 3 chế độ:
/// 1. Spectrum Bars (Mặc định - Cột phổ tần số đáy nhảy theo nhịp Kick/Bass/Mids/Hi-hats như ảnh)
/// 2. Mirrored Wave (Sóng âm đối xứng tâm nhảy theo nhịp)
/// 3. Oscilloscope (Máy hiện sóng quét Analog Sine CRT co giãn theo biên độ nhịp)
class MusicWaveWidget extends StatefulWidget {
  final bool isPlaying;
  final Duration? position;
  final double height;
  final WaveMusicType? typeOverride;
  final Color? color;

  const MusicWaveWidget({
    super.key,
    required this.isPlaying,
    this.position,
    this.height = 46,
    this.typeOverride,
    this.color,
  });

  @override
  State<MusicWaveWidget> createState() => _MusicWaveWidgetState();
}

class _MusicWaveWidgetState extends State<MusicWaveWidget> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  static const int _barCount = 52;

  // Mảng lưu trạng thái độ cao hiện tại và điểm đỉnh rơi tự do (Peak hold gravity)
  final List<double> _currentHeights = List.filled(_barCount, 0.06);
  final List<double> _peakHeights = List.filled(_barCount, 0.06);

  double _internalTimeSec = 0.0;
  Duration _lastElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    if (widget.isPlaying) {
      _ticker.start();
    }
  }

  @override
  void didUpdateWidget(covariant MusicWaveWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_ticker.isActive) {
      _ticker.start();
    } else if (!widget.isPlaying && _ticker.isActive) {
      // Khi dừng, tiếp tục chạy vài frame để dải sóng hạ mượt về mức nghỉ
    }
  }

  void _onTick(Duration elapsed) {
    final double dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;

    if (widget.isPlaying) {
      // Luôn cộng thời gian thực tế dt để sóng chuyển động mượt mà 60fps không bị đứng giật
      _internalTimeSec += dt.clamp(0.0, 0.05);
      // Nếu có seek bài hát (chênh lệch lớn hơn 1 giây) thì đồng bộ lại mốc
      if (widget.position != null) {
        final posSec = widget.position!.inMilliseconds / 1000.0;
        if ((posSec - _internalTimeSec).abs() > 1.2) {
          _internalTimeSec = posSec;
        }
      }
    }

    bool needsRepaint = false;

    // Tính toán độ cao từng cột theo nhịp trống Kick, Snare, Hi-hat và giai điệu
    for (int i = 0; i < _barCount; i++) {
      final double target = _calculateBeatTarget(i, _barCount, _internalTimeSec, widget.isPlaying);

      if (widget.isPlaying) {
        // Attack nhanh (khi có nhịp đập thì nảy lên dứt khoát), Release mượt mà
        if (target > _currentHeights[i]) {
          _currentHeights[i] += (target - _currentHeights[i]) * 0.45;
        } else {
          _currentHeights[i] += (target - _currentHeights[i]) * 0.18;
        }

        // Điểm đỉnh rơi trọng lực (Peak hold gravity drop)
        if (_currentHeights[i] > _peakHeights[i]) {
          _peakHeights[i] = _currentHeights[i];
        } else {
          _peakHeights[i] = math.max(_currentHeights[i], _peakHeights[i] - 0.012);
        }
        needsRepaint = true;
      } else {
        // Khi tạm dừng (Paused): sóng hạ dần về đường chân phẳng tĩnh lặng
        if (_currentHeights[i] > 0.06) {
          _currentHeights[i] = math.max(0.06, _currentHeights[i] - 0.03);
          _peakHeights[i] = math.max(0.06, _peakHeights[i] - 0.03);
          needsRepaint = true;
        }
      }
    }

    if (needsRepaint) {
      setState(() {});
    } else if (!widget.isPlaying && _ticker.isActive) {
      _ticker.stop();
    }
  }

  /// Thuật toán phân tích nhịp điệu âm nhạc theo thời gian thực (Procedural Beat-Frequency Synthesizer)
  double _calculateBeatTarget(int index, int totalBars, double timeSec, bool isPlaying) {
    if (!isPlaying) return 0.06;

    final double u = index / (totalBars - 1); // 0.0 (Bass cực trầm) -> 1.0 (Treble cao vút)

    // Nhịp độ chuẩn âm nhạc (Tempo ~128 BPM -> 1 phách = 0.46875 giây)
    const double beatInterval = 0.46875;
    final double beatProgress = (timeSec % beatInterval) / beatInterval; // 0.0 -> 1.0 trong 1 phách
    final int beatIndex = (timeSec ~/ beatInterval) % 4; // Phách 0, 1, 2, 3 trong ô nhịp 4/4

    // 1. Nhịp Kick Drum (Trống trầm đập ở phách 0 và phách 2)
    final double isKick = (beatIndex == 0 || beatIndex == 2) ? 1.0 : 0.35;
    final double kickEnvelope = math.exp(-6.5 * beatProgress) * isKick;

    // 2. Nhịp Snare / Clap (Tiếng gõ đập ở phách 1 và phách 3)
    final double isSnare = (beatIndex == 1 || beatIndex == 3) ? 1.0 : 0.25;
    final double snareEnvelope = math.exp(-5.5 * beatProgress) * isSnare;

    // 3. Nhịp Hi-hats (Tiếng đĩa xì rải đều liên tục ở nốt móc đôi 8th & 16th notes)
    final double subBeat = (timeSec % (beatInterval / 2)) / (beatInterval / 2);
    final double hihatEnvelope = math.exp(-10.0 * subBeat);

    // Chu kỳ thay đổi trường đoạn âm nhạc (Verse / Drop / Chorus qua từng đoạn)
    final double songDynamics = (math.sin(timeSec * 0.35) * 0.15 + 0.85);

    double height = 0.06;

    if (u < 0.30) {
      // === DẢI BASS / SUB-WOOFER (Cột 0 -> 15 bên trái) ===
      // Nhảy cực mạnh theo từng tiếng trống Kick trầm đập rộn ràng
      final double bassRollOff = 1.0 - (u / 0.30) * 0.35;
      final double subRumble = math.sin(timeSec * 14.0 + index * 0.9) * 0.12;
      height = (kickEnvelope * 0.78 + subRumble + 0.18) * bassRollOff * songDynamics;
    } else if (u < 0.72) {
      // === DẢI MIDS & VOCAL (Cột 16 -> 37 ở giữa) ===
      // Nhảy bốc theo tiếng Snare, giọng hát ca sĩ và giai điệu nhạc cụ
      final double midNorm = (u - 0.30) / (0.72 - 0.30);
      final double melodyWave1 = math.sin(timeSec * 7.5 + index * 0.5) * 0.22;
      final double melodyWave2 = math.cos(timeSec * 11.0 - index * 0.75) * 0.16;
      final double hump = math.sin(midNorm * math.pi); // Tạo sóng vồng tự nhiên ở trung âm
      height = (snareEnvelope * 0.58 + melodyWave1 + melodyWave2 + 0.24) * hump * songDynamics;
    } else {
      // === DẢI TREBLE & AIR (Cột 38 -> 51 bên phải) ===
      // Nhảy li ti sắc nét theo tiếng Hi-hat, chũm chọe và âm thanh điện tử
      final double highNorm = (u - 0.72) / 0.28;
      final double trebleShimmer = (math.sin(timeSec * 26.0 + index * 1.8) * 0.5 + 0.5) * 0.28;
      height = (hihatEnvelope * 0.52 + trebleShimmer + 0.12) * (1.0 - highNorm * 0.45) * songDynamics;
    }

    return height.clamp(0.06, 0.96);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: widget.typeOverride == null);
    final waveType = widget.typeOverride ?? settings.waveType;
    final waveColor = widget.color ?? (waveType == WaveMusicType.oscilloscope ? AppTheme.terminalGreen : Colors.white);

    return CustomPaint(
      size: Size(double.infinity, widget.height),
      painter: _BeatWavePainter(
        heights: _currentHeights,
        peakHeights: _peakHeights,
        timeSec: _internalTimeSec,
        isPlaying: widget.isPlaying,
        waveType: waveType,
        color: waveColor,
      ),
    );
  }
}

class _BeatWavePainter extends CustomPainter {
  final List<double> heights;
  final List<double> peakHeights;
  final double timeSec;
  final bool isPlaying;
  final WaveMusicType waveType;
  final Color color;

  _BeatWavePainter({
    required this.heights,
    required this.peakHeights,
    required this.timeSec,
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

  /// 1. Spectrum Bars (Dải cột phổ tần số đáy nhảy nhịp nhàng theo nhạc)
  void _paintSpectrumBars(Canvas canvas, Size size) {
    final int count = heights.length;
    final double totalWidth = size.width;
    final double barWidth = 2.4;
    final double spacing = (totalWidth - (count * barWidth)) / (count - 1);

    final barPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final peakPaint = Paint()
      ..color = isPlaying ? AppTheme.terminalGreen : AppTheme.textMuted
      ..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final double h = heights[i];
      final double barHeight = (size.height * h).clamp(2.5, size.height);

      final double x = i * (barWidth + spacing);
      final double y = size.height - barHeight;

      // Thân cột sóng chính
      canvas.drawRect(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        barPaint,
      );

      // Điểm đỉnh rơi tự do (Equalizer Peak Indicator)
      if (isPlaying) {
        final double peakH = peakHeights[i];
        final double peakY = size.height - (size.height * peakH).clamp(3.0, size.height);
        canvas.drawRect(
          Rect.fromLTWH(x, math.max(0.0, peakY - 1.5), barWidth, 1.5),
          peakPaint,
        );
      }
    }
  }

  /// 2. Mirrored Wave (Sóng âm đối xứng tâm nhảy theo nhịp)
  void _paintMirroredWave(Canvas canvas, Size size) {
    final int count = heights.length;
    final double totalWidth = size.width;
    final double barWidth = 2.4;
    final double spacing = (totalWidth - (count * barWidth)) / (count - 1);
    final double centerY = size.height / 2;

    final barPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final double h = heights[i];
      final double halfH = (size.height * 0.48 * h).clamp(1.5, size.height * 0.48);

      final double x = i * (barWidth + spacing);
      final double y = centerY - halfH;

      canvas.drawRect(
        Rect.fromLTWH(x, y, barWidth, halfH * 2),
        barPaint,
      );
    }
  }

  /// 3. Oscilloscope (Máy hiện sóng quét Analog Sine CRT co giãn theo nhịp)
  void _paintOscilloscope(Canvas canvas, Size size) {
    final double centerY = size.height / 2;

    // Đường trung tâm zero-line
    final gridPaint = Paint()
      ..color = const Color(0xFF222222)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), gridPaint);

    final path = Path();
    const int points = 180;

    // Lấy năng lượng tổng hợp từ dải Bass và Mids hiện tại
    double energy = 0.2;
    if (isPlaying && heights.isNotEmpty) {
      energy = (heights[2] + heights[8] + heights[24]) / 3.0;
    }

    final double phase = timeSec * 16.0;

    for (int i = 0; i <= points; i++) {
      final double u = i / points;
      final double x = u * size.width;

      double y = centerY;
      if (isPlaying) {
        final double harm1 = math.sin(u * math.pi * 6.0 + phase) * (size.height * 0.38 * energy);
        final double harm2 = math.sin(u * math.pi * 14.0 - phase * 1.5) * (size.height * 0.15 * energy);
        final double envelope = math.sin(u * math.pi);
        y = centerY + (harm1 + harm2) * envelope;
      } else {
        y = centerY + math.sin(u * math.pi * 4.0) * 1.5;
      }

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Nét quét phát quang (Glow)
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawPath(path, glowPaint);

    // Nét quét chính
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _BeatWavePainter oldDelegate) {
    return true;
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

                        // Khung Preview trực tiếp của kiểu sóng nhảy nhịp nhàng
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
