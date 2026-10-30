import 'package:flutter/material.dart';
import '../storage/local_storage_service.dart';
import '../storage/storage_keys.dart';

/// Architecture controller managing the default statutory reading language ('en', 'te').
///
/// Persists user preference via [LocalStorageService] under [StorageKeys.defaultLanguage].
/// Notifies listeners whenever the default reading language preference changes.
class LanguageController extends ChangeNotifier {
  static const String english = 'en';
  static const String telugu = 'te';
  static const Set<String> supportedLanguages = {english, telugu};

  final LocalStorageService _storageService;
  String _defaultLanguage = english;
  bool _isInitialized = false;
  bool _userExplicitlyModified = false;
  String? _errorMessage;

  LanguageController({LocalStorageService? storageService})
    : _storageService = storageService ?? LocalStorageService();

  String get defaultLanguage => _defaultLanguage;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  bool get isEnglish => _defaultLanguage == english;
  bool get isTelugu => _defaultLanguage == telugu;

  /// Loads the persisted default language from local storage.
  ///
  /// Restores 'en' or 'te'. Falls back safely to 'en' on missing or invalid data.
  /// Does not overwrite a user's explicit selection made before initialization completes.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final raw = await _storageService.getString(StorageKeys.defaultLanguage);
      if (!_userExplicitlyModified && raw != null) {
        final parsed = _parseLanguage(raw);
        if (_defaultLanguage != parsed) {
          _defaultLanguage = parsed;
          notifyListeners();
        }
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load default language: $e';
    } finally {
      _isInitialized = true;
    }
  }

  /// Sets the default reading language, notifies listeners immediately, and persists to storage.
  Future<void> setDefaultLanguage(String language) async {
    final normalized = language.trim().toLowerCase();
    if (!supportedLanguages.contains(normalized)) {
      return; // Ignore unsupported language codes safely
    }

    _userExplicitlyModified = true;
    if (_defaultLanguage == normalized) return;

    _defaultLanguage = normalized;
    notifyListeners();

    try {
      await _storageService.setString(StorageKeys.defaultLanguage, normalized);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to persist default language: $e';
    }
  }

  static String _parseLanguage(String value) {
    final normalized = value.trim().toLowerCase();
    if (supportedLanguages.contains(normalized)) {
      return normalized;
    }
    return english;
  }
}
