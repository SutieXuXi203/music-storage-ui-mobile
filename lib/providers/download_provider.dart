import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/download_task_model.dart';
import '../services/api_service.dart';
import 'song_provider.dart';

class DownloadProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final List<DownloadTask> _tasks = [];
  Timer? _timer;

  List<DownloadTask> get tasks => List.unmodifiable(_tasks);

  bool get hasActiveTasks => _tasks.any((t) => t.isActive);

  List<DownloadTask> get activeTasks =>
      _tasks.where((t) => t.isActive).toList();

  DownloadTask? get primaryTask {
    if (activeTasks.isNotEmpty) {
      return activeTasks.last;
    }
    if (_tasks.isNotEmpty) {
      return _tasks.last;
    }
    return null;
  }

  void _ensureTimer() {
    if (_timer != null && _timer!.isActive) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      bool changed = false;
      for (final task in _tasks) {
        if (task.isActive) {
          task.elapsedSeconds += 1;
          changed = true;

          // Cập nhật tiến trình và stage giả định theo thời gian thực thi
          if (task.elapsedSeconds <= 3) {
            task.stage = DownloadStage.connecting;
            task.progress = (0.05 + task.elapsedSeconds * 0.05).clamp(0.0, 0.20);
          } else if (task.elapsedSeconds <= 12) {
            task.stage = DownloadStage.extracting;
            final ratio = (task.elapsedSeconds - 3) / 9.0;
            task.progress = (0.20 + ratio * 0.40).clamp(0.20, 0.60);
          } else if (task.elapsedSeconds <= 24) {
            task.stage = DownloadStage.syncingDrive;
            final ratio = (task.elapsedSeconds - 12) / 12.0;
            task.progress = (0.60 + ratio * 0.28).clamp(0.60, 0.88);
          } else {
            task.stage = DownloadStage.indexingDb;
            task.progress = (0.88 + ((task.elapsedSeconds - 24) * 0.01)).clamp(0.88, 0.96);
          }
        }
      }
      if (changed) {
        notifyListeners();
      } else {
        _timer?.cancel();
        _timer = null;
      }
    });
  }

  Future<bool> startDownload(
    String url, {
    required SongProvider songProvider,
  }) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return false;

    final taskId = 'TASK_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final task = DownloadTask(
      id: taskId,
      url: cleanUrl,
      stage: DownloadStage.connecting,
      progress: 0.08,
    );

    _tasks.add(task);
    _ensureTimer();
    notifyListeners();

    try {
      final res = await _apiService.downloadFromYoutube(
        url: cleanUrl,
        format: 'mp3',
        saveToDrive: true,
      );

      if (res['status'] == 'success') {
        task.stage = DownloadStage.completed;
        task.progress = 1.0;
        task.title = res['title']?.toString();
        task.artist = res['artist']?.toString();
        notifyListeners();

        // Tự động làm mới danh sách bài hát trong thư viện
        await songProvider.fetchSongs();
        return true;
      } else {
        task.stage = DownloadStage.failed;
        task.errorMessage = res['message']?.toString() ?? 'Lỗi không xác định từ máy chủ';
        notifyListeners();
        return false;
      }
    } catch (e) {
      task.stage = DownloadStage.failed;
      var msg = e.toString();
      if (msg.contains('400') || msg.contains('HTTP 400')) {
        msg = 'URL YouTube không hợp lệ hoặc video bị chặn bản quyền';
      } else if (msg.contains('timeout')) {
        msg = 'Thời gian kết nối quá lâu (Timeout)';
      }
      task.errorMessage = msg;
      notifyListeners();
      return false;
    }
  }

  void retryTask(String taskId, {required SongProvider songProvider}) {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      final old = _tasks[idx];
      _tasks.removeAt(idx);
      startDownload(old.url, songProvider: songProvider);
    }
  }

  void dismissTask(String taskId) {
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
  }

  void clearCompleted() {
    _tasks.removeWhere((t) => !t.isActive);
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
