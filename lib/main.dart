import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:my_quran/app/font_size_controller.dart';
import 'package:my_quran/app/models.dart';
import 'package:my_quran/app/pages/home_page.dart';
import 'package:my_quran/app/services/reading_position_service.dart';
import 'package:my_quran/app/services/search_service.dart';
import 'package:my_quran/app/services/settings_service.dart';
import 'package:my_quran/app/settings_controller.dart';
import 'package:my_quran/app/theme.dart';
import 'package:my_quran/app/utils.dart';
import 'package:my_quran/quran/quran.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize search index in background

  final settingsController = SettingsController(
    settingsService: SettingsService(),
  );
  await settingsController.init();

  unawaited(SearchService.init(settingsController.fontFamily.name));

  await Quran.initialize(fontFamily: settingsController.fontFamily);
  await FontSizeController().initialize();

  final lastPosition = await ReadingPositionService.loadPosition();
  debugPrint('📱 Last Position: $lastPosition');

  // FORCE TRANSPARENT STATUS BAR
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Edge-to-Edge mode for Android 10+ (Removes bottom black bar)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(MyApp(lastPosition, settingsController));
}

class MyApp extends StatelessWidget {
  const MyApp(this.lastPosition, this.settingsController, {super.key});
  final ReadingPosition? lastPosition;
  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settingsController,
      builder: (context, child) {
        return MaterialApp(
          title: 'My Quran',
          debugShowCheckedModeBanner: false,
          locale: Locale(settingsController.language),
          supportedLocales: const [Locale('ar')],
          themeMode: settingsController.themeMode,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: buildThemeForAppTheme(settingsController.appTheme).copyWith(
            textTheme: const TextTheme().apply(
              fontFamily: FontFamily.hafs.name,
            ),
          ),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              textTheme: context.textTheme.apply(
                bodyColor: context.colorScheme.onSurface,
                displayColor: context.colorScheme.onSurface,
              ),
            ),
            child: child!,
          ),
          home: HomePage(
            initialPosition: lastPosition,
            settingsController: settingsController,
          ),
        );
      },
    );
  }
}
