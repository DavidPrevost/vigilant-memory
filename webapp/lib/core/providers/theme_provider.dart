import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Theme Mode State Notifier
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const String _themeModeKey = 'theme_mode';
  final SharedPreferences _prefs;

  ThemeModeNotifier(this._prefs) : super(_loadThemeMode(_prefs));

  static ThemeMode _loadThemeMode(SharedPreferences prefs) {
    final themeModeString = prefs.getString(_themeModeKey);
    switch (themeModeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(_themeModeKey, mode.name);
  }

  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }
}

// Shared Preferences Provider
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

// Theme Mode Provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);

  return prefs.when(
    data: (sharedPrefs) => ThemeModeNotifier(sharedPrefs),
    loading: () => ThemeModeNotifier(
      // Create a temporary instance with system theme while loading
      _DummySharedPreferences(),
    ),
    error: (_, __) => ThemeModeNotifier(
      _DummySharedPreferences(),
    ),
  );
});

// Dummy SharedPreferences for loading/error states
class _DummySharedPreferences implements SharedPreferences {
  @override
  String? getString(String key) => null;

  @override
  Future<bool> setString(String key, String value) async => true;

  // Implement other required methods as no-ops
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

// Current brightness provider (useful for conditional UI)
final currentBrightnessProvider = Provider<Brightness>((ref) {
  final themeMode = ref.watch(themeModeProvider);

  // Note: In a real app, you'd want to use MediaQuery to get system brightness
  // This is a simplified version
  switch (themeMode) {
    case ThemeMode.light:
      return Brightness.light;
    case ThemeMode.dark:
      return Brightness.dark;
    case ThemeMode.system:
      // Default to light for system mode
      // In actual widgets, use MediaQuery.of(context).platformBrightness
      return Brightness.light;
  }
});

// Is dark mode provider
final isDarkModeProvider = Provider<bool>((ref) {
  final brightness = ref.watch(currentBrightnessProvider);
  return brightness == Brightness.dark;
});
