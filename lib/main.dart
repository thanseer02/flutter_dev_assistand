import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'injection_container.dart' as di;
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/core_ui/presentation/providers/layout_provider.dart';
import 'features/project/presentation/providers/project_provider.dart';
import 'features/project/data/services/project_service.dart';

late SharedPreferences prefs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependency injection
  await di.init();

  // Initialize SharedPreferences
  prefs = await SharedPreferences.getInstance();

  // Initialize desktop window manager
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 800),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const FlutterDevAssistantApp());
}

class FlutterDevAssistantApp extends StatelessWidget {
  const FlutterDevAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LayoutProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider(ProjectService(), prefs)),
        // Add other providers here later from DI
      ],
      child: MaterialApp.router(
        title: 'Flutter Dev Assistant',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
