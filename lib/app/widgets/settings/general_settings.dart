part of 'settings_screen.dart';

class GeneralSettings extends StatelessWidget {
  const GeneralSettings({required this.settingsController, super.key});

  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    final hizbHidden = settingsController.hizbDisplay.isHidden;
    final isWarsh = settingsController.fontFamily == FontFamily.warsh;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                    onSelectionChanged: settingsController.isSwitchingDataset
                        ? null
                        : (newSet) => _switchDataset(
                            context,
                            settingsController,
                            newSet.first ? FontFamily.warsh : FontFamily.hafs,
                          ),
                  ),
                  if (settingsController.isSwitchingDataset) ...[
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
            ),
          ],
        ),
        SettingsGroup(
          title: 'طريقة القراءة',
          children: [
            _ToggleRow(
              icon: Icons.swipe,
              title: 'وضع الكتاب',
              subtitle: 'تقليب الصفحات بالسحب يميناً ويساراً',
              value: settingsController.isHorizontalScrolling,
              onChanged: (v) => settingsController.isHorizontalScrolling = v,
            ),
            _ToggleRow(
              icon: Icons.lightbulb_outline,
              title: 'إبقاء الشاشة مضاءة',
              subtitle: 'منع انطفاء الشاشة أثناء القراءة',
              value: settingsController.keepScreenOn,
              onChanged: (_) => settingsController.toggleKeepScreenOn(),
            ),
          ],
        ),
        SettingsGroup(
          title: 'الشريط المُثبت',
          children: [
            _ToggleRow(
              icon: Icons.numbers_outlined,
              title: 'عرض رقم الحزب',
              subtitle: 'يظهر رقم الحزب بدلاً من رقم الجزء في الشريط المُثبت',
              value: !hizbHidden,
              onChanged: (displayed) =>
                  settingsController.hizbDisplay = displayed
                  ? HizbDisplay.replaceJuzWithQuarter
                  : HizbDisplay.hidden,
            ),
            _ToggleRow(
              enabled: !hizbHidden,
              icon: Icons.hide_source,
              title: 'إخفاء رقم الربع',
              subtitle: 'إظهار رقم الحزب فقط دون تقسيمه إلى أرباع',
              value: !settingsController.hizbDisplay.withQuarter,
              onChanged: (hidden) => settingsController.hizbDisplay = hidden
                  ? HizbDisplay.replaceJuz
                  : HizbDisplay.replaceJuzWithQuarter,
            ),
          ],
        ),
        SettingsGroup(
          title: 'التمرير التلقائي',
          children: [
            ListenableBuilder(
              listenable: settingsController,
              builder: (context, _) {
                final isHorizontal = settingsController.isHorizontalScrolling;
                final isScrolling = settingsController.autoScrollEnabled;
                return _ToggleRow(
                  icon: isScrolling
                      ? Icons.pause_circle_filled_outlined
                      : Icons.keyboard_double_arrow_down_outlined,
                  title: 'التمرير التلقائي',
                  subtitle: isHorizontal
                      ? 'يتطلب الوضع العمودي'
                      : isScrolling
                      ? 'قيد التشغيل — اضغط لإيقاف'
                      : 'متوقف — اضغط للبدء',
                  value: isScrolling && !isHorizontal,
                  enabled: !isHorizontal,
                  onChanged: (_) {
                    settingsController.autoScrollEnabled = !isScrolling;
                  },
                );
              },
            ),
            ListenableBuilder(
              listenable: settingsController,
              builder: (context, _) {
                final interval = settingsController.autoScrollIntervalMs;
                final ppm = (60000 / interval).round().clamp(1, 12);
                return _StepperRow(
                  label: 'السرعة',
                  icon: Icons.speed_outlined,
                  value: '$ppm ص/د',
                  isDefault: ppm == 4,
                  onReset: () =>
                      settingsController.autoScrollIntervalMs = 15000,
                  onDecrease: ppm <= 1
                      ? null
                      : () => settingsController.autoScrollIntervalMs =
                            60000 ~/ (ppm - 1),
                  onIncrease: ppm >= 12
                      ? null
                      : () => settingsController.autoScrollIntervalMs =
                            60000 ~/ (ppm + 1),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
