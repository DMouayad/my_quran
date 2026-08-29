part of 'settings_screen.dart';

class GeneralSettings extends StatelessWidget {
  const GeneralSettings({required this.settingsController, super.key});

  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    final hizbHidden = settingsController.hizbDisplay.isHidden;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
      ],
    );
  }
}
