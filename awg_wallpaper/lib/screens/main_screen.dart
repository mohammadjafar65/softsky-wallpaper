import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_bottom_nav.dart';
import 'home_screen.dart';
import 'packs_screen.dart';
import 'community/community_screen.dart';
import 'bookmarks_screen.dart';
import 'pro_wallpapers_screen.dart';
import '../providers/wallpaper_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1; // 1: Wallpapers / Home by default

  final List<Widget> _screens = const [
    CommunityScreen(), // 0: Collective
    HomeScreen(),      // 1: Wallpapers (Default)
    BookmarksScreen(), // 2: Bookmarks
    PacksScreen(),     // 3: Packs
    ProWallpapersScreen(), // 4: Pro Wallpapers
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          // Bottom bar gradient
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 180,
            child: IgnorePointer(
              child: Image.asset(
                'assets/images/newgradient_bottom.png',
                fit: BoxFit.fill,
                width: double.infinity,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          if (index == 4) {
            context
                .read<WallpaperProvider>()
                .loadProWallpapers(refresh: true, force: true);
          }
        },
      ),
    );
  }
}

