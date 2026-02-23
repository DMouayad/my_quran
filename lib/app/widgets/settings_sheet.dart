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

    return ListenableBuilder(
      listenable: Listenable.merge([fontController, settingsController]),
      builder: (context, _) {
        final isWarsh = settingsController.fontFamily == FontFamily.warsh;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // --- 1. FONT SIZE ---
            _buildSectionTitle('حجم الخط'),
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: fontController.decreaseFontSize,
                    icon: const Icon(Icons.remove),
                  ),
                  Expanded(
                    child: Text(
                      fontController.fontSize.round().toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: FontFamily.arabicNumbersFontFamily.name,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: fontController.increaseFontSize,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // --- 1b. LINE HEIGHT ---
            _buildSectionTitle('ارتفاع الأسطر'),
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: fontController.isAtMinLineHeight
                        ? null
                        : fontController.decreaseLineHeight,
                    icon: const Icon(Icons.density_large),
                  ),
                  Expanded(
                    child: Text(
                      fontController.lineHeight.toStringAsFixed(1),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: FontFamily.arabicNumbersFontFamily.name,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: fontController.isAtMaxLineHeight
                        ? null
                        : fontController.increaseLineHeight,
                    icon: const Icon(Icons.density_small),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- 2. NARRATION ---
            _buildSectionTitle('الرواية'),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                segments: [
                  const ButtonSegment(value: false, label: Text('حفص عن عاصم')),
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
                  await Future<void>.delayed(const Duration(milliseconds: 300));
                  final newFont = settingsController.fontFamily;
                  await Quran.useDatasourceForFont(newFont);
                  unawaited(SearchService.init(newFont.name));
                },
              ),
            ),
            const SizedBox(height: 24),

            // --- 3. FONT TYPE (Hafs only) ---
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
              const SizedBox(height: 16),
            ],

            // --- 4. FONT WEIGHT ---
            if (settingsController.fontFamily != FontFamily.rustam) ...[
              _buildSectionTitle('سماكة الخط'),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<FontWeight>(
                  segments: const [
                    ButtonSegment(value: FontWeight.w500, label: Text('عادي')),
                    ButtonSegment(value: FontWeight.w600, label: Text('عريض')),
                  ],
                  style: segmentStyle,
                  selected: {settingsController.fontWeight},
                  onSelectionChanged: (newSet) {
                    settingsController.fontWeight = newSet.first;
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            const Divider(),

            // --- 5. GENERAL SETTINGS ---
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'استخدام اللون الأسود',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('للشاشات من نوع AMOLED (توفير البطارية)'),
              value: settingsController.useTrueBlackBgColor,
              activeThumbColor: colorScheme.primary,
              onChanged: (v) => settingsController.useTrueBlackBgColor = v,
            ),

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
                'إبقاء الشاشة فعّالة',
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
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(fontFamily: FontFamily.hafs.name, fontSize: 16),
      ),
    );
  }
}
