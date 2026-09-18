import 'package:flutter/material.dart';
import '../config/theme.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.getBackground(isDark),
      appBar: AppBar(
        title: Text(
          'Terms & Conditions',
          style: TextStyle(color: AppTheme.getTextPrimary(isDark)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.getTextPrimary(isDark)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextPrimary(isDark),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Last updated: December 01, 2025',
              style: TextStyle(
                color: AppTheme.getTextSecondary(isDark),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Agreement to Terms',
              'By accessing our app, you agree to be bound by these Terms. If you disagree with any part of the terms, then you may not access the service.',
              isDark,
            ),
            _buildSection(
              '2. Content',
              'Our service allows you to view and download wallpapers. You may not distribute, modify, transmit, reuse, download, repost, copy, or use said Content, whether in whole or in part, for commercial purposes or for personal gain, without express advance written permission from us.',
              isDark,
            ),
            _buildSection(
              '3. Pro Subscription',
              'Some parts of the Service are billed on a subscription basis ("Subscription(s)"). You will be billed in advance on a recurring and periodic basis.',
              isDark,
            ),
            _buildSection(
              '4. Termination',
              'We may terminate or suspend access to our Service immediately, without prior notice or liability, for any reason whatsoever, including without limitation if you breach the Terms.',
              isDark,
            ),
            _buildSection(
              '5. Changes',
              'We reserve the right, at our sole discretion, to modify or replace these Terms at any time.',
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.getTextSecondary(isDark),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

