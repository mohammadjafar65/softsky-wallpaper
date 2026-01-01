import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../providers/auto_wallpaper_provider.dart';
import '../providers/bookmark_provider.dart';
import '../services/auto_wallpaper_service.dart';

/// Settings screen for Auto Wallpaper features (PRO only)
class AutoWallpaperSettingsScreen extends StatefulWidget {
  const AutoWallpaperSettingsScreen({super.key});

  @override
  State<AutoWallpaperSettingsScreen> createState() =>
      _AutoWallpaperSettingsScreenState();
}

class _AutoWallpaperSettingsScreenState
    extends State<AutoWallpaperSettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AutoWallpaperProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Consumer<AutoWallpaperProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              // Background gradient orbs
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.purple.withOpacity(0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -50,
                left: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.primary.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Main content
              SafeArea(
                child: CustomScrollView(
                  slivers: [
                    // App Bar
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
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.darkSurfaceVariant),
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
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.gold, Color(0xFFFFB700)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'PRO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Automatically change your wallpaper',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.6),
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('🔄 Auto Change', 'Schedule wallpaper changes'),
          const SizedBox(height: 16),

          // Main toggle card
          _buildGlassCard(
            child: Column(
              children: [
                // Enable toggle
                _buildToggleRow(
                  icon: Icons.auto_awesome_rounded,
                  iconColor: Colors.purple,
                  title: 'Auto Wallpaper',
                  subtitle: provider.isEnabled
                      ? 'Changes ${provider.getIntervalName(provider.interval).toLowerCase()}'
                      : 'Disabled',
                  value: provider.isEnabled,
                  onChanged: (val) => provider.toggleAutoWallpaper(val),
                ),

                if (provider.isEnabled) ...[
                  const Divider(color: AppTheme.darkSurfaceVariant, height: 1),

                  // Interval selector
                  _buildOptionRow(
                    icon: Icons.schedule_rounded,
                    iconColor: Colors.blue,
                    title: 'Change Interval',
                    value: provider.getIntervalName(provider.interval),
                    onTap: () => _showIntervalPicker(context, provider),
                  ),

                  const Divider(color: AppTheme.darkSurfaceVariant, height: 1),

                  // Source selector
                  _buildOptionRow(
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
          _buildGlassCard(
            child: Column(
              children: [
                // Enable toggle
                _buildToggleRow(
                  icon: Icons.brightness_6_rounded,
                  iconColor: Colors.orange,
                  title: 'Day/Night Mode',
                  subtitle: provider.isDayNightEnabled
                      ? 'Active'
                      : 'Use different wallpapers based on time',
                  value: provider.isDayNightEnabled,
                  onChanged: (val) => provider.toggleDayNightMode(val),
                ),

                if (provider.isDayNightEnabled) ...[
                  const Divider(color: AppTheme.darkSurfaceVariant, height: 1),

                  // Day wallpaper picker
                  _buildWallpaperPickerRow(
                    icon: Icons.wb_sunny_rounded,
                    iconColor: Colors.amber,
                    title: 'Day Wallpaper',
                    subtitle: 'Shown from ${provider.dayStartHour}:00',
                    imageUrl: provider.dayWallpaperUrl,
                    onTap: () => _pickWallpaper(context, provider, true),
                  ),

                  const Divider(color: AppTheme.darkSurfaceVariant, height: 1),

                  // Night wallpaper picker
                  _buildWallpaperPickerRow(
                    icon: Icons.nightlight_rounded,
                    iconColor: Colors.indigo,
                    title: 'Night Wallpaper',
                    subtitle: 'Shown from ${provider.nightStartHour}:00',
                    imageUrl: provider.nightWallpaperUrl,
                    onTap: () => _pickWallpaper(context, provider, false),
                  ),

                  const Divider(color: AppTheme.darkSurfaceVariant, height: 1),

                  // Time settings
                  _buildOptionRow(
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
                child: _buildActionButton(
                  icon: Icons.refresh_rounded,
                  label: 'Change Now',
                  color: AppTheme.primary,
                  onTap: provider.isEnabled
                      ? () async {
                          await provider.changeNow();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Wallpaper changed!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.stop_rounded,
                  label: 'Stop All',
                  color: Colors.red,
                  onTap: (provider.isEnabled || provider.isDayNightEnabled)
                      ? () async {
                          await provider.cancelAll();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('All schedules cancelled'),
                                behavior: SnackBarBehavior.floating,
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
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Last changed: ${_formatDateTime(provider.lastChangedAt!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.darkSurface.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
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
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
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
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.4),
              size: 20,
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
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 40,
                  height: 60,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width: 40,
                    height: 60,
                    color: AppTheme.darkSurfaceVariant,
                  ),
                ),
              )
            else
              Container(
                width: 40,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.darkSurfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDisabled
              ? AppTheme.darkSurfaceVariant
              : color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDisabled ? Colors.transparent : color.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isDisabled ? Colors.white.withOpacity(0.3) : color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDisabled ? Colors.white.withOpacity(0.3) : color,
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
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Change Interval',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            ...ScheduleInterval.values.map((interval) => ListTile(
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
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    provider.setInterval(interval);
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showSourcePicker(BuildContext context, AutoWallpaperProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Wallpaper Source',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            ...WallpaperSource.values.map((source) => ListTile(
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
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    provider.setSource(source);
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 20),
          ],
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
        const SnackBar(
          content: Text('No bookmarked wallpapers. Save some first!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    isDay ? Icons.wb_sunny_rounded : Icons.nightlight_rounded,
                    color: isDay ? Colors.amber : Colors.indigo,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Select ${isDay ? "Day" : "Night"} Wallpaper',
                    style: const TextStyle(
                      fontSize: 18,
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
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.6,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: bookmarks.length,
                itemBuilder: (context, index) {
                  final wallpaper = bookmarks[index];
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
                          content:
                              Text('${isDay ? "Day" : "Night"} wallpaper set!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: wallpaper.thumbnailUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppTheme.darkSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimePicker(BuildContext context, AutoWallpaperProvider provider) {
    int dayHour = provider.dayStartHour;
    int nightHour = provider.nightStartHour;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Set Times',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // Day time slider
              Row(
                children: [
                  const Icon(Icons.wb_sunny_rounded,
                      color: Colors.amber, size: 20),
                  const SizedBox(width: 12),
                  const Text('Day starts:',
                      style: TextStyle(color: Colors.white)),
                  const Spacer(),
                  Text('${dayHour}:00',
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: dayHour.toDouble(),
                min: 4,
                max: 10,
                divisions: 6,
                activeColor: Colors.amber,
                onChanged: (val) => setSheetState(() => dayHour = val.round()),
              ),

              const SizedBox(height: 16),

              // Night time slider
              Row(
                children: [
                  const Icon(Icons.nightlight_rounded,
                      color: Colors.indigo, size: 20),
                  const SizedBox(width: 12),
                  const Text('Night starts:',
                      style: TextStyle(color: Colors.white)),
                  const Spacer(),
                  Text('${nightHour}:00',
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold)),
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

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    provider.setDayNightTimes(dayHour, nightHour);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Times',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
