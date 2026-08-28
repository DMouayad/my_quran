part of 'settings_screen.dart';

class GeneralSettings extends StatelessWidget {
  const GeneralSettings({required this.settingsController, super.key});

  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ToggleRow(
          icon: Icons.swipe,
          title: 'وضع الكتاب',
          subtitle: 'تقليب الصفحات بالسحب يميناً ويساراً',
          value: settingsController.isHorizontalScrolling,
          onChanged: (v) => settingsController.isHorizontalScrolling = v,
        ),
        const Divider(),
        _ToggleRow(
          icon: Icons.lightbulb_outline,
          title: 'إبقاء الشاشة مضاءة',
          subtitle: 'منع انطفاء الشاشة أثناء القراءة',
          value: settingsController.keepScreenOn,
          onChanged: (_) => settingsController.toggleKeepScreenOn(),
        ),
        const Divider(),
        _ToggleRow(
          icon: Icons.numbers_outlined,
          title: 'عرض رقم الحزب',
          subtitle:
              'يظهر رقم الحزب بدلاً من '
              'رقم الجزء في الشريط المُثبت.',
          value: !settingsController.hizbDisplay.isHidden,
          onChanged: (displayed) => settingsController.hizbDisplay = displayed
              ? HizbDisplay.replaceJuzWithQuarter
              : HizbDisplay.hidden,
        ),
        const Divider(),
        _ToggleRow(
          enabled: !settingsController.hizbDisplay.isHidden,
          icon: Icons.hide_source,
          title: 'إخفاء رقم الربع',
          value: !settingsController.hizbDisplay.withQuarter,
          onChanged: (hidden) => settingsController.hizbDisplay = hidden
              ? HizbDisplay.replaceJuz
              : HizbDisplay.replaceJuzWithQuarter,
        ),
      ],
    );
  }
}
