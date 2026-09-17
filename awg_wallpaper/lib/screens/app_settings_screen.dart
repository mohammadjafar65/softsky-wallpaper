import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/theme_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/auto_wallpaper_provider.dart';
import '../widgets/rating_dialog.dart';
import 'auto_wallpaper_settings_screen.dart';
import 'subscription_screen.dart';
import 'contact_us_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_conditions_screen.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final autoWallpaperProvider = Provider.of<AutoWallpaperProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AppTheme.getBackground(isDark),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.getSurface(isDark).withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            // Settings List
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                children: [
                  // Preferences Section
                  _buildSectionHeader('Preferences'),
                  _buildCard(
                    isDark: isDark,
                    children: [
                      // Dark Mode Switch
                      ListTile(
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.indigo.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.dark_mode_rounded,
                            color: Colors.indigoAccent,
                            size: 20,
                          ),
                        ),
                        title: const Text(
                          'Dark Mode',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          themeProvider.isDarkMode ? 'Enabled' : 'Disabled',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                        trailing: Switch.adaptive(
                          value: themeProvider.isDarkMode,
                          activeThumbColor: AppTheme.primary,
                          activeTrackColor: AppTheme.primary.withValues(alpha: 0.5),
                          onChanged: (val) {
                            themeProvider.setDarkMode(val);
                          },
                        ),
                      ),
                      const Divider(height: 1, indent: 64, color: Colors.white12),

                      // Notifications Switch
                      ListTile(
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: Colors.amberAccent,
                            size: 20,
                          ),
                        ),
                        title: const Text(
                          'Notifications',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          _notificationsEnabled ? 'Wallpaper updates' : 'Muted',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                        trailing: Switch.adaptive(
                          value: _notificationsEnabled,
                          activeThumbColor: AppTheme.primary,
                          activeTrackColor: AppTheme.primary.withValues(alpha: 0.5),
                          onChanged: (val) {
                            setState(() => _notificationsEnabled = val);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Automation Section
                  _buildSectionHeader('Automation'),
                  _buildCard(
                    isDark: isDark,
                    children: [
                      ListTile(
                        onTap: () {
                          if (subscriptionProvider.isPro) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AutoWallpaperSettingsScreen(),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SubscriptionScreen(),
                              ),
                            );
                          }
                        },
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: AppTheme.primary,
                            size: 20,
                          ),
                        ),
                        title: Row(
                          children: [
                            const Text(
                              'Auto Wallpaper',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (!subscriptionProvider.isPro)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.gold,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'PRO',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          subscriptionProvider.isPro
                              ? (autoWallpaperProvider.isEnabled
                                  ? 'Active • ${autoWallpaperProvider.getIntervalName(autoWallpaperProvider.interval)}'
                                  : 'Configure automatic rotation')
                              : 'PRO Feature - Upgrade to unlock',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white54,
                          size: 22,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Storage Section
                  _buildSectionHeader('Storage & Cache'),
                  _buildCard(
                    isDark: isDark,
                    children: [
                      ListTile(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Temporary cache cleared successfully!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.cleaning_services_rounded,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                        ),
                        title: const Text(
                          'Clear Cache',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          'Free up offline storage space',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.white54,
                          size: 20,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Support & Legal
                  _buildSectionHeader('Support & Legal'),
                  _buildCard(
                    isDark: isDark,
                    children: [
                      ListTile(
                        onTap: () => showDialog(
                          context: context,
                          builder: (_) => const RatingDialog(),
                        ),
                        leading: _buildIcon(Icons.star_outline_rounded, Colors.orange),
                        title: const Text('Rate App', style: _itemStyle),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                      ),
                      const Divider(height: 1, indent: 64, color: Colors.white12),
                      ListTile(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ContactUsScreen()),
                        ),
                        leading: _buildIcon(Icons.mail_outline_rounded, Colors.cyan),
                        title: const Text('Contact Us', style: _itemStyle),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                      ),
                      const Divider(height: 1, indent: 64, color: Colors.white12),
                      ListTile(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                        ),
                        leading: _buildIcon(Icons.privacy_tip_outlined, Colors.green),
                        title: const Text('Privacy Policy', style: _itemStyle),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                      ),
                      const Divider(height: 1, indent: 64, color: Colors.white12),
                      ListTile(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TermsConditionsScreen()),
                        ),
                        leading: _buildIcon(Icons.description_outlined, Colors.purple),
                        title: const Text('Terms of Service', style: _itemStyle),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Version tag
                  Center(
                    child: Text(
                      'SoftSky Version 3.0.23',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const TextStyle _itemStyle = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w600,
    fontSize: 15,
  );

  Widget _buildIcon(IconData icon, Color color) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildCard({required bool isDark, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}
