import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_state.dart';
import 'screens/shell.dart';
import 'services/notifications.dart';

const Color brandGreen = Color(0xFF0F7B4A);
const Color brandGold = Color(0xFFC9A227);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = await AppState.load();
  final notifications = NotificationService.instance;
  state.onScheduleChanged = (s) => notifications.reschedule(s);
  runApp(DailyDeenApp(state: state));
  // Set up reminders after the first frame so startup stays fast.
  await notifications.init();
  if (state.settings.notifications || state.settings.tahajjudReminder) {
    await notifications.requestPermission();
  }
  await notifications.reschedule(state);
}

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: brandGreen, brightness: brightness).copyWith(
    primary: brightness == Brightness.light ? brandGreen : const Color(0xFF5FD39A),
    tertiary: brandGold,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: brightness == Brightness.light ? const Color(0xFFF5F8F6) : null,
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: brightness == Brightness.light ? Colors.white : scheme.surfaceContainerHigh,
      margin: EdgeInsets.zero,
    ),
    appBarTheme: const AppBarTheme(centerTitle: false),
  );
}

class DailyDeenApp extends StatelessWidget {
  final AppState state;
  const DailyDeenApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final urdu = state.settings.urdu;
          return MaterialApp(
            title: 'Daily Deen',
            debugShowCheckedModeBanner: false,
            theme: buildTheme(Brightness.light),
            darkTheme: buildTheme(Brightness.dark),
            themeMode: state.settings.themeMode,
            locale: urdu ? const Locale('ur') : const Locale('en'),
            supportedLocales: const [Locale('en'), Locale('ur')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const AppShell(),
          );
        },
      ),
    );
  }
}
