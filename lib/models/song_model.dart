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
  final String? fallbackCoverUrl;
  final String? webViewLink;
  final String? userId;
  final String? userUsername;
  final DateTime? createdAt;
  final String? lyrics;
  final String? syncedLyrics;
  final String? lrcDriveFileId;

  String get bitrate => '192 kbps';
  bool get hasLyrics =>
      (lyrics != null && lyrics!.trim().isNotEmpty) ||
      (syncedLyrics != null && syncedLyrics!.trim().isNotEmpty);
  bool get hasSyncedLyrics =>
      syncedLyrics != null && syncedLyrics!.trim().isNotEmpty;

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
    this.fallbackCoverUrl,
    this.webViewLink,
    this.userId,
    this.userUsername,
    this.createdAt,
    this.lyrics,
    this.syncedLyrics,
    this.lrcDriveFileId,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    final songId = (json['id'] ?? json['_id'] ?? '').toString();
    final proxyStreamUrl = songId.isNotEmpty
        ? '${ApiConstants.baseUrl}/songs/$songId/stream'
        : null;

    final coverDriveId =
        json['cover_drive_file_id'] ?? json['thumbnail_drive_file_id'];

    // Google CDN trực tiếp lh3 (siêu nhanh, tương thích mọi browser, hỗ trợ CORS)
    final googleCdnUrl = coverDriveId != null
        ? 'https://lh3.googleusercontent.com/d/$coverDriveId'
        : null;

    // Backend proxy URL (có caching cục bộ)
    final proxyCoverUrl = songId.isNotEmpty && coverDriveId != null
        ? '${ApiConstants.baseUrl}/songs/$songId/cover'
        : null;

    final rawCoverUrl = (json['cover_url'] as String?)?.trim();

    // Ưu tiên link CDN trực tiếp lh3 hoặc json['cover_url'], nếu không có mới dùng proxyCoverUrl
    final primaryCoverUrl = (rawCoverUrl != null && rawCoverUrl.isNotEmpty)
        ? rawCoverUrl
        : (googleCdnUrl ?? proxyCoverUrl);

    // Fallback URL: nếu primary là Google CDN thì fallback là proxy, ngược lại là Google CDN
    final secondaryCoverUrl = (primaryCoverUrl == proxyCoverUrl)
        ? googleCdnUrl
        : proxyCoverUrl;

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
      coverUrl: primaryCoverUrl,
      fallbackCoverUrl: secondaryCoverUrl,
      webViewLink: json['web_view_link'],
      userId: json['user_id'],
      userUsername: json['user_username'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      lyrics: json['lyrics'],
      syncedLyrics: json['synced_lyrics'],
      lrcDriveFileId: json['lrc_drive_file_id'],
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
      'cover_drive_file_id': coverDriveFileId,
      'thumbnail_drive_file_id': thumbnailDriveFileId,
      'stream_url': streamUrl,
      'download_url': downloadUrl,
      'cover_url': coverUrl,
      'fallback_cover_url': fallbackCoverUrl,
      'web_view_link': webViewLink,
      'user_id': userId,
      'user_username': userUsername,
      'created_at': createdAt?.toIso8601String(),
      'lyrics': lyrics,
      'synced_lyrics': syncedLyrics,
      'lrc_drive_file_id': lrcDriveFileId,
    };
  }

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    int? duration,
    String? genre,
    String? format,
    int? fileSize,
    String? driveFileId,
    String? coverDriveFileId,
    String? thumbnailDriveFileId,
    String? streamUrl,
    String? downloadUrl,
    String? coverUrl,
    String? fallbackCoverUrl,
    String? webViewLink,
    String? userId,
    String? userUsername,
    DateTime? createdAt,
    String? lyrics,
    String? syncedLyrics,
    String? lrcDriveFileId,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      genre: genre ?? this.genre,
      format: format ?? this.format,
      fileSize: fileSize ?? this.fileSize,
      driveFileId: driveFileId ?? this.driveFileId,
      coverDriveFileId: coverDriveFileId ?? this.coverDriveFileId,
      thumbnailDriveFileId: thumbnailDriveFileId ?? this.thumbnailDriveFileId,
      streamUrl: streamUrl ?? this.streamUrl,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      fallbackCoverUrl: fallbackCoverUrl ?? this.fallbackCoverUrl,
      webViewLink: webViewLink ?? this.webViewLink,
      userId: userId ?? this.userId,
      userUsername: userUsername ?? this.userUsername,
      createdAt: createdAt ?? this.createdAt,
      lyrics: lyrics ?? this.lyrics,
      syncedLyrics: syncedLyrics ?? this.syncedLyrics,
      lrcDriveFileId: lrcDriveFileId ?? this.lrcDriveFileId,
    );
  }

  String get formattedDuration {
    if (duration <= 0) return '00:00';
    final minutes = (duration / 60).floor().toString().padLeft(2, '0');
    final seconds = (duration % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
