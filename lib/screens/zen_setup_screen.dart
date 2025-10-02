import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_setup_provider.dart';
import '../data/category_registry.dart';
import '../widgets/parallel_pulse_waves_background.dart';
import 'package:convey/widgets/team_color_button.dart';
import '../widgets/game_settings.dart';
import 'game_screen.dart';

class ZenSetupScreen extends ConsumerStatefulWidget {
  const ZenSetupScreen({super.key});

  @override
  ConsumerState<ZenSetupScreen> createState() => _ZenSetupScreenState();
}

class _ZenSetupScreenState extends ConsumerState<ZenSetupScreen> {
  // Defaults
  int _selectedTime = GameSettingsState.timeOptions[3]; // 60s
  int _selectedSkips = GameSettingsState.skipOptions[3]; // 3
  String _selectedCategoryId =
      CategoryRegistry.getUnlockedCategories().first.id;

  @override
  Widget build(BuildContext context) {
    final categories = CategoryRegistry.getUnlockedCategories();

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: ParallelPulseWavesBackground(
              perRowPhaseOffset: 0.0,
              baseSpacing: 35.0,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Center(
                    child: Text(
                      'Zen Mode',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ).copyWith(
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _buildSectionTitle(context, 'Time (seconds)'),
                                const SizedBox(height: 16),
                                _buildOptionsWrap<int>(
                                  options: GameSettingsState.timeOptions,
                                  isSelected: (v) => v == _selectedTime,
                                  labelBuilder: (v) => v.toString(),
                                  color: Colors.blue,
                                  onTap: (v) =>
                                      setState(() => _selectedTime = v),
                                ),
                                const SizedBox(height: 16),
                                _buildSectionTitle(context, 'Allowed Skips'),
                                const SizedBox(height: 16),
                                _buildOptionsWrap<int>(
                                  options: GameSettingsState.skipOptions,
                                  isSelected: (v) => v == _selectedSkips,
                                  labelBuilder: (v) => v.toString(),
                                  color: Colors.orange,
                                  onTap: (v) =>
                                      setState(() => _selectedSkips = v),
                                ),
                                const SizedBox(height: 16),
                                _buildSectionTitle(context, 'Category'),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  alignment: WrapAlignment.center,
                                  runAlignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    for (final cat in categories)
                                      GestureDetector(
                                        onTap: () => setState(
                                            () => _selectedCategoryId = cat.id),
                                        child: Builder(
                                          builder: (context) {
                                            final bool isSelectedCategory =
                                                _selectedCategoryId == cat.id;
                                            final Color baseBg =
                                                Theme.of(context)
                                                    .colorScheme
                                                    .background;
                                            final double overlayAlpha =
                                                isSelectedCategory ? 0.6 : 0.2;
                                            final Color background =
                                                Color.alphaBlend(
                                                    cat.color.withOpacity(
                                                        overlayAlpha),
                                                    baseBg);
                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 10),
                                              decoration: BoxDecoration(
                                                color: background,
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                                border: Border.all(
                                                  color: cat.color,
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: Text(
                                                cat.displayName,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: isSelectedCategory
                                                          ? Colors.white
                                                          : cat.color,
                                                      fontWeight:
                                                          isSelectedCategory
                                                              ? FontWeight.bold
                                                              : FontWeight.w500,
                                                    ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 70),
                Padding(
                  padding: const EdgeInsets.all(16.0),
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
                      const SizedBox(width: 16),
                      Expanded(
                        child: TeamColorButton(
                          text: 'Start',
                          icon: Icons.play_arrow_rounded,
                          color: uiColors[1],
                          onPressed: () {
                            final setup = ref.read(gameSetupProvider.notifier);
                            setup.setRoundTime(_selectedTime);
                            setup.setAllowedSkips(_selectedSkips);

                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => GameScreen(
                                  teamIndex: 0,
                                  roundNumber: 1,
                                  turnNumber: 1,
                                  category: _selectedCategoryId,
                                  zenMode: true,
                                ),
                              ),
                            );
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Center(
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.6,
            ),
      ),
    );
  }

  Widget _buildOptionsWrap<T>({
    required List<T> options,
    required bool Function(T) isSelected,
    required String Function(T) labelBuilder,
    required Color color,
    required void Function(T) onTap,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      runAlignment: WrapAlignment.center,
      children: options.map((opt) {
        final selected = isSelected(opt);
        return Builder(
          builder: (context) {
            final Color baseBg = Theme.of(context).colorScheme.background;
            final double overlayAlpha = selected ? 0.6 : 0.2;
            final Color background =
                Color.alphaBlend(color.withOpacity(overlayAlpha), baseBg);
            return GestureDetector(
              onTap: () => onTap(opt),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: color,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  labelBuilder(opt),
                  style: TextStyle(
                    color: selected ? Colors.white : color,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}
