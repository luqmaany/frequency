# Learning Notes - Flutter Game Development

This document captures key learnings and insights from developing the Convey word game in Flutter.

## 🎯 **Core Game Architecture**

### State Management with Riverpod
- **Provider Pattern**: Using `StateNotifierProvider` for complex state management
- **State Notifiers**: Classes that extend `StateNotifier<T?>` to manage nullable state
- **Consumer Widgets**: Widgets that can read and watch provider state changes

### Game State Flow
```
TurnOverScreen → GameStateNotifier.recordTurn() → GameState.advanceTurn() → Navigation
```

## ⚠️ **Critical Timing Considerations**

### The advanceTurn() Timing Problem
**The `advanceTurn()` method from `GameState` is called BEFORE navigation to the next screen.**

#### Key Issues:
1. **Off-by-One Errors**: `currentTeamIndex` is incremented before navigation
2. **State Mismatch**: Navigation logic sees updated state, not the state from when the turn started
3. **Tiebreaker Confusion**: `isInTiebreaker` and `tiedTeamIndices` may change during `advanceTurn()`

#### Best Practices:
```dart
// ✅ Always pass the teamIndex parameter
GameNavigationService.navigateToNextScreen(context, ref, teamIndex: widget.teamIndex);

// ✅ Use passed parameters instead of reading from updated state
final teamIndexInTiedTeams = tiedTeamIndices.indexOf(teamIndex ?? gameState.currentTeamIndex);

// ✅ Be explicit about which state you're checking
if (teamIndex == gameState.config.teams.length - 1) {
  // End of round logic
}
```

#### The Golden Rule:
**The key is to always be aware that `advanceTurn()` changes the game state, so any navigation logic needs to work with the state as it was BEFORE the turn was recorded, not after.**

## 🔧 **Dart Language Features**

### Null Safety
- **Null Assertion Operator (`!`)**: `state!.advanceTurn()` tells Dart "I know this isn't null"
- **Null-Aware Operator (`?.`)**: `state?.advanceTurn()` safely calls method if not null
- **Null Check Pattern**: `if (state == null) return;` + `state!.method()` is common

### Common Patterns
```dart
// Null assertion after null check
if (state == null) return;
state = state!.advanceTurn(turnRecord);

// this means that the state wont be null, so were telling dart that we know that it wont be null

// Alternative: null-aware operator
state = state?.advanceTurn(turnRecord);



// Alternative: explicit null check
if (state != null) {
  state = state.advanceTurn(turnRecord);
}
```

## 🎮 **Game Logic Patterns**

### Tiebreaker Implementation
- **Separate State Fields**: `isTiebreaker`, `isInTiebreaker`, `tiedTeamIndices`, `tiebreakerScores`
- **Round Tracking**: Use `tiebreakerRound` for tiebreaker-specific numbering
- **State Transitions**: Clear distinction between normal rounds and tiebreaker rounds

### Navigation Service Pattern
- **Centralized Navigation**: Single service handling all screen transitions
- **State-Aware Routing**: Navigation decisions based on current game state
- **Parameter Passing**: Always pass relevant data to navigation methods

## 🏗️ **Code Organization**

### Widget Architecture
- **Composable Widgets**: Break complex screens into smaller, reusable widgets
- **Mixin Pattern**: Use mixins for shared functionality (e.g., `GameMechanicsMixin`)
- **Provider Integration**: Widgets consume state through Riverpod providers

### Service Layer
- **State Providers**: Manage game state and business logic
- **Navigation Service**: Handle screen transitions
- **Setup Providers**: Manage game configuration

## 🐛 **Common Pitfalls & Solutions**

### Off-by-One Errors
**Problem**: Using `currentTeamIndex` after it's been incremented
**Solution**: Always use the `teamIndex` parameter passed to navigation methods

### State Confusion
**Problem**: Navigation logic using updated state instead of pre-turn state
**Solution**: Pass and use explicit parameters rather than reading from current state

### Round Number Reset
**Problem**: Resetting `currentRound` during tiebreaker caused navigation confusion
**Solution**: Keep `currentRound` unchanged, use `tiebreakerRound` for tiebreaker numbering

## 📱 **Flutter-Specific Learnings**

### Widget Lifecycle
- **initState()**: Initialize timers, load data
- **dispose()**: Clean up timers, cancel subscriptions
- **build()**: Return widget tree

### State Management
- **ConsumerStatefulWidget**: For widgets that need to manage local state
- **ConsumerWidget**: For widgets that only need to read provider state
- **ref.watch()**: Rebuild when provider changes
- **ref.read()**: One-time read, no rebuilds

### Navigation
- **Navigator.push()**: Add screen to stack
- **Navigator.pushReplacement()**: Replace current screen
- **Navigator.popUntil()**: Pop until condition met

## 🎨 **UI/UX Patterns**

### Category-Based Styling
- **Dynamic Colors**: Different colors for different word categories
- **Consistent Theming**: Use category colors throughout the UI
- **Visual Hierarchy**: Clear distinction between different game states

### Animation Patterns
- **Countdown Animations**: Smooth transitions for game start
- **Card Swiping**: Gesture-based interactions
- **State Transitions**: Visual feedback for game state changes

## 🔍 **Debugging Strategies**

### State Debugging
- **Print Statements**: Use `print('[DEBUG] ...')` for state tracking
- **Provider Watching**: Use `ref.watch()` to see state changes in real-time
- **State Inspection**: Log state before and after operations

### Navigation Debugging
- **Flow Tracing**: Follow the navigation call chain
- **State Comparison**: Compare state before and after `advanceTurn()`
- **Parameter Validation**: Ensure correct parameters are passed

## 📚 **Best Practices Summary**

1. **Always pass explicit parameters** to navigation methods
2. **Use null checks** before null assertion operators
3. **Keep state transitions clear** and well-documented
4. **Separate concerns** between state management and navigation
5. **Test edge cases** like tiebreakers and game over conditions
6. **Document timing dependencies** clearly
7. **Use meaningful variable names** that reflect the actual data
8. **Handle null cases explicitly** rather than relying on defaults

---

*This document should be updated as new learnings are discovered during development.* 