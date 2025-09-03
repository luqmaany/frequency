import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import 'dart:math';

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

/// Provides a stream of only the selected category for a given session ID.
/// Only triggers when selected category actually changes.
final sessionSelectedCategoryProvider =
    StreamProvider.family<String?, String>((ref, sessionId) {
  return FirestoreService.sessionStream(sessionId)
      .map((doc) => doc.data()?['gameState']?['selectedCategory'] as String?)
      .distinct(); // Only emit when selected category actually changes
});

/// Provides a stream of only the role assignment state for a given session ID.
/// Only triggers when role assignment state actually changes.
final sessionRoleAssignmentProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, sessionId) {
  return FirestoreService.sessionStream(sessionId)
      .map((doc) =>
          doc.data()?['gameState']?['roleAssignment'] as Map<String, dynamic>?)
      .distinct(); // Only emit when role assignment state actually changes
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

// ============================================================================
// SESSION MANAGEMENT PROVIDERS
// ============================================================================

/// Provider for checking if a session exists
final sessionExistsProvider =
    FutureProvider.family<bool, String>((ref, sessionId) async {
  return FirestoreService.sessionExists(sessionId);
});

/// Provider for creating a new session
final createSessionProvider =
    FutureProvider.family<String, Map<String, dynamic>>(
        (ref, sessionData) async {
  final sessionId = sessionData['sessionId'] as String;
  print(
      '🔥 FIRESTORE WRITE: createSessionProvider($sessionId) - creating new session');
  await FirestoreService.sessions.doc(sessionId).set(sessionData);
  return sessionId;
});

// ============================================================================
// TEAM MANAGEMENT PROVIDERS
// ============================================================================

/// Provider for getting teams from a session
final sessionTeamsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, sessionId) async {
  print('🔥 FIRESTORE READ: sessionTeamsProvider($sessionId) - getting teams');
  final doc = await FirestoreService.sessions.doc(sessionId).get();
  if (!doc.exists) return [];
  final data = doc.data() as Map<String, dynamic>;
  return (data['teams'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e))
          .toList() ??
      [];
});

/// Provider for updating teams in a session
final updateTeamsProvider =
    FutureProvider.family<void, Map<String, dynamic>>((ref, params) async {
  final sessionId = params['sessionId'] as String;
  final teams = params['teams'] as List<Map<String, dynamic>>;
  print('🔥 FIRESTORE WRITE: updateTeamsProvider($sessionId) - updating teams');
  await FirestoreService.sessions.doc(sessionId).update({'teams': teams});
});

/// Provider for updating settings in a session
final updateSettingsProvider =
    FutureProvider.family<void, Map<String, dynamic>>((ref, params) async {
  final sessionId = params['sessionId'] as String;
  final key = params['key'] as String;
  final value = params['value'];
  print(
      '🔥 FIRESTORE WRITE: updateSettingsProvider($sessionId) - key: $key, value: $value');
  await FirestoreService.sessions
      .doc(sessionId)
      .update({'settings.$key': value});
});

/// Provider for updating game state status
final updateGameStateStatusProvider =
    FutureProvider.family<void, Map<String, dynamic>>((ref, params) async {
  final sessionId = params['sessionId'] as String;
  final status = params['status'] as String;
  print(
      '🔥 FIRESTORE WRITE: updateGameStateStatusProvider($sessionId) - status: $status');
  await FirestoreService.sessions
      .doc(sessionId)
      .update({'gameState.status': status});
});

// ============================================================================
// UTILITY PROVIDERS
// ============================================================================

/// Provider for generating random session codes
final sessionCodeGeneratorProvider = Provider<String>((ref) {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final rand = Random.secure();
  return List.generate(6, (i) => chars[rand.nextInt(chars.length)]).join();
});

/// Provider for getting device ID
final deviceIdProvider = FutureProvider<String>((ref) async {
  return await StorageService.getDeviceId();
});
