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
  final String id;
  final String url;
  String? title;
  String? artist;
  DownloadStage stage;
  double progress; // 0.0 -> 1.0
  int elapsedSeconds;
  String? errorMessage;
  final DateTime startedAt;

  DownloadTask({
    required this.id,
    required this.url,
    this.title,
    this.artist,
    this.stage = DownloadStage.queued,
    this.progress = 0.05,
    this.elapsedSeconds = 0,
    this.errorMessage,
    DateTime? startedAt,
  }) : startedAt = startedAt ?? DateTime.now();

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

  String get stageDescription {
    switch (stage) {
      case DownloadStage.queued:
        return 'WAITING IN QUEUE...';
      case DownloadStage.connecting:
        return 'INITIALIZING STREAM METADATA';
      case DownloadStage.extracting:
        return 'DOWNLOADING & CONVERTING MP3 320K';
      case DownloadStage.syncingDrive:
        return 'UPLOADING TO GOOGLE DRIVE STORAGE';
      case DownloadStage.indexingDb:
        return 'INDEXING RECORD IN DATABASE';
      case DownloadStage.completed:
        return 'INGEST SUCCESSFUL // READY';
      case DownloadStage.failed:
        return errorMessage ?? 'INGESTION FAILED // ABORTED';
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
