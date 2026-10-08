import 'package:flutter/foundation.dart';
import '../models/folder_model.dart';
import '../models/song_model.dart';
import '../services/api_service.dart';

class FolderProvider extends ChangeNotifier {
  List<Folder> _folders = [];
  bool _isLoading = false;
  String? _errorMessage;

  Folder? _currentFolder;
  bool _isLoadingDetails = false;

  List<Folder> get folders => _folders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Folder? get currentFolder => _currentFolder;
  bool get isLoadingDetails => _isLoadingDetails;

  FolderProvider() {
    fetchFolders();
  }

  void clear() {
    _folders = [];
    _currentFolder = null;
    _isLoading = false;
    _isLoadingDetails = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchFolders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _folders = await apiService.getFolders();
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách thư mục: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Folder?> createFolder(String name) async {
    try {
      final newFolder = await apiService.createFolder(name);
      if (newFolder != null) {
        _folders.insert(0, newFolder);
        notifyListeners();
        return newFolder;
      }
      return null;
    } catch (e) {
      _errorMessage = 'Tạo thư mục thất bại: $e';
      notifyListeners();
      return null;
    }
  }

  Future<bool> renameFolder(String folderId, String newName) async {
    try {
      final ok = await apiService.renameFolder(folderId, newName);
      if (ok) {
        final idx = _folders.indexWhere((f) => f.id == folderId);
        if (idx != -1) {
          _folders[idx] = _folders[idx].copyWith(name: newName, updatedAt: DateTime.now());
        }
        if (_currentFolder?.id == folderId) {
          _currentFolder = _currentFolder!.copyWith(name: newName, updatedAt: DateTime.now());
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteFolder(String folderId) async {
    try {
      final ok = await apiService.deleteFolder(folderId);
      if (ok) {
        _folders.removeWhere((f) => f.id == folderId);
        if (_currentFolder?.id == folderId) {
          _currentFolder = null;
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Folder?> fetchFolderDetails(String folderId) async {
    _isLoadingDetails = true;
    notifyListeners();

    try {
      final detailed = await apiService.getFolderDetails(folderId);
      if (detailed != null) {
        _currentFolder = detailed;
        // Cập nhật lại trong danh sách _folders nếu có
        final idx = _folders.indexWhere((f) => f.id == folderId);
        if (idx != -1) {
          _folders[idx] = detailed;
        }
      }
      return detailed;
    } catch (e) {
      return null;
    } finally {
      _isLoadingDetails = false;
      notifyListeners();
    }
  }

  Future<bool> addSongToFolder(String folderId, Song song, {String? fromFolderId}) async {
    try {
      final ok = await apiService.addSongToFolder(folderId, song.id, fromFolderId: fromFolderId);
      if (ok) {
        // Cập nhật thư mục đích
        final idx = _folders.indexWhere((f) => f.id == folderId);
        if (idx != -1) {
          final target = _folders[idx];
          final updatedSongIds = List<String>.from(target.songIds);
          if (!updatedSongIds.contains(song.id)) {
            updatedSongIds.add(song.id);
          }
          _folders[idx] = target.copyWith(
            songIds: updatedSongIds,
            songCount: updatedSongIds.length,
            coverUrl: target.coverUrl ?? song.coverUrl,
          );
        }

        // Nếu đang xem chi tiết thư mục đích, thêm bài vào list songs
        if (_currentFolder?.id == folderId) {
          final currentSongs = List<Song>.from(_currentFolder!.songs);
          if (!currentSongs.any((s) => s.id == song.id)) {
            currentSongs.add(song);
          }
          final updatedSongIds = List<String>.from(_currentFolder!.songIds);
          if (!updatedSongIds.contains(song.id)) {
            updatedSongIds.add(song.id);
          }
          _currentFolder = _currentFolder!.copyWith(
            songs: currentSongs,
            songIds: updatedSongIds,
            songCount: currentSongs.length,
            coverUrl: _currentFolder!.coverUrl ?? song.coverUrl,
          );
        }

        // Nếu chuyển từ thư mục khác, cập nhật thư mục cũ
        if (fromFolderId != null && fromFolderId.isNotEmpty) {
          final fromIdx = _folders.indexWhere((f) => f.id == fromFolderId);
          if (fromIdx != -1) {
            final fromFolder = _folders[fromIdx];
            final updatedFromIds = List<String>.from(fromFolder.songIds)..remove(song.id);
            _folders[fromIdx] = fromFolder.copyWith(
              songIds: updatedFromIds,
              songCount: updatedFromIds.length,
            );
          }
          if (_currentFolder?.id == fromFolderId) {
            final currentSongs = List<Song>.from(_currentFolder!.songs)..removeWhere((s) => s.id == song.id);
            final updatedFromIds = List<String>.from(_currentFolder!.songIds)..remove(song.id);
            _currentFolder = _currentFolder!.copyWith(
              songs: currentSongs,
              songIds: updatedFromIds,
              songCount: currentSongs.length,
            );
          }
        }

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeSongFromFolder(String folderId, String songId) async {
    try {
      final ok = await apiService.removeSongFromFolder(folderId, songId);
      if (ok) {
        final idx = _folders.indexWhere((f) => f.id == folderId);
        if (idx != -1) {
          final target = _folders[idx];
          final updatedIds = List<String>.from(target.songIds)..remove(songId);
          _folders[idx] = target.copyWith(
            songIds: updatedIds,
            songCount: updatedIds.length,
          );
        }

        if (_currentFolder?.id == folderId) {
          final updatedSongs = List<Song>.from(_currentFolder!.songs)..removeWhere((s) => s.id == songId);
          final updatedIds = List<String>.from(_currentFolder!.songIds)..remove(songId);
          _currentFolder = _currentFolder!.copyWith(
            songs: updatedSongs,
            songIds: updatedIds,
            songCount: updatedSongs.length,
            coverUrl: updatedSongs.isNotEmpty ? updatedSongs.first.coverUrl : null,
          );
        }

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
