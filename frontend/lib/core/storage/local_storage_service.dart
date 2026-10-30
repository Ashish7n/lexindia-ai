import 'package:shared_preferences/shared_preferences.dart';

/// Exception thrown when a local storage read, write, or removal operation fails.
class StorageException implements Exception {
  final String message;

  const StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}

/// Generic local persistence service wrapping [SharedPreferences].
///
/// Encapsulates reading, writing, and removing key-value entries safely.
/// Handles missing keys gracefully by returning `null`, catches unexpected platform
/// errors, and provides explicit removal and multi-key clearing without wiping
/// unrelated preferences.
class LocalStorageService {
  SharedPreferences? _preferences;

  /// Creates a [LocalStorageService].
  ///
  /// An optional [preferences] instance can be injected for deterministic
  /// unit testing. In production, the instance is lazily initialized via
  /// [SharedPreferences.getInstance].
  LocalStorageService({SharedPreferences? preferences})
    : _preferences = preferences;

  /// Returns the underlying [SharedPreferences] instance.
  Future<SharedPreferences> get _instance async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  /// Reads a string value associated with [key].
  ///
  /// Returns `null` if the key does not exist or has no stored value.
  Future<String?> getString(String key) async {
    try {
      final prefs = await _instance;
      return prefs.getString(key);
    } catch (e) {
      throw StorageException(
        'Failed to read key "$key" from local storage: $e',
      );
    }
  }

  /// Persists a [value] string associated with [key].
  ///
  /// Returns `true` if the write succeeded.
  /// Throws [StorageException] if the write operation fails.
  Future<bool> setString(String key, String value) async {
    try {
      final prefs = await _instance;
      final success = await prefs.setString(key, value);
      if (!success) {
        throw StorageException('Storage write returned false for key "$key"');
      }
      return true;
    } on StorageException {
      rethrow;
    } catch (e) {
      throw StorageException('Failed to write key "$key" to local storage: $e');
    }
  }

  /// Removes the value associated with [key].
  ///
  /// Safely succeeds even if the key does not exist in storage.
  /// Returns `true` if the key was successfully removed or was not present.
  Future<bool> remove(String key) async {
    try {
      final prefs = await _instance;
      if (!prefs.containsKey(key)) {
        return true;
      }
      final success = await prefs.remove(key);
      if (!success) {
        throw StorageException('Storage remove returned false for key "$key"');
      }
      return true;
    } on StorageException {
      rethrow;
    } catch (e) {
      throw StorageException(
        'Failed to remove key "$key" from local storage: $e',
      );
    }
  }

  /// Checks whether [key] exists in local storage.
  Future<bool> containsKey(String key) async {
    try {
      final prefs = await _instance;
      return prefs.containsKey(key);
    } catch (e) {
      throw StorageException('Failed to check key "$key" in local storage: $e');
    }
  }

  /// Removes only the explicitly specified [keys] from local storage.
  ///
  /// Does not wipe unrelated application preferences.
  Future<void> clearKeys(Iterable<String> keys) async {
    for (final key in keys) {
      await remove(key);
    }
  }
}
