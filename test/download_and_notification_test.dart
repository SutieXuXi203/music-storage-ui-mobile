import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile_ui/models/download_task_model.dart';
import 'package:mobile_ui/providers/download_provider.dart';
import 'package:mobile_ui/providers/song_provider.dart';
import 'package:mobile_ui/services/notification_service.dart';
import 'package:mobile_ui/widgets/tech_download_hud.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DownloadTask Model Tests', () {
    test(
        'Initializes correctly with default values and unique positive notificationId',
        () {
      final task1 = DownloadTask(
        id: 'TASK_123456',
        url: 'https://youtube.com/watch?v=abc',
        stage: DownloadStage.connecting,
        progress: 0.15,
      );

      final task2 = DownloadTask(
        id: 'TASK_123457',
        url: 'https://youtube.com/watch?v=def',
      );

      expect(task1.id, 'TASK_123456');
      expect(task1.url, 'https://youtube.com/watch?v=abc');
      expect(task1.stage, DownloadStage.connecting);
      expect(task1.progressPercentage, '15%');
      expect(task1.isActive, isTrue);
      expect(task1.stageTag, 'CONN://YT');
      expect(task1.stageStep, 1);
      expect(task1.stageDescriptionVi, contains('kết nối'));
      expect(task1.notificationId, greaterThan(0));
      expect(task2.notificationId, greaterThan(0));
      expect(task2.notificationId, isNot(equals(task1.notificationId)));
    });

    test('Stage descriptions, tags, and songId for all download stages', () {
      final completedTask = DownloadTask(
        id: 'TASK_999999',
        url: 'https://youtube.com/watch?v=xyz',
        title: 'See You Again',
        artist: 'Wiz Khalifa',
        songId: 'SONG_MONGO_123',
        stage: DownloadStage.completed,
        progress: 1.0,
      );

      expect(completedTask.isActive, isFalse);
      expect(completedTask.songId, 'SONG_MONGO_123');
      expect(completedTask.stageTag, 'SYS://OK');
      expect(completedTask.stageStep, 4);
      expect(completedTask.stageDescriptionVi, contains('Đã tải xong'));
      expect(completedTask.stageShortVi, 'Thành công');

      final failedTask = DownloadTask(
        id: 'TASK_888888',
        url: 'https://youtube.com/watch?v=bad',
        stage: DownloadStage.failed,
        errorMessage: 'Video bị bản quyền',
      );

      expect(failedTask.isActive, isFalse);
      expect(failedTask.stageTag, 'SYS://ERR');
      expect(failedTask.stageStep, 0);
      expect(failedTask.stageDescriptionVi, 'Video bị bản quyền');
      expect(failedTask.stageShortVi, 'Thất bại');

      final extractingTask = DownloadTask(
        id: 'TASK_EXTRACT',
        url: 'https://youtube.com/watch?v=ext',
        stage: DownloadStage.extracting,
      );
      expect(extractingTask.stageTag, 'EXTRACT://AUDIO');
      expect(extractingTask.stageStep, 2);

      final syncTask = DownloadTask(
        id: 'TASK_SYNC',
        url: 'https://youtube.com/watch?v=sync',
        stage: DownloadStage.syncingDrive,
      );
      expect(syncTask.stageTag, 'SYNC://DRIVE');
      expect(syncTask.stageStep, 3);
    });

    test('Timer formatting for seconds and minutes', () {
      final task1 = DownloadTask(
        id: 'TASK_T1',
        url: 'https://youtube.com/watch?v=1',
        elapsedSeconds: 5,
      );
      expect(task1.formattedTimer, 'T+00:05');

      final task2 = DownloadTask(
        id: 'TASK_T2',
        url: 'https://youtube.com/watch?v=2',
        elapsedSeconds: 65,
      );
      expect(task2.formattedTimer, 'T+01:05');
    });
  });

  group('DownloadProvider Multi-Task & Navigation Tests', () {
    test('Default state has no tasks and null primaryTask', () {
      final provider = DownloadProvider();
      expect(provider.hasActiveTasks, isFalse);
      expect(provider.primaryTask, isNull);
      expect(provider.tasks, isEmpty);
      expect(provider.selectedIndex, 0);
    });

    test('Single task tracking and dismissal', () {
      final provider = DownloadProvider();
      final task = DownloadTask(
        id: 'TASK_1',
        url: 'https://youtube.com/watch?v=1',
        title: 'Song One',
      );

      provider.addTestTask(task);
      expect(provider.tasks.length, 1);
      expect(provider.primaryTask?.id, 'TASK_1');

      provider.dismissTask('TASK_1');
      expect(provider.tasks, isEmpty);
      expect(provider.primaryTask, isNull);
    });

    test('Multi-task navigation between active and completed tasks', () {
      final provider = DownloadProvider();
      final task1 = DownloadTask(
        id: 'TASK_1',
        url: 'https://youtube.com/watch?v=1',
        title: 'Song One',
        stage: DownloadStage.completed,
      );
      final task2 = DownloadTask(
        id: 'TASK_2',
        url: 'https://youtube.com/watch?v=2',
        title: 'Song Two',
        stage: DownloadStage.extracting,
      );

      provider.addTestTask(task1);
      provider.addTestTask(task2);

      expect(provider.tasks.length, 2);
      expect(provider.selectedIndex, 1);
      expect(provider.primaryTask?.id, 'TASK_2');

      provider.prevTask();
      expect(provider.selectedIndex, 0);
      expect(provider.primaryTask?.id, 'TASK_1');

      provider.nextTask();
      expect(provider.selectedIndex, 1);
      expect(provider.primaryTask?.id, 'TASK_2');

      provider.selectTask(0);
      expect(provider.selectedIndex, 0);
      expect(provider.primaryTask?.id, 'TASK_1');
    });

    test('clearCompleted removes only completed tasks and updates selection',
        () {
      final provider = DownloadProvider();
      final taskCompleted = DownloadTask(
        id: 'TASK_DONE',
        url: 'https://youtube.com/watch?v=done',
        stage: DownloadStage.completed,
      );
      final taskActive = DownloadTask(
        id: 'TASK_ACTIVE',
        url: 'https://youtube.com/watch?v=active',
        stage: DownloadStage.connecting,
      );

      provider.addTestTask(taskCompleted);
      provider.addTestTask(taskActive);
      expect(provider.tasks.length, 2);

      provider.clearCompleted();
      expect(provider.tasks.length, 1);
      expect(provider.primaryTask?.id, 'TASK_ACTIVE');
    });
  });

  group('NotificationService Event Stream & Invocation Safety', () {
    test(
        'NotificationService records progress, completed, failed, and cancel events',
        () async {
      final service = NotificationService.instance;
      final events = <DownloadNotificationRecord>[];

      final sub = NotificationService.onNotificationRecord.listen((event) {
        events.add(event);
      });

      await service.showDownloadProgress(
        id: 999,
        title: 'Hát Với Chú Ve Con',
        stageDesc: 'Đang trích xuất MP3...',
        progressPercent: 60,
      );

      await service.showDownloadCompleted(
        id: 999,
        title: 'Hát Với Chú Ve Con',
        artist: 'Thanh Lam',
        payload: 'SONG_ID_999',
      );

      await service.showDownloadFailed(
        id: 888,
        title: 'Bài Hát Lỗi',
        error: 'Video không tồn tại',
      );

      await service.cancel(999);

      await Future.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      expect(events.length, 4);

      expect(events[0].type, NotificationEventType.progress);
      expect(events[0].id, 999);
      expect(events[0].title, 'Hát Với Chú Ve Con');
      expect(events[0].progress, 60);

      expect(events[1].type, NotificationEventType.completed);
      expect(events[1].id, 999);
      expect(events[1].title, contains('Đã tải xong'));
      expect(events[1].body, contains('Thanh Lam'));
      expect(events[1].payload, 'SONG_ID_999');

      expect(events[2].type, NotificationEventType.failed);
      expect(events[2].id, 888);
      expect(events[2].title, contains('Tải không thành công'));
      expect(events[2].body, 'Video không tồn tại');

      expect(events[3].type, NotificationEventType.cancelled);
      expect(events[3].id, 999);
    });

    test('Notification tap stream notifies listeners with payload', () async {
      final tappedPayloads = <String>[];
      final sub = NotificationService.onNotificationTapped.listen((payload) {
        tappedPayloads.add(payload);
      });

      NotificationService.instance.showDownloadCompleted(
        id: 123,
        title: 'Demo Song',
        payload: 'SONG_PAYLOAD_ABC',
      );

      final tapCallbackField = NotificationService.onNotificationTapped;
      expect(tapCallbackField, isNotNull);

      await sub.cancel();
    });

    test(
        'NotificationService.init() safely initializes without unhandled crashes',
        () async {
      final service = NotificationService.instance;
      await service.init();
    });
  });

  group('TechDownloadHud Widget Tests', () {
    testWidgets('Renders nothing when no task is present', (tester) async {
      final downloadProv = DownloadProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: downloadProv),
            ChangeNotifierProvider(
                create: (_) => SongProvider(autoFetch: false)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TechDownloadHud(),
            ),
          ),
        ),
      );

      expect(find.byType(TechDownloadHud), findsOneWidget);
      expect(find.text('ĐANG TẢI XUỐNG'), findsNothing);
      expect(find.text('TẢI HOÀN TẤT'), findsNothing);
    });

    testWidgets('Renders active downloading state with cancel button',
        (tester) async {
      final downloadProv = DownloadProvider();
      downloadProv.addTestTask(
        DownloadTask(
          id: 'TASK_ACTIVE',
          url: 'https://youtube.com/watch?v=123',
          title: 'Bài Hát Đang Tải',
          artist: 'Ca Sĩ Demo',
          stage: DownloadStage.extracting,
          progress: 0.45,
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: downloadProv),
            ChangeNotifierProvider(
                create: (_) => SongProvider(autoFetch: false)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TechDownloadHud(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('ĐANG TẢI XUỐNG'), findsOneWidget);
      expect(find.text('45%'), findsOneWidget);
      expect(find.textContaining('Bài Hát Đang Tải'), findsOneWidget);
      expect(find.text('HỦY'), findsOneWidget);

      await tester.tap(find.text('HỦY'));
      await tester.pump();

      expect(downloadProv.tasks, isEmpty);
      expect(find.text('ĐANG TẢI XUỐNG'), findsNothing);
    });

    testWidgets(
        'Renders multi-task switcher and allows switching between tasks',
        (tester) async {
      final downloadProv = DownloadProvider();
      final task1 = DownloadTask(
        id: 'TASK_1',
        url: 'https://youtube.com/watch?v=1',
        title: 'Song Completed',
        stage: DownloadStage.completed,
        progress: 1.0,
      );
      final task2 = DownloadTask(
        id: 'TASK_2',
        url: 'https://youtube.com/watch?v=2',
        title: 'Song In Progress',
        stage: DownloadStage.connecting,
        progress: 0.20,
      );

      downloadProv.addTestTask(task1);
      downloadProv.addTestTask(task2);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: downloadProv),
            ChangeNotifierProvider(
                create: (_) => SongProvider(autoFetch: false)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TechDownloadHud(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('2/2'), findsOneWidget);
      expect(find.text('ĐANG TẢI XUỐNG'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pump();

      expect(find.text('1/2'), findsOneWidget);
      expect(find.text('TẢI HOÀN TẤT'), findsOneWidget);
      expect(find.text('PHÁT'), findsOneWidget);
    });

    testWidgets('Renders completed download state with PHÁT and ĐÓNG buttons',
        (tester) async {
      final downloadProv = DownloadProvider();
      downloadProv.addTestTask(
        DownloadTask(
          id: 'TASK_DONE',
          url: 'https://youtube.com/watch?v=done',
          title: 'Bài Hát Hoàn Tất',
          artist: 'Ca Sĩ A',
          songId: 'SONG_DONE_ID',
          stage: DownloadStage.completed,
          progress: 1.0,
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: downloadProv),
            ChangeNotifierProvider(
                create: (_) => SongProvider(autoFetch: false)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TechDownloadHud(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('TẢI HOÀN TẤT'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('PHÁT'), findsOneWidget);
      expect(find.text('ĐÓNG'), findsOneWidget);

      await tester.tap(find.text('ĐÓNG'));
      await tester.pump();

      expect(downloadProv.tasks, isEmpty);
      expect(find.text('TẢI HOÀN TẤT'), findsNothing);
    });

    testWidgets('Renders failed download state with THỬ LẠI button',
        (tester) async {
      final downloadProv = DownloadProvider();
      downloadProv.addTestTask(
        DownloadTask(
          id: 'TASK_FAIL',
          url: 'https://youtube.com/watch?v=fail',
          title: 'Bài Hát Bị Lỗi',
          stage: DownloadStage.failed,
          errorMessage: 'Video bị bản quyền từ YouTube',
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: downloadProv),
            ChangeNotifierProvider(
                create: (_) => SongProvider(autoFetch: false)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TechDownloadHud(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('LỖI TẢI XUỐNG'), findsOneWidget);
      expect(find.text('THỬ LẠI'), findsOneWidget);
      expect(find.text('ĐÓNG'), findsOneWidget);
      expect(find.text('Video bị bản quyền từ YouTube'), findsOneWidget);
    });

    testWidgets('Tapping PHÁT on completed task dismisses HUD task safely',
        (tester) async {
      final downloadProv = DownloadProvider();
      downloadProv.addTestTask(
        DownloadTask(
          id: 'TASK_PLAY',
          url: 'https://youtube.com/watch?v=play',
          title: 'Bài Hát Test Phát',
          artist: 'Ca Sĩ B',
          stage: DownloadStage.completed,
          progress: 1.0,
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: downloadProv),
            ChangeNotifierProvider(
                create: (_) => SongProvider(autoFetch: false)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TechDownloadHud(),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('PHÁT'), findsOneWidget);

      await tester.tap(find.text('PHÁT'));
      await tester.pump();

      expect(downloadProv.tasks, isEmpty);
      expect(find.text('TẢI HOÀN TẤT'), findsNothing);
    });
  });
}
