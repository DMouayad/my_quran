import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_quran/app/settings_controller.dart';

class AutoScrollSheet extends StatelessWidget {
  const AutoScrollSheet({
    required this.settingsController,
    required this.isAutoScrolling,
    required this.onToggleAutoScroll,
    super.key,
  });

  final SettingsController settingsController;
  final bool isAutoScrolling;
  final VoidCallback onToggleAutoScroll;

  static const List<int> quickPresets = [1, 2, 4, 8, 12];

  int _ppmFor(int intervalMs) {
    final ppm = (60000 / intervalMs).round();
    return ppm.clamp(1, 12);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isScrolling = isAutoScrolling;
    final intervalMs = settingsController.autoScrollIntervalMs;
    final ppm = _ppmFor(intervalMs);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.keyboard_double_arrow_down_outlined,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'التمرير التلقائي',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$ppm ص/د',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 34),

          // Quick presets
          Container(
            height: 54,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: ppm <= 1
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          settingsController.autoScrollIntervalMs =
                              60000 ~/ (ppm - 1);
                        },
                  icon: Icon(
                    Icons.remove,
                    size: 18,
                    color: ppm <= 1
                        ? colorScheme.onSurface.withValues(alpha: 0.25)
                        : colorScheme.onSurface,
                  ),
                ),
                Expanded(
                  child: Text(
                    '$ppm صفحة / دقيقة',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: ppm >= 12
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          settingsController.autoScrollIntervalMs =
                              60000 ~/ (ppm + 1);
                        },
                  icon: Icon(
                    Icons.add,
                    size: 18,
                    color: ppm >= 12
                        ? colorScheme.onSurface.withValues(alpha: 0.25)
                        : colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Stepper like font size
          Wrap(
            spacing: 8,
            children: [
              for (final p in quickPresets)
                ChoiceChip(
                  label: Text('$p'),
                  selected: ppm == p,
                  onSelected: (_) {
                    HapticFeedback.selectionClick();
                    settingsController.autoScrollIntervalMs = 60000 ~/ p;
                  },
                ),
            ],
          ),
          const SizedBox(height: 34),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: onToggleAutoScroll,
              style: FilledButton.styleFrom(
                backgroundColor: isScrolling
                    ? colorScheme.errorContainer
                    : colorScheme.primary,
                foregroundColor: isScrolling
                    ? colorScheme.onErrorContainer
                    : colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: Icon(
                isScrolling
                    ? Icons.pause_circle_filled_outlined
                    : Icons.play_circle_filled_outlined,
              ),
              label: Text(
                isScrolling ? 'إيقاف' : 'بدء',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
