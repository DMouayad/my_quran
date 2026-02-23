import 'package:flutter/material.dart';
import 'package:my_quran/app/models.dart';
import 'package:my_quran/app/settings_controller.dart';
import 'package:my_quran/app/utils.dart';

class ThemePickerDialog extends StatelessWidget {
  const ThemePickerDialog({required this.settingsController, super.key});
  final SettingsController settingsController;
  static const List<({IconData icon, String label, AppTheme theme})> _themes = [
    (theme: AppTheme.light, label: 'فاتح', icon: Icons.light_mode_outlined),
    (theme: AppTheme.dark, label: 'داكن', icon: Icons.dark_mode_outlined),
    (theme: AppTheme.classic, label: 'كلاسيكي', icon: Icons.contrast),
    (theme: AppTheme.amoled, label: 'أسود', icon: Icons.brightness_2_outlined),
    (theme: AppTheme.sepia, label: 'سيبيا', icon: Icons.auto_stories_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'المظهر',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListenableBuilder(
                listenable: settingsController,
                builder: (context, _) {
                  return Wrap(
                    spacing: 3,
                    runSpacing: 3,
                    children: [
                      for (int i = 0; i < _themes.length; i++) ...[
                        _buildThemeOption(
                          context,
                          theme: _themes[i].theme,
                          label: _themes[i].label,
                          icon: _themes[i].icon,
                          isSelected:
                              settingsController.appTheme == _themes[i].theme,
                          colors: previewColorsForTheme(
                            context,
                            _themes[i].theme,
                          ),
                          onTap: () {
                            settingsController.appTheme = _themes[i].theme;
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required AppTheme theme,
    required String label,
    required IconData icon,
    required bool isSelected,
    required ({Color bg, Color text}) colors,
    required VoidCallback onTap,
  }) {
    final selectedColor = Theme.of(context).colorScheme.primary;
    final previewBg = colors.bg == Colors.transparent
        ? Theme.of(context).colorScheme.surface
        : colors.bg;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        width: 80,
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: previewBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? selectedColor : Colors.grey.applyOpacity(0.3),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedColor.applyOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: colors.text),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: colors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
