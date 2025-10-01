import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import '../services/sound_service.dart';
import '../services/theme_provider.dart';
import '../widgets/team_color_button.dart';
import '../widgets/dual_radial_interference_background.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final preferences = await StorageService.loadAppPreferences();
      setState(() {
        _soundEnabled = preferences['soundEnabled'] ?? true;
        _vibrationEnabled = preferences['vibrationEnabled'] ?? true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    try {
      await StorageService.saveAppPreferences(
        soundEnabled: _soundEnabled,
        vibrationEnabled: _vibrationEnabled,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save settings'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateSoundEnabled(bool value) {
    setState(() {
      _soundEnabled = value;
    });
    _saveSettings();
    // Reflect immediately in SoundService
    final soundService = ref.read(soundServiceProvider);
    soundService.setEnabled(value);
  }

  void _updateVibrationEnabled(bool value) {
    setState(() {
      _vibrationEnabled = value;
    });
    _saveSettings();
  }

  // Dark mode is forced globally; keep infra in provider but no toggle here.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                const Positioned.fill(
                  child: DualRadialInterferenceBackground(
                    verticalPositionFactor: 0.5,
                    sourcesHorizontalOffsetFactor: 0.52,
                    colorCyclesPerLoop: 0.05,
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.only(
                              left: 24, right: 24, top: 24, bottom: 100),
                          children: [
                            Center(
                              child: Text(
                                'Settings',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                'App Preferences',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.6,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildSettingTile(
                              context,
                              'Sound Effects',
                              Icons.volume_up_rounded,
                              'Enable sound effects during gameplay',
                              _soundEnabled,
                              _updateSoundEnabled,
                              Colors.blue,
                            ),
                            const SizedBox(height: 16),
                            _buildSettingTile(
                              context,
                              'Vibration',
                              Icons.vibration_rounded,
                              'Enable vibration feedback',
                              _vibrationEnabled,
                              _updateVibrationEnabled,
                              Colors.green,
                            ),
                            const SizedBox(height: 16),
                            // Dark mode is forced; hide toggle but keep code infrastructure
                            const SizedBox(height: 16),
                            Center(
                              child: Text(
                                'Data Management',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.6,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildActionTile(
                              context,
                              'Reset to Defaults',
                              Icons.refresh_rounded,
                              'Restore all settings to default values',
                              _showResetDefaultsDialog,
                              Colors.orange,
                            ),
                            const SizedBox(height: 16),
                            _buildActionTile(
                              context,
                              'Clear Game Data',
                              Icons.delete_outline_rounded,
                              'Remove all saved games and statistics',
                              _showClearDataDialog,
                              Colors.red,
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
                ),
              ],
            ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context,
    String title,
    IconData icon,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    Color color,
  ) {
    final Color baseBg = Theme.of(context).colorScheme.background;
    final Color overlay = color.withOpacity(0.3);
    final Color buttonColor = Color.alphaBlend(overlay, baseBg);
    final Color borderColor = color;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onChanged(!value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: borderColor.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, size: 24, color: borderColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFFE0E0E0),
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFB0B0B0),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: borderColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    String title,
    IconData icon,
    String subtitle,
    VoidCallback onTap,
    Color color,
  ) {
    final Color baseBg = Theme.of(context).colorScheme.background;
    final Color overlay = color.withOpacity(0.3);
    final Color buttonColor = Color.alphaBlend(overlay, baseBg);
    final Color borderColor = color;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: borderColor.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, size: 24, color: borderColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFFE0E0E0),
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFB0B0B0),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: borderColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearDataDialog() {
    _showStyledActionDialog(
      title: 'Clear Game Data',
      message:
          'This will permanently delete all saved games, statistics, and player data. This action cannot be undone.',
      baseColor: Colors.red,
      icon: Icons.delete_outline_rounded,
      confirmText: 'Clear Data',
      onConfirm: _clearGameData,
    );
  }

  void _showResetDefaultsDialog() {
    _showStyledActionDialog(
      title: 'Reset to Defaults',
      message:
          'This will reset all settings to their default values. Your game data will be preserved.',
      baseColor: Colors.orange,
      icon: Icons.refresh_rounded,
      confirmText: 'Reset',
      onConfirm: _resetToDefaults,
    );
  }

  Future<void> _clearGameData() async {
    try {
      await StorageService.clearGameData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Game data cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to clear game data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resetToDefaults() async {
    try {
      await StorageService.saveAppPreferences(
        soundEnabled: true,
        vibrationEnabled: true,
      );
      // Immediately re-enable sounds if they were off
      ref.read(soundServiceProvider).setEnabled(true);
      ref.read(themeProvider.notifier).setTheme(false);
      setState(() {
        _soundEnabled = true;
        _vibrationEnabled = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings reset to defaults'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to reset settings'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showStyledActionDialog({
    required String title,
    required String message,
    required Color baseColor,
    required IconData icon,
    required String confirmText,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final Color fillColor = Color.alphaBlend(
          baseColor.withOpacity(0.18),
          Theme.of(context).colorScheme.background,
        );
        final Color borderColor = baseColor;
        final Color textColor = Colors.white;
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 560),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: borderColor, size: 48),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: textColor.withOpacity(0.9), fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: TeamColorButton(
                        text: 'Cancel',
                        icon: Icons.close,
                        color: TeamColor('Base', baseColor.withOpacity(0.2),
                            borderColor, Colors.white),
                        variant: TeamButtonVariant.outline,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TeamColorButton(
                        text: confirmText,
                        icon: icon,
                        color: TeamColor('Base', baseColor.withOpacity(0.2),
                            borderColor, Colors.white),
                        variant: TeamButtonVariant.filled,
                        onPressed: () {
                          Navigator.of(context).pop();
                          onConfirm();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
