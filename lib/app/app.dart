import 'package:careconnect_mobile/core/logging/app_logger.dart';
import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:careconnect_mobile/core/theme/theme_controller.dart';
import 'package:careconnect_mobile/features/onboarding/presentation/splash_screen.dart';
import 'package:flutter/material.dart';

class CareConnectApp extends StatefulWidget {
  const CareConnectApp({super.key, this.themeController});

  final ThemeController? themeController;

  @override
  State<CareConnectApp> createState() => _CareConnectAppState();
}

class _CareConnectAppState extends State<CareConnectApp> {
  late final ThemeController _themeController =
      widget.themeController ?? ThemeController();
  late final bool _ownsController = widget.themeController == null;

  @override
  void initState() {
    super.initState();
    _themeController.load();
  }

  @override
  void dispose() {
    if (_ownsController) _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeControllerScope(
      controller: _themeController,
      child: ListenableBuilder(
        listenable: _themeController,
        builder: (context, _) => MaterialApp(
          title: 'CareConnect',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: _themeController.themeMode,
          navigatorObservers: [CareConnectNavigatorObserver()],
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
