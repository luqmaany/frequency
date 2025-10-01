# Reconnection & Offline Support Plan

## Problem Statement

This is a **synchronous multiplayer game** where players take turns in real-time. Unlike asynchronous games (like chess), offline support must be carefully designed to prevent:

- ❌ Players queuing critical actions while offline (blocking others)
- ❌ Other teams waiting indefinitely for disconnected players
- ❌ Game state desync across devices
- ✅ While still handling brief network hiccups gracefully

---

## Current State

### What We Have
- Firestore streams for real-time game state
- Rate limiting (70 reads/min, 100 writes/min per session)
- Cached streams to reduce duplicate listeners
- Basic error handling in some screens (`.when()` pattern)

### What We DON'T Have
- ❌ Firestore offline persistence configuration
- ❌ Connection state monitoring
- ❌ User feedback about offline state
- ❌ Guards to prevent offline writes for critical operations
- ❌ Timeout handling for stuck/offline players
- ❌ Consistent error handling across all screens

---

## Architecture Overview

### Three-Tier Approach

```
┌─────────────────────────────────────────────────────────┐
│ TIER 1: Enable Firestore Offline Persistence           │
│ - Handles 1-5 second network blips automatically       │
│ - Queues non-critical writes (lobby actions)           │
│ - Provides instant reads from cache                    │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ TIER 2: Connection State Detection & UI Feedback       │
│ - Detect when truly offline vs. slow network           │
│ - Show "Reconnecting..." banner to users               │
│ - Provide metadata (cache vs. server) indicators       │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ TIER 3: Smart Operation Guards & Timeout Handling      │
│ - Block critical operations when offline               │
│ - Allow non-blocking operations to queue               │
│ - Auto-skip teams that timeout (host control)          │
└─────────────────────────────────────────────────────────┘
```

---

## Operation Categories

### ✅ SAFE for Offline Queueing (Lobby Phase)

These don't block other players:

```dart
// Joining/leaving lobby
FirestoreService.joinSession()
FirestoreService.upsertTeamByDeviceId()
FirestoreService.removeTeamByDeviceId()
FirestoreService.updateTeam() // name, color, ready status
```

**Why safe:** Game hasn't started, no one waiting, eventual consistency is fine.

---

### ⚠️ CONDITIONALLY Safe (View-Only)

```dart
// Reads
sessionStream() // Watching game state
sessionTeamsProvider() // Viewing scoreboard

// Personal confirmations (don't block progression)
FirestoreService.confirmScoreForTeam()
```

**Why conditionally safe:** Reads from cache are fine for spectating. Score confirmations can wait.

---

### ❌ MUST BE ONLINE (Critical Game Actions)

```dart
// Host controls
FirestoreService.startGame() 
FirestoreService.fromRoundEnd()

// Active turn controls (when it's YOUR turn)
FirestoreService.updateCategorySpinState()
FirestoreService.fromCategorySelection()
FirestoreService.updateRoleAssignment()
FirestoreService.fromRoleAssignment()
FirestoreService.fromGameScreen() // End your turn
FirestoreService.fromTurnOver() // Advance to next team
FirestoreService.advanceToNextTeam()
```

**Why must be online:** All other players are waiting. Game progression blocked.

---

## Implementation Plan

### Phase 1: Enable Smart Offline Support (30 min)

#### Step 1.1: Configure Firestore Persistence

**File:** `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ADD THIS
import 'screens/home_screen.dart';
import 'services/theme_provider.dart';
import 'services/storage_service.dart';
import 'data/category_registry.dart';
import 'services/purchase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Prevent duplicate Firebase app initialization
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
    
    // ============================================================
    // CONFIGURE FIRESTORE OFFLINE PERSISTENCE
    // ============================================================
    final firestore = FirebaseFirestore.instance;
    
    // Configure optimal settings for multiplayer game
    firestore.settings = const Settings(
      // Persistence enabled by default on mobile, explicit for clarity
      persistenceEnabled: true,
      
      // Set cache size - 100 MB handles ~2000 game sessions
      cacheSizeBytes: 100 * 1024 * 1024,
    );
    
    print('✅ Firestore offline persistence configured (100 MB cache)');
  }
  
  await CategoryRegistry.loadDynamicCategories();
  await PurchaseService.init();
  // ... rest of existing code
}
```

**What this does:**
- Caches Firestore reads locally (instant from cache when offline)
- Queues writes locally (auto-sync when reconnected)
- Handles brief disconnections (1-5 seconds) transparently

---

#### Step 1.2: Create Connection State Service

**File:** `lib/services/connection_service.dart` (NEW FILE)

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service to detect connection state using Firestore metadata
class ConnectionService {
  /// Stream that emits true when online, false when offline
  /// Uses Firestore's metadata to detect actual connection state
  static Stream<bool> connectionStream() {
    // Monitor a lightweight document to track connection
    return FirebaseFirestore.instance
        .collection('_system')
        .doc('connection_test')
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          // If metadata shows data from cache, we're offline
          final isFromCache = snapshot.metadata.isFromCache;
          final hasPendingWrites = snapshot.metadata.hasPendingWrites;
          
          // We're online if data is from server OR we have pending writes being synced
          return !isFromCache || hasPendingWrites;
        })
        .distinct();
  }
}

/// Provider for global connection state
final connectionStateProvider = StreamProvider<bool>((ref) {
  return ConnectionService.connectionStream();
});
```

**Usage:** Any screen can check `ref.watch(connectionStateProvider)`.

---

#### Step 1.3: Add Connection Banner Widget

**File:** `lib/widgets/connection_banner.dart` (NEW FILE)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/connection_service.dart';

/// Banner that shows at top of screen when offline
class ConnectionBanner extends ConsumerWidget {
  const ConnectionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionAsync = ref.watch(connectionStateProvider);
    
    return connectionAsync.when(
      data: (isOnline) {
        if (isOnline) return const SizedBox.shrink();
        
        // Show reconnecting banner when offline
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: Colors.orange.shade700,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Reconnecting...',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
```

**Add to screens:**

```dart
// Example: in online_game_screen.dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        const ConnectionBanner(), // ADD THIS
        Expanded(
          child: /* existing UI */
        ),
      ],
    ),
  );
}
```

---

### Phase 2: Protect Critical Operations (1 hour)

#### Step 2.1: Create Firestore Operation Wrapper

**File:** `lib/services/firestore_wrapper.dart` (NEW FILE)

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Wrapper for Firestore operations with offline handling
class FirestoreWrapper {
  /// For operations that MUST succeed immediately (like ending your turn)
  /// Throws exception if offline, preventing queueing
  static Future<T> requireOnlineWrite<T>({
    required Future<T> Function() operation,
    required bool isOnline,
    String offlineMessage = 'You must be online to perform this action',
    Duration timeout = const Duration(seconds: 10),
  }) async {
    // Check if we're online BEFORE attempting the write
    if (!isOnline) {
      throw Exception(offlineMessage);
    }

    try {
      return await operation().timeout(
        timeout,
        onTimeout: () {
          throw Exception('Operation timed out. Check your connection.');
        },
      );
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
        throw Exception('Cannot connect to server. Check your connection.');
      }
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. You may not have access.');
      }
      rethrow;
    } catch (e) {
      // Re-throw any other errors
      rethrow;
    }
  }

  /// For operations that can be queued (like lobby actions)
  /// Allows offline queueing, Firestore will sync when reconnected
  static Future<T> allowOfflineWrite<T>({
    required Future<T> Function() operation,
    String errorMessage = 'Operation failed',
  }) async {
    try {
      // Let Firestore handle queueing automatically
      return await operation();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied');
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception(errorMessage);
    }
  }
}
```

---

#### Step 2.2: Protect Turn-Ending Operations

**Example: `lib/screens/online_game_screen.dart`**

```dart
@override
void onTurnEnd() {
  print('onTurnEnd');
  
  try {
    ref.read(soundServiceProvider).playTurnEnd();
  } catch (_) {}

  final conveyor = widget.sessionData!['gameState']['currentConveyor'] as String;
  final guesser = widget.sessionData!['gameState']['currentGuesser'] as String;

  // CHECK CONNECTION BEFORE ALLOWING TURN END
  final connectionAsync = ref.read(connectionStateProvider);
  final isOnline = connectionAsync.value ?? false;

  FirestoreWrapper.requireOnlineWrite(
    operation: () => FirestoreService.fromGameScreen(
      widget.sessionId!,
      widget.teamIndex,
      widget.roundNumber,
      widget.turnNumber,
      widget.category,
      correctCount,
      skipsLeft,
      wordsGuessed,
      wordsSkipped,
      currentWords.map((w) => w.text).toList(),
      disputedWords,
      conveyor,
      guesser,
    ),
    isOnline: isOnline,
    offlineMessage: 'You must be online to end your turn. Reconnecting...',
  ).catchError((error) {
    // Show error to user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => onTurnEnd(), // Retry
          ),
        ),
      );
    }
  });
}
```

---

#### Step 2.3: Protect Other Critical Operations

Apply the same pattern to:

1. **Category selection** (`lib/screens/category_selection_screen.dart`)
2. **Role assignment** (`lib/screens/role_assignment_screen.dart`)
3. **Turn over advancement** (`lib/screens/online_turn_over_screen.dart`)
4. **Host starting game** (`lib/screens/game_settings_screen.dart`)

**Template:**

```dart
final isOnline = ref.read(connectionStateProvider).value ?? false;

FirestoreWrapper.requireOnlineWrite(
  operation: () => FirestoreService.someOperation(...),
  isOnline: isOnline,
  offlineMessage: 'You must be online to [action]',
).catchError((error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(error.toString())),
  );
});
```

---

### Phase 3: Handle Stuck Games (2 hours)

#### Step 3.1: Add Turn Timeout Detection

**File:** `lib/services/turn_timeout_service.dart` (NEW FILE)

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to detect and handle teams that timeout during their turn
class TurnTimeoutService {
  // Timeout after 2 minutes of no activity
  static const _turnTimeout = Duration(minutes: 2);
  
  /// Monitor if current team is taking too long (possibly offline)
  static Stream<bool> currentTeamTimedOut(String sessionId) {
    return FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data();
          if (data == null) return false;
          
          final gameState = data['gameState'] as Map<String, dynamic>?;
          if (gameState == null) return false;
          
          // Check when turn started
          final turnStartTime = gameState['turnStartTime'] as Timestamp?;
          if (turnStartTime == null) return false;
          
          // Check if status is still in active turn states
          final status = gameState['status'] as String?;
          final activeStates = ['category_selection', 'role_assignment', 'game'];
          if (!activeStates.contains(status)) return false;
          
          // Calculate elapsed time
          final elapsed = DateTime.now().difference(turnStartTime.toDate());
          return elapsed > _turnTimeout;
        })
        .distinct();
  }
  
  /// Host can force-skip a team that's offline/timed out
  static Future<void> skipOfflineTeam(String sessionId) async {
    final docRef = FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId);
    
    final snapshot = await docRef.get();
    final data = snapshot.data();
    if (data == null) return;
    
    final gameState = data['gameState'] as Map<String, dynamic>?;
    final teams = data['teams'] as List? ?? [];
    final currentTeamIndex = gameState?['currentTeamIndex'] as int? ?? 0;
    
    // Create a forfeit turn record
    final forfeitTurnRecord = {
      'teamIndex': currentTeamIndex,
      'roundNumber': gameState?['roundNumber'] ?? 1,
      'turnNumber': gameState?['turnNumber'] ?? 1,
      'category': 'Forfeited',
      'correctCount': 0,
      'skipsLeft': 0,
      'wordsGuessed': [],
      'wordsSkipped': [],
      'wordsLeftOnScreen': [],
      'disputedWords': [],
      'conveyor': 'Offline',
      'guesser': 'Offline',
      'isForfeited': true, // Mark as forfeited
    };
    
    // Add forfeit to turn history and advance
    await docRef.update({
      'gameState.turnHistory': FieldValue.arrayUnion([forfeitTurnRecord]),
      'gameState.currentTurnRecord': forfeitTurnRecord,
    });
    
    // Advance to next team
    await FirestoreService.advanceToNextTeam(sessionId);
  }
  
  /// Update turn start time when turn begins
  static Future<void> markTurnStart(String sessionId) async {
    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .update({
          'gameState.turnStartTime': FieldValue.serverTimestamp(),
        });
  }
}
```

---

#### Step 3.2: Add Timeout UI for Host

**File:** `lib/widgets/turn_timeout_dialog.dart` (NEW FILE)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/turn_timeout_service.dart';

/// Dialog shown to host when current team times out
class TurnTimeoutDialog extends ConsumerWidget {
  final String sessionId;
  final String teamName;
  
  const TurnTimeoutDialog({
    super.key,
    required this.sessionId,
    required this.teamName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.orange),
          SizedBox(width: 12),
          Text('Player Disconnected'),
        ],
      ),
      content: Text(
        '$teamName appears to be offline and has not taken their turn.\n\n'
        'You can skip their turn (0 points) to continue the game.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Wait Longer'),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              await TurnTimeoutService.skipOfflineTeam(sessionId);
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Skipped $teamName\'s turn')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
          ),
          child: const Text('Skip Turn (0 pts)'),
        ),
      ],
    );
  }
}
```

---

#### Step 3.3: Integrate Timeout Detection in Screens

**Example: `lib/screens/category_selection_screen.dart`**

```dart
@override
Widget build(BuildContext context) {
  // ... existing code
  
  // For online games, monitor timeout if we're NOT the active team
  if (widget.sessionId != null && !_isActiveTeam) {
    ref.listen(
      // Create a provider that monitors timeout
      StreamProvider((ref) => 
        TurnTimeoutService.currentTeamTimedOut(widget.sessionId!)
      ),
      (previous, next) {
        final timedOut = next.value ?? false;
        
        // Only host can skip
        if (timedOut && _isHost && context.mounted) {
          showDialog(
            context: context,
            builder: (_) => TurnTimeoutDialog(
              sessionId: widget.sessionId!,
              teamName: _currentTeamName,
            ),
          );
        }
      },
    );
  }
  
  // ... rest of build
}
```

---

#### Step 3.4: Mark Turn Start Times

Update navigation service to mark when turns start:

**File:** `lib/services/online_game_navigation_service.dart`**

```dart
// In _navigateToCategorySelection method
static void _navigateToCategorySelection(...) async {
  // Mark turn start for timeout tracking
  await TurnTimeoutService.markTurnStart(sessionId);
  
  // ... existing navigation code
}
```

Do the same for:
- `_navigateToRoleAssignment`
- `_navigateToGameScreen`

---

## Decision Matrix

| Operation | Offline OK? | Wrapper | Reason |
|-----------|-------------|---------|---------|
| Join lobby | ✅ Yes | `allowOfflineWrite` | Doesn't block others |
| Change team color | ✅ Yes | `allowOfflineWrite` | Non-critical |
| Mark ready | ⚠️ Conditional | `requireOnlineWrite` | Should warn if offline |
| Host starts game | ❌ No | `requireOnlineWrite` | Everyone must know |
| Select category | ❌ No | `requireOnlineWrite` | Active turn, others waiting |
| Assign roles | ❌ No | `requireOnlineWrite` | Active turn |
| End turn | ❌ No | `requireOnlineWrite` | Critical sync point |
| View scoreboard | ✅ Yes | N/A (read) | Cached is fine |
| Confirm score | ⚠️ Yes | `allowOfflineWrite` | Can queue, warn user |

---

## Testing Guide

### Test Scenario 1: Brief Network Hiccup (< 5 seconds)

1. Start a game session with 2 devices
2. During Team A's turn, enable airplane mode for 3 seconds
3. Disable airplane mode
4. **Expected:** Game continues smoothly, writes auto-sync

### Test Scenario 2: Extended Offline (30+ seconds)

1. Start a game session
2. During Team A's turn, enable airplane mode
3. Try to end turn
4. **Expected:** Error message "You must be online to end your turn"
5. Disable airplane mode
6. **Expected:** Connection banner disappears, retry works

### Test Scenario 3: Team Timeout

1. Start a game with 3+ teams
2. Host device online, Team B device goes offline
3. Wait 2 minutes
4. **Expected:** Host sees "Skip Turn" dialog
5. Host skips turn
6. **Expected:** Game advances to Team C with 0 points for Team B

### Test Scenario 4: Lobby Actions While Offline

1. On lobby screen, enable airplane mode
2. Change team color
3. Disable airplane mode
4. **Expected:** Color change syncs automatically, no errors

---

## File Checklist

### New Files to Create

- [ ] `lib/services/connection_service.dart`
- [ ] `lib/services/firestore_wrapper.dart`
- [ ] `lib/services/turn_timeout_service.dart`
- [ ] `lib/widgets/connection_banner.dart`
- [ ] `lib/widgets/turn_timeout_dialog.dart`

### Files to Modify

- [ ] `lib/main.dart` - Add Firestore persistence config
- [ ] `lib/screens/online_game_screen.dart` - Add connection guard
- [ ] `lib/screens/category_selection_screen.dart` - Add guards + timeout UI
- [ ] `lib/screens/role_assignment_screen.dart` - Add connection guard
- [ ] `lib/screens/online_turn_over_screen.dart` - Add connection guard
- [ ] `lib/screens/game_settings_screen.dart` - Guard start game
- [ ] `lib/services/online_game_navigation_service.dart` - Mark turn starts

---

## Implementation Order

1. **Phase 1** (30 min) - Basic offline support
   - Configure Firestore persistence
   - Add connection state provider
   - Add connection banner to key screens
   
2. **Test Phase 1** - Verify brief disconnections work

3. **Phase 2** (1 hour) - Protect critical operations
   - Create `FirestoreWrapper`
   - Guard turn-ending operations
   - Guard host operations
   
4. **Test Phase 2** - Verify offline errors show properly

5. **Phase 3** (2 hours) - Handle timeouts
   - Create timeout service
   - Add timeout UI
   - Mark turn start times
   
6. **Test Phase 3** - Verify timeout/skip works

---

## Future Enhancements (Optional)

### Low Priority

- [ ] Exponential backoff for failed writes (probably not needed with Firestore's built-in retry)
- [ ] Local queue visualization (show pending writes to user)
- [ ] Reconnection sound/haptic feedback
- [ ] Analytics for connection quality

### Nice to Have

- [ ] "Rejoin game" from push notification when reconnected
- [ ] Automatic team timeout after 3 consecutive forfeit turns
- [ ] Connection quality indicator (ping time)

---

## Notes

- Firestore's offline persistence is **already enabled by default** on Android/iOS, but explicit configuration is better
- The 100 MB cache size handles ~2000 game sessions
- Connection state uses Firestore metadata (more accurate than network connectivity)
- Timeout duration (2 min) should be tuned based on user testing
- All critical operations have 10-second timeout to prevent infinite hangs

---

## Estimated Total Time

- **Phase 1:** 30 minutes
- **Phase 2:** 1 hour
- **Phase 3:** 2 hours
- **Testing:** 1 hour
- **Total:** ~4.5 hours

---

*Last Updated: October 1, 2025*

