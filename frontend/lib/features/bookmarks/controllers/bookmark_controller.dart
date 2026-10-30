import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/storage/storage_keys.dart';
import '../models/bookmarked_section.dart';

/// Controller responsible for managing persisted BNS section bookmarks.
///
/// Features:
/// - Reactive state management via [ChangeNotifier]
/// - Safe local persistence backed by [LocalStorageService]
/// - Defends against malformed JSON and corrupted records
/// - Prevents duplicate entries by section number
/// - Serialized write queue to prevent race conditions during rapid user taps
/// - Reverts in-memory state on persistence failures and reports errors
class BookmarkController extends ChangeNotifier {
  final LocalStorageService _storageService;

  List<BookmarkedSection> _bookmarks = [];
  Set<int> _bookmarkedSectionNumbers = {};

  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Serialized queue for write operations to prevent race conditions
  Future<void> _writeQueue = Future.value();

  BookmarkController({LocalStorageService? storageService})
    : _storageService = storageService ?? LocalStorageService();

  /// Unmodifiable view of currently loaded bookmarks, ordered by recency.
  List<BookmarkedSection> get bookmarks => List.unmodifiable(_bookmarks);

  /// True once local storage has been read.
  bool get isInitialized => _isInitialized;

  /// True while an asynchronous operation is in progress.
  bool get isLoading => _isLoading;

  /// Message describing the last error that occurred, or null.
  String? get errorMessage => _errorMessage;

  /// Checks whether [sectionNumber] is currently bookmarked in O(1) time.
  bool isBookmarked(int sectionNumber) =>
      _bookmarkedSectionNumbers.contains(sectionNumber);

  /// Returns the [BookmarkedSection] for [sectionNumber], or null if absent.
  BookmarkedSection? getBookmark(int sectionNumber) {
    try {
      return _bookmarks.firstWhere((b) => b.sectionNumber == sectionNumber);
    } catch (_) {
      return null;
    }
  }

  /// Explicitly initializes and loads stored bookmarks from local storage.
  ///
  /// Defensively handles empty storage or malformed payloads,
  /// preserving any valid entries when individual records are corrupt.
  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rawJson = await _storageService.getString(StorageKeys.bookmarks);
      if (rawJson == null || rawJson.trim().isEmpty) {
        _bookmarks = [];
        _bookmarkedSectionNumbers = {};
      } else {
        final decoded = jsonDecode(rawJson);
        if (decoded is List) {
          final List<BookmarkedSection> validItems = [];
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              try {
                final bookmark = BookmarkedSection.fromJson(item);
                // Prevent duplicate section numbers in stored payload
                if (!validItems.any(
                  (b) => b.sectionNumber == bookmark.sectionNumber,
                )) {
                  validItems.add(bookmark);
                }
              } catch (_) {
                // Skip invalid individual item defensively to preserve valid ones
              }
            }
          }
          _bookmarks = validItems;
          _bookmarkedSectionNumbers = validItems
              .map((b) => b.sectionNumber)
              .toSet();
        } else {
          // If stored value is not a list, reset to empty
          _bookmarks = [];
          _bookmarkedSectionNumbers = {};
        }
      }
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // Catch any unexpected parse or storage read exception
      _bookmarks = [];
      _bookmarkedSectionNumbers = {};
      _isInitialized = true;
      _isLoading = false;
      _errorMessage = 'Failed to load bookmarks: $e';
      notifyListeners();
    }
  }

  /// Serializes write operations so rapid consecutive actions
  /// cannot cause stale writes to overwrite newer bookmark state.
  Future<T> _enqueueWrite<T>(Future<T> Function() operation) async {
    final previous = _writeQueue;
    final completer = Completer<void>();
    _writeQueue = completer.future;

    try {
      await previous;
      return await operation();
    } finally {
      completer.complete();
    }
  }

  /// Adds a new [bookmark] to storage.
  ///
  /// Prevents duplicates. If persistence fails, rolls back in-memory state,
  /// sets [errorMessage], notifies listeners, and throws [StorageException].
  Future<void> addBookmark(BookmarkedSection bookmark) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (isBookmarked(bookmark.sectionNumber)) {
      return; // Already bookmarked, avoid duplicate
    }

    final previousBookmarks = List<BookmarkedSection>.from(_bookmarks);
    final previousNumbers = Set<int>.from(_bookmarkedSectionNumbers);

    // Optimistically update in-memory state for immediate UI reaction
    _bookmarks.insert(0, bookmark);
    _bookmarkedSectionNumbers.add(bookmark.sectionNumber);
    _errorMessage = null;
    notifyListeners();

    return _enqueueWrite(() async {
      try {
        await _persist();
      } catch (e) {
        // Rollback on failure
        _bookmarks = previousBookmarks;
        _bookmarkedSectionNumbers = previousNumbers;
        _errorMessage = 'Failed to save bookmark: $e';
        notifyListeners();
        rethrow;
      }
    });
  }

  /// Removes the bookmark for [sectionNumber] from storage.
  ///
  /// If persistence fails, rolls back in-memory state, sets [errorMessage],
  /// notifies listeners, and throws [StorageException].
  Future<void> removeBookmark(int sectionNumber) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!isBookmarked(sectionNumber)) {
      return; // Not bookmarked
    }

    final previousBookmarks = List<BookmarkedSection>.from(_bookmarks);
    final previousNumbers = Set<int>.from(_bookmarkedSectionNumbers);

    // Optimistically update in-memory state for immediate UI reaction
    _bookmarks.removeWhere((b) => b.sectionNumber == sectionNumber);
    _bookmarkedSectionNumbers.remove(sectionNumber);
    _errorMessage = null;
    notifyListeners();

    return _enqueueWrite(() async {
      try {
        await _persist();
      } catch (e) {
        // Rollback on failure
        _bookmarks = previousBookmarks;
        _bookmarkedSectionNumbers = previousNumbers;
        _errorMessage = 'Failed to remove bookmark: $e';
        notifyListeners();
        rethrow;
      }
    });
  }

  /// Toggles the bookmark status for [bookmark].
  ///
  /// Returns `true` if the section is now bookmarked, or `false` if removed.
  /// Throws [StorageException] if local persistence fails.
  Future<bool> toggleBookmark(BookmarkedSection bookmark) async {
    if (isBookmarked(bookmark.sectionNumber)) {
      await removeBookmark(bookmark.sectionNumber);
      return false;
    } else {
      await addBookmark(bookmark);
      return true;
    }
  }

  /// Serializes and writes current bookmarks to local storage.
  Future<void> _persist() async {
    final jsonList = _bookmarks.map((b) => b.toJson()).toList();
    final jsonStr = jsonEncode(jsonList);
    await _storageService.setString(StorageKeys.bookmarks, jsonStr);
  }
}
