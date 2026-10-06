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
  final String? thumbnailDriveFileId;
  final String? streamUrl;
  final String? downloadUrl;
  final String? coverUrl;
  final String? webViewLink;
  final String? userId;
  final String? userUsername;
  final DateTime? createdAt;

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
    return Song(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? 'Bài hát không tên',
      artist: json['artist'] ?? 'Chưa rõ nghệ sĩ',
      album: json['album'] ?? 'Single',
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      genre: json['genre'] ?? 'Pop',
      format: json['format'] ?? 'mp3',
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      driveFileId: json['drive_file_id'],
      thumbnailDriveFileId: json['thumbnail_drive_file_id'],
      streamUrl: json['stream_url'] ?? json['download_url'],
      downloadUrl: json['download_url'],
      coverUrl: json['cover_url'],
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
