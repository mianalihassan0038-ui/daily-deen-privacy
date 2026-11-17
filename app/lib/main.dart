import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_state.dart';
import 'core/theme.dart';
import 'screens/onboarding_screen.dart';
import 'screens/shell.dart';
import 'screens/splash_screen.dart';
import 'services/notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = await AppState.load();
  final notifications = NotificationService.instance;
  state.onScheduleChanged = (s) => notifications.reschedule(s);
  runApp(DailyDeenApp(state: state));
  // Set up reminders after the first frame so startup stays fast.
  await notifications.init();
  if (state.settings.onboarded && state.settings.notifications) {
    await notifications.requestPermission();
  }
  await notifications.reschedule(state);
}

/// Background entry point started by the native RescheduleReceiver after
/// BOOT_COMPLETED, TIMEZONE_CHANGED, TIME_SET or an app update. It loads the
/// saved data (read only: records are never changed here), recalculates prayer
/// times for the current zone and replaces all scheduled reminders.
@pragma('vm:entry-point')
Future<void> backgroundReschedule(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final state = await AppState.load();
    final action = args.isEmpty ? '' : args.first;
    final clockChange = action.endsWith('TIMEZONE_CHANGED') || action.endsWith('TIME_SET');
    if (clockChange && !state.settings.autoTimezone) {
      await const MethodChannel('dailydeen/bg').invokeMethod<void>('done');
      return;
    }
    final notifications = NotificationService.instance;
    await notifications.init();
    await notifications.reschedule(state);
  } catch (e) {
    debugPrint('Background reschedule failed: $e');
  }
  try {
    await const MethodChannel('dailydeen/bg').invokeMethod<void>('done');
  } catch (_) {}
}

class DailyDeenApp extends StatelessWidget {
  final AppState state;
  final bool showSplash;
  const DailyDeenApp({super.key, required this.state, this.showSplash = true});

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
            theme: buildTheme(Brightness.light, urdu: urdu),
            darkTheme: buildTheme(Brightness.dark, urdu: urdu),
            themeMode: state.settings.themeMode,
            locale: urdu ? const Locale('ur') : const Locale('en'),
            supportedLocales: const [Locale('en'), Locale('ur')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: RootGate(showSplash: showSplash),
          );
        },
      ),
    );
  }
}

/// Splash -> Onboarding (first launch) -> main app.
class RootGate extends StatefulWidget {
  final bool showSplash;
  const RootGate({super.key, this.showSplash = true});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  late bool _splash = widget.showSplash;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    Widget child;
    if (_splash) {
      child = SplashScreen(key: const ValueKey('splash'), onDone: () => setState(() => _splash = false));
    } else if (!state.settings.onboarded) {
      child = const OnboardingScreen(key: ValueKey('onboarding'));
    } else {
      child = const AppShell(key: ValueKey('shell'));
    }
    return AnimatedSwitcher(duration: const Duration(milliseconds: 450), child: child);
  }
}
