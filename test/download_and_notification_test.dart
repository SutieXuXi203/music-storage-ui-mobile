import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile_ui/models/download_task_model.dart';
import 'package:mobile_ui/models/song_model.dart';
import 'package:mobile_ui/providers/download_provider.dart';
import 'package:mobile_ui/providers/song_provider.dart';
import 'package:mobile_ui/services/notification_service.dart';
import 'package:mobile_ui/widgets/tech_download_hud.dart';

class TestDownloadProvider extends DownloadProvider {
  final List<DownloadTask> _testTasks = [];

  void addTestTask(DownloadTask task) {
    _testTasks.add(task);
    notifyListeners();
  }

  @override
  List<DownloadTask> get tasks => List.unmodifiable(_testTasks);

  @override
  List<DownloadTask> get activeTasks =>
      _testTasks.where((t) => t.isActive).toList();

  @override
  DownloadTask? get primaryTask {
    if (activeTasks.isNotEmpty) return activeTasks.last;
    if (_testTasks.isNotEmpty) return _testTasks.last;
    return null;
  }
}

void main() {
  group('DownloadTask Model Tests', () {
    test('Initializes correctly with default values', () {
      final task = DownloadTask(
        id: 'TASK_123456',
        url: 'https://youtube.com/watch?v=abc',
        stage: DownloadStage.connecting,
        progress: 0.15,
      );

      expect(task.id, 'TASK_123456');
      expect(task.url, 'https://youtube.com/watch?v=abc');
      expect(task.stage, DownloadStage.connecting);
      expect(task.progressPercentage, '15%');
      expect(task.isActive, isTrue);
      expect(task.stageTag, 'CONN://YT');
      expect(task.stageStep, 1);
      expect(task.stageDescriptionVi, contains('kết nối'));
      expect(task.notificationId, greaterThan(0));
    });

    test('Stage descriptions and steps for completed and failed', () {
      final completedTask = DownloadTask(
        id: 'TASK_999999',
        url: 'https://youtube.com/watch?v=xyz',
        title: 'See You Again',
        artist: 'Wiz Khalifa',
        stage: DownloadStage.completed,
        progress: 1.0,
      );

      expect(completedTask.isActive, isFalse);
      expect(completedTask.stageTag, 'SYS://OK');
      expect(completedTask.stageStep, 4);
      expect(completedTask.stageDescriptionVi, contains('Đã tải xong'));

      final failedTask = DownloadTask(
        id: 'TASK_888888',
        url: 'https://youtube.com/watch?v=bad',
        stage: DownloadStage.failed,
        errorMessage: 'Video bị bản quyền',
      );

      expect(failedTask.isActive, isFalse);
      expect(failedTask.stageTag, 'SYS://ERR');
      expect(failedTask.stageDescriptionVi, 'Video bị bản quyền');
    });

    test('Timer formatting', () {
      final task = DownloadTask(
        id: 'TASK_TIMER',
        url: 'https://youtube.com/watch?v=test',
        elapsedSeconds: 65,
      );

      expect(task.formattedTimer, 'T+01:05');
    });
  });

  group('DownloadProvider Tests', () {
    test('Task dismissal and navigation', () {
      final provider = DownloadProvider();
      expect(provider.hasActiveTasks, isFalse);
      expect(provider.primaryTask, isNull);

      provider.dismissTask('NON_EXISTENT');
      expect(provider.tasks, isEmpty);
    });
  });

  group('NotificationService Invocation Safety', () {
    test('NotificationService methods do not throw in test environment', () async {
      final service = NotificationService.instance;
      await service.init();
      await service.showDownloadProgress(
        id: 101,
        title: 'Test Song',
        stageDesc: 'Đang tải...',
        progressPercent: 50,
      );
      await service.showDownloadCompleted(
        id: 101,
        title: 'Test Song',
        artist: 'Artist',
      );
      await service.showDownloadFailed(
        id: 101,
        title: 'Test Song',
        error: 'Network Error',
      );
      await service.cancel(101);
    });
  });

  group('TechDownloadHud Widget Tests', () {
    testWidgets('Renders nothing when no task is present', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => DownloadProvider()),
            ChangeNotifierProvider(create: (_) => SongProvider(autoFetch: false)),
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

    testWidgets('Renders active downloading state', (tester) async {
      final downloadProv = TestDownloadProvider();
      downloadProv.addTestTask(
        DownloadTask(
          id: 'TASK_ACTIVE',
          url: 'https://youtube.com/watch?v=123',
          title: 'Bài Hát Đang Tải',
          stage: DownloadStage.extracting,
          progress: 0.45,
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DownloadProvider>.value(value: downloadProv),
            ChangeNotifierProvider(create: (_) => SongProvider(autoFetch: false)),
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
      expect(find.text('Bài Hát Đang Tải'), findsOneWidget);
      expect(find.text('HỦY'), findsOneWidget);
    });

    testWidgets('Renders completed download state with PHÁT button', (tester) async {
      final downloadProv = TestDownloadProvider();
      downloadProv.addTestTask(
        DownloadTask(
          id: 'TASK_DONE',
          url: 'https://youtube.com/watch?v=done',
          title: 'Bài Hát Hoàn Tất',
          artist: 'Ca Sĩ A',
          stage: DownloadStage.completed,
          progress: 1.0,
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DownloadProvider>.value(value: downloadProv),
            ChangeNotifierProvider(create: (_) => SongProvider(autoFetch: false)),
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
      expect(find.text('PHÁT'), findsOneWidget);
      expect(find.text('ĐÓNG'), findsOneWidget);
    });

    testWidgets('Renders failed download state with THỬ LẠI button', (tester) async {
      final downloadProv = TestDownloadProvider();
      downloadProv.addTestTask(
        DownloadTask(
          id: 'TASK_FAIL',
          url: 'https://youtube.com/watch?v=fail',
          title: 'Bài Hát Lỗi',
          stage: DownloadStage.failed,
          errorMessage: 'Lỗi tải xuống',
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DownloadProvider>.value(value: downloadProv),
            ChangeNotifierProvider(create: (_) => SongProvider(autoFetch: false)),
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
    });
  });
}
