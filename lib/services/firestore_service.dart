import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for handling all Firestore database operations
/// Manages sessions, teams, game state, and host transfers for online multiplayer
class FirestoreService {
  static final _sessions = FirebaseFirestore.instance.collection('sessions');

  // Rate limiting
  static final Map<String, List<DateTime>> _writeTimestamps = {};
  static final Map<String, List<DateTime>> _readTimestamps = {};
  static const int _maxWritesPerMinute = 30;
  static const int _maxReadsPerMinute = 100;
  static const Duration _rateLimitWindow = Duration(minutes: 1);

  // ============================================================================
  // RATE LIMITING HELPERS
  // ============================================================================

  /// Check if we can perform a write operation
  static bool _canWrite(String sessionId) {
    final now = DateTime.now();
    final timestamps = _writeTimestamps[sessionId] ?? [];

    // Remove timestamps older than 1 minute
    final recentTimestamps = timestamps
        .where((timestamp) => now.difference(timestamp) < _rateLimitWindow)
        .toList();

    _writeTimestamps[sessionId] = recentTimestamps;

    if (recentTimestamps.length >= _maxWritesPerMinute) {
      print('⚠️ RATE LIMIT: Too many writes for session $sessionId');
      return false;
    }

    // Add current timestamp
    recentTimestamps.add(now);
    _writeTimestamps[sessionId] = recentTimestamps;
    return true;
  }

  /// Check if we can perform a read operation
  static bool _canRead(String sessionId) {
    final now = DateTime.now();
    final timestamps = _readTimestamps[sessionId] ?? [];

    // Remove timestamps older than 1 minute
    final recentTimestamps = timestamps
        .where((timestamp) => now.difference(timestamp) < _rateLimitWindow)
        .toList();

    _readTimestamps[sessionId] = recentTimestamps;

    if (recentTimestamps.length >= _maxReadsPerMinute) {
      print('⚠️ RATE LIMIT: Too many reads for session $sessionId');
      return false;
    }

    // Add current timestamp
    recentTimestamps.add(now);
    _readTimestamps[sessionId] = recentTimestamps;
    return true;
  }

  // ============================================================================
  // SESSION MANAGEMENT
  // ============================================================================

  /// Create a new session document with a gameState object
  static Future<void> createSession(String sessionId,
      Map<String, dynamic> sessionData, Map<String, dynamic>? gameState) async {
    if (!_canWrite(sessionId)) {
      throw Exception('Rate limit exceeded for writes');
    }

    print('🔥 FIRESTORE WRITE: createSession($sessionId)');
    await _sessions.doc(sessionId).set({
      ...sessionData,
      'gameState': gameState,
    });
  }

  /// Listen to session changes in real-time
  /// Uses caching to reduce Firestore reads
  static Stream<DocumentSnapshot<Map<String, dynamic>>> sessionStream(
      String sessionId) {
    if (!_canRead(sessionId)) {
      // Return empty stream if rate limited
      return Stream.empty();
    }

    print('🔥 FIRESTORE READ: sessionStream($sessionId)');
    return _sessions.doc(sessionId).snapshots(
          includeMetadataChanges: false, // Only listen to actual data changes
        );
  }

  // ============================================================================
  // GAME STATE OPERATIONS
  // ============================================================================

  /// Update the gameState object for a session
  static Future<void> setGameState(
      String sessionId, Map<String, dynamic> gameState) async {
    if (!_canWrite(sessionId)) {
      throw Exception('Rate limit exceeded for writes');
    }

    print('🔥 FIRESTORE WRITE: setGameState($sessionId)');
    await _sessions.doc(sessionId).update({'gameState': gameState});
  }

  /// Get the gameState object for a session (one-time fetch)
  static Future<Map<String, dynamic>?> getGameState(String sessionId) async {
    if (!_canRead(sessionId)) {
      throw Exception('Rate limit exceeded for reads');
    }

    print('🔥 FIRESTORE READ: getGameState($sessionId)');
    final doc = await _sessions.doc(sessionId).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    return data['gameState'] as Map<String, dynamic>?;
  }

  /// Start the game by updating gameState in Firestore
  /// This triggers the navigation listener for all players in the session
  static Future<void> startGame(String sessionId) async {
    if (!_canWrite(sessionId)) {
      throw Exception('Rate limit exceeded for writes');
    }

    print('🔥 FIRESTORE WRITE: startGame($sessionId)');
    await _sessions.doc(sessionId).update({
      'gameState.status': 'start_game',
      'gameState.currentTeamIndex': 0,
      'gameState.roundNumber': 1,
      'gameState.turnNumber': 1,
      // Add other initial fields as needed
    });
  }

  /// Advance to the next team's turn
  static Future<void> advanceToNextTeam(String sessionId) async {
    if (!_canRead(sessionId) || !_canWrite(sessionId)) {
      throw Exception('Rate limit exceeded');
    }

    print(
        '🔥 FIRESTORE READ: advanceToNextTeam($sessionId) - getting current state');
    final doc = await _sessions.doc(sessionId).get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    final gameState = data['gameState'] as Map<String, dynamic>?;
    final teams = (data['teams'] as List?) ?? [];

    if (gameState == null || teams.isEmpty) return;

    final currentTeamIndex = gameState['currentTeamIndex'] as int? ?? 0;
    final currentRound = gameState['roundNumber'] as int? ?? 1;

    // Calculate next team index
    final nextTeamIndex = (currentTeamIndex + 1) % teams.length;

    // If we've gone through all teams, advance to next round
    final nextRound = nextTeamIndex == 0 ? currentRound + 1 : currentRound;

    // Check if this is the last team in the round
    final isLastTeamInRound = nextTeamIndex == 0;

    print(
        '🔥 FIRESTORE WRITE: advanceToNextTeam($sessionId) - updating to next team');
    await _sessions.doc(sessionId).update({
      'gameState.currentTeamIndex': nextTeamIndex,
      'gameState.roundNumber': nextRound,
      'gameState.turnNumber': 1, // Each team has 1 turn per round
      'gameState.status':
          isLastTeamInRound ? 'round_end' : 'category_selection',
    });
  }

  /// Update the category spin state for synchronized animation across all players
  static Future<void> updateCategorySpinState(
    String sessionId, {
    bool? isSpinning,
    int? spinCount,
    String? currentCategory,
    String? selectedCategory,
  }) async {
    if (!_canWrite(sessionId)) {
      throw Exception('Rate limit exceeded for writes');
    }

    final updates = <String, dynamic>{};

    if (isSpinning != null) {
      updates['gameState.categorySpin.isSpinning'] = isSpinning;
    }
    if (spinCount != null) {
      updates['gameState.categorySpin.spinCount'] = spinCount;
    }
    if (currentCategory != null) {
      updates['gameState.categorySpin.currentCategory'] = currentCategory;
    }
    if (selectedCategory != null) {
      updates['gameState.categorySpin.selectedCategory'] = selectedCategory;
    }

    print('🔥 FIRESTORE WRITE: updateCategorySpinState($sessionId) - $updates');
    await _sessions.doc(sessionId).update(updates);
  }

  /// Update game state for role assignment with selected category
  static Future<void> fromCategorySelection(
    String sessionId, {
    required String selectedCategory,
  }) async {
    if (!_canWrite(sessionId)) {
      throw Exception('Rate limit exceeded for writes');
    }

    print(
        '🔥 FIRESTORE WRITE: fromCategorySelection($sessionId) - selectedCategory: $selectedCategory');
    await _sessions.doc(sessionId).update({
      'gameState.status': 'role_assignment',
      'gameState.selectedCategory': selectedCategory,
      'gameState.categorySpin.isSpinning': false,
      'gameState.categorySpin.selectedCategory': selectedCategory,
    });
  }

  /// Update role assignment state for synchronized viewing across all players
  static Future<void> updateRoleAssignment(
    String sessionId, {
    String? guesser,
    String? conveyor,
    bool? isTransitioning,
  }) async {
    if (!_canWrite(sessionId)) {
      throw Exception('Rate limit exceeded for writes');
    }

    final updates = <String, dynamic>{};

    if (guesser != null) {
      updates['gameState.roleAssignment.guesser'] = guesser;
    }
    if (conveyor != null) {
      updates['gameState.roleAssignment.conveyor'] = conveyor;
    }
    if (isTransitioning != null) {
      updates['gameState.roleAssignment.isTransitioning'] = isTransitioning;
    }

    print('🔥 FIRESTORE WRITE: updateRoleAssignment($sessionId) - $updates');
    await _sessions.doc(sessionId).update(updates);
  }

  /// Transition from role assignment to game screen
  static Future<void> fromRoleAssignment(
    String sessionId, {
    required String guesser,
    required String conveyor,
  }) async {
    if (!_canWrite(sessionId)) {
      throw Exception('Rate limit exceeded for writes');
    }

    print(
        '🔥 FIRESTORE WRITE: fromRoleAssignment($sessionId) - guesser: $guesser, conveyor: $conveyor');
    await _sessions.doc(sessionId).update({
      'gameState.status': 'game',
      'gameState.currentGuesser': guesser,
      'gameState.currentConveyor': conveyor,
      'gameState.roleAssignment.isTransitioning': false,
    });
  }

  /// Update disputed words in turn over state
  static Future<void> updateDisputedWords(
    String sessionId,
    List<String> disputedWords,
  ) async {
    if (!_canWrite(sessionId)) {
      throw Exception('Rate limit exceeded for writes');
    }

    print(
        '🔥 FIRESTORE WRITE: updateDisputedWords($sessionId) - disputedWords: $disputedWords');
    await _sessions.doc(sessionId).update({
      'gameState.turnOverState.disputedWords': disputedWords,
    });
  }

  /// Confirm score for a team in turn over state
  static Future<void> confirmScoreForTeam(
    String sessionId,
    int teamIndex,
  ) async {
    if (!_canWrite(sessionId)) {
      throw Exception('Rate limit exceeded for writes');
    }

    print(
        '🔥 FIRESTORE WRITE: confirmScoreForTeam($sessionId) - teamIndex: $teamIndex');
    await _sessions.doc(sessionId).update({
      'gameState.turnOverState.confirmedTeams':
          FieldValue.arrayUnion([teamIndex]),
    });
  }

  /// Add current turn record to turn history and transition to turn over screen
  static Future<void> fromGameScreen(
      String sessionId,
      int teamIndex,
      int roundNumber,
      int turnNumber,
      String category,
      int correctCount,
      int skipsLeft,
      List<String> wordsGuessed,
      List<String> wordsSkipped,
      Set<String> disputedWords,
      String conveyor,
      String guesser) async {
    if (!_canWrite(sessionId)) {
      throw Exception('Rate limit exceeded for writes');
    }

    // Create the turn record
    print('fromGameScreen');
    final turnRecord = {
      'teamIndex': teamIndex,
      'roundNumber': roundNumber,
      'turnNumber': turnNumber,
      'category': category,
      'correctCount': correctCount,
      'skipsLeft': skipsLeft,
      'wordsGuessed': wordsGuessed,
      'wordsSkipped': wordsSkipped,
      'disputedWords':
          disputedWords.toList(), // Convert Set to List for Firestore
      'conveyor': conveyor,
      'guesser': guesser,
    };

    await _sessions.doc(sessionId).update({
      'gameState.status': 'turn_over',
      'gameState.currentTurnRecord':
          turnRecord, // Store current turn for easy access
      'gameState.turnOverState': {
        'disputedWords': disputedWords.toList(),
        'confirmedTeams': [],
        'currentTeamIndex': teamIndex,
      },
    });
  }

  static Future<void> fromTurnOver(
    String sessionId,
    int teamIndex,
    int roundNumber,
    int turnNumber,
    String category,
    int correctCount,
    int skipsLeft,
    List<String> wordsGuessed,
    List<String> wordsSkipped,
    Set<String> disputedWords,
    String conveyor,
    String guesser,
  ) async {
    if (!_canWrite(sessionId)) {
      throw Exception('Rate limit exceeded for writes');
    }

    //create the final turn record
    final turnRecord = {
      'teamIndex': teamIndex,
      'roundNumber': roundNumber,
      'turnNumber': turnNumber,
      'category': category,
      'correctCount': correctCount,
      'skipsLeft': skipsLeft,
      'wordsGuessed': wordsGuessed,
      'wordsSkipped': wordsSkipped,
      'disputedWords': disputedWords.toList(),
      'conveyor': conveyor,
      'guesser': guesser,
    };

    await _sessions.doc(sessionId).update({
      //put the final turn record into the turn history field in the gameState
      'gameState.turnHistory': FieldValue.arrayUnion([turnRecord]),
      'gameState.currentTurnRecord': turnRecord,
      'gameState.turnOverState': {
        'disputedWords': disputedWords.toList(),
        'confirmedTeams': [],
        'currentTeamIndex': teamIndex,
      },
    });
    //advance to next team
    await advanceToNextTeam(sessionId);
  }

  // ============================================================================
  // TEAM MANAGEMENT
  // ============================================================================

  /// Join a session by adding a team to the teams array
  static Future<void> joinSession(
      String sessionId, Map<String, dynamic> teamData) async {
    if (!_canWrite(sessionId)) {
      throw Exception('Rate limit exceeded for writes');
    }

    await _sessions.doc(sessionId).update({
      'teams': FieldValue.arrayUnion([teamData])
    });
  }

  /// Update a team's info (name, color, ready) in the teams array by teamId
  static Future<void> updateTeam(String sessionId, String teamId,
      Map<String, dynamic> updatedFields) async {
    if (!_canRead(sessionId) || !_canWrite(sessionId)) {
      throw Exception('Rate limit exceeded');
    }

    final doc = await _sessions.doc(sessionId).get();
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;
    final teams = (data['teams'] as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final idx = teams.indexWhere((t) => t['teamId'] == teamId);
    if (idx == -1) return;
    teams[idx].addAll(updatedFields);
    await _sessions.doc(sessionId).update({'teams': teams});
  }

  /// Mark a team as inactive (team leaves the game)
  static Future<void> leaveTeam(String sessionId, String teamId) async {
    if (!_canRead(sessionId) || !_canWrite(sessionId)) {
      throw Exception('Rate limit exceeded');
    }

    final doc = await _sessions.doc(sessionId).get();
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;
    final teams = (data['teams'] as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final idx = teams.indexWhere((t) => t['teamId'] == teamId);
    if (idx == -1) return;
    teams[idx]['active'] = false;
    await _sessions.doc(sessionId).update({'teams': teams});
  }

  /// Mark a team as active (team rejoins the game)
  /// Optionally update the players list
  static Future<void> rejoinTeam(
      String sessionId, String teamId, List<String> players) async {
    if (!_canRead(sessionId) || !_canWrite(sessionId)) {
      throw Exception('Rate limit exceeded');
    }

    final doc = await _sessions.doc(sessionId).get();
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;
    final teams = (data['teams'] as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final idx = teams.indexWhere((t) => t['teamId'] == teamId);
    if (idx == -1) return;
    teams[idx]['active'] = true;
    teams[idx]['players'] = players;
    await _sessions.doc(sessionId).update({'teams': teams});
  }

  // ============================================================================
  // HOST MANAGEMENT
  // ============================================================================

  /// Transfer host status to another active team if the current host leaves
  static Future<void> transferHostIfNeeded(
      String sessionId, String leavingDeviceId) async {
    if (!_canRead(sessionId) || !_canWrite(sessionId)) {
      throw Exception('Rate limit exceeded');
    }

    final doc = await _sessions.doc(sessionId).get();
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;
    final currentHostId = data['hostId'] as String?;
    if (currentHostId != leavingDeviceId)
      return; // Only transfer if the host is leaving

    final teams = (data['teams'] as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    // Find the first active team with a deviceId different from the leaving host
    final newHostTeam = teams.firstWhere(
      (t) => t['active'] == true && t['deviceId'] != leavingDeviceId,
      orElse: () => <String, dynamic>{},
    );
    if (newHostTeam.isNotEmpty && newHostTeam['deviceId'] != null) {
      await _sessions
          .doc(sessionId)
          .update({'hostId': newHostTeam['deviceId']});
    }
  }
}
