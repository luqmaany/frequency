import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

/// Provides a stream of session document snapshots for a given session ID.
final sessionStreamProvider =
    StreamProvider.family<DocumentSnapshot<Map<String, dynamic>>?, String>(
        (ref, sessionId) {
  return FirestoreService.sessionStream(sessionId);
});

/// Provides a stream of the settings map for a given session ID.
final sessionSettingsProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, sessionId) {
  return FirestoreService.sessionStream(sessionId).map((doc) =>
      (doc.data()?['gameState'] as Map<String, dynamic>?)?['gameConfig']
          as Map<String, dynamic>?);
});
