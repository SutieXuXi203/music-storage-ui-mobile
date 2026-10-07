import 'song_model.dart';

class Folder {
  final String id;
  final String name;
  final String userId;
  final List<String> songIds;
  final int songCount;
  final String? coverUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<Song> songs;

  Folder({
    required this.id,
    required this.name,
    required this.userId,
    this.songIds = const [],
    this.songCount = 0,
    this.coverUrl,
    this.createdAt,
    this.updatedAt,
    this.songs = const [],
  });

  factory Folder.fromJson(Map<String, dynamic> json) {
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

    return Folder(
      id: id,
      name: json['name']?.toString() ?? 'Thư mục không tên',
      userId: json['user_id']?.toString() ?? '',
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
      'song_ids': songIds,
      'song_count': songCount,
      'cover_url': coverUrl,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Folder copyWith({
    String? id,
    String? name,
    String? userId,
    List<String>? songIds,
    int? songCount,
    String? coverUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Song>? songs,
  }) {
    return Folder(
      id: id ?? this.id,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      songIds: songIds ?? this.songIds,
      songCount: songCount ?? this.songCount,
      coverUrl: coverUrl ?? this.coverUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      songs: songs ?? this.songs,
    );
  }
}
