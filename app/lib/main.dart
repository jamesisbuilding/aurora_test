import 'package:aurora_test/di/service_locator.dart';
import 'package:aurora_test/firebase_options.dart';
import 'package:design_system/design_system.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_navigation/app_router.dart';
import 'theme/theme_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await configureDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = serviceLocator.get<ThemeNotifier>();
    return ListenableBuilder(
      listenable: themeNotifier,
      builder: (context, _) => MaterialApp.router(
        title: 'Aurora Demo',
        debugShowCheckedModeBanner: false,
        // showPerformanceOverlay: true,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeNotifier.themeMode,
        routerConfig: appRouter,
      ),
    );
  }
}
