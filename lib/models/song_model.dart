import '../core/constants/api_constants.dart';

typedef SongModel = Song;

class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final int duration;
  final String genre;
  final String format;
  final int fileSize;
  final String? driveFileId;
  final String? coverDriveFileId;
  final String? thumbnailDriveFileId;
  final String? streamUrl;
  final String? downloadUrl;
  final String? coverUrl;
  final String? webViewLink;
  final String? userId;
  final String? userUsername;
  final DateTime? createdAt;

  String get bitrate => '192 kbps';

  Song({
    required this.id,
    required this.title,
    this.artist = 'Unknown Artist',
    this.album = 'Single',
    this.duration = 0,
    this.genre = 'Pop',
    this.format = 'mp3',
    this.fileSize = 0,
    this.driveFileId,
    this.coverDriveFileId,
    this.thumbnailDriveFileId,
    this.streamUrl,
    this.downloadUrl,
    this.coverUrl,
    this.webViewLink,
    this.userId,
    this.userUsername,
    this.createdAt,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    final songId = json['id'] ?? json['_id'] ?? '';
    // Luôn ưu tiên dùng backend stream proxy để phát nhạc mượt mà trên mọi nền tảng (Web/Mobile) không lỗi CORS
    final proxyStreamUrl = songId.isNotEmpty ? '${ApiConstants.baseUrl}/songs/$songId/stream' : null;

    final coverDriveId = json['cover_drive_file_id'] ?? json['thumbnail_drive_file_id'];
    final proxyCoverUrl = songId.isNotEmpty && coverDriveId != null
        ? '${ApiConstants.baseUrl}/songs/$songId/cover'
        : (coverDriveId != null ? 'https://lh3.googleusercontent.com/d/$coverDriveId' : null);

    return Song(
      id: songId,
      title: json['title'] ?? 'Bài hát không tên',
      artist: json['artist'] ?? 'Chưa rõ nghệ sĩ',
      album: json['album'] ?? 'Single',
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      genre: json['genre'] ?? 'Pop',
      format: json['format'] ?? 'mp3',
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      driveFileId: json['drive_file_id'],
      coverDriveFileId: coverDriveId,
      thumbnailDriveFileId: coverDriveId,
      streamUrl: proxyStreamUrl ?? json['stream_url'] ?? json['download_url'],
      downloadUrl: json['download_url'],
      coverUrl: proxyCoverUrl ?? json['cover_url'],
      webViewLink: json['web_view_link'],
      userId: json['user_id'],
      userUsername: json['user_username'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );

  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'duration': duration,
      'genre': genre,
      'format': format,
      'file_size': fileSize,
      'drive_file_id': driveFileId,
      'thumbnail_drive_file_id': thumbnailDriveFileId,
      'stream_url': streamUrl,
      'download_url': downloadUrl,
      'cover_url': coverUrl,
      'web_view_link': webViewLink,
      'user_id': userId,
      'user_username': userUsername,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  String get formattedDuration {
    if (duration <= 0) return '00:00';
    final minutes = (duration / 60).floor().toString().padLeft(2, '0');
    final seconds = (duration % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
