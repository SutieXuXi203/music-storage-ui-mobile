import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import '../services/api_service.dart';
import '../services/audio_player_service.dart';

class SongProvider extends ChangeNotifier {
  List<Song> _songs = [];
  bool _isLoading = false;
  bool _isDownloading = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<String> _recentSongIds = [];
  bool _isRecentLoaded = false;
  static const String _recentStorageKey = 'recently_played_song_ids';

  List<Song> get songs => _songs;
  bool get isLoading => _isLoading;
  bool get isDownloading => _isDownloading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  /// Danh sách đúng tối đa 5 bài hát được nghe gần đây nhất theo thứ tự LRU (Mới nghe nhất ở đầu)
  List<Song> get recentSongs {
    if (_songs.isEmpty) return [];

    final result = <Song>[];
    for (final id in _recentSongIds) {
      for (final s in _songs) {
        if (s.id == id) {
          result.add(s);
          break;
        }
      }
    }

    // Nếu vừa mở app và chưa kịp tải prefs, trả về tạm 5 bài đầu
    if (result.isEmpty && !_isRecentLoaded && _songs.isNotEmpty) {
      return _songs.take(5).toList();
    }

    return result.take(5).toList();
  }

  SongProvider({bool autoFetch = true}) {
    audioPlayerService.addSongPlayedListener(_handleSongPlayed);
    _loadRecentSongIds();
    if (autoFetch) {
      fetchSongs();
    }
  }

  void _handleSongPlayed(Song song) {
    // 1. Gỡ bài hát nếu đã có trong danh sách để đưa lên đầu
    _recentSongIds.remove(song.id);
    // 2. Chèn vào vị trí đầu tiên (vừa nghe)
    _recentSongIds.insert(0, song.id);
    // 3. Luôn giữ tối đa đúng 5 bài (bài nghe sớm nhất ở cuối sẽ bị đẩy ra)
    if (_recentSongIds.length > 5) {
      _recentSongIds = _recentSongIds.sublist(0, 5);
    }
    _saveRecentSongIds();
    notifyListeners();
  }

  Future<void> _loadRecentSongIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_recentStorageKey);
      if (saved != null) {
        _recentSongIds = List<String>.from(saved);
        _isRecentLoaded = true;
        notifyListeners();
      } else {
        _isRecentLoaded = true;
      }
    } catch (e) {
      debugPrint('[SongProvider] Lỗi đọc recently played: $e');
      _isRecentLoaded = true;
    }
  }

  Future<void> _saveRecentSongIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentStorageKey, _recentSongIds);
    } catch (e) {
      debugPrint('[SongProvider] Lỗi lưu recently played: $e');
    }
  }

  void clear() {
    _songs = [];
    _isLoading = false;
    _isDownloading = false;
    _errorMessage = null;
    _searchQuery = '';
    notifyListeners();
  }

  Future<void> fetchSongs({String? query}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _searchQuery = query ?? _searchQuery;
      _songs = await apiService.getSongs(search: _searchQuery.isNotEmpty ? _searchQuery : null);

      // Nếu người dùng chưa từng nghe bài nào (lần đầu dùng), khởi tạo 5 bài đầu tiên
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey(_recentStorageKey) && _recentSongIds.isEmpty && _songs.isNotEmpty) {
        _recentSongIds = _songs.take(5).map((s) => s.id).toList();
        await prefs.setStringList(_recentStorageKey, _recentSongIds);
      }
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách bài hát: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> ingestYouTube(String url) => downloadFromYouTube(url);

  Future<bool> downloadFromYouTube(String url) async {
    _isDownloading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await apiService.downloadFromYoutube(url: url, format: 'mp3', saveToDrive: true);
      // Làm mới danh sách bài hát sau khi tải xong
      await fetchSongs();
      return res['status'] == 'success' || res['saved_to_drive'] == true;
    } catch (e) {
      _errorMessage = 'Tải nhạc từ YouTube thất bại: $e';
      return false;
    } finally {
      _isDownloading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteSong(String songId) async {
    try {
      final success = await apiService.deleteSong(songId);
      if (success) {
        _songs.removeWhere((s) => s.id == songId);
        if (_recentSongIds.remove(songId)) {
          _saveRecentSongIds();
        }
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = 'Không thể xóa bài hát: $e';
      return false;
    }
  }

  @override
  void dispose() {
    audioPlayerService.removeSongPlayedListener(_handleSongPlayed);
    super.dispose();
  }
}
