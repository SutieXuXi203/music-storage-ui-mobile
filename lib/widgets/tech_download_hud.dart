import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../models/download_task_model.dart';
import '../models/song_model.dart';
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
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _safePlaySong(
    BuildContext context,
    DownloadTask task,
    SongProvider songProv,
  ) {
    Song? matched;

    // 1. Tìm chính xác theo songId từ cơ sở dữ liệu
    if (task.songId != null && task.songId!.isNotEmpty) {
      for (final song in songProv.songs) {
        if (song.id == task.songId) {
          matched = song;
          break;
        }
      }
    }

    // 2. Tìm theo tên bài hát nếu không khớp id
    if (matched == null) {
      final taskTitle = task.title?.trim().toLowerCase();
      if (taskTitle != null && taskTitle.isNotEmpty) {
        for (final song in songProv.songs) {
          final sTitle = song.title.trim().toLowerCase();
          if (sTitle == taskTitle ||
              sTitle.contains(taskTitle) ||
              taskTitle.contains(sTitle)) {
            matched = song;
            break;
          }
        }
      }
    }

    // 3. Phát nếu tìm thấy, hoặc thông báo nếu không tìm thấy trong thư viện
    if (matched != null) {
      audioPlayerService.playSong(matched);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bài hát đã được lưu. Mở tab Thư viện để nghe.',
            style: GoogleFonts.jetBrainsMono(fontSize: 12),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<DownloadProvider, SongProvider>(
      builder: (context, downloadProv, songProv, _) {
        final task = downloadProv.primaryTask;
        if (task == null) {
          if (_pulseController.isAnimating) {
            _pulseController.stop();
          }
          return const SizedBox.shrink();
        }

        if (task.isActive) {
          if (!_pulseController.isAnimating) {
            _pulseController.repeat(reverse: true);
          }
        } else {
          if (_pulseController.isAnimating) {
            _pulseController.stop();
          }
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final hudBg = AppTheme.getSurfaceElevated(context);
        final textPrimary = AppTheme.getText(context);
        final textMuted = AppTheme.getTextMuted(context);

        Color accentColor;
        String statusLabel;
        IconData statusIcon;

        if (task.stage == DownloadStage.completed) {
          accentColor = const Color(0xFF10B981); // Emerald Green
          statusLabel = 'TẢI HOÀN TẤT';
          statusIcon = Icons.check_circle_outline_rounded;
        } else if (task.stage == DownloadStage.failed) {
          accentColor = const Color(0xFFEF4444); // Crimson Red
          statusLabel = 'LỖI TẢI XUỐNG';
          statusIcon = Icons.error_outline_rounded;
        } else {
          accentColor = const Color(0xFF38BDF8); // Cyber Cyan
          statusLabel = 'ĐANG TẢI XUỐNG';
          statusIcon = Icons.arrow_downward_rounded;
        }

        final tasksCount = downloadProv.tasks.length;
        final currentIdx = downloadProv.selectedIndex;

        return AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: hudBg,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.40),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Thanh tiêu đề: [Icon + Trạng thái] ... [Bộ đếm đa tác vụ + Timer + % + Nút đóng]
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (task.isActive)
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, _) {
                                return Opacity(
                                  opacity: 0.4 + (_pulseController.value * 0.6),
                                  child: Icon(statusIcon, size: 14, color: accentColor),
                                );
                              },
                            )
                          else
                            Icon(statusIcon, size: 14, color: accentColor),
                          const SizedBox(width: 6),
                          Text(
                            statusLabel,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: accentColor,
                            ),
                          ),
                          if (tasksCount > 1) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: downloadProv.prevTask,
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Icon(Icons.chevron_left_rounded, size: 14, color: textMuted),
                              ),
                            ),
                            Text(
                              '${currentIdx + 1}/$tasksCount',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            InkWell(
                              onTap: downloadProv.nextTask,
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Icon(Icons.chevron_right_rounded, size: 14, color: textMuted),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '[${task.formattedTimer}]',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: textMuted,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          task.progressPercentage,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => downloadProv.dismissTask(task.id),
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 5),

                // 2. Thông tin bài hát / Nghệ sĩ hoặc URL YouTube
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title != null
                            ? '${task.title}${task.artist != null && task.artist!.isNotEmpty && task.artist != 'Unknown' ? " • ${task.artist}" : ""}'
                            : task.url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),

                // 3. Thanh tiến trình chạy mượt mà (Animated Progress Bar)
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 0.0,
                    end: task.progress.clamp(0.0, 1.0),
                  ),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedProgress, _) {
                    return Container(
                      height: 4.5,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E232E) : const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: animatedProgress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 5),

                // 4. Mô tả giai đoạn & Các nút thao tác
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Tag giai đoạn & Mô tả tiếng Việt
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              task.stageTag,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              task.stageDescriptionVi,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9.5,
                                color: textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Nút điều khiển: [▶ PHÁT] / [↻ THỬ LẠI] / [HỦY] / [ĐÓNG]
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (task.stage == DownloadStage.completed) ...[
                          InkWell(
                            onTap: () {
                              _safePlaySong(context, task, songProv);
                              downloadProv.dismissTask(task.id);
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.6),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.play_arrow_rounded,
                                      size: 13, color: Color(0xFF10B981)),
                                  const SizedBox(width: 2),
                                  Text(
                                    'PHÁT',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (task.stage == DownloadStage.failed) ...[
                          InkWell(
                            onTap: () => downloadProv.retryTask(task.id, songProvider: songProv),
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.6),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.refresh_rounded,
                                      size: 13, color: Color(0xFFEF4444)),
                                  const SizedBox(width: 2),
                                  Text(
                                    'THỬ LẠI',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFEF4444),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (task.isActive) ...[
                          InkWell(
                            onTap: () => downloadProv.dismissTask(task.id),
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Text(
                                'HỦY',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: textMuted,
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          InkWell(
                            onTap: () => downloadProv.dismissTask(task.id),
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Text(
                                'ĐÓNG',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: textMuted,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
