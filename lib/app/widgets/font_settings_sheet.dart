import 'package:flutter/material.dart';

import 'package:my_quran/app/models.dart';
import 'package:my_quran/app/settings_controller.dart';
import 'package:my_quran/app/font_size_controller.dart';

class FontSettingsSheet extends StatelessWidget {
  const FontSettingsSheet({required this.settingsController, super.key});

  final SettingsController settingsController;

  static void show(
    BuildContext context,
    SettingsController settingsController,
  ) {
    showModalBottomSheet(
      context: context,
      barrierColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          FontSettingsSheet(settingsController: settingsController),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fontController = FontSizeController();

    return DefaultTextStyle(
      style: TextStyle(
        fontFamily: FontFamily.hafs.name,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurfaceVariant,
      ),
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: ListenableBuilder(
            listenable: Listenable.merge([fontController, settingsController]),
            builder: (context, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 64,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('حجم الخط'),
                        const Spacer(),
                        IconButton.filled(
                          onPressed: fontController.decreaseFontSize,
                          icon: const Icon(Icons.remove),
                        ),
                        Expanded(
                          child: Text(
                            fontController.fontSize.round().toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              fontFamily:
                                  FontFamily.arabicNumbersFontFamily.name,
                            ),
                          ),
                        ),
                        IconButton.filled(
                          onPressed: fontController.increaseFontSize,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('نوع الخط'),
                      SegmentedButton<FontFamily>(
                        segments: const [
                          ButtonSegment(
                            value: FontFamily.hafs,
                            label: Text('حفص'),
                          ),
                          ButtonSegment(
                            value: FontFamily.rustam,
                            label: Text('المدينة'),
                          ),
                        ],
                        style: ButtonStyle(
                          textStyle: WidgetStatePropertyAll(
                            TextStyle(fontFamily: FontFamily.hafs.name),
                          ),
                          foregroundColor: WidgetStateColor.resolveWith((
                            states,
                          ) {
                            if (states.contains(WidgetState.selected)) {
                              return colorScheme.onPrimary;
                            }
                            return colorScheme.onSurfaceVariant;
                          }),
                          backgroundColor: WidgetStateColor.resolveWith((
                            states,
                          ) {
                            if (states.contains(WidgetState.selected)) {
                              return colorScheme.primary;
                            }
                            return colorScheme.surfaceContainer;
                          }),
                          side: WidgetStatePropertyAll(
                            BorderSide(color: colorScheme.primary),
                          ),
                        ),
                        selected: {settingsController.fontFamily},
                        onSelectionChanged: (newSelection) {
                          settingsController.fontFamily = newSelection.first;
                        },
                      ),
                    ],
                  ),
                  if (settingsController.fontFamily == FontFamily.hafs) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('سماكة الخط'),
                        SegmentedButton<FontWeight>(
                          segments: const [
                            ButtonSegment(
                              value: FontWeight.w500,
                              label: Text('عادي'),
                            ),
                            ButtonSegment(
                              value: FontWeight.w600,
                              label: Text('عريض'),
                            ),
                          ],
                          style: ButtonStyle(
                            textStyle: WidgetStatePropertyAll(
                              TextStyle(fontFamily: FontFamily.hafs.name),
                            ),
                            foregroundColor: WidgetStateColor.resolveWith((
                              states,
                            ) {
                              if (states.contains(WidgetState.selected)) {
                                return colorScheme.onPrimary;
                              }
                              return colorScheme.onSurfaceVariant;
                            }),
                            backgroundColor: WidgetStateColor.resolveWith((
                              states,
                            ) {
                              if (states.contains(WidgetState.selected)) {
                                return colorScheme.primary;
                              }
                              return colorScheme.surfaceContainer;
                            }),
                            side: WidgetStatePropertyAll(
                              BorderSide(color: colorScheme.primary),
                            ),
                          ),
                          selected: {settingsController.fontWeight},
                          onSelectionChanged: (newSelection) {
                            settingsController.fontWeight = newSelection.first;
                          },
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 34),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
