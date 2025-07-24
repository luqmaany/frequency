import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final _sessions = FirebaseFirestore.instance.collection('sessions');

  // Create a new session document with a gameState object
  static Future<void> createSession(String sessionId,
      Map<String, dynamic> sessionData, Map<String, dynamic>? gameState) async {
    await _sessions.doc(sessionId).set({
      ...sessionData,
      'gameState': gameState,
    });
  }

  // Update the gameState object for a session
  static Future<void> setGameState(
      String sessionId, Map<String, dynamic> gameState) async {
    await _sessions.doc(sessionId).update({'gameState': gameState});
  }

  // Get the gameState object for a session (one-time fetch)
  static Future<Map<String, dynamic>?> getGameState(String sessionId) async {
    final doc = await _sessions.doc(sessionId).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    return data['gameState'] as Map<String, dynamic>?;
  }

  // Join a session by adding a team to the teams array
  static Future<void> joinSession(
      String sessionId, Map<String, dynamic> teamData) async {
    await _sessions.doc(sessionId).update({
      'teams': FieldValue.arrayUnion([teamData])
    });
  }

  // Update a team's info (name, color, ready) in the teams array by teamId
  static Future<void> updateTeam(String sessionId, String teamId,
      Map<String, dynamic> updatedFields) async {
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

  // Listen to session changes
  static Stream<DocumentSnapshot<Map<String, dynamic>>> sessionStream(
      String sessionId) {
    return _sessions.doc(sessionId).snapshots();
  }

  // Mark a team as inactive (team leaves the game)
  static Future<void> leaveTeam(String sessionId, String teamId) async {
    final doc = await _sessions.doc(sessionId).get();
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;
    final teams = (data['teams'] as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final idx = teams.indexWhere((t) => t['teamId'] == teamId);
    if (idx == -1) return;
    teams[idx]['active'] = false;
    teams[idx]['lastSeen'] = DateTime.now().millisecondsSinceEpoch;
    await _sessions.doc(sessionId).update({'teams': teams});
  }

  // Mark a team as active (team rejoins the game)
  // Optionally update the players list
  static Future<void> rejoinTeam(
      String sessionId, String teamId, List<String> players) async {
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
    teams[idx]['lastSeen'] = DateTime.now().millisecondsSinceEpoch;
    await _sessions.doc(sessionId).update({'teams': teams});
  }

  // Transfer host status to another active team if the current host leaves
  static Future<void> transferHostIfNeeded(
      String sessionId, String leavingDeviceId) async {
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
