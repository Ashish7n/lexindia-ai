import 'package:flutter/material.dart';
import '../storage/local_storage_service.dart';
import '../storage/storage_keys.dart';

/// Architecture controller managing system, light, and dark theme modes.
///
/// Persists the selected theme mode locally via [LocalStorageService].
/// Notifies listeners whenever the user or system appearance changes.
class ThemeController extends ChangeNotifier {
  final LocalStorageService _storageService;
  ThemeMode _themeMode = ThemeMode.system;
  bool _isInitialized = false;
  bool _userExplicitlyModified = false;
  String? _errorMessage;

  ThemeController({LocalStorageService? storageService})
    : _storageService = storageService ?? LocalStorageService();

  ThemeMode get themeMode => _themeMode;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;

  /// Loads the persisted theme mode from local storage.
  ///
  /// Restores 'light', 'dark', or 'system'. If the key is missing, empty,
  /// or unparseable, defaults safely to [ThemeMode.system].
  /// Does not overwrite a user's explicit selection made before initialization completes.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final raw = await _storageService.getString(StorageKeys.themeMode);
      if (!_userExplicitlyModified && raw != null) {
        final parsed = _parseThemeMode(raw);
        if (_themeMode != parsed) {
          _themeMode = parsed;
          notifyListeners();
        }
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load theme preference: $e';
    } finally {
      _isInitialized = true;
    }
  }

  /// Sets the theme mode, notifies listeners immediately, and persists to storage.
  Future<void> setThemeMode(ThemeMode mode) async {
    _userExplicitlyModified = true;
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    try {
      final modeString = _themeModeToString(mode);
      await _storageService.setString(StorageKeys.themeMode, modeString);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to persist theme preference: $e';
    }
  }

  static ThemeMode _parseThemeMode(String value) {
    switch (value.trim().toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
