/// Centralized storage key constants for device local persistence.
///
/// Centralizing all keys ensures consistent naming across storage services
/// and controllers, eliminates literal string typos, and avoids key collisions.
abstract final class StorageKeys {
  /// Key for locally saved BNS section bookmarks JSON payload.
  static const String bookmarks = 'lexindia_bookmarks';

  /// Key for recently viewed BNS sections history JSON payload.
  static const String recentHistory = 'lexindia_recent_history';

  /// Key for persisted theme mode preference ('system', 'light', 'dark').
  static const String themeMode = 'lexindia_theme_mode';

  /// Key for default preferred statutory reading language ('en', 'te').
  static const String defaultLanguage = 'lexindia_default_language';

  /// Unmodifiable set of all defined storage keys for auditing and testing.
  static const Set<String> allKeys = {
    bookmarks,
    recentHistory,
    themeMode,
    defaultLanguage,
  };
}
