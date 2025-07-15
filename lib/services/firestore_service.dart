import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final _sessions = FirebaseFirestore.instance.collection('sessions');

  // Create a new session document
  static Future<void> createSession(
      String sessionId, Map<String, dynamic> sessionData) async {
    await _sessions.doc(sessionId).set(sessionData);
  }

  // Join a session by adding a team to the teams array
  static Future<void> joinSession(
      String sessionId, Map<String, dynamic> teamData) async {
    await _sessions.doc(sessionId).update({
      'teams': FieldValue.arrayUnion([teamData])
    });
  }

  // Update a team's info (name, color, ready) in the teams array
  static Future<void> updateTeam(String sessionId, String teamName,
      Map<String, dynamic> updatedFields) async {
    final doc = await _sessions.doc(sessionId).get();
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;
    final teams = (data['teams'] as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final idx = teams.indexWhere((t) => t['teamName'] == teamName);
    if (idx == -1) return;
    teams[idx].addAll(updatedFields);
    await _sessions.doc(sessionId).update({'teams': teams});
  }

  // Listen to session changes
  static Stream<DocumentSnapshot<Map<String, dynamic>>> sessionStream(
      String sessionId) {
    return _sessions.doc(sessionId).snapshots();
  }
}
