import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.getBackground(isDark),
      appBar: AppBar(
        title: Text('Contact Us',
            style: TextStyle(color: AppTheme.getTextPrimary(isDark))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.getTextPrimary(isDark)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We\'d love to hear from you!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextPrimary(isDark),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Have a question, suggestion, or found a bug? Let us know.',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.getTextSecondary(isDark),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            _buildContactMethod(
              context,
              isDark: isDark,
              icon: Icons.email_rounded,
              title: 'Email Support',
              subtitle: 'support@softskywallpaper.studio', // Placeholder
              onTap: () => _launchEmail(),
            ),
            const SizedBox(height: 16),
            _buildContactMethod(
              context,
              isDark: isDark,
              icon: Icons.web_rounded,
              title: 'Visit Website',
              subtitle: 'www.softsky.studio', // Placeholder
              onTap: () => _launchUrl('https://softsky.studio/'), // Placeholder
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactMethod(BuildContext context,
      {required bool isDark,
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.getSurface(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.getTextPrimary(isDark),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.getTextSecondary(isDark),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: AppTheme.getTextMuted(isDark), size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@softskywallpaper.com',
      query: 'subject=Support Request - SoftSky Wallpaper App',
    );
    await _launchUrl(emailLaunchUri.toString());
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      // Handle error
    }
  }
}

