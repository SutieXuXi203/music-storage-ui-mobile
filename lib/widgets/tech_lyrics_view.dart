import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/song_model.dart';
import '../services/api_service.dart';
import '../services/audio_player_service.dart';

class LrcLine {
  final Duration timestamp;
  final String text;

  const LrcLine({required this.timestamp, required this.text});
}

List<LrcLine> parseLrcContent(String lrc) {
  final lines = lrc.split('\n');
  final result = <LrcLine>[];
  final timeRegex = RegExp(r'\[(\d{2}):(\d{2})(?:\.(\d{1,3}))?\]');

  for (final line in lines) {
    final matches = timeRegex.allMatches(line).toList();
    if (matches.isEmpty) continue;

    final text = line.replaceAll(timeRegex, '').trim();
    if (text.isEmpty) continue;

    for (final match in matches) {
      final minutes = int.tryParse(match.group(1) ?? '0') ?? 0;
      final seconds = int.tryParse(match.group(2) ?? '0') ?? 0;
      final msStr = match.group(3) ?? '0';
      int milliseconds = 0;
      if (msStr.length == 1) {
        milliseconds = (int.tryParse(msStr) ?? 0) * 100;
      } else if (msStr.length == 2) {
        milliseconds = (int.tryParse(msStr) ?? 0) * 10;
      } else {
        milliseconds = int.tryParse(msStr.substring(0, 3)) ?? 0;
      }

      final dur = Duration(
        minutes: minutes,
        seconds: seconds,
        milliseconds: milliseconds,
      );
      result.add(LrcLine(timestamp: dur, text: text));
    }
  }

  result.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  return result;
}

class TechLyricsView extends StatefulWidget {
  final AudioPlayerService playerService;
  final Song song;
  final VoidCallback? onClose;
  final ValueChanged<Song>? onSongUpdated;

  const TechLyricsView({
    super.key,
    required this.playerService,
    required this.song,
    this.onClose,
    this.onSongUpdated,
  });

  @override
  State<TechLyricsView> createState() => _TechLyricsViewState();
}

class _TechLyricsViewState extends State<TechLyricsView> {
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();
  final GlobalKey _viewportKey = GlobalKey();
  final Map<int, GlobalKey> _itemKeys = {};
  List<LrcLine> _parsedLines = [];
  int _currentActiveIndex = -1;
  bool _isUserScrolling = false;
  Timer? _resumeAutoScrollTimer;
  bool _isFetchingLyrics = false;
  StreamSubscription<Duration>? _positionSub;

  late Song _currentSong;

  @override
  void initState() {
    super.initState();
    _currentSong = widget.song;
    _initLyricsData();
    _calculateInitialActiveIndex();
    _listenToPlayer();
    _checkLatestLyricsSilently();
  }

  void _calculateInitialActiveIndex() {
    if (_parsedLines.isEmpty) return;
    final pos = widget.playerService.player.position;
    int activeIdx = -1;
    for (int i = 0; i < _parsedLines.length; i++) {
      if (_parsedLines[i].timestamp <= pos) {
        activeIdx = i;
      } else {
        break;
      }
    }
    _currentActiveIndex = activeIdx;
    if (activeIdx >= 0) {
      _scrollToActiveIndex(activeIdx);
    }
  }

  Future<void> _checkLatestLyricsSilently() async {
    try {
      final res = await _apiService.getSongLyrics(_currentSong.id);
      if (!mounted) return;
      if (res != null && res['status'] == 'success') {
        final newLyrics = res['lyrics'] as String?;
        final newSynced = res['synced_lyrics'] as String?;
        if (newSynced != null && newSynced != _currentSong.syncedLyrics) {
          final updated = _currentSong.copyWith(
            lyrics: newLyrics,
            syncedLyrics: newSynced,
          );
          setState(() {
            _currentSong = updated;
            _initLyricsData();
          });
          widget.onSongUpdated?.call(updated);
        }
      }
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant TechLyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.id != widget.song.id ||
        oldWidget.song.syncedLyrics != widget.song.syncedLyrics ||
        oldWidget.song.lyrics != widget.song.lyrics) {
      _currentSong = widget.song;
      _initLyricsData();
      _calculateInitialActiveIndex();
      _checkLatestLyricsSilently();
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _resumeAutoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _initLyricsData() {
    _itemKeys.clear();
    if (_currentSong.hasSyncedLyrics) {
      _parsedLines = parseLrcContent(_currentSong.syncedLyrics!);
    } else {
      _parsedLines = [];
    }
  }

  void _listenToPlayer() {
    _positionSub?.cancel();
    _positionSub = widget.playerService.player.positionStream.listen((pos) {
      if (!mounted || _parsedLines.isEmpty) return;

      int activeIdx = -1;
      for (int i = 0; i < _parsedLines.length; i++) {
        if (_parsedLines[i].timestamp <= pos) {
          activeIdx = i;
        } else {
          break;
        }
      }

      if (activeIdx != _currentActiveIndex) {
        setState(() {
          _currentActiveIndex = activeIdx;
        });

        if (!_isUserScrolling && activeIdx >= 0) {
          _scrollToActiveIndex(activeIdx);
        }
      }
    });
  }

  void _scrollToActiveIndex(int index) {
    if (index < 0 || index >= _parsedLines.length) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = _itemKeys[index];
      final itemContext = key?.currentContext;
      if (itemContext == null) return;

      final itemBox = itemContext.findRenderObject() as RenderBox?;
      final viewportBox =
          _viewportKey.currentContext?.findRenderObject() as RenderBox?;

      if (itemBox != null &&
          itemBox.hasSize &&
          viewportBox != null &&
          viewportBox.hasSize &&
          _scrollController.hasClients) {
        // Tọa độ Y hiện tại của item bên trong viewport
        final itemInViewport =
            itemBox.localToGlobal(Offset.zero, ancestor: viewportBox);
        final itemCenterY = itemInViewport.dy + (itemBox.size.height / 2);
        final viewportCenterY = viewportBox.size.height / 2;

        // Tính độ lệch cần cuộn để đưa tâm item vào chính giữa viewport
        final delta = itemCenterY - viewportCenterY;

        // Nếu độ lệch rất nhỏ (< 1.5px) thì không cần cuộn lại
        if (delta.abs() < 1.5) return;

        final targetOffset = (_scrollController.offset + delta).clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        );

        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _onUserTouch() {
    _isUserScrolling = true;
    _resumeAutoScrollTimer?.cancel();
    _resumeAutoScrollTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _isUserScrolling = false;
        });
        if (_currentActiveIndex >= 0) {
          _scrollToActiveIndex(_currentActiveIndex);
        }
      }
    });
  }

  Future<void> _fetchOrRefreshLyrics({bool forceRefresh = false}) async {
    if (_isFetchingLyrics) return;
    setState(() {
      _isFetchingLyrics = true;
    });

    try {
      final res = await _apiService.getSongLyrics(
        _currentSong.id,
        refresh: forceRefresh,
      );

      if (!mounted) return;

      if (res != null && res['status'] == 'success') {
        final newLyrics = res['lyrics'] as String?;
        final newSynced = res['synced_lyrics'] as String?;

        if (newLyrics != null || newSynced != null) {
          final updated = _currentSong.copyWith(
            lyrics: newLyrics,
            syncedLyrics: newSynced,
          );
          setState(() {
            _currentSong = updated;
            _initLyricsData();
          });
          widget.onSongUpdated?.call(updated);
          AppTheme.showSnackBar(
            context,
            newSynced != null
                ? 'Đã tải lời bài hát đồng bộ (LRC) thành công!'
                : 'Đã tải lời bài hát thành công!',
          );
        } else {
          AppTheme.showSnackBar(
            context,
            'Không tìm thấy lời bài hát từ nhà cung cấp.',
          );
        }
      } else {
        AppTheme.showSnackBar(
          context,
          'Không thể lấy lời bài hát lúc này.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppTheme.showSnackBar(
        context,
        'Lỗi khi kết nối lấy lời bài hát: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingLyrics = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSynced = _parsedLines.isNotEmpty;
    final hasPlain = _currentSong.lyrics != null &&
        _currentSong.lyrics!.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceElevated(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: AppTheme.getBorder(context),
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          // Header: Tech header với // SYNCED bên trái và Làm mới bên phải
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 10, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 2.5,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(width: 2.5),
                    Container(
                      width: 2.0,
                      height: 7,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(width: 2.5),
                    Container(
                      width: 1.5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '/// SYNC_TELEMETRY',
                      style: AppTheme.monoStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isFetchingLyrics)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Đang tải...',
                            style: AppTheme.monoStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    else
                      BouncingWidget(
                        onTap: () => _fetchOrRefreshLyrics(forceRefresh: true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.getSurface(context),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSm),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 0.6,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.refresh_rounded,
                                size: 13,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Làm mới',
                                style: AppTheme.monoStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (widget.onClose != null) ...[
                      const SizedBox(width: 8),
                      BouncingWidget(
                        onTap: widget.onClose,
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Nội dung hiển thị lyrics
          Expanded(
            child: _buildLyricsBody(context, hasSynced, hasPlain),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsBody(BuildContext context, bool hasSynced, bool hasPlain) {
    if (_isFetchingLyrics && _parsedLines.isEmpty && !hasPlain) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            Text(
              'Đang tìm kiếm lời bài hát...',
              style: AppTheme.monoStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    if (hasSynced) {
      return KeyedSubtree(
        key: _viewportKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final halfHeight = constraints.maxHeight / 2;
            final verticalPad = halfHeight > 30.0 ? halfHeight - 24.0 : 40.0;

            return Stack(
              children: [
                // 2 vạch căn giữa công nghệ đối xứng 2 bên (Center Alignment Reticle Marks)
                Positioned(
                  left: 3,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IgnorePointer(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 1.5,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(0.5),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Container(
                            width: 2,
                            height: 1.5,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 3,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IgnorePointer(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 2,
                            height: 1.5,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(0.5),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Container(
                            width: 6,
                            height: 1.5,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                NotificationListener<UserScrollNotification>(
                  onNotification: (notification) {
                    _onUserTouch();
                    return false;
                  },
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      vertical: verticalPad,
                      horizontal: 14.0,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(_parsedLines.length, (index) {
                        final line = _parsedLines[index];
                        final isActive = index == _currentActiveIndex;
                        final itemKey =
                            _itemKeys.putIfAbsent(index, () => GlobalKey());

                        return BouncingWidget(
                          key: itemKey,
                          onTap: () {
                            widget.playerService.player.seek(line.timestamp);
                            _scrollToActiveIndex(index);
                            _onUserTouch();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 7.5),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.transparent,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSm),
                              border: Border.all(
                                color: isActive
                                    ? Colors.white.withValues(alpha: 0.85)
                                    : Colors.transparent,
                                width: 1.0,
                              ),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color:
                                            Colors.white.withValues(alpha: 0.16),
                                        blurRadius: 10,
                                        spreadRadius: 0.5,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (isActive) ...[
                                  // "thêm vài gạch nữa cho công nghệ" - Cụm vạch sóng tín hiệu vi mạch trắng
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 2.5,
                                        height: 15,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(1),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.white
                                                  .withValues(alpha: 0.85),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 2.0),
                                      Container(
                                        width: 1.5,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.7),
                                          borderRadius:
                                              BorderRadius.circular(1),
                                        ),
                                      ),
                                      const SizedBox(width: 2.0),
                                      Container(
                                        width: 2.5,
                                        height: 17,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(1),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.white
                                                  .withValues(alpha: 0.85),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 2.0),
                                      Container(
                                        width: 1.5,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.8),
                                          borderRadius:
                                              BorderRadius.circular(1),
                                        ),
                                      ),
                                      const SizedBox(width: 2.0),
                                      Container(
                                        width: 1.5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.5),
                                          borderRadius:
                                              BorderRadius.circular(1),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 5,
                                        height: 1.5,
                                        color:
                                            Colors.white.withValues(alpha: 0.6),
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                  ),
                                ] else ...[
                                  // Gạch mờ phân cách cho dòng chưa tới
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 1.2,
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.18),
                                          borderRadius:
                                              BorderRadius.circular(0.5),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                  ),
                                ],
                                Expanded(
                                  child: Text(
                                    line.text,
                                    textAlign: TextAlign.left,
                                    style: AppTheme.monoStyle(
                                      fontSize: isActive ? 14.5 : 12.5,
                                      fontWeight: isActive
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                      color: isActive
                                          ? Colors.white
                                          : Colors.white
                                              .withValues(alpha: 0.45),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isActive) ...[
                                  Text(
                                    '//',
                                    style: AppTheme.monoStyle(
                                      fontSize: 10.0,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          Colors.white.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  _formatTimestamp(line.timestamp),
                                  style: AppTheme.monoStyle(
                                    fontSize: isActive ? 11.5 : 10.5,
                                    fontWeight: isActive
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: isActive
                                        ? Colors.white
                                        : Colors.white
                                            .withValues(alpha: 0.35),
                                  ),
                                ),
                                if (isActive) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    width: 2.0,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    if (hasPlain) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: SelectableText(
          _currentSong.lyrics!,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.5,
            height: 1.8,
            color: AppTheme.getText(context),
            letterSpacing: 0.2,
          ),
        ),
      );
    }

    // Trạng thái chưa có lời
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.music_off_outlined,
              size: 40,
              color: AppTheme.getTextMuted(context).withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              'Chưa có lời cho bài hát này',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.getText(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Bạn có thể tự động tra cứu lời bài hát từ cơ sở dữ liệu LRCLIB hoặc phụ đề video.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.getTextSecondary(context),
              ),
            ),
            const SizedBox(height: 16),
            BouncingWidget(
              onTap: () => _fetchOrRefreshLyrics(forceRefresh: true),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      size: 14,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'TÌM LỜI BÀI HÁT NGAY',
                      style: AppTheme.pixelStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
