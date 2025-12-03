import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:my_quran/app/models.dart';
import 'package:my_quran/app/font_size_controller.dart';
import 'package:my_quran/app/pages/home_page.dart';
import 'package:my_quran/app/services/bookmark_service.dart';
import 'package:my_quran/app/services/reading_position_service.dart';
import 'package:my_quran/app/services/search_service.dart';
import 'package:my_quran/app/services/settings_service.dart';
import 'package:my_quran/app/settings_controller.dart';
import 'package:my_quran/quran/quran.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize search index in background
  unawaited(SearchService.init());
  await Quran.initialize();
  await BookmarkService().initialize();
  await FontSizeController().initialize();

  final lastPosition = await ReadingPositionService.loadPosition();
  debugPrint('📱 Last Position: $lastPosition');
  final settingsController = SettingsController(
    settingsService: SettingsService(),
  );
  await settingsController.init();

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
  static const seedColor = Color(0xFF0F766E);
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
          darkTheme: ThemeData(
            fontFamily: settingsController.fontFamily.name,
            colorScheme: ColorScheme.fromSeed(
              brightness: Brightness.dark,
              seedColor: seedColor,
            ),
          ),
          theme: ThemeData(
            fontFamily: settingsController.fontFamily.name,
            colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
          ),
          home: HomePage(
            fontFamily: settingsController.fontFamily,
            themeMode: settingsController.themeMode,
            initialPosition: lastPosition,
            onFontFamilyChange: (v) => settingsController.fontFamily = v,
            onThemeToggle: settingsController.toggleTheme,
          ),
        );
      },
    );
  }
}
