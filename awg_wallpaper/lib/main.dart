import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:upgrader/upgrader.dart';
import 'config/theme.dart';
import 'providers/wallpaper_provider.dart';
import 'providers/bookmark_provider.dart';
import 'providers/search_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/pack_provider.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox('bookmarks');
  await Hive.openBox('settings');
  await Hive.openBox('cache');

  // Initialize Firebase
  try {
    await Firebase.initializeApp();

    // Initialize notification service
    try {
      await NotificationService().initialize();
      debugPrint('Notification service initialized');
    } catch (e) {
      debugPrint('Notification service init failed: $e');
    }
  } catch (e) {
    debugPrint('Firebase init failed: $e');
    runApp(MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Firebase Initialization Failed',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
    return;
  }

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Prevent screenshots and screen recording (FLAG_SECURE)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const AWGWallpaperApp());
}

class AWGWallpaperApp extends StatelessWidget {
  const AWGWallpaperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WallpaperProvider()),
        ChangeNotifierProvider(create: (_) => BookmarkProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => PackProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          // Update system UI based on theme
          final isDark = themeProvider.isDarkMode;
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
            ),
          );

          return MaterialApp(
            title: 'SoftSky Wallpaper App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: UpgradeAlert(
              upgrader: Upgrader(
                durationUntilAlertAgain: const Duration(hours: 12),
              ),
              child: const SecureApp(child: SplashScreen()),
            ),
          );
        },
      ),
    );
  }
}

// Wrapper to enable screenshot prevention
class SecureApp extends StatefulWidget {
  final Widget child;

  const SecureApp({super.key, required this.child});

  @override
  State<SecureApp> createState() => _SecureAppState();
}

class _SecureAppState extends State<SecureApp> with WidgetsBindingObserver {
  static const platform = MethodChannel('com.awg.wallpaper/secure');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enableSecureFlag();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _enableSecureFlag() async {
    try {
      // Try to invoke native method to set FLAG_SECURE
      await platform.invokeMethod('enableSecureFlag');
    } catch (e) {
      // Platform channel not implemented, will fall back to no-op
      debugPrint('Secure flag not available on this platform');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
