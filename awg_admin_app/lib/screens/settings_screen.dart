import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../widgets/page_header.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loading = true;
  bool _saving = false;

  // Controllers
  final _appNameCtrl = TextEditingController();
  final _pkgNameCtrl = TextEditingController();
  final _supportEmailCtrl = TextEditingController();
  final _contactEmailCtrl = TextEditingController();
  final _privacyUrlCtrl = TextEditingController();
  final _termsUrlCtrl = TextEditingController();
  final _minVerCtrl = TextEditingController();
  final _latestVerCtrl = TextEditingController();
  final _maintenanceMsgCtrl = TextEditingController();
  final _freeLimitCtrl = TextEditingController();
  final _proLimitCtrl = TextEditingController();

  // Deal controllers
  final _dealDiscountCtrl = TextEditingController();
  final _dealOrigPriceCtrl = TextEditingController();
  final _dealDiscPriceCtrl = TextEditingController();
  final _dealIntervalCtrl = TextEditingController();
  String _dealTargetPlan = 'annual';

  // Booleans
  bool _forceUpdate = false;
  bool _maintenanceMode = false;
  bool _enableNotifications = true;
  bool _enableSubscriptions = true;
  bool _enableWideWallpapers = true;
  bool _enableLimitedTimeDeal = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _appNameCtrl.dispose();
    _pkgNameCtrl.dispose();
    _supportEmailCtrl.dispose();
    _contactEmailCtrl.dispose();
    _privacyUrlCtrl.dispose();
    _termsUrlCtrl.dispose();
    _minVerCtrl.dispose();
    _latestVerCtrl.dispose();
    _maintenanceMsgCtrl.dispose();
    _freeLimitCtrl.dispose();
    _proLimitCtrl.dispose();
    _dealDiscountCtrl.dispose();
    _dealOrigPriceCtrl.dispose();
    _dealDiscPriceCtrl.dispose();
    _dealIntervalCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/settings');
      if (!mounted) return;
      final s = (res is Map<String, dynamic> ? res['settings'] : null) as Map<String, dynamic>? ?? {};

      _appNameCtrl.text = s['appName']?.toString() ?? 'SoftSky Wallpaper';
      _pkgNameCtrl.text = s['androidPackageName']?.toString() ?? 'com.webinessdesign.softskywallpaper';
      _supportEmailCtrl.text = s['supportEmail']?.toString() ?? 'support@softsky.studio';
      _contactEmailCtrl.text = s['contactEmail']?.toString() ?? 'contact@softsky.studio';
      _privacyUrlCtrl.text = s['privacyPolicyUrl']?.toString() ?? 'https://softskyadmin.softsky.studio/privacy-policy.html';
      _termsUrlCtrl.text = s['termsUrl']?.toString() ?? 'https://softskyadmin.softsky.studio/terms';
      _minVerCtrl.text = s['minAppVersion']?.toString() ?? '3.0.0';
      _latestVerCtrl.text = s['latestAppVersion']?.toString() ?? '3.0.29';
      _maintenanceMsgCtrl.text = s['maintenanceMessage']?.toString() ?? 'SoftSky is under maintenance. Please try again shortly.';
      _freeLimitCtrl.text = (s['freeDownloadLimitPerDay'] ?? 20).toString();
      _proLimitCtrl.text = (s['proDownloadLimitPerDay'] ?? 0).toString();

      _dealDiscountCtrl.text = (s['dealDiscountPercentage'] ?? 50).toString();
      _dealOrigPriceCtrl.text = (s['dealOriginalPrice'] ?? 79.9).toString();
      _dealDiscPriceCtrl.text = (s['dealDiscountedPrice'] ?? 40.0).toString();
      _dealIntervalCtrl.text = (s['dealIntervalDays'] ?? 2).toString();
      _dealTargetPlan = s['dealTargetPlan']?.toString() ?? 'annual';

      _forceUpdate = s['forceUpdate'] == true;
      _maintenanceMode = s['maintenanceMode'] == true;
      _enableNotifications = s['enableNotifications'] != false;
      _enableSubscriptions = s['enableSubscriptions'] != false;
      _enableWideWallpapers = s['enableWideWallpapers'] != false;
      _enableLimitedTimeDeal = s['enableLimitedTimeDeal'] != false;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load settings: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final payload = {
        'appName': _appNameCtrl.text.trim(),
        'androidPackageName': _pkgNameCtrl.text.trim(),
        'supportEmail': _supportEmailCtrl.text.trim(),
        'contactEmail': _contactEmailCtrl.text.trim(),
        'privacyPolicyUrl': _privacyUrlCtrl.text.trim(),
        'termsUrl': _termsUrlCtrl.text.trim(),
        'minAppVersion': _minVerCtrl.text.trim(),
        'latestAppVersion': _latestVerCtrl.text.trim(),
        'forceUpdate': _forceUpdate,
        'maintenanceMode': _maintenanceMode,
        'maintenanceMessage': _maintenanceMsgCtrl.text.trim(),
        'freeDownloadLimitPerDay': int.tryParse(_freeLimitCtrl.text.trim()) ?? 20,
        'proDownloadLimitPerDay': int.tryParse(_proLimitCtrl.text.trim()) ?? 0,
        'enableNotifications': _enableNotifications,
        'enableSubscriptions': _enableSubscriptions,
        'enableWideWallpapers': _enableWideWallpapers,
        'enableLimitedTimeDeal': _enableLimitedTimeDeal,
        'dealDiscountPercentage': int.tryParse(_dealDiscountCtrl.text.trim()) ?? 50,
        'dealOriginalPrice': double.tryParse(_dealOrigPriceCtrl.text.trim()) ?? 79.9,
        'dealDiscountedPrice': double.tryParse(_dealDiscPriceCtrl.text.trim()) ?? 40.0,
        'dealIntervalDays': int.tryParse(_dealIntervalCtrl.text.trim()) ?? 2,
        'dealTargetPlan': _dealTargetPlan,
      };

      await ApiService.put('/settings', payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully!'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceVariant,
      body: Column(
        children: [
          PageHeader(
            title: 'App Settings',
            subtitle: 'Remote app configuration, version gates & deals',
            trailing: ElevatedButton.icon(
              onPressed: _loading || _saving ? null : _saveSettings,
              icon: _saving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded, size: 16),
              label: Text(_saving ? 'Saving...' : 'Save'),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadSettings,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildSectionCard(
                          title: 'App Identity & Store',
                          icon: Icons.storefront_rounded,
                          color: AppTheme.info,
                          children: [
                            _buildTextField('App Name', _appNameCtrl),
                            const SizedBox(height: 12),
                            _buildTextField('Android Package Name', _pkgNameCtrl),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _buildTextField('Support Email', _supportEmailCtrl)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildTextField('Contact Email', _contactEmailCtrl)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildTextField('Privacy Policy URL', _privacyUrlCtrl),
                            const SizedBox(height: 12),
                            _buildTextField('Terms of Service URL', _termsUrlCtrl),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          title: 'Version Gates & Maintenance',
                          icon: Icons.system_update_rounded,
                          color: AppTheme.warning,
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildTextField('Min Version', _minVerCtrl)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildTextField('Latest Version', _latestVerCtrl)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Force Update', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              subtitle: const Text('Require users below minimum version to update', style: TextStyle(fontSize: 12)),
                              value: _forceUpdate,
                              onChanged: (v) => setState(() => _forceUpdate = v),
                            ),
                            const Divider(height: 16),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Maintenance Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              subtitle: const Text('Block regular app usage and display maintenance note', style: TextStyle(fontSize: 12)),
                              value: _maintenanceMode,
                              onChanged: (v) => setState(() => _maintenanceMode = v),
                            ),
                            if (_maintenanceMode) ...[
                              const SizedBox(height: 8),
                              _buildTextField('Maintenance Message', _maintenanceMsgCtrl, maxLines: 2),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          title: 'Promotions & Limited Deals',
                          icon: Icons.local_offer_rounded,
                          color: AppTheme.creator,
                          children: [
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Enable 50% Off Deal Popup', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              subtitle: const Text('Display promotional limited-time deal modal to users', style: TextStyle(fontSize: 12)),
                              value: _enableLimitedTimeDeal,
                              onChanged: (v) => setState(() => _enableLimitedTimeDeal = v),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField('Discount (%)', _dealDiscountCtrl, keyboardType: TextInputType.number),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _dealTargetPlan,
                                    decoration: InputDecoration(
                                      labelText: 'Target Plan',
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'annual', child: Text('Annual')),
                                      DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                                      DropdownMenuItem(value: 'lifetime', child: Text('Lifetime')),
                                    ],
                                    onChanged: (v) => setState(() => _dealTargetPlan = v ?? 'annual'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField('Original Price (₹)', _dealOrigPriceCtrl, keyboardType: TextInputType.number),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTextField('Discounted Price (₹)', _dealDiscPriceCtrl, keyboardType: TextInputType.number),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildTextField('Popup Interval Gap (Days)', _dealIntervalCtrl, keyboardType: TextInputType.number),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          title: 'Quotas & Feature Switches',
                          icon: Icons.toggle_on_rounded,
                          color: AppTheme.success,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField('Free Limit/Day', _freeLimitCtrl, keyboardType: TextInputType.number),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTextField('Pro Limit/Day (0=∞)', _proLimitCtrl, keyboardType: TextInputType.number),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Enable Notifications', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              value: _enableNotifications,
                              onChanged: (v) => setState(() => _enableNotifications = v),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Enable Subscriptions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              value: _enableSubscriptions,
                              onChanged: (v) => setState(() => _enableSubscriptions = v),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Enable Wide Wallpapers', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              value: _enableWideWallpapers,
                              onChanged: (v) => setState(() => _enableWideWallpapers = v),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _loading || _saving ? null : _saveSettings,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.save_rounded),
                            label: Text(
                              _saving ? 'Saving Changes...' : 'Save All Settings',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController ctrl, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
      ),
    );
  }
}
