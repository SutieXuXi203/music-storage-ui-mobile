import 'package:flutter/material.dart';
import 'package:reicon_flutter/reicon_flutter.dart';
import '../models/song_model.dart';
import '../core/theme/app_theme.dart';
import 'mini_equalizer_widget.dart';
import 're_icon.dart';

class SongCardWidget extends StatefulWidget {
  final int index;
  final Song song;
  final bool isCurrent;
  final bool isPlaying;
  final bool isBuffering;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const SongCardWidget({
    super.key,
    required this.index,
    required this.song,
    required this.isCurrent,
    required this.isPlaying,
    this.isBuffering = false,
    required this.onTap,
    this.onDelete,
  });

  @override
  State<SongCardWidget> createState() => _SongCardWidgetState();
}

class _SongCardWidgetState extends State<SongCardWidget> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final indexStr = (widget.index + 1).toString().padLeft(2, '0');

    // Đường viền đổi màu mượt mà khi hover hoặc khi bài hát đang chọn/phát/buffering
    final borderColor = widget.isCurrent
        ? ((widget.isPlaying || widget.isBuffering) ? AppTheme.terminalGreen : const Color(0xFF666666))
        : (_isHovered ? const Color(0xFF888888) : AppTheme.border);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
          decoration: BoxDecoration(
            color: widget.isCurrent ? AppTheme.surfaceLight : AppTheme.surface,
            borderRadius: BorderRadius.zero,
            border: Border.all(
              color: borderColor,
              width: widget.isCurrent ? 1.2 : 1.0,
            ),
            boxShadow: (widget.isCurrent && widget.isPlaying)
                ? [
                    BoxShadow(
                      color: AppTheme.terminalGreen.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              hoverColor: Colors.transparent,
              splashColor: AppTheme.terminalGreen.withValues(alpha: 0.12),
              highlightColor: AppTheme.terminalGreen.withValues(alpha: 0.05),
              borderRadius: BorderRadius.zero,
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                    // Số thứ tự hoặc Equalizer động khi bài hát đang phát
                    Container(
                      width: 28,
                      alignment: Alignment.centerLeft,
                      child: widget.isCurrent
                          ? (widget.isBuffering
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 1.6, color: AppTheme.terminalGreen),
                                )
                              : (widget.isPlaying
                                  ? const MiniEqualizerWidget(
                                      isPlaying: true,
                                      height: 14,
                                      width: 16,
                                      barCount: 4,
                                      color: AppTheme.terminalGreen,
                                    )
                                  : ReIcon(
                                      Reicon.outline.pause,
                                      size: 16,
                                      color: AppTheme.terminalGreen,
                                    )))
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
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.zero,
                        border: Border.all(
                          color: (widget.isCurrent && widget.isPlaying)
                              ? AppTheme.terminalGreen.withValues(alpha: 0.6)
                              : AppTheme.border,
                          width: 1,
                        ),
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
                              fontWeight: widget.isCurrent ? FontWeight.bold : FontWeight.w600,
                              color: widget.isCurrent
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
                      defaultColor: widget.isCurrent ? AppTheme.terminalGreen : AppTheme.textPrimary,
                      hoverColor: AppTheme.terminalGreen,
                      icon: widget.isBuffering
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 1.6, color: AppTheme.terminalGreen),
                            )
                          : AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                              child: ReIcon(
                                (widget.isCurrent && widget.isPlaying) ? Reicon.outline.pause : Reicon.outline.play,
                                key: ValueKey(widget.isCurrent && widget.isPlaying),
                                size: 15,
                              ),
                            ),
                    ),

                    if (widget.onDelete != null) ...[
                      const SizedBox(width: 6),
                      TerminalActionBtn(
                        onTap: widget.onDelete,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        defaultColor: AppTheme.textMuted,
                        hoverColor: AppTheme.error,
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
      ),
    );
  }
}
