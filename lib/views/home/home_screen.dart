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

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final List<Widget> _tabs;
  StreamSubscription? _notifSub;

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
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
    return ListenableBuilder(
      listenable: audioPlayerService,
      builder: (context, _) {
        final hasActiveSong = audioPlayerService.currentSong != null;
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
              // High-Tech Download Process HUD
              const TechDownloadHud(),

              // Mini Player Dock
              if (hasActiveSong)
                MiniPlayerWidget(playerService: audioPlayerService),

              // Bottom Navigation Bar with Gradient Blur (top-to-bottom blur & fade)
              ClipRect(
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
                            _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
                            _buildNavItem(1, Icons.library_music_outlined, Icons.library_music, 'Library'),
                            _buildNavItem(2, Icons.search_outlined, Icons.search, 'Search'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, IconData iconOutline, IconData iconFilled, String label) {
    final isSelected = _currentIndex == index;
    final activeColor = AppTheme.getText(context);
    final inactiveColor = AppTheme.getTextMuted(context);

    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
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
