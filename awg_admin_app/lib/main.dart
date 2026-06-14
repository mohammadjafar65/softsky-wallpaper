import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'services/auth_service.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
    };
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    try {
      await AuthService.init();
    } catch (e) {
      debugPrint('Failed to restore admin session: $e');
    }
    runApp(const AdminApp());
  }, (error, stack) {
    debugPrint('Uncaught app error: $error');
  });
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SoftSky Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
