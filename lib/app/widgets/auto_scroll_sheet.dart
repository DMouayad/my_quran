import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_quran/app/settings_controller.dart';
import 'package:my_quran/app/utils.dart';

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

  static const int minPpm = 1;
  static const int maxPpm = 12;
  static const List<int> quickPresets = [1, 2, 4, 8, 12];

  int _ppmFor(int intervalMs) =>
      (60000 / intervalMs).round().clamp(minPpm, maxPpm);

  void _setPpm(int ppm) {
    HapticFeedback.selectionClick();
    settingsController.autoScrollIntervalMs = 60000 ~/ ppm;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ppm = _ppmFor(settingsController.autoScrollIntervalMs);

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
              color: colorScheme.onSurfaceVariant.applyOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
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
          const SizedBox(height: 28),

          // Primary control: slider for fast, spatial speed adjustment
          Row(
            children: [
              Icon(
                Icons.slow_motion_video_outlined,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    value: ppm.toDouble(),
                    min: minPpm.toDouble(),
                    max: maxPpm.toDouble(),
                    divisions: maxPpm - minPpm,
                    label: '$ppm',
                    onChanged: (v) => _setPpm(v.round()),
                  ),
                ),
              ),
              Icon(
                Icons.fast_forward_outlined,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Secondary control: one-tap common speeds
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              for (final p in quickPresets)
                ChoiceChip(
                  label: Text('$p'),
                  selected: ppm == p,
                  onSelected: (_) => _setPpm(p),
                ),
            ],
          ),
          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: onToggleAutoScroll,
              style: FilledButton.styleFrom(
                backgroundColor: isAutoScrolling
                    ? colorScheme.errorContainer
                    : colorScheme.primary,
                foregroundColor: isAutoScrolling
                    ? colorScheme.onErrorContainer
                    : colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: Icon(
                isAutoScrolling
                    ? Icons.pause_circle_filled_outlined
                    : Icons.play_circle_filled_outlined,
              ),
              label: Text(
                isAutoScrolling ? 'إيقاف' : 'بدء',
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
