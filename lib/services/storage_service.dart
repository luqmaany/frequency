import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

class StorageService {
  // Game setup keys
  static const String _playerNamesKey = 'player_names';
  static const String _suggestedNamesKey = 'suggested_names';
  // Removed: _teamsKey and _teamColorIndicesKey

  // App initialization key
  static const String _firstRunKey = 'first_run';

  // Game settings keys
  static const String _roundTimeSecondsKey = 'round_time_seconds';
  static const String _targetScoreKey = 'target_score';
  static const String _allowedSkipsKey = 'allowed_skips';

  // Game statistics keys
  static const String _gameHistoryKey = 'game_history';
  static const String _playerStatsKey = 'player_stats';
  static const String _teamStatsKey = 'team_stats';

  // App preferences keys
  static const String _soundEnabledKey = 'sound_enabled';
  static const String _vibrationEnabledKey = 'vibration_enabled';
  static const String _darkModeKey = 'dark_mode';

  // Queue constants
  static const int _maxQueueSize = 20;

  static const _deviceIdKey = 'device_id';

  // ===== APP INITIALIZATION METHODS =====

  // Check if this is the first run of the app
  static Future<bool> isFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstRunKey) != true;
  }

  // Mark the app as initialized (not first run)
  static Future<void> markAsInitialized() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstRunKey, true);
  }

  // Initialize default player names on first run
  static Future<void> initializeDefaultNames() async {
    final isFirst = await isFirstRun();
    if (isFirst) {
      final defaultNames = [
        'Aline',
        'Nazime',
        'Arash',
        'Cameron',
        'Jhud',
        'Huzaifah',
        'Mayy',
        'Siawosh',
        'Nadine',
        'Luqmaan',
        'Arun',
        'Malaika'
      ];
      await saveSuggestedNames(defaultNames);
      await markAsInitialized();
    }
  }

  // ===== GAME SETUP METHODS =====

  // Save player names to local storage (added players)
  static Future<void> savePlayerNames(List<String> playerNames) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_playerNamesKey, playerNames);
  }

  // Load player names from local storage (added players)
  static Future<List<String>> loadPlayerNames() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_playerNamesKey) ?? [];
  }

  // Save suggested names to local storage
  static Future<void> saveSuggestedNames(List<String> suggestedNames) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_suggestedNamesKey, suggestedNames);
  }

  // Load suggested names from local storage
  static Future<List<String>> loadSuggestedNames() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_suggestedNamesKey) ?? [];
  }

  // Add names to the suggestion queue
  static Future<void> addNamesToQueue(List<String> newNames) async {
    final currentQueue = await loadSuggestedNames();
    final updatedQueue = <String>[];

    // Add current queue names first
    updatedQueue.addAll(currentQueue);

    // Process new names
    for (final name in newNames) {
      final trimmedName = name.trim();
      if (trimmedName.isEmpty) continue;

      // Remove existing occurrence if it exists
      updatedQueue.remove(trimmedName);

      // Add to front of queue
      updatedQueue.insert(0, trimmedName);
    }

    // Limit queue size to maximum
    if (updatedQueue.length > _maxQueueSize) {
      updatedQueue.removeRange(_maxQueueSize, updatedQueue.length);
    }

    await saveSuggestedNames(updatedQueue);
  }

  // Move a name to the front of the queue (if it exists)
  static Future<void> moveNameToFront(String name) async {
    final currentQueue = await loadSuggestedNames();
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) return;

    // Remove existing occurrence
    currentQueue.remove(trimmedName);

    // Add to front
    currentQueue.insert(0, trimmedName);

    await saveSuggestedNames(currentQueue);
  }

  // Removed: saveTeams, loadTeams, saveTeamColorIndices, loadTeamColorIndices methods

  // ===== GAME SETTINGS METHODS =====

  // Save game settings
  static Future<void> saveGameSettings({
    int? roundTimeSeconds,
    int? targetScore,
    int? allowedSkips,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (roundTimeSeconds != null) {
      await prefs.setInt(_roundTimeSecondsKey, roundTimeSeconds);
    }
    if (targetScore != null) {
      await prefs.setInt(_targetScoreKey, targetScore);
    }
    if (allowedSkips != null) {
      await prefs.setInt(_allowedSkipsKey, allowedSkips);
    }
  }

  // Load game settings
  static Future<Map<String, int>> loadGameSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'roundTimeSeconds': prefs.getInt(_roundTimeSecondsKey) ?? 2,
      'targetScore': prefs.getInt(_targetScoreKey) ?? 2,
      'allowedSkips': prefs.getInt(_allowedSkipsKey) ?? 3,
    };
  }

  // ===== APP PREFERENCES METHODS =====

  // Save app preferences
  static Future<void> saveAppPreferences({
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? darkMode,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (soundEnabled != null) {
      await prefs.setBool(_soundEnabledKey, soundEnabled);
    }
    if (vibrationEnabled != null) {
      await prefs.setBool(_vibrationEnabledKey, vibrationEnabled);
    }
    if (darkMode != null) {
      await prefs.setBool(_darkModeKey, darkMode);
    }
  }

  // Load app preferences
  static Future<Map<String, bool>> loadAppPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'soundEnabled': prefs.getBool(_soundEnabledKey) ?? true,
      'vibrationEnabled': prefs.getBool(_vibrationEnabledKey) ?? true,
      'darkMode': prefs.getBool(_darkModeKey) ?? false,
    };
  }

  // ===== GAME STATISTICS METHODS =====

  // Save game history (list of completed games)
  static Future<void> saveGameHistory(
      List<Map<String, dynamic>> gameHistory) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = gameHistory.map((game) => jsonEncode(game)).toList();
    await prefs.setStringList(_gameHistoryKey, historyJson);
  }

  // Load game history
  static Future<List<Map<String, dynamic>>> loadGameHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_gameHistoryKey) ?? [];
    return historyJson
        .map((gameJson) => jsonDecode(gameJson) as Map<String, dynamic>)
        .toList();
  }

  // Save player statistics
  static Future<void> savePlayerStats(
      Map<String, Map<String, dynamic>> playerStats) async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson =
        playerStats.map((player, stats) => MapEntry(player, jsonEncode(stats)));
    final statsString = jsonEncode(statsJson);
    await prefs.setString(_playerStatsKey, statsString);
  }

  // Load player statistics
  static Future<Map<String, Map<String, dynamic>>> loadPlayerStats() async {
    final prefs = await SharedPreferences.getInstance();
    final statsString = prefs.getString(_playerStatsKey);
    if (statsString == null) return {};

    final statsJson = jsonDecode(statsString) as Map<String, dynamic>;
    return statsJson.map((player, statsJson) =>
        MapEntry(player, jsonDecode(statsJson) as Map<String, dynamic>));
  }

  // ===== UTILITY METHODS =====

  // Save any string data with a custom key
  static Future<void> saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  // Load any string data with a custom key
  static Future<String?> loadString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  // Save any boolean data with a custom key
  static Future<void> saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  // Load any boolean data with a custom key
  static Future<bool?> loadBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key);
  }

  // Save any integer data with a custom key
  static Future<void> saveInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  // Load any integer data with a custom key
  static Future<int?> loadInt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key);
  }

  // Save any double data with a custom key
  static Future<void> saveDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
  }

  // Load any double data with a custom key
  static Future<double?> loadDouble(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(key);
  }

  // Save any list of strings with a custom key
  static Future<void> saveStringList(String key, List<String> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, value);
  }

  // Load any list of strings with a custom key
  static Future<List<String>> loadStringList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key) ?? [];
  }

  // Save any JSON-serializable object
  static Future<void> saveObject(
      String key, Map<String, dynamic> object) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(object));
  }

  // Load any JSON-serializable object
  static Future<Map<String, dynamic>?> loadObject(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);
    if (jsonString == null) return null;
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  // Remove a specific key
  static Future<void> removeKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  // Clear all stored data
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Clear only game data (keep preferences)
  static Future<void> clearGameData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_playerNamesKey);
    // Removed: _teamsKey and _teamColorIndicesKey removal
    await prefs.remove(_gameHistoryKey);
    await prefs.remove(_playerStatsKey);
    await prefs.remove(_teamStatsKey);

    // Reset suggested names to default list
    final defaultNames = [
      'Aline',
      'Nazime',
      'Arash',
      'Cameron',
      'Jhud',
      'Huzaifah',
      'Mayy',
      'Siawosh',
      'Nadine',
      'Luqmaan',
      'Arun',
      'Malaika'
    ];
    await saveSuggestedNames(defaultNames);
  }

  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_deviceIdKey);
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString(_deviceIdKey, id);
    }
    return id;
  }
}
