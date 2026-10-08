enum DownloadStage {
  queued,
  connecting,
  extracting,
  syncingDrive,
  indexingDb,
  completed,
  failed,
}

class DownloadTask {
  static int _idCounter = 1000;

  final String id;
  final String url;
  String? title;
  String? artist;
  String? songId;
  DownloadStage stage;
  double progress; // 0.0 -> 1.0
  int elapsedSeconds;
  String? errorMessage;
  final DateTime startedAt;
  final int notificationId;

  DownloadTask({
    required this.id,
    required this.url,
    this.title,
    this.artist,
    this.songId,
    this.stage = DownloadStage.queued,
    this.progress = 0.05,
    this.elapsedSeconds = 0,
    this.errorMessage,
    DateTime? startedAt,
    int? notificationId,
  })  : startedAt = startedAt ?? DateTime.now(),
        notificationId = notificationId ?? (++_idCounter);

  String get stageTag {
    switch (stage) {
      case DownloadStage.queued:
        return 'QUEUED';
      case DownloadStage.connecting:
        return 'CONN://YT';
      case DownloadStage.extracting:
        return 'EXTRACT://AUDIO';
      case DownloadStage.syncingDrive:
        return 'SYNC://DRIVE';
      case DownloadStage.indexingDb:
        return 'INDEX://MONGO';
      case DownloadStage.completed:
        return 'SYS://OK';
      case DownloadStage.failed:
        return 'SYS://ERR';
    }
  }

  String get stageShortVi {
    switch (stage) {
      case DownloadStage.queued:
        return 'Hàng đợi';
      case DownloadStage.connecting:
        return 'Kết nối';
      case DownloadStage.extracting:
        return 'Trích xuất MP3';
      case DownloadStage.syncingDrive:
        return 'Lưu Google Drive';
      case DownloadStage.indexingDb:
        return 'Lưu Thư viện';
      case DownloadStage.completed:
        return 'Thành công';
      case DownloadStage.failed:
        return 'Thất bại';
    }
  }

  String get stageDescriptionVi {
    switch (stage) {
      case DownloadStage.queued:
        return 'Đang chờ trong hàng đợi...';
      case DownloadStage.connecting:
        return 'Đang kết nối & nạp dữ liệu YouTube...';
      case DownloadStage.extracting:
        return 'Đang trích xuất & chuyển đổi MP3 320kbps...';
      case DownloadStage.syncingDrive:
        return 'Đang đồng bộ âm thanh lên Google Drive...';
      case DownloadStage.indexingDb:
        return 'Đang lập chỉ mục & lưu vào thư viện bài hát...';
      case DownloadStage.completed:
        return 'Đã tải xong! Đã lưu vào Google Drive & Thư viện';
      case DownloadStage.failed:
        return errorMessage ?? 'Tải bài hát không thành công';
    }
  }

  String get stageDescription => stageDescriptionVi;

  int get stageStep {
    switch (stage) {
      case DownloadStage.queued:
        return 0;
      case DownloadStage.connecting:
        return 1;
      case DownloadStage.extracting:
        return 2;
      case DownloadStage.syncingDrive:
        return 3;
      case DownloadStage.indexingDb:
      case DownloadStage.completed:
        return 4;
      case DownloadStage.failed:
        return 0;
    }
  }

  bool get isActive =>
      stage != DownloadStage.completed && stage != DownloadStage.failed;

  String get progressPercentage => '${(progress * 100).toInt()}%';

  String get formattedTimer {
    final mins = (elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (elapsedSeconds % 60).toString().padLeft(2, '0');
    return 'T+$mins:$secs';
  }

  String get asciiProgressBar {
    const totalBars = 16;
    final filledBars = (progress * totalBars).round().clamp(0, totalBars);
    final emptyBars = totalBars - filledBars;
    return '[${'=' * filledBars}>${' ' * (emptyBars > 0 ? emptyBars - 1 : 0)}]';
  }
}
