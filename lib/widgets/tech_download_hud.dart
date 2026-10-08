import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/download_task_model.dart';
import '../providers/download_provider.dart';
import '../providers/song_provider.dart';
import '../services/audio_player_service.dart';

class TechDownloadHud extends StatefulWidget {
  const TechDownloadHud({super.key});

  @override
  State<TechDownloadHud> createState() => _TechDownloadHudState();
}

class _TechDownloadHudState extends State<TechDownloadHud>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<DownloadProvider, SongProvider>(
      builder: (context, downloadProv, songProv, _) {
        final task = downloadProv.primaryTask;
        if (task == null) return const SizedBox.shrink();

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final hudBg = isDark ? const Color(0xFF090A0D) : const Color(0xFFF3F4F6);
        final hudBorder = isDark ? const Color(0xFF232733) : const Color(0xFFD1D5DB);
        final textPrimary = isDark ? const Color(0xFFE5E7EB) : const Color(0xFF111827);
        final textMuted = isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);

        Color accentColor;
        String statusLabel;
        if (task.stage == DownloadStage.completed) {
          accentColor = const Color(0xFF10B981); // Emerald Green
          statusLabel = 'SUCCESS';
        } else if (task.stage == DownloadStage.failed) {
          accentColor = const Color(0xFFEF4444); // Crimson Red
          statusLabel = 'ERROR';
        } else {
          accentColor = const Color(0xFF38BDF8); // Cyber Cyan
          statusLabel = 'ACTIVE';
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: hudBg,
            borderRadius: BorderRadius.zero, // Góc vuông chuẩn Terminal
            border: Border.all(color: hudBorder, width: 1.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Bar: [SYS://INGEST_TASK] ... [● STATUS T+00:12s]
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            '[SYS://INGEST_DAEMON]',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: accentColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '#${task.id}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9.5,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      if (task.isActive)
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, _) {
                            return Opacity(
                              opacity: 0.3 + (_pulseController.value * 0.7),
                              child: Text(
                                '● ',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  color: accentColor,
                                ),
                              ),
                            );
                          },
                        ),
                      Text(
                        '[$statusLabel ${task.formattedTimer}]',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // 2. Target info: [TARGET: <url/title>]
              Text(
                'TARGET: ${task.title != null ? "${task.title} - ${task.artist ?? 'YouTube'}" : task.url}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 5),

              // 3. Tech Hairline Progress Bar + Percentage
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E222D) : const Color(0xFFE5E7EB),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: task.progress.clamp(0.0, 1.0),
                        child: Container(color: accentColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    task.progressPercentage.padLeft(4),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),

              // 4. Command Execution Line: > STAGE: SYNCING_GOOGLE_DRIVE...
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '> [${task.stageTag}] ${task.stageDescription}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9.5,
                        color: textMuted,
                      ),
                    ),
                  ),

                  // 5. High-Tech Action Controls
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (task.stage == DownloadStage.completed) ...[
                        InkWell(
                          onTap: () {
                            if (task.title != null) {
                              final matched = songProv.songs.firstWhere(
                                (s) => s.title == task.title,
                                orElse: () => songProv.songs.isNotEmpty ? songProv.songs.first : throw '',
                              );
                              audioPlayerService.playSong(matched);
                            }
                            downloadProv.dismissTask(task.id);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Text(
                              '[▶ PLAY]',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      if (task.stage == DownloadStage.failed) ...[
                        InkWell(
                          onTap: () => downloadProv.retryTask(task.id, songProvider: songProv),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Text(
                              '[↻ RETRY]',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      InkWell(
                        onTap: () => downloadProv.dismissTask(task.id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Text(
                            '[DISMISS]',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: textMuted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
