import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song_model.dart';
import '../providers/folder_provider.dart';
import '../core/theme/app_theme.dart';
import '../services/audio_player_service.dart';
import '../views/details/song_detail_screen.dart';
import 'mini_equalizer_widget.dart';

class SongCardWidget extends StatefulWidget {
  final int index;
  final Song song;
  final bool isCurrent;
  final bool isPlaying;
  final bool isBuffering;
  final bool showTrackNumber;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const SongCardWidget({
    super.key,
    required this.index,
    required this.song,
    required this.isCurrent,
    required this.isPlaying,
    this.isBuffering = false,
    this.showTrackNumber = false,
    required this.onTap,
    this.onDelete,
  });

  @override
  State<SongCardWidget> createState() => _SongCardWidgetState();
}

class _SongCardWidgetState extends State<SongCardWidget> {
  void _showOptionsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.getSurfaceElevated(context),
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusSheet)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 3,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color:
                        AppTheme.getTextMuted(context).withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(
                            color: AppTheme.getBorder(context), width: 0.8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: AppCoverImage(
                        url: widget.song.coverUrl,
                        width: 40,
                        height: 40,
                        iconSize: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppTheme.getText(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.song.artist} • ${widget.song.formattedDuration}',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.getTextSecondary(context)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: AppTheme.getBorder(context), height: 1),
                const SizedBox(height: 4),
                ListTile(
                  dense: true,
                  leading: Icon(Icons.play_arrow_outlined,
                      color: AppTheme.getText(context), size: 20),
                  title: Text('Phát bài hát',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.getText(context))),
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onTap();
                  },
                ),
                ListTile(
                  dense: true,
                  leading: Icon(Icons.playlist_play_rounded,
                      color: AppTheme.getText(context), size: 20),
                  title: Text('Phát tiếp theo',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.getText(context))),
                  onTap: () {
                    Navigator.pop(ctx);
                    audioPlayerService.addToNext(widget.song);
                    AppTheme.showSnackBar(
                      context,
                      'Đã thêm "${widget.song.title}" vào Bài tiếp theo',
                    );
                  },
                ),
                ListTile(
                  dense: true,
                  leading: Icon(Icons.info_outline,
                      color: AppTheme.getText(context), size: 20),
                  title: Text('Xem chi tiết bài hát',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.getText(context))),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SongDetailScreen(song: widget.song),
                      ),
                    );
                  },
                ),
                ListTile(
                  dense: true,
                  leading: Icon(Icons.drive_file_move_outlined,
                      color: AppTheme.getText(context), size: 20),
                  title: Text('Chuyển vào thư mục',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.getText(context))),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAddToFolderModal(context);
                  },
                ),
                if (widget.onDelete != null)
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.delete_outline,
                        color: AppTheme.getDanger(context), size: 20),
                    title: Text('Xoá khỏi kho nhạc',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.getDanger(context))),
                    onTap: () {
                      Navigator.pop(ctx);
                      widget.onDelete!();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddToFolderModal(BuildContext context) {
    final folderProv = Provider.of<FolderProvider>(context, listen: false);
    final folders = folderProv.folders;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.getSurfaceElevated(context),
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusSheet)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 32,
                    height: 3,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color:
                          AppTheme.getTextMuted(context).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CHỌN THƯ MỤC',
                      style: AppTheme.monoStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.getText(context),
                        letterSpacing: 0.6,
                      ),
                    ),
                    BouncingIconButton(
                      icon: Icon(Icons.close,
                          size: 20, color: AppTheme.getTextSecondary(context)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                Text(
                  'Chọn thư mục để chuyển bài hát "${widget.song.title}" vào',
                  style: TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.getTextSecondary(context)),
                ),
                const SizedBox(height: 10),
                Divider(color: AppTheme.getBorder(context), height: 1),
                const SizedBox(height: 6),
                if (folders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'Chưa có thư mục nào. Hãy tạo thư mục ở tab Thư viện trước.',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.getTextMuted(context)),
                      ),
                    ),
                  )
                else
                  ...folders.map((folder) {
                    final isAlreadyIn = folder.songIds.contains(widget.song.id);
                    return ListTile(
                      dense: true,
                      leading: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppTheme.getSurface(context),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                          border: Border.all(
                              color: AppTheme.getBorder(context), width: 0.8),
                        ),
                        child: Icon(Icons.folder_outlined,
                            size: 18, color: AppTheme.getText(context)),
                      ),
                      title: Text(
                        folder.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.getText(context),
                        ),
                      ),
                      subtitle: Text(
                        '${folder.songCount} bài hát',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.getTextSecondary(context)),
                      ),
                      trailing: isAlreadyIn
                          ? Text(
                              'ĐÃ CÓ',
                              style: AppTheme.monoStyle(
                                  fontSize: 10,
                                  color: AppTheme.getTextMuted(context)),
                            )
                          : Icon(Icons.add,
                              size: 18, color: AppTheme.getText(context)),
                      onTap: () async {
                        Navigator.pop(ctx);
                        final ok = await folderProv.addSongToFolder(
                            folder.id, widget.song);
                        if (context.mounted && ok) {
                          AppTheme.showSnackBar(
                            context,
                            'Đã chuyển "${widget.song.title}" vào thư mục "${folder.name}"',
                          );
                        }
                      },
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final trackNum = widget.index + 1;

    final cardBg = widget.isCurrent
        ? AppTheme.getSurfaceSubtle(context)
        : AppTheme.getSurface(context);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: widget.isCurrent
              ? AppTheme.getText(context).withValues(alpha: 0.3)
              : AppTheme.getBorder(context),
          width: 0.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                if (widget.showTrackNumber) ...[
                  SizedBox(
                    width: 22,
                    child: Text(
                      '$trackNum',
                      style: AppTheme.monoStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: widget.isCurrent
                            ? AppTheme.getText(context)
                            : AppTheme.getTextMuted(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppTheme.getSurfaceSubtle(context),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(
                          color: AppTheme.getBorder(context),
                          width: 0.8,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: AppCoverImage(
                        url: widget.song.coverUrl,
                        width: 38,
                        height: 38,
                        borderRadius: AppTheme.radiusSm,
                        iconSize: 18,
                      ),
                    ),
                    if (widget.isCurrent) ...[
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: Center(
                          child: widget.isBuffering
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 1.5, color: Colors.white),
                                )
                              : (widget.isPlaying
                                  ? const MiniEqualizerWidget(
                                      isPlaying: true,
                                      height: 12,
                                      width: 12,
                                      barCount: 3,
                                      color: Colors.white,
                                    )
                                  : const Icon(Icons.pause,
                                      color: Colors.white, size: 16)),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(width: 10),
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
                          fontWeight: widget.isCurrent
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: AppTheme.getText(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: AppTheme.getTextSecondary(context),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.song.formattedDuration,
                            style: AppTheme.monoStyle(
                              fontSize: 10,
                              color: AppTheme.getTextMuted(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                BouncingIconButton(
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: AppTheme.getTextSecondary(context),
                  ),
                  onPressed: () => _showOptionsModal(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
