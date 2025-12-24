import 'package:flutter/material.dart';
import '../widgets/custom_bottom_nav.dart';
import 'home_screen.dart';
import 'packs_screen.dart';
import 'wide_wallpapers_screen.dart';
import 'bookmarks_screen.dart';
import 'pro_wallpapers_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    PacksScreen(),
    WideWallpapersScreen(),
    BookmarksScreen(),
    ProWallpapersScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
