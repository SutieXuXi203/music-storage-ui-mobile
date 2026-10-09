import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/song_model.dart';
import '../../services/audio_player_service.dart';
import '../../services/notification_service.dart';
import '../../providers/song_provider.dart';
import '../../providers/folder_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/mini_player_widget.dart';
import '../../widgets/tech_download_hud.dart';
import 'tabs/home_tab.dart';
import 'tabs/search_tab.dart';
import 'tabs/library_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  late final List<Widget> _tabs;
  StreamSubscription? _notifSub;
  bool _isPromptingBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    audioPlayerService.addListener(_onPlayerChanged);
    _tabs = [
      HomeTab(
        onNavigateToSearch: () => _onTabTapped(2),
        onNavigateToLibrary: () => _onTabTapped(1),
      ),
      const LibraryTab(),
      const SearchTab(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SongProvider>(context, listen: false).fetchSongs();
      Provider.of<FolderProvider>(context, listen: false).fetchFolders();
    });

    _notifSub = NotificationService.onNotificationTapped.listen((payload) {
      if (!mounted) return;
      final songProv = Provider.of<SongProvider>(context, listen: false);
      Song? matched;
      for (final s in songProv.songs) {
        if (s.id == payload || s.title.toLowerCase() == payload.toLowerCase()) {
          matched = s;
          break;
        }
      }
      if (matched != null) {
        audioPlayerService.playSong(matched);
      } else {
        _onTabTapped(1);
      }
    });
  }

  void _onPlayerChanged() {
    if (!mounted) return;
    if (audioPlayerService.isPlaying && !_isPromptingBackground) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      if (!settings.askedBackgroundPlayback) {
        _isPromptingBackground = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final result = await AppTheme.showBackgroundPlaybackDialog(context);
          if (mounted && result != null) {
            settings.setBackgroundPlayback(result, asked: true);
          }
          _isPromptingBackground = false;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      if (!settings.backgroundPlayback && audioPlayerService.isPlaying) {
        audioPlayerService.pause();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    audioPlayerService.removeListener(_onPlayerChanged);
    _notifSub?.cancel();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = AppTheme.getSurface(context);
    final borderColor = AppTheme.getBorder(context);

    return Scaffold(
      backgroundColor: AppTheme.getBg(context),
      extendBody: true,
      body: Stack(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _currentIndex == index;
          return IgnorePointer(
            ignoring: !isSelected,
            child: AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: _tabs[index],
            ),
          );
        }),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const RepaintBoundary(child: TechDownloadHud()),
          ListenableBuilder(
            listenable: audioPlayerService,
            builder: (context, _) {
              if (audioPlayerService.currentSong == null) {
                return const SizedBox.shrink();
              }
              return RepaintBoundary(
                child: MiniPlayerWidget(playerService: audioPlayerService),
              );
            },
          ),
          RepaintBoundary(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        surfaceColor.withValues(alpha: 0.45),
                        surfaceColor.withValues(alpha: 0.80),
                        surfaceColor.withValues(alpha: 0.98),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                    border: Border(
                      top: BorderSide(
                        color: borderColor.withValues(alpha: 0.6),
                        width: 0.8,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      height: 52,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNavItem(
                              0, Icons.home_outlined, Icons.home, 'Trang chủ'),
                          _buildNavItem(1, Icons.library_music_outlined,
                              Icons.library_music, 'Thư viện'),
                          _buildNavItem(2, Icons.search_outlined,
                              Icons.search, 'Tìm kiếm'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData iconOutline, IconData iconFilled, String label) {
    final isSelected = _currentIndex == index;
    final activeColor = AppTheme.getText(context);
    final inactiveColor = AppTheme.getTextMuted(context);

    return Expanded(
      child: BouncingWidget(
        onTap: () => _onTabTapped(index),
        scaleFactor: 0.90,
        child: SizedBox(
          height: 52,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? iconFilled : iconOutline,
                color: isSelected ? activeColor : inactiveColor,
                size: 20,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
