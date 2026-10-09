import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

enum NotificationEventType {
  progress,
  completed,
  failed,
  cancelled,
}

class DownloadNotificationRecord {
  final NotificationEventType type;
  final int id;
  final String title;
  final String? body;
  final int? progress;
  final String? payload;
  final DateTime timestamp;

  DownloadNotificationRecord({
    required this.type,
    required this.id,
    required this.title,
    this.body,
    this.progress,
    this.payload,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  static const String downloadChannelId = 'download_progress_channel';
  static const String downloadChannelName = 'Tiến trình tải nhạc';
  static const String downloadChannelDesc =
      'Hiển thị thông báo và thanh tiến trình khi tải bài hát từ YouTube vào Google Drive';

  static const String downloadCompletedChannelId = 'download_completed_channel';
  static const String downloadCompletedChannelName = 'Thông báo tải hoàn tất';
  static const String downloadCompletedChannelDesc =
      'Thông báo khi bài hát đã tải xuống thành công và lưu vào thư viện';

  static final StreamController<DownloadNotificationRecord>
      _notificationRecordController =
      StreamController<DownloadNotificationRecord>.broadcast();
  static Stream<DownloadNotificationRecord> get onNotificationRecord =>
      _notificationRecordController.stream;

  static final StreamController<String> _onNotificationTappedController =
      StreamController<String>.broadcast();
  static Stream<String> get onNotificationTapped =>
      _onNotificationTappedController.stream;

  @visibleForTesting
  void setPluginForTesting(FlutterLocalNotificationsPlugin plugin,
      {bool initialized = true}) {
    _notificationsPlugin = plugin;
    _initialized = initialized;
  }

  @visibleForTesting
  void resetForTesting() {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();
    _initialized = false;
  }

  Future<void> init() async {
    if (_initialized) return;

    if (!kIsWeb &&
        (Platform.isAndroid ||
            Platform.isIOS ||
            Platform.isMacOS ||
            Platform.isWindows ||
            Platform.isLinux)) {
      try {
        const androidInit =
            AndroidInitializationSettings('@mipmap/ic_launcher');
        const darwinInit = DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
        const linuxInit = LinuxInitializationSettings(
          defaultActionName: 'Open notification',
        );
        const windowsInit = WindowsInitializationSettings(
          appName: 'Meowsic',
          appUserModelId: 'com.sutiexuxi.musicapp.mobile_ui',
          guid: '2d1c69c1-7ef4-4f0f-8b9a-4c28f9d0c641',
        );

        final initSettings = const InitializationSettings(
          android: androidInit,
          iOS: darwinInit,
          macOS: darwinInit,
          linux: linuxInit,
          windows: windowsInit,
        );

        final initialized = await _notificationsPlugin.initialize(
          settings: initSettings,
          onDidReceiveNotificationResponse: (NotificationResponse response) {
            final payload = response.payload;
            if (payload != null && payload.isNotEmpty) {
              _onNotificationTappedController.add(payload);
            }
          },
        );

        if (Platform.isAndroid) {
          final androidPlatform =
              _notificationsPlugin.resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();

          if (androidPlatform != null) {
            const progressChannel = AndroidNotificationChannel(
              downloadChannelId,
              downloadChannelName,
              description: downloadChannelDesc,
              importance: Importance.low,
              playSound: false,
              enableVibration: false,
              showBadge: false,
            );
            await androidPlatform.createNotificationChannel(progressChannel);

            const completedChannel = AndroidNotificationChannel(
              downloadCompletedChannelId,
              downloadCompletedChannelName,
              description: downloadCompletedChannelDesc,
              importance: Importance.high,
              playSound: true,
              enableVibration: true,
              showBadge: true,
            );
            await androidPlatform.createNotificationChannel(completedChannel);

            await androidPlatform.requestNotificationsPermission();
          }
        }

        _initialized = initialized ?? true;
      } catch (e) {
        debugPrint(
            '[NotificationService] Lưu ý: Thông báo nền hệ thống chưa khả dụng: $e');
        _initialized = false;
      }
    }
  }

  Future<void> showDownloadProgress({
    required int id,
    required String title,
    required String stageDesc,
    required int progressPercent,
  }) async {
    final safeProgress = progressPercent.clamp(0, 100);
    final body = '$stageDesc ($safeProgress%)';

    _notificationRecordController.add(
      DownloadNotificationRecord(
        type: NotificationEventType.progress,
        id: id,
        title: title,
        body: body,
        progress: safeProgress,
      ),
    );

    if (!_initialized) return;

    try {
      final androidDetails = AndroidNotificationDetails(
        downloadChannelId,
        downloadChannelName,
        channelDescription: downloadChannelDesc,
        importance: Importance.low,
        priority: Priority.low,
        showProgress: true,
        maxProgress: 100,
        progress: safeProgress,
        ongoing: true,
        onlyAlertOnce: true,
        autoCancel: false,
        playSound: false,
        enableVibration: false,
        icon: '@mipmap/ic_launcher',
      );

      final windowsDetails = WindowsNotificationDetails(
        progressBars: [
          WindowsProgressBar(
            id: 'progress_$id',
            status: body,
            value: safeProgress / 100.0,
          ),
        ],
      );

      final notifDetails = NotificationDetails(
        android: androidDetails,
        windows: windowsDetails,
      );

      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notifDetails,
      );
    } catch (e) {
      debugPrint('[NotificationService] Lỗi cập nhật thông báo tiến trình: $e');
    }
  }

  Future<void> showDownloadCompleted({
    required int id,
    required String title,
    String? artist,
    String? payload,
  }) async {
    final body = (artist != null && artist.isNotEmpty && artist != 'Unknown')
        ? '$artist • Đã lưu vào Google Drive & Thư viện thành công'
        : 'Đã lưu vào Google Drive & Thư viện thành công';

    _notificationRecordController.add(
      DownloadNotificationRecord(
        type: NotificationEventType.completed,
        id: id,
        title: '✓ Đã tải xong: $title',
        body: body,
        progress: 100,
        payload: payload,
      ),
    );

    if (!_initialized) return;

    try {
      await _notificationsPlugin.cancel(id: id);

      const androidDetails = AndroidNotificationDetails(
        downloadCompletedChannelId,
        downloadCompletedChannelName,
        channelDescription: downloadCompletedChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        showProgress: false,
        ongoing: false,
        autoCancel: true,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        channelShowBadge: true,
        category: AndroidNotificationCategory.status,
      );

      final notifDetails = const NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        windows: WindowsNotificationDetails(),
        linux: LinuxNotificationDetails(),
      );

      await _notificationsPlugin.show(
        id: id,
        title: '✓ Đã tải xong: $title',
        body: body,
        notificationDetails: notifDetails,
        payload: payload ?? title,
      );
    } catch (e) {
      debugPrint('[NotificationService] Lỗi hiển thị thông báo hoàn tất: $e');
    }
  }

  Future<void> showDownloadFailed({
    required int id,
    required String title,
    required String error,
  }) async {
    _notificationRecordController.add(
      DownloadNotificationRecord(
        type: NotificationEventType.failed,
        id: id,
        title: '✕ Tải không thành công: $title',
        body: error,
      ),
    );

    if (!_initialized) return;

    try {
      await _notificationsPlugin.cancel(id: id);

      const androidDetails = AndroidNotificationDetails(
        downloadCompletedChannelId,
        downloadCompletedChannelName,
        channelDescription: downloadCompletedChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        showProgress: false,
        ongoing: false,
        autoCancel: true,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        category: AndroidNotificationCategory.status,
      );

      final notifDetails = const NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        windows: WindowsNotificationDetails(),
        linux: LinuxNotificationDetails(),
      );

      await _notificationsPlugin.show(
        id: id,
        title: '✕ Tải không thành công: $title',
        body: error,
        notificationDetails: notifDetails,
      );
    } catch (e) {
      debugPrint('[NotificationService] Lỗi hiển thị thông báo thất bại: $e');
    }
  }

  Future<void> cancel(int id) async {
    _notificationRecordController.add(
      DownloadNotificationRecord(
        type: NotificationEventType.cancelled,
        id: id,
        title: 'Cancelled',
      ),
    );

    if (!_initialized) return;
    try {
      await _notificationsPlugin.cancel(id: id);
    } catch (e) {
      debugPrint('[NotificationService] Lỗi hủy thông báo: $e');
    }
  }
}
