import 'package:flutter/foundation.dart';
import '../models/song_model.dart';
import '../services/api_service.dart';

class SongProvider extends ChangeNotifier {
  List<Song> _songs = [];
  bool _isLoading = false;
  bool _isDownloading = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<Song> get songs => _songs;
  bool get isLoading => _isLoading;
  bool get isDownloading => _isDownloading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  SongProvider() {
    fetchSongs();
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
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = 'Không thể xóa bài hát: $e';
      return false;
    }
  }
}
