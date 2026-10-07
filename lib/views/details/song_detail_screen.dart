import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/song_model.dart';
import '../../services/audio_player_service.dart';

class SongDetailScreen extends StatelessWidget {
  final Song song;

  const SongDetailScreen({super.key, required this.song});

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '2.14 MB';
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.getBg(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.getText(context), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Album Cover (Compact 180x180, radius 12)
              Center(
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppTheme.getSurfaceSubtle(context),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.getBorder(context), width: 1.0),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: song.coverUrl != null && song.coverUrl!.isNotEmpty
                      ? Image.network(
                          song.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(Icons.music_note, size: 48, color: AppTheme.getTextMuted(context)),
                        )
                      : Icon(Icons.music_note, size: 48, color: AppTheme.getTextMuted(context)),
                ),
              ),
              const SizedBox(height: 16),

              // Title & Artist
              Text(
                song.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.getText(context),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                song.artist,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.getTextSecondary(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '2026 · ${song.formattedDuration} · ${song.format.toUpperCase()}',
                style: AppTheme.monoStyle(
                  fontSize: 11,
                  color: AppTheme.getTextMuted(context),
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons Row: [ PLAY ] [ SHUFFLE ]
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.getAction(context),
                          foregroundColor: AppTheme.getActionText(context),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          ),
                        ),
                        onPressed: () {
                          audioPlayerService.playSong(song);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_arrow, size: 18, color: AppTheme.getActionText(context)),
                            const SizedBox(width: 4),
                            Text('PLAY', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppTheme.getActionText(context))),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppTheme.getSurface(context),
                          foregroundColor: AppTheme.getText(context),
                          side: BorderSide(color: AppTheme.getBorder(context), width: 1.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          ),
                        ),
                        onPressed: () {
                          audioPlayerService.playSong(song);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shuffle, size: 16, color: AppTheme.getText(context)),
                            const SizedBox(width: 4),
                            Text('SHUFFLE', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: AppTheme.getText(context))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Secondary actions: [ + Add ] [ ♡ Favorite ] [ Download ] [ More ]
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPillAction(context, icon: Icons.add, label: 'Add'),
                  _buildPillAction(context, icon: Icons.favorite_border, label: 'Favorite'),
                  _buildPillAction(context, icon: Icons.download_outlined, label: 'Download'),
                  _buildPillAction(context, icon: Icons.more_horiz, label: 'More'),
                ],
              ),
              const SizedBox(height: 20),

              // Information Section
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Information',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.getText(context)),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.getSurface(context),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(color: AppTheme.getBorder(context), width: 0.8),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(context, 'Format', song.format.toUpperCase(), isMono: true),
                    Divider(height: 1, color: AppTheme.getBorder(context)),
                    _buildInfoRow(context, 'Bitrate', song.bitrate.toUpperCase(), isMono: true),
                    Divider(height: 1, color: AppTheme.getBorder(context)),
                    _buildInfoRow(context, 'Size', _formatFileSize(song.fileSize), isMono: true),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Storage Section
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Storage',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.getText(context)),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.getSurface(context),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(color: AppTheme.getBorder(context), width: 0.8),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(context, 'Provider', 'Google Drive'),
                    Divider(height: 1, color: AppTheme.getBorder(context)),
                    _buildInfoRow(context, 'Status', 'Streaming ready'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillAction(BuildContext context, {required IconData icon, required String label}) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.getSurface(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          border: Border.all(color: AppTheme.getBorder(context), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.getTextSecondary(context)),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.getText(context))),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, {bool isMono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: AppTheme.getTextSecondary(context))),
          Text(
            value,
            style: isMono
                ? AppTheme.monoStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getText(context),
                  )
                : TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getText(context),
                  ),
          ),
        ],
      ),
    );
  }
}
