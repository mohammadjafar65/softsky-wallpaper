import 'package:flutter/material.dart';
import '../config/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Privacy Policy', style: TextStyle(color: AppTheme.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Last updated: December 01, 2025',
              style: TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 24),
            _buildSection('1. Introduction', 'Welcome to SoftSky Wallpaper App. We respect your privacy and are committed to protecting your personal data.'),
            _buildSection('2. Data We Collect', 'We may collect usage data, device information, and basic profile info if you sign in with Google. We do not sell your personal data.'),
            _buildSection('3. How We Use Your Data', 'To provide and maintain the Service, notify you about changes, allow interactive features, and provide customer support.'),
            _buildSection('4. Third Party Services', 'We use Google Firebase for authentication and database services. Please refer to their privacy policies.'),
             _buildSection('5. Contact Us', 'If you have any questions about this Privacy Policy, please contact us.'),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
