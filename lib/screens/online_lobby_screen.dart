import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/team_color_button.dart';
import '../services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/storage_service.dart';
import '../providers/session_providers.dart';
import 'online_team_lobby_screen.dart';
import 'dart:math';
import '../widgets/parallel_pulse_waves_background.dart';
import '../widgets/segmented_code_input.dart';

class OnlineLobbyScreen extends ConsumerStatefulWidget {
  const OnlineLobbyScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends ConsumerState<OnlineLobbyScreen> {
  final TextEditingController _joinCodeController = TextEditingController();
  final SegmentedCodeController _codeController = SegmentedCodeController();
  String? _createError;
  String? _joinError;
  bool _isCreating = false;
  bool _isJoining = false;

  Future<void> _joinSession() async {
    final code = _joinCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _joinError = 'Enter join code.';
        _createError = null;
      });
      return;
    }
    setState(() {
      _isJoining = true;
      _joinError = null;
      _createError = null;
    });
    try {
      final deviceId = await StorageService.getDeviceId();

      // Check if session exists using provider
      final sessionExists = await ref.read(sessionExistsProvider(code).future);
      if (!mounted) return;
      if (!sessionExists) {
        setState(() => _joinError = 'Session not found.');
        _codeController.clear();
        return;
      }

      // Get teams using provider
      final teams = await ref.read(sessionTeamsProvider(code).future);

      // Check if this device already has a team in this session
      final myTeam = teams.firstWhere(
        (t) => t['deviceId'] == deviceId,
        orElse: () => <String, dynamic>{},
      );

      if (myTeam.isNotEmpty) {
        // Rejoin: mark as active and go to team lobby
        await FirestoreService.rejoinTeam(
            code, myTeam['teamId'], List<String>.from(myTeam['players']));
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OnlineTeamLobbyScreen(
              sessionId: code,
              player1Name: (myTeam['players'] as List?)?[0] ?? 'Player 1',
              player2Name: (myTeam['players'] as List?)?[1] ?? 'Player 2',
            ),
          ),
        );
      } else {
        // New join: go to team lobby to set up team
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OnlineTeamLobbyScreen(
              sessionId: code,
              player1Name: '', // Empty - user will set this
              player2Name: '', // Empty - user will set this
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _joinError = 'Failed to join session.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join session: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isJoining = false;
      });
    }
  }

  Future<bool> _sessionExists(String code) async {
    try {
      final exists = await ref.read(sessionExistsProvider(code).future);
      print('🔍 Checking session $code: exists=$exists');
      return exists;
    } catch (e) {
      print('❌ Error checking session existence: $e');
      return false; // If there's an error, assume it doesn't exist
    }
  }

  Future<void> _createSession() async {
    setState(() {
      _isCreating = true;
      _createError = null;
    });

    String newCode = '';
    bool exists = true;
    int attempts = 0;
    const maxAttempts = 3;

    // Try up to 3 times to generate a unique code
    while (exists && attempts < maxAttempts) {
      print('another one');
      newCode = _generateRandomCode();
      exists = await _sessionExists(newCode);
      attempts++;
      print('🔍 Session creation attempt $attempts: $newCode exists=$exists');

      // Add a small delay to prevent overwhelming Firestore
      if (attempts < maxAttempts) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    if (exists) {
      setState(() {
        _isCreating = false;
        _createError =
            'Failed to generate unique code after $maxAttempts attempts. Please try again.';
      });
      return;
    }
    try {
      final hostId = await StorageService.getDeviceId();

      // Create session with all initial data in one operation
      final sessionData = {
        'sessionId': newCode,
        'hostId': hostId,
        'settings': {
          'roundTimeSeconds': 60,
          'targetScore': 20,
          'allowedSkips': 3,
          'tiebreakerTimeSeconds': 30,
        },
        'teams': [], // Empty teams array - teams will be added manually
        'gameState': {
          'currentTeamIndex': 0,
          'roundNumber': 1,
          'turnNumber': 1,
        },
        'createdAt': FieldValue.serverTimestamp(),
      };

      await ref.read(createSessionProvider(sessionData).future);

      // Navigate to a team setup screen or show instructions
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OnlineTeamLobbyScreen(
            sessionId: newCode,
            player1Name: '', // Empty - user will set this
            player2Name: '', // Empty - user will set this
          ),
        ),
      );
    } catch (e) {
      setState(() => _createError = 'Failed to create session.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create session: $e')),
      );
    } finally {
      setState(() => _isCreating = false);
    }
  }

  String _generateRandomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(6, (i) => chars[rand.nextInt(chars.length)]).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: ParallelPulseWavesBackground(
              perRowPhaseOffset: 0.0,
              baseSpacing: 35.0,
            ),
          ),
          Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24.0),
                  children: [
                    const SizedBox(height: 48),
                    Center(
                      child: Text(
                        'Online Lobby',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Push controls closer to the middle of the screen
                    const SizedBox(height: 100),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Create session first
                          TeamColorButton(
                            text: 'Create New Session',
                            icon: Icons.add,
                            color: teamColors[1],
                            onPressed: _isCreating ? null : _createSession,
                            isLoading: _isCreating,
                          ),
                          if (_createError != null) ...[
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                _createError!,
                                style: TextStyle(
                                  color: Colors.red.shade400,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),
                          // OR separator
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Theme.of(context)
                                      .dividerColor
                                      .withOpacity(0.4),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.8),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Theme.of(context)
                                      .dividerColor
                                      .withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Join section below
                          SegmentedCodeInput(
                            length: 6,
                            controller: _codeController,
                            onChanged: (value) {
                              setState(() => _joinError = null);
                              _joinCodeController.text = value;
                            },
                            onCompleted: (value) async {
                              setState(() => _joinError = null);
                              _joinCodeController.text = value;
                              // Do not auto-join; wait for button press
                            },
                          ),
                          if (_joinError != null) ...[
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                _joinError!,
                                style: TextStyle(
                                  color: Colors.red.shade400,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TeamColorButton(
                      text: 'Join Session',
                      icon: Icons.login_rounded,
                      color: teamColors[0],
                      onPressed: _isJoining ? null : _joinSession,
                      isLoading: _isJoining,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TeamColorButton(
                        text: 'Home',
                        icon: Icons.home,
                        color: uiColors[0],
                        onPressed: () {
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
