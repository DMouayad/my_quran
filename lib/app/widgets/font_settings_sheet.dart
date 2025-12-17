import 'package:flutter/material.dart';

import 'package:my_quran/app/font_size_controller.dart';

class MinimalFontSizeControl extends StatelessWidget {
  const MinimalFontSizeControl({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      barrierColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      builder: (context) => const MinimalFontSizeControl(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fontController = FontSizeController();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: colorScheme.outlineVariant.withOpacity(0.2),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: ListenableBuilder(
              listenable: fontController,
              builder: (context, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 50,
                      width: 250,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton.filledTonal(
                            onPressed: fontController.increaseFontSize,
                            icon: const Icon(Icons.add),
                          ),
                          Expanded(
                            child: Text(
                              '${fontController.fontSize.round()}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          IconButton.filledTonal(
                            onPressed: fontController.decreaseFontSize,
                            icon: const Icon(Icons.remove),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.save, size: 18),
                        label: const Text(
                          'حفظ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
