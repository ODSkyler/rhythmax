import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme_mode.dart';

class ThemeController extends ChangeNotifier {
  static const _prefKey = 'app_theme_mode';
  static const _dynamicKey = 'dynamic_theme_enabled';

  AppThemeMode mode = AppThemeMode.dark;

  bool _dynamicEnabled = true;
  Color? _dynamicAccent;

  ThemeController() {
    _load();
  }

  /* -------------------------------------------------------------------------- */
  /*                               THEME MODE                                   */
  /* -------------------------------------------------------------------------- */

  bool get isAmoled => mode == AppThemeMode.amoled;

  Color get backgroundColor =>
      isAmoled ? Colors.black : const Color(0xFF1C1D22);

  /* -------------------------------------------------------------------------- */
  /*                           DYNAMIC THEME CONTROL                            */
  /* -------------------------------------------------------------------------- */

  bool get dynamicThemeEnabled => _dynamicEnabled;

  Color get accentColor {
    if (_dynamicEnabled && _dynamicAccent != null) {
      return _dynamicAccent!;
    }
    return Colors.cyanAccent;
  }

  Future<void> toggleDynamicTheme(bool value) async {
    _dynamicEnabled = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dynamicKey, value);
  }

  void setDynamicAccent(Color? color) {
    if (!_dynamicEnabled) return; // ignore if disabled
    _dynamicAccent = color;
    notifyListeners();
  }

  void clearDynamicAccent() {
    _dynamicAccent = null;
    notifyListeners();
  }

  /* -------------------------------------------------------------------------- */
  /*                               PERSISTENCE                                  */
  /* -------------------------------------------------------------------------- */

  Future<void> setTheme(AppThemeMode newMode) async {
    mode = newMode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKey, mode.index);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    final index = prefs.getInt(_prefKey);
    if (index != null && index < AppThemeMode.values.length) {
      mode = AppThemeMode.values[index];
    }

    _dynamicEnabled = prefs.getBool(_dynamicKey) ?? true;

    notifyListeners();
  }
}
