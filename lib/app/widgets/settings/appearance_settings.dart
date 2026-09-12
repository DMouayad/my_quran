part of 'settings_screen.dart';

class AppearanceSettings extends StatefulWidget {
  const AppearanceSettings({
    required this.fontController,
    required this.settingsController,
    super.key,
  });

  final SettingsController settingsController;
  final FontSizeController fontController;

  @override
  State<AppearanceSettings> createState() => _AppearanceSettingsState();
}

class _AppearanceSettingsState extends State<AppearanceSettings> {
  /// True while a riwaya/font dataset swap is in flight. Disables the
  /// switchers so rapid taps can't stack concurrent loads (the data layer
  /// in `Quran._applyFont` is also token-guarded; this is the UI half).
  bool _isSwitchingDataset = false;

  SettingsController get settingsController => widget.settingsController;
  FontSizeController get fontController => widget.fontController;

  /// Loads the dataset for [next] first and only then flips/persists the
  /// font, so the selected font never points at not-yet-loaded data (not
  /// even if the app is killed mid-switch). On failure the old font is
  /// simply kept and a notice is shown — nothing to revert.
  Future<void> _switchDataset(FontFamily next, {required bool isRiwaya}) async {
    if (_isSwitchingDataset) return;
    if (next == settingsController.fontFamily) return;
    setState(() => _isSwitchingDataset = true);
    try {
      await Quran.instance.useDatasourceForFont(next);
      settingsController.fontFamily = next;
      if (isRiwaya) unawaited(SearchService.init(next.name));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر تحميل الرواية')));
      }
    } finally {
      if (mounted) setState(() => _isSwitchingDataset = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWarsh = settingsController.fontFamily == FontFamily.warsh;
    final showFontWeight = settingsController.fontFamily != FontFamily.rustam;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsGroup(
          title: 'السمة',
          children: [
            _ThemeExpansionRow(settingsController: settingsController),
            _ToggleRow(
              icon: Icons.contrast,
              title: 'خلفية سوداء للوضع الداكن',
              subtitle: 'خلفية سوداء تماماً لشاشات AMOLED',
              value: settingsController.useTrueBlackBgColor,
              onChanged: (v) => settingsController.useTrueBlackBgColor = v,
            ),
          ],
        ),

        SettingsGroup(
          title: 'الخط',
          children: [
            _StepperRow(
              label: 'حجم الخط',
              icon: Icons.format_size,
              value: fontController.fontSize.round().toString(),
              onDecrease: fontController.isAtMinFont
                  ? null
                  : fontController.decreaseFontSize,
              onIncrease: fontController.isAtMaxFont
                  ? null
                  : fontController.increaseFontSize,
            ),
            _StepperRow(
              label: 'ارتفاع الأسطر',
              icon: Icons.height,
              value: fontController.isDefaultLineHeight
                  ? 'تلقائي'
                  : fontController.lineHeight!.toStringAsFixed(1),
              onDecrease: fontController.isAtMinLineHeight
                  ? null
                  : fontController.decreaseLineHeight,
              onIncrease: fontController.isAtMaxLineHeight
                  ? null
                  : fontController.increaseLineHeight,
              onReset: fontController.resetLineHeight,
              isDefault: fontController.isDefaultLineHeight,
            ),
            if (showFontWeight)
              _SegmentedRow(
                label: 'سماكة الخط',
                icon: Icons.format_bold,
                child: SegmentedButton<FontWeight>(
                  segments: const [
                    ButtonSegment(value: FontWeight.w500, label: Text('عادي')),
                    ButtonSegment(value: FontWeight.w600, label: Text('عريض')),
                  ],
                  style: _segmentStyle(context.colorScheme),
                  selected: {settingsController.fontWeight},
                  onSelectionChanged: (newSet) {
                    settingsController.fontWeight = newSet.first;
                  },
                ),
              ),
            if (!isWarsh)
              _SegmentedRow(
                label: 'نوع الخط',
                icon: Icons.type_specimen,
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
                  style: _segmentStyle(context.colorScheme),
                  selected: {settingsController.fontFamily},
                  onSelectionChanged: _isSwitchingDataset
                      ? null
                      : (newSet) => unawaited(
                          _switchDataset(newSet.first, isRiwaya: false),
                        ),
                ),
              ),
          ],
        ),

        SettingsGroup(
          title: 'العرض',
          children: [
            _SegmentedRow(
              label: 'محاذاة النص',
              icon: Icons.format_align_center,
              child: SegmentedButton<TextAlignOption>(
                segments: const [
                  ButtonSegment(
                    value: TextAlignOption.justify,
                    label: Text('متساوي'),
                  ),
                  ButtonSegment(
                    value: TextAlignOption.center,
                    label: Text('وسط'),
                  ),
                  ButtonSegment(
                    value: TextAlignOption.start,
                    label: Text('يمين'),
                  ),
                ],
                style: _segmentStyle(context.colorScheme),
                selected: {settingsController.textAlign},
                onSelectionChanged: (v) =>
                    settingsController.textAlign = v.first,
              ),
            ),
          ],
        ),

        SettingsGroup(
          title: 'الرواية',
          children: [
            _SegmentedRow(
              label: 'اختيار الرواية',
              icon: Icons.record_voice_over_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<bool>(
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
                    style: _segmentStyle(context.colorScheme),
                    selected: {isWarsh},
                    onSelectionChanged: _isSwitchingDataset
                        ? null
                        : (newSet) => unawaited(
                            _switchDataset(
                              newSet.first ? FontFamily.warsh : FontFamily.hafs,
                              isRiwaya: true,
                            ),
                          ),
                  ),
                  if (_isSwitchingDataset) ...[
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ───────────────────────── theme picker ─────────────────────────

String _themeLabel(AppTheme theme) => switch (theme) {
  AppTheme.myQuran => 'قرآني',
  AppTheme.sepia => 'سيبيا',
  AppTheme.dynamic => 'ألوان جهازك',
};

/// Themed row that expands inline to reveal [ThemeTilesPicker].
/// Kept as its own widget (instead of `ExpansionTile` styled ad-hoc)
/// so it visually matches every other row in the group — same leading
/// icon chip, same title/subtitle typography — while still expanding.
class _ThemeExpansionRow extends StatelessWidget {
  const _ThemeExpansionRow({required this.settingsController});

  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return Theme(
      // Kill the default ExpansionTile top/bottom border lines so it
      // blends seamlessly into the surrounding SettingsGroup card.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: const ValueKey('appearance-theme-tile'),
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        leading: const _SettingsIcon(Icons.palette_outlined),
        title: const Text(
          'السمة',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(_themeLabel(settingsController.appTheme)),
        children: [
          ThemeTilesPicker(
            selected: settingsController.appTheme,
            onChanged: (theme) => settingsController.appTheme = theme,
            supportsDynamic: settingsController.supportsDynamicColor,
            deviceLightScheme: settingsController.deviceLightScheme,
          ),
        ],
      ),
    );
  }
}

class ThemeTilesPicker extends StatelessWidget {
  const ThemeTilesPicker({
    required this.selected,
    required this.onChanged,
    required this.supportsDynamic,
    super.key,
    this.deviceLightScheme,
  });

  final AppTheme selected;
  final ValueChanged<AppTheme> onChanged;
  final bool supportsDynamic;
  final ColorScheme? deviceLightScheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ThemeTile(
          title: 'قرآني',
          description: 'المظهر الافتراضي الخاص بتطبيق "قرآني"',
          previewColors: (
            bg: const Color(0xFFFAFDFC),
            accent: const Color(0xFF0F766E),
          ),
          isSelected: selected == AppTheme.myQuran,
          onTap: () => onChanged(AppTheme.myQuran),
        ),
        _ThemeTile(
          title: 'سيبيا',
          description: 'ألوان مشابهة للورق، مريحة للعين',
          previewColors: (
            bg: const Color(0xFFF2E7DA),
            accent: const Color(0xFF7A5A3A),
          ),
          isSelected: selected == AppTheme.sepia,
          onTap: () => onChanged(AppTheme.sepia),
        ),
        if (supportsDynamic)
          _ThemeTile(
            title: 'ألوان جهازك',
            description: 'يستخدم ألوان جهازك الشخصية مع التبديل التلقائي',
            previewColors: (
              bg:
                  deviceLightScheme?.primaryContainer ??
                  const Color(0xFFE8DEF8),
              accent: deviceLightScheme?.primary ?? const Color(0xFF6750A4),
            ),
            isSelected: selected == AppTheme.dynamic,
            onTap: () => onChanged(AppTheme.dynamic),
          ),
      ],
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.title,
    required this.description,
    required this.previewColors,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String description;
  final ({Color bg, Color accent}) previewColors;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected
            ? scheme.primaryContainer.applyOpacity(0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? scheme.primary
                    : scheme.outlineVariant.applyOpacity(0.5),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: previewColors.bg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: scheme.outlineVariant,
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: previewColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.3,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: scheme.primary, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
