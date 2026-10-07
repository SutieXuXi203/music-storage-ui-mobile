import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song_model.dart';

class AudioPlayerService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  List<Song> _playlist = [];
  int _currentIndex = -1;
  bool _isLoading = false;

  AudioPlayer get player => _player;
  List<Song> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  Song? get currentSong => _currentIndex >= 0 && _currentIndex < _playlist.length ? _playlist[_currentIndex] : null;
  Song? get nextSong => (_currentIndex >= 0 && _currentIndex + 1 < _playlist.length)
      ? _playlist[_currentIndex + 1]
      : (_playlist.isNotEmpty ? _playlist.first : null);
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
        next(); // Tự động phát bài tiếp theo
      }
      notifyListeners();
    });

    _player.positionStream.listen((_) => notifyListeners());
    _player.durationStream.listen((_) => notifyListeners());
  }

  Future<void> setPlaylist(List<Song> songs, {int initialIndex = 0}) async {
    _playlist = List.from(songs);
    if (_playlist.isNotEmpty && initialIndex >= 0 && initialIndex < _playlist.length) {
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

  Future<void> playSongAtIndex(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    _currentIndex = index;
    final song = _playlist[index];

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
    _player.dispose();
    super.dispose();
  }
}

final audioPlayerService = AudioPlayerService();
