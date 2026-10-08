import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/download_task_model.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'song_provider.dart';

class DownloadProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final List<DownloadTask> _tasks = [];
  Timer? _timer;
  int _selectedTaskIndex = 0;

  List<DownloadTask> get tasks => List.unmodifiable(_tasks);

  bool get hasActiveTasks => _tasks.any((t) => t.isActive);

  List<DownloadTask> get activeTasks =>
      _tasks.where((t) => t.isActive).toList();

  int get selectedIndex => _selectedTaskIndex;

  DownloadTask? get primaryTask {
    if (activeTasks.isNotEmpty) {
      final safeIdx = _selectedTaskIndex.clamp(0, activeTasks.length - 1);
      return activeTasks[safeIdx];
    }
    if (_tasks.isNotEmpty) {
      return _tasks.last;
    }
    return null;
  }

  void nextTask() {
    if (activeTasks.length > 1) {
      _selectedTaskIndex = (_selectedTaskIndex + 1) % activeTasks.length;
      notifyListeners();
    }
  }

  void prevTask() {
    if (activeTasks.length > 1) {
      _selectedTaskIndex =
          (_selectedTaskIndex - 1 + activeTasks.length) % activeTasks.length;
      notifyListeners();
    }
  }

  void _ensureTimer() {
    if (_timer != null && _timer!.isActive) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      bool changed = false;
      for (final task in _tasks) {
        if (task.isActive) {
          task.elapsedSeconds += 1;
          changed = true;

          // Cập nhật tiến trình và stage mô phỏng theo thời gian thực thi
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

          // Cập nhật thanh tiến trình lên thông báo hệ thống của thiết bị
          final percent = (task.progress * 100).round().clamp(0, 100);
          NotificationService.instance.showDownloadProgress(
            id: task.notificationId,
            title: task.title ?? 'Đang tải nhạc từ YouTube...',
            stageDesc: task.stageDescriptionVi,
            progressPercent: percent,
          );
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
    _selectedTaskIndex = activeTasks.length - 1;
    _ensureTimer();
    notifyListeners();

    // Hiển thị ngay thông báo bắt đầu tải lên hệ thống của thiết bị
    NotificationService.instance.showDownloadProgress(
      id: task.notificationId,
      title: 'Đang kết nối YouTube...',
      stageDesc: task.stageDescriptionVi,
      progressPercent: 8,
    );

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

        // Báo cho thiết bị biết tải thành công (Chuông / Rung / Heads-up notification)
        await NotificationService.instance.showDownloadCompleted(
          id: task.notificationId,
          title: task.title ?? 'Bài hát mới',
          artist: task.artist,
        );

        // Tự động làm mới danh sách bài hát trong thư viện
        await songProvider.fetchSongs();

        // Tự động đóng HUD sau 12 giây nếu người dùng không bấm play/dismiss
        Future.delayed(const Duration(seconds: 12), () {
          if (_tasks.any((t) => t.id == task.id && t.stage == DownloadStage.completed)) {
            dismissTask(task.id);
          }
        });

        return true;
      } else {
        task.stage = DownloadStage.failed;
        task.errorMessage = res['message']?.toString() ?? 'Lỗi không xác định từ máy chủ';
        notifyListeners();

        await NotificationService.instance.showDownloadFailed(
          id: task.notificationId,
          title: task.title ?? 'Tải nhạc từ YouTube',
          error: task.errorMessage!,
        );
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

      await NotificationService.instance.showDownloadFailed(
        id: task.notificationId,
        title: task.title ?? 'Tải nhạc từ YouTube',
        error: msg,
      );
      return false;
    }
  }

  void retryTask(String taskId, {required SongProvider songProvider}) {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      final old = _tasks[idx];
      _tasks.removeAt(idx);
      NotificationService.instance.cancel(old.notificationId);
      startDownload(old.url, songProvider: songProvider);
    }
  }

  void dismissTask(String taskId) {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      NotificationService.instance.cancel(_tasks[idx].notificationId);
      _tasks.removeAt(idx);
      if (_selectedTaskIndex >= activeTasks.length && activeTasks.isNotEmpty) {
        _selectedTaskIndex = activeTasks.length - 1;
      }
      notifyListeners();
    }
  }

  void clearCompleted() {
    for (final t in _tasks.where((t) => !t.isActive)) {
      NotificationService.instance.cancel(t.notificationId);
    }
    _tasks.removeWhere((t) => !t.isActive);
    _selectedTaskIndex = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
