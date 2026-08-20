import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database_provider.dart';

const _darkModeKey = 'darkMode';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._ref) : super(ThemeMode.light) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    try {
      await _ref.read(databaseInitProvider.future);
      final db = _ref.read(databaseProvider);
      final value = await db.getSetting(_darkModeKey);
      if (value == 'true') state = ThemeMode.dark;
    } catch (_) {
      // Keep light theme if settings cannot be loaded yet.
    }
  }

  Future<void> setDarkMode(bool enabled) async {
    state = enabled ? ThemeMode.dark : ThemeMode.light;
    final db = _ref.read(databaseProvider);
    await db.setSetting(_darkModeKey, enabled ? 'true' : 'false');
  }

  bool get isDarkMode => state == ThemeMode.dark;
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref);
});
