import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/storage/storage_keys.dart';
import '../models/history_item.dart';

/// Controller responsible for managing persisted BNS section viewing history.
///
/// Features:
/// - Reactive state management via [ChangeNotifier]
/// - Safe local persistence backed by [LocalStorageService]
/// - Bounded history size (maximum [maxHistoryItems] items)
/// - Deduplication by section number, updating recency to the top on revisit
/// - Defends against malformed JSON and corrupted records
/// - Serialized write queue to prevent race conditions during rapid navigation
/// - Reverts in-memory state on persistence failures and reports errors
class HistoryController extends ChangeNotifier {
  /// Maximum number of unique recent section provisions to store.
  static const int maxHistoryItems = 20;

  final LocalStorageService _storageService;

  List<HistoryItem> _history = [];

  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Serialized queue for write operations to prevent race conditions
  Future<void> _writeQueue = Future.value();

  HistoryController({LocalStorageService? storageService})
    : _storageService = storageService ?? LocalStorageService();

  /// Unmodifiable view of currently loaded history, ordered most recently viewed first.
  List<HistoryItem> get history => List.unmodifiable(_history);

  /// Total count of saved history items.
  int get count => _history.length;

  /// True once local storage has been read.
  bool get isInitialized => _isInitialized;

  /// True while an asynchronous operation is in progress.
  bool get isLoading => _isLoading;

  /// Message describing the last error that occurred, or null.
  String? get errorMessage => _errorMessage;

  /// Returns the [HistoryItem] for [sectionNumber], or null if absent.
  HistoryItem? getHistoryItem(int sectionNumber) {
    try {
      return _history.firstWhere((h) => h.sectionNumber == sectionNumber);
    } catch (_) {
      return null;
    }
  }

  /// Explicitly initializes and loads stored history from local storage.
  ///
  /// Defensively handles empty storage or malformed payloads,
  /// preserving any valid entries when individual records are corrupt.
  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rawJson = await _storageService.getString(
        StorageKeys.recentHistory,
      );
      if (rawJson == null || rawJson.trim().isEmpty) {
        _history = [];
      } else {
        final decoded = jsonDecode(rawJson);
        if (decoded is List) {
          final List<HistoryItem> validItems = [];
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              try {
                final historyItem = HistoryItem.fromJson(item);
                // Deduplicate by section number preserving the first (most recent) occurrence
                if (!validItems.any(
                  (h) => h.sectionNumber == historyItem.sectionNumber,
                )) {
                  validItems.add(historyItem);
                  if (validItems.length >= maxHistoryItems) {
                    break;
                  }
                }
              } catch (_) {
                // Skip invalid individual item defensively to preserve valid ones
              }
            }
          }
          _history = validItems;
        } else {
          // If stored value is not a list, reset to empty
          _history = [];
        }
      }
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // Catch any unexpected parse or storage read exception
      _history = [];
      _isInitialized = true;
      _isLoading = false;
      _errorMessage = 'Failed to load history: $e';
      notifyListeners();
    }
  }

  /// Serializes write operations so rapid consecutive actions
  /// cannot cause stale writes to overwrite newer history state.
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

  /// Records a visit to a section.
  ///
  /// If [item] was already visited, it moves to the top with the updated [item.lastViewedAt].
  /// Enforces [maxHistoryItems] bound by evicting the oldest items.
  /// If persistence fails, rolls back in-memory state and throws [StorageException].
  Future<void> recordVisit(HistoryItem item) async {
    if (!_isInitialized) {
      await initialize();
    }

    final previousHistory = List<HistoryItem>.from(_history);

    // Optimistically update in-memory state:
    // Remove existing entry for the same section if present, then prepend as newest
    _history.removeWhere((h) => h.sectionNumber == item.sectionNumber);
    _history.insert(0, item);

    // Enforce maximum history capacity
    if (_history.length > maxHistoryItems) {
      _history = _history.sublist(0, maxHistoryItems);
    }

    _errorMessage = null;
    notifyListeners();

    return _enqueueWrite(() async {
      try {
        await _persist();
      } catch (e) {
        // Rollback on failure
        _history = previousHistory;
        _errorMessage = 'Failed to record history visit: $e';
        notifyListeners();
        rethrow;
      }
    });
  }

  /// Clears all recorded history.
  Future<void> clearHistory() async {
    if (!_isInitialized) {
      await initialize();
    }

    final previousHistory = List<HistoryItem>.from(_history);
    _history = [];
    _errorMessage = null;
    notifyListeners();

    return _enqueueWrite(() async {
      try {
        await _persist();
      } catch (e) {
        _history = previousHistory;
        _errorMessage = 'Failed to clear history: $e';
        notifyListeners();
        rethrow;
      }
    });
  }

  /// Serializes and writes current history to local storage.
  Future<void> _persist() async {
    final jsonList = _history.map((h) => h.toJson()).toList();
    final jsonStr = jsonEncode(jsonList);
    await _storageService.setString(StorageKeys.recentHistory, jsonStr);
  }
}
