import 'song_model.dart';

class Playlist {
  final String id;
  final String name;
  final String userId;
  final String? driveFolderId;
  final bool isDefault;
  final List<String> songIds;
  final int songCount;
  final String? coverUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<Song> songs;

  Playlist({
    required this.id,
    required this.name,
    required this.userId,
    this.driveFolderId,
    this.isDefault = false,
    this.songIds = const [],
    this.songCount = 0,
    this.coverUrl,
    this.createdAt,
    this.updatedAt,
    this.songs = const [],
  });

  String? get effectiveCoverUrl {
    if (coverUrl != null && coverUrl!.trim().isNotEmpty) {
      return coverUrl!.trim();
    }
    if (songs.isNotEmpty) {
      for (final s in songs) {
        if (s.coverUrl != null && s.coverUrl!.trim().isNotEmpty) {
          return s.coverUrl!.trim();
        }
      }
    }
    return null;
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    final rawSongIds = json['song_ids'];
    List<String> parsedSongIds = [];
    if (rawSongIds is List) {
      parsedSongIds = rawSongIds.map((e) => e.toString()).toList();
    }

    List<Song> parsedSongs = [];
    if (json['songs'] is List) {
      parsedSongs = (json['songs'] as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => Song.fromJson(item))
          .toList();
    }

    DateTime? parseDate(dynamic dateVal) {
      if (dateVal == null) return null;
      if (dateVal is DateTime) return dateVal;
      return DateTime.tryParse(dateVal.toString());
    }

    final id = (json['id'] ?? json['_id'] ?? '').toString();
    final count = json['song_count'] != null
        ? (json['song_count'] as num).toInt()
        : parsedSongIds.length;

    return Playlist(
      id: id,
      name: json['name']?.toString() ?? 'Thư mục không tên',
      userId: json['user_id']?.toString() ?? '',
      driveFolderId: json['drive_folder_id']?.toString(),
      isDefault: json['is_default'] == true,
      songIds: parsedSongIds,
      songCount: count,
      coverUrl: json['cover_url']?.toString(),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      songs: parsedSongs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'user_id': userId,
      'drive_folder_id': driveFolderId,
      'is_default': isDefault,
      'song_ids': songIds,
      'song_count': songCount,
      'cover_url': coverUrl,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Playlist copyWith({
    String? id,
    String? name,
    String? userId,
    String? driveFolderId,
    bool? isDefault,
    List<String>? songIds,
    int? songCount,
    String? coverUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Song>? songs,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      driveFolderId: driveFolderId ?? this.driveFolderId,
      isDefault: isDefault ?? this.isDefault,
      songIds: songIds ?? this.songIds,
      songCount: songCount ?? this.songCount,
      coverUrl: coverUrl ?? this.coverUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      songs: songs ?? this.songs,
    );
  }
}

typedef Folder = Playlist;
