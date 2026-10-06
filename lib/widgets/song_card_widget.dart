import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/song_model.dart';
import '../core/theme/app_theme.dart';

class SongCardWidget extends StatelessWidget {
  final Song song;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const SongCardWidget({
    super.key,
    required this.song,
    required this.isPlaying,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isPlaying ? AppTheme.surfaceLight : AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isPlaying ? Border.all(color: AppTheme.primary, width: 1.5) : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 52,
            height: 52,
            color: AppTheme.surfaceLight,
            child: song.coverUrl != null && song.coverUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: song.coverUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Icon(
                      Icons.music_note,
                      color: AppTheme.textSecondary,
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.music_note,
                      color: AppTheme.textSecondary,
                    ),
                  )
                : const Icon(Icons.music_note, color: AppTheme.textSecondary),
          ),
        ),
        title: Text(
          song.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: isPlaying ? AppTheme.primaryLight : AppTheme.textPrimary,
          ),
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                song.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              song.formattedDuration,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                color: isPlaying ? AppTheme.primary : Colors.white,
                size: 32,
              ),
              onPressed: onTap,
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
                onPressed: onDelete,
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
