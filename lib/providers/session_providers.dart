import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

/// Provides a stream of session document snapshots for a given session ID.
/// Uses caching to reduce Firestore reads
final sessionStreamProvider =
    StreamProvider.family<DocumentSnapshot<Map<String, dynamic>>?, String>(
        (ref, sessionId) {
  return FirestoreService.sessionStream(sessionId);
});

/// Provides a stream of the settings map for a given session ID.
/// Only triggers when settings actually change
final sessionSettingsProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, sessionId) {
  return FirestoreService.sessionStream(sessionId)
      .map((doc) => doc.data()?['settings'] as Map<String, dynamic>?)
      .distinct(); // Only emit when settings actually change
});

/// Provides a stream of only the game status for a given session ID.
/// Only triggers when the status field actually changes.
final sessionStatusProvider =
    StreamProvider.family<String?, String>((ref, sessionId) {
  return FirestoreService.sessionStream(sessionId)
      .map((doc) => doc.data()?['gameState']?['status'] as String?)
      .distinct(); // Only emit when the value actually changes
});

/// Provides a stream of only the game state for a given session ID.
/// Only triggers when game state actually changes.
final sessionGameStateProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, sessionId) {
  return FirestoreService.sessionStream(sessionId)
      .map((doc) => doc.data()?['gameState'] as Map<String, dynamic>?)
      .distinct(); // Only emit when game state actually changes
});

/// Provides a stream of only the category spin state for a given session ID.
/// Only triggers when category spin state actually changes.
final sessionCategorySpinProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, sessionId) {
  return FirestoreService.sessionStream(sessionId)
      .map((doc) =>
          doc.data()?['gameState']?['categorySpin'] as Map<String, dynamic>?)
      .distinct(); // Only emit when category spin state actually changes
});

/// Provides a stream of only the turn over state for a given session ID.
/// Only triggers when turn over state actually changes.
final sessionTurnOverProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, sessionId) {
  return FirestoreService.sessionStream(sessionId)
      .map((doc) =>
          doc.data()?['gameState']?['turnOverState'] as Map<String, dynamic>?)
      .distinct(); // Only emit when turn over state actually changes
});
