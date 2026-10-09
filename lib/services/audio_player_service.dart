import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song_model.dart';

typedef SongPlayedCallback = void Function(Song song);

class AudioPlayerService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final List<SongPlayedCallback> _songPlayedListeners = [];

  void addSongPlayedListener(SongPlayedCallback listener) {
    _songPlayedListeners.add(listener);
  }

  void removeSongPlayedListener(SongPlayedCallback listener) {
    _songPlayedListeners.remove(listener);
  }

  void _notifySongPlayed(Song song) {
    for (final listener
        in List<SongPlayedCallback>.from(_songPlayedListeners)) {
      try {
        listener(song);
      } catch (e) {
        debugPrint('[AudioPlayer] Lỗi listener bài hát vừa phát: $e');
      }
    }
  }

  List<Song> _playlist = [];
  int _currentIndex = -1;
  bool _isLoading = false;

  AudioPlayer get player => _player;
  List<Song> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  Song? get currentSong =>
      _currentIndex >= 0 && _currentIndex < _playlist.length
          ? _playlist[_currentIndex]
          : null;
  Song? get nextSong =>
      (_currentIndex >= 0 && _currentIndex + 1 < _playlist.length)
          ? _playlist[_currentIndex + 1]
          : (_playlist.isNotEmpty ? _playlist.first : null);
  List<Song> get upcomingSongs {
    if (_currentIndex < 0 || _currentIndex + 1 >= _playlist.length) return [];
    return _playlist.sublist(_currentIndex + 1);
  }
  bool get isLoading =>
      _isLoading ||
      _player.processingState == ProcessingState.buffering ||
      _player.processingState == ProcessingState.loading;
  bool get isBuffering => isLoading;
  bool get isPlaying => _player.playing;
  bool _isShuffle = false;
  bool get isShuffle => _isShuffle;
  bool _isLoop = false;
  bool get isLoop => _isLoop;

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  void toggleLoop() {
    _isLoop = !_isLoop;
    _player.setLoopMode(_isLoop ? LoopMode.one : LoopMode.off);
    notifyListeners();
  }

  AudioPlayerService() {
    _initStreams();
  }

  void _initStreams() {
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        next();
      }
      notifyListeners();
    });

    _player.durationStream.listen((_) => notifyListeners());
  }

  Future<void> setPlaylist(List<Song> songs, {int initialIndex = 0}) async {
    _playlist = List.from(songs);
    if (_playlist.isNotEmpty &&
        initialIndex >= 0 &&
        initialIndex < _playlist.length) {
      await playSongAtIndex(initialIndex);
    }
  }

  Future<void> playSong(Song song) async {
    final existingIndex = _playlist.indexWhere((s) => s.id == song.id);
    if (existingIndex >= 0) {
      await playSongAtIndex(existingIndex);
    } else {
      _playlist.insert(0, song);
      await playSongAtIndex(0);
    }
  }

  void addToNext(Song song) {
    if (_playlist.isEmpty || _currentIndex < 0) {
      playSong(song);
      return;
    }
    final existingIdx = _playlist.indexWhere((s) => s.id == song.id);
    if (existingIdx >= 0) {
      if (existingIdx == _currentIndex) return;
      _playlist.removeAt(existingIdx);
      if (existingIdx < _currentIndex) {
        _currentIndex--;
      }
    }
    final insertIdx = (_currentIndex + 1).clamp(0, _playlist.length);
    _playlist.insert(insertIdx, song);
    notifyListeners();
  }

  void removeUpcomingSong(String songId) {
    final idx = _playlist.indexWhere((s) => s.id == songId);
    if (idx < 0 || idx == _currentIndex) return;
    if (idx < _currentIndex) _currentIndex--;
    _playlist.removeAt(idx);
    notifyListeners();
  }

  void clearUpcomingSongs() {
    if (_currentIndex >= 0 && _currentIndex < _playlist.length) {
      _playlist = [_playlist[_currentIndex]];
      _currentIndex = 0;
    } else {
      _playlist.clear();
      _currentIndex = -1;
    }
    notifyListeners();
  }

  void updateCurrentSongMetadata(Song updated) {
    if (_currentIndex >= 0 && _currentIndex < _playlist.length) {
      _playlist[_currentIndex] = updated;
      notifyListeners();
    }
  }

  void reorderUpcoming(int oldIndex, int newIndex) {
    final base = _currentIndex + 1;
    final realOld = base + oldIndex;
    var realNew = base + newIndex;
    if (realOld < base || realOld >= _playlist.length) return;
    if (realNew < base || realNew > _playlist.length) return;
    if (oldIndex < newIndex) {
      realNew -= 1;
    }
    final item = _playlist.removeAt(realOld);
    _playlist.insert(realNew, item);
    notifyListeners();
  }

  Future<void> playSongAtIndex(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    _currentIndex = index;
    final song = _playlist[index];

    _notifySongPlayed(song);

    final streamUrl = song.streamUrl;
    if (streamUrl == null || streamUrl.isEmpty) {
      debugPrint('[AudioPlayer] Bài hát không có đường dẫn streamUrl!');
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      await _player.setUrl(streamUrl);
      await _player.play();
    } catch (e) {
      debugPrint('[AudioPlayer] Lỗi phát nhạc: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> pause() async {
    await _player.pause();
    notifyListeners();
  }

  Future<void> resume() async {
    await _player.play();
    notifyListeners();
  }

  Future<void> play() async {
    await _player.play();
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
    notifyListeners();
  }

  Future<void> next() async {
    if (_playlist.isEmpty) return;
    final nextIndex = (_currentIndex + 1) % _playlist.length;
    await playSongAtIndex(nextIndex);
  }

  Future<void> previous() async {
    if (_playlist.isEmpty) return;
    final prevIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    await playSongAtIndex(prevIndex);
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> stopAndReset() async {
    try {
      await _player.pause();
      await _player.stop();
    } catch (e) {
      debugPrint('[AudioPlayer] Lỗi dừng phát: $e');
    }
    _currentIndex = -1;
    _playlist.clear();
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _songPlayedListeners.clear();
    _player.dispose();
    super.dispose();
  }
}

final audioPlayerService = AudioPlayerService();
