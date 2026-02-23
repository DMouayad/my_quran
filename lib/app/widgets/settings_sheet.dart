import 'dart:async';

import 'package:flutter/material.dart';
import 'package:my_quran/app/font_size_controller.dart';
import 'package:my_quran/app/models.dart';
import 'package:my_quran/app/services/search_service.dart';
import 'package:my_quran/app/settings_controller.dart';
import 'package:my_quran/app/utils.dart';
import 'package:my_quran/quran/quran.dart';

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({
    required this.fontController,
    required this.settingsController,
    super.key,
  });
  final SettingsController settingsController;
  final FontSizeController fontController;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    final segmentStyle = ButtonStyle(
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontWeight: FontWeight.w600),
      ),
      foregroundColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? colorScheme.onPrimary
            : colorScheme.onSurfaceVariant,
      ),
      backgroundColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? colorScheme.primary
            : colorScheme.surfaceContainer,
      ),
      side: WidgetStatePropertyAll(
        BorderSide(color: colorScheme.primary.applyOpacity(0.5)),
      ),
    );

    return DefaultTextStyle(
      style: context.textTheme.bodyMedium!.copyWith(
        color: context.colorScheme.onSurface,
      ),
      child: ListenableBuilder(
        listenable: Listenable.merge([fontController, settingsController]),
        builder: (context, _) {
          final isWarsh = settingsController.fontFamily == FontFamily.warsh;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              // ── FONT SIZE ──
              _buildSectionTitle('حجم الخط'),
              _buildStepperControl(
                colorScheme: colorScheme,
                value: fontController.fontSize.round().toString(),
                onDecrease: fontController.isAtMinFont
                    ? null
                    : fontController.decreaseFontSize,
                onIncrease: fontController.isAtMaxFont
                    ? null
                    : fontController.increaseFontSize,
              ),
              const SizedBox(height: 16),

              // ── LINE HEIGHT ──
              _buildSectionTitle('ارتفاع الأسطر'),
              _buildStepperControl(
                colorScheme: colorScheme,
                value: fontController.lineHeight.toStringAsFixed(1),
                onDecrease: fontController.isAtMinLineHeight
                    ? null
                    : fontController.decreaseLineHeight,
                onIncrease: fontController.isAtMaxLineHeight
                    ? null
                    : fontController.increaseLineHeight,
              ),
              const SizedBox(height: 24),

              // ── THEME ──
              _buildSectionTitle('المظهر'),
              _ReadingThemePicker(
                selected: settingsController.appTheme,
                onChanged: (theme) => settingsController.appTheme = theme,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // ── NARRATION ──
              _buildSectionTitle('الرواية'),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<bool>(
                  segments: [
                    const ButtonSegment(
                      value: false,
                      label: Text('حفص عن عاصم'),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text(
                        'ورش عن نافع',
                        style: TextStyle(fontFamily: FontFamily.warsh.name),
                      ),
                    ),
                  ],
                  style: segmentStyle,
                  selected: {isWarsh},
                  onSelectionChanged: (newSet) async {
                    final selectedWarsh = newSet.first;
                    if (selectedWarsh) {
                      settingsController.fontFamily = FontFamily.warsh;
                    } else {
                      settingsController.fontFamily = FontFamily.hafs;
                    }
                    await Future<void>.delayed(
                      const Duration(milliseconds: 300),
                    );
                    final newFont = settingsController.fontFamily;
                    await Quran.useDatasourceForFont(newFont);
                    unawaited(SearchService.init(newFont.name));
                  },
                ),
              ),
              // ── FONT TYPE (Hafs only) ──
              if (!isWarsh) ...[
                _buildSectionTitle('نوع الخط'),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<FontFamily>(
                    segments: [
                      ButtonSegment(
                        value: FontFamily.hafs,
                        label: Text(
                          'الرسم العثماني',
                          style: TextStyle(fontFamily: FontFamily.hafs.name),
                        ),
                      ),
                      ButtonSegment(
                        value: FontFamily.rustam,
                        label: Text(
                          'خط المدينة',
                          style: TextStyle(fontFamily: FontFamily.rustam.name),
                        ),
                      ),
                    ],
                    style: segmentStyle,
                    selected: {settingsController.fontFamily},
                    onSelectionChanged: (newSet) async {
                      settingsController.fontFamily = newSet.first;
                      await Future<void>.delayed(
                        const Duration(milliseconds: 300),
                      );
                      final newFont = settingsController.fontFamily;
                      if (newFont.isWarsh) {
                        settingsController.fontWeight = FontWeight.normal;
                      }
                      await Quran.useDatasourceForFont(newFont);
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // ── FONT WEIGHT ──
              if (settingsController.fontFamily != FontFamily.rustam) ...[
                _buildSectionTitle('سماكة الخط'),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<FontWeight>(
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
                    style: segmentStyle,
                    selected: {settingsController.fontWeight},
                    onSelectionChanged: (newSet) {
                      settingsController.fontWeight = newSet.first;
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const Divider(),

              // ── GENERAL SETTINGS ──
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'وضع الكتاب',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'يمكنك من تقليب الصفحات بالسحب يميناً ويساراً.',
                ),
                value: settingsController.isHorizontalScrolling,
                activeThumbColor: colorScheme.primary,
                onChanged: (v) => settingsController.isHorizontalScrolling = v,
              ),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'إبقاء الشاشة مضاءة',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('منع الشاشة من الانطفاء أثناء القراءة'),
                value: settingsController.keepScreenOn,
                activeThumbColor: colorScheme.primary,
                onChanged: (_) => settingsController.toggleKeepScreenOn(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 16)),
    );
  }

  Widget _buildStepperControl({
    required ColorScheme colorScheme,
    required String value,
    required VoidCallback? onDecrease,
    required VoidCallback? onIncrease,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          IconButton(onPressed: onDecrease, icon: const Icon(Icons.remove)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: FontFamily.arabicNumbersFontFamily.name,
              ),
            ),
          ),
          IconButton(onPressed: onIncrease, icon: const Icon(Icons.add)),
        ],
      ),
    );
  }
}

class _ReadingThemePicker extends StatelessWidget {
  const _ReadingThemePicker({required this.selected, required this.onChanged});

  final AppTheme selected;
  final ValueChanged<AppTheme> onChanged;

  static const List<({IconData icon, String label, AppTheme theme})> _themes = [
    (theme: AppTheme.light, label: 'فاتح', icon: Icons.light_mode_outlined),
    (theme: AppTheme.dark, label: 'داكن', icon: Icons.dark_mode_outlined),
    (theme: AppTheme.classic, label: 'كلاسيكي', icon: Icons.contrast),
    (theme: AppTheme.amoled, label: 'أسود', icon: Icons.brightness_2_outlined),
    (theme: AppTheme.sepia, label: 'سيبيا', icon: Icons.auto_stories_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedColor = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        for (int i = 0; i < _themes.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _ThemeCard(
              label: _themes[i].label,
              icon: _themes[i].icon,
              previewColors: previewColorsForTheme(context, _themes[i].theme),
              isSelected: selected == _themes[i].theme,
              selectedColor: selectedColor,
              onTap: () => onChanged(_themes[i].theme),
            ),
          ),
        ],
      ],
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.label,
    required this.icon,
    required this.previewColors,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final ({Color bg, Color text}) previewColors;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: previewColors.bg,
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
            Icon(icon, size: 20, color: previewColors.text),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: previewColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
