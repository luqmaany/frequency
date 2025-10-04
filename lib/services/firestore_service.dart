import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for handling all Firestore database operations
/// Manages sessions, teams, game state, and host transfers for online multiplayer
class FirestoreService {
  static final sessions = FirebaseFirestore.instance.collection('sessions');

  // Rate limiting
  static final Map<String, List<DateTime>> _writeTimestamps = {};
  static final Map<String, List<DateTime>> _readTimestamps = {};
  static const int _maxWritesPerMinute = 100;
  static const int _maxReadsPerMinute = 70;
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
    await sessions.doc(sessionId).set({
      ...sessionData,
      'gameState': gameState,
    });
  }

  // Cache for session streams to avoid multiple listeners to the same document
  static final Map<String, Stream<DocumentSnapshot<Map<String, dynamic>>>>
      _sessionStreamCache = {};

  /// Listen to session changes in real-time
  /// Uses caching to reduce Firestore reads
  static Stream<DocumentSnapshot<Map<String, dynamic>>> sessionStream(
      String sessionId) {
    if (!_canRead(sessionId)) {
      // Return empty stream if rate limited
      return const Stream.empty();
    }

    // Return cached stream if it exists
    if (_sessionStreamCache.containsKey(sessionId)) {
      return _sessionStreamCache[sessionId]!;
    }

    print('🔥 FIRESTORE READ: sessionStream($sessionId) - creating new stream');
    final stream = sessions.doc(sessionId).snapshots(
          includeMetadataChanges: false, // Only listen to actual data changes
        );

    // Cache the stream
    _sessionStreamCache[sessionId] = stream;

    return stream;
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
    await sessions.doc(sessionId).update({'gameState': gameState});
  }

  /// Get the gameState object for a session (one-time fetch)
  static Future<Map<String, dynamic>?> getGameState(String sessionId) async {
    if (!_canRead(sessionId)) {
      throw Exception('Rate limit exceeded for reads');
    }

    print('🔥 FIRESTORE READ: getGameState($sessionId)');
    final doc = await sessions.doc(sessionId).get();
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
    await sessions.doc(sessionId).update({
      'gameState.status': 'category_selection',
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
    final doc = await sessions.doc(sessionId).get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    final gameState = data['gameState'] as Map<String, dynamic>?;
    final teams = (data['teams'] as List?) ?? [];

    if (gameState == null || teams.isEmpty) return;

    final currentTeamIndex = gameState['currentTeamIndex'] as int? ?? 0;
    final currentRound = gameState['roundNumber'] as int? ?? 1;

    // Tiebreaker state (if any)
    final Map<String, dynamic> tiebreakerState =
        (gameState['tiebreaker'] as Map<String, dynamic>?) ?? {};
    final bool isTiebreakerActive = tiebreakerState['active'] == true;
    final List<dynamic> eligibleRaw =
        (tiebreakerState['eligibleTeamIndices'] as List?) ?? const [];
    final List<int> eligibleTeamIndices =
        eligibleRaw.map((e) => (e as num).toInt()).toList();

    int nextTeamIndex;
    bool isLastTeamInRound;
    if (isTiebreakerActive && eligibleTeamIndices.isNotEmpty) {
      // Advance only among eligible teams
      final int currentPos = eligibleTeamIndices.indexOf(currentTeamIndex);
      final int nextPos =
          currentPos == -1 ? 0 : (currentPos + 1) % eligibleTeamIndices.length;
      nextTeamIndex = eligibleTeamIndices[nextPos];
      isLastTeamInRound =
          currentPos != -1 && currentPos == eligibleTeamIndices.length - 1;
    } else {
      // Normal round rotation across all teams
      nextTeamIndex = (currentTeamIndex + 1) % teams.length;
      isLastTeamInRound = nextTeamIndex == 0;
    }

    // If we've gone through all relevant teams, advance to next round
    final nextRound = isLastTeamInRound ? currentRound + 1 : currentRound;

    // Determine round transition outcome (game over, tiebreaker, or next round)
    bool isGameOver = false;
    bool shouldStartOrContinueTiebreaker = false;
    List<int> newEligible = eligibleTeamIndices;
    if (isLastTeamInRound) {
      final settings = (data['settings'] as Map<String, dynamic>?) ?? {};
      final int targetScore = (settings['targetScore'] as int?) ?? 20;
      final List<dynamic> rawHistory =
          (gameState['turnHistory'] as List?) ?? const [];
      final List<Map<String, dynamic>> turnHistory =
          rawHistory.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      // Sum scores by team
      final Map<int, int> teamTotals = {};
      for (final tr in turnHistory) {
        final int tIdx = (tr['teamIndex'] as int?) ?? 0;
        final int score = (tr['correctCount'] as int?) ?? 0;
        teamTotals[tIdx] = (teamTotals[tIdx] ?? 0) + score;
      }

      if (isTiebreakerActive) {
        // Evaluate winners only among eligible teams
        final scores = eligibleTeamIndices
            .map((idx) => MapEntry(idx, teamTotals[idx] ?? 0))
            .toList();
        if (scores.isNotEmpty) {
          final int top =
              scores.map((e) => e.value).fold<int>(0, (a, b) => a > b ? a : b);
          final List<int> leaders =
              scores.where((e) => e.value == top).map((e) => e.key).toList();
          if (leaders.length == 1) {
            isGameOver = true; // Unique leader wins
            newEligible = leaders;
          } else {
            // Continue tiebreaker with only tied leaders
            shouldStartOrContinueTiebreaker = true;
            newEligible = leaders;
          }
        } else {
          // Fallback: no scores? end game to avoid loop
          isGameOver = true;
        }
      } else {
        // Normal round end: check if multiple teams reached or exceeded target
        final List<int> overTargetTeams = teamTotals.entries
            .where((e) => e.value >= targetScore)
            .map((e) => e.key)
            .toList();
        if (overTargetTeams.length >= 2) {
          // Start tiebreaker
          shouldStartOrContinueTiebreaker = true;
          newEligible = overTargetTeams;
        } else {
          // Single team can win immediately
          isGameOver = overTargetTeams.length == 1;
        }
      }
    }

    print(
        '🔥 FIRESTORE WRITE: advanceToNextTeam($sessionId) - updating to next team');
    final Map<String, dynamic> updates = {
      'gameState.currentTeamIndex': nextTeamIndex,
      'gameState.roundNumber': nextRound,
      'gameState.turnNumber': 1, // Each team has 1 turn per round
      'gameState.status': isLastTeamInRound
          ? (isGameOver ? 'game_over' : 'round_end')
          : 'category_selection',
    };

    // Manage tiebreaker state transitions
    if (isLastTeamInRound) {
      if (isGameOver) {
        updates['gameState.tiebreaker'] = {
          'active': false,
          'eligibleTeamIndices': newEligible,
        };
      } else if (shouldStartOrContinueTiebreaker) {
        // Ensure next team index starts with first eligible in next cycle
        final int startIdx = newEligible.isNotEmpty ? newEligible.first : 0;
        updates['gameState.currentTeamIndex'] = startIdx;
        updates['gameState.tiebreaker'] = {
          'active': true,
          'eligibleTeamIndices': newEligible,
        };
      } else if (isTiebreakerActive) {
        // Keep tiebreaker inactive if resolved during mid-round (unlikely)
        updates['gameState.tiebreaker'] = {
          'active': false,
          'eligibleTeamIndices': [],
        };
      }
    }

    await sessions.doc(sessionId).update(updates);
  }

  /// Update the selected category for synchronized display across all players
  static Future<void> updateCategorySpinState(
    String sessionId, {
    required String selectedCategory,
  }) async {
    if (!_canWrite(sessionId)) {
      throw Exception('Rate limit exceeded for writes');
    }

    print(
        '🔥 FIRESTORE WRITE: updateCategorySpinState($sessionId) - selectedCategory: $selectedCategory');
    await sessions.doc(sessionId).update({
      'gameState.selectedCategory': selectedCategory,
    });
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
    await sessions.doc(sessionId).update({
      'gameState.status': 'role_assignment',
      'gameState.selectedCategory': selectedCategory,
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
    await sessions.doc(sessionId).update(updates);
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
    await sessions.doc(sessionId).update({
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
    await sessions.doc(sessionId).update({
      'gameState.turnOverState.disputedWords': disputedWords,
    });
  }

  /// Update promoted words in turn over state
  static Future<void> updatePromotedWords(
    String sessionId,
    List<String> promotedWords,
  ) async {
    if (!_canWrite(sessionId)) {
      throw Exception('Rate limit exceeded for writes');
    }

    print(
        '🔥 FIRESTORE WRITE: updatePromotedWords($sessionId) - promotedWords: $promotedWords');
    await sessions.doc(sessionId).update({
      'gameState.turnOverState.promotedWords': promotedWords,
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
    await sessions.doc(sessionId).update({
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
      List<String> wordsLeftOnScreen,
      Set<String> disputedWords,
      String conveyor,
      String guesser,
      {Map<String, double>? wordTimings}) async {
    if (!_canWrite(sessionId)) {
      throw Exception('Rate limit exceeded for writes');
    }

    // Create the turn record
    print(
        '🔥 FIRESTORE WRITE: fromGameScreen($sessionId) - teamIndex: $teamIndex, roundNumber: $roundNumber');
    final turnRecord = {
      'teamIndex': teamIndex,
      'roundNumber': roundNumber,
      'turnNumber': turnNumber,
      'category': category,
      'correctCount': correctCount,
      'skipsLeft': skipsLeft,
      'wordsGuessed': wordsGuessed,
      'wordsSkipped': wordsSkipped,
      'wordsLeftOnScreen': wordsLeftOnScreen,
      'disputedWords':
          disputedWords.toList(), // Convert Set to List for Firestore
      'conveyor': conveyor,
      'guesser': guesser,
      'wordTimings': wordTimings ?? {}, // Store word timings or empty map
    };

    await sessions.doc(sessionId).update({
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
    String guesser, {
    Map<String, double>? wordTimings,
  }) async {
    if (!_canWrite(sessionId)) {
      throw Exception('Rate limit exceeded for writes');
    }

    //create the final turn record
    print(
        '🔥 FIRESTORE WRITE: fromTurnOver($sessionId) - teamIndex: $teamIndex, roundNumber: $roundNumber');
    final turnRecord = {
      'teamIndex': teamIndex,
      'roundNumber': roundNumber,
      'turnNumber': turnNumber,
      'category': category,
      'correctCount': correctCount,
      'skipsLeft': skipsLeft,
      'wordsGuessed': wordsGuessed,
      'wordsSkipped': wordsSkipped,
      'wordsLeftOnScreen': [],
      'disputedWords': disputedWords.toList(),
      'conveyor': conveyor,
      'guesser': guesser,
      'wordTimings': wordTimings ?? {}, // Store word timings or empty map
    };

    await sessions.doc(sessionId).update({
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

  /// Proceed from round end (scoreboard) to the next round's category selection
  static Future<void> fromRoundEnd(String sessionId) async {
    if (!_canWrite(sessionId)) {
      throw Exception('Rate limit exceeded for writes');
    }

    print('🔥 FIRESTORE WRITE: fromRoundEnd($sessionId)');
    await sessions.doc(sessionId).update({
      'gameState.status': 'category_selection',
    });
  }

  // ============================================================================
  // SURVEY DATA
  // ============================================================================

  /// Write survey data to Firestore
  static Future<void> writeSurveyData(Map<String, dynamic> surveyData) async {
    try {
      await FirebaseFirestore.instance
          .collection('insight_surveys')
          .add(surveyData);
      print('✅ Survey data written to Firestore');
    } catch (e) {
      print('❌ Failed to write survey data: $e');
      rethrow;
    }
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

    print(
        '🔥 FIRESTORE WRITE: joinSession($sessionId) - teamData: ${teamData['teamId']}');
    await sessions.doc(sessionId).update({
      'teams': FieldValue.arrayUnion([teamData])
    });
  }

  /// Update a team's info (name, color, ready) in the teams array by teamId
  static Future<void> updateTeam(String sessionId, String teamId,
      Map<String, dynamic> updatedFields) async {
    if (!_canRead(sessionId) || !_canWrite(sessionId)) {
      throw Exception('Rate limit exceeded');
    }

    print('🔥 FIRESTORE READ: updateTeam($sessionId) - getting current teams');
    final doc = await sessions.doc(sessionId).get();
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;
    final teams = (data['teams'] as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final idx = teams.indexWhere((t) => t['teamId'] == teamId);
    if (idx == -1) return;
    teams[idx].addAll(updatedFields);

    print(
        '🔥 FIRESTORE WRITE: updateTeam($sessionId) - teamId: $teamId, updatedFields: $updatedFields');
    await sessions.doc(sessionId).update({'teams': teams});
  }

  /// Mark a team as inactive (team leaves the game)
  static Future<void> leaveTeam(String sessionId, String teamId) async {
    if (!_canRead(sessionId) || !_canWrite(sessionId)) {
      throw Exception('Rate limit exceeded');
    }

    print('🔥 FIRESTORE READ: leaveTeam($sessionId) - getting current teams');
    final doc = await sessions.doc(sessionId).get();
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;
    final teams = (data['teams'] as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final idx = teams.indexWhere((t) => t['teamId'] == teamId);
    if (idx == -1) return;
    teams[idx]['active'] = false;

    print('🔥 FIRESTORE WRITE: leaveTeam($sessionId) - teamId: $teamId');
    await sessions.doc(sessionId).update({'teams': teams});
  }

  /// Mark a team as active (team rejoins the game)
  /// Optionally update the players list
  static Future<void> rejoinTeam(
      String sessionId, String teamId, List<String> players) async {
    if (!_canRead(sessionId) || !_canWrite(sessionId)) {
      throw Exception('Rate limit exceeded');
    }

    print('🔥 FIRESTORE READ: rejoinTeam($sessionId) - getting current teams');
    final doc = await sessions.doc(sessionId).get();
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;
    final teams = (data['teams'] as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final idx = teams.indexWhere((t) => t['teamId'] == teamId);
    if (idx == -1) return;
    teams[idx]['active'] = true;
    teams[idx]['players'] = players;

    print(
        '🔥 FIRESTORE WRITE: rejoinTeam($sessionId) - teamId: $teamId, players: $players');
    await sessions.doc(sessionId).update({'teams': teams});
  }

  /// Upsert a team by deviceId atomically to avoid clobbering other teams
  /// Supports both 'couch' mode (single device, 2 players) and 'remote' mode (2 devices, 1 player each)
  static Future<void> upsertTeamByDeviceId(
      String sessionId, Map<String, dynamic> teamData) async {
    if (!_canWrite(sessionId)) {
      throw Exception('Rate limit exceeded for writes');
    }

    final deviceId = teamData['deviceId'];
    if (deviceId == null) {
      throw Exception('teamData.deviceId is required');
    }

    final teamMode = teamData['teamMode'] as String? ??
        'couch'; // Default to couch mode for backward compatibility

    print(
        '🔥 FIRESTORE TX: upsertTeamByDeviceId($sessionId) - deviceId: $deviceId, mode: $teamMode');
    await sessions.firestore.runTransaction((txn) async {
      final docRef = sessions.doc(sessionId);
      final snapshot = await txn.get(docRef);
      if (!snapshot.exists) {
        throw Exception('Session not found');
      }
      final data = snapshot.data() as Map<String, dynamic>;
      final List<Map<String, dynamic>> teams = (data['teams'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [];

      final int? desiredColor = teamData['colorIndex'] as int?;

      if (teamMode == 'couch') {
        // Couch mode: enforce unique color per device (existing logic)
        if (desiredColor != null) {
          final conflict = teams.any((t) =>
              t['colorIndex'] == desiredColor && t['deviceId'] != deviceId);
          if (conflict) {
            throw Exception('Color already taken');
          }
        }

        // Remove previous entry for this device and add the new one
        teams.removeWhere((t) => t['deviceId'] == deviceId);
        teams.add(teamData);
      } else if (teamMode == 'remote') {
        // Remote mode: handle joining an existing team or creating a new remote team
        await _handleRemoteTeamUpsert(teams, teamData, desiredColor, deviceId);
      }

      txn.update(docRef, {'teams': teams});
    });
  }

  /// Helper method to handle remote team upsert logic
  static Future<void> _handleRemoteTeamUpsert(
    List<Map<String, dynamic>> teams,
    Map<String, dynamic> teamData,
    int? desiredColor,
    String deviceId,
  ) async {
    print(
        '🔍 _handleRemoteTeamUpsert: desiredColor=$desiredColor, deviceId=$deviceId');
    if (desiredColor == null) {
      throw Exception('colorIndex is required for remote teams');
    }

    // Check if there's already a remote team with this color
    final existingTeam = teams.firstWhere(
      (t) => t['colorIndex'] == desiredColor && t['teamMode'] == 'remote',
      orElse: () => <String, dynamic>{},
    );

    print(
        '🔍 existingTeam search result: ${existingTeam.isNotEmpty ? "found existing team" : "no existing team"}');
    if (existingTeam.isNotEmpty) {
      print('🔍 joining existing remote team');
      // Joining an existing remote team
      final devices =
          List<Map<String, dynamic>>.from(existingTeam['devices'] ?? []);

      // Check if this device is already in the team
      final existingDeviceIndex =
          devices.indexWhere((d) => d['deviceId'] == deviceId);

      if (existingDeviceIndex != -1) {
        // Update existing device data
        devices[existingDeviceIndex] = {
          'deviceId': deviceId,
          'playerName': teamData['playerName'],
          'isReady': teamData['ready'] ?? false,
        };
      } else {
        // Add new device to the team
        if (devices.length >= 2) {
          throw Exception('Remote team already has 2 players');
        }

        devices.add({
          'deviceId': deviceId,
          'playerName': teamData['playerName'],
          'isReady': teamData['ready'] ?? false,
        });
      }

      // Update the existing team
      final teamIndex = teams.indexWhere(
          (t) => t['colorIndex'] == desiredColor && t['teamMode'] == 'remote');
      teams[teamIndex]['devices'] = devices;
      teams[teamIndex]['players'] =
          devices.map((d) => d['playerName']).toList();
      teams[teamIndex]['ready'] =
          devices.every((d) => d['isReady'] == true) && devices.length == 2;
    } else {
      print('🔍 creating new remote team');
      // Creating a new remote team
      // Check if any couch team already uses this color
      final couchTeamConflict = teams.any(
          (t) => t['colorIndex'] == desiredColor && t['teamMode'] != 'remote');
      print('🔍 couchTeamConflict check: $couchTeamConflict');
      if (couchTeamConflict) {
        throw Exception('Color already taken');
      }

      // Remove any previous team entries for this device
      teams.removeWhere((t) =>
          (t['deviceId'] == deviceId) ||
          (t['devices'] != null &&
              (t['devices'] as List).any((d) => d['deviceId'] == deviceId)));

      // Create new remote team
      teams.add({
        'teamName': teamData['teamName'],
        'colorIndex': desiredColor,
        'teamMode': 'remote',
        'devices': [
          {
            'deviceId': deviceId,
            'playerName': teamData['playerName'],
            'isReady': teamData['ready'] ?? false,
          }
        ],
        'players': [teamData['playerName']],
        'ready': false, // Not ready until both players join
      });
    }
  }

  /// Remove a team by deviceId atomically
  /// Handles both 'couch' mode (removes entire team) and 'remote' mode (removes device from team or entire team if last device)
  static Future<void> removeTeamByDeviceId(
      String sessionId, String deviceId) async {
    if (!_canWrite(sessionId)) {
      throw Exception('Rate limit exceeded for writes');
    }

    print(
        '🔥 FIRESTORE TX: removeTeamByDeviceId($sessionId) - deviceId: $deviceId');
    await sessions.firestore.runTransaction((txn) async {
      final docRef = sessions.doc(sessionId);
      final snapshot = await txn.get(docRef);
      if (!snapshot.exists) {
        return;
      }
      final data = snapshot.data() as Map<String, dynamic>;
      final List<Map<String, dynamic>> teams = (data['teams'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [];

      // Handle couch mode teams (existing logic)
      teams.removeWhere((t) => t['deviceId'] == deviceId);

      // Handle remote mode teams
      for (int i = teams.length - 1; i >= 0; i--) {
        final team = teams[i];
        if (team['teamMode'] == 'remote' && team['devices'] != null) {
          final devices = List<Map<String, dynamic>>.from(team['devices']);
          final deviceIndex =
              devices.indexWhere((d) => d['deviceId'] == deviceId);

          if (deviceIndex != -1) {
            devices.removeAt(deviceIndex);

            if (devices.isEmpty) {
              // Remove entire team if no devices left
              teams.removeAt(i);
            } else {
              // Update team with remaining devices
              teams[i]['devices'] = devices;
              teams[i]['players'] =
                  devices.map((d) => d['playerName']).toList();
              teams[i]['ready'] =
                  false; // Team is no longer ready when a player leaves
            }
            break; // Device found and handled, no need to check other teams
          }
        }
      }
      txn.update(docRef, {'teams': teams});
    });
  }

  /// Get available remote team slots (colors that have remote teams with only 1 player)
  static Future<List<Map<String, dynamic>>> getAvailableRemoteTeamSlots(
      String sessionId) async {
    if (!_canRead(sessionId)) {
      throw Exception('Rate limit exceeded for reads');
    }

    print('🔥 FIRESTORE READ: getAvailableRemoteTeamSlots($sessionId)');
    final doc = await sessions.doc(sessionId).get();
    if (!doc.exists) return [];

    final data = doc.data() as Map<String, dynamic>;
    final teams = (data['teams'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        [];

    // Find remote teams that have only 1 player
    return teams.where((team) {
      return team['teamMode'] == 'remote' &&
          team['devices'] != null &&
          (team['devices'] as List).length == 1;
    }).toList();
  }

  /// Check if a device can join a specific remote team color
  static Future<bool> canJoinRemoteTeam(
      String sessionId, int colorIndex, String deviceId) async {
    if (!_canRead(sessionId)) {
      throw Exception('Rate limit exceeded for reads');
    }

    print(
        '🔥 FIRESTORE READ: canJoinRemoteTeam($sessionId) - color: $colorIndex, device: $deviceId');
    final doc = await sessions.doc(sessionId).get();
    if (!doc.exists) return false;

    final data = doc.data() as Map<String, dynamic>;
    final teams = (data['teams'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        [];

    final targetTeam = teams.firstWhere(
      (t) => t['colorIndex'] == colorIndex,
      orElse: () => <String, dynamic>{},
    );

    if (targetTeam.isEmpty) {
      // No team with this color exists, can create new team
      return true;
    }

    if (targetTeam['teamMode'] == 'remote') {
      final devices = targetTeam['devices'] as List? ?? [];
      // Can join if team has less than 2 players and device isn't already in team
      return devices.length < 2 &&
          !devices.any((d) => d['deviceId'] == deviceId);
    }

    // Can't join couch mode teams or full remote teams
    return false;
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

    print(
        '🔥 FIRESTORE READ: transferHostIfNeeded($sessionId) - leavingDeviceId: $leavingDeviceId');
    final doc = await sessions.doc(sessionId).get();
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;
    final currentHostId = data['hostId'] as String?;
    if (currentHostId != leavingDeviceId) {
      return; // Only transfer if the host is leaving
    }

    final teams = (data['teams'] as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    // Find the first active team with a deviceId different from the leaving host
    final newHostTeam = teams.firstWhere(
      (t) => t['active'] == true && t['deviceId'] != leavingDeviceId,
      orElse: () => <String, dynamic>{},
    );
    if (newHostTeam.isNotEmpty && newHostTeam['deviceId'] != null) {
      print(
          '🔥 FIRESTORE WRITE: transferHostIfNeeded($sessionId) - new host: ${newHostTeam['deviceId']}');
      await sessions.doc(sessionId).update({'hostId': newHostTeam['deviceId']});
    }
  }

  /// Check if a session exists (with authentication and rate limiting)
  static Future<bool> sessionExists(String sessionId) async {
    if (!_canRead(sessionId)) {
      throw Exception('Rate limit exceeded for reads');
    }

    print(
        '🔥 FIRESTORE READ: sessionExists($sessionId) - checking session existence');
    final doc = await sessions.doc(sessionId).get();
    return doc.exists;
  }

  /// Clear cached stream for a session (call when leaving a session)
  static void clearSessionStreamCache(String sessionId) {
    _sessionStreamCache.remove(sessionId);
    print('🗑️ CACHE: Cleared stream cache for session $sessionId');
  }
}
