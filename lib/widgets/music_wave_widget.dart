import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:reicon_flutter/reicon_flutter.dart';
import '../core/theme/app_theme.dart';
import '../providers/settings_provider.dart';
import 're_icon.dart';

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

class _MusicWaveWidgetState extends State<MusicWaveWidget>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  static const int _barCount = 52;

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
    } else if (!widget.isPlaying && _ticker.isActive) {}
  }

  void _onTick(Duration elapsed) {
    final double dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;

    if (widget.isPlaying) {
      _internalTimeSec += dt.clamp(0.0, 0.05);
      if (widget.position != null) {
        final posSec = widget.position!.inMilliseconds / 1000.0;
        if ((posSec - _internalTimeSec).abs() > 1.2) {
          _internalTimeSec = posSec;
        }
      }
    }

    bool needsRepaint = false;

    for (int i = 0; i < _barCount; i++) {
      final double target = _calculateBeatTarget(
          i, _barCount, _internalTimeSec, widget.isPlaying);

      if (widget.isPlaying) {
        if (target > _currentHeights[i]) {
          _currentHeights[i] += (target - _currentHeights[i]) * 0.45;
        } else {
          _currentHeights[i] += (target - _currentHeights[i]) * 0.18;
        }

        if (_currentHeights[i] > _peakHeights[i]) {
          _peakHeights[i] = _currentHeights[i];
        } else {
          _peakHeights[i] =
              math.max(_currentHeights[i], _peakHeights[i] - 0.012);
        }
        needsRepaint = true;
      } else {
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

  double _calculateBeatTarget(
      int index, int totalBars, double timeSec, bool isPlaying) {
    if (!isPlaying) return 0.06;

    final double u = index / (totalBars - 1);

    const double beatInterval = 0.46875;
    final double beatProgress = (timeSec % beatInterval) / beatInterval;
    final int beatIndex = (timeSec ~/ beatInterval) % 4;

    final double isKick = (beatIndex == 0 || beatIndex == 2) ? 1.0 : 0.35;
    final double kickEnvelope = math.exp(-6.5 * beatProgress) * isKick;

    final double isSnare = (beatIndex == 1 || beatIndex == 3) ? 1.0 : 0.25;
    final double snareEnvelope = math.exp(-5.5 * beatProgress) * isSnare;

    final double subBeat = (timeSec % (beatInterval / 2)) / (beatInterval / 2);
    final double hihatEnvelope = math.exp(-10.0 * subBeat);

    final double songDynamics = (math.sin(timeSec * 0.35) * 0.15 + 0.85);

    double height = 0.06;

    if (u < 0.30) {
      final double bassRollOff = 1.0 - (u / 0.30) * 0.35;
      final double subRumble = math.sin(timeSec * 14.0 + index * 0.9) * 0.12;
      height =
          (kickEnvelope * 0.78 + subRumble + 0.18) * bassRollOff * songDynamics;
    } else if (u < 0.72) {
      final double midNorm = (u - 0.30) / (0.72 - 0.30);
      final double melodyWave1 = math.sin(timeSec * 7.5 + index * 0.5) * 0.22;
      final double melodyWave2 = math.cos(timeSec * 11.0 - index * 0.75) * 0.16;
      final double hump = math.sin(midNorm * math.pi);
      height = (snareEnvelope * 0.58 + melodyWave1 + melodyWave2 + 0.24) *
          hump *
          songDynamics;
    } else {
      final double highNorm = (u - 0.72) / 0.28;
      final double trebleShimmer =
          (math.sin(timeSec * 26.0 + index * 1.8) * 0.5 + 0.5) * 0.28;
      height = (hihatEnvelope * 0.52 + trebleShimmer + 0.12) *
          (1.0 - highNorm * 0.45) *
          songDynamics;
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
    final settings = Provider.of<SettingsProvider>(context,
        listen: widget.typeOverride == null);
    final waveType = widget.typeOverride ?? settings.waveType;
    final waveColor = widget.color ??
        (waveType == WaveMusicType.oscilloscope
            ? AppTheme.terminalGreen
            : Colors.white);

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

      canvas.drawRect(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        barPaint,
      );

      if (isPlaying) {
        final double peakH = peakHeights[i];
        final double peakY =
            size.height - (size.height * peakH).clamp(3.0, size.height);
        canvas.drawRect(
          Rect.fromLTWH(x, math.max(0.0, peakY - 1.5), barWidth, 1.5),
          peakPaint,
        );
      }
    }
  }

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
      final double halfH =
          (size.height * 0.48 * h).clamp(1.5, size.height * 0.48);

      final double x = i * (barWidth + spacing);
      final double y = centerY - halfH;

      canvas.drawRect(
        Rect.fromLTWH(x, y, barWidth, halfH * 2),
        barPaint,
      );
    }
  }

  void _paintOscilloscope(Canvas canvas, Size size) {
    final double centerY = size.height / 2;

    final gridPaint = Paint()
      ..color = const Color(0xFF222222)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), gridPaint);

    final path = Path();
    const int points = 180;

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
        final double harm1 =
            math.sin(u * math.pi * 6.0 + phase) * (size.height * 0.38 * energy);
        final double harm2 = math.sin(u * math.pi * 14.0 - phase * 1.5) *
            (size.height * 0.15 * energy);
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

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawPath(path, glowPaint);

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
                      color: isSelected
                          ? AppTheme.surfaceLight
                          : AppTheme.background,
                      borderRadius: BorderRadius.zero,
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.terminalGreen
                            : AppTheme.border,
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
                                    color: isSelected
                                        ? AppTheme.terminalGreen
                                        : AppTheme.textMuted,
                                  ),
                                ),
                                Text(
                                  type.label,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: isSelected
                                        ? AppTheme.terminalGreen
                                        : AppTheme.textPrimary,
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
                                color: isSelected
                                    ? AppTheme.terminalGreen
                                    : AppTheme.textMuted,
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
                        Container(
                          height: 32,
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.zero,
                            border: Border.fromBorderSide(BorderSide(
                                color: Color(0xFF222222), width: 1.0)),
                          ),
                          child: MusicWaveWidget(
                            isPlaying: true,
                            height: 24,
                            typeOverride: type,
                            color: isSelected
                                ? AppTheme.terminalGreen
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TerminalActionBtn(
                  onTap: () => Navigator.of(dialogContext).pop(),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  defaultColor: AppTheme.terminalGreen,
                  hoverColor: Colors.white,
                  defaultBorderColor: AppTheme.terminalGreen,
                  hoverBorderColor: Colors.white,
                  icon: ReIcon(Reicon.outline.check,
                      size: 16, color: AppTheme.terminalGreen),
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
