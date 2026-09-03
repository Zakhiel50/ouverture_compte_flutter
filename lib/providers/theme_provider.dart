import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _themePrefKey = 'selected_theme_mode';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }

  /// Charge la préférence de thème sauvegardée
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themePrefKey);
    if (isDark != null) {
      state = isDark ? ThemeMode.dark : ThemeMode.light;
    }
  }

  /// Bascule entre le mode Clair et le mode Sombre et sauvegarde le choix
  Future<void> toggleTheme() async {
    final nextMode = state == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    state = nextMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePrefKey, nextMode == ThemeMode.dark);
  }

  /// Définit explicitement un mode de thème et sauvegarde le choix
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePrefKey, mode == ThemeMode.dark);
  }
}

/// Provider Riverpod global pour écouter et modifier le mode de thème
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  return ThemeModeNotifier();
});
