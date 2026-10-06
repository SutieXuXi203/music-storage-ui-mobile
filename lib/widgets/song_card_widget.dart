import 'package:flutter/material.dart';
import 'package:reicon_flutter/reicon_flutter.dart';
import '../models/song_model.dart';
import '../core/theme/app_theme.dart';
import 're_icon.dart';

class SongCardWidget extends StatefulWidget {
  final int index;
  final Song song;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const SongCardWidget({
    super.key,
    required this.index,
    required this.song,
    required this.isPlaying,
    required this.onTap,
    this.onDelete,
  });

  @override
  State<SongCardWidget> createState() => _SongCardWidgetState();
}

class _SongCardWidgetState extends State<SongCardWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final indexStr = (widget.index + 1).toString().padLeft(2, '0');

    // Đường viền đổi màu khi hover, tuyệt đối không đổi màu nền và không bo góc
    final borderColor = widget.isPlaying
        ? AppTheme.textPrimary
        : (_isHovered ? const Color(0xFF666666) : AppTheme.border);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        decoration: BoxDecoration(
          color: widget.isPlaying ? AppTheme.surfaceLight : AppTheme.surface,
          borderRadius: BorderRadius.zero, // Bỏ bo tròn hoàn toàn
          border: Border.all(
            color: borderColor,
            width: widget.isPlaying ? 1.2 : 1.0,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            hoverColor: Colors.transparent, // Không hiển thị màu hình nền hover
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            borderRadius: BorderRadius.zero,
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Số thứ tự hoặc icon đang phát dạng Terminal Reicon
                  Container(
                    width: 28,
                    alignment: Alignment.centerLeft,
                    child: widget.isPlaying
                        ? ReIcon(
                            Reicon.outline.musicPlay,
                            size: 16,
                            color: AppTheme.terminalGreen,
                          )
                        : Text(
                            indexStr,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.textMuted,
                            ),
                          ),
                  ),

                  // Ảnh Cover Art vuông vức viền mảnh chuẩn Terminal
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.zero, // Bỏ bo tròn
                      border: Border.fromBorderSide(BorderSide(color: AppTheme.border, width: 1)),
                    ),
                    child: widget.song.coverUrl != null && widget.song.coverUrl!.isNotEmpty
                        ? Image.network(
                            widget.song.coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              final coverId = widget.song.coverDriveFileId ?? widget.song.thumbnailDriveFileId;
                              if (coverId != null && !widget.song.coverUrl!.contains('googleusercontent')) {
                                return Image.network(
                                  'https://lh3.googleusercontent.com/d/$coverId',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: ReIcon(Reicon.outline.musicNote, size: 16, color: AppTheme.textMuted),
                                  ),
                                );
                              }
                              return Center(
                                child: ReIcon(Reicon.outline.musicNote, size: 16, color: AppTheme.textMuted),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 1.2, color: AppTheme.textMuted),
                                ),
                              );
                            },
                          )
                        : Center(
                            child: ReIcon(Reicon.outline.musicNote, size: 16, color: AppTheme.textMuted),
                          ),
                  ),

                  const SizedBox(width: 12),

                  // Tiêu đề & Nghệ sĩ
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: widget.isPlaying ? FontWeight.bold : FontWeight.w600,
                            color: widget.isPlaying
                                ? AppTheme.terminalGreen
                                : (_isHovered ? AppTheme.textPrimary : const Color(0xFFDDDDDD)),
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.song.formattedDuration,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Nút Play / Pause dùng Reicon
                  TerminalActionBtn(
                    onTap: widget.onTap,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    defaultColor: widget.isPlaying ? AppTheme.terminalGreen : AppTheme.textPrimary,
                    hoverColor: AppTheme.terminalGreen,
                    icon: ReIcon(
                      widget.isPlaying ? Reicon.outline.pause : Reicon.outline.play,
                      size: 15,
                    ),
                  ),

                  if (widget.onDelete != null) ...[
                    const SizedBox(width: 6),
                    TerminalActionBtn(
                      onTap: widget.onDelete,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      defaultColor: AppTheme.textMuted,
                      hoverColor: AppTheme.error, // Di chuột vào đổi màu đỏ cảnh báo xoá
                      hoverBorderColor: AppTheme.error,
                      icon: ReIcon(
                        Reicon.outline.trash,
                        size: 15,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
