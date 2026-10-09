import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum WaveMusicType {
  spectrumBars,
  mirroredWave,
  oscilloscope,
}

extension WaveMusicTypeExt on WaveMusicType {
  String get id {
    switch (this) {
      case WaveMusicType.spectrumBars:
        return 'spectrum_bars';
      case WaveMusicType.mirroredWave:
        return 'mirrored_wave';
      case WaveMusicType.oscilloscope:
        return 'oscilloscope';
    }
  }

  String get label {
    switch (this) {
      case WaveMusicType.spectrumBars:
        return 'SPECTRUM_BARS';
      case WaveMusicType.mirroredWave:
        return 'MIRRORED_WAVE';
      case WaveMusicType.oscilloscope:
        return 'OSCILLOSCOPE';
    }
  }

  String get displayName {
    switch (this) {
      case WaveMusicType.spectrumBars:
        return 'Cột phổ tần số đáy (Mặc định)';
      case WaveMusicType.mirroredWave:
        return 'Sóng âm đối xứng tâm (SoundCloud)';
      case WaveMusicType.oscilloscope:
        return 'Máy hiện sóng quét Analog (Sine CRT)';
    }
  }

  String get tag {
    switch (this) {
      case WaveMusicType.spectrumBars:
        return '[01/03] DEFAULT';
      case WaveMusicType.mirroredWave:
        return '[02/03] SYMMETRIC';
      case WaveMusicType.oscilloscope:
        return '[03/03] ANALOG_CRT';
    }
  }
}

class SettingsProvider extends ChangeNotifier {
  static const String _prefWaveTypeKey = 'wave_music_type';
  static const String _prefThemeModeKey = 'app_theme_mode';

  WaveMusicType _waveType = WaveMusicType.spectrumBars;
  ThemeMode _themeMode = ThemeMode.dark;

  WaveMusicType get waveType => _waveType;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedType = prefs.getString(_prefWaveTypeKey);
      if (savedType != null) {
        final match = WaveMusicType.values.firstWhere(
          (t) => t.id == savedType,
          orElse: () => WaveMusicType.spectrumBars,
        );
        _waveType = match;
      }

      final savedTheme = prefs.getString(_prefThemeModeKey);
      if (savedTheme != null) {
        _themeMode = savedTheme == 'light' ? ThemeMode.light : ThemeMode.dark;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[SettingsProvider] Lỗi tải cài đặt: $e');
    }
  }

  Future<void> setWaveType(WaveMusicType type) async {
    if (_waveType == type) return;
    _waveType = type;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefWaveTypeKey, type.id);
    } catch (e) {
      debugPrint('[SettingsProvider] Lỗi lưu cài đặt: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _prefThemeModeKey, mode == ThemeMode.light ? 'light' : 'dark');
    } catch (e) {
      debugPrint('[SettingsProvider] Lỗi lưu cài đặt theme: $e');
    }
  }

  void toggleTheme() {
    setThemeMode(
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  void cycleWaveType() {
    final nextIndex = (_waveType.index + 1) % WaveMusicType.values.length;
    setWaveType(WaveMusicType.values[nextIndex]);
  }
}
