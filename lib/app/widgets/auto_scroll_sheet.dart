import 'package:flutter/material.dart';
import 'package:my_quran/app/settings_controller.dart';

class AutoScrollSheet extends StatefulWidget {
  const AutoScrollSheet({
    required this.settingsController,
    required this.isAutoScrolling,
    required this.onToggleAutoScroll,
    super.key,
  });

  final SettingsController settingsController;
  final bool isAutoScrolling;
  final VoidCallback onToggleAutoScroll;

  @override
  State<AutoScrollSheet> createState() => _AutoScrollSheetState();
}

class _AutoScrollSheetState extends State<AutoScrollSheet> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isScrolling = widget.isAutoScrolling;
    final intervalMs = widget.settingsController.autoScrollIntervalMs;
    final seconds = intervalMs ~/ 1000;

    // Map 60s (Slow / Right) to 5 and 5s (Fast / Left) to 60
    final sliderVal = ((65000 - intervalMs) / 1000).clamp(5.0, 60.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header title & live speed
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$seconds ثانية / صفحة',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Speed Slider
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'سرعة التمرير',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Slider(
                value: sliderVal,
                min: 5,
                max: 60,
                divisions: 55,
                onChanged: (v) {
                  final newMs = ((65 - v) * 1000).round();
                  widget.settingsController.autoScrollIntervalMs = newMs;
                  setState(() {});
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'بطيء جداً (60ث)',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'سريع (5ث)',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Big Play/Pause Start Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: () {
                widget.onToggleAutoScroll();
                setState(() {});
              },
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
                isScrolling ? 'إيقاف التمرير' : 'بدء التمرير التلقائي',
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
