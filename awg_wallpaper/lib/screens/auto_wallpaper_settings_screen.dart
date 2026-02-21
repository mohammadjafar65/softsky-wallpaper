import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../providers/auto_wallpaper_provider.dart';
import '../providers/bookmark_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/auto_wallpaper_service.dart';
import 'subscription_screen.dart';

/// Enhanced Settings screen for Auto Wallpaper features (PRO only)
class AutoWallpaperSettingsScreen extends StatefulWidget {
  const AutoWallpaperSettingsScreen({super.key});

  @override
  State<AutoWallpaperSettingsScreen> createState() =>
      _AutoWallpaperSettingsScreenState();
}

class _AutoWallpaperSettingsScreenState
    extends State<AutoWallpaperSettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Check PRO status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isPro = context.read<SubscriptionProvider>().isPro;
      if (!isPro) {
        // Redirect non-PRO users to subscription screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
        );
        return;
      }
      context.read<AutoWallpaperProvider>().initialize();
    });

    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Consumer<AutoWallpaperProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              // Enhanced background gradient orbs with animation
              Positioned(
                top: -120,
                right: -80,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.purple.withValues(alpha: 0.25),
                          Colors.deepPurple.withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 200,
                left: -100,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.orange.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -60,
                right: -60,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.primary.withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Main content
              SafeArea(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Header
                    SliverToBoxAdapter(
                      child: _buildHeader(context),
                    ),

                    // Auto Wallpaper Section
                    SliverToBoxAdapter(
                      child: _buildAutoWallpaperSection(context, provider),
                    ),

                    // Day/Night Section
                    SliverToBoxAdapter(
                      child: _buildDayNightSection(context, provider),
                    ),

                    // Quick Actions
                    SliverToBoxAdapter(
                      child: _buildQuickActions(context, provider),
                    ),

                    const SliverToBoxAdapter(
                      child: SizedBox(height: 100),
                    ),
                  ],
                ),
              ),

              // Loading overlay
              if (provider.isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.7),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                            color: AppTheme.primary),
                        const SizedBox(height: 16),
                        Text(
                          'Processing...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.darkSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Auto Wallpaper',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.gold, Color(0xFFFFB700)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.gold.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'PRO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Automatically refresh your wallpaper',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoWallpaperSection(
      BuildContext context, AutoWallpaperProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
              '🔄 Auto Change', 'Schedule automatic wallpaper changes'),
          const SizedBox(height: 16),

          // Main toggle card with enhanced glassmorphism
          _buildEnhancedGlassCard(
            child: Column(
              children: [
                // Enable toggle
                _buildEnhancedToggleRow(
                  icon: Icons.auto_awesome_rounded,
                  iconColor: Colors.purple,
                  title: 'Auto Wallpaper',
                  subtitle: provider.isEnabled
                      ? 'Changes ${provider.getIntervalName(provider.interval).toLowerCase()}'
                      : 'Tap to enable automatic changes',
                  value: provider.isEnabled,
                  onChanged: (val) => provider.toggleAutoWallpaper(val),
                  isActive: provider.isEnabled,
                ),

                if (provider.isEnabled) ...[
                  const Divider(
                    color: AppTheme.darkSurfaceVariant,
                    height: 1,
                    thickness: 0.5,
                  ),

                  // Interval selector
                  _buildEnhancedOptionRow(
                    icon: Icons.schedule_rounded,
                    iconColor: Colors.blue,
                    title: 'Change Interval',
                    value: provider.getIntervalName(provider.interval),
                    onTap: () => _showIntervalPicker(context, provider),
                  ),

                  const Divider(
                    color: AppTheme.darkSurfaceVariant,
                    height: 1,
                    thickness: 0.5,
                  ),

                  // Source selector
                  _buildEnhancedOptionRow(
                    icon: Icons.photo_library_rounded,
                    iconColor: Colors.teal,
                    title: 'Wallpaper Source',
                    value: provider.getSourceName(provider.source),
                    onTap: () => _showSourcePicker(context, provider),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayNightSection(
      BuildContext context, AutoWallpaperProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
              '🌙 Smart Day/Night', 'Different wallpapers for day and night'),
          const SizedBox(height: 16),
          _buildEnhancedGlassCard(
            child: Column(
              children: [
                // Enable toggle
                _buildEnhancedToggleRow(
                  icon: Icons.brightness_6_rounded,
                  iconColor: Colors.orange,
                  title: 'Day/Night Mode',
                  subtitle: provider.isDayNightEnabled
                      ? 'Smart wallpaper switching active'
                      : 'Use different wallpapers based on time',
                  value: provider.isDayNightEnabled,
                  onChanged: (val) => provider.toggleDayNightMode(val),
                  isActive: provider.isDayNightEnabled,
                ),

                if (provider.isDayNightEnabled) ...[
                  const Divider(
                    color: AppTheme.darkSurfaceVariant,
                    height: 1,
                    thickness: 0.5,
                  ),

                  // Day wallpaper picker with enhanced UI
                  _buildWallpaperPickerRow(
                    icon: Icons.wb_sunny_rounded,
                    iconColor: Colors.amber,
                    title: 'Day Wallpaper',
                    subtitle: 'Active from ${provider.dayStartHour}:00',
                    imageUrl: provider.dayWallpaperUrl,
                    onTap: () => _pickWallpaper(context, provider, true),
                  ),

                  const Divider(
                    color: AppTheme.darkSurfaceVariant,
                    height: 1,
                    thickness: 0.5,
                  ),

                  // Night wallpaper picker with enhanced UI
                  _buildWallpaperPickerRow(
                    icon: Icons.nightlight_rounded,
                    iconColor: Colors.indigo,
                    title: 'Night Wallpaper',
                    subtitle: 'Active from ${provider.nightStartHour}:00',
                    imageUrl: provider.nightWallpaperUrl,
                    onTap: () => _pickWallpaper(context, provider, false),
                  ),

                  const Divider(
                    color: AppTheme.darkSurfaceVariant,
                    height: 1,
                    thickness: 0.5,
                  ),

                  // Time settings
                  _buildEnhancedOptionRow(
                    icon: Icons.access_time_rounded,
                    iconColor: Colors.purple,
                    title: 'Change Times',
                    value:
                        'Day: ${provider.dayStartHour}:00 • Night: ${provider.nightStartHour}:00',
                    onTap: () => _showTimePicker(context, provider),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(
      BuildContext context, AutoWallpaperProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('⚡ Quick Actions', 'Manual controls'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildEnhancedActionButton(
                  icon: Icons.refresh_rounded,
                  label: 'Change Now',
                  color: AppTheme.primary,
                  onTap: provider.isEnabled
                      ? () async {
                          await provider.changeNow();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Wallpaper changed!'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: AppTheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        }
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildEnhancedActionButton(
                  icon: Icons.stop_rounded,
                  label: 'Stop All',
                  color: Colors.red,
                  onTap: (provider.isEnabled || provider.isDayNightEnabled)
                      ? () async {
                          await provider.cancelAll();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('All schedules cancelled'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        }
                      : null,
                ),
              ),
            ],
          ),
          if (provider.lastChangedAt != null) ...[
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.darkSurfaceVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Last changed: ${_formatDateTime(provider.lastChangedAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedGlassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkSurface.withValues(alpha: 0.8),
            AppTheme.darkSurface.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: child,
        ),
      ),
    );
  }

  Widget _buildEnhancedToggleRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    bool isActive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  iconColor.withValues(alpha: 0.25),
                  iconColor.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: iconColor.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: isActive ? 0.7 : 0.5),
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 1.1,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: iconColor,
              activeTrackColor: iconColor.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedOptionRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    iconColor.withValues(alpha: 0.2),
                    iconColor.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: iconColor.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.3),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWallpaperPickerRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? imageUrl,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    iconColor.withValues(alpha: 0.2),
                    iconColor.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: iconColor.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (imageUrl != null)
              Container(
                width: 50,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: AppTheme.darkSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 50,
                height: 70,
                decoration: BoxDecoration(
                  color: AppTheme.darkSurfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.3),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: iconColor.withValues(alpha: 0.6),
                  size: 24,
                ),
              ),
            const SizedBox(width: 12),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.3),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: isDisabled
              ? null
              : LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.25),
                    color.withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: isDisabled ? AppTheme.darkSurfaceVariant : null,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                isDisabled ? Colors.transparent : color.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: isDisabled
              ? null
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isDisabled ? Colors.white.withValues(alpha: 0.3) : color,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDisabled ? Colors.white.withValues(alpha: 0.3) : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showIntervalPicker(
      BuildContext context, AutoWallpaperProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkSurface,
              AppTheme.darkSurface.withValues(alpha: 0.95),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Change Interval',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              ...ScheduleInterval.values.map((interval) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: provider.interval == interval
                          ? AppTheme.primary.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: provider.interval == interval
                            ? AppTheme.primary.withValues(alpha: 0.3)
                            : Colors.transparent,
                      ),
                    ),
                    child: ListTile(
                      leading: Radio<ScheduleInterval>(
                        value: interval,
                        groupValue: provider.interval,
                        onChanged: (val) {
                          if (val != null) provider.setInterval(val);
                          Navigator.pop(context);
                        },
                        activeColor: AppTheme.primary,
                      ),
                      title: Text(
                        provider.getIntervalName(interval),
                        style: TextStyle(
                          color: provider.interval == interval
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.7),
                          fontWeight: provider.interval == interval
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        provider.setInterval(interval);
                        Navigator.pop(context);
                      },
                    ),
                  )),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showSourcePicker(BuildContext context, AutoWallpaperProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkSurface,
              AppTheme.darkSurface.withValues(alpha: 0.95),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Wallpaper Source',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              ...WallpaperSource.values.map((source) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: provider.source == source
                          ? AppTheme.primary.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: provider.source == source
                            ? AppTheme.primary.withValues(alpha: 0.3)
                            : Colors.transparent,
                      ),
                    ),
                    child: ListTile(
                      leading: Radio<WallpaperSource>(
                        value: source,
                        groupValue: provider.source,
                        onChanged: (val) {
                          if (val != null) provider.setSource(val);
                          Navigator.pop(context);
                        },
                        activeColor: AppTheme.primary,
                      ),
                      title: Text(
                        provider.getSourceName(source),
                        style: TextStyle(
                          color: provider.source == source
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.7),
                          fontWeight: provider.source == source
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        provider.setSource(source);
                        Navigator.pop(context);
                      },
                    ),
                  )),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _pickWallpaper(
      BuildContext context, AutoWallpaperProvider provider, bool isDay) {
    // Show bookmarks to pick from
    final bookmarks = context.read<BookmarkProvider>().bookmarks;

    if (bookmarks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No bookmarked wallpapers. Save some first!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkSurface,
                AppTheme.darkSurface.withValues(alpha: 0.95),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isDay ? Colors.amber : Colors.indigo)
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isDay
                            ? Icons.wb_sunny_rounded
                            : Icons.nightlight_rounded,
                        color: isDay ? Colors.amber : Colors.indigo,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Select ${isDay ? "Day" : "Night"} Wallpaper',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: bookmarks.length,
                  itemBuilder: (context, index) {
                    final wallpaper = bookmarks[index];
                    final isSelected = isDay
                        ? provider.dayWallpaperUrl == wallpaper.thumbnailUrl
                        : provider.nightWallpaperUrl == wallpaper.thumbnailUrl;

                    return GestureDetector(
                      onTap: () {
                        if (isDay) {
                          provider.setDayWallpaper(wallpaper);
                        } else {
                          provider.setNightWallpaper(wallpaper);
                        }
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '${isDay ? "Day" : "Night"} wallpaper set!'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor:
                                isDay ? Colors.amber : Colors.indigo,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? (isDay ? Colors.amber : Colors.indigo)
                                : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color:
                                        (isDay ? Colors.amber : Colors.indigo)
                                            .withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: wallpaper.thumbnailUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: AppTheme.darkSurfaceVariant,
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  color: (isDay ? Colors.amber : Colors.indigo)
                                      .withValues(alpha: 0.3),
                                  child: Center(
                                    child: Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.white,
                                      size: 32,
                                      shadows: const [
                                        Shadow(
                                          color: Colors.black45,
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showTimePicker(BuildContext context, AutoWallpaperProvider provider) {
    int dayHour = provider.dayStartHour;
    int nightHour = provider.nightStartHour;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkSurface,
                AppTheme.darkSurface.withValues(alpha: 0.95),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set Times',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),

                // Day time slider
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.wb_sunny_rounded,
                              color: Colors.amber, size: 24),
                          const SizedBox(width: 12),
                          const Text('Day starts:',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('$dayHour:00',
                                style: const TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                          ),
                        ],
                      ),
                      Slider(
                        value: dayHour.toDouble(),
                        min: 4,
                        max: 10,
                        divisions: 6,
                        activeColor: Colors.amber,
                        onChanged: (val) =>
                            setSheetState(() => dayHour = val.round()),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Night time slider
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.indigo.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.nightlight_rounded,
                              color: Colors.indigo, size: 24),
                          const SizedBox(width: 12),
                          const Text('Night starts:',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.indigo.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('$nightHour:00',
                                style: const TextStyle(
                                    color: Colors.indigo,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                          ),
                        ],
                      ),
                      Slider(
                        value: nightHour.toDouble(),
                        min: 17,
                        max: 22,
                        divisions: 5,
                        activeColor: Colors.indigo,
                        onChanged: (val) =>
                            setSheetState(() => nightHour = val.round()),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      provider.setDayNightTimes(dayHour, nightHour);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Save Times',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
